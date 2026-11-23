# Plan

Goal: a working Jac app that behaves like linkding (proven by the same checks run against both), and a complete, honest list of what neojac could not do. The gap list is the main result.

Update the Status column as work moves: `todo`, `doing`, `done`, `blocked`, `skipped`. One row is `doing` at a time. A `blocked` or `skipped` row needs a gap.

| ID | Milestone | Status | Done when (something we can show) |
|----|-----------|--------|-----------------------------------|
| M0 | Setup and baseline | done | linkding runs from `reference/`; `parity/` checks pass against it; `neojac absorb` and `neojac port --check` run on a copy outside the repo and their findings are logged; gap site is live |
| M1 | Data core | done | `app/jac.toml` has `[check.lint] ignore = ["strip-comments", "strip-docstrings"]` (set before any `neojac fmt --fix`); `archwire.jac` declares the layers; bookmarks, tags and users stored through `root` and the `store` plugin; `neojac arch` is clean; a `neojac test` run creates, lists and searches them |
| M2 | REST API | done | API parity checks pass: same status codes, fields and filters as linkding's `/api/` (checkpoint) |
| M3 | Import, export, CLI | done | a Netscape bookmark file round-trips; admin commands run from a CLI app |
| M4 | Web UI | doing | list, search, add, edit, tags pages work in a browser; the same browser checks pass on both apps (checkpoint) |
| M5 | Background work | todo | page snapshot and favicon jobs run and a scheduled job fires |
| M6 | Sign-in and architecture review | todo | sign-in and API tokens work through the `auth` plugin; the architecture picture matches the code and no duplicate implementations remain |
| M7 | Optional extras | todo | any of: desktop window, Android app on the Pixel 6a, `by llm()` tag suggestions |
| M8 | Final report | todo | gap list complete and triaged; summary page on the site; team handover |

## Working rules for slices

- Work in slices that can be shown in one sitting: one endpoint group, one page, one job.
- A slice is done when its parity check passes and its gaps are logged. Polish waits for the refactor pass.
- Stuck after three different approaches: log the gap, mark the slice `blocked`, move to the next slice.
- Start each milestone by listing its slices here, under the table, as a short checklist. Tick them as they land.

## Slices

### M0

- [x] Setup checked: neojac 0.4.0, skills in `.claude/skills`, linkding pinned at 27b7303, site workflow live
- [x] linkding runs from `reference/linkding` (how: `journal/2026-11-23.md`)
- [x] `parity/` API checks for bookmarks and tags, 33 of 33 pass against the original; `parity/run.sh` writes `parity/results.json`
- [x] `neojac absorb` and `neojac port --check` run on copies in `~/.claude-scratch/linkjac/`; findings logged as GAP-002 to GAP-024 (GAP-001 withdrawn: our instruction error)

### M1

- [x] S1 spike: one Bookmark and one Tag through `root`, served by the standard `store` plugin and read back after a restart; `neojac test` creates and lists; `archwire.jac` with `domain` and `service` layers; `app/jac.toml` with the lint ignore (GAP-025, GAP-026, GAP-027)
- [x] S2 Bookmark with linkding's core fields (url, normalized url, title, description, notes, unread, archived, shared, dates) and add/update/delete
- [x] S3 Tags the linkding way: name rules, case-insensitive find-or-make, replacing a bookmark's tags, tags listed with counts
- [x] S4 Search: text over url, title, description, notes; `#tag` terms; unread, archived and shared filters; newest first
- [x] S5 User profile: a `UserProfile` node under each caller's `root` with linkding's defaults (accounts themselves are M6, GAP-027)
- Not done in M1, carried to M2: tag search "lax" mode and quoted terms; linkding's default search is an expression language (and/or/not, quotes, parentheses; `bookmarks/services/search_query_parser.py`); M1 has the legacy all-terms search only. Per-user roots are untested until `auth` is bound (M6): the persistence check uses `root.shared`.
- [x] S6 Close: persistence round trip against the served app, `neojac arch` clean, `neojac fmt --check`, `neojac check`, `neojac test`, `/close-milestone`

