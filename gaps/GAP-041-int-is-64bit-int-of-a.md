---
id: GAP-041
title: int is 64-bit: int() of a number past 64 bits raises OverflowError where CPython answers
kind: limitation
severity: nit
status: worked-around
area: other
milestone: M3
found: 2026-11-23
neojac: 0.4.0
command: neojac run main.jac
code:
---

## Symptom
`int("99999999999999999999")` in a scratch project raised `OverflowError int too large to fit in 64 bits`. CPython 3 answers `99999999999999999999`. In the port, `read_epoch` in `app/impl/clock.impl.jac` catches the error, so a huge `ADD_DATE` in a Netscape file is read as no date. What the original does with such a number was not run, so whether the two agree is unknown.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# scratch project: jac.toml with [project] name and archwire = false, and [check.lint] ignore as the repo requires
# main.jac:  with entry { try { print(int("99999999999999999999")); } except OverflowError as e { print("OverflowError", e); } }
neojac run main.jac                   # OverflowError int too large to fit in 64 bits
python3 -c 'print(int("99999999999999999999"))'   # 99999999999999999999
```

## Expected
Documented, so a limitation and not a bug: `neojac docs language/numbers` ("The types"): "`int` | A signed 64-bit integer, -2**63 to 2**63 - 1"; the porting-from-python skill lists "`int` raises `OverflowError` past 64 bits" among meanings that differ with no error. `i128`/`u128` exist for larger values (`neojac docs language/numbers-128`), but `int(text)` of a string gives `int`.

## Workaround
`read_epoch` catches `OverflowError` (a comment there says why). No marker was added when it was written; this gap is its record.

## Cause
Unknown. The docs state the range; nothing was found that says why `int` is not unbounded.
