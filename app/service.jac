"""Persistence check endpoints: save and list bookmarks on the shared root."""

def:pub save(url: str, title: str, tag_string: str) -> str;

def:pub titles -> list[str];
