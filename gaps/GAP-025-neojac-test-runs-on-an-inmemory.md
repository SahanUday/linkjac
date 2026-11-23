---
id: GAP-025
title: neojac test runs on an in-memory root: a test cannot show that data is kept by the store
kind: limitation
severity: minor
status: open
area: test
milestone: M1
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
`neojac test` ran the `test` blocks of a module that writes nodes under `root`, and no `graph.db` or other store file appeared. The same code served as an app (`neojac build api`, run, restart) kept its bookmark. So `neojac test` shows that the code creates, lists and searches nodes, never that the store keeps them.

## Repro
```sh
neojac --version
# scratch project: jac.toml, archwire.jac with `layer all { *; }`, m.jac:
#   node N { has v: int; }   test "first" { root ++> N(v=1); assert len([root --> [?:N]]) == 1; }
neojac test
find . -name '*.db'        # nothing
```

## Expected
`neojac docs root`, section "A native program: nothing persists": a native program's `root` is new and empty each start with no file behind it; `neojac docs apps/data`: a serving app keeps its graph. The pages are consistent, so this is documented. Recorded because M1's done-when asks for data stored through `root` and the `store` plugin and a test run, and the two cannot be one command.

## Workaround
Domain logic is tested with `neojac test`; that the store keeps data is checked by serving the app, saving through an endpoint, restarting the binary and reading back (done by hand for the M1 spike; to be made a parity check in M2). No code marker: nothing in code works around it.

## Cause
Unknown.
