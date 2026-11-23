---
id: GAP-019
title: neojac port refuses JavaScript import
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check import_stmt.js
code: E4001
---

## Symptom
`import { html } from "lit"` raises `port does not translate JavaScript's `import` yet`. 47 in linkding's frontend, so no frontend module that imports anything can be ported.

## Repro
```sh
neojac --version
neojac port --check js/import_stmt.js
```

`js/import_stmt.js`:

```js
import { html } from "lit";
export const a = 1;
```

## Expected
Documented by omission. `neojac docs interop/port-javascript`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The JavaScript mapping table in that page has no row for `import`, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in the frontend in `bookmarks/frontend/` (Lit web components, Turbo); those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
