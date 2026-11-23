"""Page snapshots: a bookmark of an account that wants them gets an asset that is filled in some time later, with the page as it was."""

import httpx
import pytest

from conftest import FIXTURE, eventually

NO_SCRAPING = {"disable_scraping": ""}


def make(client, url, **params):
    response = client.post("/bookmarks/", params={**NO_SCRAPING, **params}, json={"url": url})
    assert response.status_code == 201, response.text
    return response.json()


def assets_of(client, bookmark_id):
    response = client.get(f"/bookmarks/{bookmark_id}/assets/")
    assert response.status_code == 200, response.text
    body = response.json()
    return body["results"] if isinstance(body, dict) else body


def finished(client, bookmark_id):
    def read():
        found = assets_of(client, bookmark_id)
        return found[0] if found and found[0]["status"] != "pending" else None

    return eventually(read)


def test_a_snapshot_is_asked_for_when_the_bookmark_is_made(jobs_api, unique):
    made = make(jobs_api, f"{FIXTURE}/page?{unique}")
    first = assets_of(jobs_api, made["id"])
    assert len(first) == 1 and first[0]["status"] in ("pending", "complete")
    assert first[0]["asset_type"] == "snapshot" and first[0]["bookmark"] == made["id"]


def test_the_snapshot_is_filled_in_and_holds_the_page(jobs_api, unique):
    made = make(jobs_api, f"{FIXTURE}/page?{unique}")
    done = finished(jobs_api, made["id"])
    assert done["status"] == "complete" and done["content_type"] == "text/html"
    assert done["display_name"].startswith("HTML snapshot from ") and done["file_size"] > 0
    download = jobs_api.get(f"/bookmarks/{made['id']}/assets/{done['id']}/download/")
    assert download.status_code == 200 and download.headers["content-type"].startswith("text/html")
    assert "Fixture page" in download.text and "attachment" in download.headers["content-disposition"]
    assert jobs_api.get(f"/bookmarks/{made['id']}/").json()["date_modified"] > made["date_modified"]


def test_a_page_that_cannot_be_read_ends_as_a_failure(jobs_api, unique):
    made = make(jobs_api, f"http://127.0.0.1:9/{unique}")
    assert finished(jobs_api, made["id"])["status"] == "failure"


def test_no_snapshot_when_it_is_disabled_in_the_request(jobs_api, unique):
    made = make(jobs_api, f"{FIXTURE}/page?{unique}", disable_html_snapshot="")
    assert assets_of(jobs_api, made["id"]) == []


def test_an_account_that_does_not_want_snapshots_gets_none(api, unique):
    made = make(api, f"{FIXTURE}/page?{unique}")
    assert assets_of(api, made["id"]) == []
    api.delete(f"/bookmarks/{made['id']}/")


def test_an_asset_can_be_removed_and_is_the_owners_alone(jobs_api, other_api, unique):
    made = make(jobs_api, f"{FIXTURE}/page?{unique}")
    done = finished(jobs_api, made["id"])
    assert other_api.get(f"/bookmarks/{made['id']}/assets/").status_code == 404
    assert jobs_api.delete(f"/bookmarks/{made['id']}/assets/{done['id']}/").status_code == 204
    assert assets_of(jobs_api, made["id"]) == []
    assert jobs_api.get(f"/bookmarks/{made['id']}/assets/{done['id']}/").status_code == 404


def test_a_page_at_an_address_that_is_not_allowed_ends_as_a_failure(jobs_api, unique):
    made = make(jobs_api, f"{FIXTURE.replace('127.0.0.1', '127.0.0.2')}/page?{unique}")
    assert finished(jobs_api, made["id"])["status"] == "failure"


def test_making_the_same_bookmark_again_does_not_ask_for_a_second_snapshot(jobs_api, unique):
    made = make(jobs_api, f"{FIXTURE}/page?{unique}")
    again = make(jobs_api, f"{FIXTURE}/page?{unique}")
    assert again["id"] == made["id"]
    assert len(assets_of(jobs_api, made["id"])) == 1
