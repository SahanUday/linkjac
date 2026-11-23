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
Documented by omission. `neojac docs interop/port-python`, section "What is refused": "Anything not in the table is refused with E4001, and nothing is written for the file". The Python mapping table in that page has no row for `lambda` or a function inside a function, and `neojac docs E4001` says the same. The page does not name this construct. linkding uses it in `views/contexts.py`, `views/reload.py` and the loaders; those files cannot be ported.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
