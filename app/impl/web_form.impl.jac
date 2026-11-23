impl save_bookmark(
    url: str, title: str, description: str, notes: str, tag_string: str, unread: bool
) -> SaveResult {
    address = url.strip();
    if not is_valid_url(address) {
        return SaveResult(url_error="Enter a valid URL.");
    }
    create_bookmark(
        root,
        BookmarkDraft(
            url=address,
            title=title,
            description=description,
            notes=notes,
            unread=unread,
            tag_string=tag_string.replace(" ", ","),
        ),
    );
    return SaveResult(saved=True);
}