### M2

How the API is served (spikes, 2026-11-23): `@restspec` cannot carry linkding's `/api/` (GAP-030 to GAP-033); the `accounts` plugin reads `Bearer` and not `Token` (GAP-034) but gives each caller their own `root`. So `/api/` goes through a `transport` plugin, `plugins/rest_bridge`, which serves HTTP, turns `Authorization: Token` into `Bearer`, hands every request under `/api/` to one `:protect` endpoint of the app (`rest.handle`) and writes back the status and body that endpoint returns. The routing, the field names and the status codes live in `app/`, in Jac. The parity checks run against the port with a token made by `POST /__jac/auth/register` (`parity/run.sh`, `PARITY_TARGET=port`).

Counts are reported as two numbers: original (must stay 33 of 33 plus what is added) and port.

- [x] S0 spikes: auth (Bearer yes, Token no: GAP-034); restspec limits (GAP-030..033); transport plugin serves the app as a pass-through
- [x] S1 port target for `parity/run.sh`; bridge forwards `/api/` to `rest.handle`; auth replies as linkding's (401 bodies)
- [x] S2 integer ids for bookmarks and tags
- [x] S3 tags endpoints (list with pagination, create, get, delete, 405 for PUT)
- [x] S4 bookmarks create, get, delete (URL validation, fields, `tag_names`, date format with `Z`: GAP-029)
- [x] S5 bookmarks update (PUT, PATCH) and the 400 and 404 bodies
- [x] S6 bookmarks list: `q` (legacy search as in M1), `limit` and `offset`, `next` and `previous`
- [x] S7 search expression language: and, or, not, quotes, parentheses (own slice; `search_query_parser.py` in the original)
- [x] S8 the rest of linkding's `/api/` that can run without the network or files: list filters (`unread`, `shared`, `sort`, `added_since`, `modified_since`), `archived`, `archive`, `unarchive`, `shared` (anonymous too), `user/profile/`; 9 parity checks added against the original first (`parity/test_api_bookmark_views.py`)
- Not in M2, each with a reason: `bookmarks/check/` and the web-archive/scraping on create (need the network; M5 jobs), `singlefile` and assets (need `files`; M5), bundles (M4 with the UI), the `user` query parameter of the shared list (a root has no username; M6 with `auth`), the shared list with sharing enabled (unrun: GAP-035, and no API turns sharing on until M4). Known simplifications: `favicon_url`, `preview_image_url`, `website_title` and `website_description` are always null (no scraping); `web_archive_snapshot_url` is the original's fallback built from `date_added` (the original does the same when it has no snapshot); ids are counted per user in `ids.jac`, linkding's are global (two users both get id 1); `version` in the profile is the constant `1.47.0`; `date_added` and `date_modified` sent on create are ignored
- [x] S9 close: persistence check against the served port (`tools/check_persistence.sh`), `neojac arch` clean, gap audit done; `/close-milestone` (build the site, push) not run, waiting for the user

### M3

`neojac port --check` on the original's Netscape unit (copies in `~/.claude-scratch/linkjac/m3-netscape/`): `exporter.py` is accepted (raw output typed `any`); `parser.py` is refused (class decorator, class attributes, `with`, `super()`: GAP-007, 008, 010, 011); `import_netscape.py` is refused. So the exporter's logic comes from `port`'s output as raw material, the parser and importer are designed by hand (`html.parser` is native, `neojac docs library/text`).

