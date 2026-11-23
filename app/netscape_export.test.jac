def listed(url: str, title: str, added: int, modified: int, tags: str = "") -> Bookmark {
    made = create_bookmark(root, BookmarkDraft(url=url, title=title, tag_string=tags));
    made.date_added = read_epoch(str(added)) or made.date_added;
    made.date_modified = read_epoch(str(modified)) or made.date_modified;
    return made;
}

test "bookmarks are written as the original writes them" {
    one = listed("https://export.example/1", "Title 1", 1, 11);
    one.description = "Example description";
    two = listed("https://export.example/2", "Title 2", 2, 22, "tag3, tag1, tag2");
    three = listed("https://export.example/3", "Title 3", 3, 33);
    three.unread = True;
    four = listed("https://export.example/4", "Title 4", 4, 44);
    four.shared = True;
    four.description = "Example description";
    four.notes = "Example notes";
    five = listed("https://export.example/5", "Title 5", 5, 55, "tag4");
    set_archived(five, True);
    five.date_modified = read_epoch("55") or five.date_modified;
    text = export_netscape([one, two, three, four, five]);
    expected = [
        "<DT><A HREF=\"https://export.example/1\" ADD_DATE=\"1\" LAST_MODIFIED=\"11\" PRIVATE=\"1\" TOREAD=\"0\" TAGS=\"\">Title 1</A>",
        "<DD>Example description",
        "<DT><A HREF=\"https://export.example/2\" ADD_DATE=\"2\" LAST_MODIFIED=\"22\" PRIVATE=\"1\" TOREAD=\"0\" TAGS=\"tag1,tag2,tag3\">Title 2</A>",
        "<DT><A HREF=\"https://export.example/3\" ADD_DATE=\"3\" LAST_MODIFIED=\"33\" PRIVATE=\"1\" TOREAD=\"1\" TAGS=\"\">Title 3</A>",
        "<DT><A HREF=\"https://export.example/4\" ADD_DATE=\"4\" LAST_MODIFIED=\"44\" PRIVATE=\"0\" TOREAD=\"0\" TAGS=\"\">Title 4</A>",
        "<DD>Example description[linkding-notes]Example notes[/linkding-notes]",
        "<DT><A HREF=\"https://export.example/5\" ADD_DATE=\"5\" LAST_MODIFIED=\"55\" PRIVATE=\"1\" TOREAD=\"0\" TAGS=\"tag4,linkding:bookmarks.archived\">Title 5</A>",
    ];
    assert "\n\r".join(expected) in text;
    assert text.startswith("<!DOCTYPE NETSCAPE-Bookmark-file-1>\n\r<META HTTP-EQUIV");
    assert text.endswith("</DL><p>");
}

test "html in titles, descriptions, notes and tag names is escaped" {
    made = listed("https://export.example/esc", "<style>: Style", 1, 1, "\",&");
    made.description = "The <style> element";
    made.notes = "About <style>";
    text = export_netscape([made]);
    assert "&lt;style&gt;: Style" in text;
    assert "The &lt;style&gt; element[linkding-notes]About &lt;style&gt;[/linkding-notes]" in text;
    assert "TAGS=\"&quot;,&amp;\"" in text;
}

test "a bookmark with no title is written with its URL as the title" {
    made = listed("https://export.example/untitled", "", 1, 1);
    assert ">https://export.example/untitled</A>" in export_netscape([made]);
}
