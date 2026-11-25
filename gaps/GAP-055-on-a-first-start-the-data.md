---
id: GAP-055
title: On a first start the data directory does not exist when a plugin's open() is called, and the docs do not say so
kind: docs
severity: nit
status: worked-around
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: dist/api-linux-x86_64 (first start, empty data directory)
code:
---

## Symptom
An auth plugin that opens a file in `host.data_dir()` inside `open()` fails on a first start, because the directory is not there yet: with `JAC_API_DATA` naming a new directory the program stopped with `OperationalError: unable to open database file` raised from the plugin's `open`. Creating the directory in the plugin (`os.makedirs(host.data_dir(), exist_ok=True)`) fixed it.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# The spike project used below (kept in session scratch while it was run): a plugin package `linkauth` (`jac.toml` with `[plugin]` `fills = "auth"`, `interface_ver = 1`, `class = "linkauth.keyring.LinkAuth"`; one module, `obj LinkAuth(Auth)` with `open`, `caller`, `asks`, `answer`, `leave`) beside an app that declares it in `[packages]` and `[auth] plugin = "linkauth"`, with one `def:protect add_mine` and one `def:pub open_one`.
# open(): db = sqlite3.connect(os.path.join(host.data_dir(), "linkauth.db"))
neojac build api && JAC_API_DATA=$(mktemp -d)/new JAC_API_LISTEN=127.0.0.1:8312 dist/api-linux-x86_64
```

## Expected
`neojac docs apps/plugins` says `data_dir()` is "where the program keeps files beside itself" and `open` is "where a store reaches its file"; neither says the plugin must create it. Not tried: the same with a default data directory.

## Workaround
`plugins/linkauth` creates the directory before it writes (`WORKAROUND(GAP-055)`).

## Cause
Unknown.
