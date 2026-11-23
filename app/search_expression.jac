"""Search expression: linkding's search language (and, or, not, quotes, parentheses, #tags, !keywords) read into a tree and tested on a bookmark."""

# WORKAROUND(GAP-028): names wired in for search_expression.test.jac only; E1146 flags them under bare check unless listed here.
glob __all__: list[str] = ["BookmarkDraft", "create_bookmark"];

"""One word of a query: its kind (term, tag, keyword, and, or, not, open, close) and its text."""
obj Token {
    has kind: str,
        text: str = "";
}

"""One node of the tree a query is read into: a leaf (term, tag, keyword) or and, or, not over its parts."""
obj SearchNode {
    has kind: str,
        text: str = "",
        left: SearchNode | None = None,
        right: SearchNode | None = None;
}

"""The tree of a query, None for an empty one, and whether the query could be read at all."""
obj ExpressionReading {
    has tree: SearchNode | None = None,
        valid: bool = True;
}

"""A query cut into tokens the way linkding's tokenizer cuts it."""
def tokenize(query: str) -> list[Token];

"""A query read into a tree; `valid` is False for one linkding refuses (it then finds nothing)."""
def parse_expression(query: str) -> ExpressionReading;

"""Whether a bookmark satisfies the tree; with `lax`, a plain term also matches a tag name."""
def node_matches(part: SearchNode, bookmark: Bookmark, lax: bool) -> bool;
