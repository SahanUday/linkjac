"""Shared fixtures for the parity checks: an API client for the target app and the results file."""

import json
import os
import subprocess
import uuid

import httpx
import pytest

pytest_plugins = ["ui"]

BASE_URL = os.environ.get("LINKDING_URL", "http://127.0.0.1:8000").rstrip("/")
TOKEN = os.environ.get("LINKDING_TOKEN", "")
TOKEN_OTHER = os.environ.get("LINKDING_TOKEN_OTHER", "")
RESULTS_PATH = os.environ.get("PARITY_RESULTS", "")
FIXTURE = os.environ.get("FIXTURE_URL", "http://127.0.0.1:9100").rstrip("/")
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


def wipe_account(client):
    """Deletes every bookmark (live and archived) and every tag of the client's account."""
    for path in ("/bookmarks/?limit=1000", "/bookmarks/archived/?limit=1000"):
        for bookmark in client.get(path).json()["results"]:
            client.delete(f"/bookmarks/{bookmark['id']}/")
    for tag in client.get("/tags/?limit=1000").json()["results"]:
        client.delete(f"/tags/{tag['id']}/")


class WebNetscape:
    """The original's import form and export view, used through a signed-in browser session."""

    def __init__(self):
        self.http = httpx.Client(base_url=BASE_URL, follow_redirects=False, timeout=60)
        page = self.http.get("/login/")
        form = {"username": "parity", "password": "parity-pass", "csrfmiddlewaretoken": self.csrf(page.text)}
        assert self.http.post("/login/", data=form).status_code == 302

    @staticmethod
    def csrf(page):
        marker = 'name="csrfmiddlewaretoken" value="'
        start = page.index(marker) + len(marker)
        return page[start : page.index('"', start)]

    def import_text(self, text, map_private_flag=False):
        token = self.csrf(self.http.get("/settings/general").text)
        data = {"csrfmiddlewaretoken": token}
        if map_private_flag:
            data["map_private_flag"] = "on"
        files = {"import_file": ("bookmarks.html", text.encode("utf-8"), "text/html")}
        assert self.http.post("/settings/import", data=data, files=files).status_code == 302

    def export_text(self):
        response = self.http.get("/settings/export")
        assert response.status_code == 200
        return response.text


class CliNetscape:
    """The port's command-line app, which signs in with the parity user's token."""

    def __init__(self, program, tmp_path):
        self.program = program
        self.tmp_path = tmp_path
        self.env = {**os.environ, "JAC_REMOTE_API": BASE_URL, "JAC_REMOTE_TOKEN": TOKEN}

    def run(self, *args):
        done = subprocess.run([self.program, *args], env=self.env, capture_output=True, text=True, timeout=120)
        assert done.returncode == 0, done.stdout + done.stderr
        return done.stdout

    def import_text(self, text, map_private_flag=False):
        path = self.tmp_path / "import.html"
        path.write_text(text, encoding="utf-8")
        self.run("import", str(path), *(["--map-private-flag"] if map_private_flag else []))

    def export_text(self):
        path = self.tmp_path / "export.html"
        self.run("export", str(path))
        return path.read_bytes().decode("utf-8")


@pytest.fixture
def netscape(tmp_path):
    """Imports and exports Netscape files on the target: the original's web form, or the port's CLI (PARITY_CLI)."""
    program = os.environ.get("PARITY_CLI", "")
    if program:
        yield CliNetscape(program, tmp_path)
    else:
        driver = WebNetscape()
        yield driver
        driver.http.close()


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
