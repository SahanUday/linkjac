import from urllib.parse { urlparse, urlunparse, parse_qsl, urlencode, quote }

impl normalize_url(url: str) -> str {
    text = url.strip();
    if not text {
        return "";
    }
    try {
        parsed = urlparse(text);
        host = (parsed.hostname or "").lower();
        netloc = host;
        if parsed.port is not None {
            netloc += f":{parsed.port}";
        }
        if parsed.username {
            login = parsed.username;
            if parsed.password {
                login += f":{parsed.password}";
            }
            netloc = f"{login}@{netloc}";
        }
        query = "";
        if parsed.query {
            pairs = sorted(parse_qsl(parsed.query, keep_blank_values=True));
            query = urlencode(pairs, quote_via=quote);
        }
        return urlunparse((
            parsed.scheme.lower(),
            netloc,
            parsed.path.rstrip("/"),
            parsed.params,
            query,
            parsed.fragment,
        ));
    } except ValueError {
        return text;
    }
}
