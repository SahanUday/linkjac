"""Words: the parts of an `Authorization` header that offers a token, read the one way linkding reads it."""

"""The words of `header` when its first one is `Token` or `Bearer` in any case, else none."""
def token_words(header: str) -> list[str];
