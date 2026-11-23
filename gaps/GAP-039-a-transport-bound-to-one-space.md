---
id: GAP-039
title: A transport bound to one space with [spaces.<space>.transport] does not serve that space: two spaces bound to two plugins end up on one
kind: bug
severity: major
status: worked-around
area: transport
milestone: M3
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
`app/jac.toml` has two spaces, `api` (served, needs the `rest_bridge` transport plugin) and `cli` (a client that calls `api`, which needs a transport that can `send`). `neojac docs apps/plugins` ("Binding a plugin") says `[spaces.<space>.<abstraction>]` binds one space's plugin. Three bindings were built (`neojac build`, no error each time) and run:

| jac.toml | What the built `api` and `cli` programs did |
|---|---|
| A: `[spaces.api.transport] plugin = "rest_bridge"`, `[spaces.api.transport.rest_bridge]` with its settings, `[spaces.cli.transport] plugin = "http"` | `cli` reached the server and imported and exported. `api` was served by the standard transport: `curl -sv /__jac/auth/` showed `HTTP/1.1` (the plugin answers `HTTP/1.0`) and `/api/tags/` answered `not found`. |
| B: as A, with the settings only in `[transport.rest_bridge]` | The same as A. |
| C: `[transport] plugin = "rest_bridge"` for the project and `[spaces.cli.transport] plugin = "http"` | `api` served `/api/` through the plugin; `cli` failed with the plugin's own error: its `send` was used, not the standard transport's. |
So in no binding did each space get its own plugin: the spaces got one transport between them, and which one depended on the binding. The same project with `JAC_TRANSPORT=http dist/cli-linux-x86_64` run against binding C ends with `JAC_TRANSPORT=http: this program was not built with a plugin 'http' for `transport`. jac.toml lists: rest_bridge`.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# project: this repo's app/ with plugins/rest_bridge bound at the project level (binding C), then
# add to app/jac.toml:  [spaces.cli.transport]  plugin = "http"
cd app && neojac build                # builds api and cli
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8322 dist/api-linux-x86_64 &
# register a user, then, with JAC_REMOTE_API=http://127.0.0.1:8322 JAC_REMOTE_TOKEN=<token>:
dist/cli-linux-x86_64 export          # "export failed: rest_bridge carries no calls to other apps"
```
For binding A, replace the project-level `[transport]` by `[spaces.api.transport] plugin = "rest_bridge"` and rebuild; `curl -sv http://127.0.0.1:8322/__jac/auth/` shows `HTTP/1.1`.

## Expected
`neojac docs apps/plugins`: "`[spaces.<space>.<abstraction>]` binds one space's, for an abstraction a space has one of. The spaces one program runs share one `store`, so they are bound alike (E5090 otherwise)." Nothing there says a transport is shared, or that spaces bound to different transports get one. Two apps (`api` and `cli`) each run one space, so each is its own program and was expected to take its own space's binding.

## Workaround
Binding C, and `plugins/rest_bridge` got a client-side `send` (the standard `http` transport's job), so the one plugin carries both the served `/api/` and the CLI's calls (`WORKAROUND(GAP-039)` in `plugins/rest_bridge/impl/bridge.impl.jac`). Before that the plugin's `send` raised `OSError` (GAP-037), which made the CLI fail.

## Cause
Unknown. Guess: a project's `transport` is one choice for all its apps, and a space's binding is only read in some cases.
