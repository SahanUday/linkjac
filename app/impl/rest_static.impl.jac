impl static_route(method: str, path: str) -> ApiReply {
    if method != "GET" {
        return reply_not_allowed(method);
    }
    found = find_favicon(path.removeprefix("/static/"));
    if found is None {
        return reply_detail(404, "Not found.");
    }
    return reply_file(found.content_type, found.data, "");
}
