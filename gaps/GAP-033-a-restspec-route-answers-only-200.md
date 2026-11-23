---
id: GAP-033
title: A restspec route answers only 200 or 500: no way to answer 201, 204, 400 or 404 from the function
kind: limitation
severity: major
status: open
area: transport
milestone: M2
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
A `@restspec` route answers `200` when the function returns and `500` when it raises (`{"ok": false, "kind": "failed", "detail": "boom failed"}`). There is no way to answer `201` for a create, `204` for a delete, `400` for a bad body or `404` for an unknown id, which the parity checks compare. Unauthenticated calls to a `:protect` route are 401 with the body `{"ok": false, "kind": "rejected", "detail": "This needs a signed-in caller."}`; linkding's 401 body is `{"detail": "..."}`.

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
curl -s -i -X POST http://127.0.0.1:8311/api/tags/ | sed -n 1p        # 200
# with `def:pub boom -> str { raise ValueError("nope"); }` at GET /api/boom/:
curl -s -i http://127.0.0.1:8311/api/boom/ | sed -n 1p            # 500, body says "boom failed"
kill %1
```

## Expected
`neojac docs apps/server`, "Replies", status table: 200 "The call returned", 500 "The endpoint raised"; "A function that returns nothing answers ...". `@restspec` is not said to differ. Documented as it is; the parity checks need 201, 204, 400, 404.

## Workaround
None yet.

## Cause
Unknown.
