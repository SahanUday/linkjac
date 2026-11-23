"""Persistence check endpoints: save, search, tag and profile calls on the shared root."""

def:pub save(url: str, title: str, tag_string: str) -> str;

def:pub titles -> list[str];

def:pub find(text: str) -> list[str];

def:pub tags -> dict[str, int];

def:pub set_theme(theme: str);

def:pub theme -> str;
