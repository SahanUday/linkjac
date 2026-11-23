---
id: GAP-038
title: neojac test says 'the test runner failed to build' for modules that build and pass in the next run, with no diagnostic
kind: bug
severity: minor
status: open
area: test
milestone: M3
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
Twice, `neojac test` in `app/` (under `capped --mem 4G`) reported modules as not built, with no diagnostic, and the very next run of the same sources passed.
1. After the refactor edits: `32 passed; 8 of 10 modules passed`, `FAILED rest.jac (did not build)`, `FAILED rest_forms.jac (did not build)`. Only the last six lines of output were read, so any message above them is unknown.
2. After adding the Netscape modules and tests, with the full output read: for `netscape_import.jac`, `netscape_parse.jac` and `search.jac` the only text was `<module>.jac: the test runner failed to build`. No error code, file or line. The same run also had two real test failures (`clock.jac`, `netscape_export.jac`), which were printed with a traceback.
Both times the next `neojac test` (and `neojac test netscape_parse.test.jac` alone) passed all those modules, with no source change in between.
Not reproduced in three later tries: a full run after `touch` of every `.jac` and removal of `.jac/cache`, at `--mem 4G` and at `--mem 8G` (13 of 13 modules passed each time).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
cd app
capped --mem 4G -- neojac test        # first run after editing several modules and tests, at least one test failing
```
Could not be made to fail on demand; the repro above is the circumstance, not a recipe.

## Expected
`neojac docs apps/stdjac` and `neojac help test` were not found to say what "failed to build" means for a module. A diagnostic of the kind `neojac check` prints (code, file, line) was expected, or no failure.

## Workaround
Rerun `neojac test`. Nothing in the code.

## Cause
Unknown.
