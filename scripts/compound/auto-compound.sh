#!/bin/bash
# auto-compound.sh - Claude Code version
#
# Full pipeline: report -> PRD -> tasks -> implementation -> PR
#
# Runs AFTER daily-compound-review.sh so that CLAUDE.md files contain
# the latest learnings before implementation begins.
#
# Usage: ./scripts/compound/auto-compound.sh [project_dir]
#
# Prerequisites:
# - Claude Code installed: npm install -g @anthropic-ai/claude-code
# - jq installed: brew install jq
# - gh CLI installed and authenticated: brew install gh
# - A reports/ directory with prioritized markdown reports
#
# Based on Ryan Carson's compound engineering workflow:
# https://x.com/ryancarson/status/2016520542723924279

set -e

# Project directory (default: current directory)
PROJECT_DIR="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/auto-compound.log"
}

log "=== Starting Auto-Compound Pipeline ==="
log "Project: $PROJECT_DIR"

cd "$PROJECT_DIR"

# Source environment if available
if [ -f ".env.local" ]; then
  source .env.local
fi

# Step 1: Fetch latest (including tonight's CLAUDE.md updates from review)
log "Step 1: Fetching latest from main..."
git fetch origin main 2>/dev/null || git fetch origin master 2>/dev/null || {
  log "WARNING: Could not fetch. Continuing with local state."
}
git checkout main 2>/dev/null || git checkout master 2>/dev/null
git reset --hard "origin/$(git branch --show-current)" || {
  log "WARNING: Could not reset to remote. Using local state."
}

# Step 2: Find the latest prioritized report
log "Step 2: Finding latest prioritized report..."
if [ ! -d "reports" ]; then
  log "ERROR: No reports/ directory found. Create reports with prioritized items."
  log "Example: reports/2026-01-30-priorities.md"
  exit 1
fi

