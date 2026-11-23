def one_file(rows: list[str]) -> str {
    return "<DL><p>\n" + "\n".join(rows) + "\n</DL><p>";
}

def row(url: str, extra: str = "", title: str = "T") -> str {
    return f"<DT><A HREF=\"{url}\" {extra}>{title}</A>";
}

test "a file's bookmarks are made with their dates, flags and tags" {
    text = one_file([
        row(
            "https://imp.example/a",
            "ADD_DATE=\"1700000000\" LAST_MODIFIED=\"1700000500\" TOREAD=\"1\" TAGS=\"imp-x,imp-y,linkding:bookmarks.archived\"",
            "Title A",
        ),
        "<DD>Desc[linkding-notes]Notes[/linkding-notes]",
    ]);
    result = import_netscape(root, text);
    assert result.total == 1 and result.success == 1 and result.failed == 0;
    made = find_existing(root, "https://imp.example/a");
    assert made is not None;
    assert made.title == "Title A" and made.description == "Desc" and made.notes == "Notes";
    assert made.unread and made.is_archived and not made.shared;
    assert epoch_of(made.date_added) == 1700000000 and epoch_of(made.date_modified) == 1700000500;
    assert tag_names_of(made) == ["imp-x", "imp-y"];
}

test "a missing date means now, and a missing modified date means the added date" {
    import_netscape(root, one_file([row("https://imp.example/dates", "ADD_DATE=\"86400\"")]));
    kept = find_existing(root, "https://imp.example/dates");
    assert kept is not None and epoch_of(kept.date_modified) == 86400;
    import_netscape(root, one_file([row("https://imp.example/nodate")]));
    fresh = find_existing(root, "https://imp.example/nodate");
    assert fresh is not None and fresh.date_added == fresh.date_modified;
    assert epoch_of(fresh.date_added) > 1700000000;
}

test "importing a URL that is saved changes it, keeps its tags and adds the new ones" {
    first = create_bookmark(
        root,
        BookmarkDraft(
            url="https://imp.example/again", title="Old", notes="old notes", tag_string="imp-old"
        ),
    );
    import_netscape(root, one_file([row("https://imp.example/again/", "TAGS=\"imp-new\"", "")]));
    assert find_existing(root, "https://imp.example/again") is first;
    assert first.title == "Old" and first.notes == "old notes";
    assert tag_names_of(first) == ["imp-new", "imp-old"];
}

test "the private flag is only used when asked, and only ever shares" {
    import_netscape(root, one_file([row("https://imp.example/pub", "PRIVATE=\"0\"")]));
    plain = find_existing(root, "https://imp.example/pub");
    assert plain is not None and not plain.shared;
    import_netscape(root, one_file([row("https://imp.example/pub", "PRIVATE=\"0\"")]), True);
    assert plain.shared;
    import_netscape(root, one_file([row("https://imp.example/pub", "PRIVATE=\"1\"")]), True);
    assert plain.shared;
}

test "a repeated address, a bad address, a long title and a bad date are refused and counted" {
    result = import_netscape(
        root,
        one_file([
            row("https://imp.example/r1"),
            row("https://imp.example/r1/"),
            row("not a url"),
            row("https://imp.example/r2", "", "x" * 513),
            row("https://imp.example/r3", "ADD_DATE=\"soon\""),
            row("https://imp.example/r4"),
        ]),
    );
    assert result.total == 6 and result.success == 2 and result.failed == 4;
    assert find_existing(root, "https://imp.example/r3") is None;
}

test "tags are made for every listed bookmark, and a tag name over 64 characters is left out" {
    long_name = "n" * 65;
    import_netscape(
        root,
        one_file([
            row("not a url", "TAGS=\"imp-only-here\""),
            row("https://imp.example/lt", f"TAGS=\"{long_name},imp-ok\""),
        ]),
    );
    assert find_tag(root, "imp-only-here") is not None;
    assert find_tag(root, long_name) is None;
    made = find_existing(root, "https://imp.example/lt");
    assert made is not None and tag_names_of(made) == ["imp-ok"];
}

test "a file exported from bookmarks imports back to the same bookmarks" {
    one = create_bookmark(
        root,
        BookmarkDraft(
            url="https://rt.example/one",
            title="One & <b>",
            description="d",
            notes="n",
            tag_string="rt-b,rt-a",
            unread=True,
            shared=True,
        ),
    );
    two = create_bookmark(
        root, BookmarkDraft(url="https://rt.example/two", title="Two", is_archived=True)
    );
    one.date_added = read_epoch("1600000000") or one.date_added;
    one.date_modified = read_epoch("1600000009") or one.date_modified;
    text = export_netscape([one, two]);
    delete_bookmark(one);
    delete_bookmark(two);
    result = import_netscape(root, text, True);
    assert result.success == 2 and result.failed == 0;
    back = find_existing(root, "https://rt.example/one");
    assert back is not None;
    assert back.title == "One & <b>" and back.description == "d" and back.notes == "n";
    assert back.unread and back.shared and not back.is_archived;
    assert tag_names_of(back) == ["rt-a", "rt-b"];
    assert epoch_of(back.date_added) == 1600000000 and epoch_of(back.date_modified) == 1600000009;
    again = find_existing(root, "https://rt.example/two");
    assert again is not None and again.is_archived and not again.shared;
}
