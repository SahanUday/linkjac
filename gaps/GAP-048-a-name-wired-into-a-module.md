---
id: GAP-048
title: A name wired into a module only for its test annex is refused by neojac check (E1146) though neojac test builds and passes it
kind: limitation
severity: minor
status: worked-around
area: arch
milestone: M5
found: 2026-11-23
neojac: 0.4.0
command: neojac check
code: E1146
---

## Symptom
A wire in `archwire.jac` (`a ++> b { make }`) whose name `b` uses only in `b.test.jac` (a `def one` that calls `make()`, called from a `test` block) is refused by `neojac check`: `error[E1146]: 'make' is wired into 'b', which never uses it`. `neojac test` in the same project builds `b` with that wire and passes (`b.jac: 1 passed`). Hit in `app/assets.test.jac` (a test wanting `create_bookmark` and `BookmarkDraft` from `bookmarks`): `neojac check` gave the two E1146 errors, and the first full `neojac test` run after it printed `FAILED <module> (did not build)` for 4 to 5 other modules, with no diagnostic. After the wire names were removed, `check` was clean and `neojac test` passed (71 tests, 18 modules).

## Repro
Scratch project (`~/.claude-scratch/<session>/wire`, 5 files), run 2026-11-23:
```sh
neojac --version                     # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# archwire.jac: graph spaces { space api: native { a; b; } app api { run api; } }  graph import { a ++> b { make } }
# a.jac:      def make -> int { return 1; }
# b.jac:      def twice -> int { return 2; }
# b.test.jac: def one -> int { return make(); }   test "x" { assert one() == 1; }
neojac check     # error[E1146]: 'make' is wired into 'b', which never uses it
neojac test      # b.jac: 1 passed
```

## Expected
`neojac docs E1146` (`reference/diagnostics/e11-1`): "Every name a wire binds must be used where it lands: in code, in a type annotation, in one of the module's `impl` files, or listed in the module's `__all__`." A test annex is not in that list, so the refusal follows the page; what was expected is that a module's test file counts as where it lands (a test that needs a name from another module has no other way to get it), or that `neojac test` refuses it too. `neojac docs search "test annex"` and `neojac docs apps/testing` were not read for a rule on names a test needs.

## Workaround
The test builds what it needs from names the module already has (`app/assets.test.jac` makes its bookmarks with `Bookmark(...)`, wired for the module's own use). Not tried: `__all__` (GAP-028 used it for another case).

## Cause
Unknown.
