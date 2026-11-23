---
id: GAP-009
title: neojac port refuses Python try/except
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check try_except.py
code: E4001
---

## Symptom
`try: ... except ValueError:` raises `port does not translate Python's `try` yet`. 67 uses in linkding's `bookmarks/`, 66 outside tests (`services/tasks.py`, `views/access.py`, `utils.py`, `services/http_client.py`).

## Repro
```sh
neojac --version
neojac port --check py/try_except.py
```

`py/try_except.py`:

```python
def parse(s: str) -> int:
    try:
        return int(s)
    except ValueError:
        return 0
```

## Expected
Documented by omission. `neojac docs interop/port-python`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The Python mapping table in that page has no row for `try`/`except`, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in background tasks, access checks and the HTTP client; those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
