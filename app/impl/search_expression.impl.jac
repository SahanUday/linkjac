glob term_stops: str = "()\"'#!",
     word_stops: str = "()\"'";

"""Where a run of characters that is not blank and holds none of `stops` ends, from `start`."""
def run_end(text: str, start: int, stops: str) -> int {
    at = start;
    while at < len(text) and not text[at].isspace() and text[at] not in stops {
        at += 1;
    }
    return at;
}

def unescaped(mark: str, quote: str) -> str {
    if mark == "n" {
        return "\n";
    }
    if mark == "t" {
        return "\t";
    }
    if mark == "r" {
        return "\r";
    }
    return mark;
}

"""The text of a quoted string whose opening quote is at `start`, and where it ends; an unclosed one runs to the end."""
def read_quoted(text: str, start: int) -> tuple[str, int] {
    quote = text[start];
    content = "";
    at = start + 1;
    while at < len(text) and text[at] != quote {
        if text[at] == "\\" {
            at += 1;
            if at < len(text) {
                content += unescaped(text[at], quote);
                at += 1;
            }
        } else {
            content += text[at];
            at += 1;
        }
    }
    return (content, at + 1 if at < len(text) else at);
}

def operator_kind(word: str) -> str {
    lowered = word.lower();
    return lowered if lowered in ["and", "or", "not"] else "term";
}

impl tokenize(query: str) -> list[Token] {
    text = query.strip();
    tokens: list[Token] = [];
    at = 0;
    while at < len(text) {
        mark = text[at];
        if mark.isspace() {
            at += 1;
        } elif mark == "(" or mark == ")" {
            tokens.append(Token(kind="open" if mark == "(" else "close", text=mark));
            at += 1;
        } elif mark == "\"" or mark == "'" {
            (content, at) = read_quoted(text, at);
            tokens.append(Token(kind="term", text=content));
        } elif mark == "#" or mark == "!" {
            end = run_end(text, at + 1, word_stops);
            if end > at + 1 {
                tokens.append(
                    Token(kind="tag" if mark == "#" else "keyword", text=text[at + 1:end])
                );
            }
            at = end if end > at + 1 else at + 1;
        } else {
            end = run_end(text, at, term_stops);
            word = text[at:end];
            tokens.append(Token(kind=operator_kind(word), text=word));
            at = end;
        }
    }
    return tokens;
}

"""A reader over the tokens of one query, which parse functions move along."""
obj Reader {
    has tokens: list[Token],
        at: int = 0;
}

def peek_kind(reader: Reader) -> str {
    return reader.tokens[reader.at].kind if reader.at < len(reader.tokens) else "end";
}

def starts_operand(kind: str) -> bool {
    return kind in ["term", "tag", "keyword", "open", "not"];
}

def parse_not(reader: Reader) -> SearchNode {
    kind = peek_kind(reader);
    if kind == "not" {
        reader.at += 1;
        return SearchNode(kind="not", left=parse_not(reader));
    }
    if kind == "open" {
        reader.at += 1;
        inner = parse_or(reader);
        if peek_kind(reader) != "close" {
            raise ValueError("expected a closing parenthesis");
        }
        reader.at += 1;
        return inner;
    }
    if kind in ["term", "tag", "keyword"] {
        token = reader.tokens[reader.at];
        reader.at += 1;
        return SearchNode(kind=kind, text=token.text);
    }
    raise ValueError("unexpected " + kind);
}

def parse_and(reader: Reader) -> SearchNode {
    left = parse_not(reader);
    while peek_kind(reader) == "and" or starts_operand(peek_kind(reader)) {
        if peek_kind(reader) == "and" {
            reader.at += 1;
        }
        left = SearchNode(kind="and", left=left, right=parse_not(reader));
    }
    return left;
}

def parse_or(reader: Reader) -> SearchNode {
    left = parse_and(reader);
    while peek_kind(reader) == "or" {
        reader.at += 1;
        left = SearchNode(kind="or", left=left, right=parse_and(reader));
    }
    return left;
}

impl parse_expression(query: str) -> ExpressionReading {
    tokens = tokenize(query);
    if not tokens {
        return ExpressionReading();
    }
    reader = Reader(tokens=tokens);
    try {
        tree = parse_or(reader);
        if reader.at < len(tokens) {
            raise ValueError("unexpected " + peek_kind(reader));
        }
    } except ValueError {
        return ExpressionReading(valid=False);
    }
    return ExpressionReading(tree=tree);
}

def has_text(bookmark: Bookmark, term: str) -> bool {
    needle = term.lower();
    return any([
        needle in f.lower()
        for f in [bookmark.title, bookmark.description, bookmark.notes, bookmark.url]
    ]);
}

def has_tag(bookmark: Bookmark, name: str) -> bool {
    return name.lower() in [n.lower() for n in tag_names_of(bookmark)];
}

def keyword_holds(bookmark: Bookmark, word: str) -> bool {
    if word.lower() == "unread" {
        return bookmark.unread;
    }
    if word.lower() == "untagged" {
        return not tag_names_of(bookmark);
    }
    return True;
}

impl node_matches(part: SearchNode, bookmark: Bookmark, lax: bool) -> bool {
    if part.kind == "term" {
        return has_text(bookmark, part.text) or (lax and has_tag(bookmark, part.text));
    }
    if part.kind == "tag" {
        return has_tag(bookmark, part.text);
    }
    if part.kind == "keyword" {
        return keyword_holds(bookmark, part.text);
    }
    if part.left is None {
        return True;
    }
    if part.kind == "not" {
        return not node_matches(part.left, bookmark, lax);
    }
    if part.right is None {
        return True;
    }
    if part.kind == "and" {
        return node_matches(part.left, bookmark, lax) and node_matches(part.right, bookmark, lax);
    }
    return node_matches(part.left, bookmark, lax) or node_matches(part.right, bookmark, lax);
}
