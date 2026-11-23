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
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping javascript`) lists what is translated. linkding uses this construct in the frontend in `bookmarks/frontend/` (Lit web components, Turbo), so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
