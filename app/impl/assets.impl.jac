impl snapshots_enabled -> bool {
    return os.getenv("LD_ENABLE_SNAPSHOTS", "").lower() in ["true", "1", "yes"];
}

impl ask_for_snapshot(owner: Root, bookmark: Bookmark) {
    if snapshots_enabled() and profile_of(owner).enable_automatic_html_snapshots {
        bookmark +>:HasAsset:+> Asset(id=next_asset_id(owner), date_created=now_utc());
    }
}

impl assets_of(bookmark: Bookmark) -> list[Asset] {
    return sorted([bookmark ->:HasAsset:->], key=lambda (a: Asset) -> int { return a.id; });
}

impl find_asset(bookmark: Bookmark, asset_id: int) -> Asset | None {
    for each in assets_of(bookmark) {
        if each.id == asset_id {
            return each;
        }
    }
    return None;
}

impl complete_snapshot(asset: Asset, bookmark: Bookmark, text: str) {
    asset.status = "complete";
    asset.content_type = "text/html";
    asset.display_name = "HTML snapshot from " + asset.date_created.strftime("%m/%d/%Y");
    asset.data = base64.b64encode(text.encode("utf-8")).decode("ascii");
    asset.file_size = len(text.encode("utf-8"));
    touch(bookmark);
}

impl fail_snapshot(asset: Asset) {
    asset.status = "failure";
}

impl delete_asset(asset: Asset) {
    remove(asset);
}
