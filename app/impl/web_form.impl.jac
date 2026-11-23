impl bookmark_fields(bookmark_id: int) -> BookmarkFields {
    bookmark = find_bookmark(root, bookmark_id);
    if bookmark is None {
        return BookmarkFields();
    }
    return BookmarkFields(
        found=True,
        url=bookmark.url,
        title=bookmark.title,
        description=bookmark.description,
        notes=bookmark.notes,
        tag_string=" ".join(tag_names_of(bookmark)),
        unread=bookmark.unread,
    );
}

impl save_bookmark(
    bookmark_id: int,
    url: str,
    title: str,
    description: str,
    notes: str,
    tag_string: str,
    unread: bool,
) -> SaveResult {
    address = url.strip();
    if not is_valid_url(address) {
        return SaveResult(url_error="Enter a valid URL.");
    }
    draft = BookmarkDraft(
        url=address,
        title=title,
        description=description,
        notes=notes,
        unread=unread,
        tag_string=tag_string.replace(" ", ","),
    );
    existing = find_bookmark(root, bookmark_id) if bookmark_id != 0 else None;
    if bookmark_id != 0 and existing is None {
        return SaveResult(url_error="This bookmark does not exist.");
    }
    if existing is None {
        create_bookmark(root, draft);
    } else {
        update_bookmark(root, existing, draft);
    }
    return SaveResult(saved=True);
}
