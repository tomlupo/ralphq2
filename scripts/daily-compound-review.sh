#!/bin/bash
# daily-compound-review.sh - Claude Code version
#
# Runs BEFORE auto-compound.sh to update CLAUDE.md with learnings.
# Reviews recent Claude Code sessions and extracts patterns, gotchas,
# and context into CLAUDE.md files so the next implementation run
# benefits from today's learnings.
#
# Usage: ./scripts/daily-compound-review.sh [project_dir]
#
# Based on Ryan Carson's compound engineering workflow:
# https://x.com/ryancarson/status/2016520542723924279

set -e

# Project directory (default: current directory)
PROJECT_DIR="${1:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/logs"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/compound-review.log"
}

log "=== Starting Compound Review ==="
log "Project: $PROJECT_DIR"

cd "$PROJECT_DIR"

# Ensure we're on main and up to date
log "Checking out main and pulling latest..."
git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
  log "ERROR: Could not checkout main or master branch"
  exit 1
}
git pull origin "$(git branch --show-current)" || {
  log "WARNING: Could not pull latest. Continuing with local state."
}

# Build the compound review prompt for Claude Code
REVIEW_PROMPT="You are reviewing recent work sessions to extract and persist learnings.

Your task:
1. Look at the git log from the last 24 hours: git log --since='24 hours ago' --oneline --all
2. For each recent commit, review the changes: git diff <commit>^..<commit>
3. Read any existing CLAUDE.md files in directories that were modified
4. Read progress.txt if it exists for recent learnings

For any work where learnings were NOT already captured in CLAUDE.md files:
- Extract key patterns discovered (e.g., 'this codebase uses X for Y')
- Note gotchas encountered (e.g., 'don't forget to update Z when changing W')
- Document useful context (e.g., 'the settings panel is in component X')
- Add API patterns or conventions specific to modified modules
- Note dependencies between files that aren't obvious

Update the relevant CLAUDE.md files with these learnings. If a directory doesn't have a CLAUDE.md, create one only if there are substantial learnings worth preserving.

Rules:
- Only add genuinely reusable knowledge, not story-specific details
- Keep entries concise and actionable
- Don't duplicate information already in CLAUDE.md files
- Don't add temporary debugging notes

After updating, commit your changes with message: 'chore: compound review - extract learnings from recent sessions'
Then push to the current branch."

log "Running Claude Code compound review..."

# Run Claude Code with the review prompt
OUTPUT=$(claude -p "$REVIEW_PROMPT" --dangerously-skip-permissions 2>&1 | tee -a "$LOG_DIR/compound-review.log") || true

# Check if changes were made
if git diff --quiet && git diff --cached --quiet; then
  log "No new learnings to extract. CLAUDE.md files are up to date."
else
  log "Compound review complete. CLAUDE.md files updated."
fi

log "=== Compound Review Finished ==="
