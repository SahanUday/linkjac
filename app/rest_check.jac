"""Check route: /api/bookmarks/check/, what a page says about itself and the bookmark that already has its address."""

"""The reply to GET /api/bookmarks/check/?url=..., for the bookmarks of `owner`."""
def check_route(call: ApiCall, owner: Root) -> ApiReply;
