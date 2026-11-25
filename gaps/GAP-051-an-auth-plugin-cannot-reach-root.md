---
id: GAP-051
title: An auth plugin cannot reach root or the project's store, so the accounts and tokens it keeps need persistence of their own
kind: limitation
severity: major
status: worked-around
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: neojac docs apps/plugins
code:
---

## Symptom
An auth plugin has to keep accounts, API tokens and sessions. It cannot hang them off `root` or hand them to the project's `store` plugin: a plugin imports nothing of stdjac and no other abstraction's contract (`neojac docs apps/plugins`, "What a plugin imports"), and what the host gives `Auth.open` is `data_dir()`, `secret()`, `upgraded()`, `windowed()` and `consume_limit()` (`neojac docs apps/stdjac-server`, "What a plugin conforms to"). So its data needs a persistence layer of its own, which CLAUDE.md rule 6 of this project asks to avoid; the standard `accounts` plugin likewise keeps `accounts.db` (GAP-027).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
neojac docs apps/plugins              # "What a plugin imports": the Host table
neojac docs apps/stdjac-server        # "What a plugin conforms to": AuthHost
neojac docs apps/data                 # "Where it is kept"
```

## Expected
Documented, so a limitation: a way for a plugin to keep records through the project's store (or the graph), so accounts are backed up, moved and shared between instances with the rest of the data.

## Workaround
`plugins/linkauth/ledger.jac` keeps users, tokens and sessions in one JSON file in the app's data directory (or the `path` setting), rewritten whole and swapped in with `os.replace` under a lock; no SQL (`WORKAROUND(GAP-051)`). Not covered: several server instances on one file, and the cost of rewriting it with many accounts.

## Cause
Unknown.
