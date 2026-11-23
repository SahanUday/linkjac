"""Text sweep: every page of the target, loaded with the same data, has the same visible text as the original's."""

import difflib
import os
import re
from pathlib import Path

import pytest

from conftest import BASE_URL, QUIET, wipe_account
from ui import TARGET, sign_in

SNAPSHOTS = Path(__file__).parent / "text"
RECORD = os.environ.get("PARITY_RECORD_TEXT") == "1"

BOOKMARKS = [
    ("Alpha page", ["red", "blue"], {"description": "First one", "notes": "a note"}),
    ("Beta page", ["blue"], {"unread": True}),
    ("Gamma page", [], {}),
    ("Delta archived", ["green"], {"is_archived": True}),
]
PAGES = {
    "list": "/bookmarks",
    "archived": "/bookmarks/archived",
    "new": "/bookmarks/new",
    "edit": "/bookmarks/{first}/edit",
    "tags": "/tags",
    "tag_new": "/tags/new",
    "search": "/bookmarks?q=%23blue",
    "empty": "/bookmarks?q=zzzz",
}

# What a user reads in a form control: its label (or placeholder) and its value, the selected option for a menu.
READ_FIELDS = """() => [...document.querySelectorAll('input,textarea,select')]
  .filter(e => e.type !== 'hidden' && e.type !== 'submit' && e.offsetParent !== null)
  .map(e => (e.getAttribute('aria-label') || (e.getAttribute('aria-labelledby') && document.getElementById(e.getAttribute('aria-labelledby')).innerText) || (e.labels && e.labels[0] ? e.labels[0].textContent.trim() : '') || e.placeholder || e.name)
    + ' = ' + (e.type === 'checkbox' ? e.checked : e.tagName === 'SELECT' ? e.selectedOptions[0].text : e.value))"""
# The words of the page in document order, from its text nodes, so that CSS (which decides where innerText breaks lines) cannot change them.
READ_TEXT = """() => {
  const out = [];
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const node = walker.currentNode, parent = node.parentElement;
    if (node.textContent.trim() && parent.checkVisibility() && !['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEXTAREA'].includes(parent.tagName)) out.push(node.textContent.trim());
  }
  return out.join(' ');
}"""
# A submit button's caption is its value, which innerText leaves out.
SHOW_SUBMITS = "document.querySelectorAll('input[type=submit]').forEach(e => e.after(' ' + e.value + ' '))"

# Where the port still differs from the original on a page: (words the original has, words the port has), in page order.
# Each kind is a line of "M4 web UI" in Known deviations in PLAN.md. A difference that goes away, or a new one, fails the check.
BRAND = ("LINKDING", "")  # the original's heading text; the port has no brand
MENU = ("Settings", "Archived Tags")  # the original's Bookmarks menu holds Archived and Tags, and it has Settings
DATE_VIEW = ("<date> | View", "")  # the date link and the View link of each bookmark (no details page, no date shown)
UNREAD_MARK = ("| Unread", "")  # the unread mark of a bookmark
NOTES_TOGGLE = ("| Notes", "")  # the button that shows a bookmark's notes
BUNDLES = ("Bundles", "")  # the bundles region (bundles are not ported)
LETTER = ("b lue r ed", "blue red")  # the tag cloud puts a tag's first letter in an element of its own
TAG_BAR = ("|", "")  # the bar between a bookmark's tags and its description
KNOWN = {
    "list": [BRAND, MENU, DATE_VIEW, DATE_VIEW, UNREAD_MARK, TAG_BAR, DATE_VIEW, NOTES_TOGGLE, BUNDLES, LETTER],
    "archived": [BRAND, MENU, DATE_VIEW, BUNDLES, ("g reen", "green")],
    "new": [BRAND, MENU],
    "edit": [BRAND, MENU, ("Refresh from website Clear", ""), ("Clear Notes", "")],
    "tags": [BRAND, MENU, ("Merge Tags", ""), ("Previous 1 Next", "")],
    "search": [BRAND, MENU, DATE_VIEW, UNREAD_MARK, TAG_BAR, DATE_VIEW, NOTES_TOGGLE, BUNDLES, ("-blue r ed", "blue red")],
    "empty": [BRAND, MENU, ("bookmarklet . Bundles", "bookmarklet.")],
}


def normalised(text):
    """Whitespace collapsed to single spaces, the relative dates ("Today", "3 days ago") made one word, a tag's # dropped."""
    text = " ".join(text.split())
    text = re.sub(r"\b(Today|Yesterday|\d+ (?:day|week|month|year)s? ago)\b", "<date>", text)
    return re.sub(r"(^| )#(?=\w)", r"\1", text)  # linkding draws the # of a tag link in CSS (::before), so its text has none


def differences(original, port):
    """The runs of words that differ, as (original's words, port's words)."""
    a, b = original.split(" "), port.split(" ")
    found = difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes()
    return [(" ".join(a[i1:i2]), " ".join(b[j1:j2])) for tag, i1, i2, j1, j2 in found if tag != "equal"]


@pytest.fixture(scope="module")
def page_texts(api, browser):
    """The visible text of each page, read once with the account holding exactly the data above."""
    wipe_account(api)
    ids = []
    for number, (title, tags, more) in enumerate(BOOKMARKS):
        body = {"url": f"https://example.com/{number}", "title": title, "tag_names": tags, **more}
        response = api.post("/bookmarks/", params=QUIET, json=body)
        assert response.status_code == 201, response.text
        ids.append(response.json()["id"])
    assert api.post("/tags/", json={"name": "unused"}).status_code == 201
    context = browser.new_context()
    page = context.new_page()
    page.set_default_timeout(10000)
    try:
        sign_in(page)
        texts = {}
        for name, address in PAGES.items():
            page.goto(BASE_URL + address.format(first=ids[0]))
            page.wait_for_load_state("networkidle")
            page.evaluate(SHOW_SUBMITS)
            texts[name] = normalised(page.evaluate(READ_TEXT) + " [fields] " + " | ".join(page.evaluate(READ_FIELDS)))
    finally:
        context.close()
        wipe_account(api)
    return texts


@pytest.mark.parametrize("name", PAGES)
def test_the_visible_text_of_a_page_matches_the_original(page_texts, name):
    snapshot = SNAPSHOTS / f"{name}.txt"
    if TARGET == "original":
        if RECORD:
            SNAPSHOTS.mkdir(exist_ok=True)
            snapshot.write_text(page_texts[name] + "\n", encoding="utf-8")
        assert page_texts[name] == snapshot.read_text(encoding="utf-8").strip()
    else:
        found = differences(snapshot.read_text(encoding="utf-8").strip(), page_texts[name])
        assert found == KNOWN.get(name, []), "\n".join(map(repr, found))
