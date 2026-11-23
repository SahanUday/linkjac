graph layers {
    """Bookmarks and tags, and the rules for keeping them."""
    layer domain { urls | tags | bookmarks; }

    """What a caller reaches: endpoints over the domain."""
    layer service { service; }
}

graph spaces {
    space api: native { urls | tags | bookmarks | service; }

    app api { run api; }
}

graph import {
    """The service is written over the domain."""
    edge Serves: domain --> service;

    urls ++> bookmarks { normalize_url }
    tags ++> bookmarks { Tag, find_or_make_tag, parse_tag_string }
    bookmarks ++> service { BookmarkDraft, create_bookmark, list_bookmarks }
}
