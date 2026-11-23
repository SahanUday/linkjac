impl import_bookmarks(text: str, map_private_flag: bool = False) -> dict[str, int] {
    result = import_netscape(root, text, map_private_flag);
    return {"total": result.total, "success": result.success, "failed": result.failed};
}

impl export_bookmarks -> str {
    return export_netscape(list_bookmarks(root));
}
