"""Bookmarks: the nodes that hold a saved link, their tag links, and making, changing and removing them."""

import from datetime { datetime }

node Bookmark {
    has id: int,
        url: str,
        url_normalized: str,
        date_added: datetime,
        date_modified: datetime,
        title: str = "",
        description: str = "",
        notes: str = "",
        unread: bool = False,
        is_archived: bool = False,
        shared: bool = False;
}

edge Tagged: Bookmark --> Tag {}

"""What a client gives to save or change a bookmark, with tags as comma-separated text."""
obj BookmarkDraft {
    has url: str,
        title: str = "",
        description: str = "",
        notes: str = "",
        unread: bool = False,
        shared: bool = False,
        is_archived: bool = False,
        tag_string: str = "";
}

"""Make the links from `bookmark` to the tags named in the text, dropping the old ones."""
def set_tags(owner: Root, bookmark: Bookmark, tag_string: str);

"""The bookmark of `owner` whose URL normalizes like `url`, or None."""
def find_existing(owner: Root, url: str) -> Bookmark | None;

"""The bookmark of `owner` with this id, or None."""
def find_bookmark(owner: Root, bookmark_id: int) -> Bookmark | None;

"""A draft that carries every field of `bookmark` as it is now, so a partial change can start from it."""
def draft_of(bookmark: Bookmark) -> BookmarkDraft;

"""Save a draft: change the bookmark that has the same normalized URL, or make a new one."""
def create_bookmark(owner: Root, draft: BookmarkDraft) -> Bookmark;

"""Replace every field of `bookmark` the draft carries, and its tags, and stamp the change."""
def update_bookmark(owner: Root, bookmark: Bookmark, draft: BookmarkDraft) -> Bookmark;

"""Stamp a bookmark as changed now."""
def touch(bookmark: Bookmark);

"""Mark a bookmark archived or not archived, and stamp the change."""
def set_archived(bookmark: Bookmark, archived: bool) -> Bookmark;

"""Take a bookmark out of the graph with its links; its tags stay."""
def delete_bookmark(bookmark: Bookmark);

"""Every bookmark under `owner`, in the order they were made."""
def list_bookmarks(owner: Root) -> list[Bookmark];

"""The names of the tags of one bookmark, sorted ignoring case."""
def tag_names_of(bookmark: Bookmark) -> list[str];

"""The tag's name in the form names compare by."""
def tag_name_key(tag: Tag) -> str;

"""Every tag of `owner` with the number of bookmarks that carry it, by name ignoring case."""
def tag_counts(owner: Root) -> dict[str, int];
