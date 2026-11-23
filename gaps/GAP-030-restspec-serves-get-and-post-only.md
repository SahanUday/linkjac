---
id: GAP-030
title: restspec serves GET and POST only: PUT, PATCH and DELETE on its path answer 404
kind: limitation
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
On a path served by `@restspec`, a `PUT`, `PATCH` or `DELETE` request is answered `404 not found` as text; only `GET` and `POST` reach the function. linkding's API uses `PUT`, `PATCH` and `DELETE` on bookmarks and tags (the parity checks `test_put_*`, `test_patch_*`, `test_delete_*`).

## Repro
```sh
neojac --version
# scratch project: jac.toml `[project] name = "t"`; archwire.jac:
#   graph layers { layer all { *; } }
#   graph spaces { space api: native { m; } app api { run api; } }
# m.jac:
#   @restspec(method=HTTPMethod.GET, path="/api/tags/", produces="application/json", envelope=False)
#   def:pub tags_list -> str { return "{\"results\":[]}"; }
#   @restspec(method=HTTPMethod.POST, path="/api/tags/", produces="application/json", envelope=False)
#   def:pub tags_create -> str { return "{\"id\":1}"; }
neojac fmt --fix . && neojac build api
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8311 dist/api-linux-x86_64 &
for m in GET POST PUT PATCH DELETE; do curl -s -i -X $m http://127.0.0.1:8311/api/tags/ | sed -n 1p; done
# 200, 200, 404, 404, 404
kill %1
```

## Expected
`neojac docs apps/server`, section "A path of its own: @restspec", table: `method` is "`HTTPMethod.GET` or `HTTPMethod.POST`. A request with another method is 404." So documented, and `neojac docs apps/stdjac-server` lists `HTTPMethod` as `GET`, `POST`. linkding needs five methods.

## Workaround
`plugins/rest_bridge` serves HTTP itself and passes `PUT`, `PATCH` and `DELETE` on (`WORKAROUND(GAP-030)` in `plugins/rest_bridge/bridge.jac`). Cost: a transport plugin of ~200 lines that has to stand in for the standard `http` transport (no streams, no keep-alive, none of its limits: GAP-037).

## Cause
Unknown.
