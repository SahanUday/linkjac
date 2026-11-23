impl tags_of_matches(found: list[Bookmark]) -> list[ListedTag] {
    counts: dict[str, int] = {};
    for bookmark in found {
        for name in tag_names_of(bookmark) {
            counts[name] = counts.get(name, 0) + 1;
        }
    }
    return [ListedTag(name=n, count=counts[n]) for n in sorted(counts.keys(), key=name_key)];
}

impl bookmark_page(q: str, page: int, archived: bool = False) -> ListPage {
    profile = profile_of(root);
    found = search_bookmarks(
        root,
        BookmarkFilter(
            text=q, archived=archived, legacy=profile.legacy_search, lax=profile.tag_search == "lax"
        ),
    );
    size = profile.items_per_page;
    pages = max(1, (len(found) + size - 1) // size);
    shown = min(max(page, 1), pages);
    window = found[(shown - 1) * size:shown * size];
    return ListPage(
        items=[
            ListedBookmark(
                id=b.id,
                url=b.url,
                title=b.title,
                description=b.description,
                tag_names=tag_names_of(b),
                is_archived=b.is_archived,
            )
            for b in window
        ],
        tags=tags_of_matches(found),
        page=shown,
        pages=pages,
        total=len(found),
    );
}
