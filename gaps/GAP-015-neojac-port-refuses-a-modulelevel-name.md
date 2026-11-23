---
id: GAP-015
title: neojac port refuses a module-level name that code binds and functions use
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check global_bound_by_code.py
code: E4005
---

## Symptom
`HOME = os.environ.get(...)` used by a function raises `port writes no Jac yet that keeps the meaning of the module-level name 'HOME', which functions use: a Jac global has its value from the start, and this one is bound by the module's code`. 44 module-level names (plus 2 top-level variables in JavaScript) in linkding's `bookmarks/`. The help line suggests binding it to a literal or passing it to the functions.

## Repro
```sh
neojac --version
neojac port --check py/global_bound_by_code.py
```

`py/global_bound_by_code.py`:

```python
import os

HOME = os.environ.get("HOME", "/")

def where() -> str:
    return HOME
```

## Expected
Documented. `neojac docs interop/port-python`, section "What is refused", lists: "**A module-level name that functions use, bound by anything but a literal before the module's code.**", and `neojac docs E4005` explains the code (the default-value example there is the one in GAP-017). It is a stated limitation of the port, not a defect; recorded because linkding hits it (44 module-level names in `bookmarks/`).

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
