---
id: GAP-026
title: language/tests does not say that every test of a module shares one root
kind: docs
severity: nit
status: worked-around
area: docs
milestone: M1
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
Two tests of one module: the first makes a node under `root`, the second asserts `root` has none, and the second fails. Every test of a module shares one `root` (and so sees what earlier tests made).

## Repro
```sh
neojac --version
# scratch project with m.jac:
#   node N { has v: int; }
#   test "first"  { root ++> N(v=1); assert len([root --> [?:N]]) == 1; }
#   test "second" { assert len([root --> [?:N]]) == 0; }
neojac test     # 1 passed, 1 failed: second
```

## Expected
`neojac docs language/tests`, section "What a test is" (after the annex rules): "each test in the order it is written, in one process. A global one test changes is changed for the tests after it". `neojac docs toolchain/test` says the same of source order. Neither names `root`, and `neojac docs root` does not mention tests (searched "test root", "tests share root"). The docs are silent on `root` in tests; kind stays docs.

## Workaround
Tests count relative to what exists (`before = len(...)`) or use names unique to the test. Marked `WORKAROUND(GAP-026)` in `app/bookmarks.test.jac` and `app/search.test.jac`.

## Cause
Unknown.
