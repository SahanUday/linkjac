"""Static route: a kept favicon at /static/<file>, answered as a file."""

"""The reply to GET /static/<file>."""
def static_route(method: str, path: str) -> ApiReply;