LATEST_REPORT=$(ls -t reports/*.md 2>/dev/null | head -1)
if [ -z "$LATEST_REPORT" ]; then
  log "ERROR: No report files found in reports/"
  exit 1
fi
log "Using report: $LATEST_REPORT"

# Step 3: Analyze report and pick #1 priority
log "Step 3: Analyzing report for top priority..."
ANALYSIS=$("$SCRIPT_DIR/analyze-report.sh" "$LATEST_REPORT") || {
  log "ERROR: Report analysis failed"
  exit 1
}

PRIORITY_ITEM=$(echo "$ANALYSIS" | jq -r '.priority_item')
BRANCH_NAME=$(echo "$ANALYSIS" | jq -r '.branch_name')

if [ -z "$PRIORITY_ITEM" ] || [ "$PRIORITY_ITEM" = "null" ]; then
  log "ERROR: Could not extract priority item from analysis"
  log "Analysis output: $ANALYSIS"
  exit 1
fi

log "Priority item: $PRIORITY_ITEM"
log "Branch: $BRANCH_NAME"

# Step 4: Create feature branch
log "Step 4: Creating feature branch..."
git checkout -b "$BRANCH_NAME" 2>/dev/null || {
  # Branch might already exist
  git checkout "$BRANCH_NAME" 2>/dev/null || {
    log "ERROR: Could not create or checkout branch: $BRANCH_NAME"
    exit 1
  }
}

# Step 5: Create PRD using Claude Code
log "Step 5: Creating PRD..."
mkdir -p tasks

PRD_PROMPT="You are a product requirements document generator.

Create a detailed PRD for this feature: $PRIORITY_ITEM

Follow these rules:
1. Break it into small user stories (each completable in one context window)
2. Order stories by dependency (schema -> backend -> UI)
3. Each story needs verifiable acceptance criteria
4. Always include 'Typecheck passes' as a criterion
5. For UI stories, include 'Verify in browser' as a criterion

Save the PRD to tasks/prd-$(echo "$BRANCH_NAME" | sed 's|compound/||').md

Format it as a proper markdown PRD with:
- Introduction/Overview
- Goals
- User Stories (US-001, US-002, etc.)
- Functional Requirements
- Non-Goals
- Technical Considerations"

claude -p "$PRD_PROMPT" --dangerously-skip-permissions >> "$LOG_DIR/auto-compound.log" 2>&1 || {
  log "WARNING: PRD creation may have had issues. Checking..."
}

# Step 6: Convert PRD to prd.json using Claude Code
log "Step 6: Converting PRD to prd.json..."

PRD_FILE=$(ls -t tasks/prd-*.md 2>/dev/null | head -1)
if [ -z "$PRD_FILE" ]; then
  log "ERROR: No PRD file found in tasks/"
  exit 1
fi

CONVERT_PROMPT="Convert this PRD to prd.json format for the Ralph autonomous agent system.

Read the PRD at: $PRD_FILE

Output prd.json with this structure:
{
  \"project\": \"[Project Name]\",
  \"branchName\": \"$BRANCH_NAME\",
  \"description\": \"[Feature description]\",
  \"userStories\": [
    {
      \"id\": \"US-001\",
      \"title\": \"[Story title]\",
      \"description\": \"As a [user], I want [feature] so that [benefit]\",
      \"acceptanceCriteria\": [\"Criterion 1\", \"Typecheck passes\"],
      \"priority\": 1,
      \"passes\": false,
      \"notes\": \"\"
    }
  ]
}

Rules:
- Each story must be completable in ONE iteration (small enough)
- Stories ordered by dependency
- Every story has 'Typecheck passes' as a criterion
- UI stories have 'Verify in browser' as a criterion
- All stories start with passes: false
- Save to prd.json in the project root"

claude -p "$CONVERT_PROMPT" --dangerously-skip-permissions >> "$LOG_DIR/auto-compound.log" 2>&1 || {
  log "WARNING: PRD conversion may have had issues. Checking..."
}

if [ ! -f "prd.json" ]; then
  log "ERROR: prd.json was not created"
  exit 1
fi

log "prd.json created with $(jq '.userStories | length' prd.json) stories"

# Step 7: Run the execution loop
log "Step 7: Running execution loop..."
"$SCRIPT_DIR/loop.sh" 25 "$PROJECT_DIR" || {
  log "WARNING: Loop exited with remaining tasks. Check progress.txt"
}

# Step 8: Push and create PR
log "Step 8: Creating PR..."
git push -u origin "$BRANCH_NAME" 2>/dev/null || {
  log "WARNING: Push failed. Retrying..."
  sleep 2
  git push -u origin "$BRANCH_NAME" 2>/dev/null || {
    sleep 4
    git push -u origin "$BRANCH_NAME" 2>/dev/null || {
      log "ERROR: Could not push to remote after retries"
      exit 1
    }
  }
}

# Create draft PR
STORIES_DONE=$(jq '[.userStories[] | select(.passes == true)] | length' prd.json 2>/dev/null || echo "?")
STORIES_TOTAL=$(jq '.userStories | length' prd.json 2>/dev/null || echo "?")

PR_BODY="## Summary
- Implements: $PRIORITY_ITEM
- Stories completed: $STORIES_DONE / $STORIES_TOTAL
- Source report: $LATEST_REPORT

## What Changed
$(git log main.."$BRANCH_NAME" --oneline 2>/dev/null || echo "See commits")

## Auto-Compound
This PR was automatically generated by the compound nightly loop.
Review the changes and merge when ready."

gh pr create \
  --draft \
  --title "Compound: $PRIORITY_ITEM" \
  --body "$PR_BODY" \
  --base main 2>/dev/null || {
  log "WARNING: Could not create PR. You may need to create it manually."
  log "Branch: $BRANCH_NAME"
}

log "=== Auto-Compound Pipeline Complete ==="
log "Branch: $BRANCH_NAME"
log "Stories: $STORIES_DONE / $STORIES_TOTAL complete"
