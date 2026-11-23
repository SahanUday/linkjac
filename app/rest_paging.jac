"""Paging: the limit and offset of a list request, and the page linkding's API wraps around a list."""

"""Where a page starts and how many it holds."""
obj PageWindow {
    has limit: int,
        offset: int;
}

"""The window a request asked for, 100 at the start unless `limit` and `offset` say otherwise."""
def window_of(call: ApiCall) -> PageWindow;

"""The page object: the count, the links to the next and previous page, and the rows of this page."""
def page_of(
    call: ApiCall, route: str, window: PageWindow, count: int, results: list[dict[str, any]]
) -> dict[str, any];
