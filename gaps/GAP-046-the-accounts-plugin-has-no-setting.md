---
id: GAP-046
title: The accounts plugin has no setting to turn off public sign-up: the sign-in dialog offers Create account and register works for anyone
kind: gap
severity: major
status: worked-around
area: auth
milestone: M4
found: 2026-11-23
neojac: 0.4.0
command: curl -X POST /__jac/auth/register
code:
---

## Symptom
The port's served app, signed out, shows the plugin's sign-in dialog with the buttons Cancel, Sign in and Create account and an "Email (optional)" field (`sign_in()` on `/bookmarks`, read with Playwright's accessibility snapshot). `POST /__jac/auth/register` with a new username and password answered `{"ok": true, "data": {"user": ..., "token": ...}}` to a caller with no credentials, so anyone who can reach the app can make an account and use it. linkding has no public sign-up: its accounts are made by an admin. `neojac docs apps/server` "The accounts plugin" lists the settings of `[auth.accounts]` (`path`, `rounds`, `session_seconds`, `local_users`, `email_required`, the GitHub ones, `origin`); none turns registration off. Not tried: an `auth` plugin of our own, or the `limits` setting (the page says 10 registrations per client address per 15 minutes).

## Repro
```sh
neojac --version                      # neojac 0.4.0 (linux-x86_64, bdb6b2746f64)
# build app/ (neojac build), start dist/api-linux-x86_64/api with JAC_API_DATA=<empty dir> JAC_API_LISTEN=127.0.0.1:8011
curl -s -X POST http://127.0.0.1:8011/__jac/auth/register -d '{"username":"stranger","email":"s@example.com","password":"stranger-pass"}'
neojac docs apps/server               # section "The accounts plugin": the settings table
```

## Expected
The original has no sign-up: linkding's accounts are made by an admin, and its login page offers no way to create one. The port must behave the same, so `register` must be closed to a caller with no credentials. neojac side: a setting such as "registration off", or a page saying how an app that makes its accounts itself closes `register`. `neojac docs search "registration sign up create account"` found only the rate-limit line of `apps/server`.

## Workaround
Since M6 (2026-11-26): `plugins/linkauth` offers `login` alone and refuses `register` (`WORKAROUND(GAP-046)`); the first account comes from `LD_SUPERUSER_NAME` and `LD_SUPERUSER_PASSWORD` as in linkding, and a superuser makes the others (action `add_user`, GAP-053). Shown by `parity/test_ui_accounts.py` on both apps. The standard plugin still has no setting for it (GAP-050).

## Cause
Unknown.
