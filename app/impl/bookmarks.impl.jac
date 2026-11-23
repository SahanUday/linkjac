import from datetime { timezone }
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
    stamp = datetime.now(timezone.utc);
    made = owner ++> Bookmark(
        url=draft.url,
        url_normalized=normalize_url(draft.url),
        date_added=stamp,
        date_modified=stamp,
        title=draft.title,
        description=draft.description,
        notes=draft.notes,
        unread=draft.unread,
        shared=draft.shared,
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
    bookmark.date_modified = datetime.now(timezone.utc);
    set_tags(owner, bookmark, draft.tag_string);
    return bookmark;
}

impl archive_bookmark(bookmark: Bookmark) -> Bookmark {
    bookmark.is_archived = True;
    bookmark.date_modified = datetime.now(timezone.utc);
    return bookmark;
}

impl unarchive_bookmark(bookmark: Bookmark) -> Bookmark {
    bookmark.is_archived = False;
    bookmark.date_modified = datetime.now(timezone.utc);
    return bookmark;
}

impl delete_bookmark(bookmark: Bookmark) {
    remove(bookmark);
}

impl list_bookmarks(owner: Root) -> list[Bookmark] {
    return [owner --> [?:Bookmark]];
}

impl tag_names_of(bookmark: Bookmark) -> list[str] {
    return sorted(
        [t.name for t in [bookmark ->:Tagged:->]], key=lambda (n: str) -> str { n.lower() }
    );
}

impl tag_counts(owner: Root) -> dict[str, int] {
    counts: dict[str, int] = {};
    for tag in [owner --> [?:Tag]] {
        counts[tag.name] = len([tag <-:Tagged:<-]);
    }
    return counts;
}
