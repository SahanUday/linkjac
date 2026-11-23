glob loading: dict[str, Job[list[str]]] = {},
     failed_at: dict[str, float] = {},
     seconds_before_retry: float = 60.0,
     snapshotting: list[tuple[Asset, Bookmark, Job[str]]] = [],
     most_snapshots_at_once: int = 2;

def collect_favicons {
    for base in list(loading.keys()) {
        started = loading[base];
        if not started.done() {
            continue;
        }
        loading.pop(base);
        try {
            got = wait started;
            keep_favicon(base, got[0], got[1]);
        } except JobFailed {
            failed_at[base] = time.time();
        }
    }
}

def may_start(base: str) -> bool {
    return base not in loading and time.time() - failed_at.get(base, 0.0) > seconds_before_retry;
}

def want_favicon(bookmark: Bookmark) {
    base = favicon_base_name(bookmark.url);
    kept = find_favicon_of_site(base);
    if kept is not None {
        bookmark.favicon_file = kept.file;
    } elif may_start(base) {
        loading[base] = flow load_favicon(provider_address(bookmark.url));
    }
}

def collect_snapshots {
    still: list[tuple[Asset, Bookmark, Job[str]]] = [];
    for (asset, bookmark, started) in snapshotting {
        if not started.done() {
            still.append((asset, bookmark, started));
            continue;
        }
        try {
            complete_snapshot(asset, bookmark, wait started);
        } except JobFailed {
            fail_snapshot(asset);
        }
    }
    snapshotting.clear();
    snapshotting.extend(still);
}

def is_snapshotting(asset: Asset) -> bool {
    return any([each[0] is asset for each in snapshotting]);
}

def want_snapshots(bookmark: Bookmark) {
    for asset in assets_of(bookmark) {
        if asset.status == "pending"
            and not is_snapshotting(asset)
            and len(snapshotting) < most_snapshots_at_once
        {
            snapshotting.append((asset, bookmark, flow load_snapshot(bookmark.url)));
        }
    }
}

impl run_background_work {
    collect_favicons();
    collect_snapshots();
    for owner in allroots() {
        profile = find_profile(owner);
        for bookmark in list_bookmarks(owner) {
            want_snapshots(bookmark);
            if profile is not None and profile.enable_favicons and not bookmark.favicon_file {
                want_favicon(bookmark);
            }
        }
    }
}
