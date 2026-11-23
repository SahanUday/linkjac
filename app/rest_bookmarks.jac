"""Bookmark routes: /api/bookmarks/ and /api/bookmarks/<id>/ as linkding's API answers them."""

"""The reply to a request whose path starts with bookmarks, for the bookmarks of `owner`."""
def bookmarks_route(call: ApiCall, owner: Root) -> ApiReply;
