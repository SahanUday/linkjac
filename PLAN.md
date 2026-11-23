# Plan

Goal: a working Jac app that behaves like linkding (proven by the same checks run against both), and a complete, honest list of what neojac could not do. The gap list is the main result.

Update the Status column as work moves: `todo`, `doing`, `done`, `blocked`, `skipped`. One row is `doing` at a time. A `blocked` or `skipped` row needs a gap.

| ID | Milestone | Status | Done when (something we can show) |
|----|-----------|--------|-----------------------------------|
| M0 | Setup and baseline | done | linkding runs from `reference/`; `parity/` checks pass against it; `neojac absorb` and `neojac port --check` run on a copy outside the repo and their findings are logged; gap site is live |
| M1 | Data core | done | `app/jac.toml` has `[check.lint] ignore = ["strip-comments", "strip-docstrings"]` (set before any `neojac fmt --fix`); `archwire.jac` declares the layers; bookmarks, tags and users stored through `root` and the `store` plugin; `neojac arch` is clean; a `neojac test` run creates, lists and searches them |
| M2 | REST API | done | API parity checks pass: same status codes, fields and filters as linkding's `/api/` (checkpoint) |
| M3 | Import, export, CLI | done | a Netscape bookmark file round-trips; admin commands run from a CLI app |
| M4 | Web UI | closed with exceptions (judged 2026-11-23; see Known deviations: 40 of 41 UI checks pass on the port and 1 is `expected_gap` GAP-045; S7 to S9 not built; sign-up cannot be disabled, GAP-046) | list, search, add, edit, tags pages work in a browser; the same browser checks pass on both apps (checkpoint) |
| M5 | Background work | done (judged 2026-11-23, see M5 below) | page snapshot and favicon jobs run and a scheduled job fires |
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

Done-when for M4 is judged at the end of S6 (see the paragraph under the list). S7 to S9 are not in the done-when.

- [x] S1 list page: items, order, search box and `q`, tags region, tag links, 30 per page, Previous and Next (spike above; 7 checks, original 7/7, port 7/7)
- [x] S2 add: `/bookmarks/new` with URL, Tags (space-separated), Title, Description, Notes, unread box; same URL updates; invalid URL error; Cancel (6 checks, `parity/test_ui_add.py`; original 6/6, port 6/6; a mutant that broke tag splitting and the error text failed 2 of them)
- [x] S3 edit: `/bookmarks/<id>/edit` filled from the bookmark, Save, Cancel, the Edit link of an item, a bad address refused (6 checks, `parity/test_ui_edit.py`; original 6/6; port 5 passed and 1 expected gap: a missing bookmark answers 404, GAP-045). The route has the id before a fixed segment, so one page takes `/bookmarks/*` (GAP-044). List and form became components in `app/ui/`
- [x] S4 tags page: `/tags` table of tags with counts, search, sort (4 orders), unused-only filter, count link to the list, Create Tag, Edit (rename), Remove with the "Are you sure?" question (8 checks, `parity/test_ui_tags.py`; original 8/8, port 8/8). `/tags/new` and `/tags/<id>/edit` are one page that takes the rest of the path (GAP-044). Not done: "Merge Tags", the "Showing n of m" text has the original's words but the original also pages the table (the port does not)
- [x] S5 remove and archive on the list; archived list and unarchive (6 checks, `parity/test_ui_actions.py`; run on the original first, 6/6; port 6/6). New `web_actions.jac` (`archive_bookmark`, `remove_bookmark`), reusing `find_bookmark`, `set_archived`, `delete_bookmark`; the list takes `archived`, and `/bookmarks/archived` is one more case of the catch-all page (GAP-044); Remove asks "Are you sure?" as the original does
- [x] S6 sign-in and root: anonymous visit leads to sign-in, wrong password refused, `/` leads to the list, sign out (6 checks, `parity/test_ui_signin.py`; original 6/6, port 6/6). New `pages/index.jac` (`/`) and `ui/site_nav.jac` (links and a Logout button, on the list, tags, add and edit pages). Sign-in itself is the `accounts` plugin's dialog; GAP-046 (its "Create account" button and open `register`)
- [ ] S7 (not in the done-when; left open) search preferences: sort, shared and unread filters; unread and shared marks on items
- [ ] S8 (not in the done-when; left open) bulk edit
- [ ] S9 (not in the done-when; left open) settings page (profile fields) and the import and export form

