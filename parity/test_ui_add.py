"""The add-bookmark page: its fields, what saving does, and what it does with a repeated or bad address."""

from conftest import BASE_URL


def open_form(ui):
    ui.goto(f"{BASE_URL}/bookmarks/new")
    ui.get_by_role("heading", name="New bookmark", level=1).wait_for()


def fill_form(ui, url, title="", description="", tags="", notes="", unread=False):
    ui.get_by_label("URL").fill(url)
    ui.get_by_label("Tags", exact=True).fill(tags)
    ui.get_by_label("Title").fill(title)
    ui.get_by_label("Description").fill(description)
    if notes:
        ui.get_by_text("Notes", exact=True).first.click()
        ui.get_by_label("Notes", exact=True).fill(notes)
    if unread:
        ui.get_by_label("Mark as unread").check()


def find(api, unique):
    return api.get("/bookmarks/", params={"q": unique, "limit": 100}).json()["results"]


def total(api):
    return api.get("/bookmarks/", params={"limit": 1}).json()["count"]


def test_the_form_has_the_fields_of_a_bookmark(ui):
    open_form(ui)
    for label in ("URL", "Tags", "Title", "Description", "Mark as unread"):
        assert ui.get_by_label(label, exact=True).count() == 1, label
    assert ui.get_by_text("Notes", exact=True).count() >= 1
    assert ui.get_by_role("button", name="Save").count() == 1
    assert ui.get_by_role("link", name="Cancel").count() == 1


def test_saving_makes_a_bookmark_with_what_was_typed(ui, api, unique):
    url = f"https://example.com/{unique}/added"
    open_form(ui)
    fill_form(ui, url, title="Typed title", description="Typed description", tags=f"{unique}-a {unique}-b", notes="Typed notes", unread=True)
    ui.get_by_role("button", name="Save").click()
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    made = find(api, f"#{unique}-a")
    try:
        assert len(made) == 1
        got = made[0]
        assert (got["url"], got["title"], got["description"], got["notes"], got["unread"]) == (url, "Typed title", "Typed description", "Typed notes", True)
        assert sorted(got["tag_names"]) == [f"{unique}-a", f"{unique}-b"]
    finally:
        for b in made:
            api.delete(f"/bookmarks/{b['id']}/")


def test_a_saved_bookmark_is_on_the_list(ui, api, unique):
    url = f"https://example.com/{unique}/listed"
    open_form(ui)
    fill_form(ui, url, title=f"Listed {unique}", tags=f"{unique}-l")
    ui.get_by_role("button", name="Save").click()
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    try:
        ui.goto(f"{BASE_URL}/bookmarks?q=%23{unique}-l")
        ui.get_by_role("link", name=f"Listed {unique}").wait_for()
    finally:
        for b in find(api, f"#{unique}-l"):
            api.delete(f"/bookmarks/{b['id']}/")


def test_saving_an_address_again_changes_that_bookmark(ui, api, make_bookmark, unique):
    before = make_bookmark(title="Old title", tag_names=[f"{unique}-o"])
    open_form(ui)
    fill_form(ui, before["url"], title="New title", description="Now described", tags=f"{unique}-n")
    ui.get_by_role("button", name="Save").click()
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    got = api.get(f"/bookmarks/{before['id']}/").json()
    assert (got["title"], got["description"], got["tag_names"]) == ("New title", "Now described", [f"{unique}-n"])
    assert len([b for b in api.get("/bookmarks/", params={"q": before["url"], "limit": 100}).json()["results"] if b["url"] == before["url"]]) == 1


def test_a_bad_address_is_refused_with_a_message(ui, api):
    before = total(api)
    open_form(ui)
    fill_form(ui, "not a url", title="Never saved")
    ui.get_by_role("button", name="Save").click()
    ui.get_by_text("Enter a valid URL.").wait_for()
    assert total(api) == before
    assert ui.get_by_label("URL").input_value() == "not a url"


def test_cancel_saves_nothing(ui, api, unique):
    before = total(api)
    open_form(ui)
    fill_form(ui, f"https://example.com/{unique}/cancelled", title="Cancelled")
    ui.get_by_role("link", name="Cancel").click()
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    assert total(api) == before
