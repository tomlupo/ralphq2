#!/bin/bash
# Build-Test-Fix Loop
# Extends Ralph with automated testing and bug-fixing cycles.
#
# Usage: ./build-test-fix-loop.sh [deployment_url] [max_cycles]
#
# Each cycle:
#   1. Runs Ralph to build/fix stories
#   2. Tests the deployment for bugs
#   3. Converts bugs to new stories
#   4. Loops back to step 1

set -e

DEPLOYMENT_URL="${1:-http://localhost:3000}"
MAX_CYCLES="${2:-3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "============================================="
echo "  Build-Test-Fix Loop"
echo "============================================="
echo "  Deployment URL: $DEPLOYMENT_URL"
echo "  Max cycles:     $MAX_CYCLES"
echo "============================================="
echo ""

for cycle in $(seq 1 $MAX_CYCLES); do
  echo ""
  echo "============================================="
  echo "  Cycle $cycle of $MAX_CYCLES"
  echo "============================================="

  # Phase 1: Build with Ralph
  echo ""
  echo "--- Phase 1: Building with Ralph ---"
  "$SCRIPT_DIR/ralph.sh" --tool claude 50

  BUILD_EXIT=$?
  if [ $BUILD_EXIT -ne 0 ]; then
    echo "Ralph did not complete all stories. Checking remaining..."
    REMAINING=$(cat "$SCRIPT_DIR/prd.json" | jq '[.userStories[] | select(.passes == false)] | length')
    if [ "$REMAINING" -gt 0 ]; then
      echo "$REMAINING stories still incomplete. Continuing to test what we have..."
    fi
  fi

  # Phase 2: Test the deployment
  echo ""
  echo "--- Phase 2: Testing deployment ---"
  TEST_PROMPT="You are a QA tester. Test the application at $DEPLOYMENT_URL thoroughly.

For each bug found, report:
- Bug ID (BUG-001, BUG-002, etc.)
- Severity: Critical | High | Medium | Low
- Steps to reproduce
- Expected behavior
- Actual behavior

Save your bug report to tasks/bug-report-cycle-${cycle}.md

If no bugs are found, write 'NO BUGS FOUND' in the file."

  TEST_OUTPUT=$(echo "$TEST_PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true

  # Phase 3: Check for bugs
  BUG_REPORT="$SCRIPT_DIR/tasks/bug-report-cycle-${cycle}.md"
  if [ ! -f "$BUG_REPORT" ]; then
    echo "No bug report generated. Skipping bug-to-story conversion."
    continue
  fi

  if grep -q "NO BUGS FOUND" "$BUG_REPORT"; then
    echo ""
    echo "============================================="
    echo "  No bugs found! Build-Test-Fix complete."
    echo "============================================="
    exit 0
  fi

  # Count bugs by severity
  CRITICAL=$(grep -c "Critical" "$BUG_REPORT" 2>/dev/null || echo "0")
  HIGH=$(grep -c "High" "$BUG_REPORT" 2>/dev/null || echo "0")
  MEDIUM=$(grep -c "Medium" "$BUG_REPORT" 2>/dev/null || echo "0")
  LOW=$(grep -c "Low" "$BUG_REPORT" 2>/dev/null || echo "0")

  echo ""
  echo "Bugs found: Critical=$CRITICAL High=$HIGH Medium=$MEDIUM Low=$LOW"

  # Phase 4: Convert bugs to stories
  echo ""
  echo "--- Phase 4: Converting bugs to stories ---"
  CONVERT_PROMPT="Read the bug report at tasks/bug-report-cycle-${cycle}.md.

Convert each Critical and High severity bug into a user story and add it to prd.json.

For each bug story:
- ID: BF-${cycle}XX (e.g., BF-${cycle}01, BF-${cycle}02)
- Title: Fix: [bug title]
- Description: Bug fix from cycle $cycle testing
- Acceptance criteria: Steps to verify the fix
- Priority: Set higher than remaining feature stories
- passes: false

Add these new stories to the existing prd.json userStories array."

  CONVERT_OUTPUT=$(echo "$CONVERT_PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true

  echo "Cycle $cycle complete. Bug stories added to prd.json."
  sleep 2
done

echo ""
echo "============================================="
echo "  Build-Test-Fix reached max cycles ($MAX_CYCLES)"
echo "  Check prd.json and progress.txt for status."
echo "============================================="
exit 1
