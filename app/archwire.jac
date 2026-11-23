graph layers {
    """Bookmarks and tags, and the rules for keeping them."""
    layer domain {
        clock
            | ids
            | urls
            | tags
            | bookmarks
            | matching
            | search_expression
            | search
            | profiles
            | netscape_parse
            | netscape_export
            | netscape_import;
    }

    """What a signed-in caller can ask the server to do beyond /api/."""
    layer service { admin; }

    """Programs that call the server."""
    layer client { cli; }

    """What the web pages ask the server for."""
    layer web { web_list | web_form | web_tags | web_actions | web_settings; }

    """Parts of pages: the list and the form."""
    layer ui { ui.*; }

    """The pages the browser shows."""
    layer pages { pages.*; }

    """Reading web pages: fetching one and what it says about itself."""
    layer net { web_fetch | website; }

    """Work done apart from requests: icons fetched by jobs and kept, started by one scheduled function."""
    layer background { favicons | favicon_job | snapshot_job | assets | background; }

    """The REST layer: linkding's /api/ over the domain."""
    layer rest {
        rest
            | rest_assets
            | rest_static
            | rest_check
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
            | netscape_parse
            | netscape_export
            | netscape_import
            | web_fetch
            | website
            | favicons
            | favicon_job
            | snapshot_job
            | assets
            | background
            | rest_assets
            | rest_static
            | web_settings
            | rest_check
            | admin
            | web_list
            | web_form
            | web_tags
            | web_actions
            | rest
            | rest_call
            | rest_reply
            | rest_forms
            | rest_paging
            | rest_tags
            | rest_bookmarks
            | rest_user;
    }

    space site: browser { pages.* | ui.*; }

    space cli: native { entry cli; }

    app api { run api; serve site; }
    app cli { run cli; }
}

