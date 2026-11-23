"""API checks for /api/tags/: list, create, get, delete and errors."""

TAG_FIELDS = {"id", "name", "date_added"}


def test_requires_a_token(anonymous):
    response = anonymous.get("/tags/")
    assert response.status_code == 401
    assert response.json() == {"detail": "Authentication credentials were not provided."}


def test_list_has_pagination_envelope(api):
    body = api.get("/tags/").json()
    assert set(body) == {"count", "next", "previous", "results"}


def test_create_returns_tag_fields(make_tag, unique):
    created = make_tag()
    assert set(created) == TAG_FIELDS
    assert created["name"] == f"{unique}-t"


def test_create_existing_name_returns_same_tag(api, make_tag):
    first = make_tag()
    again = api.post("/tags/", json={"name": first["name"]})
    assert again.status_code == 201
    assert again.json()["id"] == first["id"]


def test_create_without_name_is_rejected(api):
    response = api.post("/tags/", json={})
    assert response.status_code == 400
    assert response.json() == {"name": ["This field is required."]}


def test_get_returns_the_tag(api, make_tag):
    created = make_tag()
    response = api.get(f"/tags/{created['id']}/")
    assert response.status_code == 200
    assert response.json() == created


def test_get_unknown_id_is_404(api):
    response = api.get("/tags/999999999/")
    assert response.status_code == 404
    assert response.json() == {"detail": "No Tag matches the given query."}


def test_list_contains_created_tag(api, make_tag):
    created = make_tag()
    names = [tag["name"] for tag in api.get("/tags/", params={"limit": 1000}).json()["results"]]
    assert created["name"] in names


def test_bookmark_tags_appear_in_tag_list(api, make_bookmark, unique):
    make_bookmark(tag_names=[f"{unique}-viabookmark"])
    names = [tag["name"] for tag in api.get("/tags/", params={"limit": 1000}).json()["results"]]
    assert f"{unique}-viabookmark" in names
    # Tags made through a bookmark are not removed with it, so remove this one here.
    tag_id = next(t["id"] for t in api.get("/tags/", params={"limit": 1000}).json()["results"] if t["name"] == f"{unique}-viabookmark")
    assert api.delete(f"/tags/{tag_id}/").status_code == 204


def test_list_paginates(api, make_tag):
    make_tag("p1")
    make_tag("p2")
    body = api.get("/tags/", params={"limit": 1}).json()
    assert len(body["results"]) == 1
    assert body["count"] >= 2
    assert "offset=1" in body["next"]


def test_put_is_not_allowed(api, make_tag):
    created = make_tag()
    response = api.put(f"/tags/{created['id']}/", json={"name": "other"})
    assert response.status_code == 405
    assert response.json() == {"detail": 'Method "PUT" not allowed.'}


def test_delete_removes_the_tag(api, make_tag):
    created = make_tag()
    assert api.delete(f"/tags/{created['id']}/").status_code == 204
    assert api.get(f"/tags/{created['id']}/").status_code == 404


def test_delete_unknown_id_is_404(api):
    response = api.delete("/tags/999999999/")
    assert response.status_code == 404
    assert response.json() == {"detail": "No Tag matches the given query."}
