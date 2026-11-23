"""Netscape import: the bookmarks of a Netscape file made or updated for one owner, the way linkding imports them."""

# WORKAROUND(GAP-028): names wired in for netscape_import.test.jac only; E1146 flags them under bare check unless listed here.
glob __all__: list[str] = ["epoch_of", "delete_bookmark", "export_netscape"];

"""How many bookmarks a file listed, how many were imported and how many were refused."""
obj ImportResult {
    has total: int = 0,
        success: int = 0,
        failed: int = 0;
}

"""Make every tag the file names that `owner` lacks; names over 64 characters are left out."""
def make_missing_tags(owner: Root, listed: list[NetscapeBookmark]);

"""Whether a listed bookmark would be refused: a bad URL, a title too long or a date that is not a timestamp."""
def is_refused(listed: NetscapeBookmark) -> bool;

"""Link `bookmark` to the tags named, keeping the tags it has."""
def add_tags(owner: Root, bookmark: Bookmark, names: list[str]);

"""Save one listed bookmark for `owner`: change the one with the same normalized URL, or make a new one."""
def save_listed(owner: Root, listed: NetscapeBookmark, map_private_flag: bool);

"""Import the bookmarks of a Netscape file for `owner`; with `map_private_flag`, a bookmark marked not private becomes shared."""
def import_netscape(owner: Root, text: str, map_private_flag: bool = False) -> ImportResult;
