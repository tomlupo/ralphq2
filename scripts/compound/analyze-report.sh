#!/bin/bash
# analyze-report.sh - Analyze a prioritized report and extract the #1 priority item
#
# Usage: ./scripts/compound/analyze-report.sh <report_file>
# Output: JSON with priority_item and branch_name
#
# Expected report format: Markdown with numbered/prioritized items.
# The script uses Claude Code to analyze the report and pick the top item.

set -e

REPORT_FILE="$1"

if [ -z "$REPORT_FILE" ] || [ ! -f "$REPORT_FILE" ]; then
  echo '{"error": "Report file not found: '"$REPORT_FILE"'"}' >&2
  exit 1
fi

REPORT_CONTENT=$(cat "$REPORT_FILE")

# Use Claude Code to analyze the report and output structured JSON
ANALYSIS_PROMPT="Analyze this prioritized report and extract the #1 highest priority item that has NOT been implemented yet.

Check the git log and existing PRs to see what has already been done:
- git log --oneline -20
- Check for any open PRs if gh CLI is available

Report content:
---
$REPORT_CONTENT
---

Output ONLY valid JSON (no markdown fences, no explanation) in this exact format:
{
  \"priority_item\": \"A clear, concise description of the #1 priority item to implement\",
  \"branch_name\": \"compound/short-kebab-case-name\",
  \"report_file\": \"$(basename "$REPORT_FILE")\"
}

Rules:
- Pick the highest priority item that hasn't been implemented
- The branch_name should be descriptive but short (3-5 words, kebab-case)
- The priority_item description should be detailed enough to create a PRD from"

OUTPUT=$(claude -p "$ANALYSIS_PROMPT" --dangerously-skip-permissions 2>/dev/null) || {
  echo '{"error": "Claude Code analysis failed"}' >&2
  exit 1
}

# Extract just the JSON from the output (in case there's extra text)
echo "$OUTPUT" | grep -o '{.*}' | head -1
