impl BookmarkForm(
    bookmark_id: int = 0,
    url0: str = "",
    tags0: str = "",
    title0: str = "",
    description0: str = "",
    notes0: str = "",
    unread0: bool = False,
) -> JsxElement {
    # WORKAROUND(GAP-047): state named like the prop would not build.
    has url: str = url0;
    has tag_string: str = tags0;
    has title: str = title0;
    has description: str = description0;
    has notes: str = notes0;
    has unread: bool = unread0;
    has url_error: str = "";

    async def save(e: any) {
        e.preventDefault();
        result = await save_bookmark(
            bookmark_id, url, title, description, notes, tag_string, unread
        );
        if result.saved {
            navigate("/bookmarks");
        } else {
            url_error = result.url_error;
        }
    }

    return <form onSubmit={save}>
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
        <p>
            Enter any number of tags separated by space and without the hash (#). If a tag does not exist it will be automatically created.
        </p>
        <label htmlFor="id_title">Title</label>
        <input id="id_title" value={title} onInput={lambda (e: any) { title = e.target.value; }} />
        <label htmlFor="id_description">Description</label>
        <textarea
            id="id_description"
            value={description}
            onInput={lambda (e: any) { description = e.target.value; }}
        />
        <details open={notes0 != ""}>
            <summary>Notes</summary>
            <textarea
                aria-label="Notes"
                value={notes}
                onInput={lambda (e: any) { notes = e.target.value; }}
            />
            <p>Additional notes, supports Markdown.</p>
        </details>
        <label><input
            type="checkbox"
            checked={unread}
            onChange={lambda (e: any) { unread = e.target.checked; }}
        />
            Mark as unread
        </label>
        <p>
            Unread bookmarks can be filtered for, and marked as read after you had a chance to look at them.
        </p>
        <button type="submit">Save</button>
        {" "}
        <a href="/bookmarks">Cancel</a>
    </form>;
}
