glob sample_file: str = "<!DOCTYPE NETSCAPE-Bookmark-file-1>\n<TITLE>Bookmarks</TITLE>\n<H1>Bookmarks</H1>\n<DL><p>\n    <DT><H3>A folder</H3>\n    <DL><p>\n        <DT><A HREF=\"https://parse.example/one\" ADD_DATE=\"1700000000\" LAST_MODIFIED=\"1700000100\" PRIVATE=\"0\" TOREAD=\"1\" TAGS=\"b, a ,linkding:bookmarks.archived\">One &amp; only</A>\n        <DD>Words[linkding-notes]Some notes[/linkding-notes]\n        <DT><A HREF=\"https://parse.example/two\">Two</A>\n    </DL><p>\n    <DT><A HREF=\"https://parse.example/three\" TAGS=\"\"></A>\n</DL><p>\n";

test "bookmarks are read from a file with a folder, in order" {
    found = parse_netscape(sample_file);
    assert [b.href for b in found] == [
        "https://parse.example/one",
        "https://parse.example/two",
        "https://parse.example/three",
    ];
}

test "one bookmark's fields are read" {
    one = parse_netscape(sample_file)[0];
    assert one.title == "One & only";
    assert one.description == "Words" and one.notes == "Some notes";
    assert one.date_added == "1700000000" and one.date_modified == "1700000100";
    assert one.tag_names == ["a", "b"] and one.archived;
    assert one.to_read and not one.private;
}

test "a bookmark with no flags is private, not unread and not archived, and fields do not leak to the next" {
    two = parse_netscape(sample_file)[1];
    assert two.private and not two.to_read and not two.archived;
    assert two.description == "" and two.notes == "" and two.tag_names == [];
    assert two.date_added == "";
}

test "an empty title and a file with no bookmarks" {
    assert parse_netscape(sample_file)[2].title == "";
    assert parse_netscape("<DL><p></DL><p>") == [];
    assert parse_netscape("") == [];
}
