# Ralph + BMAD QRD Agent System

## Overview

Ralph is an autonomous AI agent loop that uses structured planning (BMAD method) and quality validation (QRD) to build software features. Each iteration is a fresh instance with clean context.

## Workflow Phases

| Phase | Role | Output |
|-------|------|--------|
| Discovery | BMAD Analyst | Problem understanding |
| PRD | BMAD PM | `tasks/prd-[name].md` |
| QRD | Quality Engineer | `tasks/qrd-[name].md` |
| Edge Cases | Risk Analyst | Updated QRD |
| Story Validation | Quality Gate | Validated PRD |
| Architecture | Architect (optional) | `tasks/architecture-[name].md` |
| JSON Conversion | Ralph Converter | `prd.json` |
| Build Loop | Ralph Agent | Implemented features |

## Commands

```bash
# Run Ralph with Claude Code (default)
./ralph.sh [max_iterations]

# Run Ralph with Amp
./ralph.sh --tool amp [max_iterations]

# Run build-test-fix cycle
./build-test-fix-loop.sh [deployment_url] [max_cycles]

# Run flowchart dev server
cd flowchart && npm run dev
```

## Key Files

- `CLAUDE.md` - Main workflow (10 phases, guides user through planning + launch)
- `ralph.sh` - Autonomous build loop (default: Claude Code, 100 iterations)
- `build-test-fix-loop.sh` - Extended build-test-fix cycle
- `prompts/ralph-agent.md` - Agent instructions for each iteration (Claude)
- `prompt.md` - Agent instructions for each iteration (Amp)
- `prd.json` - Task list with story status and quality gates (generated)
- `progress.txt` - Append-only learnings log (generated)

## Skills

- `skills/prd/` - PRD generation (BMAD structured analysis + discovery interview)
- `skills/qrd/` - QRD generation (quality requirements, gates, edge cases, validation patterns)
- `skills/ralph/` - PRD-to-JSON conversion with QRD integration
- `skills/edge-cases/` - Edge case analysis (7 categories, min 5 findings)
- `skills/story-quality/` - Story quality validation (5 checks: size, deps, criteria, QRD, completeness)

## Templates

- `templates/prd.json.example` - Example prd.json with QRD fields
- `templates/qrd.md.example` - Example Quality Requirements Document

## Patterns

- Each iteration spawns a fresh AI instance with clean context
- Memory persists via git history, `progress.txt`, `prd.json`, and QRD
- Stories must be small enough for one context window
- QRD quality gates apply to every story automatically
- Always update CLAUDE.md/AGENTS.md with discovered patterns for future iterations
- Quality validation order: typecheck -> lint -> test -> build -> QRD edge cases
- Notifications via ntfy.sh (configure in `.notify-config`)
