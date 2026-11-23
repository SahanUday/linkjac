def list_tags_reply(call: ApiCall, owner: Root) -> ApiReply {
    window = window_of(call);
    everything = list_tags(owner);
    rows = [tag_json(t) for t in everything[window.offset:window.offset + window.limit]];
    return reply_json(200, page_of(call, "tags", window, len(everything), rows));
}

def create_tag_reply(call: ApiCall, owner: Root) -> ApiReply {
    given = body_object(call);
    if given is None {
        return reply_not_a_dictionary();
    }
    if "name" not in given {
        return reply_field_errors({"name": ["This field is required."]});
    }
    name = given["name"];
    if not isinstance(name, str) {
        return reply_field_errors({"name": ["Not a valid string."]});
    }
    if not name {
        return reply_field_errors({"name": ["This field may not be blank."]});
    }
    return reply_json(201, tag_json(find_or_make_tag(owner, name)));
}

def one_tag_reply(call: ApiCall, owner: Root, text: str) -> ApiReply {
    tag = find_tag_by_id(owner, id_in_path(text));
    if tag is None {
        return reply_detail(404, "No Tag matches the given query.");
    }
    if call.method == "GET" {
        return reply_json(200, tag_json(tag));
    }
    if call.method == "DELETE" {
        delete_tag(tag);
        return reply_empty(204);
    }
    return reply_not_allowed(call.method);
}

impl tags_route(call: ApiCall, owner: Root) -> ApiReply {
    if len(call.segments) == 1 {
        if call.method == "GET" {
            return list_tags_reply(call, owner);
        }
        if call.method == "POST" {
            return create_tag_reply(call, owner);
        }
        return reply_not_allowed(call.method);
    }
    if len(call.segments) == 2 {
        return one_tag_reply(call, owner, call.segments[1]);
    }
    return reply_detail(404, "Not found.");
}
