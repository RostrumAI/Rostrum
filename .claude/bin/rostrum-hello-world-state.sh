#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="$PROJECT_DIR/.claude/state"
STATE_FILE="$STATE_DIR/rostrum-hello-world.json"
HELLO_WORLD_FILE="$PROJECT_DIR/hello_world.md"
HELLO_MOON_FILE="$PROJECT_DIR/hello_moon.md"

command="${1:-status}"
next_phase="${2:-}"

mkdir -p "$STATE_DIR"

write_state() {
  local status="$1"
  local phase="$2"

  python3 - "$STATE_FILE" "$status" "$phase" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

state_file, status, phase = sys.argv[1:4]
state = {
    "playbook": "rostrum-hello-world",
    "status": status,
    "phase": phase,
    "updated_at": datetime.now(timezone.utc).isoformat(),
}
with open(state_file, "w", encoding="utf-8") as fh:
    json.dump(state, fh, indent=2)
    fh.write("\n")
PY
}

case "$command" in
  prepare)
    rm -f "$HELLO_WORLD_FILE" "$HELLO_MOON_FILE" "$STATE_FILE"
    ;;
  start)
    write_state "active" "hello_world"
    ;;
  await-user)
    if [[ -z "$next_phase" ]]; then
      echo "usage: $0 await-user <phase>" >&2
      exit 1
    fi
    write_state "awaiting_user" "$next_phase"
    ;;
  next)
    if [[ -z "$next_phase" ]]; then
      echo "usage: $0 next <phase>" >&2
      exit 1
    fi
    write_state "active" "$next_phase"
    ;;
  finish)
    write_state "complete" "complete"
    ;;
  abort)
    write_state "aborted" "aborted"
    ;;
  reset)
    rm -f "$STATE_FILE"
    ;;
  print-path)
    printf '%s\n' "$STATE_FILE"
    ;;
  status)
    if [[ -f "$STATE_FILE" ]]; then
      cat "$STATE_FILE"
    else
      printf '%s\n' '{"playbook":"rostrum-hello-world","status":"inactive","phase":"idle"}'
    fi
    ;;
  *)
    echo "unknown command: $command" >&2
    exit 1
    ;;
esac
