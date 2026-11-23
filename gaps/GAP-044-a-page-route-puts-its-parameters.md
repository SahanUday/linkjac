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
linkding's edit page is at `/bookmarks/<id>/edit`. `neojac docs apps/pages` ("Routes") says a page's route is its path below `pages/` followed by its `page` function's parameters, and gives `pages/user.jac` with `id: str` as `/user/:id` and `pages/docs/index.jac` with `*rest: str` as `/docs/*`. In that scheme a parameter always comes after the file's path, so `/bookmarks/<id>/edit` has no file: `pages/bookmarks/edit.jac` with `page(id: str)` would be `/bookmarks/edit/<id>`. A file or directory named for a parameter in the middle of a path (`pages/bookmarks/[id]/edit.jac`) was tried to be created to see what `neojac check` says; the session's permission check refused the command, so it was not run and nothing is known about it. Nothing in the docs mentions such a name.

## Repro
Read only, plus the attempt that was blocked:
```sh
neojac docs apps/pages        # section "Routes": the route table
# attempted, not run (permission check): mkdir 'app/pages/bookmarks/[id]'; write edit.jac in it with def:pub page(id: str) -> JsxPage; neojac check
```

## Expected
Docs silent on a parameter before a fixed segment. A way to write `/bookmarks/<id>/edit` (a route pattern, or a directory named for a parameter) was expected for an app that must keep linkding's addresses.

## Workaround
`pages/bookmarks/index.jac` takes `*rest: str` (route `/bookmarks/*`) and chooses the page by hand: no segments is the list, `<id>` then `edit` is the edit page (`WORKAROUND(GAP-044)` there).

## Cause
Unknown.
