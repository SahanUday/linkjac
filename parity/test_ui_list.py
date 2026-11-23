"""The bookmark list page: its items, order, search, tags region and pagination, as a signed-in user sees them."""

import re

from conftest import BASE_URL
from ui import bookmark_items, items_of, region


def open_list(ui, tag, extra=""):
    ui.goto(f"{BASE_URL}/bookmarks?q=%23{tag}{extra}")
    ui.get_by_role("heading", name="Bookmarks", level=1).wait_for()


def test_the_list_shows_title_tags_and_actions_newest_first(ui, make_bookmark, unique):
    tag = f"{unique}-a"
    make_bookmark(title="First one", tag_names=[tag, "b-" + unique])
    make_bookmark(title="Second one", tag_names=[tag])
    make_bookmark(url=f"https://example.com/{unique}/bare", tag_names=[tag])
    open_list(ui, tag)
    rows = items_of(ui)
    assert [r[0] for r in rows] == [f"https://example.com/{unique}/bare", "Second one", "First one"]
    assert rows[2][1] == sorted([f"#{tag}", f"#b-{unique}"])
    first = bookmark_items(ui).last
    for name in ("Edit", "Archive", "Remove"):
        assert first.get_by_role("link" if name == "Edit" else "button", name=name).count() == 1, name


def test_the_description_is_shown_with_its_bookmark(ui, make_bookmark, unique):
    tag = f"{unique}-d"
    make_bookmark(title="Described", description="About this thing", tag_names=[tag])
    open_list(ui, tag)
    assert region(ui, "Bookmark list").get_by_text("About this thing").count() == 1


def test_a_query_with_no_match_lists_nothing(ui, unique):
    open_list(ui, f"{unique}-none")
    assert bookmark_items(ui).count() == 0


def test_a_search_filters_the_list(ui, make_bookmark, unique):
    tag = f"{unique}-s"
    make_bookmark(title=f"needle {unique}", tag_names=[tag])
    make_bookmark(title="haystack", tag_names=[tag])
    ui.goto(f"{BASE_URL}/bookmarks")
    ui.get_by_role("searchbox", name="Search for words or #tags").fill(f"#{tag} needle")
    ui.keyboard.press("Enter")
    ui.wait_for_url("**q=*")
    assert [r[0] for r in items_of(ui)] == [f"needle {unique}"]


def test_the_tags_region_lists_the_tags_of_the_bookmarks(ui, make_bookmark, unique):
    tag = f"{unique}-r"
    make_bookmark(title="One", tag_names=[tag])
    open_list(ui, tag)
    assert region(ui, "Tags").get_by_role("link", name=tag, exact=False).count() == 1


def test_a_tag_link_searches_for_that_tag(ui, make_bookmark, unique):
    tag = f"{unique}-l"
    make_bookmark(title="Tagged", tag_names=[tag])
    make_bookmark(title="Untagged")
    ui.goto(f"{BASE_URL}/bookmarks")
    region(ui, "Tags").get_by_role("link", name=tag, exact=False).click()
    ui.wait_for_url("**q=*")
    assert [r[0] for r in items_of(ui)] == ["Tagged"]


def test_the_list_has_thirty_items_a_page(ui, make_bookmark, unique):
    tag = f"{unique}-p"
    for i in range(32):
        make_bookmark(title=f"item {i:02d}", tag_names=[tag])
    make_bookmark(title=f"outside {unique}")  # the newest of all, and not in the search: a page link that loses the search shows it
    open_list(ui, tag)
    first_page = [r[0] for r in items_of(ui)]
    assert len(first_page) == 30 and first_page[0] == "item 31" and first_page[-1] == "item 02"
    ui.get_by_role("link", name="Next").click()
    ui.wait_for_url("**page=2*")
    assert [r[0] for r in items_of(ui)] == ["item 01", "item 00"]
    assert re.search(r"page=1(&|$)", ui.get_by_role("link", name="Previous").get_attribute("href"))
    ui.get_by_role("link", name="Previous").click()
    ui.wait_for_url(lambda url: "page=2" not in url)
    assert [r[0] for r in items_of(ui)] == first_page
    ui.get_by_role("link", name="2", exact=True).click()
    ui.wait_for_url("**page=2*")
    assert [r[0] for r in items_of(ui)] == ["item 01", "item 00"]
