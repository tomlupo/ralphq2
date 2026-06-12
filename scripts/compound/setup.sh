#!/bin/bash
# setup.sh - Install the compound nightly loop for Claude Code
#
# This script:
# 1. Makes all scripts executable
# 2. Creates the logs/ and reports/ directories
# 3. Installs launchd plist files (macOS) with your project path
# 4. Loads the launch agents
#
# Usage: ./scripts/compound/setup.sh [project_dir]
#
# To uninstall: ./scripts/compound/setup.sh --uninstall

set -e

PROJECT_DIR="${1:-$(pwd)}"
HOME_DIR="$HOME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHD_SRC="$SCRIPT_DIR/../../launchd"
LAUNCHD_DEST="$HOME/Library/LaunchAgents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

# Handle uninstall
if [ "$1" = "--uninstall" ]; then
  info "Uninstalling compound nightly loop..."

  AGENTS=("com.ralph.daily-compound-review" "com.ralph.auto-compound" "com.ralph.caffeinate")
  for agent in "${AGENTS[@]}"; do
    if launchctl list | grep -q "$agent" 2>/dev/null; then
      launchctl unload "$LAUNCHD_DEST/$agent.plist" 2>/dev/null || true
      info "Unloaded $agent"
    fi
    if [ -f "$LAUNCHD_DEST/$agent.plist" ]; then
      rm "$LAUNCHD_DEST/$agent.plist"
      info "Removed $agent.plist"
    fi
  done

  info "Uninstall complete."
  exit 0
fi

echo ""
echo "============================================"
echo "  Ralph Compound Nightly Loop - Setup"
echo "  Claude Code Version"
echo "============================================"
echo ""
info "Project directory: $PROJECT_DIR"
echo ""

# Check prerequisites
info "Checking prerequisites..."

if ! command -v claude &> /dev/null; then
  error "Claude Code not found. Install it:"
  echo "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi
info "Claude Code: $(claude --version 2>/dev/null || echo 'found')"

if ! command -v jq &> /dev/null; then
  error "jq not found. Install it:"
  echo "  brew install jq"
  exit 1
fi
info "jq: found"

if ! command -v gh &> /dev/null; then
  warn "gh CLI not found. PR creation will be skipped."
  warn "Install: brew install gh"
else
  info "gh CLI: found"
fi

if ! command -v git &> /dev/null; then
  error "git not found."
  exit 1
fi
info "git: found"

echo ""

# Step 1: Make scripts executable
info "Making scripts executable..."
chmod +x "$SCRIPT_DIR/auto-compound.sh"
chmod +x "$SCRIPT_DIR/analyze-report.sh"
chmod +x "$SCRIPT_DIR/loop.sh"
chmod +x "$SCRIPT_DIR/../daily-compound-review.sh"

# Step 2: Create directories
info "Creating directories..."
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/reports"

if [ ! -f "$PROJECT_DIR/reports/.gitkeep" ]; then
  touch "$PROJECT_DIR/reports/.gitkeep"
fi

# Step 3: Check if we're on macOS for launchd
if [[ "$(uname)" != "Darwin" ]]; then
  warn "Not on macOS. Skipping launchd setup."
  warn "For Linux, use cron instead. Add these to your crontab (crontab -e):"
  echo ""
  echo "  # Compound Review at 10:30 PM"
  echo "  30 22 * * * $PROJECT_DIR/scripts/daily-compound-review.sh $PROJECT_DIR >> $PROJECT_DIR/logs/compound-review.log 2>&1"
  echo ""
  echo "  # Auto-Compound at 11:00 PM"
  echo "  0 23 * * * $PROJECT_DIR/scripts/compound/auto-compound.sh $PROJECT_DIR >> $PROJECT_DIR/logs/auto-compound.log 2>&1"
  echo ""
  info "Setup complete (without scheduling)."
  exit 0
fi

# Step 4: Install launchd plists
info "Installing launchd agents..."
mkdir -p "$LAUNCHD_DEST"

PLIST_FILES=("com.ralph.daily-compound-review" "com.ralph.auto-compound" "com.ralph.caffeinate")

for plist in "${PLIST_FILES[@]}"; do
  SRC="$LAUNCHD_SRC/$plist.plist"
  DEST="$LAUNCHD_DEST/$plist.plist"

  if [ ! -f "$SRC" ]; then
    warn "Template not found: $SRC"
    continue
  fi

  # Unload existing if present
  if launchctl list | grep -q "$plist" 2>/dev/null; then
    launchctl unload "$DEST" 2>/dev/null || true
  fi

  # Copy and substitute paths
  sed -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
      -e "s|__HOME_DIR__|$HOME_DIR|g" \
      "$SRC" > "$DEST"

  # Load the agent
  launchctl load "$DEST"
  info "Loaded: $plist"
done

echo ""

# Step 5: Verify
info "Verifying launch agents..."
for plist in "${PLIST_FILES[@]}"; do
  if launchctl list | grep -q "$plist" 2>/dev/null; then
    info "  $plist: loaded"
  else
    warn "  $plist: NOT loaded (check $LAUNCHD_DEST/$plist.plist)"
  fi
done

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
info "Schedule:"
echo "  10:30 PM - Compound Review (extracts learnings into CLAUDE.md)"
echo "  11:00 PM - Auto-Compound (implements top priority, creates PR)"
echo "   5:00 PM - Caffeinate (keeps Mac awake until 2 AM)"
echo ""
info "Next steps:"
echo "  1. Add prioritized reports to: $PROJECT_DIR/reports/"
echo "     Example: reports/2026-01-30-priorities.md"
echo "  2. Check logs at: $PROJECT_DIR/logs/"
echo "  3. Test manually:"
echo "     launchctl start com.ralph.daily-compound-review"
echo "     launchctl start com.ralph.auto-compound"
echo ""
info "To uninstall:"
echo "  ./scripts/compound/setup.sh --uninstall"
echo ""
