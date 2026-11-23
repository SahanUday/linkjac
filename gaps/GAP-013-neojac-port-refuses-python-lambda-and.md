---
id: GAP-013
title: neojac port refuses Python lambda and functions defined inside functions
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check lambda_fn.py
code: E4001
---

## Symptom
`lambda s: s.lower()` raises `port does not translate Python's `lambda` yet`; a `def` inside a `def` raises `a Python function inside a function`. 25 lambdas (18 in tests, 7 in `views/contexts.py`) and 15 nested functions (mostly `views/reload.py`, `services/website_loader.py`, `services/http_client.py`, `middlewares.py`) in linkding's `bookmarks/`.

## Repro
```sh
neojac --version
neojac port --check py/lambda_fn.py
neojac port --check py/nested_def.py
```

`py/lambda_fn.py`:

```python
def keyed(items: list[str]) -> list[str]:
    return sorted(items, key=lambda s: s.lower())
```

`py/nested_def.py`:

```python
def outer(n: int) -> int:
    def inner(x: int) -> int:
        return x + 1
    return inner(n)
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in `views/contexts.py`, `views/reload.py` and the loaders, so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
