#!/usr/bin/env bash
# Saves through /api/ of the served app, restarts the binary, and reads the data back with the same token.
# Why the REST path and not a function endpoint: that is how a client reaches the data, and it also proves
# that accounts, per-caller roots and the transport plugin survive a restart together.
# Needs: neojac, curl, capped. Uses a throwaway data directory and port 8301.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
port="${PERSISTENCE_PORT:-8301}"
base="http://127.0.0.1:$port"
work="$(mktemp -d)"
pid=""
trap '[ -n "$pid" ] && kill "$pid" 2>/dev/null || true; rm -rf "$work"' EXIT

cd "$root/app"
capped --mem 4G -- neojac build api > "$work/build.log" 2>&1 || { cat "$work/build.log"; exit 1; }
bin="$(ls -d "$root"/app/dist/api-*-* 2>/dev/null | head -1)"
[ -d "$bin" ] && bin="$bin/api" # an app that serves pages is built as a directory
[ -x "$bin" ] || { echo "no binary under app/dist"; exit 1; }

start() {
  JAC_API_DATA="$work/data" JAC_API_LISTEN="127.0.0.1:$port" "$bin" > "$work/server.log" 2>&1 &
  pid=$!
  for _ in $(seq 1 30); do grep -q "listening on" "$work/server.log" && return 0; sleep 1; done
  echo "server did not start"; cat "$work/server.log"; exit 1
}
stop() { kill "$pid"; wait "$pid" 2>/dev/null || true; pid=""; }
api() { curl -s -X "$1" "$base/api/$2" -H "Authorization: Token $token" -H 'Content-Type: application/json' ${3:+-d "$3"}; }
expect() { # name, actual, wanted
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got $2, wanted $3"; failed=1; fi
}
failed=0

start
token="$(curl -s -X POST "$base/__jac/auth/register" -d '{"username":"keeper","email":"k@example.com","password":"keeper-pass"}' \
  | sed -n 's/.*"token": *"\([0-9a-f]*\)".*/\1/p')"
[ -n "$token" ] || { echo "FAIL could not register"; exit 1; }
api POST bookmarks/ '{"url":"https://keep.example/a","title":"Kept","tag_names":["alpha","beta"]}' > /dev/null
api POST tags/ '{"name":"loose"}' > /dev/null
expect "before restart: one bookmark" "$(api GET 'bookmarks/?q=%23alpha' | sed -n 's/.*"count": *\([0-9]*\).*/\1/p')" 1
stop

start
expect "after restart: bookmark found by tag" "$(api GET 'bookmarks/?q=%23alpha' | sed -n 's/.*"count": *\([0-9]*\).*/\1/p')" 1
expect "after restart: title kept" "$(api GET 'bookmarks/?q=keep.example' | sed -n 's/.*"title": *"\([^"]*\)".*/\1/p')" Kept
expect "after restart: tags kept" "$(api GET 'tags/' | sed -n 's/.*"count": *\([0-9]*\).*/\1/p')" 3
expect "after restart: next id goes on" "$(api POST bookmarks/ '{"url":"https://keep.example/b"}' | sed -n 's/^{"id": *\([0-9]*\).*/\1/p')" 2
stop

exit "$failed"
