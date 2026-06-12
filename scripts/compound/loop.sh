#!/bin/bash
# loop.sh - Claude Code execution loop for compound tasks
#
# Runs Claude Code iteratively, one task at a time, until all tasks in
# prd.json pass or the iteration limit is reached.
#
# Usage: ./scripts/compound/loop.sh [max_iterations] [project_dir]
#
# This is the Claude Code equivalent of Ralph's ralph.sh, but designed
# to work within the compound automation pipeline.

set -e

MAX_ITERATIONS="${1:-25}"
PROJECT_DIR="${2:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
PRD_FILE="$PROJECT_DIR/prd.json"
PROGRESS_FILE="$PROJECT_DIR/progress.txt"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/compound-loop.log"
}

cd "$PROJECT_DIR"

# Check for prd.json
if [ ! -f "$PRD_FILE" ]; then
  log "ERROR: No prd.json found at $PRD_FILE"
  exit 1
fi

# Initialize progress file if needed
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Compound Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Check if there are any incomplete stories
remaining() {
  jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0"
}

log "=== Starting Compound Execution Loop ==="
log "Max iterations: $MAX_ITERATIONS"
log "Remaining stories: $(remaining)"

# Find CLAUDE.md - check project root first, then script directory
CLAUDE_MD=""
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
elif [ -f "$SCRIPT_DIR/../../CLAUDE.md" ]; then
  CLAUDE_MD="$SCRIPT_DIR/../../CLAUDE.md"
fi

for i in $(seq 1 "$MAX_ITERATIONS"); do
  REMAINING=$(remaining)

  if [ "$REMAINING" -eq 0 ]; then
    log "All stories complete!"
    break
  fi

  log ""
  log "============================================================"
  log "  Compound Loop - Iteration $i of $MAX_ITERATIONS"
  log "  Remaining stories: $REMAINING"
  log "============================================================"

  # Run Claude Code with the CLAUDE.md prompt (same as ralph.sh --tool claude)
  if [ -n "$CLAUDE_MD" ]; then
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$CLAUDE_MD" 2>&1 | tee -a "$LOG_DIR/compound-loop.log") || true
  else
    # Fallback: inline prompt if no CLAUDE.md found
    INLINE_PROMPT="Read prd.json and progress.txt. Pick the highest priority story where passes is false. Implement it, run quality checks, commit if passing, update prd.json to set passes: true, and append progress to progress.txt."
    OUTPUT=$(claude -p "$INLINE_PROMPT" --dangerously-skip-permissions 2>&1 | tee -a "$LOG_DIR/compound-loop.log") || true
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    log ""
    log "All tasks complete! (COMPLETE signal received)"
    log "Finished at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  log "Iteration $i complete. Continuing..."
  sleep 2
done

REMAINING=$(remaining)
if [ "$REMAINING" -eq 0 ]; then
  log ""
  log "=== All stories completed successfully ==="
  exit 0
else
  log ""
  log "Reached max iterations ($MAX_ITERATIONS). $REMAINING stories remaining."
  log "Check $PROGRESS_FILE for status."
  exit 1
fi
