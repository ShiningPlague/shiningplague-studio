#!/bin/bash
# SubagentStart + SubagentStop hook: audit-log agent lifecycle events.
# Branches on .hook_event_name from the stdin JSON. Merged from the old
# log-agent.sh (start) + log-agent-stop.sh (stop) pair.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null)
    AGENT=$(echo "$INPUT" | jq -r '.agent_type // "unknown"' 2>/dev/null)
else
    EVENT=$(echo "$INPUT" | grep -oE '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
    AGENT=$(echo "$INPUT" | grep -oE '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
    [ -z "$EVENT" ] && EVENT="unknown"
    [ -z "$AGENT" ] && AGENT="unknown"
fi

case "$EVENT" in
    SubagentStart) LABEL="AGENT START" ;;
    SubagentStop)  LABEL="AGENT STOP" ;;
    *)             LABEL="AGENT $EVENT" ;;
esac

SESSION_LOG_DIR="production/session-logs"
mkdir -p "$SESSION_LOG_DIR" 2>/dev/null
echo "$(date +%Y%m%d_%H%M%S) | $LABEL: $AGENT" >> "$SESSION_LOG_DIR/agent-audit.log" 2>/dev/null

exit 0
