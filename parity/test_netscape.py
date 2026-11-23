"""Import and export of Netscape bookmark files, checked through the API and the exported text."""

from datetime import datetime

import pytest


def seconds_of(stamp):
    return int(datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp())


def file_of(*rows):
    return "<!DOCTYPE NETSCAPE-Bookmark-file-1>\n<TITLE>Bookmarks</TITLE>\n<H1>Bookmarks</H1>\n<DL><p>\n" + "\n".join(rows) + "\n</DL><p>\n"


def row(url, title="", attrs="", description=None):
    text = f'<DT><A HREF="{url}" {attrs}>{title}</A>'
    return text if description is None else text + f"\n<DD>{description}"


@pytest.fixture
def listed(api, unique):
    """The bookmarks of this check, found by their shared tag, and removed when the check ends."""
    tag = f"{unique}-n"

    def find():
        found = api.get("/bookmarks/", params={"q": f"#{tag}", "limit": 100}).json()["results"]
        return {b["url"].rstrip("/").rsplit("/", 1)[-1]: b for b in found}

    yield tag, find
    for bookmark in api.get("/bookmarks/", params={"q": f"#{tag}", "limit": 100}).json()["results"]:
        api.delete(f"/bookmarks/{bookmark['id']}/")
    for bookmark in api.get("/bookmarks/archived/", params={"q": f"#{tag}", "limit": 100}).json()["results"]:
        api.delete(f"/bookmarks/{bookmark['id']}/")


def test_a_file_is_imported_with_its_fields(netscape, unique, listed):
    tag, find = listed
    netscape.import_text(file_of(
        row(f"https://nsc.example/{unique}/a", "A &amp; B", f'ADD_DATE="1700000000" LAST_MODIFIED="1700000500" TOREAD="1" TAGS="{tag},Beta, gamma"',
            "Words[linkding-notes]Some notes[/linkding-notes]"),
        row(f"https://nsc.example/{unique}/b", "Plain", f'TAGS="{tag}"'),
    ))
    a = find()["a"]
    assert (a["title"], a["description"], a["notes"]) == ("A & B", "Words", "Some notes")
    assert a["unread"] is True and a["shared"] is False and a["is_archived"] is False
    assert set(a["tag_names"]) == {tag, "Beta", "gamma"}
    assert seconds_of(a["date_added"]) == 1700000000 and seconds_of(a["date_modified"]) == 1700000500
    b = find()["b"]
    assert b["unread"] is False and b["title"] == "Plain"
    assert seconds_of(b["date_modified"]) == seconds_of(b["date_added"])


def test_the_archived_marker_archives_and_is_not_a_tag(netscape, api, unique, listed):
    tag, find = listed
    netscape.import_text(file_of(row(f"https://nsc.example/{unique}/z", "Z", f'TAGS="{tag},linkding:bookmarks.archived"')))
    found = api.get("/bookmarks/archived/", params={"q": f"#{tag}"}).json()["results"]
    assert [b["url"].rsplit("/", 1)[-1] for b in found] == ["z"]
    assert found[0]["tag_names"] == [tag]


def test_the_archived_marker_does_not_archive_a_bookmark_that_exists(netscape, api, unique, listed):
    tag, find = listed
    url = f"https://nsc.example/{unique}/kept"
    netscape.import_text(file_of(row(url, "Kept", f'TAGS="{tag}"')))
    netscape.import_text(file_of(row(url, "Kept", f'TAGS="{tag},linkding:bookmarks.archived"')))
    assert find()["kept"]["is_archived"] is False
    assert api.get("/bookmarks/archived/", params={"q": f"#{tag}"}).json()["results"] == []


def test_importing_again_changes_the_bookmark_and_adds_tags(netscape, unique, listed):
    tag, find = listed
    url = f"https://nsc.example/{unique}/again"
    netscape.import_text(file_of(row(url, "First", f'TAGS="{tag},one"', "Desc")))
    netscape.import_text(file_of(row(url + "/", "", f'TAGS="{tag},two" TOREAD="1"')))
    again = find()["again"]
    assert again["title"] == "First" and again["description"] == "Desc"
    assert set(again["tag_names"]) == {tag, "one", "two"}
    assert again["unread"] is True


