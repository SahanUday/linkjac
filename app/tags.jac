"""Tags: the nodes that label bookmarks, how their names are written, and finding or making one."""

import from datetime { datetime }

node Tag {
    has id: int,
        name: str,
        date_added: datetime;
}

"""The id of a tag, for sorting."""
def tag_id_of(tag: Tag) -> int;

"""The form of a tag name that names compare by: lower case."""
def name_key(name: str) -> str;

"""A tag name with outer spaces cut and inner spaces made hyphens."""
def sanitize_tag_name(name: str) -> str;

"""The distinct names in comma-separated text, sanitized, ignoring case, sorted by lower-case name."""
def parse_tag_string(text: str, delimiter: str = ",") -> list[str];

"""The tag of `owner` with this name, ignoring case, or None."""
def find_tag(owner: Root, called: str) -> Tag | None;

"""The tag of `owner` with this id, or None."""
def find_tag_by_id(owner: Root, tag_id: int) -> Tag | None;

"""Every tag of `owner`, oldest first."""
def list_tags(owner: Root) -> list[Tag];

"""Take a tag out of the graph with its links; the bookmarks that had it stay."""
def delete_tag(tag: Tag);

"""Give a tag the sanitized name `called`; False, and no change, when that is empty or another tag has the name already."""
def rename_tag(owner: Root, tag: Tag, called: str) -> bool;

"""The tag of `owner` with this name, made when there is none."""
def find_or_make_tag(owner: Root, called: str) -> Tag;
