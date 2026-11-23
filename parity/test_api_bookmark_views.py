"""API checks for the list filters, sorting, archive actions, shared list and profile of /api/."""

PROFILE_FIELDS = {
    "theme", "bookmark_date_display", "bookmark_link_target", "web_archive_integration", "tag_search",
    "enable_sharing", "enable_public_sharing", "enable_favicons", "display_url", "permanent_notes",
    "search_preferences", "version",
}


def ids(api, path, **params):
    return [item["id"] for item in api.get(path, params={"limit": 1000, **params}).json()["results"]]


def test_unread_filter(api, make_bookmark, unique):
    unread = make_bookmark(unread=True, tag_names=[f"{unique}-v"])
    read = make_bookmark(tag_names=[f"{unique}-v"])
    assert ids(api, "/bookmarks/", q=f"#{unique}-v", unread="yes") == [unread["id"]]
    assert ids(api, "/bookmarks/", q=f"#{unique}-v", unread="no") == [read["id"]]
    assert sorted(ids(api, "/bookmarks/", q=f"#{unique}-v", unread="off")) == sorted([unread["id"], read["id"]])


def test_shared_filter(api, make_bookmark, unique):
    shared = make_bookmark(shared=True, tag_names=[f"{unique}-s"])
    private = make_bookmark(tag_names=[f"{unique}-s"])
    assert ids(api, "/bookmarks/", q=f"#{unique}-s", shared="yes") == [shared["id"]]
    assert ids(api, "/bookmarks/", q=f"#{unique}-s", shared="no") == [private["id"]]


def test_sort_orders(api, make_bookmark, unique):
    first = make_bookmark(title="b-title", tag_names=[f"{unique}-o"])
    second = make_bookmark(title="A-title", tag_names=[f"{unique}-o"])
    third = make_bookmark(title="c-title", tag_names=[f"{unique}-o"])
    q = f"#{unique}-o"
    assert ids(api, "/bookmarks/", q=q) == [third["id"], second["id"], first["id"]]
    assert ids(api, "/bookmarks/", q=q, sort="added_asc") == [first["id"], second["id"], third["id"]]
    assert ids(api, "/bookmarks/", q=q, sort="title_asc") == [second["id"], first["id"], third["id"]]
    assert ids(api, "/bookmarks/", q=q, sort="title_desc") == [third["id"], first["id"], second["id"]]


def test_added_since_and_modified_since(api, make_bookmark, unique):
    older = make_bookmark(tag_names=[f"{unique}-d"])
    newer = make_bookmark(tag_names=[f"{unique}-d"])
    q = f"#{unique}-d"
    assert ids(api, "/bookmarks/", q=q, added_since=older["date_added"]) == [newer["id"]]
    assert ids(api, "/bookmarks/", q=q, modified_since=older["date_modified"]) == [newer["id"]]
    assert sorted(ids(api, "/bookmarks/", q=q, added_since="not a date")) == sorted([older["id"], newer["id"]])


def test_archive_moves_a_bookmark_to_the_archived_list_and_back(api, make_bookmark, unique):
    made = make_bookmark(tag_names=[f"{unique}-a"])
    q = f"#{unique}-a"
    assert api.post(f"/bookmarks/{made['id']}/archive/").status_code == 204
    assert ids(api, "/bookmarks/", q=q) == []
    assert ids(api, "/bookmarks/archived/", q=q) == [made["id"]]
    assert api.get(f"/bookmarks/{made['id']}/").json()["is_archived"] is True
    assert api.post(f"/bookmarks/{made['id']}/unarchive/").status_code == 204
    assert ids(api, "/bookmarks/", q=q) == [made["id"]]
    assert ids(api, "/bookmarks/archived/", q=q) == []


def test_archive_actions_reject_unknown_ids_and_wrong_methods(api, make_bookmark):
    made = make_bookmark()
    assert api.post("/bookmarks/999999999/archive/").status_code == 404
    assert api.post("/bookmarks/999999999/unarchive/").status_code == 404
    response = api.get(f"/bookmarks/{made['id']}/archive/")
    assert response.status_code == 405
    assert response.json() == {"detail": 'Method "GET" not allowed.'}


def test_the_archived_list_has_the_pagination_envelope(api):
    assert set(api.get("/bookmarks/archived/").json()) == {"count", "next", "previous", "results"}


def test_the_shared_list_needs_sharing_to_be_enabled(api, anonymous, make_bookmark, unique):
    make_bookmark(shared=True, tag_names=[f"{unique}-sh"])
    assert ids(api, "/bookmarks/shared/", q=f"#{unique}-sh") == []
    response = anonymous.get("/bookmarks/shared/")
    assert response.status_code == 200
    assert set(response.json()) == {"count", "next", "previous", "results"}


def test_profile_fields(api, anonymous):
    body = api.get("/user/profile/").json()
    assert set(body) == PROFILE_FIELDS
    assert body["theme"] == "auto" and body["tag_search"] == "strict"
    assert isinstance(body["version"], str) and isinstance(body["search_preferences"], dict)
    assert anonymous.get("/user/profile/").status_code == 401
