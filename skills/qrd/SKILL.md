---
name: qrd
description: "Generate a Quality Requirements Document (QRD) that defines quality gates, non-functional requirements, and validation criteria. Use after a PRD exists and before converting to prd.json. Triggers on: create qrd, quality requirements, define quality gates, qrd for."
---

# QRD Generator (Quality Requirements Document)

Create a Quality Requirements Document that defines measurable quality standards, validation gates, and non-functional requirements for a project. The QRD complements the PRD by specifying HOW WELL the system must perform, not just WHAT it must do.

---

## The Job

1. Read the existing PRD (from `tasks/prd-[feature-name].md`)
2. Analyze the project for quality dimensions that matter
3. Ask 2-4 clarifying questions about quality priorities
4. Generate a structured QRD
5. Save to `tasks/qrd-[feature-name].md`

**Important:** The QRD is a companion to the PRD. Do NOT duplicate functional requirements. Focus on quality attributes, validation criteria, and gates.

---

## Step 1: Analyze the PRD

Before asking questions, read the PRD and identify:

- **Domain type:** Is this a data pipeline, UI feature, API, algorithm, etc.?
- **Risk areas:** What could go wrong? Data corruption? Performance degradation? Security breach?
- **Complexity level:** Simple CRUD vs. complex business logic vs. quantitative/analytical workload
- **Integration points:** External APIs, databases, third-party services

---

## Step 2: Clarifying Questions

Ask 2-4 targeted questions based on analysis. Focus on quality trade-offs:

```
1. What is the most critical quality attribute?
   A. Correctness / data accuracy (zero tolerance for errors)
   B. Performance / latency (must respond within strict time bounds)
   C. Reliability / uptime (must not fail or lose data)
   D. Security / compliance (handles sensitive data or regulated domain)
   E. Maintainability (long-lived codebase, many contributors)

2. What is the expected scale?
   A. Small (< 1K records, < 10 users)
   B. Medium (1K-100K records, 10-100 users)
   C. Large (100K+ records, 100+ users)
   D. Not applicable (library, CLI tool, etc.)

3. What is the testing priority?
   A. Unit tests for business logic
   B. Integration tests for data flows
   C. End-to-end tests for user workflows
   D. All of the above with coverage targets
```

---

## Step 3: QRD Structure

Generate the QRD with these sections:

### 1. Quality Overview

Brief summary of the project's quality priorities and risk profile. Reference the PRD by name.

### 2. Quality Attributes (Non-Functional Requirements)

Only include attributes relevant to the project. Each must follow the pattern:

> **The system shall** [metric] [condition] [measurement method]

**Common attributes (include only what applies):**

#### Correctness
- Data accuracy requirements (e.g., "calculations must match reference implementation within 1e-10 tolerance")
- Input validation rules
- Output format guarantees

#### Performance
- Response time targets (e.g., "API responds within 200ms at P95")
- Throughput requirements (e.g., "processes 1000 records/second")
- Resource limits (memory, CPU, disk)

#### Reliability
- Error handling requirements (e.g., "graceful degradation on external API failure")
- Data durability (e.g., "no data loss on process crash")
- Recovery time objectives

#### Security
- Authentication/authorization requirements
- Data protection (encryption at rest/transit)
- Input sanitization rules

#### Maintainability
- Code organization requirements
- Documentation standards
- Dependency management rules

### 3. Quality Gates

Define checkpoints that must pass before code is considered complete. These are injected into every user story's acceptance criteria.

```markdown
#### Gate 1: Static Analysis
- [ ] TypeScript strict mode passes (no `any` types unless explicitly justified)
- [ ] Linter passes with zero warnings
- [ ] No TODO/FIXME/HACK comments in committed code

#### Gate 2: Testing
- [ ] Unit tests cover all business logic functions
- [ ] Tests use meaningful assertions (not just "does not throw")
- [ ] Edge cases from QRD Section 5 are covered

#### Gate 3: Integration
- [ ] All existing tests pass (no regressions)
- [ ] Build completes successfully
- [ ] Database migrations run cleanly (up and down)

#### Gate 4: Review
- [ ] Code follows existing patterns in the codebase
- [ ] No hardcoded values that should be configurable
- [ ] Error messages are actionable (not generic)
```

### 4. Validation Criteria Patterns

Define reusable acceptance criteria patterns that Ralph will inject into stories:

