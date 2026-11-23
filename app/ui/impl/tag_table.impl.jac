impl TagTable -> JsxElement {
    # WORKAROUND(GAP-043): one state each, not an obj of the server's space.
    has rows: list[TagRow] = [];
    has total: int = 0;
    has sort: str = "name_asc";
    has unused: bool = False;
    has draft: str = "";
    has removing: int = 0;
    (params, setParams) = useSearchParams();
    search = params.get("search") or "";

    count_text = (
        "Showing " + str(len(rows)) + " of " + str(total) + " tags"
            if search.strip() != "" or unused
            else str(total) + " tags total"
    );

    async def load(wanted_sort: str, wanted_unused: bool) {
        got = await tag_table(search, wanted_sort, wanted_unused);
        rows = got.rows;
        total = got.total;
    }

    can with [search] entry {
        draft = search;
    }

    async can with [search, sort, unused] entry {
        if await sign_in() {
            await load(sort, unused);
        }
    }

    def choose_sort(e: any) {
        sort = e.target.value;
    }

    def choose_unused(e: any) {
        unused = e.target.checked;
    }

    async def confirm_removal {
        await remove_tag(removing);
        removing = 0;
        await load(sort, unused);
    }

    return <main aria-label="Tags">
        <SiteNav />
        <h1>Tags</h1>
        <a href="/tags/new">Create Tag</a>
        <form method="get" action="/tags">
            <label htmlFor="search">Search tags</label>
            <input
                id="search"
                name="search"
                value={draft}
                onInput={lambda (e: any) { draft = e.target.value; }}
            />
            <button type="submit">Search</button>
            <label htmlFor="sort">Sort by</label>
            <select id="sort" value={sort} onChange={choose_sort}>
                <option value="name_asc">Name A-Z</option>
                <option value="name_desc">Name Z-A</option>
                <option value="count_asc">Fewest bookmarks</option>
                <option value="count_desc">Most bookmarks</option>
            </select>
            <label><input type="checkbox" checked={unused} onChange={choose_unused} />
                Show only unused tags
            </label>
        </form>
        <p>{count_text}</p>
        <table>
            <thead><tr><th>Name</th><th>Bookmarks</th><th>Actions</th></tr></thead>
            <tbody>
                {[
                    <tr key={r.id}>
                        <td>{r.name}</td>
                        <td><a href={"/bookmarks?q=%23" + r.name}>{str(r.count)}</a></td>
                        <td>
                            <a href={"/tags/" + str(r.id) + "/edit"}>Edit</a>
                            {" "}
                            <button
                                type="button"
                                onClick={lambda { removing = r.id; }}
                            >Remove</button>
                        </td>
                    </tr>
                    for r in rows
                ]}
            </tbody>
        </table>
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
