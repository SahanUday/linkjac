---
id: GAP-036
title: A transport plugin must print the 'listening on' line itself: the docs show the line and say the listening callback gets the port, but not that nothing else prints it
kind: docs
severity: nit
status: worked-around
area: transport
milestone: M2
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
An app built with the standard `http` transport prints `listening on http://127.0.0.1:8301/` when it is ready. The same app built with a transport plugin of its own (`plugins/rest_bridge`) that calls `listening(port)` as `neojac docs apps/stdjac` ("Transport", `listen`) describes prints nothing: the server answered 200 on `/__jac/auth/` with an empty log after 4 seconds. `tools/check_persistence.sh` waits for that line and reported "server did not start".

## Repro
```sh
neojac --version
# project with the plugin: plugins/rest_bridge of this repo, bound by app/jac.toml ([packages] and [transport] plugin = "rest_bridge")
cd app && neojac build api
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8302 dist/api-linux-x86_64 > log 2>&1 &
sleep 4; cat log                    # empty
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8302/__jac/auth/    # 200
```
The line is printed with the standard transport (seen in a scratch project, `restspec`, before the plugin was bound).

## Expected
`neojac docs apps/server`, "The shortest server", and `neojac docs skills/building-an-app/SKILL` show the line. `neojac docs apps/stdjac` says `listening` is "told the port it took". No page says who prints the line. Kind is docs.

## Workaround
The plugin prints the line itself after it calls `listening` (`WORKAROUND(GAP-036)` in `plugins/rest_bridge/impl/bridge.impl.jac`). Whether it would then print twice if a later neojac prints it from `listening` is not known.

## Cause
Guess: the standard transport prints it, not the code that calls `listening`.
