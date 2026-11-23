test "a profile is made once with linkding's defaults" {
    first = profile_of(root);
    assert first is profile_of(root);
    assert first.theme == "auto" and first.items_per_page == 30;
    assert first.display_edit_bookmark_action and not first.enable_sharing;
    assert len([root --> [?:UserProfile]]) == 1;
}

test "custom css gets the md5 hex of its text, and none gives no hash" {
    p = profile_of(root);
    set_custom_css(p, "a{color:red}");
    assert p.custom_css_hash == "d0260dc4c188396e02f19cd5db9edaaf";
    set_custom_css(p, "");
    assert p.custom_css_hash == "";
}
