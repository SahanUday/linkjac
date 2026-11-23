glob longest_tag_name: int = 64,
     longest_title: int = 512,
     longest_url: int = 2048;

impl make_missing_tags(owner: Root, listed: list[NetscapeBookmark]) {
    for each in listed {
        for name in each.tag_names {
            if len(name) <= longest_tag_name {
                find_or_make_tag(owner, name);
            }
        }
    }
}

impl is_refused(listed: NetscapeBookmark) -> bool {
    if not is_valid_url(listed.href) or len(listed.href) > longest_url {
        return True;
    }
    if len(listed.title) > longest_title {
        return True;
    }
    if listed.date_added and read_epoch(listed.date_added) is None {
        return True;
    }
    return bool(listed.date_modified) and read_epoch(listed.date_modified) is None;
}

impl add_tags(owner: Root, bookmark: Bookmark, names: list[str]) {
    have = [name_key(n) for n in tag_names_of(bookmark)];
    for name in names {
        if len(name) > longest_tag_name or name_key(name) in have {
            continue;
        }
        found = find_tag(owner, name);
        if found is not None {
            bookmark +>:Tagged:+> found;
            have.append(name_key(name));
        }
    }
}

impl save_listed(owner: Root, listed: NetscapeBookmark, map_private_flag: bool) {
    bookmark = find_existing(owner, listed.href);
    is_new = bookmark is None;
    if bookmark is None {
        bookmark = create_bookmark(owner, BookmarkDraft(url=listed.href));
    }
    bookmark.url = listed.href;
    bookmark.url_normalized = listed.href_normalized;
    added = read_epoch(listed.date_added) if listed.date_added else None;
    bookmark.date_added = added if added is not None else now_utc();
    modified = read_epoch(listed.date_modified) if listed.date_modified else None;
    bookmark.date_modified = modified if modified is not None else bookmark.date_added;
    bookmark.unread = listed.to_read;
    if listed.title {
        bookmark.title = listed.title;
    }
    if listed.description {
        bookmark.description = listed.description;
    }
    if listed.notes {
        bookmark.notes = listed.notes;
    }
    if map_private_flag and not listed.private {
        bookmark.shared = True;
    }
    # The original saves the archived marker only for a bookmark it creates, never for one it updates.
    if listed.archived and is_new {
        bookmark.is_archived = True;
    }
    add_tags(owner, bookmark, listed.tag_names);
}

impl import_netscape(owner: Root, text: str, map_private_flag: bool = False) -> ImportResult {
    listed = parse_netscape(text);
    make_missing_tags(owner, listed);
    result = ImportResult();
    done: set[str] = set();
    for each in listed {
        result.total += 1;
        # The same address twice in one file: the first is kept, the rest are refused.
        if each.href_normalized in done or is_refused(each) {
            result.failed += 1;
            continue;
        }
        save_listed(owner, each, map_private_flag);
        done.add(each.href_normalized);
        result.success += 1;
    }
    return result;
}
