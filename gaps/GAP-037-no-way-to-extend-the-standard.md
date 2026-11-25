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
To serve linkding's `/api/` (methods, ids in paths, query, body, status codes: GAP-030 to GAP-033) the only way found was a `transport` plugin of its own, `plugins/rest_bridge`, which replaces everything the standard `http` transport does.

**What the plugin is.** Jac, not Python: 240 lines of Jac (`bridge.jac` 76, `impl/bridge.impl.jac` 164), plus `archwire.jac` (4) and `jac.toml` (11), 255 in all. Its HTTP server is `http.server`, which neojac ships natively (`neojac docs library/http`), not CPython. It is bound from `app/jac.toml` by path.

**Rule it strains.** Not rule 6 (that is about persistence). It strains the Code style line "Depend on neojac's abstractions, not on concrete plugins" and "No second implementation of anything the program already does": the app names a plugin of ours in `[transport]`, the plugin is configured with the app's endpoint paths (`call_path`), and it duplicates both the standard transport's serving and, in `json_reply`, the app's `reply_json` (a plugin cannot import the app). It does implement the `transport` abstraction as documented, so the abstraction itself is used.

**What it lacks against the standard transport.** Compared with the table in `neojac docs apps/server` ("What the server will and will not read"), and tried against the served app where marked:
- Body limit: **tried.** A 17 MiB body was read in full and answered 400 by the app; the standard transport answers 413 past 16 MiB.
- Chunked body: **tried.** The bridge reads it as an empty body (the app answered 400 "Invalid data"); the standard transport answers 411.
- Keep-alive: **tried, and not a difference.** The bridge answers `HTTP/1.0` and closes after each reply; the docs say the standard transport also closes each reply ("Each reply closes its connection"). An earlier version of this gap listed `Connection: close` as a loss; that was wrong.
- Streams (`events`), the interim `100 Continue` every 15 seconds, the 1 MiB head limit (431), the 512-connection limit, the 60-second request time, the 256 calls at once, the 501 for other transfer encodings: **not tried**, absent from the plugin's code as written (it handles none of them). `http.server`'s own head limits may apply; not measured.
- `send` between apps: the plugin first raised `OSError` ("carries no calls to other apps"), which stopped the CLI app of M3 (GAP-039); it now has a client-side `send` on `http.client`, with no streams, no `100 Continue` handling and none of the standard client's limits, and is tried only by the CLI's import and export.
- **The browser bundle: tried (M4, 2026-11-23), and it is served.** With `[transport] plugin = "rest_bridge"` in `app/jac.toml` and a `browser` space in the app, this plugin, not the standard transport, serves the page shell at `/bookmarks`, `/tags` and the other page routes, the assets under `/assets/`, and the page's calls to the server's `:pub` and `:protect` functions (`call_path` and `public_call_path`). 27 browser checks (`parity/test_ui_*.py`; 26 pass and 1 is an expected gap, GAP-045) run through it on the port, with no change to the plugin since M3. It was not measured whether it matches the standard transport on what a bundle needs beyond serving it: cache headers, the 404 and 403 rules for a path below the bundle, `HEAD`, range requests, content types for fonts and source maps. The page-level behaviour (a missing bookmark answers 200 with the shell, GAP-045) was not compared with the standard transport's either, because the standard transport was not run with these pages.
Apps that use streams or `send` cannot take this plugin.

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

## Severity
Major, not blocker. A blocker means the milestone's work cannot be done at all; M2's `/api/` was done, and parity passes on 64 of 64 checks, through this plugin. It is major and not minor because every HTTP service with verbs, path parameters and status codes has this need, the fix cost a whole transport plugin, and what it does not carry (limits, streams, `send`) is silently absent. Re-rate to blocker if M4's pages or M5's jobs need what the plugin lacks and nothing else carries both.

## Workaround
`plugins/rest_bridge` (see `WORKAROUND(GAP-030)` to `GAP-033` in its `bridge.jac`). M6 should decide whether the bridge stays, or the app moves to what neojac gives by then.

M6 note (2026-11-26), our own faults in the stand-in, run on the served app: a request body that is not UTF-8 and a `Content-Length` that is not a number each close the connection with no reply (`curl` exit 52); the server goes on answering. Not run against linkding.

## Cause
Unknown.
