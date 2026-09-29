#!/usr/bin/env bash
# Throwaway dev backend for redesign proof screenshots and API proof.
# Never production: its own SQLite file under $DATA_DIR, loopback only.
# See backend/scripts/README-dev-stack.md.
set -euo pipefail

BACKEND="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$BACKEND/.venv"
# Parallel lanes on this box each own a port and a data dir; the defaults are
# the shared dev stack's.
DATA_DIR="${MM_DEV_DATA_DIR:-/srv/manhwamaniacs/dev/data}"
PORT="${MM_DEV_PORT:-8010}"
DB="$DATA_DIR/dev.db"
PID_FILE="$DATA_DIR/dev-backend.pid"
LOG_FILE="$DATA_DIR/dev-backend.log"
COOKIES="$DATA_DIR/cookies.txt"
BASE="http://127.0.0.1:$PORT"

die() { echo "dev_stack: $*" >&2; exit 2; }

available_mb() { free -m | awk '/Mem/{print $7}'; }

running_pid() {
  local pid
  [ -f "$PID_FILE" ] || return 1
  pid="$(cat "$PID_FILE")"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && echo "$pid"
}

guard_paths() {
  local real db_real
  real="$(readlink -f "$DATA_DIR")"
  case "$real" in
    /srv/manhwamaniacs/data* | /srv/manhwamaniacs/app*)
      die "refusing: $DATA_DIR resolves to production path $real" ;;
  esac
  if [ -n "${MM_DB_PATH:-}" ]; then
    db_real="$(readlink -f "$MM_DB_PATH")"
    case "$db_real" in
      "$real"/*) ;;
      *) die "refusing: MM_DB_PATH=$MM_DB_PATH resolves outside $DATA_DIR" ;;
    esac
  fi
}

guard_start() {
  guard_paths
  [ -x "$VENV/bin/python" ] || die "no virtualenv at $VENV. Create it:
  sudo apt-get install -y python3.14-venv
  cd $BACKEND && python3 -m venv .venv && .venv/bin/python -m pip install --upgrade pip && .venv/bin/pip install -r requirements.txt pytest==9.1.1"
  local avail
  avail="$(available_mb)"
  [ "$avail" -ge 1024 ] || die "refusing: only ${avail} MB available (need 1024)"
  if [ -n "$(ss -ltnH "sport = :$PORT")" ]; then
    die "refusing: something else already listens on port $PORT"
  fi
}

cmd_status() {
  local pid
  if pid="$(running_pid)"; then
    echo "running  pid $pid  port $PORT"
  else
    echo "stopped  port $PORT"
  fi
  if [ -f "$DB" ]; then
    echo "db       $DB ($(du -h "$DB" | cut -f1))"
  else
    echo "db       $DB (absent)"
  fi
  echo "free     $(available_mb) MB available"
}

cmd_start() {
  if running_pid >/dev/null; then
    cmd_status
    return 0
  fi
  guard_start
  mkdir -p "$DATA_DIR"
  local keep=(-u DEEPSEEK_API_KEY)
  if [ "${MM_DEV_AI:-}" = "1" ]; then keep=(); fi
  (
    cd "$BACKEND"
    nohup env "${keep[@]}" -u MM_RENDER_WORKER_TOKEN \
      MM_DB_PATH="$DB" \
      MM_SETTINGS_PATH="$DATA_DIR/settings.json" \
      MM_COOKIE_SECURE=false \
      MM_NOVELS_ENABLED=true \
      MM_RATE_LIMIT_ENABLED=false \
      MM_REGISTRATION_ENABLED=true \
      MM_BOOTSTRAP_WINDOW_MINUTES=1440 \
      "$VENV/bin/python" -m uvicorn main:app --host 127.0.0.1 --port "$PORT" \
      >"$LOG_FILE" 2>&1 &
    echo $! >"$PID_FILE"
  )
  for _ in $(seq 60); do
    if curl -sf "$BASE/health" >/dev/null; then
      echo "dev backend up on 127.0.0.1:$PORT (db $DB)"
      return 0
    fi
    running_pid >/dev/null || break
    sleep 1
  done
  echo "dev backend failed to come up; last log lines:" >&2
  tail -n 40 "$LOG_FILE" >&2 || true
  exit 1
}

cmd_stop() {
  local pid
  if pid="$(running_pid)"; then
    kill "$pid" 2>/dev/null || true
    for _ in $(seq 10); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    echo "dev backend stopped (pid $pid)"
  fi
  rm -f "$PID_FILE"
}

cmd_seed() {
  running_pid >/dev/null || cmd_start
  MM_DEV_PORT="$PORT" "$VENV/bin/python" "$BACKEND/scripts/seed_demo.py" --base "$BASE"
}

cmd_reset() {
  guard_paths
  cmd_stop
  rm -f "$DB" "$DB-wal" "$DB-shm" "$DATA_DIR/settings.json" "$COOKIES"
  cmd_start
  cmd_seed
}

cmd_api() {
  [ $# -ge 2 ] || die "usage: dev_stack.sh api METHOD PATH [JSON]"
  local method="$1" path="$2" body="${3:-}" pid_json profile_id
  running_pid >/dev/null || die "dev backend is not running (dev_stack.sh start)"
  if ! curl -sf -b "$COOKIES" "$BASE/auth/me" >/dev/null 2>&1; then
    curl -sf -c "$COOKIES" -H 'Content-Type: application/json' \
      -d '{"username":"demo","password":"maniacs-demo-2026","remember":true}' \
      "$BASE/auth/login" >/dev/null || die "demo login failed (dev_stack.sh seed?)"
  fi
  pid_json="$(curl -sf -b "$COOKIES" "$BASE/profiles")"
  profile_id="$(MM_DEV_PROFILE="${MM_DEV_PROFILE:-Riya}" python3 -c '
import json, os, sys
name = os.environ["MM_DEV_PROFILE"]
print(next((p["id"] for p in json.load(sys.stdin) if p["name"] == name), ""))
' <<<"$pid_json")"
  [ -n "$profile_id" ] || die "no profile named ${MM_DEV_PROFILE:-Riya}"
  local args=(-s -b "$COOKIES" -X "$method" -H "X-Profile-Id: $profile_id")
  if [ -n "$body" ]; then args+=(-H 'Content-Type: application/json' -d "$body"); fi
  curl "${args[@]}" "$BASE$path" | python3 -m json.tool
}

case "${1:-}" in
  start) cmd_start ;;
  stop) cmd_stop ;;
  restart) cmd_stop; cmd_start ;;
  status) cmd_status ;;
  seed) cmd_seed ;;
  reset) cmd_reset ;;
  api) shift; cmd_api "$@" ;;
  *) echo "usage: dev_stack.sh start|stop|restart|status|seed|reset|api METHOD PATH [JSON]" >&2; exit 2 ;;
esac
