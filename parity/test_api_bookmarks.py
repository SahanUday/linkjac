"""API checks for /api/bookmarks/: list, create, get, update, delete, filters and errors."""

BOOKMARK_FIELDS = {
    "id", "url", "title", "description", "notes", "web_archive_snapshot_url", "favicon_url",
    "preview_image_url", "is_archived", "unread", "shared", "tag_names", "date_added",
    "date_modified", "website_title", "website_description",
}
QUIET = {"disable_scraping": "", "disable_html_snapshot": ""}


def test_requires_a_token(anonymous):
    response = anonymous.get("/bookmarks/")
    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication credentials were not provided."}


def test_rejects_an_invalid_token(anonymous):
    response = anonymous.get("/bookmarks/", headers={"Authorization": "Token nope"})
    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid token."}


def test_list_has_pagination_envelope(api):
    body = api.get("/bookmarks/").json()
    assert set(body) == {"count", "next", "previous", "results"}


def test_create_returns_all_fields(api, make_bookmark, unique):
    created = make_bookmark(title="First", description="d", notes="n", tag_names=[f"{unique}-a", f"{unique}-b"])
    assert set(created) == BOOKMARK_FIELDS
    assert created["title"] == "First"
    assert created["description"] == "d"
    assert created["notes"] == "n"
    assert created["tag_names"] == [f"{unique}-a", f"{unique}-b"]
    assert created["is_archived"] is False
    assert created["unread"] is False
    assert created["shared"] is False


def test_create_without_url_is_rejected(api):
    response = api.post("/bookmarks/", params=QUIET, json={})
    assert response.status_code == 400
    assert response.json() == {"url": ["This field is required."]}


def test_create_with_invalid_url_is_rejected(api):
    response = api.post("/bookmarks/", params=QUIET, json={"url": "not a url"})
    assert response.status_code == 400
    assert response.json() == {"url": ["Enter a valid URL."]}


def test_create_with_existing_url_updates_that_bookmark(api, make_bookmark):
    first = make_bookmark(title="Before")
    again = api.post("/bookmarks/", params=QUIET, json={"url": first["url"], "title": "After"})
    assert again.status_code == 201
    assert again.json()["id"] == first["id"]
    assert again.json()["title"] == "After"


def test_get_returns_the_bookmark(api, make_bookmark):
    created = make_bookmark(title="Fetch me")
    response = api.get(f"/bookmarks/{created['id']}/")
    assert response.status_code == 200
    assert response.json() == created


def test_get_unknown_id_is_404(api):
    response = api.get("/bookmarks/999999999/")
    assert response.status_code == 404
    assert response.json() == {"detail": "No Bookmark matches the given query."}


def test_list_contains_created_bookmark(api, make_bookmark):
    created = make_bookmark()
    ids = [item["id"] for item in api.get("/bookmarks/", params={"limit": 1000}).json()["results"]]
    assert created["id"] in ids


def test_list_filters_by_search_text(api, make_bookmark, unique):
    make_bookmark(title=f"needle-{unique}")
    make_bookmark(title="haystack")
    body = api.get("/bookmarks/", params={"q": f"needle-{unique}"}).json()
    assert body["count"] == 1
    assert body["results"][0]["title"] == f"needle-{unique}"


def test_list_filters_by_tag(api, make_bookmark, unique):
    tagged = make_bookmark(tag_names=[f"{unique}-only"])
    make_bookmark()
    body = api.get("/bookmarks/", params={"q": f"#{unique}-only"}).json()
    assert [item["id"] for item in body["results"]] == [tagged["id"]]


def test_list_paginates_with_limit_and_offset(api, make_bookmark, unique):
    for _ in range(3):
        make_bookmark(tag_names=[f"{unique}-page"])
    first = api.get("/bookmarks/", params={"q": f"#{unique}-page", "limit": 2}).json()
    assert first["count"] == 3
    assert len(first["results"]) == 2
    assert first["previous"] is None
    assert "offset=2" in first["next"]
    second = api.get("/bookmarks/", params={"q": f"#{unique}-page", "limit": 2, "offset": 2}).json()
    assert len(second["results"]) == 1
    assert second["next"] is None
    assert second["previous"] is not None


def test_put_replaces_fields(api, make_bookmark, unique):
    created = make_bookmark(title="Old", tag_names=[f"{unique}-old"])
    response = api.put(
        f"/bookmarks/{created['id']}/",
        json={"url": created["url"], "title": "New", "tag_names": [f"{unique}-new"]},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == created["id"]
    assert body["title"] == "New"
    assert body["tag_names"] == [f"{unique}-new"]


def test_put_without_url_is_rejected(api, make_bookmark):
    created = make_bookmark()
    response = api.put(f"/bookmarks/{created['id']}/", json={"title": "No url"})
    assert response.status_code == 400
    assert response.json() == {"url": ["This field is required."]}


def test_patch_changes_only_given_fields(api, make_bookmark):
    created = make_bookmark(title="Keep", notes="old notes")
    response = api.patch(f"/bookmarks/{created['id']}/", json={"notes": "new notes"})
    assert response.status_code == 200
    body = response.json()
    assert body["notes"] == "new notes"
    assert body["title"] == "Keep"
    assert body["url"] == created["url"]


def test_patch_flags(api, make_bookmark):
    created = make_bookmark()
    body = api.patch(f"/bookmarks/{created['id']}/", json={"unread": True, "shared": True}).json()
    assert body["unread"] is True
    assert body["shared"] is True


def test_update_unknown_id_is_404(api):
    response = api.patch("/bookmarks/999999999/", json={"title": "x"})
    assert response.status_code == 404


def test_delete_removes_the_bookmark(api, make_bookmark):
    created = make_bookmark()
    response = api.delete(f"/bookmarks/{created['id']}/")
    assert response.status_code == 204
    assert response.content == b""
    assert api.get(f"/bookmarks/{created['id']}/").status_code == 404


def test_delete_unknown_id_is_404(api):
    response = api.delete("/bookmarks/999999999/")
    assert response.status_code == 404
    assert response.json() == {"detail": "No Bookmark matches the given query."}
