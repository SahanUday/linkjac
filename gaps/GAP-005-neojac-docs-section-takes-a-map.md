---
id: GAP-005
title: neojac docs section takes a map section, so one heading of a page cannot be printed
kind: ergonomics
severity: nit
status: open
area: cli
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac docs section
code: 
---

## Symptom
`neojac docs section "Taking in a manifest you already have"` says `there is no section`. That heading is a heading inside `toolchain/packages`. `neojac help docs` says `docs section <heading>` prints a section's pages. The project instructions suggest using it to avoid reading whole pages.

## Repro
```sh
neojac --version
neojac docs section "Taking in a manifest you already have"
neojac docs toolchain/packages | grep -n '^## '   # the heading exists in the page
```

## Expected
A way to print one heading of a page, or the help saying `section` is only for the sections of the map.

## Workaround
Printed the page and cut the lines with `sed -n`.

## Cause
Unknown.
