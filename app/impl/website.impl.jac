impl MetadataReader.handle_starttag(tag: str, attrs: list[tuple[str, str | None]]) {
    if tag == "title" and self.title is None {
        self.in_title = True;
        self.title = "";
    } elif tag == "meta" {
        given = {name: (value or "") for (name, value) in attrs};
        content = given.get("content", "").strip();
        if given.get("name") == "description" and not self.description {
            self.description = content;
        } elif given.get("property") == "og:description" and not self.og_description {
            self.og_description = content;
        } elif given.get("property") == "og:image" and not self.image {
            self.image = content;
        }
    }
}

impl MetadataReader.handle_endtag(tag: str) {
    if tag == "title" {
        self.in_title = False;
    }
}

impl MetadataReader.handle_data(data: str) {
    if self.in_title {
        self.title = (self.title or "") + data;
    }
}

impl load_website_metadata(url: str) -> WebsiteMetadata {
    page = fetch_head(url);
    found = WebsiteMetadata(url=url);
    if page is None {
        return found;
    }
    reader = MetadataReader();
    reader.feed(page);
    found.title = (reader.title or "").strip() or None;
    found.description = reader.description or reader.og_description or None;
    if reader.image {
        found.preview_image = reader.image
            if reader.image.startswith("http://") or reader.image.startswith("https://")
            else urljoin(url, reader.image);
    }
    return found;
}

impl enhance_with_website_metadata(bookmark: Bookmark) {
    if bookmark.title and bookmark.description {
        return;
    }
    found = load_website_metadata(bookmark.url);
    if not bookmark.title {
        bookmark.title = found.title or "";
    }
    if not bookmark.description {
        bookmark.description = found.description or "";
    }
}
