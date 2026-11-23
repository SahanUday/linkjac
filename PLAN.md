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
