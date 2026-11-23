"""Favicons: a bookmark of an account that wants them gets its site's icon some time after it is made, from the provider the app is pointed at."""

import httpx
import pytest

from conftest import BASE_URL, FIXTURE, eventually

PNG_FILE = "http_127_0_0_1.png"


def make(client, url, **fields):
    response = client.post("/bookmarks/", params={"disable_scraping": "", "disable_html_snapshot": ""}, json={"url": url, **fields})
    assert response.status_code == 201, response.text
    return response.json()


def favicon_of(client, bookmark_id):
    return lambda: client.get(f"/bookmarks/{bookmark_id}/").json()["favicon_url"]


def test_a_bookmark_gets_the_favicon_of_its_site(jobs_api, unique):
    made = make(jobs_api, f"{FIXTURE}/page?{unique}")
    address = eventually(favicon_of(jobs_api, made["id"]))
    assert address == f"{BASE_URL}/static/{PNG_FILE}"
    icon = httpx.get(address)
    assert icon.status_code == 200 and icon.headers["content-type"] == "image/png"
    assert icon.content == httpx.get(f"{FIXTURE}/favicon/127.0.0.1").content


def test_another_bookmark_of_the_same_site_shares_the_file(jobs_api, unique):
    first = make(jobs_api, f"{FIXTURE}/page?{unique}a")
    second = make(jobs_api, f"{FIXTURE}/no-title?{unique}b")
    assert eventually(favicon_of(jobs_api, first["id"])) == eventually(favicon_of(jobs_api, second["id"]))


def test_an_account_that_does_not_want_favicons_gets_none(api, jobs_api, unique):
    unwanted = make(api, f"{FIXTURE}/page?{unique}u")
    wanted = make(jobs_api, f"{FIXTURE}/page?{unique}w")
    assert eventually(favicon_of(jobs_api, wanted["id"]))
    assert api.get(f"/bookmarks/{unwanted['id']}/").json()["favicon_url"] is None
    api.delete(f"/bookmarks/{unwanted['id']}/")


def test_a_favicon_that_is_not_there_is_not_served():
    assert httpx.get(f"{BASE_URL}/static/no_such_favicon.png").status_code == 404
