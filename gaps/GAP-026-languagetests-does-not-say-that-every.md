---
id: GAP-026
title: language/tests does not say that every test of a module shares one root
kind: docs
severity: nit
status: open
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
`neojac docs language/tests` says tests run "in one process. A global one test changes is changed for the tests after it". `root` is not named there, and `neojac docs root` does not mention tests. The sentence implies this, so the behaviour is consistent with the docs; they do not say it for `root`.

## Workaround
Tests count relative to what exists (`before = len(...)`) or use names unique to the test.

## Cause
Unknown.
