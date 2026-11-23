# Plan

Goal: a working Jac app that behaves like linkding (proven by the same checks run against both), and a complete, honest list of what neojac could not do. The gap list is the main result.

Update the Status column as work moves: `todo`, `doing`, `done`, `blocked`, `skipped`. One row is `doing` at a time. A `blocked` or `skipped` row needs a gap.

| ID | Milestone | Status | Done when (something we can show) |
|----|-----------|--------|-----------------------------------|
| M0 | Setup and baseline | done | linkding runs from `reference/`; `parity/` checks pass against it; `neojac absorb` and `neojac port --check` run on a copy outside the repo and their findings are logged; gap site is live |
| M1 | Data core | done | `app/jac.toml` has `[check.lint] ignore = ["strip-comments", "strip-docstrings"]` (set before any `neojac fmt --fix`); `archwire.jac` declares the layers; bookmarks, tags and users stored through `root` and the `store` plugin; `neojac arch` is clean; a `neojac test` run creates, lists and searches them |
| M2 | REST API | doing | API parity checks pass: same status codes, fields and filters as linkding's `/api/` (checkpoint) |
| M3 | Import, export, CLI | todo | a Netscape bookmark file round-trips; admin commands run from a CLI app |
| M4 | Web UI | todo | list, search, add, edit, tags pages work in a browser; the same browser checks pass on both apps (checkpoint) |
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
- [ ] S8 the rest of linkding's `/api/` that the checks do not cover yet: add parity checks against the original first, then port: `archived`, `shared`, `archive`, `unarchive`, `check`, `user/profile/` (assets and bundles wait for `files` in M5)
- [ ] S9 close: persistence check against the served port, `neojac arch` clean, gap audit, `/close-milestone`

## Refactor backlog

For `/refactor-pass`. From the M1 gap-audit (a read-only subagent re-run on 2026-11-23, then spot-checked: the unused `glob` was confirmed in the source; its file:line references were partly wrong, so the notes name functions). None of these is a neojac gap. No behaviour change.

- `bookmarks.test.jac`: `glob sample_count` is never used; delete it.
- `bookmarks.impl.jac`: `archive_bookmark` and `unarchive_bookmark` differ by one flag; the `date_modified = now_utc()` stamp is written in three places. Merge into one `set_archived` and one `touch`.
- Case-insensitive name key (`lambda ... n.lower()`) and the lower-case tag compare appear in `tag_names_of`, `tag_counts`, `lacks_tag` and `find_tag`. One key function and one compare, in `tags.jac`.
- `tag_counts` is about tags and lives in `bookmarks.jac`. Moving it to `tags.jac` makes `tags` depend on the `Tagged` edge in `bookmarks`; settle the dependency direction in `archwire.jac` first, or put it in its own module.
- `search.impl.jac`: `lacks_term`, `lacks_tag`, `matches`, `title_key`, `added_key`, `modified_key`, `in_order` exist only in the annex, with no declaration or docstring; every other module declares in the module and implements in the annex. Declare them, with one-line docstrings.
- `search.impl.jac`: `matches` repeats the yes/no test for `unread` and `shared`; `added_key` and `modified_key` differ only by attribute.
- `bookmarks.impl.jac`, `find_existing`: the `url_normalized == "" and url == url` fallback has no comment saying why.
- Tests: `draft` (bookmarks.test) and `seed` (search.test) do the same thing; keep one.
- `clock.test.jac` calls `datetime.utcnow()`; check whether `neojac check` flags it and what `datetime` it resolves to, and prefer an explicit import.
- To check, not assumed: `profiles.jac` has `search_preferences: dict[str, str] = {}` on a node; confirm two profiles do not share one dict (if they do, log a gap). `tag_names_of` and `tag_counts` use the typed `lambda (n: str) -> str { ... }` form; use named key functions unless the docs say the lambda is needed.
- `tools/check_persistence.sh`: its header says what it does, not why; it assumes `capped`, port 8301 and the `/__jac/call/api/service/` path. Replaced when `service.jac` is replaced in M2.
- Every `*.test.jac` and `impl/*.impl.jac` has no module docstring. CLAUDE.md asks for one on every module; decide whether annexes count.
