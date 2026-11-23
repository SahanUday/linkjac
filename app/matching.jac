"""Matching: whether a bookmark's text or tags hold a given term or tag name, ignoring case."""

"""Whether the term is in the title, description, notes or URL of the bookmark."""
def has_text(bookmark: Bookmark, term: str) -> bool;

"""Whether the bookmark carries a tag of this name."""
def has_tag(bookmark: Bookmark, name: str) -> bool;
