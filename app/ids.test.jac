test "ids count up from one for each kind and are not reused" {
    first = next_bookmark_id(root);
    second = next_bookmark_id(root);
    assert second == first + 1;
    tag_first = next_tag_id(root);
    assert next_tag_id(root) == tag_first + 1;
    assert next_bookmark_id(root) == second + 1;
}
