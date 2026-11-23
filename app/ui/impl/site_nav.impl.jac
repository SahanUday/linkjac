impl SiteNav -> JsxElement {
    async def log_out {
        await sign_out();
        navigate("/");
    }

    return <nav aria-label="Site">
        <a href="/bookmarks/new">Add bookmark</a>
        <a href="/bookmarks">Bookmarks</a>
        <a href="/bookmarks/archived">Archived</a>
        <a href="/tags">Tags</a>
        <button type="button" onClick={log_out}>Logout</button>
    </nav>;
}
