"""An import is followed by favicons with no further request: the work that is waiting gets done on its own."""

from conftest import FIXTURE, eventually
from test_netscape import file_of, row


def test_imported_bookmarks_get_favicons_and_no_snapshot(jobs_api, netscape_jobs, unique):
    netscape_jobs.import_text(file_of(
        row(f"{FIXTURE}/page?{unique}a", "First", 'ADD_DATE="1700000000"'),
        row(f"{FIXTURE}/no-title?{unique}b", "Second", 'ADD_DATE="1700000100"'),
    ))
    found = jobs_api.get("/bookmarks/", params={"q": unique, "limit": 10}).json()["results"]
    assert len(found) == 2

    def both_have_icons():
        again = jobs_api.get("/bookmarks/", params={"q": unique, "limit": 10}).json()["results"]
        return all(b["favicon_url"] for b in again) and len(again) == 2

    assert eventually(both_have_icons)
    for bookmark in found:
        assets = jobs_api.get(f"/bookmarks/{bookmark['id']}/assets/").json()["results"]
        assert assets == []
