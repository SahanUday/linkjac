---
id: GAP-021
title: neojac port refuses JavaScript tagged templates and rest parameters
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check tagged_template.js
code: E4001
---

## Symptom
`html`<b>hi</b>`` raises `port does not translate JavaScript's `tagged template` yet`; `...values` raises `a JavaScript rest or destructuring parameter`. 7 tagged templates in linkding's frontend (Lit `html` templates). Other E4001 kinds seen in the `bookmarks/` run but not reduced to a repro: `null` (6), `await` (4), `async` (3), `new` of a class not in the file (5), `forEach` (3), `JSON` (3), spread argument (2), `function` (2), `join` (1).

## Repro
```sh
neojac --version
neojac port --check js/tagged_template.js
```

`js/tagged_template.js`:

```js
function html(strings, ...values) { return strings.join(""); }
export const view = html`<b>hi</b>`;
```

## Expected
Documented by omission. `neojac docs interop/port-javascript`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The JavaScript mapping table in that page has no row for a tagged template or a rest parameter, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in the frontend in `bookmarks/frontend/` (Lit web components, Turbo); those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
