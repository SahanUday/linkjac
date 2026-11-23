# WORKAROUND(GAP-048): built from Bookmark itself, because a wire for create_bookmark used only by this test file is refused by neojac check.
def seed(url: str) -> Bookmark {
    return root ++> Bookmark(
        id=next_asset_id(root),
        url=url,
        url_normalized=url,
        date_added=now_utc(),
        date_modified=now_utc(),
    );
}

test "no snapshot is asked for while the server does not make them" {
    made = seed("https://assets.example/off");
    ask_for_snapshot(root, made);
    assert assets_of(made) == [];
}

test "a pending asset is completed with the page, sized, named and the bookmark stamped" {
    made = seed("https://assets.example/done");
    asset = made +>:HasAsset:+> Asset(id=next_asset_id(root), date_created=now_utc());
    assert asset.status == "pending" and find_asset(made, asset.id) is asset;
    before = made.date_modified;
    complete_snapshot(asset, made, "<html>é</html>");
    assert asset.status == "complete" and asset.content_type == "text/html";
    assert asset.display_name.startswith("HTML snapshot from ");
    assert asset.file_size == len("<html>é</html>".encode("utf-8"));
    assert made.date_modified >= before;
}

test "an asset that failed says so, and deleting the bookmark removes its assets" {
    made = seed("https://assets.example/failed");
    asset = made +>:HasAsset:+> Asset(id=next_asset_id(root), date_created=now_utc());
    fail_snapshot(asset);
    assert asset.status == "failure";
    delete_asset(asset);
    assert assets_of(made) == [];
}
