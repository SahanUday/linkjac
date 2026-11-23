"""Profiles: each caller's settings, kept as a node under that caller's own root."""

node UserProfile {
    has theme: str = "auto",
        bookmark_date_display: str = "relative",
        bookmark_description_display: str = "inline",
        bookmark_description_max_lines: int = 1,
        bookmark_link_target: str = "_blank",
        web_archive_integration: str = "disabled",
        tag_search: str = "strict",
        tag_grouping: str = "alphabetical",
        enable_sharing: bool = False,
        enable_public_sharing: bool = False,
        enable_favicons: bool = False,
        enable_preview_images: bool = False,
        display_url: bool = False,
        display_view_bookmark_action: bool = True,
        display_edit_bookmark_action: bool = True,
        display_archive_bookmark_action: bool = True,
        display_remove_bookmark_action: bool = True,
        permanent_notes: bool = False,
        custom_css: str = "",
        custom_css_hash: str = "",
        auto_tagging_rules: str = "",
        search_preferences: dict[str, str] = {},
        enable_automatic_html_snapshots: bool = True,
        default_mark_unread: bool = False,
        default_mark_shared: bool = False,
        items_per_page: int = 30,
        sticky_pagination: bool = False,
        collapse_side_panel: bool = False,
        hide_bundles: bool = False,
        legacy_search: bool = False;
}

"""The profile of the caller who owns `owner`, made with linkding's defaults the first time."""
def profile_of(owner: Root) -> UserProfile;

"""Set the custom CSS and the hash of it that pages use to tell when it changed."""
def set_custom_css(profile: UserProfile, css: str);
