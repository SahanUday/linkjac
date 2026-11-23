#!/usr/bin/env bash
# Saves through the served app, restarts the binary, and reads the data back.
# Needs: neojac, curl, capped. Uses a throwaway data directory and port 8301.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
port="${PERSISTENCE_PORT:-8301}"
work="$(mktemp -d)"
bin=""
pid=""
trap '[ -n "$pid" ] && kill "$pid" 2>/dev/null || true; rm -rf "$work"' EXIT

cd "$root/app"
capped --mem 4G -- neojac build api > "$work/build.log" 2>&1 || { cat "$work/build.log"; exit 1; }
bin="$(ls dist/api-*-* 2>/dev/null | head -1)"
[ -x "$bin" ] || { echo "no binary under app/dist"; exit 1; }

start() {
  JAC_API_DATA="$work/data" JAC_API_LISTEN="127.0.0.1:$port" "$bin" > "$work/server.log" 2>&1 &
  pid=$!
  for _ in $(seq 1 30); do grep -q "listening on" "$work/server.log" && return 0; sleep 1; done
  echo "server did not start"; cat "$work/server.log"; exit 1
}
stop() { kill "$pid"; wait "$pid" 2>/dev/null || true; pid=""; }
call() { curl -s -X POST "http://127.0.0.1:$port/__jac/call/api/service/$1" -d "{\"args\": $2}"; }
expect() { # name, actual, wanted
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got $2, wanted $3"; failed=1; fi
}
failed=0

start
call save '{"url":"https://example.com/a","title":"Alpha","tag_string":"web, Demo"}' > /dev/null
call save '{"url":"https://example.com/b","title":"Beta","tag_string":"web"}' > /dev/null
call set_theme '{"theme":"dark"}' > /dev/null
stop
start
expect "titles kept"  "$(call titles '{}')" '{"ok": true, "data": ["Alpha", "Beta"]}'
expect "search kept"  "$(call find '{"text":"#demo alpha"}')" '{"ok": true, "data": ["Alpha"]}'
expect "tags kept"    "$(call tags '{}')" '{"ok": true, "data": {"Demo": 1, "web": 2}}'
expect "profile kept" "$(call theme '{}')" '{"ok": true, "data": "dark"}'
stop
exit "$failed"
