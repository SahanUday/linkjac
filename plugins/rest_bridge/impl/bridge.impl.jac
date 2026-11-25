impl Gateway.relay(method: str) {
    length = int(self.headers.get("Content-Length") or "0");
    body = self.rfile.read(length) if length > 0 else b"";
    headers: dict[str, str] = {};
    for (name, value) in self.headers.items() {
        headers[name.lower()] = value;
    }
    parts = self.path.split("?", 1);
    sent = Request(
        method=method,
        path=parts[0],
        query=parts[1] if len(parts) > 1 else "",
        headers=headers,
        body=body,
        client=self.client_address[0],
    );
    if sent.path.startswith(prefix_now) or is_static(sent.path) {
        fault = header_fault(sent.headers.get("authorization", ""));
        reply = json_reply(401, {"detail": fault})
            if fault and not is_static(sent.path)
            else rest_reply_from(answer(rest_call_for(sent)));
    } elif takes_nothing(sent, prefix_now) {
        reply = json_reply(404, {"detail": "Not found."});
    } else {
        reply = answer(sent);
    }
    self.send_response(reply.status);
    if reply.body {
        self.send_header("Content-Type", reply.ctype);
    }
    for (name, value) in reply.headers.items() {
        self.send_header(name, value);
    }
    self.send_header("Content-Length", str(len(reply.body)));
    self.end_headers();
    self.wfile.write(reply.body);
}

impl Gateway.do_GET {
    self.relay("GET");
}

impl Gateway.do_POST {
    self.relay("POST");
}

impl Gateway.do_PUT {
    self.relay("PUT");
}

impl Gateway.do_PATCH {
    self.relay("PATCH");
}

impl Gateway.do_DELETE {
    self.relay("DELETE");
}

impl Gateway.log_message(format: str, *args: any) {}

# WORKAROUND(GAP-057): the app would answer a POST to a page's path with the page.
impl takes_nothing(sent: Request, api_prefix: str) -> bool {
    return sent.method != "GET"
        and not sent.path.startswith(api_prefix)
        and not sent.path.startswith("/__jac/");
}

impl answer(sent: Request) -> Response {
    handle = handler_now;
    return handle(sent);
}

def is_static(path: str) -> bool {
    return bool(static_now) and path.startswith(static_now);
}

# WORKAROUND(GAP-054): the auth plugin cannot say why it refuses a header, so the transport does.
impl header_fault(header: str) -> str {
    words = token_words(header);
    if not words or len(words) == 2 {
        return "";
    }
    if len(words) == 1 {
        return "Invalid token header. No credentials provided.";
    }
    return "Invalid token header. Token string should not contain spaces.";
}

impl rest_call_for(sent: Request) -> Request {
    arguments = {
        "method": sent.method,
        "path": sent.path,
        "query": sent.query,
        "body": sent.body.decode("utf-8"),
        "origin": "http://" + sent.headers.get("host", ""),
    };
    carries_token = bool(token_words(sent.headers.get("authorization", "")));
    return Request(
        method="POST",
        path=call_now if carries_token and not is_static(sent.path) else public_call_now,
        query="",
        headers=dict(sent.headers),
        body=json.dumps({"args": arguments}).encode("utf-8"),
        client=sent.client,
    );
}

def json_reply(status: int, value: any) -> Response {
    return Response(
        status=status,
        ctype="application/json",
        body=json.dumps(value).encode("utf-8"),
        headers={},
        events=None,
    );
}

def file_reply(kept: dict[str, str]) -> Response {
    named = {"Content-Disposition": f'attachment; filename="{kept["name"]}"'}
        if kept["name"]
        else {};
    return Response(
        status=200,
        ctype=kept["type"],
        body=base64.b64decode(kept["base64"]),
        headers=named,
        events=None,
    );
}

# WORKAROUND(GAP-054): a refused token is answered in the runtime's words; linkding's clients expect {"detail": "Invalid token."}.
impl rest_reply_from(inner: Response) -> Response {
    if inner.status == 401 {
        return json_reply(401, {"detail": "Invalid token."});
    }
    try {
        decoded = json.loads(inner.body.decode("utf-8"));
        if inner.status == 200 and decoded["ok"] {
            data = decoded["data"];
            if data["status"] == 200 and data["body"].startswith('{"__file__"') {
                return file_reply(json.loads(data["body"])["__file__"]);
            }
            return Response(
                status=data["status"],
                ctype="application/json",
                body=data["body"].encode("utf-8"),
                headers={},
                events=None,
            );
        }
        return json_reply(inner.status, {"detail": decoded.get("detail", "")});
    } except (ValueError, KeyError, TypeError, AttributeError) {
        return json_reply(
            500, {"detail": "The app answered in a form the REST bridge does not know."}
        );
    }
}

impl RestBridge.open(host: dyn Host) {}

# WORKAROUND(GAP-039): the CLI app reaches the server through the project's one transport, which is this plugin, so it carries calls out too (no streams).
impl RestBridge.send(address: str, r: Request, seconds: float) -> Response {
    where = urlsplit(address);
    link = HTTPConnection(where.hostname, where.port, timeout=seconds);
    try {
        link.request(
            r.method, r.path + ("?" + r.query if r.query else ""), body=r.body, headers=r.headers
        );
        got = link.getresponse();
        return Response(
            status=got.status,
            ctype=got.getheader("Content-Type") or "",
            body=got.read(),
            headers={},
            events=None,
        );
    } finally {
        link.close();
    }
}

impl RestBridge.claim(address: str) -> Claim {
    parts = address.rsplit(":", 1);
    try {
        server = ThreadingHTTPServer((parts[0], int(parts[1])), Gateway);
    } except OSError as e {
        raise CannotListen(reason=str(e));
    }
    return Door(server=server);
}

impl RestBridge.listen(
    claim: Claim,
    handle: Callable[[Request], Response],
    ticks: list[Tick],
    listening: Callable[[int], None] | None,
) {
    prefix_now = self.api_prefix;
    call_now = self.call_path;
    public_call_now = self.public_call_path;
    static_now = self.static_prefix;
    handler_now = handle;
    door = claim as Door;
    if listening is not None {
        listening(door.server.server_port);
    }
    # WORKAROUND(GAP-036): nothing else prints the line that scripts wait for.
    print(
        f"listening on http://{door.server.server_address[0]}:{door.server.server_port}/",
        flush=True,
    );
    door.server.serve_forever();
}

impl RestBridge.on_loop(work: Callable[[], None]) {
    work();
}

impl RestBridge.serving -> bool {
    return True;
}

impl RestBridge.serves_paths -> bool {
    return True;
}
