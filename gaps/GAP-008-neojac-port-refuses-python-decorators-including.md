---
id: GAP-008
title: neojac port refuses Python decorators, including @property and @staticmethod
kind: limitation
severity: minor
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check decorator.py
code: E4001
---

## Symptom
A method decorated with `@property` raises `port does not translate a Python decorator yet`. `@staticmethod` raises that and `port does not translate a Python method whose first parameter is not `self` yet`. Class decorators raise their own E4001. 220 decorators, 20 non-self methods and 15 class decorators in linkding's `bookmarks/` (118 in tests; 102 elsewhere, most in `models.py` 19, `templatetags/shared.py` 13, `services/tasks.py` 13, `views/contexts.py` 9).

## Repro
```sh
neojac --version
neojac port --check py/decorator.py
neojac port --check py/static_method.py
```

`py/decorator.py`:

```python
class Box:
    def __init__(self, n: int):
        self.n = n

    @property
    def double(self) -> int:
        return self.n * 2
```

`py/static_method.py`:

```python
class Util:
    @staticmethod
    def one() -> int:
        return 1
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in `models.py`, template tags, services and views, so the port tool cannot take those files; that is what this gap records.

## Workaround
None needed in M0. The affected units are written by hand in Jac in later milestones; each use will carry `WORKAROUND(GAP-nnn)` if this construct had to be rewritten.

## Cause
Unknown.