- [x] S1 export: an owner's bookmarks as a Netscape file, byte for byte as `exporter.py` writes it
- [x] S2 parser: Netscape file into bookmark records (tags, dates, `TOREAD`, `PRIVATE`, notes, archived marker)
- [x] S3 import: records into bookmarks (update on same normalized URL, skip duplicates in the file, dates kept, tags created, archived)
- [x] S4 round trip: export, import into an empty owner, same bookmarks (a `test` block, and a check)
- [x] S5 entry points and CLI app: `:protect` endpoints for import and export; a `cli` app that calls them (route in `neojac docs crossings`; `JAC_REMOTE_TOKEN` for a caller's session)
- [x] S6 admin commands: `import <file> [--map-private-flag]` and `export [<file>]`, as the signed-in token holder (GAP-040); the original's other commands are not ported (see Known deviations)
- [x] S7 7 checks on both targets (`parity/test_netscape.py`): the original through its web import form and export view, the port through its CLI; the API shows the same bookmarks and the exported text is the same. Original 78/78, port 78/78

### M4

#### UI parity method

What is compared: structure and behaviour, never pixels, class names, markup or CSS. The same Playwright checks (`parity/test_ui_*.py`, Python, `LINKDING_URL`) run against both targets, and are run on the original first; a check that fails on the original is wrong and is fixed there before the port is tried. Each check drives the page by role and accessible name (`get_by_role`, `get_by_label`), the way `neojac browse snapshot` prints the page, and asserts: (1) the outline of a region as a list of (role, name) with dates, ids and "Today" normalised away; (2) what a user action does, read both from the page afterwards and from the API (`/api/`, which both targets answer the same); (3) status and address after navigation. A difference that can only be matched by copying linkding's web components or markup is not matched: it is logged as a gap or a deviation, with the check marked `expected_gap("GAP-nnn")`. Sign-in: the original's own `/login/` form; the port's runs through the `accounts` plugin (`sign_in()` shows the runtime's own form, GAP to be filed with the first page that needs it), so login is checked as behaviour (an anonymous visit leads to a sign-in, a wrong password is refused with a message, a right one reaches the list), not as a form outline.

The pages and actions of the original (from `bookmarks/urls.py`, the templates and `neojac browse` on the running original), and what each check pins:

