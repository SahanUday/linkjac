---
id: GAP-028
title: E1146 flags a wire name that only a module's test annex uses, under bare check and check <app>, not under check <module> or test
kind: bug
severity: minor
status: worked-around
area: arch
milestone: M1
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
A wire `a ++> b { make }` whose name `make` is used only in `b.test.jac` is accepted by `neojac check b.jac` and `neojac test`, but `neojac check` (no argument) and `neojac check api` report `E1146: 'make' is wired into 'b', which never uses it` once `b` is in a space of an app. A project cannot have both a test that needs a name from another module and a clean `neojac check`.

Seen again in M4 S5 (2026-11-23) with `web_actions.test.jac`: `neojac test web_actions.test.jac` said `W2001 unknown name 'create_bookmark'` until the names were wired in, and then bare `neojac check` said `E1146` for `BookmarkDraft` and `create_bookmark`. The same workaround (`glob __all__` with a `WORKAROUND(GAP-028)` comment in `web_actions.jac`) cleared it.

## Repro
```sh
neojac --version
# scratch project: jac.toml `[project] name = "t"`; files below
```
`archwire.jac`:
```jac
graph layers { layer all { *; } }
graph spaces { space api: native { a; b; c; } app api { run api; } }
graph import { a ++> b { make } }
```
`a.jac` has `node N { has v: int; }` and `def make(v: int) -> N { return N(v=v); }`; `b.jac` has `def twice(n: int) -> int { return n * 2; }`; `c.jac` has `def one -> int { return 1; }`; `b.test.jac`: `test "t" { assert make(1).v == 1; }`.
```sh
neojac check b.jac    # quiet
neojac check c.jac    # quiet
neojac check          # 2 x E1146 ('make' wired into 'b')
neojac check api      # 2 x E1146
neojac test           # b.jac: 1 passed
```
Without the `graph spaces` block, `neojac check b.jac`, `a.jac` and `c.jac` are all quiet (the bare form needs a main.jac there, E5152).

## Expected
`neojac docs E1146` lists where a name counts as used: "in code, in a type annotation, in one of the module's `impl` files, or listed in the module's `__all__`". A test annex is not listed. `neojac docs language/modules-wiring`, "What a command judges", says every command judges the archwire whole and "What the program at hand loads makes no difference". The `starting-a-project` skill says a test annex "sees the module's names without importing them", so the annex's use of a wired name is expected to work, as `check b.jac` and `test` treat it. The commands disagree on whether it counts.

## Workaround
In `app/search.jac` the names only its test annex uses are listed in `__all__`, which `neojac docs language/modules-wiring` says counts as use. Marked `WORKAROUND(GAP-028)`; this makes them part of `search`'s public surface, which they should not be.

## Cause
Unknown.
