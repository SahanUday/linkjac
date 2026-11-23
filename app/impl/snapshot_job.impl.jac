impl load_snapshot(address: str, note: JobNote) -> str {
    note("loading", address);
    text = fetch_page(address);
    if text is None {
        raise ValueError("the page could not be read");
    }
    return text;
}
