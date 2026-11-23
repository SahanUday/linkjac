"""Netscape export: a list of bookmarks written as a Netscape bookmark file, the way linkding writes one."""

import html;

# WORKAROUND(GAP-028): names wired in for netscape_export.test.jac only; E1146 flags them under bare check unless listed here.
glob __all__: list[str] = ["BookmarkDraft", "create_bookmark", "set_archived", "read_epoch"];

"""The text of a Netscape bookmark file that lists these bookmarks, in order."""
def export_netscape(bookmarks: list[Bookmark]) -> str;

"""The line, and the description line when there is one, that write one bookmark."""
def bookmark_lines(bookmark: Bookmark) -> list[str];
