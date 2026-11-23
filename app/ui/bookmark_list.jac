"""Bookmark list: the caller's bookmarks with a search box, a tags region and paging, as shown at /bookmarks."""

import from "@jac/runtime" { sign_in, useSearchParams }

"""One bookmark of the list: its title, its tags, its description and what can be done to it."""
def:pub BookmarkRow(item: ListedBookmark) -> JsxElement;

"""The address of page `number` of the list for the query `q`."""
def page_href(q: str, number: int) -> str;

def:pub BookmarkList -> JsxElement;
