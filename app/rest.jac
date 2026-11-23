"""REST entry: the one endpoint the transport hands every /api/ request to, and the routing of it by path."""

"""Answer a request to /api/ from a caller who is not signed in: the routes linkding lets anyone read, and 401 for the rest."""
def:pub handle_public(method: str, path: str, query: str, body: str, origin: str) -> ApiReply;

"""Answer one request to /api/ for the caller: `path` is the whole path, `query` the text after the question mark."""
def:protect handle(method: str, path: str, query: str, body: str, origin: str) -> ApiReply;
