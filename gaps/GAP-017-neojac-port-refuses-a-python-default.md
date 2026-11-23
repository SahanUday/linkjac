---
id: GAP-017
title: neojac port refuses a Python default value that is not a constant
kind: limitation
severity: nit
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check mutable_default.py
code: E4005
---

## Symptom
`seen: list[int] = []` raises `port writes no Jac yet that keeps the meaning of a default value that is not a constant: Python makes it once, when the function is defined, and Jac at each call that leaves it out`. 17 in linkding's `bookmarks/`.

## Repro
```sh
neojac --version
neojac port --check py/mutable_default.py
```

`py/mutable_default.py`:

```python
def add(x: int, seen: list[int] = []) -> list[int]:
    seen.append(x)
    return seen
```

## Expected
Documented. `neojac docs interop/port-python`, section "What is refused", lists: "**A default value that is not a constant.**", and `neojac docs E4005` explains the code (the default-value example there is the one in GAP-017). It is a stated limitation of the port, not a defect; recorded because linkding hits it (17 sites in `bookmarks/`).

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