#### M4 done-when, judged 2026-11-23 (end of S6)

Done-when, quoted from the table: "list, search, add, edit, tags pages work in a browser; the same browser checks pass on both apps (checkpoint)".
- The five pages exist and are driven in a real browser (headless Chrome through Playwright), by role and name: list and search (7 checks), add (6), edit (7), tags (9). Plus S5 (6) and S6 (6), which the wording does not name.
- "The same browser checks pass on both apps": the 41 UI checks pass on the original (41/41, run first). On the port 40 pass and 1 is an `expected_gap_on_port("GAP-045")` check, which runs and must fail there: a missing bookmark's edit address answers 404 on the original and 200 with the shell on the port. Read literally, that is not "pass on both" for 1 check of 41; under rule 7 of CLAUDE.md ("a check that cannot pass gets `expected_gap`") it is the allowed way to count it. Totals, both targets, run 2026-11-23: original `{"passed": 120, "total": 120}`, port `{"passed": 119, "total": 120}` (119 passed + 1 expected failure).
- Sign-in, remove and archive are not named by the done-when, so they were not needed to meet it; they are done anyway (S5, S6). Search preferences, bulk edit, settings and the import form (S7 to S9) are in the table of pages above but not in the done-when; they stay open and are listed in Known deviations.
- Judgement: met, with that one expected gap. M4 is closed on that reading; if the stricter reading (no expected gap) is wanted, M4 stays open until GAP-045 is resolved.

#### Mutation checks of the UI and Netscape checks (2026-11-23)

