#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/../../loop-config.json"

if [ ! -f "$CONFIG_PATH" ]; then
  cat <<'ENDJSON'
{
  "decision": "stop",
  "followup_message": "loop-config.json not found. Create one in the workspace root. See README.md for the schema."
}
ENDJSON
  exit 0
fi

json_escape() {
  python3 -c "import sys,json; print(json.dumps(sys.stdin.read())[1:-1])" 2>/dev/null \
    || sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' '|' | sed 's/|/\\n/g'
}

TASK=$(python3 -c "import json; c=json.load(open('$CONFIG_PATH')); print(c.get('task',''))" 2>/dev/null)

if [ -z "$TASK" ] || [ "$(echo "$TASK" | tr -d '[:space:]')" = "" ]; then
  cat <<'ENDJSON'
{
  "decision": "stop"
}
ENDJSON
  exit 0
fi

VALIDATION_CMD=$(python3 -c "import json; c=json.load(open('$CONFIG_PATH')); print(c.get('validation_command',''))" 2>/dev/null)
ON_FAIL=$(python3 -c "import json; c=json.load(open('$CONFIG_PATH')); print(c.get('on_validation_fail','Validation failed. Fix the errors:\n{errors}'))" 2>/dev/null)
ON_PASS=$(python3 -c "import json; c=json.load(open('$CONFIG_PATH')); print(c.get('on_validation_pass','Validation passed.'))" 2>/dev/null)

MSG=""

if [ -n "$VALIDATION_CMD" ]; then
  OUTPUT=$(eval "$VALIDATION_CMD" 2>&1) || true
  EXIT_CODE=${PIPESTATUS[0]:-$?}

  ESCAPED_OUTPUT=$(echo "$OUTPUT" | json_escape)

  if [ "$EXIT_CODE" != "0" ]; then
    FAIL_MSG=$(echo "$ON_FAIL" | sed "s|{errors}|$ESCAPED_OUTPUT|g")
    MSG="$(echo "$FAIL_MSG" | json_escape)\n\n"
  else
    MSG="$(echo "$ON_PASS" | json_escape)\n\n"
  fi
fi

ESCAPED_TASK=$(echo "$TASK" | json_escape)
MSG="${MSG}ONGOING TASK (keep working on this):\n${ESCAPED_TASK}"

cat <<ENDJSON
{
  "decision": "continue",
  "followup_message": "$MSG"
}
ENDJSON
