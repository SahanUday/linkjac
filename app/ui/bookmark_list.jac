"""Bookmark list: the caller's bookmarks with a search box, a tags region and paging, as shown at /bookmarks."""

import from "@jac/runtime" { sign_in, useSearchParams }

"""One bookmark of the list: its title, its tags, its description and what can be done to it; `on_archive(id, archived)` and `on_remove(id)` are called by its buttons."""
def:pub BookmarkRow(item: ListedBookmark, on_archive: any, on_remove: any) -> JsxElement;

"""The address of page `number` of the list at `base` for the query `q`."""
def page_href(base: str, q: str, number: int) -> str;

"""The caller's live bookmarks, or the archived ones when `archived` is set."""
def:pub BookmarkList(archived: bool = False) -> JsxElement;
