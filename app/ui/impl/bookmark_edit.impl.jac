impl EditBookmark(bookmark_id: int) -> JsxElement {
    has loaded: bool = False;
    has found: bool = False;
    has url: str = "";
    has tags: str = "";
    has title: str = "";
    has description: str = "";
    has notes: str = "";
    has unread: bool = False;

    async can with [bookmark_id] entry {
        if await sign_in() {
            fields = await bookmark_fields(bookmark_id);
            found = fields.found;
            url = fields.url;
            tags = fields.tag_string;
            title = fields.title;
            description = fields.description;
            notes = fields.notes;
            unread = fields.unread;
            loaded = True;
        }
    }

    return <main aria-label="Edit bookmark">
        <SiteNav />
        <h1>Edit bookmark</h1>
        {[
            <BookmarkForm
                key="form"
                bookmark_id={bookmark_id}
                url0={url}
                tags0={tags}
                title0={title}
                description0={description}
                notes0={notes}
                unread0={unread}
            />
            for _ in range(1)
            if loaded and found
        ]}
        {[
            <p key="missing">This bookmark does not exist.</p>
            for _ in range(1)
            if loaded and not found
        ]}
    </main>;
}
