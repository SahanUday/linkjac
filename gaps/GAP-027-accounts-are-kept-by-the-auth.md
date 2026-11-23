---
id: GAP-027
title: Accounts are kept by the auth plugin in accounts.db, not under root, so users cannot be stored through root
kind: limitation
severity: minor
status: open
area: auth
milestone: M1
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
linkding's users (login, password, token, is_staff) have no home under `root`: `neojac docs apps/data`, table "Where it is kept", puts accounts and sessions in `accounts.db`, written by the `auth` plugin (`accounts`, the standard one). Only data the program hangs off a caller's `root` goes through `root` and `store`. So M1's "users stored through `root`" can only hold what linkding keeps beside the account, for example a `UserProfile` node. Run in M2 (see GAP-034): a `:protect` endpoint gets the caller's own `root` (only one account was used in the runs, so that two accounts' data stay apart is not shown), but no function reads the caller's username: searched `neojac docs search "caller username"`, nothing. So a root cannot be turned into a user name, which linkding's `shared` list (`?user=`) needs.

## Repro
```sh
neojac --version
neojac docs apps/data | sed -n '/## Where it is kept/,/^They are/p'
```

## Expected
Documented, so kind is limitation: `neojac docs apps/data`, "Where it is kept": `accounts.db` holds "Accounts and sessions", beside `graph.db`. `neojac docs apps/server`, "The accounts plugin": "keeps accounts of a username and a password"; it lists a username, an email and a password, and no other field. linkding's user model has first and last name, is_staff and is_superuser, which `accounts` has no field for.

## Workaround
None yet. M1 stores a `UserProfile` node under each caller's `root`; M2 runs per-caller roots under the `accounts` plugin; accounts as linkding has them are M6.

## Cause
Unknown.
