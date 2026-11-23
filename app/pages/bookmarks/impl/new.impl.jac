impl page -> JsxPage {
    has url: str = "";
    has tag_string: str = "";
    has title: str = "";
    has description: str = "";
    has notes: str = "";
    has unread: bool = False;
    has url_error: str = "";

    async can with entry {
        await sign_in();
    }

    async def save(e: any) {
        e.preventDefault();
        result = await save_bookmark(url, title, description, notes, tag_string, unread);
        if result.saved {
            navigate("/bookmarks");
        } else {
            url_error = result.url_error;
        }
    }

    return <main aria-label="New bookmark">
        <h1>New bookmark</h1>
        <form onSubmit={save}>
            <label htmlFor="id_url">URL</label>
            <input
                id="id_url"
                required={True}
                value={url}
                onInput={lambda (e: any) { url = e.target.value; }}
            />
            {[<ul key="e"><li>{url_error}</li></ul> for _ in range(1) if url_error != ""]}
            <label htmlFor="id_tags">Tags</label>
            <input
                id="id_tags"
                value={tag_string}
                onInput={lambda (e: any) { tag_string = e.target.value; }}
            />
            <label htmlFor="id_title">Title</label>
            <input
                id="id_title"
                value={title}
                onInput={lambda (e: any) { title = e.target.value; }}
            />
            <label htmlFor="id_description">Description</label>
            <textarea
                id="id_description"
                value={description}
                onInput={lambda (e: any) { description = e.target.value; }}
            />
            <details>
                <summary>Notes</summary>
                <textarea
                    aria-label="Notes"
                    value={notes}
                    onInput={lambda (e: any) { notes = e.target.value; }}
                />
            </details>
            <label><input
                type="checkbox"
                checked={unread}
                onChange={lambda (e: any) { unread = e.target.checked; }}
            />
                Mark as unread
            </label>
            <button type="submit">Save</button>
            <a href="/bookmarks">Cancel</a>
        </form>
    </main>;
}
