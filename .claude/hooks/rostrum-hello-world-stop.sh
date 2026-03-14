#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
STATE_SCRIPT="$PROJECT_DIR/.claude/bin/rostrum-hello-world-state.sh"
HELLO_WORLD_FILE="$PROJECT_DIR/hello_world.md"
HELLO_MOON_FILE="$PROJECT_DIR/hello_moon.md"
INPUT="$(cat)"

json_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$field // empty"
  else
    printf '%s' "$INPUT" | python3 - "$field" <<'PY'
import json
import sys

field = sys.argv[1].lstrip(".")
try:
    payload = json.loads(sys.stdin.read() or "{}")
except json.JSONDecodeError:
    payload = {}

value = payload.get(field, "")
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
else:
    print(value)
PY
  fi
}

block() {
  local reason="$1"
  python3 - "$reason" <<'PY'
import json
import sys

print(json.dumps({"decision": "block", "reason": sys.argv[1]}))
PY
}

if [[ ! -x "$STATE_SCRIPT" ]]; then
  exit 0
fi

STOP_HOOK_ACTIVE="$(json_field '.stop_hook_active')"
SUBAGENT_STOP_HOOK_ACTIVE="$(json_field '.subagent_stop_hook_active')"
if [[ "$STOP_HOOK_ACTIVE" == "true" || "$SUBAGENT_STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

STATE_JSON="$("$STATE_SCRIPT" status)"
if [[ -z "$STATE_JSON" ]]; then
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  STATUS="$(printf '%s' "$STATE_JSON" | jq -r '.status')"
  PHASE="$(printf '%s' "$STATE_JSON" | jq -r '.phase')"
else
  STATUS="$(printf '%s' "$STATE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))')"
  PHASE="$(printf '%s' "$STATE_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("phase",""))')"
fi

if [[ "$STATUS" != "active" ]]; then
  exit 0
fi

case "$PHASE" in
  hello_world)
    if [[ ! -f "$HELLO_WORLD_FILE" ]]; then
      block "The Rostrum hello-world sample is still active. Create hello_world.md before stopping."
      exit 0
    fi

    block 'The Rostrum hello-world sample is not done yet. Run `.claude/bin/rostrum-hello-world-state.sh next hello_moon`, then immediately delegate to the `rostrum-hello-moon` subagent to create hello_moon.md and finish the playbook.'
    ;;
  hello_moon)
    if [[ ! -f "$HELLO_MOON_FILE" ]]; then
      block 'The Rostrum hello-world sample is waiting on phase two. Delegate now to the `rostrum-hello-moon` subagent. That subagent must create hello_moon.md and then run `.claude/bin/rostrum-hello-world-state.sh finish`.'
      exit 0
    fi

    block 'hello_moon.md exists, but the playbook has not been marked complete yet. Run `.claude/bin/rostrum-hello-world-state.sh finish` before stopping.'
    ;;
esac
