impl page(*rest: str) -> JsxPage {
    # WORKAROUND(GAP-044): a route cannot put a parameter before a fixed segment, so this one page takes the rest of the path.
    if len(rest) == 1 and rest[0] == "new" {
        return <TagDialog />;
    }
    if len(rest) == 2 and rest[1] == "edit" {
        return <TagDialog tag_id={int(rest[0])} />;
    }
    return <TagTable />;
}
