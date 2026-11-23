"""Asset routes: /api/bookmarks/<id>/assets/ and what is below it, as linkding's API answers them, for the snapshots of one bookmark."""

"""The reply to a request for the assets of `bookmark` (`segments` is what follows `assets` in the path): the list, one asset, its download or its removal."""
def assets_route(call: ApiCall, bookmark: Bookmark, segments: list[str]) -> ApiReply;
