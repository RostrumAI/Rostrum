#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
STATE_SCRIPT="$PROJECT_DIR/.claude/bin/rostrum-hello-world-state.sh"
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

emit_context() {
  local context="$1"
  python3 - "$context" <<'PY'
import json
import sys

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": sys.argv[1],
    }
}))
PY
}

if [[ ! -x "$STATE_SCRIPT" ]]; then
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

if [[ "$STATUS" != "awaiting_user" ]]; then
  exit 0
fi

USER_PROMPT="$(json_field '.prompt')"
if [[ -z "$USER_PROMPT" ]]; then
  USER_PROMPT="$(json_field '.user_prompt')"
fi
if [[ -z "$USER_PROMPT" ]]; then
  exit 0
fi

case "$PHASE" in
  hello_world)
    emit_context 'Rostrum hello-world is waiting for user-provided file content. Treat the user'"'"'s just-submitted prompt as the exact Markdown content for hello_world.md. Invoke the hidden `rostrum-hello-world-phase` skill in forked context, write the content exactly without adding framing, then advance the playbook into the hello_moon phase.'
    ;;
  hello_moon)
    emit_context 'Rostrum hello-world is waiting for user-provided file content. Treat the user'"'"'s just-submitted prompt as the exact Markdown content for hello_moon.md. Invoke the hidden `rostrum-hello-moon` skill in forked context, write the content exactly without adding framing, then finish the playbook.'
    ;;
esac
