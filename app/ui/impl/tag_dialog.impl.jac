impl TagDialog(tag_id: int = 0) -> JsxElement {
    has name: str = "";
    has problem: str = "";
    has ready: bool = False;

    async can with [tag_id] entry {
        if await sign_in() {
            if tag_id != 0 {
                name = await tag_name(tag_id);
            }
            ready = True;
        }
    }

    async def save(e: any) {
        e.preventDefault();
        message = await save_tag(tag_id, name);
        if message == "" {
            navigate("/tags");
        } else {
            problem = message;
        }
    }

    return <div>
        {[
            <form key="dialog" onSubmit={save}>
                <div role="dialog" aria-label={"Edit Tag" if tag_id != 0 else "Create Tag"}>
                    <h2>{"Edit Tag" if tag_id != 0 else "Create Tag"}</h2>
                    <label htmlFor="id_name">Name</label>
                    <input
                        id="id_name"
                        required={True}
                        value={name}
                        onInput={lambda (e: any) { name = e.target.value; }}
                    />
                    <p
                    >Tag names are case-insensitive and cannot contain spaces (spaces will be replaced with hyphens).</p>
                    {[
                        <p key="problem" role="alert">{problem}</p>
                        for _ in range(1)
                        if problem != ""
                    ]}
                    <a href="/tags">Cancel</a>
                    {" "}
                    <button type="submit">Save</button>
                </div>
            </form>
            for _ in range(1)
            if ready
        ]}
    </div>;
}
