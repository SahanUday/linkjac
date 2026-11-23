test "archiving and unarchiving a bookmark by its id" {
    made = create_bookmark(root, BookmarkDraft(url="https://wa.example/one"));
    assert archive_bookmark(made.id, True) and made.is_archived;
    assert archive_bookmark(made.id, False) and not made.is_archived;
}

test "removing a bookmark by its id takes it out, and an unknown id changes nothing" {
    made = create_bookmark(root, BookmarkDraft(url="https://wa.example/two"));
    assert remove_bookmark(made.id);
    assert find_bookmark(root, made.id) is None;
    assert not remove_bookmark(made.id) and not archive_bookmark(made.id, True);
}
