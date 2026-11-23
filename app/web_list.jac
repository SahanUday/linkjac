"""Web list: one page of the caller's bookmarks, and the tags of what matched, as the bookmark list page shows them."""

"""A bookmark as the list page shows it."""
obj ListedBookmark {
    has id: int = 0,
        url: str = "",
        title: str = "",
        description: str = "",
        tag_names: list[str] = [],
        is_archived: bool = False;
}

"""A tag of the matched bookmarks and how many of them carry it."""
obj ListedTag {
    has name: str = "",
        count: int = 0;
}

"""What the list page shows: one page of bookmarks, how many pages there are, and the tags of all the matches."""
obj ListPage {
    has items: list[ListedBookmark] = [],
        tags: list[ListedTag] = [],
        page: int = 1,
        pages: int = 1,
        total: int = 0;
}

"""The caller's bookmarks that match `q`, page `page` of them (counted from 1), as the profile's page size cuts them."""
def:protect bookmark_page(q: str, page: int, archived: bool = False) -> ListPage;

"""The tags of `found` with the number of bookmarks carrying each, in name order."""
def tags_of_matches(found: list[Bookmark]) -> list[ListedTag];
