---
id: GAP-042
title: Page examples in the docs and the pages skill put the body inline; the default lint (W3055) refuses an inline body in pages/
kind: docs
severity: minor
status: open
area: docs
milestone: M4
found: 2026-11-23
neojac: 0.4.0
command: neojac check
code: W3055
---

## Symptom
`app/pages/bookmarks.jac` was written as `neojac docs apps/pages` and the pages-and-components skill show a page: `def:pub page -> JsxPage { has ...; ... return <main>...</main>; }` with the body in the module. `neojac check` then said `error[W3055]: the body of 'page' belongs in an impl: a module reads as its declarations, by design; neojac fmt --fix moves the body to the module's impl annex [separate-impls]`, for `page` and for a component in the same file, and counted them as 2 errors. `neojac fmt --fix pages` moved both bodies to `pages/impl/bookmarks.impl.jac` and `neojac check` was then clean. Only these two functions were run; other examples were not.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# project with app/jac.toml, a browser space with pages.*, and pages/index.jac = the page of `neojac docs apps/pages` "The shortest site"
neojac check                          # W3055 on `page`
```

## Expected
The docs' examples to pass the default `neojac check`, or the pages to say that bodies go in an annex. `neojac docs apps/pages` ("The shortest site", "What a page module declares") says a page module declares `page` and shows no annex; it says `.impl.jac` files under `pages/` are not pages ("except `.impl.jac` and `.test.jac` files and anything in a directory named `impl`") but not that a page's body belongs there.

## Workaround
`neojac fmt --fix pages`, once (allowed here: `app/jac.toml` has the lint ignore for comments and docstrings). Nothing in the code.

## Cause
Unknown.
