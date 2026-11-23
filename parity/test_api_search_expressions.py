"""API checks for the search expression language of /api/bookmarks/?q=: and, or, not, quotes, parentheses, tags."""

import pytest


@pytest.fixture
def corpus(make_bookmark, unique):
    """Four bookmarks with known words, tags and flags; returns the unique token and their titles by letter."""
    u = unique
    make_bookmark(title=f"alpha-{u} shared-{u}", tag_names=[f"t1-{u}"])
    make_bookmark(title=f"beta-{u} shared-{u}", tag_names=[f"t2-{u}"])
    make_bookmark(title=f"gamma-{u}", notes="a quoted phrase here", tag_names=[f"t1-{u}", f"t2-{u}"])
    make_bookmark(title=f"delta-{u}", unread=True)
    return u


def found(api, query):
    """The titles a query finds, without the unique token, sorted."""
    body = api.get("/bookmarks/", params={"q": query, "limit": 1000}).json()
    return sorted(item["title"].split("-")[0] + (" shared" if "shared" in item["title"] else "") for item in body["results"])


def test_terms_are_combined_with_and_by_default(api, corpus):
    u = corpus
    assert found(api, f"alpha-{u} shared-{u}") == ["alpha shared"]
    assert found(api, f"alpha-{u} beta-{u}") == []


def test_or_finds_either_term_in_any_case(api, corpus):
    u = corpus
    assert found(api, f"alpha-{u} or beta-{u}") == ["alpha shared", "beta shared"]
    assert found(api, f"alpha-{u} OR beta-{u}") == ["alpha shared", "beta shared"]


def test_not_removes_matches_and_binds_tighter_than_and(api, corpus):
    u = corpus
    assert found(api, f"shared-{u} and not beta-{u}") == ["alpha shared"]
    assert found(api, f"not alpha-{u} shared-{u}") == ["beta shared"]
    assert found(api, f"shared-{u} not not alpha-{u}") == ["alpha shared"]


def test_and_binds_tighter_than_or(api, corpus):
    u = corpus
    assert found(api, f"alpha-{u} or beta-{u} and gamma-{u}") == ["alpha shared"]


def test_parentheses_group(api, corpus):
    u = corpus
    assert found(api, f"(alpha-{u} or beta-{u}) and #t1-{u}") == ["alpha shared"]
    assert found(api, f"not (alpha-{u} or beta-{u}) and shared-{u}") == []


def test_tags_combine_with_and_and_or(api, corpus):
    u = corpus
    assert found(api, f"#t1-{u} #t2-{u}") == ["gamma"]
    assert found(api, f"#t1-{u} or #t2-{u}") == ["alpha shared", "beta shared", "gamma"]
    assert found(api, f"#T1-{u.upper()}") == ["alpha shared", "gamma"]


def test_quotes_make_one_term(api, corpus):
    u = corpus
    assert found(api, '"quoted phrase"') == ["gamma"]
    assert found(api, "'quoted phrase'") == ["gamma"]
    assert found(api, '"phrase quoted"') == []
    assert found(api, f'quoted phrase gamma-{u}') == ["gamma"]


def test_special_keywords(api, corpus):
    u = corpus
    assert found(api, f"!unread delta-{u}") == ["delta"]
    assert found(api, f"!untagged delta-{u}") == ["delta"]
    assert found(api, f"!untagged gamma-{u}") == []
    assert found(api, f"!nosuchword delta-{u}") == ["delta"]


@pytest.mark.parametrize("query", ["(alpha", "alpha)", "alpha and", "or alpha", "()", "not"])
def test_a_query_that_cannot_be_parsed_finds_nothing(api, corpus, query):
    assert api.get("/bookmarks/", params={"q": query}).json()["count"] == 0
