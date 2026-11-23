impl save(url: str, title: str, tag_string: str) -> str {
    return jid(
        create_bookmark(root.shared, BookmarkDraft(url=url, title=title, tag_string=tag_string))
    );
}

impl titles -> list[str] {
    return [b.title for b in list_bookmarks(root.shared)];
}
