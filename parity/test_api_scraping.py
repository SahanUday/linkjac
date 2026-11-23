"""Creating a bookmark through the API fills an empty title and description from the page, unless disable_scraping is sent."""

import httpx
import pytest

from conftest import FIXTURE


@pytest.fixture
def create(api):
    """POSTs a bookmark with the given query parameters and removes it when the check ends."""
    made = []

    def post(body, **params):
        response = api.post("/bookmarks/", params=params, json=body)
        assert response.status_code == 201, response.text
        made.append(response.json()["id"])
        return response.json()

    yield post
    for bookmark_id in made:
        api.delete(f"/bookmarks/{bookmark_id}/")


def asked():
    return httpx.get(f"{FIXTURE}/__seen").json()


def test_an_empty_title_and_description_are_filled_from_the_page(create, unique):
    made = create({"url": f"{FIXTURE}/page?{unique}"})
    assert (made["title"], made["description"]) == ("Fixture page", "About the fixture")


def test_what_the_caller_gave_is_kept(create, unique):
    made = create({"url": f"{FIXTURE}/page?{unique}", "title": "Mine"})
    assert (made["title"], made["description"]) == ("Mine", "About the fixture")
    made = create({"url": f"{FIXTURE}/page?{unique}b", "title": "Mine", "description": "Also mine"})
    assert (made["title"], made["description"]) == ("Mine", "Also mine")
    made = create({"url": f"{FIXTURE}/page?{unique}c", "description": "Only mine"})
    assert (made["title"], made["description"]) == ("Fixture page", "Only mine")


def test_a_page_without_metadata_leaves_them_empty(create, unique):
    for path in ("no-title", "missing"):
        made = create({"url": f"{FIXTURE}/{path}?{unique}"})
        assert (made["title"], made["description"]) == ("", "")


def test_disable_scraping_fetches_nothing(create, unique):
    before = asked()
    made = create({"url": f"{FIXTURE}/page?{unique}"}, disable_scraping="")
    assert (made["title"], made["description"]) == ("", "")
    assert asked() == before


def test_the_page_is_kept_in_the_bookmark_without_a_second_change_of_its_date(api, create, unique):
    made = create({"url": f"{FIXTURE}/page?{unique}"})
    again = api.get(f"/bookmarks/{made['id']}/").json()
    assert again["title"] == "Fixture page"
    assert again["date_modified"] == made["date_modified"]


def test_an_address_that_is_not_allowed_is_not_fetched(create, unique):
    elsewhere = FIXTURE.replace("127.0.0.1", "127.0.0.2")
    before = asked()
    made = create({"url": f"{elsewhere}/page?{unique}"})
    assert made["title"] == "" and asked() == before
