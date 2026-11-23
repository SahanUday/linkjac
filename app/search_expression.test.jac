def kinds(query: str) -> list[str] {
    return [t.kind for t in tokenize(query)];
}

def sample(title: str, tags: str = "", unread: bool = False) -> Bookmark {
    return create_bookmark(
        root,
        BookmarkDraft(
            url="https://expr.example/" + title, title=title, tag_string=tags, unread=unread
        ),
    );
}

def holds(query: str, bookmark: Bookmark, lax: bool = False) -> bool {
    tree = parse_expression(query).tree;
    return tree is not None and node_matches(tree, bookmark, lax);
}

test "a query is cut into terms, tags, keywords, operators, parentheses and quoted terms" {
    assert kinds("a AND b or not (c) #t !unread \"x y\"") == [
        "term",
        "and",
        "term",
        "or",
        "not",
        "open",
        "term",
        "close",
        "tag",
        "keyword",
        "term",
    ];
    assert [t.text for t in tokenize("'it\\'s' \"a\\tb\"")] == ["it's", "a\tb"];
    assert [t.text for t in tokenize("\"unclosed phrase")] == ["unclosed phrase"];
    assert kinds("# ! #") == [];
}

test "and binds tighter than or, not tighter than both, and parentheses group" {
    assert parse_expression("a or b and c").tree.kind == "or";
    assert parse_expression("a b or c").tree.kind == "or";
    assert parse_expression("not a b").tree.kind == "and";
    assert parse_expression("(a or b) c").tree.kind == "and";
    assert parse_expression("").tree is None;
}

test "a query that cannot be read is invalid" {
    for query in ["(a", "a)", "a and", "or a", "()", "not"] {
        assert not parse_expression(query).valid;
    }
}

test "terms, tags and keywords are tested on a bookmark, ignoring case" {
    tagged = sample("ex-one", "Red, blue", True);
    plain = sample("ex-two");
    assert holds("EX-ONE", tagged) and not holds("ex-one", plain);
    assert holds("#red #BLUE", tagged) and not holds("#red", plain);
    assert holds("!unread", tagged) and not holds("!unread", plain);
    assert holds("!untagged ex-two", plain) and not holds("!untagged", tagged);
    assert holds("!nosuch", plain);
    assert holds("ex-one or ex-two", plain) and not holds("not (ex-one or ex-two)", plain);
    assert not holds("red", tagged) and holds("red", tagged, True);
}
