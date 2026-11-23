impl sorted_rows(rows: list[TagRow], sort: str) -> list[TagRow] {
    by_name = sorted(rows, key=row_name_key);
    if sort == "name_desc" {
        return list(reversed(by_name));
    }
    if sort == "count_desc" {
        return sorted(by_name, key=row_count_key, reverse=True);
    }
    if sort == "count_asc" {
        return sorted(by_name, key=row_count_key);
    }
    return by_name;
}

impl tag_table(search: str, sort: str, unused: bool) -> TagTable {
    counts = tag_counts(root);
    everything = [
        TagRow(id=t.id, name=t.name, count=counts.get(t.name, 0))
        for t in list_tags(root)
    ];
    wanted = name_key(search.strip());
    rows = [r for r in everything if wanted in name_key(r.name) and (not unused or r.count == 0)];
    return TagTable(rows=sorted_rows(rows, sort), total=len(everything));
}

impl tag_name(tag_id: int) -> str {
    tag = find_tag_by_id(root, tag_id);
    return "" if tag is None else tag.name;
}

impl save_tag(tag_id: int, name: str) -> str {
    clean = sanitize_tag_name(name);
    if clean == "" {
        return "Enter a tag name.";
    }
    if tag_id == 0 {
        if find_tag(root, clean) is not None {
            return "Tag \"" + clean + "\" already exists.";
        }
        find_or_make_tag(root, clean);
        return "";
    }
    tag = find_tag_by_id(root, tag_id);
    if tag is None {
        return "This tag does not exist.";
    }
    if not rename_tag(root, tag, clean) {
        return "Tag \"" + clean + "\" already exists.";
    }
    return "";
}

impl remove_tag(tag_id: int) {
    tag = find_tag_by_id(root, tag_id);
    if tag is not None {
        delete_tag(tag);
    }
}

impl row_name_key(row: TagRow) -> str {
    return name_key(row.name);
}

impl row_count_key(row: TagRow) -> int {
    return row.count;
}
