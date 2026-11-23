def not_allowed(call: ApiCall) -> ApiReply {
    return reply_detail(405, f"Method \"{call.method}\" not allowed.");
}

def missing_bookmark -> ApiReply {
    return reply_detail(404, "No Bookmark matches the given query.");
}

def list_reply(call: ApiCall, owner: Root) -> ApiReply {
    window = window_of(call);
    found = search_bookmarks(owner, BookmarkFilter(text=query_value(call, "q")));
    rows = [bookmark_json(b) for b in found[window.offset:window.offset + window.limit]];
    return reply_json(200, page_of(call, "bookmarks", window, len(found), rows));
}

def refused(reading: DraftReading) -> ApiReply {
    return reply_field_errors(reading.errors);
}

def create_reply(call: ApiCall, owner: Root) -> ApiReply {
    given = body_object(call);
    if given is None {
        return reply_field_errors({"non_field_errors": ["Invalid data. Expected a dictionary."]});
    }
    reading = read_draft(given, BookmarkDraft(url=""), True);
    if reading.errors {
        return refused(reading);
    }
    return reply_json(201, bookmark_json(create_bookmark(owner, reading.draft)));
}

def has_other_with_url(owner: Root, bookmark: Bookmark, url: str) -> bool {
    return any([b.url == url and b is not bookmark for b in list_bookmarks(owner)]);
}

def change_reply(call: ApiCall, owner: Root, bookmark: Bookmark) -> ApiReply {
    given = body_object(call);
    if given is None {
        return reply_field_errors({"non_field_errors": ["Invalid data. Expected a dictionary."]});
    }
    reading = read_draft(given, draft_of(bookmark), call.method == "PUT");
    if not reading.errors and has_other_with_url(owner, bookmark, reading.draft.url) {
        reading.errors["url"] = ["A bookmark with this URL already exists."];
    }
    if reading.errors {
        return refused(reading);
    }
    return reply_json(200, bookmark_json(update_bookmark(owner, bookmark, reading.draft)));
}

def one_reply(call: ApiCall, owner: Root, text: str) -> ApiReply {
    bookmark = find_bookmark(owner, int(text)) if text.isdigit() else None;
    if bookmark is None {
        return missing_bookmark();
    }
    if call.method == "GET" {
        return reply_json(200, bookmark_json(bookmark));
    }
    if call.method == "PUT" or call.method == "PATCH" {
        return change_reply(call, owner, bookmark);
    }
    if call.method == "DELETE" {
        delete_bookmark(bookmark);
        return reply_empty(204);
    }
    return not_allowed(call);
}

impl bookmarks_route(call: ApiCall, owner: Root) -> ApiReply {
    if len(call.segments) == 1 {
        if call.method == "GET" {
            return list_reply(call, owner);
        }
        if call.method == "POST" {
            return create_reply(call, owner);
        }
        return not_allowed(call);
    }
    if len(call.segments) == 2 {
        return one_reply(call, owner, call.segments[1]);
    }
    return reply_detail(404, "Not found.");
}
