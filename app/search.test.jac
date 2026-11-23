def seed(
    url: str, title: str, tags: str, notes: str = "", unread: bool = False, shared: bool = False
) -> Bookmark {
    return create_bookmark(
        root,
        BookmarkDraft(
            url=url, title=title, notes=notes, tag_string=tags, unread=unread, shared=shared
        ),
    );
}

def urls_of(found: list[Bookmark]) -> list[str] {
    return [b.url for b in found];
}

test "a query string splits into terms, tags and commands" {
    parsed = parse_query_string("  rust  #Web #web guide !untagged !unread ");
    assert parsed.terms == ["rust", "guide"];
    assert parsed.tag_names == ["Web"];
    assert parsed.untagged and parsed.unread;
    assert parse_query_string("").terms == [];
}

test "terms match url, title, notes ignoring case, and all must match" {
    seed("https://s1.example/Alpha", "Zebra post", "", notes="about mangoes");
    seed("https://s2.example/beta", "Another", "");
    assert urls_of(search_bookmarks(root, BookmarkFilter(text="alpha"))) == [
        "https://s1.example/Alpha",
    ];
    assert urls_of(search_bookmarks(root, BookmarkFilter(text="MANGO zebra"))) == [
        "https://s1.example/Alpha",
    ];
    assert urls_of(search_bookmarks(root, BookmarkFilter(text="mango beta"))) == [];
}

# WORKAROUND(GAP-026): every test of a module shares one root, so tags here are named for this test.
test "tag terms need every named tag, ignoring case" {
    seed("https://s3.example", "Tagged", "red, blue");
    seed("https://s4.example", "One tag", "red");
    assert urls_of(search_bookmarks(root, BookmarkFilter(text="#RED #blue"))) == [
        "https://s3.example",
    ];
    assert "https://s4.example" in urls_of(search_bookmarks(root, BookmarkFilter(text="#red")));
}

test "untagged, unread, shared and archived narrow the list" {
    plain = seed("https://s5.example", "Plain", "");
    seed("https://s6.example", "Unread shared", "x", unread=True, shared=True);
    assert plain in search_bookmarks(root, BookmarkFilter(text="!untagged"));
    assert urls_of(
        search_bookmarks(root, BookmarkFilter(text="s6.example", unread="yes", shared="yes"))
    ) == ["https://s6.example"];
    assert search_bookmarks(root, BookmarkFilter(text="s6.example", unread="no")) == [];
    archive_bookmark(plain);
    assert plain not in search_bookmarks(root, BookmarkFilter(text="s5.example"));
    assert plain in search_bookmarks(root, BookmarkFilter(text="s5.example", archived=True));
}

# WORKAROUND(GAP-026): every test of a module shares one root, so this test filters to names of its own.
test "newest first by default, and titles sort ignoring case" {
    older = seed("https://s7.example", "b-title", "");
    newer = seed("https://s8.example", "A-title", "");
    found = [
        b
        for b in search_bookmarks(root, BookmarkFilter(text="-title"))
        if b is older or b is newer
    ];
    assert found == [newer, older];
    by_title = search_bookmarks(root, BookmarkFilter(text="-title", sort="title_asc"));
    assert urls_of(by_title) == ["https://s8.example", "https://s7.example"];
    assert urls_of(search_bookmarks(root, BookmarkFilter(text="-title", sort="title_desc"))) == [
        "https://s7.example",
        "https://s8.example",
    ];
    assert urls_of(search_bookmarks(root, BookmarkFilter(text="-title", sort="added_asc"))) == [
        "https://s7.example",
        "https://s8.example",
    ];
}

test "legacy search reads 'or' as a plain word, and the expression search reads it as an operator" {
    seed("https://lg1.example", "legacy-aa", "");
    seed("https://lg2.example", "legacy-bb", "");
    assert search_bookmarks(root, BookmarkFilter(text="legacy-aa or legacy-bb", legacy=True)) == [];
    assert len(search_bookmarks(root, BookmarkFilter(text="legacy-aa or legacy-bb"))) == 2;
}
