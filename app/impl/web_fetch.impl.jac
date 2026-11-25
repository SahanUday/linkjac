glob user_agent: str = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
     chunk_size: int = 51200,
     longest_page: int = 5120000,
     seconds_to_wait: float = 10.0,
     most_redirects: int = 5;

def read_body(response: HTTPResponse, head_only: bool) -> bytes {
    content = b"";
    while len(content) <= longest_page {
        part = response.read(chunk_size);
        if not part {
            break;
        }
        content += part;
        if head_only and b"</head>" in content {
            return content.split(b"</head>")[0] + b"</head>";
        }
    }
    return content;
}

# The socket is opened to an address that was checked, never to the name again: a second lookup could give another answer.
def open_to(addresses: list[str], port: int) -> socket.socket {
    for address in addresses[:-1] {
        try {
            return socket.create_connection((address, port), timeout=seconds_to_wait);
        } except OSError {
            continue;
        }
    }
    return socket.create_connection((addresses[-1], port), timeout=seconds_to_wait);
}

def connect_checked(host: str, port: int, secure: bool) -> HTTPConnection | None {
    addresses = checked_addresses(host, port);
    if not addresses {
        return None;
    }
    opened = open_to(addresses, port);
    connection = HTTPSConnection(host, port) if secure else HTTPConnection(host, port);
    connection.sock = ssl.create_default_context().wrap_socket(opened, server_hostname=host)
        if secure
        else opened;
    return connection;
}

def get_once(current: str, head_only: bool) -> tuple[int, str, bytes] | None {
    connection: HTTPConnection | None = None;
    try {
        parts = urlsplit(current);
        if parts.scheme not in ["http", "https"] or not parts.hostname {
            return None;
        }
        secure = parts.scheme == "https";
        connection = connect_checked(parts.hostname, parts.port or (443 if secure else 80), secure);
        if connection is None {
            return None;
        }
        path = (parts.path or "/") + ("?" + parts.query if parts.query else "");
        connection.request("GET", path, headers={"User-Agent": user_agent});
        response = connection.getresponse();
        where = response.getheader("Location") or "";
        return (response.status, where, read_body(response, head_only));
    } except Exception {
        return None;
    } finally {
        if connection is not None {
            connection.close();
        }
    }
}

impl fetch_page(url: str, head_only: bool = False) -> str | None {
    current = url;
    for _ in range(most_redirects + 1) {
        got = get_once(current, head_only);
        if got is None {
            return None;
        }
        if got[0] in [301, 302, 303, 307, 308] and got[1] {
            current = urljoin(current, got[1]);
            continue;
        }
        return got[2].decode("utf-8", errors="replace");
    }
    return None;
}
