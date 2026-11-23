impl change_profile(enable_favicons: bool, enable_automatic_html_snapshots: bool) -> bool {
    profile = profile_of(root);
    profile.enable_favicons = enable_favicons;
    profile.enable_automatic_html_snapshots = enable_automatic_html_snapshots;
    return True;
}
