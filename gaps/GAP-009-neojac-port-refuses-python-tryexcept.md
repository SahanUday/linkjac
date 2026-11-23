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
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in background tasks, access checks and the HTTP client, so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
