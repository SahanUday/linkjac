impl counter_of(owner: Root) -> IdCounter {
    found = [owner --> [?:IdCounter]];
    if found {
        return found[0];
    }
    return owner ++> IdCounter();
}

impl next_bookmark_id(owner: Root) -> int {
    counter = counter_of(owner);
    counter.last_bookmark += 1;
    return counter.last_bookmark;
}

impl next_tag_id(owner: Root) -> int {
    counter = counter_of(owner);
    counter.last_tag += 1;
    return counter.last_tag;
}

impl next_asset_id(owner: Root) -> int {
    counter = counter_of(owner);
    counter.last_asset += 1;
    return counter.last_asset;
}
