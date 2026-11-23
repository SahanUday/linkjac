"""Netscape parse: a Netscape bookmark file read into the bookmarks it lists, the way linkding reads one."""

import from html.parser { HTMLParser }

"""The marker linkding writes into a bookmark's tags for an archived bookmark."""
glob archived_marker: str = "linkding:bookmarks.archived";

"""One bookmark as a Netscape file lists it, with its dates still as written."""
obj NetscapeBookmark {
    has href: str,
        href_normalized: str,
        title: str = "",
        description: str = "",
        notes: str = "",
        date_added: str = "",
        date_modified: str = "",
        tag_names: list[str] = [],
        to_read: bool = False,
        private: bool = True,
        archived: bool = False;
}

"""Reads the tags of a Netscape file in order and collects the bookmarks they describe."""
class NetscapeReader(HTMLParser) {
    has bookmarks: list[NetscapeBookmark] = [],
        current_tag: str = "",
        bookmark: NetscapeBookmark | None = None,
        href: str = "",
        add_date: str = "",
        last_modified: str = "",
        tags: str = "",
        title: str = "",
        description: str = "",
        notes: str = "",
        toread: str = "",
        private: str = "";

    def begin_bookmark(attrs: list[tuple[str, str | None]]);

    def end_bookmark;

    def read_description(data: str);

    override def handle_starttag(tag: str, attrs: list[tuple[str, str | None]]);

    override def handle_endtag(tag: str);

    override def handle_data(data: str);
}

"""The bookmarks a Netscape file lists, in file order."""
def parse_netscape(text: str) -> list[NetscapeBookmark];
