"""Search: a query string and filters turned into the bookmarks of one owner that match, in order."""

import from datetime { datetime }

# WORKAROUND(GAP-028): names wired in for search.test.jac only; E1146 flags them under bare check unless listed here.
glob __all__: list[str] = ["BookmarkDraft", "create_bookmark", "set_archived"];

"""A query string split into plain terms, `#tag` names and the `!untagged` and `!unread` words."""
obj ParsedQuery {
    has terms: list[str] = [],
        tag_names: list[str] = [],
        untagged: bool = False,
        unread: bool = False;
}

"""What a list of bookmarks is narrowed and ordered by; `unread` and `shared` are "off", "yes" or "no"; `legacy` reads the text as all-terms-must-match, `lax` lets a term match a tag name."""
obj BookmarkFilter {
    has text: str = "",
        archived: bool = False,
        unread: str = "off",
        shared: str = "off",
        sort: str = "added_desc",
        added_since: str = "",
        modified_since: str = "",
        legacy: bool = False,
        lax: bool = False;
}

"""Split a query string the way linkding's legacy search does."""
def parse_query_string(text: str) -> ParsedQuery;

"""The bookmarks of all `owners` that match every term and tag of the filter, in the filter's order."""
def search_many(owners: list[Root], narrowing: BookmarkFilter) -> list[Bookmark];

"""The bookmarks of `owner` that match every term and tag of the filter, in the filter's order."""
def search_bookmarks(owner: Root, narrowing: BookmarkFilter) -> list[Bookmark];

"""Whether a "yes" or "no" choice rules a bookmark out, given its flag; any other choice rules out nothing."""
def refuses_choice(choice: str, flag: bool) -> bool;

"""Whether a bookmark is in the archived state asked for and passes the unread, shared and date limits of the filter."""
def passes_flags(bookmark: Bookmark, narrowing: BookmarkFilter) -> bool;

"""Whether a bookmark has every term, tag and keyword of a legacy query."""
def matches_legacy(bookmark: Bookmark, parsed: ParsedQuery) -> bool;

"""Whether `stamp` is at or before the time `limit` names."""
def not_after(limit: str, stamp: datetime) -> bool;

"""A bookmark's title, or its URL when it has none, in lower case, for sorting."""
def title_key(bookmark: Bookmark) -> str;

"""When a bookmark was added, for sorting."""
def added_key(bookmark: Bookmark) -> datetime;

"""When a bookmark was last changed, for sorting."""
def modified_key(bookmark: Bookmark) -> datetime;

"""The bookmarks sorted by `order`: added, modified or title, ascending or descending."""
def in_order(found: list[Bookmark], order: str) -> list[Bookmark];
