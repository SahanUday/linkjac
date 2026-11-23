import from urllib.parse { urlencode }

def whole_number(text: str, fallback: int) -> int {
    try {
        value = int(text);
    } except ValueError {
        return fallback;
    }
    return value if value >= 0 else fallback;
}

def link_to(call: ApiCall, route: str, window: PageWindow, keep_offset: bool) -> str {
    pairs = [(k, v) for (k, v) in call.query.items() if k != "limit" and k != "offset"];
    pairs.append(("limit", str(window.limit)));
    if keep_offset {
        pairs.append(("offset", str(window.offset)));
    }
    return call.origin + "/api/" + route + "/?" + urlencode(pairs);
}

impl window_of(call: ApiCall) -> PageWindow {
    limit = whole_number(query_value(call, "limit", "100"), 100);
    return PageWindow(
        limit=limit if limit > 0 else 100, offset=whole_number(query_value(call, "offset", "0"), 0)
    );
}

impl page_of(
    call: ApiCall, route: str, window: PageWindow, count: int, results: list[dict[str, any]]
) -> dict[str, any] {
    following: str | None = None;
    if window.offset + window.limit < count {
        following = link_to(
            call, route, PageWindow(window.limit, window.offset + window.limit), True
        );
    }
    preceding: str | None = None;
    if window.offset > 0 {
        back = window.offset - window.limit;
        preceding = link_to(call, route, PageWindow(window.limit, back), back > 0);
    }
    return {"count": count, "next": following, "previous": preceding, "results": results};
}
