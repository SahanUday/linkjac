impl page -> JsxPage {
    async can with entry {
        await sign_in();
    }

    return <main aria-label="New bookmark"><SiteNav /><h1>New bookmark</h1><BookmarkForm /></main>;
}
