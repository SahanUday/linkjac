impl iso_utc(stamp: datetime) -> str {
    fraction = f".{stamp.microsecond:06d}" if stamp.microsecond else "";
    return stamp.strftime("%Y-%m-%dT%H:%M:%S") + fraction + "Z";
}

impl archive_url_of(bookmark: Bookmark) -> str {
    return "https://web.archive.org/web/"
        + bookmark.date_added.strftime("%Y%m%d%H%M%S")
        + "/"
        + bookmark.url;
}

impl tag_json(tag: Tag) -> dict[str, any] {
    return {"id": tag.id, "name": tag.name, "date_added": iso_utc(tag.date_added)};
}

impl bookmark_json(bookmark: Bookmark) -> dict[str, any] {
    return {
        "id": bookmark.id,
        "url": bookmark.url,
        "title": bookmark.title,
        "description": bookmark.description,
        "notes": bookmark.notes,
        "web_archive_snapshot_url": archive_url_of(bookmark),
        "favicon_url": None,
        "preview_image_url": None,
        "is_archived": bookmark.is_archived,
        "unread": bookmark.unread,
        "shared": bookmark.shared,
        "tag_names": tag_names_of(bookmark),
        "date_added": iso_utc(bookmark.date_added),
        "date_modified": iso_utc(bookmark.date_modified),
        "website_title": None,
        "website_description": None,
    };
}

def text_field(given: dict[str, any], name: str, into: DraftReading) -> str | None {
    value = given[name];
    if isinstance(value, str) {
        return value;
    }
    into.errors[name] = ["Not a valid string."]
        if value is not None
        else ["This field may not be null."];
    return None;
}

def flag_field(given: dict[str, any], name: str, into: DraftReading) -> bool | None {
    value = given[name];
    if isinstance(value, bool) {
        return value;
    }
    into.errors[name] = ["Must be a valid boolean."];
    return None;
}

def read_url(given: dict[str, any], into: DraftReading) {
    text = text_field(given, "url", into);
    if text is None {
        return;
    }
    if not text {
        into.errors["url"] = ["This field may not be blank."];
    } elif not is_valid_url(text) {
        into.errors["url"] = ["Enter a valid URL."];
    } else {
        into.draft.url = text;
    }
}

def read_tag_names(given: dict[str, any], into: DraftReading) {
    value = given["tag_names"];
    if isinstance(value, list) and all([isinstance(n, str) for n in value]) {
        into.draft.tag_string = ",".join([str(n) for n in value]);
    } else {
        into.errors["tag_names"] = ["Expected a list of strings."];
    }
}

impl read_draft(given: dict[str, any], start: BookmarkDraft, url_required: bool) -> DraftReading {
    reading = DraftReading(draft=start);
    if "url" in given {
        read_url(given, reading);
    } elif url_required {
        reading.errors["url"] = ["This field is required."];
    }
    for name in ["title", "description", "notes"] {
        if name in given {
            text = text_field(given, name, reading);
            if text is not None {
                setattr(reading.draft, name, text);
            }
        }
    }
    for name in ["unread", "shared", "is_archived"] {
        if name in given {
            flag = flag_field(given, name, reading);
            if flag is not None {
                setattr(reading.draft, name, flag);
            }
        }
    }
    if "tag_names" in given {
        read_tag_names(given, reading);
    }
    return reading;
}
