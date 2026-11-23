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
Documented by omission. `neojac docs interop/port-python`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The Python mapping table in that page has no row for `super()`, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in forms, widgets, models and the admin; those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
