---
name: prd
description: "Generate a Product Requirements Document (PRD) using BMAD method structured analysis. Use when planning a feature, starting a new project, or when asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

# PRD Generator (BMAD Method)

Create detailed Product Requirements Documents through structured discovery and analysis, following the BMAD (Breakthrough Method of Agile AI-Driven Development) approach.

---

## The Job

1. Receive a feature description from the user
2. Conduct a structured discovery interview (BMAD Phase 1)
3. Ask 3-5 essential clarifying questions (with lettered options)
4. Generate a structured PRD (BMAD Phase 2)
5. Save to `tasks/prd-[feature-name].md`

**Important:** Do NOT start implementing. Create only the PRD. A QRD (Quality Requirements Document) should be created separately using the `qrd` skill.

---

## Step 1: Discovery Interview (BMAD Phase 1)

Before writing requirements, conduct a brief structured discovery. Ask the user about:

- **Problem Statement:** What specific problem does this solve? Who has this problem today?
- **Target Users:** Who will use this? What is their technical level?
- **Core Value Proposition:** What is the single most important thing this feature does?
- **Success Criteria:** How will we know this feature is successful?
- **Scope Boundaries:** What should this explicitly NOT do?

Keep the interview focused. 3-5 questions maximum.

---

## Step 2: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Format with lettered options for quick responses:

```
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
   D. Other: [please specify]

2. Who is the target user?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the scope?
   A. Minimal viable version
   B. Full-featured implementation
   C. Just the backend/API
   D. Just the UI
```

This lets users respond with "1A, 2C, 3B" for quick iteration.

---

## Step 3: PRD Structure

Generate the PRD with these sections:

### 1. Introduction/Overview
Brief description of the feature and the problem it solves. Include context from the discovery interview.

### 2. Goals
Specific, measurable objectives (bullet list). Each goal should be verifiable.

### 3. User Stories
Each story needs:
- **Title:** Short descriptive name
- **Description:** "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist of what "done" means

Each story should be small enough to implement in one focused session.

**Format:**
```markdown
### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck/lint passes
- [ ] **[UI stories only]** Verify in browser using dev-browser skill
```

**Story sizing rules:**
- If you cannot describe the change in 2-3 sentences, it is too big
- Each story should touch at most 3 files
- Schema, backend, and UI changes should be separate stories

**Dependency ordering:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**Acceptance criteria rules:**
- Must be verifiable, not vague. "Works correctly" is bad. "Button shows confirmation dialog before deleting" is good
- Always include "Typecheck passes" for every story
- For UI stories: Always include "Verify in browser using dev-browser skill"
- For data/logic stories: Include "Unit tests cover happy path and error cases"

### 4. Functional Requirements
Numbered list of specific functionalities:
- "FR-1: The system must allow users to..."
- "FR-2: When a user clicks X, the system must..."

Be explicit and unambiguous.

### 5. Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope.

### 6. Design Considerations (Optional)
- UI/UX requirements
- Link to mockups if available
- Relevant existing components to reuse

### 7. Technical Considerations (Optional)
- Known constraints or dependencies
- Integration points with existing systems
- Performance requirements

### 8. Success Metrics
How will success be measured? Each metric should be quantifiable.

### 9. Open Questions
Remaining questions or areas needing clarification.

---

## Writing for Autonomous Agents

The PRD reader may be an AI agent (like Ralph) or a junior developer. Therefore:

- Be explicit and unambiguous
- Avoid jargon or explain it
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples where helpful
- Specify exact field names, types, and values where possible

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

---

## Example PRD

```markdown
# PRD: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering to help users manage their workload effectively.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering and sorting by priority
- Default new tasks to medium priority

## User Stories

### US-001: Add priority field to database
**Description:** As a developer, I need to store task priority so it persists across sessions.

**Acceptance Criteria:**
- [ ] Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Generate and run migration successfully
- [ ] Typecheck passes

### US-002: Display priority indicator on task cards
**Description:** As a user, I want to see task priority at a glance so I know what needs attention first.

**Acceptance Criteria:**
- [ ] Each task card shows colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Priority visible without hovering or clicking
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-003: Add priority selector to task edit
**Description:** As a user, I want to change a task's priority when editing it.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves immediately on selection change
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-004: Filter tasks by priority
**Description:** As a user, I want to filter the task list to see only high-priority items when I'm focused.

**Acceptance Criteria:**
- [ ] Filter dropdown with options: All | High | Medium | Low
- [ ] Filter persists in URL params
- [ ] Empty state message when no tasks match filter
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: Add `priority` field to tasks table ('high' | 'medium' | 'low', default 'medium')
- FR-2: Display colored priority badge on each task card
- FR-3: Include priority selector in task edit modal
- FR-4: Add priority filter dropdown to task list header
- FR-5: Sort by priority within each status column (high to medium to low)

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params
- Priority stored in database, not computed

## Success Metrics

- Users can change priority in under 2 clicks
- High-priority tasks immediately visible at top of lists
- No regression in task list performance

## Open Questions

- Should priority affect task ordering within a column?
- Should we add keyboard shortcuts for priority changes?
```

---

## Next Steps After PRD

After creating the PRD, the recommended workflow is:

1. **Create QRD:** Use the `qrd` skill to define quality requirements
2. **Analyze Edge Cases:** Use the `edge-cases` skill to find risks
3. **Validate Stories:** Use the `story-quality` skill to check story quality
4. **Convert to JSON:** Use the `ralph` skill to create `prd.json`

---

## Checklist

Before saving the PRD:

- [ ] Conducted discovery interview
- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] User stories are small and specific (one context window each)
- [ ] Stories are ordered by dependency (schema → backend → UI)
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] All stories include "Typecheck passes"
- [ ] UI stories include "Verify in browser using dev-browser skill"
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] Saved to `tasks/prd-[feature-name].md`
