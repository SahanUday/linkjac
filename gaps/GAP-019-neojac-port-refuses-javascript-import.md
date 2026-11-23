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
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping javascript`) lists what is translated. linkding uses this construct in the frontend in `bookmarks/frontend/` (Lit web components, Turbo), so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
