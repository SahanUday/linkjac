glob user_agent: str = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
     chunk_size: int = 51200,
     longest_page: int = 5120000,
     seconds_to_wait: float = 10.0,
     most_redirects: int = 5;

def allowed_hosts -> list[str] {
    named = os.getenv("LD_ALLOWED_INTERNAL_HOSTS", "");
    return [each.strip() for each in named.split(",") if each.strip()];
}

impl may_connect(host: str) -> bool {
    allowed = allowed_hosts();
    if "*" in allowed or host in allowed {
        return True;
    }
    try {
        found = socket.getaddrinfo(host, None);
    } except OSError {
        return False;
    }
    for each in found {
        address = str(each[4][0]);
        if address not in allowed and not ipaddress.ip_address(address).is_global {
            return False;
        }
    }
    return True;
}

def read_head(response: HTTPResponse) -> bytes {
    content = b"";
    while len(content) <= longest_page {
        part = response.read(chunk_size);
        if not part {
            break;
        }
        content += part;
        if b"</head>" in content {
            return content.split(b"</head>")[0] + b"</head>";
        }
    }
    return content;
}

def get_once(current: str) -> tuple[int, str, bytes] | None {
    parts = urlsplit(current);
    if parts.scheme not in ["http", "https"]
        or not parts.hostname
        or not may_connect(parts.hostname)
    {
        return None;
    }
    path = (parts.path or "/") + ("?" + parts.query if parts.query else "");
    connection = HTTPSConnection(parts.hostname, parts.port, timeout=seconds_to_wait)
        if parts.scheme == "https"
        else HTTPConnection(parts.hostname, parts.port, timeout=seconds_to_wait);
    try {
        connection.request("GET", path, headers={"User-Agent": user_agent});
        response = connection.getresponse();
        where = response.getheader("Location") or "";
        return (response.status, where, read_head(response));
    } except Exception {
        return None;
    } finally {
        connection.close();
    }
}

impl fetch_head(url: str) -> str | None {
    current = url;
    for _ in range(most_redirects + 1) {
        got = get_once(current);
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
