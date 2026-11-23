"""User routes: /api/user/profile/ as linkding's API answers it."""

"""The reply to a request whose path starts with user, for the caller `owner`."""
def user_route(call: ApiCall, owner: Root) -> ApiReply;
