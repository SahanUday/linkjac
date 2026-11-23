impl handle(method: str, path: str, query: str, body: str, origin: str) -> ApiReply {
    call = make_call(method, path, query, body, origin);
    if not call.segments {
        return reply_detail(404, "Not found.");
    }
    if call.segments[0] == "tags" {
        return tags_route(call, root);
    }
    if call.segments[0] == "bookmarks" {
        return bookmarks_route(call, root);
    }
    if call.segments[0] == "user" {
        return user_route(call, root);
    }
    return reply_detail(404, "Not found.");
}

impl handle_public(method: str, path: str, query: str, body: str, origin: str) -> ApiReply {
    if path.startswith("/static/") {
        return static_route(method, path);
    }
    call = make_call(method, path, query, body, origin);
    if call.segments == ["bookmarks", "shared"] {
        return shared_route(call, True);
    }
    return reply_detail(401, "Authentication credentials were not provided.");
}