graph import {
    """The REST layer is written over the domain."""
    edge Exposes: domain --> rest | service | web;
    edge Reads: net --> rest;
    edge Describes: domain --> net;
    edge Keeps: domain --> background;
    edge Fetches: net --> background;
    edge Serves: background --> rest;
    edge Shows: web --> ui;
    edge Builds: ui --> pages;
    edge Calls: service --> client;

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
    tags ++> netscape_parse { parse_tag_string }
    urls ++> netscape_parse { normalize_url }
    clock ++> netscape_export { epoch_of, read_epoch }
    bookmarks ++> netscape_export {
        Bookmark,
        BookmarkDraft,
        create_bookmark,
        set_archived,
        tag_names_of,
    }
    netscape_parse ++> netscape_export { archived_marker }
    netscape_parse ++> netscape_import { NetscapeBookmark, parse_netscape }
    urls ++> netscape_import { is_valid_url }
    clock ++> netscape_import { read_epoch, epoch_of, now_utc }
    tags ++> netscape_import { find_or_make_tag, find_tag, name_key }
    bookmarks ++> netscape_import {
        Bookmark,
        BookmarkDraft,
        Tagged,
        create_bookmark,
        find_existing,
        delete_bookmark,
        tag_names_of,
    }
    netscape_export ++> netscape_import { export_netscape }
    netscape_import ++> admin { import_netscape }
    netscape_export ++> admin { export_netscape }
    bookmarks ++> admin { list_bookmarks }
    admin ++> cli { import_bookmarks, export_bookmarks }
    bookmarks ++> website { Bookmark }
    bookmarks ++> background { Bookmark, list_bookmarks }
    profiles ++> background { find_profile }
    favicons ++> background {
        favicon_base_name,
        provider_address,
        find_favicon_of_site,
        keep_favicon,
    }
    favicon_job ++> background { load_favicon }
    snapshot_job ++> background { load_snapshot }
    web_fetch ++> snapshot_job { fetch_page }
    bookmarks ++> assets { Asset, HasAsset, Bookmark, touch }
    ids ++> assets { next_asset_id }
    clock ++> assets { now_utc }
    profiles ++> assets { profile_of }
    assets ++> background { Asset, assets_of, complete_snapshot, fail_snapshot }
    assets ++> rest_bookmarks { ask_for_snapshot, assets_of }
    assets ++> rest_assets { Asset, assets_of, find_asset, delete_asset }
    bookmarks ++> rest_assets { Bookmark }
    rest_call ++> rest_assets { ApiCall, id_in_path }
    rest_paging ++> rest_assets { window_of, page_of }
    rest_forms ++> rest_assets { iso_utc }
    rest_reply ++> rest_assets {
        ApiReply,
        reply_detail,
        reply_json,
        reply_empty,
        reply_not_allowed,
        reply_file,
    }
    rest_assets ++> rest_bookmarks { assets_route }
    favicons ++> rest_static { find_favicon }
    rest_reply ++> rest_static { ApiReply, reply_not_allowed, reply_detail, reply_file }
    rest_static ++> rest { static_route }
    profiles ++> web_settings { profile_of }
    web_fetch ++> website { fetch_head }
    website ++> rest_check { load_website_metadata }
    website ++> rest_bookmarks { enhance_with_website_metadata }
    rest_call ++> rest_check { ApiCall, query_value }
    rest_reply ++> rest_check { ApiReply, reply_not_allowed, reply_json }
    bookmarks ++> rest_check { find_existing }
    rest_forms ++> rest_check { bookmark_json }
    rest_check ++> rest_bookmarks { check_route }
    rest_call ++> rest_user { ApiCall }
    rest_reply ++> rest_user { ApiReply, reply_not_allowed, reply_detail, reply_json }
    rest_forms ++> rest_user { profile_json }
    profiles ++> rest_user { profile_of }
    rest_user ++> rest { user_route }
    rest_call ++> rest { make_call }
    rest_reply ++> rest { ApiReply, reply_detail }
    rest_tags ++> rest { tags_route }
    rest_bookmarks ++> rest { bookmarks_route, shared_route }
    bookmarks ++> web_list { Bookmark, tag_names_of }
    tags ++> web_list { name_key }
    profiles ++> web_list { profile_of }
    search ++> web_list { BookmarkFilter, search_bookmarks }
    web_list ++> ui.bookmark_list { bookmark_page, ListedBookmark, ListedTag }
    urls ++> web_form { is_valid_url }
    bookmarks ++> web_form {
        BookmarkDraft,
        create_bookmark,
        find_bookmark,
        update_bookmark,
        tag_names_of,
    }
    web_form ++> ui.bookmark_form { save_bookmark }
    web_form ++> ui.bookmark_edit { bookmark_fields }
    bookmarks ++> web_actions {
        BookmarkDraft,
        create_bookmark,
        find_bookmark,
        set_archived,
        delete_bookmark,
    }
    web_actions ++> ui.bookmark_list { archive_bookmark, remove_bookmark }
    ui.site_nav ++> ui.bookmark_list | ui.tag_table | ui.bookmark_edit | pages.bookmarks.new {
        SiteNav,
    }
    ui.bookmark_list ++> pages.bookmarks.index { BookmarkList }
    ui.bookmark_edit ++> pages.bookmarks.index { EditBookmark }
    ui.bookmark_form ++> pages.bookmarks.new | ui.bookmark_edit { BookmarkForm }
    tags ++> web_tags {
        find_tag,
        find_tag_by_id,
        find_or_make_tag,
        list_tags,
        delete_tag,
        rename_tag,
        sanitize_tag_name,
        name_key,
    }
    bookmarks ++> web_tags { tag_counts }
    web_tags ++> ui.tag_table { tag_table, remove_tag, TagRow }
    web_tags ++> ui.tag_dialog { tag_name, save_tag }
    ui.tag_table ++> pages.tags.index { TagTable }
    ui.tag_dialog ++> pages.tags.index { TagDialog }
}
