---
id: GAP-011
title: neojac port refuses a Python class body that holds assignments (Django models, Meta classes)
kind: limitation
severity: major
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check models_like.py
code: E4001
---

## Symptom
`name = models.CharField(max_length=64)` in a class body raises `port does not translate a class's own attribute (Python's Assign) yet`; `limit: int = 5` raises the same with `(Python's AnnAssign)`. 397 Assign and 48 AnnAssign in linkding's `bookmarks/`. Every Django model field is one of these, so `models.py` cannot be ported. The message also names Python's internal node names (`Assign`, `AnnAssign`), which are not terms in the Python mapping page.

## Repro
```sh
neojac --version
neojac port --check py/class_attrs.py
neojac port --check py/models_like.py
```

`py/class_attrs.py`:

```python
class Meta:
    ordering = "name"
    limit: int = 5
```

`py/models_like.py`:

```python
from django.db import models

class Tag(models.Model):
    name = models.CharField(max_length=64)
```

## Expected
`neojac docs toolchain/port` says port "translates a core of each language ... and refuses the rest", and `neojac docs E4001` says the mapping page (`neojac port --mapping python`) lists what is translated. linkding uses this construct in `models.py` (140 diagnostics), `admin.py` (36), `views/contexts.py` (32) and `forms.py` (29), so the port tool cannot take those files; that is what this gap records.

## Workaround
None for the port. The data model is designed by hand with `root` and `store` in M1.

## Cause
Unknown.
