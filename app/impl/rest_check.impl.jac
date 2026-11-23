impl check_route(call: ApiCall, owner: Root) -> ApiReply {
    if call.method != "GET" {
        return reply_not_allowed(call.method);
    }
    url = query_value(call, "url");
    existing = find_existing(owner, url);
    found = load_website_metadata(url);
    return reply_json(
        200,
        {
            "bookmark": bookmark_json(existing, call.origin) if existing is not None else None,
            "metadata": {
                "url": found.url,
                "title": found.title,
                "description": found.description,
                "preview_image": found.preview_image,
            },
            "auto_tags": [],
        },
    );
}
