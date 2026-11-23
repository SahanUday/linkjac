test "a tag name loses outer spaces and gets hyphens inside" {
    assert sanitize_tag_name("  my tag ") == "my-tag";
}

test "a tag string is sanitized, de-duplicated ignoring case and sorted" {
    assert parse_tag_string("web, Demo,web ,, DEMO,a b") == ["a-b", "Demo", "web"];
    assert parse_tag_string("") == [];
}

test "a tag is found ignoring case and made once" {
    first = find_or_make_tag(root, "CaseTag");
    again = find_or_make_tag(root, "casetag");
    assert first is again;
    assert first.name == "CaseTag";
    assert find_tag(root, "never-made") is None;
}

test "a tag is found by its id, listed oldest first and deleted with its links" {
    made = find_or_make_tag(root, "by-id-tag");
    assert find_tag_by_id(root, made.id) is made;
    assert made in list_tags(root);
    assert list_tags(root)[-1].id >= made.id;
    delete_tag(made);
    assert find_tag_by_id(root, made.id) is None;
}
