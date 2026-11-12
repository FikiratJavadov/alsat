#!/usr/bin/env bash
# verify-alsat control helper. Run from anywhere:
#   control.sh launch <web|docs>          start a dev server, print RUN_DIR
#   control.sh doctor <RUN_DIR>           read-only health check
#   control.sh browser <RUN_DIR> <args>   agent-browser in this run's session
#   control.sh url <RUN_DIR>              print the app URL
#   control.sh stop <RUN_DIR>             tear down what this run started
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$SKILL_DIR/../../.." && pwd)"
ROOT="${VERIFY_ALSAT_ROOT:-/tmp/verify-alsat}"
RECORDER="$SKILL_DIR/scripts/alert-recorder.js"

die() { echo "error: $*" >&2; exit 1; }

free_port() {
  local p
  for p in $(seq 3100 3199); do
    if ! lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; then echo "$p"; return; fi
  done
  die "no free port in 3100-3199"
}

descendants() {
  local kid
  for kid in $(pgrep -P "$1" 2>/dev/null || true); do descendants "$kid"; echo "$kid"; done
}

load() {
  local run="${1:-}"
  [[ -n "$run" && -f "$run/env" ]] || die "not a run dir: '$run'"
  # shellcheck disable=SC1091
  source "$run/env"
}

cmd_launch() {
  local app="${1:-}"
  [[ "$app" == web || "$app" == docs ]] || die "usage: launch <web|docs>"
  if pgrep -f "next dev" >/dev/null 2>&1; then
    echo "warning: another 'next dev' is running; if it serves apps/$app, this launch may fail on the .next lock" >&2
  fi
  local id port run
  id="$app-$(date +%Y%m%d-%H%M%S)-$$"
  port="$(free_port)"
  run="$ROOT/runs/$id"
  mkdir -p "$run" "$ROOT/evidence/$id"
  cat >"$run/env" <<ENV
APP=$app
PORT=$port
RUN_ID=$id
URL=http://localhost:$port/
SESSION=verify-alsat-$id
EVIDENCE=$ROOT/evidence/$id
LOG=$run/server.log
ENV
  cd "$REPO"
  nohup pnpm --filter "$app" exec next dev --port "$port" </dev/null >"$run/server.log" 2>&1 &
  echo $! >"$run/server.pid"
  local i
  for i in $(seq 1 90); do
    if grep -q "Ready in" "$run/server.log" 2>/dev/null &&
       curl -fsS -o /dev/null "http://localhost:$port/"; then
      echo "RUN_DIR=$run"
      return 0
    fi
    kill -0 "$(cat "$run/server.pid")" 2>/dev/null || { cat "$run/server.log" >&2; die "server exited"; }
    sleep 1
  done
  cat "$run/server.log" >&2
  die "server not ready after 90s (RUN_DIR=$run; run stop on it)"
}

cmd_doctor() {
  local run="${1:-}"; load "$run"
  local ok=1 pid listener
  pid="$(cat "$run/server.pid")"
  if kill -0 "$pid" 2>/dev/null; then echo "ok   server pid $pid alive"; else echo "FAIL server pid $pid gone"; ok=0; fi
  listener="$(lsof -nP -t -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -1 || true)"
  if [[ -n "$listener" ]] && { [[ "$listener" == "$pid" ]] || descendants "$pid" | grep -qx "$listener"; }; then
    echo "ok   port $PORT owned by this run (pid $listener)"
  else
    echo "FAIL port $PORT listener '${listener:-none}' is not this run's server"; ok=0
  fi
  local body
  body="$(curl -fsS "$URL" 2>/dev/null || true)"
  if grep -q "apps/$APP/app/page.tsx" <<<"$body"; then
    echo "ok   $URL serves the $APP app"
  else
    echo "FAIL $URL does not serve the $APP app"; ok=0
  fi
  echo "info url=$URL session=$SESSION evidence=$EVIDENCE log=$LOG"
  [[ $ok == 1 ]] || exit 1
}

cmd_browser() {
  local run="${1:-}"; load "$run"; shift
  AGENT_BROWSER_SESSION="$SESSION" exec agent-browser --init-script "$RECORDER" "$@"
}

cmd_url() { load "${1:-}"; echo "$URL"; }

cmd_stop() {
  local run="${1:-}"; load "$run"
  local bpid_file="$HOME/.agent-browser/$SESSION.pid"
  if [[ -f "$bpid_file" ]]; then
    local bpid; bpid="$(cat "$bpid_file")"
    # Ask nicely first; a daemon stuck on a dialog never answers, so fall back to its pid.
    ( AGENT_BROWSER_SESSION="$SESSION" agent-browser close >/dev/null 2>&1 & ) ; sleep 3
    if kill -0 "$bpid" 2>/dev/null; then
      local kids; kids="$(descendants "$bpid")"
      kill $kids "$bpid" 2>/dev/null || true
    fi
    rm -f "$HOME/.agent-browser/$SESSION".*
  fi
  local pid; pid="$(cat "$run/server.pid")"
  local kids; kids="$(descendants "$pid")"
  kill $kids "$pid" 2>/dev/null || true
  sleep 1
  if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then echo "warning: port $PORT still listening" >&2; fi
  rm -rf "$run"
  echo "stopped $RUN_ID; evidence kept at $EVIDENCE"
}

case "${1:-}" in
  launch|doctor|browser|url|stop) c="$1"; shift; "cmd_$c" "$@" ;;
  *) sed -n '2,7p' "$0"; exit 2 ;;
esac
