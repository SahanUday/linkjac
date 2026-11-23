---
id: GAP-012
title: neojac port refuses Python *args, **kwargs and ** spreads
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check varargs.py
code: E4001
---

## Symptom
`def call(*args, **kwargs)` raises `port does not translate Python's `*args`, `**kwargs`, keyword-only and positional-only parameters yet`. `{**a, **b}` raises `a Python `**` item of a dict`. A `**` or `*` argument at a call raises its own E4001. 44 parameter lists, 14 dict items, 20 `**` arguments and 10 `*` arguments in linkding's `bookmarks/`.

## Repro
```sh
neojac --version
neojac port --check py/varargs.py
neojac port --check py/dict_spread.py
```

`py/varargs.py`:

```python
def call(*args, **kwargs):
    return len(args) + len(kwargs)
```

`py/dict_spread.py`:

```python
def merge(a: dict[str, int], b: dict[str, int]) -> dict[str, int]:
    return {**a, **b}
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in linkding's `bookmarks/` (counts above; locations not tallied), so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
