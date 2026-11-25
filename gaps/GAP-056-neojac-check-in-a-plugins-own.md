---
id: GAP-056
title: neojac check in a plugin's own directory stops with E5152 'no main.jac', though the plugins page says it checks the plugin
kind: docs
severity: minor
status: open
area: cli
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: neojac check (in plugins/linkauth)
code: E5152
---

## Symptom
`neojac check` run in a plugin package's directory (a `jac.toml` with `kind = "plugin"`, an `archwire.jac` with layers only) exits with `error[E5152]: the Jac project '.' has no main.jac, the program it is`; `neojac check .` says the same. The plugins page says that command is how a plugin is checked on its own. `neojac check a.jac b.jac` is refused too (it takes one program). `neojac test .` in the same directory builds and runs the plugin's tests, and `neojac check` in the app that declares the plugin passes.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
mkdir demo && cd demo
printf '[project]\nname = "demo"\nkind = "plugin"\n\n[plugin]\nfills = "limits"\ninterface_ver = 1\nclass = "demo.m.Demo"\n\n[check.lint]\nignore = ["strip-comments", "strip-docstrings"]\n' > jac.toml
printf 'graph layers { layer limits { m; } }\n' > archwire.jac
printf '"""Demo."""\n\nimport from common.contract { Host }\nimport from limits.contract { Limits }\n\nobj Demo(Limits) {}\n' > m.jac
neojac check
neojac docs apps/plugins | grep -n "plugin's own directory"
```

## Expected
`neojac docs apps/plugins`, "What a plugin imports": "`neojac check` in the plugin's own directory holds it to all of this, with no app around it."

## Workaround
Check a plugin through the app that declares it (`neojac check` in `app/`) and its own tests (`neojac test .` in the plugin). Neither is said to hold the plugin to its wiring on its own (E2233).

## Cause
Unknown.
