impl usage -> str {
    return "usage: cli import <file> [--map-private-flag]\n       cli export [<file>]\nSign in first: set JAC_REMOTE_API to the server and JAC_REMOTE_TOKEN to a session's token.";
}

impl run_import(path: str, map_private_flag: bool) -> int {
    try {
        with open(path) as source {
            text = source.read();
        }
        counts = import_bookmarks(text, map_private_flag);
    } except RemoteError as e {
        print("import failed:", e.detail);
        return 1;
    } except OSError as e {
        print("could not read", path);
        return 1;
    }
    print(f"{counts['success']} bookmarks were successfully imported.");
    if counts["failed"] > 0 {
        print(f"{counts['failed']} bookmarks could not be imported.");
    }
    return 0;
}

impl run_export(path: str) -> int {
    try {
        text = export_bookmarks();
    } except RemoteError as e {
        print("export failed:", e.detail);
        return 1;
    }
    if not path {
        print(text);
        return 0;
    }
    with open(path, "w") as target {
        target.write(text);
    }
    return 0;
}

# WORKAROUND(GAP-040): the original's `import_netscape <file> <user>` names the user; here the signed-in token holder is the user.
impl run_command(args: list[str]) -> int {
    if len(args) >= 2 and args[0] == "import" {
        return run_import(args[1], "--map-private-flag" in args[2:]);
    }
    if args and args[0] == "export" and len(args) <= 2 {
        return run_export(args[1] if len(args) == 2 else "");
    }
    print(usage());
    return 2;
}
