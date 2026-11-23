import from datetime { datetime }

test "a time is written in UTC with microseconds and a Z, and no fraction when it is zero" {
    assert iso_utc(datetime(2026, 11, 23, 9, 56, 8, 51886)) == "2026-11-23T09:56:08.051886Z";
    assert iso_utc(datetime(2020, 1, 2, 1, 4, 5)) == "2020-01-02T01:04:05Z";
}

test "a body without a url, or with a bad one, is refused for that field" {
    missing = read_draft({}, BookmarkDraft(url=""), True);
    assert missing.errors == {"url": ["This field is required."]};
    bad = read_draft({"url": "not a url"}, BookmarkDraft(url=""), True);
    assert bad.errors == {"url": ["Enter a valid URL."]};
    blank = read_draft({"url": ""}, BookmarkDraft(url=""), True);
    assert blank.errors == {"url": ["This field may not be blank."]};
}

test "fields the body leaves out keep their value, and tag names become a tag string" {
    start = BookmarkDraft(url="https://keep.example", title="Keep", notes="old");
    reading = read_draft({"notes": "new", "unread": True, "tag_names": ["b", "a"]}, start, False);
    assert not reading.errors;
    assert reading.draft.title == "Keep" and reading.draft.notes == "new";
    assert reading.draft.unread and reading.draft.tag_string == "b,a";
    wrong = read_draft({"unread": "yes"}, start, False);
    assert wrong.errors == {"unread": ["Must be a valid boolean."]};
}
