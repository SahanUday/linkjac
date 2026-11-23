import from stdjac { allroots }

def missing_bookmark -> ApiReply {
    return reply_detail(404, "No Bookmark matches the given query.");
}

def filter_of(call: ApiCall, owner: Root, archived: bool) -> BookmarkFilter {
    profile = profile_of(owner);
    return BookmarkFilter(
        text=query_value(call, "q"),
        archived=archived,
        unread=query_value(call, "unread", "off"),
        shared=query_value(call, "shared", "off"),
        sort=query_value(call, "sort", "added_desc"),
        added_since=query_value(call, "added_since"),
        modified_since=query_value(call, "modified_since"),
        legacy=profile.legacy_search,
        lax=profile.tag_search == "lax",
    );
}

def page_reply(call: ApiCall, route: str, found: list[Bookmark]) -> ApiReply {
    window = window_of(call);
    rows = [bookmark_json(b) for b in found[window.offset:window.offset + window.limit]];
    return reply_json(200, page_of(call, route, window, len(found), rows));
}

def list_reply(call: ApiCall, owner: Root, archived: bool) -> ApiReply {
    found = search_bookmarks(owner, filter_of(call, owner, archived));
    return page_reply(call, "bookmarks/archived" if archived else "bookmarks", found);
}

# UNTESTED(GAP-035): allroots() is empty in `neojac test`, and no API turns sharing on, so this has never run.
def sharing_owners(public_only: bool) -> list[Root] {
    owners: list[Root] = [];
    for candidate in allroots() {
        profile = find_profile(candidate);
        if profile is not None
            and profile.enable_sharing
            and (profile.enable_public_sharing or not public_only)
        {
            owners.append(candidate);
        }
    }
    return owners;
}

def set_archived_reply(call: ApiCall, owner: Root, text: str, archive: bool) -> ApiReply {
    if call.method != "POST" {
        return reply_not_allowed(call.method);
    }
    bookmark = find_bookmark(owner, id_in_path(text));
    if bookmark is None {
        return missing_bookmark();
    }
    set_archived(bookmark, archive);
    return reply_empty(204);
}

impl shared_route(call: ApiCall, public_only: bool) -> ApiReply {
    if call.method != "GET" {
        return reply_not_allowed(call.method);
    }
    narrowing = BookmarkFilter(
        text=query_value(call, "q"),
        shared="yes",
        unread=query_value(call, "unread", "off"),
        sort=query_value(call, "sort", "added_desc"),
        added_since=query_value(call, "added_since"),
        modified_since=query_value(call, "modified_since"),
    );
    return page_reply(
        call, "bookmarks/shared", search_many(sharing_owners(public_only), narrowing)
    );
}

def refused(reading: DraftReading) -> ApiReply {
    return reply_field_errors(reading.errors);
}

def create_reply(call: ApiCall, owner: Root) -> ApiReply {
    given = body_object(call);
    if given is None {
        return reply_not_a_dictionary();
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
        return reply_not_a_dictionary();
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
    bookmark = find_bookmark(owner, id_in_path(text));
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
    return reply_not_allowed(call.method);
}

impl bookmarks_route(call: ApiCall, owner: Root) -> ApiReply {
    if len(call.segments) == 1 {
        if call.method == "GET" {
            return list_reply(call, owner, False);
        }
        if call.method == "POST" {
            return create_reply(call, owner);
        }
        return reply_not_allowed(call.method);
    }
    if len(call.segments) == 2 {
        if call.segments[1] == "archived" {
            return list_reply(call, owner, True)
                if call.method == "GET"
                else reply_not_allowed(call.method);
        }
        if call.segments[1] == "shared" {
            return shared_route(call, False);
        }
        return one_reply(call, owner, call.segments[1]);
    }
    if len(call.segments) == 3 and call.segments[2] in ["archive", "unarchive"] {
        return set_archived_reply(call, owner, call.segments[1], call.segments[2] == "archive");
    }
    return reply_detail(404, "Not found.");
}
