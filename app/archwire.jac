graph layers {
    """Bookmarks and tags, and the rules for keeping them."""
    layer domain { clock | ids | urls | tags | bookmarks | search_expression | search | profiles; }

    """What a caller reaches: endpoints over the domain."""
    layer service { service; }

    """The REST layer: linkding's /api/ over the domain."""
    layer rest {
        rest | rest_call | rest_reply | rest_forms | rest_paging | rest_tags | rest_bookmarks;
    }
}

graph spaces {
    space api: native {
        clock
            | ids
            | urls
            | tags
            | bookmarks
            | search_expression
            | search
            | profiles
            | service
            | rest
            | rest_call
            | rest_reply
            | rest_forms
            | rest_paging
            | rest_tags
            | rest_bookmarks;
    }

    app api { run api; }
}

graph import {
    """The service is written over the domain."""
    edge Serves: domain --> service;

    """The REST layer is written over the domain."""
    edge Exposes: domain --> rest;

    clock ++> tags | bookmarks { now_utc }
    ids ++> tags { next_tag_id }
    ids ++> bookmarks { next_bookmark_id }
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

    bookmarks ++> rest_forms { Bookmark, BookmarkDraft, tag_names_of }
    tags ++> rest_forms { Tag }
    urls ++> rest_forms { is_valid_url }
    rest_call ++> rest_paging { ApiCall, query_value }
    rest_call ++> rest_tags { ApiCall, body_object }
    rest_call ++> rest_bookmarks { ApiCall, body_object, query_value }
    rest_reply ++> rest_tags | rest_bookmarks {
        ApiReply,
        reply_json,
        reply_detail,
        reply_empty,
        reply_field_errors,
    }
    rest_forms ++> rest_tags { tag_json }
    rest_forms ++> rest_bookmarks { DraftReading, bookmark_json, read_draft }
    rest_paging ++> rest_tags | rest_bookmarks { window_of, page_of }
    tags ++> rest_tags { find_tag_by_id, list_tags, delete_tag, find_or_make_tag }
    bookmarks ++> rest_bookmarks {
        Bookmark,
        BookmarkDraft,
        create_bookmark,
        update_bookmark,
        delete_bookmark,
        find_bookmark,
        draft_of,
        list_bookmarks,
    }
    bookmarks ++> search_expression { Bookmark, BookmarkDraft, create_bookmark, tag_names_of }
    search_expression ++> search { parse_expression, node_matches }
    search ++> rest_bookmarks { BookmarkFilter, search_bookmarks }
    profiles ++> rest_bookmarks { profile_of }
    rest_call ++> rest { make_call }
    rest_reply ++> rest { ApiReply, reply_detail }
    rest_tags ++> rest { tags_route }
    rest_bookmarks ++> rest { bookmarks_route }
}
