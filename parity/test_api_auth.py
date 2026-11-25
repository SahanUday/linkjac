"""API tokens and credentials: which Authorization headers the API takes, what it says to the others, and tokens made and removed."""

import httpx
import pytest

from conftest import BASE_URL, TOKEN

NOT_PROVIDED = "Authentication credentials were not provided."
INVALID = "Invalid token."


def ask(header, path="/tags/"):
    return httpx.get(f"{BASE_URL}/api{path}", headers={} if header is None else {"Authorization": header}, timeout=20)


@pytest.mark.parametrize("keyword", ["Token", "token", "TOKEN", "Bearer", "bearer"])
def test_either_keyword_in_any_case_is_taken(keyword):
    assert ask(f"{keyword} {TOKEN}").status_code == 200


@pytest.mark.parametrize(
    "header,detail",
    [
        (None, NOT_PROVIDED),
        ("Basic abc", NOT_PROVIDED),
        (f"Key {TOKEN}", NOT_PROVIDED),
        (TOKEN, NOT_PROVIDED),
        ("Token", "Invalid token header. No credentials provided."),
        ("Bearer", "Invalid token header. No credentials provided."),
        (f"Token {TOKEN} more", "Invalid token header. Token string should not contain spaces."),
        ("Token 0123456789012345678901234567890123456789", INVALID),
        ("Bearer nope", INVALID),
        (f"Token {TOKEN[:-1]}", INVALID),
        (f"Token {TOKEN.upper()}", INVALID),
    ],
    ids=["none", "basic", "other-keyword", "bare-key", "token-alone", "bearer-alone", "two-words", "unknown", "unknown-bearer", "cut-short", "capitals"],
)
def test_a_refused_header_says_why(header, detail):
    response = ask(header)
    assert response.status_code == 401, response.text
    assert response.json() == {"detail": detail}


@pytest.mark.parametrize("header,detail", [("Token nope", INVALID), ("Token", "Invalid token header. No credentials provided.")])
def test_a_bad_token_is_refused_even_where_no_token_is_needed(header, detail):
    assert ask(None, "/bookmarks/shared/").status_code == 200
    response = ask(header, "/bookmarks/shared/")
    assert response.status_code == 401, response.text
    assert response.json() == {"detail": detail}


def test_a_second_token_of_a_user_reads_the_same_account_and_leaves_the_first_working(tokens, make_bookmark):
    made = make_bookmark()
    second = tokens.create("second")
    try:
        assert second.key != TOKEN
        assert ask(f"Token {second.key}", f"/bookmarks/{made['id']}/").json()["url"] == made["url"]
        assert ask(f"Token {TOKEN}", f"/bookmarks/{made['id']}/").status_code == 200
    finally:
        tokens.delete(second)


def test_two_tokens_of_one_name_are_two_keys(tokens):
    first, second = tokens.create("twin"), tokens.create("twin")
    try:
        assert first.key != second.key
        assert ask(f"Token {first.key}").status_code == 200 and ask(f"Token {second.key}").status_code == 200
    finally:
        tokens.delete(first)
        tokens.delete(second)


def test_a_removed_token_is_refused_and_the_others_still_work(tokens):
    kept, removed = tokens.create("kept"), tokens.create("removed")
    try:
        assert ask(f"Token {removed.key}").status_code == 200
        tokens.delete(removed)
        refused = ask(f"Token {removed.key}")
        assert refused.status_code == 401 and refused.json() == {"detail": INVALID}
        assert ask(f"Token {kept.key}").status_code == 200
        assert ask(f"Token {TOKEN}").status_code == 200
    finally:
        tokens.delete(kept)
