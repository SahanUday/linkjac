"""Signing in and out: what an anonymous visit shows, a wrong and a right password, the root address, and ending the session."""

import re

from conftest import BASE_URL
from ui import bookmark_items, sign_in, soon, submit_credentials

REFUSAL = re.compile(r"didn.t match|invalid|incorrect|wrong|fail|denied|not match", re.IGNORECASE)


def test_an_anonymous_visit_to_the_list_asks_for_a_sign_in(visitor):
    visitor.goto(f"{BASE_URL}/bookmarks")
    visitor.get_by_label("Username").wait_for()
    assert visitor.get_by_label("Password").count() == 1
    assert bookmark_items(visitor).count() == 0


def test_a_wrong_password_is_refused_with_a_message(visitor):
    visitor.goto(f"{BASE_URL}/bookmarks")
    submit_credentials(visitor, "parity", "not-the-password")
    visitor.get_by_text(REFUSAL).first.wait_for()
    assert visitor.get_by_label("Username").count() == 1
    assert bookmark_items(visitor).count() == 0


def test_the_right_password_shows_the_list_that_was_asked_for(visitor, make_bookmark, unique):
    make_bookmark(title=f"Behind sign-in {unique}", tag_names=[f"{unique}-in"])
    visitor.goto(f"{BASE_URL}/bookmarks?q=%23{unique}-in")
    submit_credentials(visitor, "parity", "parity-pass")
    soon(lambda: [bookmark_items(visitor).nth(i).get_by_role("link").first.inner_text() for i in range(bookmark_items(visitor).count())], [f"Behind sign-in {unique}"])


def test_the_root_address_leads_a_signed_in_user_to_the_list(ui):
    ui.goto(f"{BASE_URL}/")
    ui.wait_for_url(f"{BASE_URL}/bookmarks*")
    ui.get_by_role("heading", name="Bookmarks", level=1).wait_for()


def test_the_root_address_leads_a_visitor_to_a_sign_in(visitor):
    visitor.goto(f"{BASE_URL}/")
    visitor.get_by_label("Username").wait_for()
    assert bookmark_items(visitor).count() == 0


def test_logging_out_ends_the_session(visitor):
    sign_in(visitor)
    visitor.get_by_role("button", name="Logout").click()
    visitor.get_by_label("Username").wait_for()  # logging out itself leads to a sign-in, with no further visit
    visitor.goto(f"{BASE_URL}/bookmarks")
    visitor.get_by_label("Username").wait_for()
    assert bookmark_items(visitor).count() == 0
