impl page -> JsxPage {
    async can with entry {
        if await sign_in() {
            navigate("/bookmarks");
        }
    }

    return <main aria-label="Linkjac"><h1>Linkjac</h1></main>;
}
