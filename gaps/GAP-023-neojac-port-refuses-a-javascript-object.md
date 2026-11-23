---
id: GAP-023
title: neojac port refuses a JavaScript object literal that is not a table of one value type
kind: limitation
severity: nit
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check object_literal.js
code: E4001
---

## Symptom
`{ "Content-Type": "application/json", n: 1 }` raises `port does not translate an object literal that is not typed as a table of one value type (`Record<string, T>`) yet`. 38 in linkding's frontend.

## Repro
```sh
neojac --version
neojac port --check js/object_literal.js
```

`js/object_literal.js`:

```js
export const headers = { "Content-Type": "application/json", n: 1 };
```

## Expected
Documented by omission. `neojac docs interop/port-javascript`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The JavaScript mapping table in that page has no row for an object literal not typed `Record<string, T>` (the table lists only that form), and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in the frontend in `bookmarks/frontend/` (Lit web components, Turbo); those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
