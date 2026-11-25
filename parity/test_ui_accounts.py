"""Accounts: no one can make one for themselves, names are exact, a refusal says what linkding says, and signing out leaves API tokens working."""

import re

import httpx
import pytest

from conftest import BASE_URL, TOKEN
from ui import bookmark_items, sign_in, soon, submit_credentials

REFUSAL = "Your username and password didn't match. Please try again."
SIGN_UP = re.compile(r"create account|register|sign ?up", re.IGNORECASE)


def refused(visitor, username, password):
    visitor.goto(f"{BASE_URL}/bookmarks")
    submit_credentials(visitor, username, password)
    visitor.get_by_text(REFUSAL, exact=True).wait_for()
    assert bookmark_items(visitor).count() == 0


def test_the_sign_in_offers_no_way_to_make_an_account(visitor):
    visitor.goto(f"{BASE_URL}/bookmarks")
    visitor.get_by_label("Username").wait_for()
    assert visitor.get_by_role("button", name=SIGN_UP).count() == 0
    assert visitor.get_by_role("link", name=SIGN_UP).count() == 0


@pytest.mark.parametrize("path", ["/register", "/signup", "/accounts/signup/", "/__jac/auth/register"])
def test_asking_to_register_makes_no_account(visitor, unique, path):
    username = f"stranger{unique}"
    response = httpx.post(f"{BASE_URL}{path}", json={"username": username, "email": f"{username}@example.com", "password": "stranger-pass"}, timeout=20)
    assert response.status_code >= 300 and '"token"' not in response.text, response.text[:300]
    refused(visitor, username, "stranger-pass")


@pytest.mark.parametrize("username,password", [("PARITY", "parity-pass"), ("parity", "PARITY-PASS"), ("nobody-here", "parity-pass")], ids=["name-in-capitals", "password-in-capitals", "unknown-name"])
def test_a_sign_in_that_does_not_match_exactly_is_refused_in_linkdings_words(visitor, username, password):
    refused(visitor, username, password)


def test_signing_out_leaves_the_api_token_working(visitor):
    sign_in(visitor)
    visitor.get_by_role("button", name="Logout").click()
    visitor.get_by_label("Username").wait_for()
    assert httpx.get(f"{BASE_URL}/api/tags/", headers={"Authorization": f"Token {TOKEN}"}, timeout=20).status_code == 200
