---
id: GAP-057
title: A POST to a path that is only a page answers 200 with the HTML shell
kind: gap
severity: minor
status: worked-around
area: ui
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: curl -X POST /register (served app with pages)
code:
---

## Symptom
In the served app, which serves pages, `POST /register` with a JSON body answered 200 with the page's HTML shell, and so did `POST /signup` and `POST /accounts/signup/`. Nothing took the request. linkding answers 404 to each. Seen through the project's transport (`plugins/rest_bridge`), which hands every request outside `/api/` to the handler the program gives `Transport.listen`; the same under the standard `http` transport was not run.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# build app/ (neojac build), start dist/api-linux-x86_64/api with JAC_API_DATA=<empty dir> JAC_API_LISTEN=127.0.0.1:8011
curl -i -X POST http://127.0.0.1:8011/register -d '{}'
```

## Expected
`neojac docs apps/pages` says "A request for a path that is not a file of the bundle ... gets `index.html`", without saying which methods. A POST that no endpoint takes was expected to be 404 or 405, as a page is something a browser asks for with GET.

## Workaround
The bridge answers 404 to a request that is not a GET and is outside `/api/` and `/__jac/` (`WORKAROUND(GAP-057)`).

## Cause
Unknown.
