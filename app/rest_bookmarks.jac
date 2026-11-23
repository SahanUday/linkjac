"""Bookmark routes: /api/bookmarks/ and /api/bookmarks/<id>/ as linkding's API answers them."""

"""The reply to GET /api/bookmarks/shared/: the shared bookmarks of everyone who shares; `public_only` is for a caller who is not signed in."""
def shared_route(call: ApiCall, public_only: bool) -> ApiReply;

"""The reply to a request whose path starts with bookmarks, for the bookmarks of `owner`."""
def bookmarks_route(call: ApiCall, owner: Root) -> ApiReply;
