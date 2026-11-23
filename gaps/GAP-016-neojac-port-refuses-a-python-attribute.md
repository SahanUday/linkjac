---
id: GAP-016
title: neojac port refuses a Python attribute that __init__ does not always bind
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check init_partial.py
code: E4005
---

## Symptom
`self.n` bound only under `if` in `__init__` raises `port writes no Jac yet that keeps the meaning of the attribute 'n', which `__init__` does not always bind: a Jac object has exactly the fields its class declares`. 93 in linkding's `bookmarks/`.

## Repro
```sh
neojac --version
neojac port --check py/init_partial.py
```

`py/init_partial.py`:

```python
class Counter:
    def __init__(self, start: int):
        if start > 0:
            self.n = start

    def get(self) -> int:
        return self.n
```

## Expected
`neojac docs E4005`. Documented; recorded because 93 sites hit it.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
