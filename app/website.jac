"""Website: what a web page says about itself (title, description, preview image), read the way linkding reads it."""

import from html.parser { HTMLParser }
import from urllib.parse { urljoin }

"""What a page says about itself; a field is None when the page says nothing."""
obj WebsiteMetadata {
    has url: str,
        title: str | None = None,
        description: str | None = None,
        preview_image: str | None = None;
}

"""Reads a page's tags in order and keeps its first title, description, Open Graph description and Open Graph image."""
class MetadataReader(HTMLParser) {
    has in_title: bool = False,
        title: str | None = None,
        description: str = "",
        og_description: str = "",
        image: str = "";

    override def handle_starttag(tag: str, attrs: list[tuple[str, str | None]]);

    override def handle_endtag(tag: str);

    override def handle_data(data: str);
}

"""What the page at `url` says about itself; nothing found when it cannot be read."""
def load_website_metadata(url: str) -> WebsiteMetadata;
