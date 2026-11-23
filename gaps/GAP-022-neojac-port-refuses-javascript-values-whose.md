---
id: GAP-022
title: neojac port refuses JavaScript values whose type TypeScript does not know
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check untyped_prop.js
code: E4005
---

## Symptom
`bookmark.title` where `bookmark` is an untyped parameter raises `port writes no Jac yet that keeps the meaning of the property 'title' of a value TypeScript does not know the type of`. 88 in linkding's frontend. In the same run, `===`, `||`, `+`, `<`, `>=` and the like on such operands raise E4005 (about 50), a template literal `${id}` of a non-string raises E4005 (11), a condition that is not a boolean raises E4005 (32), and a constructor-bound property raises E4005 (34). linkding's frontend has no type annotations.

## Repro
```sh
neojac --version
neojac port --check js/untyped_prop.js
neojac port --check js/template_lit.js
```

`js/untyped_prop.js`:

```js
export function title(bookmark) {
  return bookmark.title;
}
```

`js/template_lit.js`:

```js
export function url(id) {
  return `/api/bookmarks/${id}/`;
}
```

## Expected
Partly documented. `neojac docs interop/port-javascript`, section "What is refused" lists, as E4005: "An operator on operands TypeScript does not know the types of", "A condition that is not a boolean", "A property a method binds that the constructor does not", and "A top-level variable that functions use". It does not name a property read of an untyped value (`bookmark.title`), the largest group here (88); that one is by omission under "Anything not in the table is refused with E4001". Recorded because linkding's frontend is plain JavaScript, so most of it falls here.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
