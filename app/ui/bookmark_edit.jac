"""Bookmark edit: the heading and form for changing one bookmark, filled from the server, or a note that it is missing."""

import from "@jac/runtime" { sign_in }

"""The edit page's content for bookmark `bookmark_id`."""
def:pub EditBookmark(bookmark_id: int) -> JsxElement;
