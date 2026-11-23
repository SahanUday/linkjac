impl has_text(bookmark: Bookmark, term: str) -> bool {
    needle = term.lower();
    return any([
        needle in f.lower()
        for f in [bookmark.title, bookmark.description, bookmark.notes, bookmark.url]
    ]);
}

impl has_tag(bookmark: Bookmark, name: str) -> bool {
    return name_key(name) in [name_key(n) for n in tag_names_of(bookmark)];
}
