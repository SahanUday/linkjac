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
worker_pid=""
fixture_pid=""
work=""
stop_server() {
  [ -n "$fixture_pid" ] && kill -- "-$fixture_pid" 2>/dev/null || true
  if [ -n "$worker_pid" ]; then # the task worker finishes its running task before it stops, so give it a moment, then end it
    kill -- "-$worker_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6; do kill -0 "$worker_pid" 2>/dev/null || break; sleep 0.5; done
    kill -9 -- "-$worker_pid" 2>/dev/null || true
  fi
  [ -n "$server_pid" ] && kill -- "-$server_pid" 2>/dev/null || true
  [ -n "$work" ] && rm -rf "$work" || true
}
trap stop_server EXIT

wait_for() { # url
  for _ in $(seq 60); do curl -s -o /dev/null "$1" && return 0; sleep 0.5; done
  echo "server did not answer at $1"; return 1
}

# The local web site every network check points at, so no check touches the internet (parity/fixture_server.py).
fixture_port="${FIXTURE_PORT:-9100}"
ss -ltn | grep -q ":$fixture_port " && { echo "port $fixture_port is busy"; exit 1; }
setsid python3 "$here/fixture_server.py" "$fixture_port" >/dev/null 2>&1 &
fixture_pid=$!
export FIXTURE_URL="http://127.0.0.1:$fixture_port"
# Both apps may fetch from the fixture's address and no other private one (the original's own setting, read by the port too).
export LD_ALLOWED_INTERNAL_HOSTS=127.0.0.1
# The favicon provider is the fixture site too.
export LD_FAVICON_PROVIDER="$FIXTURE_URL/favicon/{domain}"
export LD_ENABLE_SNAPSHOTS=True
wait_for "$FIXTURE_URL/__seen"

if [ -z "${LINKDING_URL:-}" ] && [ "$target" = "original" ]; then
  port="${PARITY_PORT:-8000}"
  ss -ltn | grep -q ":$port " && { echo "port $port is busy"; exit 1; }
  cd "$original"
  # Background tasks stay on: the account that wants favicons and snapshots is parity3 alone. The real single-file needs a browser, so a script that only fetches the page stands in.
  export LD_SINGLEFILE_PATH="$here/single_file_stub.py" LD_SINGLEFILE_UBLOCK_OPTIONS=""
  # The original keeps a site's favicon for a day, so one fetched in an earlier run would stand in for the fixture's.
  rm -f data/favicons/http_127_0_0_1.*
  users="$(uv run manage.py shell < "$here/ensure_original_user.py")"
  LINKDING_TOKEN="$(echo "$users" | sed -n 's/^TOKEN=//p')"
  LINKDING_TOKEN_OTHER="$(echo "$users" | sed -n 's/^TOKEN_OTHER=//p')"
  LINKDING_TOKEN_JOBS="$(echo "$users" | sed -n 's/^TOKEN_JOBS=//p')"
  export LINKDING_TOKEN LINKDING_TOKEN_OTHER LINKDING_TOKEN_JOBS
  setsid uv run manage.py runserver "127.0.0.1:$port" --noreload >/dev/null 2>&1 &
  server_pid=$!
  setsid uv run manage.py run_huey >/dev/null 2>&1 &
  worker_pid=$!
  export LINKDING_URL="http://127.0.0.1:$port"
  wait_for "$LINKDING_URL/login/"
elif [ -z "${LINKDING_URL:-}" ] && [ "$target" = "port" ]; then
  port="${PARITY_PORT:-8010}"
  ss -ltn | grep -q ":$port " && { echo "port $port is busy"; exit 1; }
  work="$(mktemp -d)"
  (cd "$here/../app" && capped --mem 4G -- neojac build > "$work/build.log" 2>&1) || { cat "$work/build.log"; exit 1; }
  bin="$(ls -d "$here"/../app/dist/api-*-* | head -1)"
  [ -d "$bin" ] && bin="$bin/api"
  export PARITY_CLI="$(ls "$here"/../app/dist/cli-*-* | head -1)"
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
  LINKDING_TOKEN_JOBS="$(register parity3)"
  [ -n "$LINKDING_TOKEN" ] && [ -n "$LINKDING_TOKEN_OTHER" ] && [ -n "$LINKDING_TOKEN_JOBS" ] || { echo "could not register the parity users on the port"; exit 1; }
  export LINKDING_TOKEN LINKDING_TOKEN_OTHER LINKDING_TOKEN_JOBS
  # The profile has no API in either app: the original's accounts were set up by its shell script, these by the port's own settings function.
  change_profile() { # token favicons snapshots
    curl -s -X POST -H "Authorization: Bearer $1" "$LINKDING_URL/__jac/call/api/web_settings/change_profile" \
      -d "{\"args\":{\"enable_favicons\":$2,\"enable_automatic_html_snapshots\":$2}}" >/dev/null
  }
  change_profile "$LINKDING_TOKEN" false
  change_profile "$LINKDING_TOKEN_OTHER" false
  change_profile "$LINKDING_TOKEN_JOBS" true
fi

cd "$here"
capped -- uv run --with pytest --with httpx --with playwright pytest -q -p no:cacheprovider . "$@" || status=$?
cat "$PARITY_RESULTS"
exit "${status:-0}"
