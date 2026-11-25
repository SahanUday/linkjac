"""Browser fixtures for the UI parity checks: one signed-in page on the target, found by role and name."""

import glob
import os
import re
import time

import pytest
from playwright.sync_api import sync_playwright

from conftest import BASE_URL

TARGET = os.environ.get("PARITY_TARGET", "original")
# A browser already on this machine (PARITY_CHROME names one); the newest Playwright wants a build that is not here.
FOUND = sorted(glob.glob(os.path.expanduser("~/.cache/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell")))
CHROME = os.environ.get("PARITY_CHROME") or (FOUND[-1] if FOUND else None)


def expected_gap_on_port(gap_id):
    """Marks a check that the original passes and the port cannot yet: on the port it still runs and must fail."""
    return pytest.mark.xfail(TARGET == "port", reason=gap_id, strict=True)  # gaps-ok


def submit_credentials(page, username, password):
    """Fills the target's own sign-in form and presses its button."""
    page.get_by_label("Username").fill(username)
    page.get_by_label("Password").fill(password)
    page.get_by_role("button", name="Login").click()


def sign_in(page):
    """Signs the parity user in through the target's own sign-in."""
    if TARGET == "original":
        page.goto(f"{BASE_URL}/login/")
        submit_credentials(page, "parity", "parity-pass")
        page.wait_for_url(f"{BASE_URL}/bookmarks*")
    else:
        page.goto(f"{BASE_URL}/bookmarks")
        submit_credentials(page, "parity", "parity-pass")
        page.get_by_role("heading", name="Bookmarks", level=1).wait_for()
        page.get_by_label("Username").wait_for(state="detached")


@pytest.fixture(scope="session")
def browser():
    with sync_playwright() as pw:
        found = pw.chromium.launch(executable_path=CHROME)
        yield found
        found.close()


@pytest.fixture(scope="session")
def browser_page(browser):
    page = browser.new_page()
    page.set_default_timeout(10000)
    sign_in(page)
    yield page
    page.close()


@pytest.fixture
def visitor(browser):
    """A page in a browser context of its own, so nobody is signed in."""
    context = browser.new_context()
    page = context.new_page()
    page.set_default_timeout(10000)
    yield page
    context.close()


@pytest.fixture
def ui(browser_page):
    return browser_page


def region(page, name):
    """A named region of the page, once the page has finished loading what it shows."""
    page.wait_for_load_state("networkidle")  # the port fills the page after it loads; the original sends it in the page
    return page.get_by_role("region", name=name)


def bookmark_items(page):
    """The list items of the bookmarks, not those of the pagination under them."""
    return region(page, "Bookmark list").get_by_role("list").first.get_by_role("listitem")


def items_of(page):
    """The bookmark list's items as (title, tag names) in page order, read from each item's accessibility outline."""
    rows = []
    for item in bookmark_items(page).all():
        names = re.findall(r'link "([^"]*)"', item.aria_snapshot())
        rows.append((names[0], sorted(n for n in names[1:] if n.startswith("#"))))
    return rows


def soon(read, expected, seconds=8):
    """Asserts that `read()` comes to equal `expected` within a few seconds: pages and servers settle at their own pace."""
    deadline = time.time() + seconds
    got = None
    while time.time() < deadline:
        try:
            got = read()
            if got == expected:
                return
        except Exception as problem:  # a page in the middle of reloading has no table yet
            got = repr(problem)
        time.sleep(0.2)
    assert got == expected
