"""URLs: the normal form linkding compares bookmarks by."""

"""The URL with a lower-case scheme and host, no trailing slash on the path and sorted query parameters."""
def normalize_url(url: str) -> str;

"""Whether a text is an address linkding accepts for a bookmark: an http, https, ftp or ftps URL with a host."""
def is_valid_url(url: str) -> bool;
