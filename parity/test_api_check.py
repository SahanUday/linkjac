"""Website metadata: /api/bookmarks/check/ reads a page of the local fixture site and says what it found."""

import httpx
import pytest

from conftest import FIXTURE

EMPTY = {"title": None, "description": None, "preview_image": None}


def check(api, url, **params):
    response = api.get("/bookmarks/check/", params={"url": url, "ignore_cache": "true", **params})
    assert response.status_code == 200, response.text
    return response.json()


def test_a_page_with_metadata_is_read(api):
    found = check(api, f"{FIXTURE}/page")
    assert found["bookmark"] is None and found["auto_tags"] == []
    assert found["metadata"] == {
        "url": f"{FIXTURE}/page",
        "title": "Fixture page",
        "description": "About the fixture",
        "preview_image": f"{FIXTURE}/image.png",
    }


def test_the_open_graph_description_is_the_second_choice(api):
    assert check(api, f"{FIXTURE}/og-description")["metadata"] == {"url": f"{FIXTURE}/og-description", "title": "Only og", "description": "From og", "preview_image": None}


def test_the_plain_description_comes_before_the_open_graph_one_and_an_absolute_image_stays(api):
    assert check(api, f"{FIXTURE}/both")["metadata"] == {"url": f"{FIXTURE}/both", "title": "Both", "description": "Plain description", "preview_image": "http://pictures.invalid/pic.png"}


def test_an_error_page_is_read_like_any_page(api):
    assert check(api, f"{FIXTURE}/gone")["metadata"]["title"] == "Gone page"


@pytest.mark.parametrize("path", ["/no-title", "/missing"])
def test_a_page_without_metadata_gives_nothing(api, path):
    assert check(api, f"{FIXTURE}{path}")["metadata"] == {"url": f"{FIXTURE}{path}", **EMPTY}


def test_a_redirect_is_followed(api):
    found = check(api, f"{FIXTURE}/redirect")["metadata"]
    assert found["title"] == "Fixture page" and found["url"] == f"{FIXTURE}/redirect"


def test_a_refused_connection_gives_nothing_and_no_error(api):
    assert check(api, "http://127.0.0.1:9/")["metadata"] == {"url": "http://127.0.0.1:9/", **EMPTY}


def test_an_address_that_is_not_allowed_is_not_fetched(api):
    elsewhere = FIXTURE.replace("127.0.0.1", "127.0.0.2")
    assert httpx.get(f"{elsewhere}/page").status_code == 200  # the site is there; only the app's guard keeps it away
    seen_before = httpx.get(f"{FIXTURE}/__seen").json()
    assert check(api, f"{elsewhere}/page")["metadata"]["title"] is None
    assert httpx.get(f"{FIXTURE}/__seen").json() == seen_before


def test_a_bookmark_that_exists_is_shown_with_the_metadata(api, make_bookmark):
    made = make_bookmark(url=f"{FIXTURE}/page", title="Mine", tag_names=["checked"])
    found = check(api, f"{FIXTURE}/page")
    assert found["bookmark"]["id"] == made["id"] and found["bookmark"]["title"] == "Mine"
    assert found["metadata"]["title"] == "Fixture page"


def test_the_check_asks_for_a_sign_in(anonymous):
    assert anonymous.get("/bookmarks/check/", params={"url": f"{FIXTURE}/page"}).status_code == 401