| Page / action | Original's address | Behaviour to check |
|---|---|---|
| Root | `/` | Anonymous: leads to login. Signed in: leads to `/bookmarks`. |
| Login, logout | `/login/`, `/logout/` | Fields Username and Password, button Login. Wrong password: stays on the form with an error. Right one: `/bookmarks`. Logout button ends the session; `/bookmarks` then leads to login. |
| Bookmark list | `/bookmarks` | Heading "Bookmarks"; one list item per bookmark, newest first; each item: title link (the URL when no title), `#tag` links, description, date link, View, Edit, Archive, Remove. Empty state when none. Side regions: Tags (tag links with counts, alphabetical). |
| Pagination | `/bookmarks?page=n` | 30 items per page (profile `bookmarks_per_page`, API default of the profile); Previous, page numbers, Next; page 2 holds the next 30. |
| Search | `/bookmarks?q=...` | Search box "Search for words or #tags"; submitting filters like the API's `q`; clicking a `#tag` link adds the tag to the query; an empty result shows the empty state. |
| Search preferences | the dropdown on the list | Sort by (added/title, asc/desc), shared filter, unread filter change the order and the list. |
| Add | `/bookmarks/new` | Fields URL, Tags, Title, Description, Notes, Mark as unread, Share; Save creates and returns to the list; the same URL again updates that bookmark; an invalid URL shows an error and creates nothing; tags typed with spaces and commas become tags. |
| Edit | `/bookmarks/<id>/edit` | Same fields filled with the bookmark's; Save changes it; Cancel changes nothing. |
| Remove | the Remove button | Removes the bookmark (after the page's own confirmation); it is gone from list and API. |
| Archive, Unarchive | Archive button, `/bookmarks/archived` | Moves the bookmark to the archived list and back; the main list no longer shows it. |
| Bulk edit | "Bulk edit" button | Checkboxes appear; actions archive, unarchive, delete, tag, untag, mark read, share, unshare on the selected; "select across" applies to every match. |
| Details, View | the View link | The bookmark's details (notes, dates, tags). |
| Tags page | `/tags` | Lists tags with counts; sort; "Show only unused tags"; New, Edit (rename), Remove, Merge. |
| Shared list | `/bookmarks/shared` | Only shared bookmarks; own and others' by `user` filter. |
| Settings | `/settings/general`, `/settings/integrations` | The profile fields (theme, items per page, tag search mode, sharing, ...) save and change the list. API token creation under integrations. |
| Import, export | `/settings/general` form, `/settings/export` | Import a Netscape file through the form; export downloads the same text as M3's export (M3 covers the file; M4 covers the form). |
| Bundles, favicons, previews, assets, feeds, bookmarklet | | Out of M4: bundles are not in the API either; the rest need M5 jobs or files. |

#### What neojac's docs support for a web UI (read 2026-11-23; `neojac docs search` for pages, browse, template, ui plugin)

- A `browser` space whose modules under `pages/` are routes (`apps/pages`): `pages/bookmarks.jac` is `/bookmarks`, a `page` function returns JSX, `has` is state, `can with entry` an effect; React is the `ui` plugin with file routes, built by Vite from an `[npm.web]` tree in `jac.toml` and `eco/web/{index.html,vite.config.ts}`.
- A page calls the server's `:pub` and `:protect` functions as ordinary async calls; the archwire wires each one to the page (`apps/crossings`, `apps/pages` "Calling the server").
- Sign-in: `sign_in()` from `@jac/runtime` shows the `auth` plugin's own form over the page (`apps/pages` "Signing in"); the page cannot supply its own login form.
- `import "./x.css";` puts a style sheet in the bundle (`apps/pages` "npm packages and style sheets"). There are no server-rendered templates: a page is HTML made in the browser, so `curl` sees an empty shell.
- Checking: `neojac browse` (open, snapshot, click, fill, wait, errors) drives a pinned headless Chrome and prints the page as an accessibility outline (`toolchain/browse`).
- Found by `neojac docs search` to have no page on them (searched 2026-11-23, "server-side rendering", "redirect", "cookie", "Content-Disposition", "download file"): server-side rendering; an HTTP redirect an app answers with (the hits are `urllib` and the sign-in's own `redirect` field); a cookie an app sets (the hits are the `http` library and `neojac browse`); a response header such as `Content-Disposition` (no page mentions it), which the export download needs. "No page found by that search" is not proof that none exists. Each is logged as a gap when the slice that needs it is reached.

#### Spike: the bookmark list (2026-11-23)

Built `app/web_list.jac` (a `:protect` function `bookmark_page(q, page, archived)` giving one page of bookmarks and the tags of the matches), `app/pages/bookmarks.jac` and its impl, the `site` browser space, `app api { run api; serve site; }`, `eco/web/`, `[npm.web]`. Shown:
- The whole route works through the project's own `rest_bridge` transport: it serves the bundle (HTML shell at `/bookmarks`, assets under `/assets/`) and the page's calls, with no change to the plugin. This was not expected (GAP-037: the bridge stands in for the standard transport); it was not measured whether it serves everything the standard transport does for a bundle (cache headers, 404 and 403 rules).
- The built program is now a directory (`dist/api-<platform>/api` and `pages/site/`), as `neojac docs apps/index` says; `parity/run.sh` was changed to run `.../api`.
- The page's structure matches the original's in roles and names: a heading, a search box, a "Bookmark list" region of list items (title link, `#tag` links, description, Edit, Archive, Remove), a pagination list (Previous, page numbers, Next) and a "Tags" region. 7 checks (`parity/test_ui_list.py`): original 7/7 (run first), port 7/7.
- Gaps found: GAP-042 (the default lint refuses the inline page bodies every docs example shows; `neojac fmt --fix pages` moves them to `pages/impl/`), GAP-043 (a page cannot build the obj of the server's space: `this.init is not a function`; worked around with one `has` per field).
- Differences kept, not matched: the sign-in is the plugin's dialog, not linkding's `/login/` page; the list is filled after the page loads (the checks wait for the network to go quiet; the original sends the list in the page); the tag region lists tag names as plain links (linkding groups them by letter, with a count link); the original's date link, "View" link, bundles region, "Bulk edit" button and search preferences menu are not on the port's list yet; the original's pagination shows "..." gaps for long ranges and the port lists every page number.

#### Slices

Done-when for M4 is met after S4. The session that wrote this list stopped there, as asked.

- [x] S1 list page: items, order, search box and `q`, tags region, tag links, 30 per page, Previous and Next (spike above; 7 checks, original 7/7, port 7/7)
- [x] S2 add: `/bookmarks/new` with URL, Tags (space-separated), Title, Description, Notes, unread box; same URL updates; invalid URL error; Cancel (6 checks, `parity/test_ui_add.py`; original 6/6, port 6/6; a mutant that broke tag splitting and the error text failed 2 of them)
- [x] S3 edit: `/bookmarks/<id>/edit` filled from the bookmark, Save, Cancel, the Edit link of an item, a bad address refused (6 checks, `parity/test_ui_edit.py`; original 6/6; port 5 passed and 1 expected gap: a missing bookmark answers 404, GAP-045). The route has the id before a fixed segment, so one page takes `/bookmarks/*` (GAP-044). List and form became components in `app/ui/`
- [ ] S4 tags page: `/tags` with counts, sort, unused-only filter, new, rename, remove
- [ ] S5 remove and archive on the list; archived list and unarchive
- [ ] S6 sign-in and root: anonymous visit leads to sign-in, wrong password refused, `/` leads to the list, sign out
- [ ] S7 search preferences: sort, shared and unread filters; unread and shared marks on items
- [ ] S8 bulk edit
- [ ] S9 settings page (profile fields) and the import and export form

## Port usage

Per unit of the original: what `neojac port --check` said, and what the app's code is. "As-is" = port's output used unchanged; "raw material" = port's output read and then rewritten; "by hand" = designed without port output. "Run when" says whether the check was run before the work (as CLAUDE.md asks) or only afterwards, on 2026-11-23, for this table (re-run on a copy in `~/.claude-scratch/linkjac/port-usage/`; the result of that re-run is what is shown, its refusal lines are the first ones counted by kind, not a full list).

| Milestone | Unit (linkding source) | `port --check` | Used as | Run when | Gaps |
|---|---|---|---|---|---|
| M0 | all of `bookmarks/` (251 sources) | 197 refused, 54 would port (mostly `__init__.py` and small modules) | none used; survey only | at the time | GAP-006, 004, 007 to 024 |
| M0 | `package.json`, `pyproject.toml` through `absorb` | `absorb` has no `--check`; takes `package.json` and `Cargo.toml` only | none used | at the time | GAP-002, 003 |
| M1 | `utils.py` (`normalize_url`, `parse_tag_string`) | refused: `try`, class attribute, class decorator, module-level name | by hand. An excerpt of `parse_tag_string` and `sanitize_tag_name` (not the unit itself) was ported in scratch (`m1-urls-tags/`, output typed `any`); `app/impl/tags.impl.jac` is not that output (it keeps a dict by name key and returns the names sorted) | at the time, for the excerpt; for the whole file only now | GAP-009, 010, 011 |
| M1 | `models.py` (Bookmark, Tag, UserProfile) | refused: 140 class attributes, 19 decorators, `*args`/`**kwargs`, `**` arguments | by hand (nodes over `root`) | now only | GAP-011, 008, 012 |
| M1 | `queries.py` (search) | refused: `with`, `try` | by hand | now only | GAP-007, 009 |
| M2 | `api/routes.py` | refused: decorators, class attributes, `try` | by hand (transport plugin plus `rest*.jac`) | now only | GAP-008, 009, 011, 030 to 034 |
| M2 | `api/serializers.py` | refused: class attributes, class statements, `**`, `super()` | by hand | now only | GAP-010, 011 |
| M2 | `services/search_query_parser.py` | refused: class attributes, class decorators, `try` | by hand (`search_expression.jac`) | now only | GAP-008, 009, 011 |
| M2 | `services/tags.py`, `services/bookmarks.py` | `tags.py` refused (`try`, module-level `logger`); `bookmarks.py` not checked | by hand | now only (`tags.py`); never (`bookmarks.py`) | GAP-009, 015 |
| M3 | `services/exporter.py` | would port (1 source), output typed `any` | raw material: the `export_netscape` logic follows it; the code in `app/` is rewritten with typed names, `bookmark_lines` split out and `epoch_of` added | at the time | none new |
| M3 | `services/parser.py` | refused: class attributes, class decorator, `with`, `super()` | by hand (`netscape_parse.jac`) | at the time | GAP-007, 008, 010, 011 |
| M3 | `services/importer.py` | refused: class attributes, class decorators, `try`, module-level `logger` | by hand (`netscape_import.jac`) | at the time | GAP-008, 009, 011, 015 |
| M3 | `management/commands/import_netscape.py` | refused: class attribute, `with`, `*args`/`**kwargs` | by hand (`cli.jac`, `admin.jac`) | at the time | GAP-007, 012, 040 |

Reading the table: of the 11 unit rows from M1 to M3, one (the exporter) would port, and its output was raw material, not used as-is; the other 10 were refused and designed by hand. Nothing was used as-is. Before the work the check was run on the M3 units and on an excerpt of `utils.py`; for `models.py`, `queries.py`, `routes.py`, `serializers.py`, `search_query_parser.py`, `tags.py` and the whole of `utils.py` it was run only afterwards, and `services/bookmarks.py` was never checked. So M1 and M2 skipped the "check first" step of CLAUDE.md "How to work" 3; the outcome is unlikely to differ (GAP-006 had the M0 whole-directory result: 197 of 251 refused), but it was not known at the time. The gap ids in the last column are matched by refusal kind from the gap titles; whether each was filed for exactly that unit was not re-read.

## Known deviations

Where the port differs from linkding or has no proof yet. The final report (M8) must repeat this list as it stands then.

- **Ids:** the port counts bookmark and tag ids per user (`ids.jac`); linkding's are global. Two users both get id 1 in the port.
- **`bookmarks/check/`:** not ported, no parity check (needs the network; M5).
- **Scraping:** no title, description, favicon or preview image is fetched on create. `favicon_url`, `preview_image_url`, `website_title` and `website_description` are always null in the port. The checks pin the field names, not these values.
- **Web-archive lookup:** not ported. `web_archive_snapshot_url` is the original's own fallback built from `date_added`.
- **`singlefile` and assets:** not ported, no check (need `files`; M5).
- **Bundles:** not ported, no check (M4 with the UI).
- **`?user=` on the shared list:** not ported. A root has no username (M6 with `auth`).
- **Shared list with sharing enabled:** implemented, never run (GAP-035; no API turns sharing on). Only the disabled case has a check.
- **Two-account isolation:** was untested at M2's close; now 7 checks (`parity/test_api_isolation.py`) pass on both targets with two users. Not covered: isolation of the profile and of the shared list (sharing cannot be turned on).
- **Ids, untried:** a global counter kept under `root.shared` was not tried; the per-user counters are the only approach run.
- **Links in a page:** `next` and `previous` are built from `http://` plus the `Host` header, so a client behind TLS or a proxy gets `http://` links. Whether the standard transport exposes the scheme was not checked.
- **M3, import and export:** the port reads and writes the same file as linkding (7 checks). Differences: only the attributes `HREF`, `ADD_DATE`, `LAST_MODIFIED`, `TAGS`, `TOREAD` and `PRIVATE` of a link are read (the original copies any attribute onto the parser); the import goes one bookmark at a time, not in batches of 200; of linkding's field validators only the URL (valid, 2048 long), the title (512) and the tag name (64) lengths are applied; favicon and preview jobs are not scheduled after an import (M5). Whether the original and the port agree on a file with an unusual layout beyond the 7 checks is untested.
- **M3, admin commands:** the port's CLI app (`cli`) has `import` and `export`, and acts as the account whose token it holds (`JAC_REMOTE_TOKEN`); the original's `import_netscape <file> <user>` names the user (GAP-040). linkding's other commands are not ported: `create_initial_superuser` and `ensure_superuser` (accounts belong to the `auth` plugin, M6), `backup`, `full_backup`, `generate_secret_key`, `enable_wal` and `migrate_tasks`. The two import and export commands have no check of their own beyond the 7 above, which call them. The import and export are not served over HTTP (the original's web form and view are M4), and the CLI calls the server through the bridge plugin, which now carries calls out as well (GAP-039, GAP-037).
- **M3, import of an archived marker on an existing bookmark (found by the gap audit by reading, not run):** the original's importer does not save `is_archived` for a bookmark it updates (`bookmarks/services/importer.py`: `_copy_bookmark_data` sets it, but `bulk_update` does not list it), the port sets it. No check covers an archived marker on an update. Fix and check are queued before M4 closes or in the next refactor.
- **Parity code is not tracked:** commit fdbd07d keeps `parity/*.py`, `run.sh` and `conftest.py` out of git on purpose (see `parity/README.md`); the two results files and the README are tracked. So the counts here can be reproduced only on the author's machine.
- **`int` is 64-bit (GAP-041):** `read_epoch` reads a number past 64 bits as no date; what the original does with such a number was not run.
- **Smaller:** `date_added` and `date_modified` sent on create are ignored; the profile `version` is the constant `1.47.0`; the bridge stands in for the standard transport (GAP-037).

## Refactor backlog

Pass of 2026-11-23 (before M3), one commit. Behaviour identical: `neojac test` 41 before, 42 after (one added); parity 71/71 on the original and on the port before and after. Merged: 8 duplicated pieces (the archive/unarchive twins; the `date_modified` stamp in three places, now `touch`; the case-insensitive name key in four places, now `name_key`; text matching and tag matching each in two modules, now `matching.jac`; the 405 reply in three places; the 400 "Invalid data" reply in three places; the yes/no test of `unread` and `shared`). Dead code removed: the unused `glob sample_count` and the unused `quote` parameter of `unescaped`. Checked, no change needed: `clock.test.jac` uses the `datetime` that `clock.jac` imports and `neojac check` is clean; two `UserProfile` nodes do not share `search_preferences` (a test now says so); the typed `lambda` keys are replaced by named key functions. Annexes (`*.test.jac`, `impl/*.impl.jac`) are not modules, so they carry no module docstring.

Left open, with the reason:
- `tag_counts` is about tags and lives in `bookmarks.jac`: moving it makes `tags` depend on the `Tagged` edge; decide the direction first.
- `find_tag_by_id` and `find_bookmark` are the same scan over two node types; the "id, then 404" step repeats in three routes. One generic helper was not attempted.
- `added_key` and `modified_key` differ only by attribute; a keyed sort needs a closure, left as two small functions.
- `draft` (bookmarks.test) and `seed` (search.test) are in different test modules and differ (one builds a draft, one saves); sharing one needs a test-helper module.
- `handle` is an if-chain over the first segment and `rest_user` is a one-function module (a route table); `profile_json` belongs with the profile; `handle` and `handle_public` both call `make_call`.
- `api_prefix` is set in `app/jac.toml` and assumed in two places of `app/`.
- The JSON body is encoded twice (envelope, then the bridge); `json_reply` in the bridge duplicates `reply_json` because a plugin cannot import the app (GAP-037).
- `parity/run.sh` and `tools/check_persistence.sh` both build, start and register; share one script. `check_persistence.sh` reads JSON with `sed`.
- `read_tag_names` uses `str(n)` after `all([isinstance(n, str) ...])`; whether `isinstance` in a comprehension narrows is unchecked.
- The bridge's outbound `send` (GAP-039) has no test of its own (`bridge.test.jac` covers the reply guard only) and returns no response headers; only the CLI checks reach it.
- The bridge keeps its settings and the app's handler in module `glob`s because the handler class is built by the library.
