#!/usr/bin/env bash
# Runs every parity check and writes parity/results.json as {"passed": n, "total": m}.
# LINKDING_URL + LINKDING_TOKEN: check that app. Otherwise start the original from reference/ and stop it after.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
original="$here/../reference/linkding"
export PARITY_RESULTS="$here/results.json"
rm -f "$PARITY_RESULTS"

server_pid=""
stop_server() { [ -n "$server_pid" ] && kill -- "-$server_pid" 2>/dev/null || true; }
trap stop_server EXIT

if [ -z "${LINKDING_URL:-}" ]; then
  port="${PARITY_PORT:-8000}"
  ss -ltn | grep -q ":$port " && { echo "port $port is busy"; exit 1; }
  cd "$original"
  export LD_DISABLE_BACKGROUND_TASKS=True
  LINKDING_TOKEN="$(uv run manage.py shell < "$here/ensure_original_user.py" | sed -n 's/^TOKEN=//p')"
  export LINKDING_TOKEN
  setsid uv run manage.py runserver "127.0.0.1:$port" --noreload >/dev/null 2>&1 &
  server_pid=$!
  export LINKDING_URL="http://127.0.0.1:$port"
  for _ in $(seq 60); do
    curl -s -o /dev/null "$LINKDING_URL/login/" && break
    sleep 0.5
  done
fi

cd "$here"
capped -- uv run --with pytest --with httpx pytest -q -p no:cacheprovider . "$@" || status=$?
cat "$PARITY_RESULTS"
exit "${status:-0}"
