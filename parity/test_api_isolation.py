"""API checks that one account cannot see or change another account's bookmarks and tags."""

import pytest

from conftest import QUIET


@pytest.fixture
def owned(api, make_bookmark, make_tag, unique):
    """A bookmark and a tag that belong to the first account, both tagged with a name only it knows."""
    tag = make_tag("iso")
    bookmark = make_bookmark(title="mine", tag_names=[tag["name"]])
    return {"tag": tag, "bookmark": bookmark, "name": tag["name"], "unique": unique}


def names(client, path, **params):
    return [row["name"] for row in client.get(path, params={"limit": 1000, **params}).json()["results"]]


def test_the_other_account_does_not_list_the_first_accounts_bookmarks(other_api, owned):
    found = other_api.get("/bookmarks/", params={"q": f"#{owned['name']}"}).json()
    assert found["count"] == 0 and found["results"] == []
    assert other_api.get("/bookmarks/", params={"q": owned["unique"]}).json()["results"] == []


def test_the_other_account_does_not_list_the_first_accounts_tags(other_api, owned):
    assert owned["name"] not in names(other_api, "/tags/")


def test_the_other_account_cannot_read_change_or_delete_the_first_accounts_bookmark(api, other_api, owned):
    path = f"/bookmarks/{owned['bookmark']['id']}/"
    assert other_api.get(path).status_code == 404
    assert other_api.put(path, json={"url": "https://example.com/taken"}).status_code == 404
    assert other_api.patch(path, json={"title": "taken"}).status_code == 404
    assert other_api.delete(path).status_code == 404
    assert api.get(path).json()["title"] == "mine"


def test_the_other_account_cannot_read_or_delete_the_first_accounts_tag(api, other_api, owned):
    path = f"/tags/{owned['tag']['id']}/"
    assert other_api.get(path).status_code == 404
    assert other_api.delete(path).status_code == 404
    assert api.get(path).json()["name"] == owned["name"]


def test_the_other_account_cannot_archive_or_unarchive_the_first_accounts_bookmark(api, other_api, owned):
    path = f"/bookmarks/{owned['bookmark']['id']}/"
    assert other_api.post(path + "archive/").status_code == 404
    assert other_api.post(path + "unarchive/").status_code == 404
    assert api.get(path).json()["is_archived"] is False


def test_the_same_url_saved_by_the_other_account_is_a_bookmark_of_its_own(api, other_api, owned):
    url = owned["bookmark"]["url"]
    response = other_api.post("/bookmarks/", params=QUIET, json={"url": url, "title": "theirs", "tag_names": [owned["name"]]})
    assert response.status_code == 201, response.text
    theirs = response.json()
    try:
        assert api.get(f"/bookmarks/{owned['bookmark']['id']}/").json()["title"] == "mine"
        mine = api.get("/bookmarks/", params={"q": f"#{owned['name']}"}).json()["results"]
        assert [row["title"] for row in mine] == ["mine"]
        others = other_api.get("/bookmarks/", params={"q": f"#{owned['name']}"}).json()["results"]
        assert [row["title"] for row in others] == ["theirs"]
    finally:
        other_api.delete(f"/bookmarks/{theirs['id']}/")


def test_a_tag_of_the_same_name_in_the_other_account_is_separate(api, other_api, owned):
    response = other_api.post("/tags/", json={"name": owned["name"]})
    assert response.status_code == 201, response.text
    theirs = response.json()
    try:
        assert other_api.delete(f"/tags/{theirs['id']}/").status_code == 204
        assert api.get(f"/tags/{owned['tag']['id']}/").status_code == 200
        assert owned["name"] in names(api, "/tags/")
    finally:
        other_api.delete(f"/tags/{theirs['id']}/")
