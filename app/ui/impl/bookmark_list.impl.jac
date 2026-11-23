impl BookmarkRow(item: ListedBookmark, on_archive: any, on_remove: any) -> JsxElement {
    return <li>
        <a href={item.url}>{item.title or item.url}</a>
        <span>
            {[<a key={n} href={"/bookmarks?q=%23" + n}>{"#" + n}</a> for n in item.tag_names]}
        </span>
        <p>{item.description}</p>
        <a href={"/bookmarks/" + str(item.id) + "/edit"}>Edit</a>
        <button type="button" onClick={lambda { on_archive(item.id, not item.is_archived); }}>
            {"Unarchive" if item.is_archived else "Archive"}
        </button>
        <button type="button" onClick={lambda { on_remove(item.id); }}>Remove</button>
    </li>;
}

impl page_href(base: str, q: str, number: int) -> str {
    return base + "?q=" + encodeURIComponent(q) + "&page=" + str(number);
}

impl BookmarkList(archived: bool = False) -> JsxElement {
    # WORKAROUND(GAP-043): one state each, not `has data: ListPage = ListPage()`, which fails in the browser.
    has items: list[ListedBookmark] = [];
    has tags: list[ListedTag] = [];
    has pages: int = 1;
    has ready: bool = False;
    has removing: int = 0;
    has version: int = 0;
    (params, setParams) = useSearchParams();
    q = params.get("q") or "";
    number = int(params.get("page") or "1");
    base = "/bookmarks/archived" if archived else "/bookmarks";
    heading = "Archived bookmarks" if archived else "Bookmarks";

    async can with [q, number, archived, version] entry {
        if await sign_in() {
            got = await bookmark_page(q, number, archived);
            items = got.items;
            tags = got.tags;
            pages = got.pages;
            ready = True;
        }
    }

    async def change_archive(bookmark_id: int, wanted: bool) {
        await archive_bookmark(bookmark_id, wanted);
        version += 1;
    }

    def ask_removal(bookmark_id: int) {
        removing = bookmark_id;
    }

    async def confirm_removal {
        await remove_bookmark(removing);
        removing = 0;
        version += 1;
    }

    return <main aria-label={heading}>
        <SiteNav />
        <h1>{heading}</h1>
        <search>
            <form method="get" action={base}>
                <input
                    type="search"
                    name="q"
                    aria-label="Search for words or #tags"
                    defaultValue={q}
                />
            </form>
        </search>
        <section aria-label="Bookmark list">
            <ul>
                {[
                    <BookmarkRow
                        key={i.id}
                        item={i}
                        on_archive={change_archive}
                        on_remove={ask_removal}
                    />
                    for i in items
                ]}
            </ul>
            <ul>
                <li>
                    <a href={page_href(base, q, number - 1) if number > 1 else "#"}>Previous</a>
                </li>
                {[
                    <li key={"p" + str(n)}><a href={page_href(base, q, n)}>{str(n)}</a></li>
                    for n in range(1, pages + 1)
                ]}
                <li>
                    <a href={page_href(base, q, number + 1) if number < pages else "#"}>Next</a>
                </li>
            </ul>
        </section>
        <section aria-label="Tags">
            <h2>Tags</h2>
            {[<a key={t.name} href={base + "?q=%23" + t.name}>{t.name}</a> for t in tags]}
        </section>
        {[
            <div key="ask" role="alertdialog" aria-label="Are you sure?">
                <button type="button" onClick={lambda { removing = 0; }}>Cancel</button>
                <button type="button" onClick={confirm_removal}>Confirm</button>
            </div>
            for _ in range(1)
            if removing != 0
        ]}
    </main>;
}
