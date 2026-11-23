---
id: GAP-043
title: A page that builds an obj of the server's space (has data: ListPage = ListPage()) fails in the browser: this.init is not a function
kind: bug
severity: minor
status: worked-around
area: ui
milestone: M4
found: 2026-11-23
neojac: 0.4.0
command: neojac browse open http://127.0.0.1:8341/bookmarks
code:
---

## Symptom
In `app/`, `web_list.jac` (space `api`) declares `obj ListPage { has items: list[ListedBookmark] = [], ...; }` with a default for every field, and `archwire.jac` wires it into the page (`web_list ++> pages.bookmarks { bookmark_page, ListPage, ListedBookmark }`). The page `pages/bookmarks.jac` had `has data: ListPage = ListPage();`. `neojac check` and `neojac build` were clean. In the browser (`neojac browse snapshot` after `open`), the page showed nothing but `TypeError: this.init is not a function at D.$init (.../assets/index-*.js)`, and `neojac browse errors` printed `jac: a component failed` with the same message. Replacing the line by one `has` per field (`has items: list[ListedBookmark] = [];` and so on) and assigning from `await bookmark_page(q, number)` made the page render and list the bookmarks. The server function itself answered correctly when called by `curl` (`/__jac/call/api/web_list/bookmark_page`).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# this repo's app/ before the change: pages/impl/bookmarks.impl.jac with  has data: ListPage = ListPage();
cd app && neojac install && neojac build
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8341 dist/api-linux-x86_64/api &
neojac browse open http://127.0.0.1:8341/bookmarks && neojac browse snapshot    # the TypeError text
```
Not reduced to a project of its own: it is not known whether an obj declared in the browser space, or built in an effect rather than as a `has` default, fails too.

## Expected
`neojac docs apps/components` and `apps/pages` show a page's state as `has x: T = value`, and `neojac docs apps/crossings` says an `obj` crosses "as an object of its fields". Nothing read says a page may not build the obj of another space, and a build that is clean was expected to run.

## Workaround
One `has` per field instead of the obj (`pages/impl/bookmarks.impl.jac`).

## Cause
Unknown.
