"""Call: one REST request as the router sees it: the method, the path below /api/, the query values and the body."""

"""A request to /api/ with its path split into segments and its query read into values."""
obj ApiCall {
    has method: str,
        segments: list[str],
        query: dict[str, str],
        body: str,
        origin: str;
}

"""The call for a request: `path` is the whole path, `query` the text after the question mark."""
def make_call(method: str, path: str, query: str, body: str, origin: str) -> ApiCall;

"""The value of a query parameter, or `fallback` when it is not there."""
def query_value(call: ApiCall, name: str, fallback: str = "") -> str;

"""The id a path segment names, or 0 for one that is not a plain number that fits; ids start at 1, so 0 finds nothing."""
def id_in_path(text: str) -> int;

"""The body read as a JSON object, or None when it is not one."""
def body_object(call: ApiCall) -> dict[str, any] | None;
