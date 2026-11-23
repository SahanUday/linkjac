"""Shared fixtures for the parity checks: an API client for the target app and the results file."""

import json
import os
import uuid

import httpx
import pytest

BASE_URL = os.environ.get("LINKDING_URL", "http://127.0.0.1:8000").rstrip("/")
TOKEN = os.environ.get("LINKDING_TOKEN", "")
TOKEN_OTHER = os.environ.get("LINKDING_TOKEN_OTHER", "")
RESULTS_PATH = os.environ.get("PARITY_RESULTS", "")
# Skips the network fetch and the web archive lookup, so checks do not depend on the internet.
QUIET = {"disable_scraping": "", "disable_html_snapshot": ""}


def expected_gap(gap_id):
    """Marks a check that cannot pass on the port yet; it still runs and must fail."""
    return pytest.mark.xfail(reason=gap_id, strict=True)  # gaps-ok


@pytest.fixture(scope="session")
def api():
    with httpx.Client(base_url=f"{BASE_URL}/api", headers={"Authorization": f"Token {TOKEN}"}, timeout=20) as client:
        yield client


@pytest.fixture(scope="session")
def other_api():
    """A client for a second account, which must never see the first account's data."""
    if not TOKEN_OTHER:
        pytest.fail("LINKDING_TOKEN_OTHER is not set: the target needs a second account")
    with httpx.Client(base_url=f"{BASE_URL}/api", headers={"Authorization": f"Token {TOKEN_OTHER}"}, timeout=20) as client:
        yield client


@pytest.fixture(scope="session")
def anonymous():
    with httpx.Client(base_url=f"{BASE_URL}/api", timeout=20) as client:
        yield client


@pytest.fixture
def unique():
    """A short token that makes urls and tag names unique to one check."""
    return uuid.uuid4().hex[:10]


@pytest.fixture
def make_bookmark(api, unique):
    """Creates bookmarks through the API and deletes them when the check ends."""
    created = []

    def make(**fields):
        body = {"url": f"https://example.com/{unique}/{len(created)}", **fields}
        response = api.post("/bookmarks/", params=QUIET, json=body)
        assert response.status_code == 201, response.text
        created.append(response.json()["id"])
        return response.json()

    yield make
    for bookmark_id in created:
        api.delete(f"/bookmarks/{bookmark_id}/")


@pytest.fixture
def make_tag(api, unique):
    """Creates tags through the API and deletes them when the check ends."""
    created = []

    def make(suffix="t"):
        response = api.post("/tags/", json={"name": f"{unique}-{suffix}"})
        assert response.status_code == 201, response.text
        created.append(response.json()["id"])
        return response.json()

    yield make
    for tag_id in created:
        api.delete(f"/tags/{tag_id}/")


def pytest_sessionfinish(session, exitstatus):
    if not RESULTS_PATH:
        return
    reporter = session.config.pluginmanager.get_plugin("terminalreporter")
    stats = reporter.stats if reporter else {}
    passed = len(stats.get("passed", []))
    total = sum(len(stats.get(kind, [])) for kind in ("passed", "failed", "error", "skipped", "xfailed", "xpassed"))  # gaps-ok
    with open(RESULTS_PATH, "w") as out:
        json.dump({"passed": passed, "total": total}, out)
        out.write("\n")
