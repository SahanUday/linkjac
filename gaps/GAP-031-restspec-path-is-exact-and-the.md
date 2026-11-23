---
id: GAP-031
title: restspec path is exact and the function takes no parameters: /api/tags/5/ cannot be served
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
A `@restspec` path matches only itself, and the function takes no parameters, so there is no way to serve `/api/tags/<id>/` or `/api/bookmarks/<id>/`. `GET /api/tags/5/` and `GET /api/tags` (no trailing slash) both answer `404 not found`, though `/api/tags/` is served.

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
curl -s -i http://127.0.0.1:8311/api/tags/5/ | sed -n 1p   # 404
curl -s -i http://127.0.0.1:8311/api/tags | sed -n 1p     # 404
kill %1
```

## Expected
`neojac docs apps/server`, same section: `path` is "Absolute: one that does not start with `/` does not compile"; "The function takes no parameters." Nothing there or in `neojac docs apps/stdjac-server` mentions a pattern or a path parameter. (`neojac docs apps/pages` has `*name` route parameters for pages, not for `@restspec`.) Documented as it is; linkding needs ids in the path.

## Workaround
None yet. Searched `neojac docs search "path parameter"`: nothing for `@restspec`.

## Cause
Unknown.
