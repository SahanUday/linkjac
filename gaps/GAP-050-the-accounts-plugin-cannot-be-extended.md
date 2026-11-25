---
id: GAP-050
title: The accounts plugin cannot be extended or wrapped: changing one thing about sign-in means writing a whole auth plugin
kind: limitation
severity: major
status: worked-around
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: neojac docs apps/plugins
code:
---

## Symptom
linkding needs two changes to sign-in: take `Authorization: Token <key>` as well as `Bearer` (GAP-034) and offer no sign-up (GAP-046). The standard `accounts` plugin has settings for neither, and nothing lets a project change one method of it and keep the rest: a plugin may import only its abstraction's contract, `common.contract`, its own declared libraries and the standard library, and never another plugin (`neojac docs apps/plugins`, "What a plugin imports": E2233, E2218). So the project writes a whole `Auth` plugin: password hashing, sessions, the sign-in form's description and the account storage, which `accounts` already has.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
neojac docs apps/plugins              # "Writing a plugin", "What a plugin imports"
neojac docs apps/server               # "The accounts plugin": its settings
neojac docs auth.contract             # the Auth interface: open, caller, asks, answer, leave
```

## Expected
Documented, so a limitation: a way to extend or wrap a standard plugin (or settings on `accounts` for accepted keywords and closed registration). `neojac docs search "auth plugin"` found no page that does so.

## Workaround
`plugins/linkauth`, an auth plugin of the project's own (`WORKAROUND(GAP-050)`). Not used from `accounts`: its limits on sign-in attempts (linkding has none).

## Cause
Unknown.
