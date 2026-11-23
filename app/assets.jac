"""Assets: the snapshot of a bookmark's page, asked for when the bookmark is made and filled in later by background work."""

import os;
import from stdjac { remove }
import base64;

"""Whether this server makes page snapshots at all: LD_ENABLE_SNAPSHOTS is true, 1 or yes, the setting linkding reads."""
def snapshots_enabled -> bool;

"""Asks for a snapshot of `bookmark`'s page if the server makes them and `owner`'s profile wants them; the asset is pending until a job fills it in."""
def ask_for_snapshot(owner: Root, bookmark: Bookmark);

"""The assets of `bookmark`, oldest first."""
def assets_of(bookmark: Bookmark) -> list[Asset];

"""The asset of `bookmark` with this id, or None."""
def find_asset(bookmark: Bookmark, asset_id: int) -> Asset | None;

"""Marks `asset` done with the page text it holds, and stamps the bookmark as changed."""
def complete_snapshot(asset: Asset, bookmark: Bookmark, text: str);

"""Removes `asset`."""
def delete_asset(asset: Asset);

"""Marks `asset` as a failure."""
def fail_snapshot(asset: Asset);
