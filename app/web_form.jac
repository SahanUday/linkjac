"""Web form: saving one bookmark from the add and edit pages, and the answer that tells the page whether it was saved."""

"""Whether a save went through, and the message to show beside the address when it did not."""
obj SaveResult {
    has saved: bool = False,
        url_error: str = "";
}

"""The fields of one bookmark as the form shows them; `found` is False when the caller has no such bookmark."""
obj BookmarkFields {
    has found: bool = False,
        url: str = "",
        title: str = "",
        description: str = "",
        notes: str = "",
        tag_string: str = "",
        unread: bool = False;
}

"""The fields of the caller's bookmark `bookmark_id`, with its tags separated by spaces."""
def:protect bookmark_fields(bookmark_id: int) -> BookmarkFields;

"""Save a bookmark for the caller: change bookmark `bookmark_id`, or with 0 make a new one (or change the one with the same address); tags are separated by spaces."""
def:protect save_bookmark(
    bookmark_id: int,
    url: str,
    title: str,
    description: str,
    notes: str,
    tag_string: str,
    unread: bool,
) -> SaveResult;
