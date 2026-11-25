---
id: GAP-059
title: An auth plugin is not told which endpoint is asked for, so it cannot limit an API token to the API
kind: limitation
severity: major
status: open
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: curl -X POST /__jac/call/api/admin/export_bookmarks -H "Authorization: Token <API key>"
code:
---

## Symptom
In linkding an API token opens the REST API only; the web pages and their actions need a signed-in session. In the port an API token is accepted by every `:protect` endpoint: run 2026-11-26, a key made with `create_token` sent to `/__jac/call/api/admin/export_bookmarks` answered 200 with the account's export. `Auth.caller(headers)` is given the request's headers and nothing about what is asked for, so the plugin cannot accept a key for some endpoints and refuse it for others.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
neojac docs apps/stdjac-server        # "What a plugin conforms to": caller(headers: dict[str, str]) -> str | None
# in app/: neojac build api; start dist/api-linux-x86_64/api with LD_SUPERUSER_NAME=probe LD_SUPERUSER_PASSWORD=probe-pass
#          JAC_API_DATA=<empty dir> JAC_API_LISTEN=127.0.0.1:8011
KEY=$(curl -s -X POST http://127.0.0.1:8011/__jac/auth/create_token -d '{"username":"probe","password":"probe-pass"}' | sed -n 's/.*"token": *"\([0-9a-f]*\)".*/\1/p')
curl -s -X POST http://127.0.0.1:8011/__jac/call/api/admin/export_bookmarks -H "Authorization: Token $KEY" -d '{"args":{}}'
```

## Expected
The docs promise no more than `caller(headers)`, so a limitation: the plugin (or the endpoint) should be able to tell kinds of credential apart, for example by being given the endpoint, or by an endpoint asking which kind signed its caller in.

## Workaround
None. The command-line app and the parity runner use an API token on `:protect` endpoints today. Not tried: the transport refusing `Token` outside `/api/` (it cannot tell a key from a session under `Bearer`).

## Cause
Unknown.
