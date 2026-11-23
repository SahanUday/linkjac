graph layers {
    """Bookmarks and tags, and the rules for keeping them."""
    layer domain {
        clock | ids | urls | tags | bookmarks | matching | search_expression | search | profiles;
    }

    """The REST layer: linkding's /api/ over the domain."""
    layer rest {
        rest
            | rest_call
            | rest_reply
            | rest_forms
            | rest_paging
            | rest_tags
            | rest_bookmarks
            | rest_user;
    }
}

graph spaces {
    space api: native {
        clock
            | ids
            | urls
            | tags
            | bookmarks
            | matching
            | search_expression
            | search
            | profiles
            | rest
            | rest_call
            | rest_reply
            | rest_forms
            | rest_paging
            | rest_tags
            | rest_bookmarks
            | rest_user;
    }

    app api { run api; }
}

graph import {
    """The REST layer is written over the domain."""
    edge Exposes: domain --> rest;

    clock ++> tags | bookmarks { now_utc }
    ids ++> tags { next_tag_id }
    ids ++> bookmarks { next_bookmark_id }
    urls ++> bookmarks { normalize_url }
    tags ++> bookmarks { Tag, find_or_make_tag, parse_tag_string, name_key }
    tags ++> matching { name_key }
    bookmarks ++> matching { Bookmark, tag_names_of }
    matching ++> search_expression | search { has_text, has_tag }
    bookmarks ++> search {
        Bookmark,
        BookmarkDraft,
        create_bookmark,
        set_archived,
        list_bookmarks,
        tag_names_of,
    }

    bookmarks ++> rest_forms { Bookmark, BookmarkDraft, tag_names_of }
    tags ++> rest_forms { Tag }
    urls ++> rest_forms { is_valid_url }
    rest_call ++> rest_paging { ApiCall, query_value }
    rest_call ++> rest_tags { ApiCall, body_object, id_in_path }
    rest_call ++> rest_bookmarks { ApiCall, body_object, id_in_path, query_value }
    rest_reply ++> rest_tags | rest_bookmarks {
        ApiReply,
        reply_not_allowed,
        reply_not_a_dictionary,
        reply_json,
        reply_detail,
        reply_empty,
        reply_field_errors,
    }
    rest_forms ++> rest_tags { tag_json }
    profiles ++> rest_forms { UserProfile }
    rest_forms ++> rest_bookmarks { DraftReading, bookmark_json, read_draft }
    rest_paging ++> rest_tags | rest_bookmarks { window_of, page_of }
    tags ++> rest_tags { find_tag_by_id, list_tags, delete_tag, find_or_make_tag }
    bookmarks ++> rest_bookmarks {
        Bookmark,
        BookmarkDraft,
        create_bookmark,
        set_archived,
        update_bookmark,
        delete_bookmark,
        find_bookmark,
        draft_of,
        list_bookmarks,
    }
    bookmarks ++> search_expression { Bookmark, BookmarkDraft, create_bookmark, tag_names_of }
    search_expression ++> search { parse_expression, node_matches }
    search ++> rest_bookmarks { BookmarkFilter, search_bookmarks, search_many }
    profiles ++> rest_bookmarks { profile_of, find_profile }
    clock ++> search { read_instant }
    rest_call ++> rest_user { ApiCall }
    rest_reply ++> rest_user { ApiReply, reply_not_allowed, reply_detail, reply_json }
    rest_forms ++> rest_user { profile_json }
    profiles ++> rest_user { profile_of }
    rest_user ++> rest { user_route }
    rest_call ++> rest { make_call }
    rest_reply ++> rest { ApiReply, reply_detail }
    rest_tags ++> rest { tags_route }
    rest_bookmarks ++> rest { bookmarks_route, shared_route }
}
