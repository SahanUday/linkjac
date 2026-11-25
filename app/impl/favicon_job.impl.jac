impl load_favicon(address: str, note: JobNote) -> list[str] {
    note("loading", address);
    # Not through web_fetch: the provider is the admin's setting, which linkding does not guard.
    with urllib.request.urlopen(address, timeout=10) as response {
        return [
            response.headers.get("Content-Type") or "",
            base64.b64encode(response.read()).decode("ascii"),
        ];
    }
}
