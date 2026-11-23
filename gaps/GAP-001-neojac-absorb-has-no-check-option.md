---
id: GAP-001
title: neojac absorb has no --check option, though the port-unit skill says it does
kind: docs
severity: nit
status: open
area: skills
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac absorb --check
code: 
---

## Symptom
`.claude/skills/port-unit/SKILL.md` step 3 says to run `neojac absorb --check` once per language tree. `neojac absorb --check` refuses the option.

## Repro
```sh
neojac --version
neojac absorb --check      # in any directory
neojac help absorb         # lists only [<directory>] [--tree <tree>]
```

## Expected
The skill and the command agree. `neojac docs reference/commands` and `neojac help absorb` list no `--check` for `absorb`; the error message says `docs`, `fmt` and `port` have it.

## Workaround
Ran `neojac absorb --tree linkding-web` on a copy in `~/.claude-scratch/linkjac/linkding-absorb/` instead, which really moves files there. No `--check` was run for `absorb`.

## Cause
Unknown.
