import json;

def answer(method: str, path: str, body: str = "", query: str = "") -> ApiReply {
    return handle(method, path, query, body, "http://test");
}

test "a path id that is not a plain number that fits finds nothing" {
    for text in ["abc", "-1", "99999999999999999999", "0"] {
        assert answer("GET", f"/api/bookmarks/{text}/").status == 404;
        assert answer("GET", f"/api/tags/{text}/").status == 404;
    }
}

test "tags are made, listed in pages, fetched and deleted through the API" {
    made = answer("POST", "/api/tags/", "{\"name\": \"rest-tag\"}");
    assert made.status == 201;
    tag_id = json.loads(made.body)["id"];
    again = answer("POST", "/api/tags/", "{\"name\": \"REST-TAG\"}");
    assert json.loads(again.body)["id"] == tag_id;
    assert answer("GET", f"/api/tags/{tag_id}/").status == 200;
    assert answer("PUT", f"/api/tags/{tag_id}/", "{}").status == 405;
    answer("POST", "/api/tags/", "{\"name\": \"REST-TAG-2\"}");
    paged = json.loads(answer("GET", "/api/tags/", "", "limit=1").body);
    assert len(paged["results"]) == 1 and paged["next"] is not None and "limit=1" in paged["next"];
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

test "archived bookmarks leave the list and appear in the archived list, and come back" {
    made = json.loads(
        answer(
            "POST",
            "/api/bookmarks/",
            "{\"url\": \"https://arch-rest.example\", \"title\": \"arch-rest\"}",
        ).body,
    );
    assert answer("POST", f"/api/bookmarks/{made['id']}/archive/").status == 204;
    assert answer("GET", f"/api/bookmarks/{made['id']}/archive/").status == 405;
    assert json.loads(answer("GET", "/api/bookmarks/", "", "q=arch-rest").body)["count"] == 0;
    assert json.loads(answer("GET", "/api/bookmarks/archived/", "", "q=arch-rest").body)["count"]
        == 1;
    assert answer("POST", f"/api/bookmarks/{made['id']}/unarchive/").status == 204;
    assert json.loads(answer("GET", "/api/bookmarks/", "", "q=arch-rest").body)["count"] == 1;
    assert answer("POST", "/api/bookmarks/999999999/archive/").status == 404;
}

test "the list is narrowed by unread, shared, added_since and ordered by sort" {
    a = json.loads(
        answer(
            "POST",
            "/api/bookmarks/",
            "{\"url\": \"https://v1.example\", \"title\": \"v-b\", \"unread\": true}",
        ).body,
    );
    b = json.loads(
        answer(
            "POST",
            "/api/bookmarks/",
            "{\"url\": \"https://v2.example\", \"title\": \"v-a\", \"shared\": true}",
        ).body,
    );
    assert [
        r["id"]
        for r in json.loads(answer("GET", "/api/bookmarks/", "", "q=v-&unread=yes").body)["results"]
    ] == [a["id"]];
    assert [
        r["id"]
        for r in json.loads(answer("GET", "/api/bookmarks/", "", "q=v-&shared=yes").body)["results"]
    ] == [b["id"]];
    assert [
        r["id"]
        for r in json.loads(
            answer("GET", "/api/bookmarks/", "", "q=v-&sort=title_asc").body
        )["results"]
    ] == [b["id"], a["id"]];
    since = a["date_added"];
    assert [
        r["id"]
        for r in json.loads(
            answer("GET", "/api/bookmarks/", "", f"q=v-&added_since={since}").body
        )["results"]
    ] == [b["id"]];
}

test "the profile route shows linkding's defaults, and the shared list is empty while no one shares" {
    shown = json.loads(answer("GET", "/api/user/profile/").body);
    assert shown["theme"] == "auto"
        and shown["tag_search"] == "strict"
        and shown["enable_sharing"] == False;
    answer(
        "POST",
        "/api/bookmarks/",
        "{\"url\": \"https://sh-rest.example\", \"title\": \"sh-rest\", \"shared\": true}",
    );
    assert json.loads(
        handle_public("GET", "/api/bookmarks/shared/", "q=sh-rest", "", "http://test").body
    )["count"]
        == 0;
    assert handle_public("GET", "/api/bookmarks/", "", "", "http://test").status == 401;
}
