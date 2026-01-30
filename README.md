# Ralph + BMAD QRD Loop

![Ralph](ralph.webp)

An autonomous AI agent loop that combines the **BMAD method** (structured discovery and planning), **QRD** (quality requirements documents), and **Ralph** (iterative execution loop) to build software features end-to-end.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/), enhanced with [BMAD method](https://github.com/tomlupo/bmad-method-quant) structured analysis and QRD quality validation.

## What's Different

This version adds three key improvements over the standard Ralph loop:

1. **BMAD-style structured planning** - Discovery interview, structured PRD creation, and architecture phases before any code is written
2. **QRD (Quality Requirements Document)** - Defines quality gates, non-functional requirements, edge cases, and validation criteria that Ralph enforces at every iteration
3. **Build-Test-Fix cycle** - Extended loop that tests the deployment, finds bugs, converts them to stories, and fixes them automatically

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- `jq` installed (`brew install jq` on macOS, `apt install jq` on Linux)
- A git repository for your project

Optional:
- [Amp CLI](https://ampcode.com) (alternative to Claude Code)

## Quick Start

### 1. Copy to your project

```bash
# From your project root
mkdir -p scripts/ralph
cp -r /path/to/ralph/* scripts/ralph/
chmod +x scripts/ralph/ralph.sh scripts/ralph/build-test-fix-loop.sh
```

Or install skills globally:

```bash
# For Claude Code
cp -r skills/* ~/.claude/skills/

# For Amp
cp -r skills/* ~/.config/amp/skills/
```

### 2. Run the guided workflow

Start Claude Code and it will walk you through 10 phases:

```bash
claude
```

Claude reads `CLAUDE.md` and guides you through:
- Phase 0: Setup check
- Phase 1: Discovery interview (BMAD Analyst)
- Phase 2: PRD creation (BMAD PM)
- Phase 3: QRD creation (Quality Engineer)
- Phase 4: Edge case analysis
- Phase 5: Story quality validation
- Phase 6: Architecture (optional)
- Phase 7: Convert to JSON
- Phase 8: Push to git
- Phase 9: Start autonomous build
- Phase 10: Monitor and iterate

### 3. Or run Ralph directly

If you already have a `prd.json`:

```bash
# Using Claude Code (default)
./ralph.sh [max_iterations]

# Using Amp
./ralph.sh --tool amp [max_iterations]
```

Default is 100 iterations.

### 4. Extended build-test-fix cycle

```bash
./build-test-fix-loop.sh http://localhost:3000 3
```

## How It Works

### Planning Phase (Human-Guided)

```
Phase 1: Discovery Interview  -->  Understand the problem
Phase 2: Create PRD           -->  tasks/prd-[name].md
Phase 3: Create QRD           -->  tasks/qrd-[name].md
Phase 4: Edge Cases           -->  Updated QRD
Phase 5: Story Validation     -->  Validated PRD
Phase 6: Architecture         -->  tasks/architecture-[name].md (optional)
Phase 7: Convert to JSON      -->  prd.json (with QRD integration)
```

### Execution Phase (Autonomous)

```
ralph.sh
  |
  +-- Iteration 1: Read prd.json + QRD -> Pick story -> Implement -> Validate -> Commit
  +-- Iteration 2: Read prd.json + QRD -> Pick story -> Implement -> Validate -> Commit
  +-- ...
  +-- Iteration N: All stories pass -> COMPLETE
```

Each iteration:
1. Reads `prd.json` to find the next story (`passes: false`)
2. Reads `progress.txt` for learnings from previous iterations
3. Reads the QRD for quality requirements and edge cases
4. Implements the story
5. Runs quality checks (typecheck, lint, test, build)
6. Validates against QRD quality gates
7. Commits and marks the story as passing
8. Appends learnings to `progress.txt`

### Build-Test-Fix Cycle

```
build-test-fix-loop.sh
  |
  +-- Cycle 1: Build -> Test -> Find bugs -> Convert to stories
  +-- Cycle 2: Build -> Test -> Find bugs -> Convert to stories
  +-- Cycle 3: Build -> Test -> No bugs -> Done!
```

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Main workflow instructions (10 phases for Claude Code) |
| `prompt.md` | Agent instructions for Amp |
| `ralph.sh` | The autonomous build loop |
| `build-test-fix-loop.sh` | Extended build-test-fix cycle |
| `prompts/ralph-agent.md` | Instructions piped into Claude each iteration |
| `prd.json` | User stories with `passes` status (generated) |
| `progress.txt` | Append-only learnings (generated) |

### Skills

| Skill | Purpose |
|-------|---------|
| `skills/prd/` | Generate PRDs with BMAD structured analysis |
| `skills/qrd/` | Generate Quality Requirements Documents |
| `skills/ralph/` | Convert PRDs + QRDs to `prd.json` |
| `skills/edge-cases/` | Analyze PRDs for edge cases and risks |
| `skills/story-quality/` | Validate story quality before execution |

### Templates

| Template | Purpose |
|----------|---------|
| `templates/prd.json.example` | Example `prd.json` with QRD integration |
| `templates/qrd.md.example` | Example QRD document |

## The QRD (Quality Requirements Document)

The QRD is the key addition in this version. It defines:

- **Quality Attributes** - Non-functional requirements (correctness, performance, reliability, security)
- **Quality Gates** - Checkpoints that must pass for every story (static analysis, testing, integration)
- **Validation Criteria Patterns** - Reusable acceptance criteria by story type
- **Edge Case & Risk Register** - Known edge cases with severity and mitigations
- **Definition of Done** - Checklist applied to every story

The QRD is created during Phase 3 and its quality gates are injected into `prd.json` during conversion. Ralph reads the QRD at each iteration and validates implementation against these requirements.

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new AI instance** with clean context. Memory persists only through:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and patterns)
- `prd.json` (which stories are done)
- QRD file (quality requirements)

### Small Tasks

Each story must be completable in one context window. If too big, the LLM runs out of context.

Right-sized: Add a column, add a component, update a server action, add a filter.

Too big: "Build the dashboard", "Add authentication", "Refactor the API".

### Quality Feedback Loops

Ralph validates at every iteration:
- Typecheck catches type errors
- Tests verify behavior
- Linter enforces style
- QRD gates enforce quality standards
- Edge case criteria prevent known risks

### Notifications

Configure push notifications via [ntfy.sh](https://ntfy.sh):

```bash
echo 'NTFY_TOPIC="ralph-my-project-'$(openssl rand -hex 4)'"' > .notify-config
```

Install the ntfy app on your phone and subscribe to the topic.

### Stop Condition

When all stories have `passes: true`, Ralph outputs the completion signal and the loop exits.

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

The `flowchart/` directory contains an interactive visualization. To run locally:

```bash
cd flowchart && npm install && npm run dev
```

## Debugging

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See remaining stories
cat prd.json | jq '[.userStories[] | select(.passes == false)] | length'

# See quality gates
cat prd.json | jq '.qualityGates'

# See learnings
cat progress.txt

# See recent commits
git log --oneline -10

# Follow Ralph in real-time
tail -f ralph.log
```

## Archiving

Ralph automatically archives previous runs when the branch name changes. Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [BMAD Method (Quant)](https://github.com/tomlupo/bmad-method-quant) - Structured AI-driven development
- [Claude Build Workflow](https://github.com/rohunj/claude-build-workflow) - Original enhanced Ralph workflow
- [Geoffrey Huntley's Ralph](https://ghuntley.com/ralph/) - The original Ralph pattern
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - Anthropic's CLI
- [Amp](https://ampcode.com) - Alternative AI coding tool
