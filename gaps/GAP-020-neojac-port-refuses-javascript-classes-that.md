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
Documented by omission. `neojac docs interop/port-javascript`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The JavaScript mapping table in that page has no row for a class that extends another, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in the frontend in `bookmarks/frontend/` (Lit web components, Turbo); those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
