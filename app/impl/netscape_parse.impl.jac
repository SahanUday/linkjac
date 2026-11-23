impl NetscapeReader.begin_bookmark(attrs: list[tuple[str, str | None]]) {
    for (name, value) in attrs {
        given = value or "";
        if name == "href" {
            self.href = given;
        } elif name == "add_date" {
            self.add_date = given;
        } elif name == "last_modified" {
            self.last_modified = given;
        } elif name == "tags" {
            self.tags = given;
        } elif name == "toread" {
            self.toread = given;
        } elif name == "private" {
            self.private = given;
        }
    }
    names = parse_tag_string(self.tags);
    archived = archived_marker in self.tags;
    if archived_marker in names {
        names.remove(archived_marker);
    }
    self.bookmark = NetscapeBookmark(
        href=self.href,
        href_normalized=normalize_url(self.href),
        date_added=self.add_date,
        date_modified=self.last_modified,
        tag_names=names,
        to_read=self.toread == "1",
        # A bookmark is private unless the file says PRIVATE="0".
        private=self.private != "0",
        archived=archived,
    );
}

impl NetscapeReader.end_bookmark {
    listed = self.bookmark;
    if listed is not None {
        listed.title = self.title;
        listed.description = self.description;
        listed.notes = self.notes;
        self.bookmarks.append(listed);
    }
    self.bookmark = None;
    self.href = "";
    self.add_date = "";
    self.last_modified = "";
    self.tags = "";
    self.title = "";
    self.description = "";
    self.notes = "";
    self.toread = "";
    self.private = "";
}

impl NetscapeReader.read_description(data: str) {
    text = data.strip();
    if "[linkding-notes]" in text {
        self.notes = text.split("[linkding-notes]")[1].split("[/linkding-notes]")[0];
    }
    self.description = text.split("[linkding-notes]")[0];
}

impl NetscapeReader.handle_starttag(tag: str, attrs: list[tuple[str, str | None]]) {
    if tag == "dt" {
        self.end_bookmark();
    } elif tag == "a" {
        self.begin_bookmark(attrs);
    }
    self.current_tag = tag;
}

impl NetscapeReader.handle_endtag(tag: str) {
    if tag == "dl" {
        self.end_bookmark();
    }
    self.current_tag = "";
}

impl NetscapeReader.handle_data(data: str) {
    if self.current_tag == "a" {
        self.title = data.strip();
    } elif self.current_tag == "dd" {
        self.read_description(data);
    }
}

impl parse_netscape(text: str) -> list[NetscapeBookmark] {
    reader = NetscapeReader();
    reader.feed(text);
    return reader.bookmarks;
}
