---
id: GAP-006
title: neojac port refuses 197 of 251 linkding sources, including models, queries, API routes and serializers
kind: limitation
severity: major
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check bookmarks
code: E4001
---

## Symptom
On a copy of linkding's `bookmarks/` (251 .py and .js files outside `static/`), `neojac port --check bookmarks` ended with `197 sources refused, nothing written for them`: 1496 E4001 and 394 E4005 diagnostics. The 54 files that raise no error are mostly `__init__.py` files and small modules (`services/bundles.py`, `services/exporter.py`, `services/wayback.py`, `tasks.py`, `urls.py`, `settings/base.py`). `models.py` (571 lines, 204 errors), `queries.py`, `api/routes.py`, `api/serializers.py` and the rest of the data and API code are refused whole. A file ports whole or not at all, so no part of a refused file is written. Output was saved in `~/.claude-scratch/linkjac/port-check-bookmarks.log`.

## Repro
```sh
neojac --version
cd ~/.claude-scratch/linkjac/linkding-m0   # copy of reference/linkding at 27b7303
neojac port --check bookmarks > ../port-check-bookmarks.log 2>&1
tail -3 ../port-check-bookmarks.log
grep -E 'error\[' ../port-check-bookmarks.log | sed -E 's/^[^ ]+ //' | sort | uniq -c | sort -rn | head
```

## Expected
`neojac docs toolchain/port` says port refuses a file whole when one construct is outside the core, so this is documented behaviour. It means `neojac port` cannot give raw material for the data and API units; the per-construct gaps below say what blocks each.

## Workaround
The port-unit step "port what it can" gives nothing for models, queries or the API. Those units are designed by hand in Jac in M1 and M2.

## Cause
Unknown.
