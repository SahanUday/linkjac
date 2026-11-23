"""Bookmark form: the fields of one bookmark and the Save and Cancel buttons, for the add and edit pages."""

import from "@jac/runtime" { navigate }

# WORKAROUND(GAP-047): the initial values come in as `url0`, `tags0`, ...; a prop named like its `has` passes check and fails the build.
"""The form for bookmark `bookmark_id` (0 for a new one), starting from the values given."""
def:pub BookmarkForm(
    bookmark_id: int = 0,
    url0: str = "",
    tags0: str = "",
    title0: str = "",
    description0: str = "",
    notes0: str = "",
    unread0: bool = False,
) -> JsxElement;