def test_the_private_flag_is_read_only_when_asked(netscape, unique, listed):
    tag, find = listed
    url = f"https://nsc.example/{unique}/pub"
    netscape.import_text(file_of(row(url, "P", f'PRIVATE="0" TAGS="{tag}"')))
    assert find()["pub"]["shared"] is False
    netscape.import_text(file_of(row(url, "P", f'PRIVATE="0" TAGS="{tag}"')), map_private_flag=True)
    assert find()["pub"]["shared"] is True
    netscape.import_text(file_of(row(url, "P", f'PRIVATE="1" TAGS="{tag}"')), map_private_flag=True)
    assert find()["pub"]["shared"] is True
    private = f"https://nsc.example/{unique}/priv"
    netscape.import_text(file_of(row(private, "Q", f'PRIVATE="1" TAGS="{tag}"')), map_private_flag=True)
    assert find()["priv"]["shared"] is False


def test_bad_and_repeated_addresses_are_left_out(netscape, unique, listed):
    tag, find = listed
    netscape.import_text(file_of(
        row(f"https://nsc.example/{unique}/ok", "Ok", f'TAGS="{tag}"'),
        row(f"https://nsc.example/{unique}/ok/", "Again", f'TAGS="{tag}"'),
        row("not a url", "Bad", f'TAGS="{tag}"'),
        row(f"https://nsc.example/{unique}/late", "Late", f'ADD_DATE="soon" TAGS="{tag}"'),
        row(f"https://nsc.example/{unique}/later", "Later", f'LAST_MODIFIED="soon" TAGS="{tag}"'),
        row(f"https://nsc.example/{unique}/" + "x" * 2100, "Long address", f'TAGS="{tag}"'),
        row(f"https://nsc.example/{unique}/title", "T" * 513, f'TAGS="{tag}"'),
    ))
    assert list(find()) == ["ok"]
    assert find()["ok"]["title"] == "Ok"


def test_the_export_lists_a_bookmark_the_way_the_original_writes_it(netscape, unique, listed):
    tag, find = listed
    base = f"https://nsc.example/{unique}"
    netscape.import_text(file_of(
        row(f"{base}/e1", "Title &lt;1&gt;", f'ADD_DATE="1700000000" LAST_MODIFIED="1700000011" PRIVATE="0" TOREAD="1" TAGS="{tag},Zed,alpha"',
            "Desc &amp; more[linkding-notes]Notes &lt;b&gt;[/linkding-notes]"),
        row(f"{base}/e2", "", f'ADD_DATE="1700000002" TAGS="{tag},linkding:bookmarks.archived"'),
    ), map_private_flag=True)
    lines = netscape.export_text().split("\n\r")
    mine = [line for index, line in enumerate(lines) if f"/{unique}/" in line or (index and f"/{unique}/" in lines[index - 1] and line.startswith("<DD>"))]
    assert mine == [
        f'<DT><A HREF="{base}/e1" ADD_DATE="1700000000" LAST_MODIFIED="1700000011" PRIVATE="0" TOREAD="1" TAGS="{",".join(sorted([tag, "Zed", "alpha"]))}">Title &lt;1&gt;</A>',
        "<DD>Desc &amp; more[linkding-notes]Notes &lt;b&gt;[/linkding-notes]",
        f'<DT><A HREF="{base}/e2" ADD_DATE="1700000002" LAST_MODIFIED="1700000002" PRIVATE="1" TOREAD="0" TAGS="{tag},linkding:bookmarks.archived">{base}/e2</A>',
    ]
    assert lines[0] == "<!DOCTYPE NETSCAPE-Bookmark-file-1>" and lines[-1] == "</DL><p>"


def test_an_exported_file_imports_back_to_the_same_bookmarks(netscape, api, unique, listed):
    tag, find = listed
    base = f"https://nsc.example/{unique}"
    netscape.import_text(file_of(
        row(f"{base}/r1", "Round &amp; trip", f'ADD_DATE="1600000000" LAST_MODIFIED="1600000009" PRIVATE="0" TOREAD="1" TAGS="{tag},rt-b,rt-a"', "D[linkding-notes]N[/linkding-notes]"),
    ), map_private_flag=True)
    before = find()["r1"]
    exported = netscape.export_text()
    api.delete(f"/bookmarks/{before['id']}/")
    assert find() == {}
    netscape.import_text(exported, map_private_flag=True)
    after = find()["r1"]
    for field in ("url", "title", "description", "notes", "unread", "shared", "is_archived"):
        assert after[field] == before[field], field
    assert set(after["tag_names"]) == set(before["tag_names"])
    assert seconds_of(after["date_added"]) == 1600000000 and seconds_of(after["date_modified"]) == 1600000009
