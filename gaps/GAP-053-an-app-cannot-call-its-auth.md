---
id: GAP-053
title: An app cannot call its auth plugin to make accounts or tokens, and an action can only reply with one Session
kind: limitation
severity: major
status: worked-around
area: auth
milestone: M6
found: 2026-11-26
neojac: 0.4.0
command: neojac docs auth.contract
code:
---

## Symptom
linkding lets a signed-in user list, make and delete API tokens on a settings page, and an admin make accounts. With the auth abstraction the accounts and tokens live in the plugin, and app code has no way to call it: a program never names a plugin or its interface (`neojac docs apps/stdjac-server`, "What a plugin conforms to"), and the runtime's page functions are `sign_in`, `sign_out` and three that read who is signed in. The one way in is `POST /__jac/auth/<action>`, whose reply is a `Session` (`user`, `token`, `name`) and nothing else, and `answer(action, given, client)` is given no request headers. So an action cannot return a list of tokens, cannot know the caller from their session without being passed it in `given`, and the app's pages cannot call it through `@jac/runtime`.

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
neojac docs apps/server               # "Signing in": the requests a served app answers
neojac docs apps/stdjac-server        # SignInAction, Session; Auth.answer(action, given, client)
neojac docs apps/pages                # "Signing in": the page's functions
```

## Expected
A way for server code to ask the auth plugin for account and credential work (or a plugin-defined call with its own reply type).

## Workaround
`plugins/linkauth` offers the actions `add_user`, `create_token` and `delete_token`, each given a name and password in `given` (`WORKAROUND(GAP-053)`); the new key comes back as the `Session`'s token. No token list, no settings page for tokens.

## Cause
Unknown.
