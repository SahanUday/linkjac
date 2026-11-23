"""The tags page: the table of tags with their counts, search, sort, the unused filter, and creating, renaming and removing a tag."""

import time

from conftest import BASE_URL
from ui import items_of


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


def open_tags(ui, search=""):
    ui.goto(f"{BASE_URL}/tags?search={search}")
    ui.get_by_role("heading", name="Tags", level=1).wait_for()
    ui.wait_for_load_state("networkidle")


def rows_of(ui):
    """The table's tags as (name, bookmark count) in page order."""
    ui.wait_for_load_state("networkidle")
    found = []
    for row in ui.get_by_role("row").filter(has=ui.get_by_role("cell")).all():
        cells = row.get_by_role("cell").all_inner_texts()
        found.append((cells[0].strip(), cells[1].strip()))
    return found


def tag_id(api, name):
    return next(t["id"] for t in api.get("/tags/", params={"limit": 1000}).json()["results"] if t["name"] == name)


def tag_names(api):
    return {t["name"] for t in api.get("/tags/", params={"limit": 1000}).json()["results"]}


def row_of(ui, name):
    return ui.get_by_role("row").filter(has=ui.get_by_role("cell", name=name, exact=True))


def three_tags(make_bookmark, make_tag, unique):
    make_bookmark(tag_names=[f"{unique}-a"])
    make_bookmark(tag_names=[f"{unique}-a", f"{unique}-b"])
    make_tag("c")


def test_the_table_lists_tags_with_their_bookmark_counts(ui, make_bookmark, make_tag, unique):
    three_tags(make_bookmark, make_tag, unique)
    open_tags(ui, unique)
    soon(lambda: rows_of(ui), [(f"{unique}-a", "2"), (f"{unique}-b", "1"), (f"{unique}-c", "0")])


def test_the_search_box_narrows_the_table(ui, make_bookmark, make_tag, unique):
    three_tags(make_bookmark, make_tag, unique)
    open_tags(ui)
    ui.get_by_label("Search tags").fill(f"{unique}-b")
    ui.get_by_role("button", name="Search").click()
    soon(lambda: rows_of(ui), [(f"{unique}-b", "1")])


def test_the_sort_choice_reorders_the_table(ui, make_bookmark, make_tag, unique):
    three_tags(make_bookmark, make_tag, unique)
    open_tags(ui, unique)
    ui.get_by_label("Sort by").select_option(label="Name Z-A")
    soon(lambda: [r[0] for r in rows_of(ui)], [f"{unique}-c", f"{unique}-b", f"{unique}-a"])
    ui.get_by_label("Sort by").select_option(label="Most bookmarks")
    soon(lambda: [r[1] for r in rows_of(ui)], ["2", "1", "0"])
    ui.get_by_label("Sort by").select_option(label="Fewest bookmarks")
    soon(lambda: [r[1] for r in rows_of(ui)], ["0", "1", "2"])


def test_the_unused_filter_shows_only_tags_with_no_bookmark(ui, make_bookmark, make_tag, unique):
    three_tags(make_bookmark, make_tag, unique)
    open_tags(ui, unique)
    ui.get_by_label("Show only unused tags").check()
    soon(lambda: rows_of(ui), [(f"{unique}-c", "0")])


def test_a_count_links_to_the_bookmarks_of_the_tag(ui, make_bookmark, make_tag, unique):
    three_tags(make_bookmark, make_tag, unique)
    open_tags(ui, unique)
    row_of(ui, f"{unique}-b").get_by_role("link", name="1", exact=True).click()
    ui.get_by_role("heading", name="Bookmarks", level=1).wait_for()
    assert "/bookmarks" in ui.url and f"{unique}-b" in ui.url.replace("%23", "#")
    assert len(items_of(ui)) == 1


def test_creating_a_tag_makes_it_with_hyphens_for_spaces(ui, api, unique):
    name = f"{unique}-new"
    open_tags(ui, unique)
    ui.get_by_role("link", name="Create Tag").click()
    ui.get_by_role("heading", name="Create Tag").wait_for()
    ui.get_by_label("Name").fill(f"{unique} new")
    ui.get_by_role("button", name="Save").click()
    ui.wait_for_load_state("networkidle")
    try:
        soon(lambda: name in tag_names(api), True)
        open_tags(ui, unique)
        soon(lambda: rows_of(ui), [(name, "0")])
    finally:
        api.delete(f"/tags/{tag_id(api, name)}/")


def test_editing_a_tag_renames_it(ui, api, make_bookmark, unique):
    made = make_bookmark(tag_names=[f"{unique}-old"])
    open_tags(ui, unique)
    row_of(ui, f"{unique}-old").get_by_role("link", name="Edit").click()
    ui.get_by_role("heading", name="Edit Tag").wait_for()
    assert ui.get_by_label("Name").input_value() == f"{unique}-old"
    ui.get_by_label("Name").fill(f"{unique}-renamed")
    ui.get_by_role("button", name="Save").click()
    try:
        soon(lambda: api.get(f"/bookmarks/{made['id']}/").json()["tag_names"], [f"{unique}-renamed"])
        open_tags(ui, unique)
        soon(lambda: rows_of(ui), [(f"{unique}-renamed", "1")])
    finally:
        api.delete(f"/tags/{tag_id(api, f'{unique}-renamed')}/")


def test_removing_a_tag_asks_first_and_then_removes_it(ui, api, make_bookmark, make_tag, unique):
    made = make_bookmark(tag_names=[f"{unique}-gone", f"{unique}-kept"])
    open_tags(ui, unique)
    row_of(ui, f"{unique}-gone").get_by_role("button", name="Remove").click()
    ui.get_by_role("alertdialog", name="Are you sure?").get_by_role("button", name="Cancel").click()
    soon(lambda: f"{unique}-gone" in tag_names(api), True)
    row_of(ui, f"{unique}-gone").get_by_role("button", name="Remove").click()
    ui.get_by_role("alertdialog", name="Are you sure?").get_by_role("button", name="Confirm").click()
    soon(lambda: f"{unique}-gone" in tag_names(api), False)
    assert api.get(f"/bookmarks/{made['id']}/").json()["tag_names"] == [f"{unique}-kept"]
    open_tags(ui, unique)
    soon(lambda: [r[0] for r in rows_of(ui)], [f"{unique}-kept"])
    api.delete(f"/tags/{tag_id(api, f'{unique}-kept')}/")
