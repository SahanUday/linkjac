"""Remove, archive and unarchive on the bookmark lists: the question before a removal, and the archived list."""

from conftest import BASE_URL
from ui import bookmark_items, soon


def open_list(ui, tag, archived=False):
    ui.goto(f"{BASE_URL}/bookmarks{'/archived' if archived else ''}?q=%23{tag}")
    ui.get_by_role("heading", name="Archived bookmarks" if archived else "Bookmarks", level=1).wait_for()
    ui.wait_for_load_state("networkidle")


def item_of(ui, title):
    return bookmark_items(ui).filter(has_text=title)


def titles_on(ui, tag, archived=False):
    """The titles listed for the tag on the main or the archived list, read afresh from the page."""
    open_list(ui, tag, archived)
    return [name for name in (bookmark_items(ui).nth(i).get_by_role("link").first.inner_text() for i in range(bookmark_items(ui).count()))]


def test_removing_asks_first_and_cancel_keeps_the_bookmark(ui, api, make_bookmark, unique):
    made = make_bookmark(title=f"Keep {unique}", tag_names=[f"{unique}-k"])
    open_list(ui, f"{unique}-k")
    item_of(ui, f"Keep {unique}").get_by_role("button", name="Remove").click()
    ui.get_by_role("alertdialog", name="Are you sure?").get_by_role("button", name="Cancel").click()
    assert api.get(f"/bookmarks/{made['id']}/").status_code == 200
    assert item_of(ui, f"Keep {unique}").count() == 1


def test_confirming_a_removal_removes_the_bookmark(ui, api, make_bookmark, unique):
    gone = make_bookmark(title=f"Gone {unique}", tag_names=[f"{unique}-g"])
    kept = make_bookmark(title=f"Kept {unique}", tag_names=[f"{unique}-g"])
    open_list(ui, f"{unique}-g")
    item_of(ui, f"Gone {unique}").get_by_role("button", name="Remove").click()
    ui.get_by_role("alertdialog", name="Are you sure?").get_by_role("button", name="Confirm").click()
    soon(lambda: item_of(ui, f"Gone {unique}").count(), 0)  # the page itself is refreshed, no reload
    assert item_of(ui, f"Kept {unique}").count() == 1
    soon(lambda: api.get(f"/bookmarks/{gone['id']}/").status_code, 404)
    assert api.get(f"/bookmarks/{kept['id']}/").status_code == 200
    soon(lambda: titles_on(ui, f"{unique}-g"), [f"Kept {unique}"])


def test_archiving_moves_the_bookmark_to_the_archived_list(ui, api, make_bookmark, unique):
    made = make_bookmark(title=f"Old {unique}", tag_names=[f"{unique}-a"])
    make_bookmark(title=f"Live {unique}", tag_names=[f"{unique}-a"])
    open_list(ui, f"{unique}-a")
    item_of(ui, f"Old {unique}").get_by_role("button", name="Archive").click()
    soon(lambda: item_of(ui, f"Old {unique}").count(), 0)
    assert item_of(ui, f"Live {unique}").count() == 1
    soon(lambda: api.get(f"/bookmarks/{made['id']}/").json()["is_archived"], True)
    soon(lambda: titles_on(ui, f"{unique}-a"), [f"Live {unique}"])
    assert titles_on(ui, f"{unique}-a", archived=True) == [f"Old {unique}"]


def test_an_archived_item_offers_unarchive_and_not_archive(ui, make_bookmark, api, unique):
    made = make_bookmark(title=f"Shelved {unique}", tag_names=[f"{unique}-s"])
    api.post(f"/bookmarks/{made['id']}/archive/")
    open_list(ui, f"{unique}-s", archived=True)
    item = item_of(ui, f"Shelved {unique}")
    assert item.get_by_role("button", name="Unarchive").count() == 1
    assert item.get_by_role("button", name="Archive", exact=True).count() == 0
    assert item.get_by_role("button", name="Remove").count() == 1


def test_unarchiving_moves_the_bookmark_back(ui, api, make_bookmark, unique):
    made = make_bookmark(title=f"Back {unique}", tag_names=[f"{unique}-u"])
    api.post(f"/bookmarks/{made['id']}/archive/")
    open_list(ui, f"{unique}-u", archived=True)
    item_of(ui, f"Back {unique}").get_by_role("button", name="Unarchive").click()
    soon(lambda: item_of(ui, f"Back {unique}").count(), 0)
    soon(lambda: api.get(f"/bookmarks/{made['id']}/").json()["is_archived"], False)
    soon(lambda: titles_on(ui, f"{unique}-u", archived=True), [])
    assert titles_on(ui, f"{unique}-u") == [f"Back {unique}"]


def test_the_archived_list_holds_only_archived_bookmarks_and_can_remove_them(ui, api, make_bookmark, unique):
    shelved = make_bookmark(title=f"Shelf {unique}", tag_names=[f"{unique}-r"])
    make_bookmark(title=f"Open {unique}", tag_names=[f"{unique}-r"])
    api.post(f"/bookmarks/{shelved['id']}/archive/")
    assert titles_on(ui, f"{unique}-r", archived=True) == [f"Shelf {unique}"]
    item_of(ui, f"Shelf {unique}").get_by_role("button", name="Remove").click()
    ui.get_by_role("alertdialog", name="Are you sure?").get_by_role("button", name="Confirm").click()
    soon(lambda: item_of(ui, f"Shelf {unique}").count(), 0)
    soon(lambda: api.get(f"/bookmarks/{shelved['id']}/").status_code, 404)
    soon(lambda: titles_on(ui, f"{unique}-r", archived=True), [])
    assert titles_on(ui, f"{unique}-r") == [f"Open {unique}"]
