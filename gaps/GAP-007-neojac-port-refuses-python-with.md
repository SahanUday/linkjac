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
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in asset handling, `queries.py` and the full-backup command, so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
