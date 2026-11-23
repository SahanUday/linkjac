---
id: GAP-004
title: neojac port --check printed a TypeScript fetch line the port docs do not mention
kind: docs
severity: nit
status: open
area: port
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac port --check bookmarks
code: 
---

## Symptom
The first `neojac port --check bookmarks` over the linkding copy printed `neojac: fetching TypeScript 6.0.3, which reads JavaScript's types` before any result. Later runs did not print it. `neojac docs toolchain/port` and `neojac help port` say `--check` writes nothing and do not mention a download.

## Repro
```sh
neojac --version
cd <copy of linkding>
neojac port --check bookmarks 2>&1 | head -2   # first run only, as far as seen
```

## Expected
`neojac docs toolchain/port` or `neojac docs interop/port-javascript` says that porting JavaScript needs a one-time download and where it is kept.

## Workaround
None.

## Cause
Guess: the TypeScript compiler is downloaded on first use and cached; not confirmed. It was not re-tested with the cache cleared.
