---
id: GAP-032
title: No documented way for a restspec function to read the query string, the request body or a header
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
A `@restspec` function takes no parameters (`E0109` for one that does), so what the request carried (the query string `?q=&limit=&offset=`, the JSON body of a create or an update, the `Authorization` header) has no documented way in. The docs do not say how a restspec function reads them, and do not say it cannot. Without them a list cannot filter or paginate and a create cannot read the new bookmark.

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
curl -s "http://127.0.0.1:8311/api/tags/?limit=5&offset=1"            # same body as without the query
curl -s -X POST http://127.0.0.1:8311/api/tags/ -d '{"name":"x"}'   # same body: the function has nowhere to read it
kill %1
```

## Expected
`neojac docs apps/server` ("A path of its own: @restspec") and `neojac docs apps/stdjac-server`: both say "one of no parameters" and nothing about reading the request. `neojac docs apps/stdjac` ("Transport") describes a `Request` with `method`, `path`, `query`, `headers`, `body`, but only for a transport plugin, not for a function. Searched `neojac docs search "query string"`, "request body restspec", "request headers": nothing for `@restspec`. Kind is gap (docs silent), not limitation. One more loose end: `neojac docs apps/stdjac`, "What a program imports", row "Crossings", says a program imports "the `Request` a program that answers one itself is given". No page found says how a program answers a request itself, or which function is given the `Request`; searched `neojac docs apps/crossings` and `apps/stdjac` for "request" and "itself".

## Workaround
The bridge reads the query string, body and headers of the request and passes them as arguments of that one endpoint (`WORKAROUND(GAP-032)` in `plugins/rest_bridge/bridge.jac`). Cost: a transport plugin of ~200 lines that has to stand in for the standard `http` transport (no streams, no keep-alive, none of its limits: GAP-037).

## Cause
Unknown.
