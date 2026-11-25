---
id: GAP-034
title: The accounts auth plugin reads only 'Authorization: Bearer <token>'; linkding's 'Token <token>' keyword is refused with 401
kind: limitation
severity: minor
status: worked-around
area: auth
milestone: M2
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
With the standard `accounts` plugin, a `:protect` endpoint answers a caller who sends `Authorization: Bearer <token>` (the token from `POST /__jac/auth/register`) and answers 401 `This needs a signed-in caller.` to the same token under `Authorization: Token <token>` or `token <token>`. linkding's API takes both keywords (`LinkdingTokenAuthentication.keywords = ["Token", "Bearer"]` in `reference/linkding/bookmarks/api/auth.py`), and every parity check sends `Token`. With Bearer, `root` inside the endpoint is the caller's own root (a node made by one call was counted by the next call of the same account), so per-caller roots work under `accounts`.

## Repro
```sh
neojac --version
# scratch project: archwire.jac as in GAP-030; m.jac:
#   node N { has v: int; }
#   def:protect add_mine -> int { root ++> N(v=1); return len([root --> [?:N]]); }
#   def:protect count_mine -> int { return len([root --> [?:N]]); }
neojac fmt --fix . && neojac build api
JAC_API_DATA=$(mktemp -d) JAC_API_LISTEN=127.0.0.1:8311 dist/api-linux-x86_64 &
TOK=$(curl -s -X POST http://127.0.0.1:8311/__jac/auth/register -d '{"username":"amy","email":"amy@example.com","password":"longenough1"}' | sed -n 's/.*"token": *"\([0-9a-f]*\)".*/\1/p')
curl -s -X POST http://127.0.0.1:8311/__jac/call/api/m/add_mine   -H "Authorization: Bearer $TOK" -d '{"args":{}}'   # {"ok": true, "data": 1}
curl -s -X POST http://127.0.0.1:8311/__jac/call/api/m/count_mine -H "Authorization: Token $TOK"  -d '{"args":{}}'   # 401
kill %1
```

## Expected
`neojac docs apps/server`, "Who is calling": the only credential header is `Authorization: Bearer <token>`; so documented, and kind is limitation. The `Auth` interface (`neojac docs apps/stdjac-server`) gives a plugin `caller(headers)`, so another plugin could read `Token`, but a plugin cannot be a change to the standard one. The same accounts also differ from linkding's tokens: a token is made by each `register` or `login` and is not a stable per-user key (a second `login` made a second token; not checked whether the first still works), and linkding allows several named tokens per user. That is M6's.

## Workaround
Since M6 (2026-11-26): the project binds its own auth plugin, `plugins/linkauth`, whose `caller` reads `Token` and `Bearer` in any case (`WORKAROUND(GAP-034)`). The bridge no longer rewrites the header. Shown by `parity/test_api_auth.py` on both apps. In M2 to M5 the bridge turned `Token` into `Bearer`. Writing a plugin for this is GAP-050.

## Cause
Unknown.
