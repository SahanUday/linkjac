"""Ids: the counters that give bookmarks and tags the whole-number ids linkding's API shows."""

node IdCounter {
    has last_bookmark: int = 0,
        last_tag: int = 0;
}

"""The counter node of `owner`, made the first time."""
def counter_of(owner: Root) -> IdCounter;

"""A bookmark id of `owner` that was never given before."""
def next_bookmark_id(owner: Root) -> int;

"""A tag id of `owner` that was never given before."""
def next_tag_id(owner: Root) -> int;
