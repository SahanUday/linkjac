import hashlib;

impl profile_of(owner: Root) -> UserProfile {
    found = [owner --> [?:UserProfile]];
    if found {
        return found[0];
    }
    return owner ++> UserProfile();
}

impl set_custom_css(profile: UserProfile, css: str) {
    profile.custom_css = css;
    profile.custom_css_hash = hashlib.md5(css.encode("utf-8")).hexdigest() if css else "";
}
