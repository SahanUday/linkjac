import json;

def answer(method: str, path: str, body: str = "", query: str = "") -> ApiReply {
    return handle(method, path, query, body, "http://test");
}

test "tags are made, listed in pages, fetched and deleted through the API" {
    made = answer("POST", "/api/tags/", "{\"name\": \"rest-tag\"}");
    assert made.status == 201;
    tag_id = json.loads(made.body)["id"];
    again = answer("POST", "/api/tags/", "{\"name\": \"REST-TAG\"}");
    assert json.loads(again.body)["id"] == tag_id;
    assert answer("GET", f"/api/tags/{tag_id}/").status == 200;
    assert answer("PUT", f"/api/tags/{tag_id}/", "{}").status == 405;
    paged = json.loads(answer("GET", "/api/tags/", "", "limit=1").body);
    assert len(paged["results"]) == 1 and "limit=1" in (paged["next"] or "limit=1");
    assert answer("DELETE", f"/api/tags/{tag_id}/").status == 204;
    assert answer("GET", f"/api/tags/{tag_id}/").status == 404;
}

test "a bookmark is made, changed in part, changed whole and deleted through the API" {
    made = answer(
        "POST", "/api/bookmarks/", "{\"url\": \"https://rest.example/a\", \"title\": \"A\"}"
    );
    assert made.status == 201;
    bookmark_id = json.loads(made.body)["id"];
    patched = answer("PATCH", f"/api/bookmarks/{bookmark_id}/", "{\"notes\": \"n\"}");
    assert json.loads(patched.body)["title"] == "A" and json.loads(patched.body)["notes"] == "n";
    assert answer("PUT", f"/api/bookmarks/{bookmark_id}/", "{\"title\": \"x\"}").status == 400;
    assert answer("DELETE", f"/api/bookmarks/{bookmark_id}/").status == 204;
    assert answer("DELETE", f"/api/bookmarks/{bookmark_id}/").status == 404;
}

test "a second bookmark cannot take the url of another when it is changed" {
    first = json.loads(
        answer("POST", "/api/bookmarks/", "{\"url\": \"https://dup.example/1\"}").body
    );
    second = json.loads(
        answer("POST", "/api/bookmarks/", "{\"url\": \"https://dup.example/2\"}").body
    );
    clash = answer("PATCH", f"/api/bookmarks/{second['id']}/", json.dumps({"url": first["url"]}));
    assert clash.status == 400;
    assert json.loads(clash.body) == {"url": ["A bookmark with this URL already exists."]};
}
