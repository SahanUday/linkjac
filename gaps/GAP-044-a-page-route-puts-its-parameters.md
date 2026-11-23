---
id: GAP-044
title: A page route puts its parameters last, so linkding's /bookmarks/<id>/edit cannot be a file route
kind: limitation
severity: minor
status: worked-around
area: ui
milestone: M4
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
linkding's edit page is at `/bookmarks/<id>/edit`. `neojac docs apps/pages` ("Routes") says a page's route is its path below `pages/` followed by its `page` function's parameters, and gives `pages/user.jac` with `id: str` as `/user/:id` and `pages/docs/index.jac` with `*rest: str` as `/docs/*`. In that scheme a parameter always comes after the file's path, so `/bookmarks/<id>/edit` has no file: `pages/bookmarks/edit.jac` with `page(id: str)` would be `/bookmarks/edit/<id>`. A directory named for a parameter in the middle of a path was tried afterwards (2026-11-23, in a copy of `app/` in `~/.claude-scratch/`, not in the repo): `pages/bookmarks/[id]/edit.jac` with `def:pub page(id: str) -> JsxPage` returning `<main>{"bracket page " + id}</main>`. `neojac build` built it, and the route table in the built bundle holds `path:"/bookmarks/[id]/edit/:id"`: the brackets are taken as literal characters of the path and the parameter is still appended last, so it is not `/bookmarks/<id>/edit`. Two more findings from the same copy: with that file the page could not import a component, because `archwire.jac` cannot name the module (`ui.bookmark_edit ++> pages.bookmarks.[id].edit { EditBookmark }` gives `error[E0003]: expected a module name, found '['` and E2097), and a page without the wire fails `neojac check` with `W2001 unknown name 'EditBookmark'`. `neojac check` also printed one `W3056` on the self-contained version (its text was not read; the build succeeded). Nothing in the docs mentions such a name.

An earlier attempt to make that directory inside `app/` was refused by the session's permission check, and the refusal text was not recorded, so which permission refused it is unknown. Run again in this session: the same `mkdir "<scratch>/pages/bookmarks/[id]"` ran with no prompt, and no rule in `~/.claude/settings.json`, `.claude/settings.json` or `.claude/hooks/guard.py` matches a path with brackets. Not tried: the command inside the repo's `app/` (CLAUDE.md forbids scratch files in the working tree).

## Repro
Read only, plus the attempt that was blocked:
```sh
neojac docs apps/pages        # section "Routes": the route table
# first attempt, refused by the permission check: mkdir 'app/pages/bookmarks/[id]'; write edit.jac in it with def:pub page(id: str) -> JsxPage; neojac check
# second attempt, in a copy under ~/.claude-scratch: the same, then neojac build; routes in the bundle's index-*.js: grep -o 'path:"[^"]*"'
```

## Expected
Docs silent on a parameter before a fixed segment. A way to write `/bookmarks/<id>/edit` (a route pattern, or a directory named for a parameter) was expected for an app that must keep linkding's addresses.

## Workaround
`pages/bookmarks/index.jac` takes `*rest: str` (route `/bookmarks/*`) and chooses the page by hand: no segments is the list, `archived` the archived list (M4 S5), `<id>` then `edit` the edit page (`WORKAROUND(GAP-044)` there).

## Cause
Unknown.
