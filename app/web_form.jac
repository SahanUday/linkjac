"""Web form: saving one bookmark from the add and edit pages, and the answer that tells the page whether it was saved."""

"""Whether a save went through, and the message to show beside the address when it did not."""
obj SaveResult {
    has saved: bool = False,
        url_error: str = "";
}

"""Save a bookmark for the caller: change the one with the same address, or make a new one; tags are separated by spaces."""
def:protect save_bookmark(
    url: str, title: str, description: str, notes: str, tag_string: str, unread: bool
) -> SaveResult;
