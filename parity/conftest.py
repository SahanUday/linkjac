"""Shared fixtures for the parity checks: an API client for the target app and the results file."""

import json
import os
import re
import time
import subprocess
import uuid

import httpx
import pytest

pytest_plugins = ["ui"]

BASE_URL = os.environ.get("LINKDING_URL", "http://127.0.0.1:8000").rstrip("/")
TOKEN = os.environ.get("LINKDING_TOKEN", "")
TOKEN_OTHER = os.environ.get("LINKDING_TOKEN_OTHER", "")
TOKEN_JOBS = os.environ.get("LINKDING_TOKEN_JOBS", "")
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


@pytest.fixture(scope="session")
def jobs_api():
    """A client for the account whose profile has favicons and snapshots on; the background-job checks use it alone."""
    if not TOKEN_JOBS:
        pytest.fail("LINKDING_TOKEN_JOBS is not set: the target needs an account with favicons and snapshots on")
    with httpx.Client(base_url=f"{BASE_URL}/api", headers={"Authorization": f"Token {TOKEN_JOBS}"}, timeout=20) as client:
        yield client
        wipe_account(client)


def eventually(read, seconds=40):
    """Polls `read()` until it gives something other than None or False, and returns that; the jobs run on their own time."""
    deadline = time.time() + seconds
    while time.time() < deadline:
        found = read()
        if found:
            return found
        time.sleep(0.5)
    return read()


class WebNetscape:
    """The original's import form and export view, used through a signed-in browser session."""

    def __init__(self, username="parity"):
        self.http = httpx.Client(base_url=BASE_URL, follow_redirects=False, timeout=60)
        page = self.http.get("/login/")
        form = {"username": username, "password": "parity-pass", "csrfmiddlewaretoken": self.csrf(page.text)}
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

    def __init__(self, program, tmp_path, token=TOKEN):
        self.program = program
        self.tmp_path = tmp_path
        self.env = {**os.environ, "JAC_REMOTE_API": BASE_URL, "JAC_REMOTE_TOKEN": token}

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


@pytest.fixture
def netscape_jobs(tmp_path):
    """The same import and export, for the account whose profile wants favicons and snapshots."""
    program = os.environ.get("PARITY_CLI", "")
    if program:
        yield CliNetscape(program, tmp_path, TOKEN_JOBS)
    else:
        driver = WebNetscape("parity3")
        yield driver
        driver.http.close()


class Made:
    """A token a check made: its key, and what removes it."""

    def __init__(self, key, handle):
        self.key = key
        self.handle = handle


class WebTokens:
    """The original's API tokens, made and removed on its integrations page by the signed-in user."""

    def __init__(self):
        self.web = WebNetscape()

    def page(self):
        return self.web.http.get("/settings/integrations")

    def create(self, name):
        token = WebNetscape.csrf(self.page().text)
        made = self.web.http.post("/settings/integrations/create-api-token", data={"csrfmiddlewaretoken": token, "name": name})
        assert made.status_code == 302, made.text
        page = self.page().text
        key = re.search(r'value="([0-9a-f]{40})"\s[^>]*id="new-token-key"', page).group(1)
        # The newest token is listed first.
        ident = re.search(r'name="token_id"\s+value="(\d+)"', page).group(1)
        return Made(key, ident)

    def delete(self, made):
        token = WebNetscape.csrf(self.page().text)
        self.web.http.post("/settings/integrations/delete-api-token", data={"csrfmiddlewaretoken": token, "token_id": made.handle})


class PortTokens:
    """The port's API tokens, made and removed through its auth plugin with the user's name and password."""

    def ask(self, action, **given):
        return httpx.post(f"{BASE_URL}/__jac/auth/{action}", json={"username": "parity", "password": "parity-pass", **given}, timeout=20)

    def create(self, name):
        response = self.ask("create_token", name=name)
        assert response.status_code == 200, response.text
        key = response.json()["data"]["token"]
        return Made(key, key)

    def delete(self, made):
        self.ask("delete_token", key=made.handle)


@pytest.fixture(scope="session")
def tokens():
    """Makes and removes API tokens of the parity user the way the target lets a user do it."""
    return PortTokens() if os.environ.get("PARITY_TARGET") == "port" else WebTokens()


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
