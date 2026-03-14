#!/usr/bin/env bash

set -euo pipefail

# This is a deliberately experimental hook. Claude Code hooks do not expose a
# supported primitive for "clear the active session now", so this script uses
# terminal input injection as a best-effort local workaround.
#
# It is expected to work only in local interactive terminal sessions where the
# current OS and terminal permit TIOCSTI input injection. It is not expected to
# work reliably in remote, GUI, or browser-backed Claude Code surfaces.

INPUT="$(cat)"
LOG_FILE="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/hooks/clear-on-stop.log"

log() {
  local message="$1"
  mkdir -p "$(dirname "$LOG_FILE")"
  printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$message" >> "$LOG_FILE"
}

if command -v jq >/dev/null 2>&1; then
  STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')"
  SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown-session"')"
else
  STOP_HOOK_ACTIVE="false"
  SESSION_ID="unknown-session"
fi

# Claude documents this guard to avoid Stop-hook loops.
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  log "session=$SESSION_ID event=skip reason=stop_hook_active"
  exit 0
fi

if [[ "${ROSTRUM_DISABLE_CLAUDE_STOP_CLEAR:-0}" == "1" ]]; then
  log "session=$SESSION_ID event=skip reason=env_disabled"
  exit 0
fi

TTY_PATH="$(tty 2>/dev/null || true)"
if [[ -z "$TTY_PATH" || "$TTY_PATH" == "not a tty" ]]; then
  log "session=$SESSION_ID event=skip reason=no_tty"
  echo "clear-on-stop: no controlling tty for session $SESSION_ID" >&2
  exit 0
fi

# Avoid rapid repeated injection if Claude emits multiple Stop events back to
# back. This is intentionally coarse and local.
STAMP_DIR="${TMPDIR:-/tmp}/rostrum-claude-stop-clear"
STAMP_FILE="$STAMP_DIR/$SESSION_ID.stamp"
mkdir -p "$STAMP_DIR"

NOW="$(date +%s)"
LAST_RUN="0"
if [[ -f "$STAMP_FILE" ]]; then
  LAST_RUN="$(cat "$STAMP_FILE" 2>/dev/null || echo 0)"
fi

if [[ "$LAST_RUN" =~ ^[0-9]+$ ]] && (( NOW - LAST_RUN < 2 )); then
  log "session=$SESSION_ID event=skip reason=debounced tty=$TTY_PATH"
  exit 0
fi

printf '%s' "$NOW" > "$STAMP_FILE"
log "session=$SESSION_ID event=inject_start tty=$TTY_PATH"

if python3 - "$TTY_PATH" "/clear"$'\n' <<'PY'
import fcntl
import os
import sys
import termios

tty_path = sys.argv[1]
payload = sys.argv[2]

if not hasattr(termios, "TIOCSTI"):
    print("clear-on-stop: TIOCSTI not available on this platform", file=sys.stderr)
    raise SystemExit(0)

flags = os.O_RDWR
if hasattr(os, "O_NOCTTY"):
    flags |= os.O_NOCTTY

try:
    fd = os.open(tty_path, flags)
except OSError as exc:
    print(f"clear-on-stop: could not open tty {tty_path}: {exc}", file=sys.stderr)
    raise SystemExit(0)

try:
    for ch in payload:
        try:
            fcntl.ioctl(fd, termios.TIOCSTI, ch.encode("utf-8"))
        except OSError as exc:
            print(f"clear-on-stop: tty injection failed: {exc}", file=sys.stderr)
            raise SystemExit(0)
finally:
    os.close(fd)
PY
then
  log "session=$SESSION_ID event=inject_done tty=$TTY_PATH"
else
  log "session=$SESSION_ID event=inject_failed tty=$TTY_PATH"
fi
