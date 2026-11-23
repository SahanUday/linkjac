---
id: GAP-003
title: neojac absorb takes package.json but nothing in pyproject.toml or uv.lock
kind: limitation
severity: minor
status: open
area: absorb
milestone: M0
found: 2026-11-23
neojac: 0.4.0
command: neojac absorb --tree linkding-web
code: 
---

## Symptom
linkding has a package.json, a pyproject.toml and a uv.lock. After `neojac absorb` the package.json became `[npm.linkding-web]` and `jac.lock` was written, but pyproject.toml and uv.lock were left untouched and the Python dependencies are not in jac.toml. `neojac help absorb` lists only package.json, Cargo.toml and cmodule.toml. The copy had no node_modules (excluded when copying), so moving node_modules was not exercised.

## Repro
```sh
neojac --version
cp -a <linkding checkout without .venv, node_modules, data> t && cd t
printf '[project]\nname = "linkding-copy"\n' > jac.toml
neojac absorb --tree linkding-web
ls            # pyproject.toml and uv.lock still there
grep -c pypi jac.toml   # 0
```

## Expected
A project with a pyproject.toml has a documented route into jac.toml (`neojac docs toolchain/packages`, `neojac docs using-python-packages` skill). None was found for taking an existing pyproject.toml in.

## Workaround
None. Python dependencies are listed by hand with `neojac install --pypi` when needed in later milestones.

## Cause
Unknown.
