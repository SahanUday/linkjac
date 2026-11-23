"""Forms: the JSON linkding's API shows for a tag and a bookmark, and a bookmark's fields read from a JSON body."""

import from datetime { datetime }

"""A bookmark draft read from a body, or the messages for each field that was wrong."""
obj DraftReading {
    has draft: BookmarkDraft,
        errors: dict[str, list[str]] = {};
}

"""A UTC time as linkding's API writes it, with six digits of fraction unless it is zero, and a Z."""
def iso_utc(stamp: datetime) -> str;

"""The web archive address linkding shows for a bookmark that has no snapshot of its own."""
def archive_url_of(bookmark: Bookmark) -> str;

"""A tag as the API shows it."""
def tag_json(tag: Tag) -> dict[str, any];

"""The profile fields the API shows, and the linkding version the port answers as."""
def profile_json(profile: UserProfile) -> dict[str, any];

"""A bookmark as the API shows it, fields in linkding's order."""
def bookmark_json(bookmark: Bookmark) -> dict[str, any];

"""`start` with each field the body gives put in its place; a url is required when `url_required`."""
def read_draft(given: dict[str, any], start: BookmarkDraft, url_required: bool) -> DraftReading;
