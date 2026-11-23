"""Web actions: archiving, unarchiving and removing one bookmark of the caller from the list page."""

# WORKAROUND(GAP-028): names wired in for web_actions.test.jac only; E1146 flags them under bare check unless listed here.
glob __all__: list[str] = ["BookmarkDraft", "create_bookmark"];

"""Archive the caller's bookmark `bookmark_id`, or unarchive it when `archived` is False; False when there is no such bookmark."""
def:protect archive_bookmark(bookmark_id: int, archived: bool) -> bool;

"""Remove the caller's bookmark `bookmark_id`; False when there is no such bookmark."""
def:protect remove_bookmark(bookmark_id: int) -> bool;
