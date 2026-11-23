glob sample_count: int = 0;

def draft(url: str, tags: str = "") -> BookmarkDraft {
    return BookmarkDraft(url=url, title="T " + url, tag_string=tags);
}

test "a created bookmark is listed with its tags" {
    made = create_bookmark(root, draft("https://example.com", "web, demo"));
    assert made in list_bookmarks(root);
    assert tag_names_of(made) == ["demo", "web"];
    assert made.url_normalized == "https://example.com";
    assert made.date_added == made.date_modified;
}

test "saving a URL that is already saved changes that bookmark" {
    first = create_bookmark(root, draft("https://dup.example/a/", "one"));
    again = create_bookmark(
        root, BookmarkDraft(url="HTTPS://dup.example/a", title="New", notes="n", tag_string="two")
    );
    assert again is first;
    assert again.title == "New" and again.notes == "n";
    assert tag_names_of(again) == ["two"];
    assert len([b for b in list_bookmarks(root) if b.url_normalized == "https://dup.example/a"])
        == 1;
}

test "a tag is made once however many bookmarks carry it" {
    create_bookmark(root, draft("https://a.example", "shared-tag"));
    create_bookmark(root, draft("https://b.example", "Shared-Tag"));
    assert len([root --> [?:Tag, name == "shared-tag"]]) == 1;
    assert tag_counts(root)["shared-tag"] == 2;
}

test "archive, unarchive and delete" {
    made = create_bookmark(root, draft("https://arch.example"));
    assert archive_bookmark(made).is_archived;
    assert not unarchive_bookmark(made).is_archived;
    delete_bookmark(made);
    assert made not in list_bookmarks(root);
    assert find_existing(root, "https://arch.example") is None;
}

test "tag counts come in name order ignoring case" {
    create_bookmark(root, draft("https://order.example", "zz-ord, AA-ord, mm-ord"));
    names = [n for n in tag_counts(root).keys() if n.endswith("-ord")];
    assert names == ["AA-ord", "mm-ord", "zz-ord"];
}
