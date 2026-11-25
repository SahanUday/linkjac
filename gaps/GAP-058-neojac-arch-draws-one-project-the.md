---
id: GAP-058
title: neojac arch draws one project: the plugins and libraries an app binds are not in its picture
kind: limitation
severity: nit
status: open
area: arch
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: neojac arch --text (in app/)
code:
---

## Symptom
`neojac arch` run in `app/` draws the layers, modules, runtime and npm imports of the app. Who signs callers in and what serves HTTP are not in it: the plugins `linkauth` and `rest_bridge` and the library `token_header` they share, all in this repository and bound or declared by path in `jac.toml`, appear in neither the layers view nor `--view spaces`. Each is a project with a picture of its own.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
cd app && neojac arch --text && neojac arch --view spaces --text
grep -A3 '^\[packages\]' jac.toml
```

## Expected
Documented, so a limitation: `neojac help arch`, "The picture is drawn from archwire.jac and from nothing else". A view that also shows which plugin carries out each abstraction, and the packages it draws on, was wanted for an architecture review.

## Workaround
None. The review read each package's `archwire.jac` and `jac.toml`; PLAN.md (M6) says which plugin carries out what.

## Cause
Unknown.
