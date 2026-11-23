impl user_route(call: ApiCall, owner: Root) -> ApiReply {
    if call.segments == ["user", "profile"] {
        if call.method != "GET" {
            return reply_detail(405, f"Method \"{call.method}\" not allowed.");
        }
        return reply_json(200, profile_json(profile_of(owner)));
    }
    return reply_detail(404, "Not found.");
}
