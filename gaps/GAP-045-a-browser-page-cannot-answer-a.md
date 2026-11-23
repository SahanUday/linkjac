---
id: GAP-045
title: A browser page cannot answer a status: an unknown route and a missing bookmark are both 200 with the HTML shell
kind: limitation
severity: minor
status: open
area: ui
milestone: M4
found: 2026-11-23
neojac: 0.4.0
command: curl -s -o /dev/null -w "%{http_code}" <url>
code:
---

## Symptom
The built `api` program (this repo's `app/`, served by the project's own `rest_bridge` transport plugin, GAP-037) answered `200 text/html` with the HTML shell for `/bookmarks/99999999/edit` (an edit page of a bookmark that does not exist) and for `/no/such/route`; `/nofile.js` and `/assets/none.js` answered `404 text/plain`. linkding answers 404 for a missing bookmark's edit address. The edit page now says "This bookmark does not exist." in the page, with status 200. The parity check `test_a_missing_bookmark_answers_404` passes on the original and is expected to fail on the port (`expected_gap_on_port("GAP-045")`; it did: 18 passed and 1 expected failure in the port's UI run).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
cd app && neojac build
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8342 dist/api-linux-x86_64/api &
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8342/bookmarks/99999999/edit    # 200
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8342/no/such/route               # 200
```
The run was through the bridge plugin, not neojac's standard transport; whether the standard one answers the same was not run.

## Expected
Documented behaviour, so a limitation: `neojac docs apps/pages` ("The HTML shell"): "A request for a path that is not a file of the bundle, `/user/amy`, gets `index.html`, even with a dot in it ... and the router picks the page in the browser." Nothing read says a page can set a status, or that a route can be marked not found.

## Workaround
The page shows a message and keeps status 200; the check is `expected_gap_on_port("GAP-045")`. Nothing in the app's code beyond the message.

## Cause
Unknown.
