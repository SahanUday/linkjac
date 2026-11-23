---
id: GAP-029
title: A served app rejects a node holding a time-zone-aware datetime: every later call fails with 'expected exactly the class its type names, got a timezone'
kind: bug
severity: major
status: worked-around
area: store
milestone: M1
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
In a served app, an endpoint that connects a node whose field is a `datetime` holding `datetime.now(timezone.utc)` answers `{"ok": false, "kind": "rejected", "detail": "add: expected exactly the class its type names, got a timezone"}`. Every later call of every endpoint of that process answers the same, even `count`, which touches no time (the bad node stays in memory; this is from the run, the cause is not known). `neojac test` of the same code passes, since a test run keeps nothing (GAP-025). A naive `datetime.utcnow()` in the same field works, is kept, and reads back with its microseconds after a restart. linkding keeps aware datetimes (`date_added`, `date_modified`).

## Repro
```sh
neojac --version
# scratch project: jac.toml with `[project] name = "t"`
```
`archwire.jac`:
```jac
graph layers { layer all { *; } }
graph spaces { space api: native { m; } app api { run api; } }
```
`m.jac`:
```jac
import from datetime { datetime, timezone }
node N { has at: datetime; }
def:pub add -> str { root.shared ++> N(at=datetime.now(timezone.utc)); return "added"; }
def:pub count -> int { return len([root.shared --> [?:N]]); }
```
```sh
neojac fmt --fix .
neojac build api
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8302 dist/api-linux-x86_64 &
curl -s -X POST http://127.0.0.1:8302/__jac/call/api/m/add -d '{"args":{}}'     # rejected ... got a timezone
curl -s -X POST http://127.0.0.1:8302/__jac/call/api/m/count -d '{"args":{}}'   # rejected, same text
kill %1
```
With `datetime.now()` or `datetime.utcnow()` in place of `datetime.now(timezone.utc)` both calls succeed.

## Expected
`neojac docs library/datetime` shows aware datetimes as ordinary values (`datetime(..., tzinfo=timezone.utc)`), and `neojac docs apps/data` says a node comes with its fields and is written when the endpoint returns, with no list of field types that cannot be kept. A `datetime` field should be kept whether or not it has a `tzinfo`, or the docs should say it cannot.

## Workaround
All timestamps are naive UTC, made in one place, `app/clock.jac` (`now_utc`), with `WORKAROUND(GAP-029)`. The REST layer in M2 must write them with a `Z` as linkding does.

## Cause
Unknown.
