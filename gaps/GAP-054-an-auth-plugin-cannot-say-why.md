---
id: GAP-054
title: An auth plugin cannot say why it refuses a credential: None gives a fixed message and raising Rejected from caller answers 500
kind: limitation
severity: minor
status: worked-around
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: curl -H 'Authorization: Token boom' (spike below)
code:
---

## Symptom
linkding answers a refused credential with a message that says why (`Invalid token.`, `Invalid token header. No credentials provided.`). `Auth.caller(headers)` can only return a user id or `None`; for `None` a `:protect` endpoint answers 401 `This needs a signed-in caller.` and a `:pub` endpoint runs as for an anonymous caller, bad token or not. Raising `Rejected` from `caller` answers 500 `the server failed to answer` (the server printed `request /__jac/call/api/m/add_mine failed: Invalid token.`).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# The spike project used below (kept in session scratch while it was run): a plugin package `linkauth` (`jac.toml` with `[plugin]` `fills = "auth"`, `interface_ver = 1`, `class = "linkauth.keyring.LinkAuth"`; one module, `obj LinkAuth(Auth)` with `open`, `caller`, `asks`, `answer`, `leave`) beside an app that declares it in `[packages]` and `[auth] plugin = "linkauth"`, with one `def:protect add_mine` and one `def:pub open_one`.
# caller(): raise Rejected(detail="Invalid token.", retry_after=0) when the key is "boom"
neojac build api && JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8312 dist/api-linux-x86_64 &
curl -i -X POST http://127.0.0.1:8312/__jac/call/api/m/add_mine -H 'Authorization: Token boom' -d '{"args":{}}'   # 500
curl -i -X POST http://127.0.0.1:8312/__jac/call/api/m/add_mine -H 'Authorization: Token nope' -d '{"args":{}}'   # 401, "This needs a signed-in caller."
curl -i -X POST http://127.0.0.1:8312/__jac/call/api/m/open_one -H 'Authorization: Token nope' -d '{"args":{}}'   # 200
```

## Expected
`neojac docs apps/stdjac-server` gives `caller` the type `str | None` and `Rejected` to `answer` only; a way for `caller` to refuse with a reason (401 and the text) was expected.

## Workaround
The project's transport (`plugins/rest_bridge`) writes linkding's messages: it answers a malformed `Token` or `Bearer` header itself, sends every request that carries one to the protected endpoint, and turns the 401 into `Invalid token.` (`WORKAROUND(GAP-054)`).

## Cause
Unknown.
