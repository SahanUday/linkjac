"""Tag routes: /api/tags/ and /api/tags/<id>/ as linkding's API answers them."""

"""The reply to a request whose path starts with tags, for the tags of `owner`."""
def tags_route(call: ApiCall, owner: Root) -> ApiReply;
