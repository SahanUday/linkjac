---
id: GAP-040
title: An admin command cannot act on a chosen user's data: a keyed caller has no root, and allroots() lists roots without names
kind: gap
severity: major
status: worked-around
area: auth
milestone: M3
found: 2026-11-23
neojac: 0.4.0
command:
code:
---

## Symptom
linkding's admin command `manage.py import_netscape <file> <user>` imports for a named user. The port's CLI app can act only as the account whose session token it holds (`JAC_REMOTE_TOKEN`); there is no way found to act for an account chosen by name. A probe in a scratch copy of `app/` (not in the repo), with the server run with `JAC_DEPLOY_KEY=s3cret`, two accounts registered (`alice1`, `bobby2`), and alice's file imported:

| Caller of an untagged function that returns `[len(allroots()), len([root --> [?:Bookmark]]), bookmarks under every root in allroots()]` | Answer |
|---|---|
| the deploy key, no token | `RemoteFailed: count_roots failed` (no reason in the message) |
| the key and alice's token | `[1, 1, 1]` |
| the key and bob's token | `[2, 0, 1]` |
So a keyed caller with no session has no usable `root`; with a session it is that account. `allroots()` lists the roots used so far (bob's showed only after his first call), and the bookmarks of all of them can be reached, but the only way to tell whose root is whose is not shown: a root has no username (the same fact that stops `?user=` on the shared list, listed in PLAN.md "Known deviations"). An admin needs the user's token, which needs their password.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# scratch copy of app/ with, in admin.jac (no :protect or :pub tag):  def count_roots -> list[int];
#   impl: total = 0; for r in allroots() { total += len([r --> [?:Bookmark]]); }
#         return [len(allroots()), len([root --> [?:Bookmark]]), total];
# cli.jac: a command that prints count_roots()
neojac build
JAC_DEPLOY_KEY=s3cret JAC_API_LISTEN=127.0.0.1:8324 dist/api-linux-x86_64 &    # register two users, import a file as one
JAC_DEPLOY_KEY=s3cret JAC_REMOTE_API=http://127.0.0.1:8324 dist/cli-linux-x86_64 roots     # RemoteFailed
JAC_DEPLOY_KEY=s3cret JAC_REMOTE_TOKEN=<token> JAC_REMOTE_API=http://127.0.0.1:8324 dist/cli-linux-x86_64 roots
```

## Expected
`neojac docs crossings` ("The deployment's key") says an untagged endpoint is served to a request that carries the key, and the building-an-app skill says such a caller "is no account, so it reads `root.shared`, not `root`". Nothing found says how a program with the key acts for one named account, or lists accounts with their names. A `RemoteFailed` for `root` was not expected to come without a reason.

## Workaround
The port's `import` and `export` commands act as the signed-in token holder; there is no `<user>` argument. The original's `import_netscape <file> <user>` is recorded as a deviation in PLAN.md.

## Cause
Unknown.