```markdown
#### For all stories:
- "Typecheck passes"
- "All existing tests pass (no regressions)"

#### For data/logic stories:
- "Unit tests cover happy path and error cases"
- "Edge cases documented in QRD are handled"

#### For API stories:
- "Input validation rejects malformed data with descriptive errors"
- "API returns appropriate HTTP status codes"

#### For UI stories:
- "Verify in browser using dev-browser skill"
- "No console errors in browser dev tools"

#### For database stories:
- "Migration runs cleanly up and down"
- "Existing data is preserved after migration"
```

### 5. Edge Case & Risk Register

Enumerate known edge cases and risks specific to this project. These feed into story acceptance criteria.

Format:
```markdown
| ID | Category | Edge Case | Severity | Mitigation |
|----|----------|-----------|----------|------------|
| EC-001 | Input | Empty/null input values | High | Validate all inputs, return descriptive errors |
| EC-002 | Data | Duplicate records | Medium | Add unique constraints, handle conflicts |
| EC-003 | Concurrency | Simultaneous updates | Low | Use optimistic locking or last-write-wins |
```

### 6. Definition of Done

A checklist that applies to EVERY story before it can be marked `passes: true`:

```markdown
- [ ] All acceptance criteria from the story are met
- [ ] All quality gates (Section 3) pass
- [ ] Relevant validation criteria patterns (Section 4) are satisfied
- [ ] No new linter warnings introduced
- [ ] Changes are committed with descriptive message
- [ ] Progress log updated with learnings
```

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `qrd-[feature-name].md` (kebab-case, matching PRD name)

---

## Example QRD

```markdown
# QRD: Task Priority System

## 1. Quality Overview

Quality requirements for the Task Priority System feature (see PRD: `tasks/prd-task-priority.md`). This is a UI-heavy feature with database changes. Primary quality concerns are data integrity (priority values must be valid) and UI correctness (visual indicators must match data).

## 2. Quality Attributes

### Correctness
- The system shall only accept priority values from the set: 'high', 'medium', 'low'
- The system shall default new tasks to 'medium' priority when no priority is specified
- The system shall preserve existing task data when adding the priority field

### Performance
- The system shall render the task list with priority badges in under 100ms for up to 500 tasks
- The system shall apply priority filters without full page reload

### Reliability
- The system shall not lose task data if a priority update fails mid-request
- The system shall show the current priority value even if the update endpoint is unavailable

## 3. Quality Gates

### Gate 1: Static Analysis
- [ ] TypeScript strict mode passes
- [ ] ESLint passes with zero warnings

### Gate 2: Testing
- [ ] Unit tests for priority validation logic
- [ ] Tests verify default priority assignment

### Gate 3: Integration
- [ ] All existing tests pass
- [ ] Build completes successfully
- [ ] Database migration runs cleanly (up and down)

### Gate 4: Visual Verification
- [ ] Priority badges render correctly in all browsers
- [ ] Filter dropdown works without JavaScript errors

## 4. Validation Criteria Patterns

### For all stories:
- "Typecheck passes"
- "All existing tests pass"

### For database stories:
- "Migration runs up and down cleanly"
- "Existing tasks get default priority 'medium'"

### For UI stories:
- "Verify in browser using dev-browser skill"
- "No console errors in browser dev tools"
- "Priority badge colors match spec (red=high, yellow=medium, gray=low)"

## 5. Edge Case & Risk Register

| ID | Category | Edge Case | Severity | Mitigation |
|----|----------|-----------|----------|------------|
| EC-001 | Data | Task created without priority field | High | Default to 'medium' in schema |
| EC-002 | Data | Invalid priority value submitted | High | Validate enum in server action |
| EC-003 | UI | Priority filter with no matching tasks | Medium | Show "No tasks match" empty state |
| EC-004 | Migration | Existing tasks have no priority | High | Migration sets default 'medium' |
| EC-005 | UI | Rapid priority changes | Low | Debounce or use optimistic UI |

## 6. Definition of Done

- [ ] All acceptance criteria from the story are met
- [ ] TypeScript strict mode passes
- [ ] ESLint passes with zero warnings
- [ ] All existing tests pass (no regressions)
- [ ] Build completes successfully
- [ ] UI stories verified in browser
- [ ] Changes committed with descriptive message
- [ ] Progress log updated with learnings
```

---

## Checklist

Before saving the QRD:

- [ ] Read and analyzed the existing PRD
- [ ] Asked targeted clarifying questions
- [ ] Quality attributes are measurable (not vague)
- [ ] Quality gates are verifiable by automated tools
- [ ] Edge cases are specific and actionable
- [ ] Definition of Done is a concrete checklist
- [ ] Saved to `tasks/qrd-[feature-name].md`
