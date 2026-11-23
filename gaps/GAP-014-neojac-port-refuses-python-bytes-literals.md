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
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in tests only (bytes literals), so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
