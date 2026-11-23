---
id: GAP-010
title: neojac port refuses Python super()
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check super_call.py
code: E4001
---

## Symptom
`super().__init__(n)` raises `port does not translate Python's `super()` yet`. 52 uses in linkding's `bookmarks/`, 41 outside tests (`forms.py` 8, `widgets.py` 7, `models.py` 6, `admin.py` 6).

## Repro
```sh
neojac --version
neojac port --check py/super_call.py
```

`py/super_call.py`:

```python
class A:
    def __init__(self, n: int):
        self.n = n

class B(A):
    def __init__(self, n: int):
        super().__init__(n)
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in forms, widgets, models and the admin, so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
