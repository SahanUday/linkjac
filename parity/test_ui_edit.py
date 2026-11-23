"""The edit-bookmark page: what it shows of a bookmark, what saving and cancelling do, and a missing bookmark."""

from conftest import BASE_URL
from ui import bookmark_items, expected_gap_on_port, region


def open_edit(ui, bookmark_id):
    ui.goto(f"{BASE_URL}/bookmarks/{bookmark_id}/edit")
    ui.get_by_role("heading", name="Edit bookmark", level=1).wait_for()
    ui.wait_for_load_state("networkidle")


def test_the_form_is_filled_with_the_bookmark(ui, make_bookmark, unique):
    made = make_bookmark(title="Filled title", description="Filled description", notes="Filled notes", unread=True, tag_names=[f"{unique}-b", f"{unique}-a"])
    open_edit(ui, made["id"])
    assert ui.get_by_label("URL").input_value() == made["url"]
    assert ui.get_by_label("Title").input_value() == "Filled title"
    assert ui.get_by_label("Description").input_value() == "Filled description"
    assert ui.get_by_label("Notes", exact=True).input_value() == "Filled notes"
    assert ui.get_by_label("Mark as unread").is_checked()
    assert sorted(ui.get_by_label("Tags", exact=True).input_value().split()) == [f"{unique}-a", f"{unique}-b"]


def test_saving_changes_the_bookmark(ui, api, make_bookmark, unique):
    made = make_bookmark(title="Before", description="Before text", tag_names=[f"{unique}-x"])
    open_edit(ui, made["id"])
    ui.get_by_label("Title").fill("After")
    ui.get_by_label("Description").fill("After text")
    ui.get_by_label("Tags", exact=True).fill(f"{unique}-y {unique}-z")
    ui.get_by_label("Mark as unread").check()
    ui.get_by_role("button", name="Save").click()
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    got = api.get(f"/bookmarks/{made['id']}/").json()
    assert (got["title"], got["description"], got["unread"]) == ("After", "After text", True)
    assert sorted(got["tag_names"]) == [f"{unique}-y", f"{unique}-z"]


def test_cancel_changes_nothing(ui, api, make_bookmark):
    made = make_bookmark(title="Kept")
    open_edit(ui, made["id"])
    ui.get_by_label("Title").fill("Not kept")
    ui.get_by_role("link", name="Cancel").click()
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    assert api.get(f"/bookmarks/{made['id']}/").json()["title"] == "Kept"


def test_the_edit_link_of_an_item_opens_its_form(ui, make_bookmark, unique):
    made = make_bookmark(title=f"Linked {unique}", tag_names=[f"{unique}-e"])
    ui.goto(f"{BASE_URL}/bookmarks?q=%23{unique}-e")
    bookmark_items(ui).first.get_by_role("link", name="Edit").click()
    ui.get_by_role("heading", name="Edit bookmark", level=1).wait_for()
    assert ui.get_by_label("Title").input_value() == f"Linked {unique}"
    assert str(made["id"]) in ui.url


def test_saving_a_bad_address_is_refused_and_keeps_the_bookmark(ui, api, make_bookmark):
    made = make_bookmark(title="Stays")
    open_edit(ui, made["id"])
    ui.get_by_label("URL").fill("not a url")
    ui.get_by_role("button", name="Save").click()
    ui.get_by_text("Enter a valid URL.").wait_for()
    assert api.get(f"/bookmarks/{made['id']}/").json()["url"] == made["url"]


@expected_gap_on_port("GAP-045")
def test_a_missing_bookmark_answers_404(ui):
    response = ui.goto(f"{BASE_URL}/bookmarks/99999999/edit")
    assert response.status == 404
