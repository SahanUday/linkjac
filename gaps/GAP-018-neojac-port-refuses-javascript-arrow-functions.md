---
id: GAP-018
title: neojac port refuses JavaScript arrow functions
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check arrow.js
code: E4001
---

## Symptom
`xs.map((x) => x * 2)` raises `port does not translate JavaScript's `arrow function` yet`. 44 in linkding's frontend.

## Repro
```sh
neojac --version
neojac port --check js/arrow.js
```

`js/arrow.js`:

```js
export function double(xs) {
  return xs.map((x) => x * 2);
}
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping javascript`) lists what is translated. linkding uses this construct in the frontend in `bookmarks/frontend/` (Lit web components, Turbo), so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
