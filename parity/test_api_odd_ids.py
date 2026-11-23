"""API checks for ids in the path that are not ordinary numbers."""

import pytest


@pytest.mark.parametrize("path", [
    "/bookmarks/²/", "/bookmarks/99999999999999999999/", "/bookmarks/abc/", "/bookmarks/-1/",
    "/tags/²/", "/tags/99999999999999999999/", "/tags/abc/", "/tags/-1/",
])
def test_an_id_that_is_not_an_ordinary_number_finds_nothing(api, path):
    assert api.get(path).status_code == 404
