---
id: GAP-014
title: neojac port refuses Python bytes literals and del
kind: limitation
severity: nit
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check bytes_lit.py
code: E4001
---

## Symptom
`MAGIC = b"abc"` raises `port does not translate a Python bytes literal yet`; `del d["x"]` raises `Python's `del``. 31 bytes literals (all in tests) and 3 `del` in linkding's `bookmarks/`.

## Repro
```sh
neojac --version
neojac port --check py/bytes_lit.py
neojac port --check py/del_stmt.py
```

`py/bytes_lit.py`:

```python
MAGIC = b"abc"
```

`py/del_stmt.py`:

```python
def drop(d: dict[str, int]) -> None:
    del d["x"]
```

## Expected
Documented by omission. `neojac docs interop/port-python`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The Python mapping table in that page has no row for bytes literals or `del`, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in tests only (bytes literals); those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
