def lacks_term(bookmark: Bookmark, term: str) -> bool {
    needle = term.lower();
    for field in [bookmark.title, bookmark.description, bookmark.notes, bookmark.url] {
        if needle in field.lower() {
            return False;
        }
    }
    return True;
}

def lacks_tag(have: list[str], wanted: str) -> bool {
    return wanted.lower() not in [n.lower() for n in have];
}

def matches(bookmark: Bookmark, parsed: ParsedQuery, narrowing: BookmarkFilter) -> bool {
    if bookmark.is_archived != narrowing.archived {
        return False;
    }
    if narrowing.unread == "yes" and not bookmark.unread {
        return False;
    }
    if narrowing.unread == "no" and bookmark.unread {
        return False;
    }
    if narrowing.shared == "yes" and not bookmark.shared {
        return False;
    }
    if narrowing.shared == "no" and bookmark.shared {
        return False;
    }
    if parsed.unread and not bookmark.unread {
        return False;
    }
    have = tag_names_of(bookmark);
    if parsed.untagged and have {
        return False;
    }
    return not (
        any([lacks_term(bookmark, t) for t in parsed.terms])
        or any([lacks_tag(have, n) for n in parsed.tag_names])
    );
}

def title_key(bookmark: Bookmark) -> str {
    return (bookmark.title or bookmark.url).lower();
}

def added_key(bookmark: Bookmark) -> datetime {
    return bookmark.date_added;
}

def modified_key(bookmark: Bookmark) -> datetime {
    return bookmark.date_modified;
}

def in_order(found: list[Bookmark], order: str) -> list[Bookmark] {
    if order.startswith("title") {
        return sorted(found, key=title_key, reverse=order == "title_desc");
    }
    if order.startswith("modified") {
        return sorted(found, key=modified_key, reverse=order == "modified_desc");
    }
    return sorted(found, key=added_key, reverse=order != "added_asc");
}

impl parse_query_string(text: str) -> ParsedQuery {
    words = [w for w in (text or "").strip().split(" ") if w];
    seen: set[str] = set();
    names: list[str] = [];
    for word in words {
        if word[0] == "#" and word[1:].lower() not in seen {
            seen.add(word[1:].lower());
            names.append(word[1:]);
        }
    }
    return ParsedQuery(
        terms=[w for w in words if w[0] != "#" and w[0] != "!"],
        tag_names=names,
        untagged="!untagged" in words,
        unread="!unread" in words,
    );
}

impl search_bookmarks(owner: Root, narrowing: BookmarkFilter) -> list[Bookmark] {
    parsed = parse_query_string(narrowing.text);
    found = [b for b in list_bookmarks(owner) if matches(b, parsed, narrowing)];
    return in_order(found, narrowing.sort);
}
