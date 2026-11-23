impl BookmarkRow(item: ListedBookmark) -> JsxElement {
    return <li>
        <a href={item.url}>{item.title or item.url}</a>
        <span>
            {[<a key={n} href={"/bookmarks?q=%23" + n}>{"#" + n}</a> for n in item.tag_names]}
        </span>
        <p>{item.description}</p>
        <a href={"/bookmarks/" + str(item.id) + "/edit"}>Edit</a>
        <button type="button">Archive</button>
        <button type="button">Remove</button>
    </li>;
}

impl page_href(q: str, number: int) -> str {
    return "/bookmarks?q=" + encodeURIComponent(q) + "&page=" + str(number);
}

impl page -> JsxPage {
    # WORKAROUND(GAP-043): one state each, not `has data: ListPage = ListPage()`, which fails in the browser.
    has items: list[ListedBookmark] = [];
    has tags: list[ListedTag] = [];
    has pages: int = 1;
    has ready: bool = False;
    (params, setParams) = useSearchParams();
    q = params.get("q") or "";
    number = int(params.get("page") or "1");

    async can with [q, number] entry {
        if await sign_in() {
            got = await bookmark_page(q, number);
            items = got.items;
            tags = got.tags;
            pages = got.pages;
            ready = True;
        }
    }

    return <main aria-label="Bookmarks">
        <h1>Bookmarks</h1>
        <search>
            <form method="get" action="/bookmarks">
                <input
                    type="search"
                    name="q"
                    aria-label="Search for words or #tags"
                    defaultValue={q}
                />
            </form>
        </search>
        <section aria-label="Bookmark list">
            <ul>{[<BookmarkRow key={i.id} item={i} /> for i in items]}</ul>
            <ul>
                <li><a href={page_href(q, number - 1) if number > 1 else "#"}>Previous</a></li>
                {[
                    <li key={"p" + str(n)}><a href={page_href(q, n)}>{str(n)}</a></li>
                    for n in range(1, pages + 1)
                ]}
                <li><a href={page_href(q, number + 1) if number < pages else "#"}>Next</a></li>
            </ul>
        </section>
        <section aria-label="Tags">
            <h2>Tags</h2>
            {[<a key={t.name} href={"/bookmarks?q=%23" + t.name}>{t.name}</a> for t in tags]}
        </section>
    </main>;
}
