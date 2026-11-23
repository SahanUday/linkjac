impl sanitize_tag_name(name: str) -> str {
    return name.strip().replace(" ", "-");
}

impl parse_tag_string(text: str, delimiter: str = ",") -> list[str] {
    if not text {
        return [];
    }
    first_seen: dict[str, str] = {};
    for raw in text.strip().split(delimiter) {
        if not raw.strip() {
            continue;
        }
        name = sanitize_tag_name(raw);
        if name.lower() not in first_seen {
            first_seen[name.lower()] = name;
        }
    }
    return [first_seen[key] for key in sorted(first_seen.keys())];
}

impl find_tag(owner: Root, called: str) -> Tag | None {
    for tag in [owner --> [?:Tag]] {
        if tag.name.lower() == called.lower() {
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
    return owner ++> Tag(name=called, date_added=now_utc());
}
