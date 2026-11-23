impl save(url: str, title: str, tag_string: str) -> str {
    return jid(
        create_bookmark(root.shared, BookmarkDraft(url=url, title=title, tag_string=tag_string))
    );
}

impl titles -> list[str] {
    return [b.title for b in list_bookmarks(root.shared)];
}

impl find(text: str) -> list[str] {
    return [b.title for b in search_bookmarks(root.shared, BookmarkFilter(text=text))];
}

impl tags -> dict[str, int] {
    return tag_counts(root.shared);
}

impl set_theme(theme: str) {
    profile_of(root.shared).theme = theme;
}

impl theme -> str {
    return profile_of(root.shared).theme;
}
