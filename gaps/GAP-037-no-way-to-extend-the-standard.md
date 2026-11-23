---
id: GAP-037
title: No way to extend the standard http transport: adding REST routing meant writing a whole transport plugin that has none of its streams, limits or keep-alive
kind: gap
severity: major
status: worked-around
area: transport
milestone: M2
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
To serve linkding's `/api/` (methods, ids in paths, query, body, status codes: GAP-030 to GAP-033) the only way found was a `transport` plugin of its own, `plugins/rest_bridge`, which serves HTTP with `http.server` and so replaces everything the standard `http` transport does. What the replacement lacks, by reading `neojac docs apps/server` ("Streams", "What the server will and will not read") and not by testing each: streamed replies (`events`), the interim `100 Continue`, the 16 MiB, 1 MiB head and 512-connection limits and the 60-second request time, `Connection: close` on every reply, and TLS-free `send` between apps (`send` raises `OSError`). Apps that use any of these cannot take this plugin. No hook was found for adding routes to the standard transport or wrapping its `handle`.

## Repro
```sh
neojac --version
neojac docs apps/plugins | sed -n '/Binding a plugin/,/Picking a plugin/p'
neojac docs apps/stdjac-server | grep -n "E2218\|never"     # nothing for plugins importing plugins
sed -n '/Import the abstraction/,/E2218/p' .claude/skills/writing-a-plugin/SKILL.md
```
Not run: whether a plugin can import the standard `http` transport to wrap it. The skill says a plugin imports "the abstraction's contract, `common.contract`, your libraries and the standard library ... never a plugin (E2218)", so it was not tried.

## Expected
`neojac docs apps/server` says a plugin "may replace" the standard ones "without changing a module". Replacing is documented; adding to one is not mentioned. A REST API with verbs, path parameters and status codes is what most HTTP services are, so the docs would be expected to say how it is done.

## Workaround
`plugins/rest_bridge` (see `WORKAROUND(GAP-030)` to `GAP-033` in its `bridge.jac`). M6 should decide whether the bridge stays, or the app moves to what neojac gives by then.

## Cause
Unknown.
