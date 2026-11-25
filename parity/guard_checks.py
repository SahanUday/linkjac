"""The address guard: which addresses an app will fetch a bookmark's page from. Run by `PARITY_SUITE=guard parity/run.sh` only,
inside a network namespace (parity/netns.sh) where each address below really answers, so "not fetched" means refused.
The app runs with LD_ALLOWED_INTERNAL_HOSTS="10.88.0.0/16, NAMED.test ,.sub.test,[fd88::1]": 127.0.0.1 is not in it."""

import httpx
import pytest

from conftest import FIXTURE, eventually

PORT = FIXTURE.rsplit(":", 1)[1]

REFUSED = {
    "ten": "10.77.0.1",
    "oneseventwo": "172.16.77.1",
    "oneninetwo": "192.168.77.1",
    "metadata": "169.254.169.254",
    "carrier": "100.64.77.1",
    "loopback": "127.0.0.1",
    "loopback2": "127.0.0.2",
    "unspecified": "0.0.0.0",
    "short-loopback": "127.2",
    "decimal-ten": "172818433",
    "loopback6": "[::1]",
    "unique-local": "[fd00::1]",
    "site-local": "[fec0::1]",
    "nat64": "[64:ff9b::a4d:1]",
    "ipv4-compatible": "[::a4d:1]",
    "mapped-loopback": "[::ffff:127.0.0.1]",
    "mapped-ten": "[::ffff:10.77.0.1]",
    "localhost": "localhost",
    "name-to-loopback": "loop.test",
    "name-to-loopback6": "six.test",
    "name-to-ten": "ten.test",
    "name-past-the-suffix": "xsub.test",
    "name-with-a-public-and-a-private-address": "mixed.test",
}

FETCHED = {
    "public": "93.184.216.34",
    "public6": "[2606:4700::1111]",
    "public-name": "public.test",
    "allowed-network": "10.88.0.1",
    "allowed-network-by-name": "inrange.test",
    "allowed-network-mapped": "[::ffff:10.88.0.1]",
    "allowed-address6": "[fd88::1]",
    "allowed-name": "named.test",
    "allowed-name-in-capitals": "NAMED.TEST",
    "allowed-subdomain": "a.sub.test",
    "allowed-suffix-itself": "sub.test",
}


def page(host, case):
    return f"http://{host}:{PORT}/guard/{case}"


def answers(host, case):
    """The site really is at that address: asked directly, it serves the page."""
    return httpx.get(page(host, f"direct-{case}"), trust_env=False, timeout=5).status_code == 200


def asked_for():
    return httpx.get(f"{FIXTURE}/__seen", trust_env=False).json()


def title_of(api, url):
    response = api.get("/bookmarks/check/", params={"url": url, "ignore_cache": "true"})
    assert response.status_code == 200, response.text
    return response.json()["metadata"]["title"]


@pytest.mark.parametrize("case", REFUSED)
def test_a_page_at_an_internal_address_is_not_fetched(api, case):
    assert answers(REFUSED[case], case)
    assert title_of(api, page(REFUSED[case], case)) is None
    assert f"/guard/{case}" not in asked_for()


@pytest.mark.parametrize("case", FETCHED)
def test_a_page_at_a_public_or_allowed_address_is_fetched(api, case):
    assert title_of(api, page(FETCHED[case], case)) == "Fixture page"
    assert f"/guard/{case}" in asked_for()


@pytest.mark.parametrize("case", ["ten", "metadata", "loopback6", "localhost", "name-to-loopback"])
def test_a_redirect_from_an_allowed_address_to_an_internal_one_is_not_followed(api, case):
    assert answers(REFUSED[case], f"redirected-{case}")
    start = f"http://10.88.0.1:{PORT}/redirect-to?url={page(REFUSED[case], f'redirected-{case}')}"
    assert title_of(api, start) is None
    assert f"/guard/redirected-{case}" not in asked_for()


def test_a_redirect_to_an_allowed_address_is_followed(api):
    start = f"http://93.184.216.34:{PORT}/redirect-to?url={page('10.88.0.1', 'redirected-allowed')}"
    assert title_of(api, start) == "Fixture page"


@pytest.mark.parametrize("host,case,title", [("public.test", "tls", "Fixture page"), ("93.184.216.34", "tls-wrong-name", None)])
def test_a_page_over_https_is_read_only_when_the_certificate_names_the_host(api, host, case, title):
    secure = int(PORT) + 43
    assert httpx.get(f"https://{host}:{secure}/guard/direct-{case}", verify=False, trust_env=False, timeout=5).status_code == 200
    assert title_of(api, f"https://{host}:{secure}/guard/{case}") == title
    assert (f"/guard/{case}" in asked_for()) == (title is not None)


def test_a_new_bookmark_at_an_internal_address_gets_no_title_from_it(api):
    url = page("ten.test", "created")
    made = api.post("/bookmarks/", params={"disable_html_snapshot": ""}, json={"url": url})
    assert made.status_code == 201, made.text
    try:
        assert made.json()["title"] == "" and made.json()["description"] == ""
        assert "/guard/created" not in asked_for()
    finally:
        api.delete(f"/bookmarks/{made.json()['id']}/")


def snapshot_status(client, url):
    made = client.post("/bookmarks/", json={"url": url})
    assert made.status_code == 201, made.text
    bookmark = made.json()["id"]

    def finished():
        assets = client.get(f"/bookmarks/{bookmark}/assets/").json()["results"]
        return assets[0]["status"] if assets and assets[0]["status"] != "pending" else None

    try:
        return eventually(finished)
    finally:
        client.delete(f"/bookmarks/{bookmark}/")


def test_no_snapshot_is_made_of_a_page_at_an_internal_address(jobs_api):
    assert snapshot_status(jobs_api, page("ten.test", "snapshot-refused")) == "failure"
    assert "/guard/snapshot-refused" not in asked_for()


def test_a_snapshot_is_made_of_a_page_at_an_allowed_address(jobs_api):
    assert snapshot_status(jobs_api, page("named.test", "snapshot-allowed")) == "complete"
    assert "/guard/snapshot-allowed" in asked_for()


def test_the_favicon_provider_is_asked_wherever_it_is(jobs_api):
    """The provider is the admin's setting, not a user's address: here it is 127.0.0.1, which is not on the list."""
    made = jobs_api.post("/bookmarks/", params={"disable_html_snapshot": ""}, json={"url": "http://93.184.216.34/favicon-of-this", "title": "t", "description": "d"})
    assert made.status_code == 201, made.text
    bookmark = made.json()["id"]
    try:
        assert eventually(lambda: jobs_api.get(f"/bookmarks/{bookmark}/").json()["favicon_url"])
        assert "/favicon/93.184.216.34" in asked_for()
    finally:
        jobs_api.delete(f"/bookmarks/{bookmark}/")
