#!/usr/bin/env bash
# Runs every parity check against one target and writes {"passed": n, "total": m}.
# PARITY_TARGET=original (default): starts the original from reference/, writes parity/results.json.
# PARITY_TARGET=port: builds app/, starts it on a fresh data directory, writes parity/results-port.json.
# LINKDING_URL + LINKDING_TOKEN: check a server that is already running (results.json).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
original="$here/../reference/linkding"
target="${PARITY_TARGET:-original}"
export PARITY_RESULTS="$here/results.json"
[ "$target" = "port" ] && PARITY_RESULTS="$here/results-port.json"
rm -f "$PARITY_RESULTS"

server_pid=""
work=""
stop_server() {
  [ -n "$server_pid" ] && kill -- "-$server_pid" 2>/dev/null || true
  [ -n "$work" ] && rm -rf "$work" || true
}
trap stop_server EXIT

wait_for() { # url
  for _ in $(seq 60); do curl -s -o /dev/null "$1" && return 0; sleep 0.5; done
  echo "server did not answer at $1"; return 1
}

if [ -z "${LINKDING_URL:-}" ] && [ "$target" = "original" ]; then
  port="${PARITY_PORT:-8000}"
  ss -ltn | grep -q ":$port " && { echo "port $port is busy"; exit 1; }
  cd "$original"
  export LD_DISABLE_BACKGROUND_TASKS=True
  users="$(uv run manage.py shell < "$here/ensure_original_user.py")"
  LINKDING_TOKEN="$(echo "$users" | sed -n 's/^TOKEN=//p')"
  LINKDING_TOKEN_OTHER="$(echo "$users" | sed -n 's/^TOKEN_OTHER=//p')"
  export LINKDING_TOKEN LINKDING_TOKEN_OTHER
  setsid uv run manage.py runserver "127.0.0.1:$port" --noreload >/dev/null 2>&1 &
  server_pid=$!
  export LINKDING_URL="http://127.0.0.1:$port"
  wait_for "$LINKDING_URL/login/"
elif [ -z "${LINKDING_URL:-}" ] && [ "$target" = "port" ]; then
  port="${PARITY_PORT:-8010}"
  ss -ltn | grep -q ":$port " && { echo "port $port is busy"; exit 1; }
  work="$(mktemp -d)"
  (cd "$here/../app" && capped --mem 4G -- neojac build api > "$work/build.log" 2>&1) || { cat "$work/build.log"; exit 1; }
  bin="$(ls "$here"/../app/dist/api-*-* | head -1)"
  JAC_API_DATA="$work/data" JAC_API_LISTEN="127.0.0.1:$port" setsid "$bin" > "$work/server.log" 2>&1 &
  server_pid=$!
  export LINKDING_URL="http://127.0.0.1:$port"
  wait_for "$LINKDING_URL/__jac/auth/"
  register() { # username
    curl -s -X POST "$LINKDING_URL/__jac/auth/register" \
      -d "{\"username\":\"$1\",\"email\":\"$1@example.com\",\"password\":\"parity-pass\"}" \
      | sed -n 's/.*"token": *"\([0-9a-f]*\)".*/\1/p'
  }
  LINKDING_TOKEN="$(register parity)"
  LINKDING_TOKEN_OTHER="$(register parity2)"
  [ -n "$LINKDING_TOKEN" ] && [ -n "$LINKDING_TOKEN_OTHER" ] || { echo "could not register the parity users on the port"; exit 1; }
  export LINKDING_TOKEN LINKDING_TOKEN_OTHER
fi

cd "$here"
capped -- uv run --with pytest --with httpx pytest -q -p no:cacheprovider . "$@" || status=$?
cat "$PARITY_RESULTS"
exit "${status:-0}"
