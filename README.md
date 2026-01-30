# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs AI coding tools ([Amp](https://ampcode.com) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code)) repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

[Read my in-depth article on how I use Ralph](https://x.com/ryancarson/status/2008548371712135632)

## Prerequisites

- One of the following AI coding tools installed and authenticated:
  - [Amp CLI](https://ampcode.com) (default)
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

### Option 1: Copy to your project

Copy the ralph files into your project:

```bash
# From your project root
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/

# Copy the prompt template for your AI tool of choice:
cp /path/to/ralph/prompt.md scripts/ralph/prompt.md    # For Amp
# OR
cp /path/to/ralph/CLAUDE.md scripts/ralph/CLAUDE.md    # For Claude Code

chmod +x scripts/ralph/ralph.sh
```

### Option 2: Install skills globally

Copy the skills to your Amp or Claude config for use across all projects:

For AMP
```bash
cp -r skills/prd ~/.config/amp/skills/
cp -r skills/ralph ~/.config/amp/skills/
```

For Claude Code
```bash
cp -r skills/prd ~/.claude/skills/
cp -r skills/ralph ~/.claude/skills/
```

### Configure Amp auto-handoff (recommended)

Add to `~/.config/amp/settings.json`:

```json
{
  "amp.experimental.autoHandoff": { "context": 90 }
}
```

This enables automatic handoff when context fills up, allowing Ralph to handle large stories that exceed a single context window.

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
# Using Amp (default)
./scripts/ralph/ralph.sh [max_iterations]

# Using Claude Code
./scripts/ralph/ralph.sh --tool claude [max_iterations]
```

Default is 10 iterations. Use `--tool amp` or `--tool claude` to select your AI coding tool.

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh AI instances (supports `--tool amp` or `--tool claude`) |
| `prompt.md` | Prompt template for Amp |
| `CLAUDE.md` | Prompt template for Claude Code |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs |
| `skills/ralph/` | Skill for converting PRDs to JSON |
| `flowchart/` | Interactive visualization of how Ralph works |
| `scripts/compound/` | Compound nightly loop scripts (Claude Code) |
| `launchd/` | macOS scheduling templates for nightly automation |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)** - Click through to see each step with animations.

The `flowchart/` directory contains the source code. To run locally:

```bash
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new AI instance** (Amp or Claude Code) with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because AI coding tools automatically read these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories must include "Verify in browser using dev-browser skill" in acceptance criteria. Ralph will use the dev-browser skill to navigate to the page, interact with the UI, and confirm changes work.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Compound Nightly Loop (Claude Code)

Run Ralph automatically every night with compounding learnings. The system runs two jobs in sequence:

- **10:30 PM** - Compound Review: Reviews recent work, extracts learnings, updates CLAUDE.md files
- **11:00 PM** - Auto-Compound: Pulls latest (with fresh learnings), picks #1 priority from reports, implements it, creates a PR

The order matters. The review job updates your CLAUDE.md files with patterns and gotchas. The implementation job then benefits from those learnings.

### Quick Setup

```bash
./scripts/compound/setup.sh
```

This installs launchd agents (macOS) or prints cron instructions (Linux).

### Manual Setup

1. **Create a reports directory** with prioritized items:

```bash
mkdir -p reports
```

Add markdown files with prioritized features/bugs, e.g. `reports/2026-01-30-priorities.md`.

2. **Make scripts executable:**

```bash
chmod +x scripts/daily-compound-review.sh
chmod +x scripts/compound/auto-compound.sh
chmod +x scripts/compound/analyze-report.sh
chmod +x scripts/compound/loop.sh
```

3. **Test manually:**

```bash
# Run the compound review
./scripts/daily-compound-review.sh

# Run the full auto-compound pipeline
./scripts/compound/auto-compound.sh
```

4. **Schedule with launchd (macOS):**

```bash
./scripts/compound/setup.sh
```

Or with cron (Linux):

```bash
# Compound Review at 10:30 PM
30 22 * * * /path/to/project/scripts/daily-compound-review.sh /path/to/project

# Auto-Compound at 11:00 PM
0 23 * * * /path/to/project/scripts/compound/auto-compound.sh /path/to/project
```

### How It Works

Every night:

1. **10:30 PM** - Agent reviews recent git commits, finds missed learnings, updates CLAUDE.md files, pushes to main
2. **11:00 PM** - Agent pulls main (now with fresh context), picks the top priority from your reports, creates a PRD, breaks it into tasks, implements them, opens a draft PR

When you wake up, you have:
- Updated CLAUDE.md files with patterns your agent learned
- A draft PR implementing your next priority
- Logs showing exactly what happened

### Compound Scripts

| Script | Purpose |
|--------|---------|
| `scripts/daily-compound-review.sh` | Reviews recent work, extracts learnings into CLAUDE.md |
| `scripts/compound/auto-compound.sh` | Full pipeline: report -> PRD -> tasks -> implementation -> PR |
| `scripts/compound/analyze-report.sh` | Analyzes a report and picks the #1 priority item |
| `scripts/compound/loop.sh` | Execution loop (runs Claude Code iteratively on tasks) |
| `scripts/compound/setup.sh` | Installer for launchd agents (macOS) |
| `launchd/` | Plist templates for macOS scheduling |

### Uninstall

```bash
./scripts/compound/setup.sh --uninstall
```

## Debugging

Check current state:

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10

# Check compound nightly loop logs
tail -f logs/compound-review.log
tail -f logs/auto-compound.log
tail -f logs/compound-loop.log

# Verify launchd agents are loaded (macOS)
launchctl list | grep ralph

# Test compound scripts manually
launchctl start com.ralph.daily-compound-review
launchctl start com.ralph.auto-compound
```

## Customizing the Prompt

After copying `prompt.md` (for Amp) or `CLAUDE.md` (for Claude Code) to your project, customize it for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Amp documentation](https://ampcode.com/manual)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