Method: a scratch copy of `app/` and `parity/` (outside the repo, `~/.claude-scratch/<session>/mut`), one source change at a time, `neojac build`, the port served, only the checks of that area run (`-k`), the file restored; the repo was not touched. Counts are mutant runs on the port.
- First batch: 64 mutants (list 17, edit 14, tags 16, Netscape 17: archived marker 5, private flag 4, bad and repeated addresses 8). Result: 46 killed, 8 survived, 10 invalid (the build refused them with E1146: a mutant that stops using a wired name; rewritten as `if False { ... }`).
- Survivors, and what strengthened them: `Previous` goes two pages back and page links that drop the search (the page-2 test passed by coincidence of data; now it adds a newer bookmark outside the search, clicks Previous and a page number, and checks the Previous link's address); notes not saved on edit and address not trimmed (the edit test now fills Notes and a new check saves an address with spaces around it; the original passes both); the "Showing n of m tags" text (the original shows "N tags total" with no filter and "Showing x of N tags" with a search or the unused filter; the port showed the second always, so that was a real difference, now fixed and checked); a bad `LAST_MODIFIED`, an address over 2048 characters and a title over 512 accepted by the importer (rows added to the bad-address check; the original refuses all three).
- Second batch (after strengthening, on the current code, with the 10 rewritten mutants and 16 new ones for S5 and S6: unarchive and archive doing nothing, Cancel removing, the list not refreshing, the archived address showing the live list, Logout not signing out, root leading elsewhere, the list not asking for a sign-in): 36 runs, 33 killed, 3 survived: Previous (the first strengthening only reached page 2, where the mutant also lands on page 1), Logout without leaving the page (the check visited `/bookmarks` itself afterwards), and "total counts the rows shown" which is an equivalent mutant (with no filter the rows are all the tags). The first two were fixed in the checks and re-run: both killed.
- Final tally: 81 distinct mutants; 80 killed (46 in the first batch, 18 after the checks were strengthened or the mutant rewritten, 16 for S5 and S6), 1 equivalent. Netscape: archived marker 5 of 5 killed (the marker on an existing bookmark by the new check), private flag 4 of 4, bad and repeated addresses 8 of 8 (3 only after strengthening).
- Not covered: the sign-in checks test the `accounts` plugin's dialog, so no mutant of `app/` changes a wrong password or an anonymous visit except removing the app's `sign_in()` call (killed); the add checks were not mutated beyond the earlier tag-splitting mutant (but the edit mutants of the shared save path also ran the add checks); mutants were of one line each, none of several lines at once. A killed mutant says the checks notice that change, not that they notice every one.


#### Text sweep and importer sweep (2026-11-23, before M5)

- **Text sweep** (`parity/test_text_sweep.py`, 8 checks): the account is wiped and given the same 4 bookmarks (tags, notes, unread, archived) and one unused tag; each page (list, archived, add, edit, tags, new tag, a search, an empty search) is read as the words of its visible text nodes (document order, so CSS cannot move a word; text areas and hidden nodes left out; a submit button's caption added) plus each form field's label and value. Dates are one word `<date>`, whitespace is collapsed, a tag's `#` is dropped (linkding draws it in CSS). The original's text is the snapshot (`parity/text/*.txt`, recorded with `PARITY_RECORD_TEXT=1` on the original); on the original the check is "same text as the snapshot" (8/8, twice, run first), on the port it is "the differences from the snapshot are exactly the `KNOWN` list in the file" (8/8), so a new difference and a fixed one both fail.
- Fixed because the sweep showed them (port): links and buttons ran together as words ("Add bookmarkBookmarksArchived..."); no empty-state text (the original says "You have no bookmarks yet" and how to start) and the pagination showed for an empty list; no help text under Tags, Mark as unread and Notes; no Search button; the Notes section was closed on a bookmark that has notes.
- Left, in `KNOWN`, listed here as deviations: the heading "LINKDING" and a Settings link (none in the port; the port's navigation has Archived and Tags as links, the original keeps them in a menu); per bookmark the date link, the View link, the Unread mark and the Notes button; the Bundles region; the tag cloud's first letter in its own element (same word); the "Refresh from website" and "Clear" buttons on the edit form (need the fetch, M5) and the form's second, visually hidden "Notes" label; "Merge Tags" and the tags table's pagination; the empty state's four links (adding, importing, browser extension, bookmarklet) are plain words in the port (no settings pages to point to).
- **Importer sweep** (`parity/test_import_sweep.py`, 2 checks, with and without `--map-private-flag`): one fixed Netscape file with 14 links (entities, a title with accents, emoji and kana, no title, TOREAD, PRIVATE 0 and 1, the archived marker, notes, a bad date, a link in a folder, the same address twice in the file, `Two/` and `Two` and a host in capitals, tags with a repeated name in two spellings, spaces and an empty name) imported into an empty account, every field the API shows read back for each bookmark (15 fields, and the tag names); then a second file over it (changed title, tags and notes, a link without title, description or notes, an archived marker on an existing bookmark, one new link) and the same read. Original is the snapshot (`parity/import/*.json`), 2/2 twice; port 2/2.
- Difference found and fixed: a tag name that appears in two spellings in one tag string (`Blue,blue`): the original keeps the last spelling (`unique()` in `bookmarks/utils.py` is a dict comprehension), the port kept the first. `parse_tag_string` is shared by the API, the forms and the importer; the test that said the first stays was wrong and is changed. Not run on the API (a parity check of `tag_names` with two spellings is still to be written).
- Mutation of the new checks (scratch copy, one change at a time): importer 7 mutants (archived marker on update, private flag inverted, title not updated, notes not updated, unread cleared, modified date falling back to now, first spelling wins), all killed; the notes mutant survived the first version of the sweep (the second file gave no new notes), the file was changed and it is killed. Text sweep 7 mutants (tags help text, empty-state text, no Search button, a label of the tags page, a navigation caption, notes never open, pagination on an empty list), all killed.
- What the sweeps do not cover: pages with 30 or more bookmarks (paging), a second user's pages, the sign-in page's text, dialogs opened by a click (Remove's question), the text after an action; dates other than "Today"; a file with several hundred links (the original imports in batches of 200).

### M5

Done when (quoted from the table): "page snapshot and favicon jobs run and a scheduled job fires".

#### What neojac's docs support (read 2026-11-23: `neojac docs search` for background job, jobs, schedule, outbound http request, files; pages `apps/server` "Scheduled functions" and "Jobs", `apps/plugins`, `apps/data`, `library/urllib`)

- **Jobs:** `@job def f(input, note: JobNote) -> R`, started with `flow f(x)` (gives a `Job[R]` at once), `j.done()`, `wait j`; run by the `jobs` plugin (`process_jobs`: a copy of the program for each). A job does not see the graph and cannot change it; input and result cross as a crossing's values. A job of the module a program starts at cannot be started (E5090). A job is not an endpoint (E2223).
- **Schedule:** `@schedule(interval=60.0)` on a function with no parameters; first run as the server starts; runs for no caller: `root` raises, `root.shared` and `allroots()` (from `stdjac`) are there; what it changes is kept; `JAC_TICKS_OFF` turns it off.
- **Outbound HTTP:** native `urllib.request.urlopen(url, timeout=...)` and `http.client` (`library/urllib`, `library/http`); https verifies certificates with the system CAs.
- **Files:** the abstractions of `neojac docs apps/plugins` are store, auth, transport, llm, jobs, schedule, limits, ui, bundler. There is no `files` abstraction, and `CLAUDE.md` and the M2 note above ("need `files`") assumed one (our error, as GAP-001 was: not a neojac gap). Bytes can be kept in a node (spike below).

#### Spike (2026-11-23, scratch project, nothing in the repo)

A 3-module native project in `~/.claude-scratch/<session>/spike`, a fixture HTTP server (page with metadata, favicon, redirect, 404) and `curl`:
- `urllib.request.urlopen` inside a `:pub` function: 200 with the body, a 404 raises `HTTPError` (`code`), a refused connection `URLError`, a redirect is followed.
- A `@job` that fetches a page returned its text (184 bytes); one returned `bytes` (67 bytes: the favicon image); both were started with `flow` from a `:pub` function and read with `j.done()` and `wait j`.
- A `bytes` field of a node under `root.shared` kept its 67 bytes across a restart of the served binary.
- `@schedule(interval=2.0)` ran at server start and every 2 s (1, then 3 beats after 5 s); the nodes it made under `root.shared` were kept across a restart.
- A scheduled function walked `allroots()`, found a user's `Note` node with no image, started a job with `flow`, on a later turn read it with `wait` and wrote the bytes onto the user's node; the user's own call saw them (`first:0`, then `first:67`).
So the design that fits the docs: a bookmark that wants a favicon or a snapshot is marked in its own node; one scheduled function scans `allroots()`, starts jobs, and stores finished results. That is the same function that makes "a scheduled job fires". What it does not show: many roots at once, a job that fails, the job's copy of the program starting cost, serving stored bytes over HTTP.

#### M5 done-when, judged 2026-11-23

Done-when, quoted from the table: "page snapshot and favicon jobs run and a scheduled job fires".
- Favicon job runs: S3, 4 checks + 1 (import), each against the fixture site, original first. Page snapshot job runs: S4, 8 checks. A scheduled job fires: `run_background_work` starts both jobs; with its interval set to 2000 s a mutant failed the favicon check by timeout (the job never started), with the control (no change) passing.
- Counts, full run 2026-11-23 before S4 and S5 (parity-runner, result files read): original 151/151, port 150/151 + 1 expected gap (GAP-045). After S4 and S5 the new checks were run alone (`-k test_jobs`): original 9/9 and port 9/9 for snapshots and favicons plus the import check; the final full count is in the journal.
- Honest limits: the original's task worker and `single-file` are replaced in the checks as said above; the jobs of the port ran with `process_jobs` (a copy of the program for each); nothing was measured of their cost or of many bookmarks at once; no check restarts the server between asking and finishing; a job that fails is only checked for the snapshot (status failure), not for the favicon's retry.

#### Method for network features

Parity for anything that fetches runs against a local fixture HTTP server (`parity/fixture_server.py`, 127.0.0.1:9100: pages with a title, description and `og:image`, a page with only `og:description`, a page with no title, a redirect, a 404, a favicon at `/favicon/<domain>`, and `/__seen` listing what it was asked for). Both apps are pointed at it, never the internet. The original needs `LD_ALLOWED_INTERNAL_HOSTS=127.0.0.1` (its SSRF guard refuses loopback otherwise: `bookmarks/services/http_client.py`), `LD_FAVICON_PROVIDER=http://127.0.0.1:9100/favicon/{domain}`, its task worker (`manage.py run_huey`, a second process) and, for snapshots, `LD_ENABLE_SNAPSHOTS=True` with `LD_SINGLEFILE_PATH` set to a small stand-in script (the real `single-file` needs a browser and is not installed here); the port must apply the same guard and read the same setting.

#### Slices

- [x] S1 website metadata: `/api/bookmarks/check/?url=` (metadata title, description, preview image, `bookmark` when the URL exists, `auto_tags` empty) with the SSRF guard and the fixture server (11 checks, `parity/test_api_check.py`; original 11/11 run first, port 11/11; 9 mutants of the port, 9 killed, 3 of them only after the fixture gained `/both` and `/gone`). New modules `web_fetch` (http.client, manual redirects, guard, 5 MB limit) and `website` (HTMLParser), layer `net`, `rest_check`. Differences kept: no cache of the last 10 pages (the original has one, `ignore_cache` is read and ignored), UTF-8 only (the original detects the charset), `auto_tags` always empty (no auto-tagging rules)
- [x] S2 metadata on create: `enhance_with_website_metadata` after an API create unless `disable_scraping` is in the query (6 checks, `parity/test_api_scraping.py`; original 6/6 run first, port 6/6; 4 mutants killed, 1 after the checks gained a description-only case). Not copied: the original fetches even when title and description are given, the port does not (no check can see it)
- [x] S3 favicon job: a scheduled function (`background.jac`, every 2 s) walks `allroots()`, starts a `@job` (`favicon_job.jac`) for each site whose bookmarks lack an icon and have `enable_favicons`, keeps the result as a `Favicon` node under `root.shared` and gives the bookmarks the file name; the bridge serves `/static/<file>` (GAP-031 note). 4 checks (`parity/test_jobs_favicon.py`, account parity3 alone, the profile set by the original's shell script and by the port's `web_settings.change_profile`): original 4/4 (run first, twice), port 4/4; 8 mutants killed and a no-change control survived. Differences: no retry backoff of 5 tries (one retry a minute), no one-day staleness, favicon name shared across users (as the original), the port keeps the bytes as base64 text in the graph
- [x] S4 page snapshot job: an `Asset` node per bookmark (pending, then complete or failure), asked for on API create when `LD_ENABLE_SNAPSHOTS` is on and the profile wants it, filled in by a `@job` (`snapshot_job.jac`) that the scheduled function starts (2 at a time); `/api/bookmarks/<id>/assets/` list, one, download, delete; the bridge sends a file reply (`__file__`) as bytes with a Content-Disposition. 8 checks (`parity/test_jobs_snapshot.py`; the original runs its `single-file` command as `parity/single_file_stub.py`, which only fetches the page, so what is compared is the asset's fields, states and that the download holds the page): original 8/8 run first, port 8/8; 11 mutants killed, 2 of them rewritten after the build refused them, and a no-change control survived. Differences: the original keeps a gzip file and its `file_size` is the compressed size, the port the text's size; no PDF snapshots; a re-made bookmark with no assets asks again; the original's lock gives one snapshot at a time, the port two; an upload route is not ported. Gap: GAP-048
- [x] S5 scheduled job: `run_background_work` (`@schedule(interval=2.0)`) is the one function that starts the favicon and snapshot jobs and stores what finished (it was written in S3 and S4; its firing is what those 12 checks and a mutant that sets its interval to 2000 s show); an import is followed by favicons with no further request (`parity/test_jobs_import.py`, original 1/1 run first, port 1/1; a control and 2 mutants, both killed). An import asks for no snapshot, as the original's does not
- [ ] S6 spare, not used (M5's done-when was met after S5) (a job that fails and is retried, or the profile's `enable_preview_images`)

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
| M5 | `website_loader`, `favicon_loader`, `http_client`, `assets`, `tasks`, `singlefile` (`bookmarks/services/`) | 6 of 6 refused (61 lines: try, decorator, class attribute, with, `**`, `*args`, super) | none used; by hand | only afterwards, 2026-11-23 | GAP-006 (note), 007 to 012 |

Reading the table: of the 11 unit rows from M1 to M3, one (the exporter) would port, and its output was raw material, not used as-is; the other 10 were refused and designed by hand. Nothing was used as-is. Before the work the check was run on the M3 units and on an excerpt of `utils.py`; for `models.py`, `queries.py`, `routes.py`, `serializers.py`, `search_query_parser.py`, `tags.py` and the whole of `utils.py` it was run only afterwards, and `services/bookmarks.py` was never checked. So M1 and M2 skipped the "check first" step of CLAUDE.md "How to work" 3; the outcome is unlikely to differ (GAP-006 had the M0 whole-directory result: 197 of 251 refused), but it was not known at the time. The gap ids in the last column are matched by refusal kind from the gap titles; whether each was filed for exactly that unit was not re-read.

## Known deviations

Where the port differs from linkding or has no proof yet. The final report (M8) must repeat this list as it stands then.

- **Ids:** the port counts bookmark and tag ids per user (`ids.jac`); linkding's are global. Two users both get id 1 in the port.
- **`bookmarks/check/`:** ported in M5 S1 (11 checks against the local fixture site). Differences: no cache of the last 10 pages and `ignore_cache` is read and ignored; UTF-8 only; `auto_tags` always empty.
- **Scraping, favicons, previews (M5):** the title and description are fetched on an API create (S2) and a favicon after it (S3); `preview_image_url`, `website_title` and `website_description` are still always null (no preview image job: `enable_preview_images` has no effect). The fetch reads `LD_ALLOWED_INTERNAL_HOSTS` and `LD_FAVICON_PROVIDER` as the original does; it refuses addresses that are not public the way the original's guard does, checked on loopback only (the checks cannot show a private range, a link-local or an IPv6 address). The port fetches the page for a title only when title or description is empty (the original always fetches), keeps no favicon staleness (the original refetches after a day), retries a failed favicon once a minute without a limit (the original: 5 tries with growing delays), and keeps favicon bytes as base64 text in the graph.
- **Web-archive lookup:** not ported. `web_archive_snapshot_url` is the original's own fallback built from `date_added`.
- **Assets (M5 S4):** the list, one asset, its download and its removal are ported for snapshots; not ported: `POST /bookmarks/<id>/assets/upload/`, `POST /bookmarks/singlefile/`, PDF snapshots, the web page's asset views. The snapshot is the page's text fetched by a job, not a `single-file` browser capture (no inlined images or styles); the checks run the original with a stand-in script for `single-file` that only fetches the page, so what is compared is the asset's fields and states and that the download holds the page. The original's `file_size` is the gzip file's, the port's the text's; the original makes one snapshot at a time, the port two; a made-again bookmark that has no assets asks again; an import asks for no snapshot (as the original).
- **Bundles:** not ported, no check (M4 with the UI).
- **`?user=` on the shared list:** not ported. A root has no username (M6 with `auth`).
- **Shared list with sharing enabled:** implemented, never run (GAP-035; no API turns sharing on). Only the disabled case has a check.
- **Two-account isolation:** was untested at M2's close; now 7 checks (`parity/test_api_isolation.py`) pass on both targets with two users. Not covered: isolation of the profile and of the shared list (sharing cannot be turned on).
- **Ids, untried:** a global counter kept under `root.shared` was not tried; the per-user counters are the only approach run.
- **Links in a page:** `next` and `previous` are built from `http://` plus the `Host` header, so a client behind TLS or a proxy gets `http://` links. Whether the standard transport exposes the scheme was not checked.
- **M3, import and export:** the port reads and writes the same file as linkding (7 checks). Differences: only the attributes `HREF`, `ADD_DATE`, `LAST_MODIFIED`, `TAGS`, `TOREAD` and `PRIVATE` of a link are read (the original copies any attribute onto the parser); the import goes one bookmark at a time, not in batches of 200; of linkding's field validators only the URL (valid, 2048 long), the title (512) and the tag name (64) lengths are applied; favicon and preview jobs are not scheduled after an import (M5). Whether the original and the port agree on a file with an unusual layout beyond the 7 checks is untested.
- **M3, admin commands:** the port's CLI app (`cli`) has `import` and `export`, and acts as the account whose token it holds (`JAC_REMOTE_TOKEN`); the original's `import_netscape <file> <user>` names the user (GAP-040). linkding's other commands are not ported: `create_initial_superuser` and `ensure_superuser` (accounts belong to the `auth` plugin, M6), `backup`, `full_backup`, `generate_secret_key`, `enable_wal` and `migrate_tasks`. The two import and export commands have no check of their own beyond the 7 above, which call them. The import and export are not served over HTTP (the original's web form and view are M4), and the CLI calls the server through the bridge plugin, which now carries calls out as well (GAP-039, GAP-037).
- **M3, archived marker on an existing bookmark (closed 2026-11-23):** the gap audit had found by reading that the original's importer does not save `is_archived` for a bookmark it updates (`bookmarks/services/importer.py`: `_copy_bookmark_data` sets it, `bulk_update` does not list it). Run: check `test_the_archived_marker_does_not_archive_a_bookmark_that_exists` (import a link, import it again with `linkding:bookmarks.archived`, expect it still in the live list and not in `/api/bookmarks/archived/`) passed on the original (`bash parity/run.sh -k archived_marker`: `2 passed, 104 deselected`); on the port it failed (`KeyError: 'kept'`: the bookmark had been archived); `save_listed` now archives only a bookmark the import makes (`is_new`), with a unit test, and the 8 Netscape checks pass on the port. Not a deviation any more.
- **`int` is 64-bit (GAP-041):** `read_epoch` reads a number past 64 bits as no date; what the original does with such a number was not run.
- **M4, web UI (S1 to S6):** the pages are built in the browser from JSON the server gives (no server-rendered HTML; `curl` sees an empty shell). Sign-in is the `accounts` plugin's dialog, not linkding's `/login/` page: the refusal reads "incorrect username or password" and appears 1 to 3 seconds after the click, the original's "Your username and password didn't match. Please try again." at once; the dialog also offers "Create account" and `register` is open to anyone, linkding has no sign-up (GAP-046). The sign-in checks pin behaviour (anonymous visit asks, wrong password refused with a message, right one shows the list, `/` leads to the list, Logout ends the session), not the form's markup. A missing bookmark's edit address answers 200 with a message, not 404 (GAP-045, check `expected_gap_on_port`). `/bookmarks/<id>/edit`, `/bookmarks/archived` and `/tags/<id>/edit` are one catch-all page each (GAP-044). The navigation is a `<nav>` inside each page's main with Add bookmark, Bookmarks, Archived, Tags and Logout; linkding's has menus (Bookmarks, Settings) and a banner. The list has no date link, View link, bundles region, "Bulk edit" button, search preferences, empty-state text or bookmark notes yet; pagination lists every page number and has no "..."; the tags region lists names without letter grouping; the tags table is not paged and has no "Merge Tags"; the add form has no "Share" box, no title and description fetch, no tag autocomplete; Remove and Archive act on one bookmark at a time with no success message. S7 to S9 (search preferences, bulk edit, settings page, import and export form) are not done. Look and feel (CSS, icons, dark theme) is not reproduced: the port's pages are unstyled HTML. linkding's MIT licence applies if its CSS is ever copied; none has been, so no notice is in the repo yet (`reference/linkding/LICENSE.txt` is the notice to copy).
- **M4 exceptions (closed with exceptions, 2026-11-23):**
  - **GAP-045, 40 of 41 UI checks:** on the port 40 of the 41 UI checks pass; the 41st (`test_a_missing_bookmark_answers_404`) is `expected_gap_on_port("GAP-045")`: a missing bookmark's edit address answers 200 with the shell, the original 404. The original passes 41 of 41.
  - **S7 to S9 not built:** search preferences (sort, shared and unread filters), bulk edit, the settings page, and the import and export form. They are in the table of pages and have no check; the port has no page for them.
  - **Sign-up cannot be disabled (GAP-046, major):** the `accounts` plugin offers "Create account" and `register` is open to anyone; linkding has no sign-up. M6 must close this.
- **M4 text differences (text sweep, 2026-11-23):** the list of what the port's pages say differently from the original is in `KNOWN` of `parity/test_text_sweep.py` and in "Text sweep and importer sweep" under M4 above; it is not repeated here.
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
- The conditional elements in `ui/` are written `{[<x key=.. /> for _ in range(1) if cond]}`. `neojac docs apps/components` shows `{<b>yes</b> if cond else <i>no</i>}`; tried in a scratch copy for the missing-bookmark message of the edit page: it checks and runs in the browser (the edit checks pass on the port). So the one-item comprehension is not a workaround for a neojac limit; replace it with the documented form in the next refactor pass (found by the M4 gap audit).
- The bridge keeps its settings and the app's handler in module `glob`s because the handler class is built by the library.
