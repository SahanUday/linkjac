import from stdjac { remove }

impl set_tags(owner: Root, bookmark: Bookmark, tag_string: str) {
    for link in [edge bookmark ->:Tagged:->] {
        del link;
    }
    for name in parse_tag_string(tag_string) {
        bookmark +>:Tagged:+> find_or_make_tag(owner, name);
    }
}

impl find_existing(owner: Root, url: str) -> Bookmark | None {
    wanted = normalize_url(url);
    # A bookmark saved with no normal form (an empty one) is found by its exact URL.
    for bookmark in [owner --> [?:Bookmark]] {
        if bookmark.url_normalized == wanted
            or (bookmark.url_normalized == "" and bookmark.url == url)
        {
            return bookmark;
        }
    }
    return None;
}

impl create_bookmark(owner: Root, draft: BookmarkDraft) -> Bookmark {
    existing = find_existing(owner, draft.url);
    if existing is not None {
        return update_bookmark(owner, existing, draft);
    }
    stamp = now_utc();
    made = owner ++> Bookmark(
        id=next_bookmark_id(owner),
        url=draft.url,
        url_normalized=normalize_url(draft.url),
        date_added=stamp,
        date_modified=stamp,
        title=draft.title,
        description=draft.description,
        notes=draft.notes,
        unread=draft.unread,
        shared=draft.shared,
        is_archived=draft.is_archived,
    );
    set_tags(owner, made, draft.tag_string);
    return made;
}

impl update_bookmark(owner: Root, bookmark: Bookmark, draft: BookmarkDraft) -> Bookmark {
    bookmark.url = draft.url;
    bookmark.url_normalized = normalize_url(draft.url);
    bookmark.title = draft.title;
    bookmark.description = draft.description;
    bookmark.notes = draft.notes;
    bookmark.unread = draft.unread;
    bookmark.shared = draft.shared;
    bookmark.is_archived = draft.is_archived;
    touch(bookmark);
    set_tags(owner, bookmark, draft.tag_string);
    return bookmark;
}

impl touch(bookmark: Bookmark) {
    bookmark.date_modified = now_utc();
}

impl set_archived(bookmark: Bookmark, archived: bool) -> Bookmark {
    bookmark.is_archived = archived;
    touch(bookmark);
    return bookmark;
}

impl delete_bookmark(bookmark: Bookmark) {
    for asset in [bookmark ->:HasAsset:->] {
        remove(asset);
    }
    remove(bookmark);
}

impl list_bookmarks(owner: Root) -> list[Bookmark] {
    return [owner --> [?:Bookmark]];
}

impl tag_names_of(bookmark: Bookmark) -> list[str] {
    return sorted([t.name for t in [bookmark ->:Tagged:->]], key=name_key);
}

impl tag_counts(owner: Root) -> dict[str, int] {
    counts: dict[str, int] = {};
    for tag in sorted([owner --> [?:Tag]], key=tag_name_key) {
        counts[tag.name] = len([tag <-:Tagged:<-]);
    }
    return counts;
}

impl find_bookmark(owner: Root, bookmark_id: int) -> Bookmark | None {
    for bookmark in [owner --> [?:Bookmark]] {
        if bookmark.id == bookmark_id {
            return bookmark;
        }
    }
    return None;
}

impl draft_of(bookmark: Bookmark) -> BookmarkDraft {
    return BookmarkDraft(
        url=bookmark.url,
        title=bookmark.title,
        description=bookmark.description,
        notes=bookmark.notes,
        unread=bookmark.unread,
        shared=bookmark.shared,
        is_archived=bookmark.is_archived,
        tag_string=",".join(tag_names_of(bookmark)),
    );
}

impl tag_name_key(tag: Tag) -> str {
    return name_key(tag.name);
}
