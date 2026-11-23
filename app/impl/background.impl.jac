glob loading: dict[str, Job[list[str]]] = {},
     failed_at: dict[str, float] = {},
     seconds_before_retry: float = 60.0;

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

impl run_background_work {
    collect_favicons();
    for owner in allroots() {
        profile = find_profile(owner);
        if profile is None or not profile.enable_favicons {
            continue;
        }
        for bookmark in list_bookmarks(owner) {
            if not bookmark.favicon_file {
                want_favicon(bookmark);
            }
        }
    }
}
