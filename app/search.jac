"""Search: a query string and filters turned into the bookmarks of one owner that match, in order."""

import from datetime { datetime }

# WORKAROUND(GAP-028): names wired in for search.test.jac only; E1146 flags them under bare check unless listed here.
glob __all__: list[str] = ["BookmarkDraft", "create_bookmark", "archive_bookmark"];

"""A query string split into plain terms, `#tag` names and the `!untagged` and `!unread` words."""
obj ParsedQuery {
    has terms: list[str] = [],
        tag_names: list[str] = [],
        untagged: bool = False,
        unread: bool = False;
}

"""What a list of bookmarks is narrowed and ordered by; `unread` and `shared` are "off", "yes" or "no"."""
obj BookmarkFilter {
    has text: str = "",
        archived: bool = False,
        unread: str = "off",
        shared: str = "off",
        sort: str = "added_desc";
}

"""Split a query string the way linkding's legacy search does."""
def parse_query_string(text: str) -> ParsedQuery;

"""The bookmarks of `owner` that match every term and tag of the filter, in the filter's order."""
def search_bookmarks(owner: Root, narrowing: BookmarkFilter) -> list[Bookmark];
