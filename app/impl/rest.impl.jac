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
    return reply_detail(404, "Not found.");
}
