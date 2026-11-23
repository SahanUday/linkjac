"""Admin calls: what a command-line app asks the server to do with the bookmarks of the account it is signed in as."""

"""Import a Netscape file for the caller; the answer has the counts `total`, `success` and `failed`."""
def:protect import_bookmarks(text: str, map_private_flag: bool = False) -> dict[str, int];

"""The caller's bookmarks as a Netscape file."""
def:protect export_bookmarks -> str;
