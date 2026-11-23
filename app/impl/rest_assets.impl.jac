def asset_json(asset: Asset, bookmark: Bookmark) -> dict[str, any] {
    return {
        "id": asset.id,
        "bookmark": bookmark.id,
        "date_created": iso_utc(asset.date_created),
        "file_size": asset.file_size if asset.status == "complete" else None,
        "asset_type": asset.asset_type,
        "content_type": asset.content_type,
        "display_name": asset.display_name,
        "status": asset.status,
    };
}

def missing_asset -> ApiReply {
    return reply_detail(404, "No BookmarkAsset matches the given query.");
}

def list_assets(call: ApiCall, bookmark: Bookmark) -> ApiReply {
    window = window_of(call);
    found = assets_of(bookmark);
    rows = [asset_json(a, bookmark) for a in found[window.offset:window.offset + window.limit]];
    return reply_json(
        200, page_of(call, f"bookmarks/{bookmark.id}/assets", window, len(found), rows)
    );
}

def one_asset(call: ApiCall, bookmark: Bookmark, segments: list[str]) -> ApiReply {
    asset = find_asset(bookmark, id_in_path(segments[0]));
    if asset is None {
        return missing_asset();
    }
    if len(segments) == 2 {
        if segments[1] != "download" {
            return reply_detail(404, "Not found.");
        }
        if call.method != "GET" {
            return reply_not_allowed(call.method);
        }
        if asset.status != "complete" {
            return reply_detail(404, "Asset file does not exist");
        }
        return reply_file(asset.content_type, asset.data, asset.display_name + ".html");
    }
    if call.method == "GET" {
        return reply_json(200, asset_json(asset, bookmark));
    }
    if call.method == "DELETE" {
        delete_asset(asset);
        return reply_empty(204);
    }
    return reply_not_allowed(call.method);
}

impl assets_route(call: ApiCall, bookmark: Bookmark, segments: list[str]) -> ApiReply {
    if not segments {
        return list_assets(call, bookmark)
            if call.method == "GET"
            else reply_not_allowed(call.method);
    }
    if len(segments) > 2 {
        return reply_detail(404, "Not found.");
    }
    return one_asset(call, bookmark, segments);
}
