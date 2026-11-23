impl bookmark_lines(bookmark: Bookmark) -> list[str] {
    title = html.escape(bookmark.title or bookmark.url);
    desc = html.escape(bookmark.description);
    if bookmark.notes {
        desc += f"[linkding-notes]{html.escape(bookmark.notes)}[/linkding-notes]";
    }
    # Plain sorting, not ignoring case: the original sorts its tag names that way here.
    names = sorted(tag_names_of(bookmark));
    if bookmark.is_archived {
        names.append(archived_marker);
    }
    tags = ",".join([html.escape(n) for n in names]);
    toread = "1" if bookmark.unread else "0";
    private = "0" if bookmark.shared else "1";
    added = epoch_of(bookmark.date_added);
    modified = epoch_of(bookmark.date_modified);
    lines = [
        f"<DT><A HREF=\"{bookmark.url}\" ADD_DATE=\"{added}\" LAST_MODIFIED=\"{modified}\" PRIVATE=\"{private}\" TOREAD=\"{toread}\" TAGS=\"{tags}\">{title}</A>",
    ];
    if desc {
        lines.append(f"<DD>{desc}");
    }
    return lines;
}

impl export_netscape(bookmarks: list[Bookmark]) -> str {
    lines = [
        "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
        "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">",
        "<TITLE>Bookmarks</TITLE>",
        "<H1>Bookmarks</H1>",
        "<DL><p>",
    ];
    for bookmark in bookmarks {
        lines += bookmark_lines(bookmark);
    }
    lines.append("</DL><p>");
    return "\n\r".join(lines);
}
