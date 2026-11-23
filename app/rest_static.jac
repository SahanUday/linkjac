"""Static route: a kept favicon at /static/<file>, answered with its content type and bytes as base64 for the transport to unpack."""

"""The reply to GET /static/<file>."""
def static_route(method: str, path: str) -> ApiReply;
