---
id: GAP-035
title: allroots() is empty in a neojac test run, so code that reads every caller's data cannot be tested there
kind: limitation
severity: minor
status: open
area: test
milestone: M2
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
In a `neojac test` run, a test that connects a node to `root` finds it by `[root --> [?:N]]`, but `len(allroots())` is not 1 (the assertion `count_roots() == 1` fails; the actual value was not printed). So code that reads every caller's data (linkding's `/api/bookmarks/shared/` lists the shared bookmarks of all users who share) cannot be tested with `neojac test`; it runs only in a served app, where, for M2, no endpoint can turn sharing on (linkding's API has no profile update), so the enabled path is unrun.

## Repro
```sh
neojac --version
# scratch project: jac.toml `[project] name = "t"`; archwire.jac `graph layers { layer all { *; } }`
# m.jac:      import from stdjac { allroots }
#             node N { has v: int; }
#             def count_roots -> int;
# impl/m.impl.jac:  impl count_roots -> int { return len(allroots()); }
# m.test.jac: test "root has a node and allroots sees it" {
#                 root ++> N(v=1);
#                 assert len([root --> [?:N]]) == 1;
#                 assert count_roots() == 1;
#             }
neojac test     # 0 passed, 1 failed: the last assertion
```

## Expected
`neojac docs apps/stdjac`, section "The kept graph", says of `allroots`, `remove` and the others: "They work in any program; in one that keeps no graph, they see the program's own", and its example prints `len(allroots())` as 0 after `root ++> n`. So documented, as a limitation: a test run keeps no graph (GAP-025), and `allroots()` lists none. The docs do not say that a node under `root` is not counted.

## Workaround
None. `rest.jac` has a test only for the disabled case (the shared list is empty while no one shares); the enabled case is unrun. M4 (a profile page) or a test-only endpoint can run it in a served app.

## Cause
Unknown.
