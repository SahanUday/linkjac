impl archive_bookmark(bookmark_id: int, archived: bool) -> bool {
    bookmark = find_bookmark(root, bookmark_id);
    if bookmark is None {
        return False;
    }
    set_archived(bookmark, archived);
    return True;
}

impl remove_bookmark(bookmark_id: int) -> bool {
    bookmark = find_bookmark(root, bookmark_id);
    if bookmark is None {
        return False;
    }
    delete_bookmark(bookmark);
    return True;
}
