---
id: GAP-020
title: neojac port refuses JavaScript classes that extend another class
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check class_extends.js
code: E4001
---

## Symptom
`class B extends A {}` raises `port does not translate a JavaScript class that extends another, or has type parameters yet`. 15 in linkding's frontend (Lit elements and Turbo behaviours), plus 18 `super` and 5 static properties.

## Repro
```sh
neojac --version
neojac port --check js/class_extends.js
```

`js/class_extends.js`:

```js
class A { }
class B extends A { }
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping javascript`) lists what is translated. linkding uses this construct in the frontend in `bookmarks/frontend/` (Lit web components, Turbo), so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
