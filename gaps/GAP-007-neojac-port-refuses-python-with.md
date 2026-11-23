---
id: GAP-007
title: neojac port refuses Python `with`
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check with_stmt.py
code: E4001
---

## Symptom
`with open(path) as f:` raises `port does not translate Python's `with` yet`. 229 uses in linkding's `bookmarks/` (208 in tests; 21 elsewhere, in `services/assets.py`, `views/reload.py`, `queries.py`, `management/commands/full_backup.py`).

## Repro
```sh
neojac --version
neojac port --check py/with_stmt.py
```

`py/with_stmt.py`:

```python
def read(path: str) -> str:
    with open(path) as f:
        return f.read()
```

## Expected
Documented by omission. `neojac docs interop/port-python`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The Python mapping table in that page has no row for `with`, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in asset handling, `queries.py` and the full-backup command; those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
