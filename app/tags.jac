"""Tags: the nodes that label bookmarks, how their names are written, and finding or making one."""

import from datetime { datetime }

node Tag {
    has name: str,
        date_added: datetime;
}

"""A tag name with outer spaces cut and inner spaces made hyphens."""
def sanitize_tag_name(name: str) -> str;

"""The distinct names in comma-separated text, sanitized, ignoring case, sorted by lower-case name."""
def parse_tag_string(text: str, delimiter: str = ",") -> list[str];

"""The tag of `owner` with this name, ignoring case, or None."""
def find_tag(owner: Root, called: str) -> Tag | None;

"""The tag of `owner` with this name, made when there is none."""
def find_or_make_tag(owner: Root, called: str) -> Tag;
