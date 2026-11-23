impl refuses_choice(choice: str, flag: bool) -> bool {
    return (choice == "yes" and not flag) or (choice == "no" and flag);
}

impl passes_flags(bookmark: Bookmark, narrowing: BookmarkFilter) -> bool {
    if bookmark.is_archived != narrowing.archived {
        return False;
    }
    if refuses_choice(narrowing.unread, bookmark.unread)
        or refuses_choice(narrowing.shared, bookmark.shared)
    {
        return False;
    }
    return not (
        not_after(narrowing.added_since, bookmark.date_added)
        or not_after(narrowing.modified_since, bookmark.date_modified)
    );
}

impl matches_legacy(bookmark: Bookmark, parsed: ParsedQuery) -> bool {
    if parsed.unread and not bookmark.unread {
        return False;
    }
    if parsed.untagged and tag_names_of(bookmark) {
        return False;
    }
    return not (
        any([not has_text(bookmark, t) for t in parsed.terms])
        or any([not has_tag(bookmark, n) for n in parsed.tag_names])
    );
}

# A limit that is empty or not a time excludes nothing, as linkding ignores a date it cannot read.
impl not_after(limit: str, stamp: datetime) -> bool {
    since = read_instant(limit) if limit else None;
    return since is not None and stamp <= since;
}

impl title_key(bookmark: Bookmark) -> str {
    return (bookmark.title or bookmark.url).lower();
}

impl added_key(bookmark: Bookmark) -> datetime {
    return bookmark.date_added;
}

impl modified_key(bookmark: Bookmark) -> datetime {
    return bookmark.date_modified;
}

impl in_order(found: list[Bookmark], order: str) -> list[Bookmark] {
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

impl search_many(owners: list[Root], narrowing: BookmarkFilter) -> list[Bookmark] {
    found: list[Bookmark] = [];
    for owner in owners {
        found += [b for b in list_bookmarks(owner) if passes_flags(b, narrowing)];
    }
    if narrowing.legacy {
        parsed = parse_query_string(narrowing.text);
        found = [b for b in found if matches_legacy(b, parsed)];
    } else {
        reading = parse_expression(narrowing.text);
        if not reading.valid {
            return [];
        }
        tree = reading.tree;
        if tree is not None {
            found = [b for b in found if node_matches(tree, b, narrowing.lax)];
        }
    }
    return in_order(found, narrowing.sort);
}

impl search_bookmarks(owner: Root, narrowing: BookmarkFilter) -> list[Bookmark] {
    return search_many([owner], narrowing);
}
