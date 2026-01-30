#!/bin/bash
# Ralph - Autonomous AI agent loop with BMAD QRD quality validation
# Usage: ./ralph.sh [--tool amp|claude] [max_iterations]

set -e

# Parse arguments
TOOL="claude"  # Default to Claude Code
MAX_ITERATIONS=100

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp' or 'claude'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
NOTIFY_CONFIG="$SCRIPT_DIR/.notify-config"

# --- Notification support ---
send_notification() {
  local title="$1"
  local message="$2"
  if [ -f "$NOTIFY_CONFIG" ]; then
    source "$NOTIFY_CONFIG"
    if [ -n "$NTFY_TOPIC" ]; then
      curl -s -d "$message" -H "Title: $title" "https://ntfy.sh/$NTFY_TOPIC" > /dev/null 2>&1 || true
    fi
  fi
}

# --- Archive previous run if branch changed ---
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# --- Track current branch ---
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# --- Initialize progress file ---
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# --- Check for QRD ---
QRD_PATH=""
if [ -f "$PRD_FILE" ]; then
  QRD_PATH=$(jq -r '.qrdPath // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$QRD_PATH" ] && [ -f "$SCRIPT_DIR/$QRD_PATH" ]; then
    echo "QRD found: $QRD_PATH"
  else
    QRD_PATH=""
    echo "No QRD configured (quality gates from prd.json will be used if present)"
  fi
fi

echo ""
echo "============================================="
echo "  Ralph - BMAD QRD Loop"
echo "============================================="
echo "  Tool:            $TOOL"
echo "  Max iterations:  $MAX_ITERATIONS"
echo "  QRD:             ${QRD_PATH:-none}"
echo "============================================="
echo ""

send_notification "Ralph Started" "Tool: $TOOL, Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Run the selected tool with the ralph prompt
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$SCRIPT_DIR/prompts/ralph-agent.md" 2>&1 | tee /dev/stderr) || true
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "============================================="
    echo "  Ralph completed all tasks!"
    echo "  Finished at iteration $i of $MAX_ITERATIONS"
    echo "============================================="
    send_notification "Ralph Complete!" "All stories passed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  # Check for errors
  if echo "$OUTPUT" | grep -iq "error\|failed\|exception"; then
    send_notification "Ralph Alert" "Potential issues detected in iteration $i. Check logs."
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "============================================="
echo "  Ralph reached max iterations ($MAX_ITERATIONS)"
echo "  Check progress.txt for status."
echo "============================================="
send_notification "Ralph Max Iterations" "Reached $MAX_ITERATIONS iterations without completing all tasks."
exit 1
