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
    if sent.path.startswith(prefix_now) {
        reply = rest_reply_from(answer(rest_call_for(sent)), "authorization" in headers);
    } else {
        reply = answer(sent);
    }
    self.send_response(reply.status);
    if reply.body {
        self.send_header("Content-Type", reply.ctype);
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

impl answer(sent: Request) -> Response {
    handle = handler_now;
    return handle(sent);
}

# WORKAROUND(GAP-034): the standard auth plugin reads only `Bearer`, linkding's clients send `Token`.
impl rest_call_for(sent: Request) -> Request {
    headers = dict(sent.headers);
    given = headers.get("authorization", "");
    if given.lower().startswith("token ") {
        headers["authorization"] = "Bearer " + given[6:];
    }
    arguments = {
        "method": sent.method,
        "path": sent.path,
        "query": sent.query,
        "body": sent.body.decode("utf-8"),
        "origin": "http://" + headers.get("host", ""),
    };
    return Request(
        method="POST",
        path=call_now,
        query="",
        headers=headers,
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

impl rest_reply_from(inner: Response, had_credentials: bool) -> Response {
    if inner.status == 401 {
        return json_reply(
            401,
            {
                "detail": "Invalid token."
                    if had_credentials
                    else "Authentication credentials were not provided.",
            },
        );
    }
    decoded = json.loads(inner.body.decode("utf-8"));
    if inner.status == 200 and decoded["ok"] {
        data = decoded["data"];
        return Response(
            status=data["status"],
            ctype="application/json",
            body=data["body"].encode("utf-8"),
            headers={},
            events=None,
        );
    }
    return json_reply(inner.status, {"detail": decoded.get("detail", "")});
}

impl RestBridge.open(host: dyn Host) {}

impl RestBridge.send(address: str, r: Request, seconds: float) -> Response {
    raise OSError("rest_bridge carries no calls to other apps");
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
    handler_now = handle;
    door = claim as Door;
    if listening is not None {
        listening(door.server.server_port);
    }
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
