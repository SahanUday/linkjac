impl page -> JsxPage {
    async can with entry {
        await sign_in();
    }

    return <main aria-label="New bookmark"><h1>New bookmark</h1><BookmarkForm /></main>;
}
