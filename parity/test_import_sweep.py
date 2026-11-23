"""Import sweep: one fixed Netscape file imported into an empty account, then a changed one over it, every field read back through the API."""

import json
import os
import re
import time
from datetime import datetime
from pathlib import Path

import pytest

from conftest import wipe_account
from ui import TARGET

SNAPSHOTS = Path(__file__).parent / "import"
RECORD = os.environ.get("PARITY_RECORD_IMPORT") == "1"
FIELDS = (
    "url title description notes website_title website_description is_archived unread shared tag_names "
    "date_added date_modified favicon_url preview_image_url web_archive_snapshot_url"
).split()


def a(url, title="", attrs="", note=None):
    text = f'<DT><A HREF="{url}" {attrs}>{title}</A>'
    return text if note is None else text + f"\n<DD>{note}"


FIRST = "\n".join([
    "<!DOCTYPE NETSCAPE-Bookmark-file-1>", "<TITLE>Bookmarks</TITLE>", "<H1>Bookmarks</H1>", "<DL><p>",
    a("https://sweep.example/one", "One &amp; &lt;b&gt;", 'ADD_DATE="1700000000" LAST_MODIFIED="1700000500" TAGS="red,Blue,blue"',
      "Some words[linkding-notes]A note\nover two lines[/linkding-notes]"),
    a("https://sweep.example/no-title", "", ""),
    a("https://sweep.example/unread", "Unread", 'ADD_DATE="1600000000" TOREAD="1"', "Unread words[linkding-notes]Unread note[/linkding-notes]"),
    a("https://sweep.example/public", "Public", 'ADD_DATE="1600000100" PRIVATE="0" TAGS="shared-tag"'),
    a("https://sweep.example/private", "Private", 'ADD_DATE="1600000200" PRIVATE="1"'),
    a("https://sweep.example/archived", "Archived", 'ADD_DATE="1600000300" TAGS="green,linkding:bookmarks.archived"'),
    a("https://sweep.example/one", "One again, in the same file", 'TAGS="other"'),
    a("https://SWEEP.example/Two/", "Two with a slash", 'ADD_DATE="1600000400"'),
    a("https://sweep.example/Two", "Two without it", 'ADD_DATE="1600000500"'),
    a("https://sweep.example/unicode", "Café ☕ 日本", 'ADD_DATE="1600000600" TAGS="Beta Gamma,  ,x y"'),
    a("https://sweep.example/bad-date", "Bad dates", 'ADD_DATE="abc" LAST_MODIFIED="-5"'),
    "<DT><H3>A folder</H3>", "<DL><p>", a("https://sweep.example/in-folder", "In a folder", 'ADD_DATE="1600000700"'), "</DL><p>",
    "</DL><p>", "",
])
# The same file's bookmarks again, changed: new title, tags and notes, an update with no title, description or notes, one more link.
SECOND = "\n".join([
    "<!DOCTYPE NETSCAPE-Bookmark-file-1>", "<TITLE>Bookmarks</TITLE>", "<H1>Bookmarks</H1>", "<DL><p>",
    a("https://sweep.example/one", "One, changed", 'ADD_DATE="1800000000" LAST_MODIFIED="1800000500" TAGS="red,new"', "New words[linkding-notes]Changed note[/linkding-notes]"),
    a("https://sweep.example/unread", "", ""),
    a("https://sweep.example/public", "Public, changed", 'PRIVATE="1" TAGS="linkding:bookmarks.archived"'),
    a("https://sweep.example/archived", "Archived, changed", 'TAGS="green"'),
    a("https://sweep.example/added-later", "Added later", 'ADD_DATE="1600000800"'),
    "</DL><p>", "",
])

# Where the port still differs from the original: (flag, step, url, field, original's value, port's value).
KNOWN = []


def seconds(stamp):
    return datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp()


def read_account(api):
    """Every bookmark of the account with every field the API shows, dates made "<now>" when the import time made them."""
    found = []
    for path in ("/bookmarks/?limit=1000", "/bookmarks/archived/?limit=1000"):
        found += api.get(path).json()["results"]
    rows = {}
    for bookmark in found:
        row = {name: bookmark[name] for name in FIELDS}
        row["tag_names"] = sorted(row["tag_names"])
        recent = time.time() - seconds(row["date_added"]) < 600
        for name in ("date_added", "date_modified"):
            if time.time() - seconds(row[name]) < 600:
                row[name] = "<now>"
        if recent:
            row["web_archive_snapshot_url"] = re.sub(r"/web/\d{14}/", "/web/<stamp>/", row["web_archive_snapshot_url"] or "")
        rows[row["url"]] = row
    tags = sorted(tag["name"] for tag in api.get("/tags/?limit=1000").json()["results"])
    return {"bookmarks": dict(sorted(rows.items())), "tags": tags}


def differences(original, port):
    found = []
    for url in sorted(set(original["bookmarks"]) | set(port["bookmarks"])):
        left, right = original["bookmarks"].get(url), port["bookmarks"].get(url)
        if left is None or right is None:
            found.append((url, "(whole bookmark)", left, right))
            continue
        found += [(url, name, left[name], right[name]) for name in FIELDS if left[name] != right[name]]
    if original["tags"] != port["tags"]:
        found.append(("(tags)", "names", original["tags"], port["tags"]))
    return found


@pytest.mark.parametrize("map_private_flag", [False, True], ids=["plain", "private-flag"])
def test_the_import_leaves_the_same_bookmarks(api, netscape, map_private_flag):
    wipe_account(api)
    try:
        netscape.import_text(FIRST, map_private_flag=map_private_flag)
        steps = {"first": read_account(api)}
        netscape.import_text(SECOND, map_private_flag=map_private_flag)
        steps["second"] = read_account(api)
    finally:
        wipe_account(api)
    assert len(steps["first"]["bookmarks"]) > 8
    snapshot = SNAPSHOTS / f"{'private-flag' if map_private_flag else 'plain'}.json"
    if TARGET == "original":
        if RECORD:
            SNAPSHOTS.mkdir(exist_ok=True)
            snapshot.write_text(json.dumps(steps, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        assert steps == json.loads(snapshot.read_text(encoding="utf-8"))
    else:
        original = json.loads(snapshot.read_text(encoding="utf-8"))
        found = [(name, *d) for name in steps for d in differences(original[name], steps[name])]
        known = [d[1:] for d in KNOWN if d[0] == map_private_flag]
        assert found == known, "\n".join(map(repr, found))
