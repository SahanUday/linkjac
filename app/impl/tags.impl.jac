import from stdjac { remove }

impl name_key(name: str) -> str {
    return name.lower();
}

impl sanitize_tag_name(name: str) -> str {
    return name.strip().replace(" ", "-");
}

impl parse_tag_string(text: str, delimiter: str = ",") -> list[str] {
    if not text {
        return [];
    }
    last_seen: dict[str, str] = {};
    for raw in text.strip().split(delimiter) {
        if not raw.strip() {
            continue;
        }
        name = sanitize_tag_name(raw);
        last_seen[name_key(name)] = name;
    }
    return [last_seen[key] for key in sorted(last_seen.keys())];
}

impl find_tag(owner: Root, called: str) -> Tag | None {
    for tag in [owner --> [?:Tag]] {
        if name_key(tag.name) == name_key(called) {
            return tag;
        }
    }
    return None;
}

impl find_or_make_tag(owner: Root, called: str) -> Tag {
    found = find_tag(owner, called);
    if found is not None {
        return found;
    }
    return owner ++> Tag(id=next_tag_id(owner), name=called, date_added=now_utc());
}

impl find_tag_by_id(owner: Root, tag_id: int) -> Tag | None {
    for tag in [owner --> [?:Tag]] {
        if tag.id == tag_id {
            return tag;
        }
    }
    return None;
}

impl list_tags(owner: Root) -> list[Tag] {
    return sorted([owner --> [?:Tag]], key=tag_id_of);
}

impl rename_tag(owner: Root, tag: Tag, called: str) -> bool {
    clean = sanitize_tag_name(called);
    other = find_tag(owner, clean);
    if clean == "" or (other is not None and other.id != tag.id) {
        return False;
    }
    tag.name = clean;
    return True;
}

impl delete_tag(tag: Tag) {
    remove(tag);
}

impl tag_id_of(tag: Tag) -> int {
    return tag.id;
}
