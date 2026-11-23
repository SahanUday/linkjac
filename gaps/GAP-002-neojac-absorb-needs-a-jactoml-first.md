---
id: GAP-002
title: neojac absorb needs a jac.toml first; the packages page does not say so
kind: limitation
severity: nit
status: open
area: docs
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac absorb --tree web
code: 
---

## Symptom
In a directory with a package.json and no jac.toml, `neojac absorb` stops with `no jac.toml in that directory or above, for the manifest to go into`. The section "Taking in a manifest you already have" in `toolchain/packages` shows the command without that step.

## Repro
```sh
neojac --version
mkdir t && cd t
printf '{"name":"x","version":"1.0.0"}' > package.json
neojac absorb --tree web   # error: no jac.toml in that directory or above
printf '[project]\nname = "x"\n' > jac.toml
neojac absorb --tree web   # works
```

## Expected
Documented only by implication. `neojac docs reference/commands`, section `neojac absorb`, says absorb takes a manifest "into jac.toml" and, for crates, "into the jac.toml of the project each is in"; `neojac docs toolchain/packages`, "Taking in a manifest you already have", says "The manifest becomes `[npm.<tree>]`". Both presuppose a project with a `jac.toml`. No page says one must exist first, nor that absorb will not create it, so it is a limitation the page leaves unstated rather than one it lists.

## Workaround
Wrote a two-line jac.toml in the scratch copy, then ran absorb.

## Cause
Unknown.
