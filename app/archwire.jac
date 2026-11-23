graph layers {
    """Bookmarks and tags, and the rules for keeping them."""
    layer domain { clock | urls | tags | bookmarks | search | profiles; }

    """What a caller reaches: endpoints over the domain."""
    layer service { service; }
}

graph spaces {
    space api: native { clock | urls | tags | bookmarks | search | profiles | service; }

    app api { run api; }
}

graph import {
    """The service is written over the domain."""
    edge Serves: domain --> service;

    clock ++> tags | bookmarks { now_utc }
    urls ++> bookmarks { normalize_url }
    tags ++> bookmarks { Tag, find_or_make_tag, parse_tag_string }
    bookmarks ++> search {
        Bookmark,
        BookmarkDraft,
        create_bookmark,
        archive_bookmark,
        list_bookmarks,
        tag_names_of,
    }
    bookmarks ++> service { BookmarkDraft, create_bookmark, list_bookmarks, tag_counts }
    search ++> service { BookmarkFilter, search_bookmarks }
    profiles ++> service { profile_of }
}
