---
name: story-quality
description: "Validate user stories meet quality standards before converting to prd.json. Use after PRD and QRD exist to validate stories. Triggers on: validate stories, check story quality, story quality check, review stories."
---

# Story Quality Validator

Validate that user stories in a PRD meet quality standards from the BMAD method before they enter the Ralph execution loop. Catches problems early when they are cheap to fix.

---

## The Job

1. Read the PRD from `tasks/prd-[feature-name].md`
2. Read the QRD from `tasks/qrd-[feature-name].md`
3. Validate each story against the quality checklist
4. Report findings as PASS / WARN / FAIL per story
5. Suggest specific fixes for any WARN or FAIL items

---

## Validation Checks

### Check 1: Story Size (CRITICAL)

Each story must be completable in ONE context window (one Ralph iteration).

**FAIL if:**
- Story requires changes to more than 3 files
- Story description takes more than 3 sentences to explain
- Story combines schema + backend + UI in one story
- Story title uses words like "entire", "complete", "full", "all"

**PASS if:**
- Story is one focused change (add column, add component, update action)
- Can describe the change in 1-2 sentences

### Check 2: Dependency Order

Stories must execute in dependency order. Earlier stories cannot depend on later ones.

**FAIL if:**
- A UI story comes before the schema it reads from
- A filter story comes before the data it filters
- Any story references an entity/field from a later story

**PASS if:**
- Schema → Backend → UI → Dashboard ordering
- Each story only depends on previous stories or existing code

### Check 3: Acceptance Criteria Quality

Each criterion must be verifiable by an automated system or explicit manual check.

**FAIL if:**
- Criterion uses vague language: "works correctly", "good UX", "handles edge cases", "properly validates"
- Criterion is not testable: "user is happy", "feels responsive"
- Missing "Typecheck passes" criterion

**WARN if:**
- UI story missing "Verify in browser" criterion
- Data story missing "Tests pass" criterion
- No mention of error handling for API stories

**PASS if:**
- Every criterion describes a specific, observable behavior
- Includes "Typecheck passes"
- UI stories include browser verification

### Check 4: QRD Alignment

Stories must satisfy the quality requirements from the QRD.

**WARN if:**
- QRD quality gates are not reflected in story criteria
- QRD edge cases (severity Critical/High) have no corresponding story criteria
- QRD validation patterns not applied to relevant stories

**PASS if:**
- Stories incorporate QRD quality gates as criteria
- Critical/High edge cases are addressed in story criteria
- Relevant validation patterns from QRD are present

### Check 5: Completeness

The set of stories must cover the PRD's functional requirements.

**FAIL if:**
- A functional requirement has no corresponding story
- PRD goals cannot be achieved by the story set

**WARN if:**
- Non-functional requirements from QRD are not addressed
- Success metrics from PRD have no way to be measured

---

## Output Format

```markdown
# Story Quality Report

## Summary
- Total Stories: N
- PASS: N
- WARN: N
- FAIL: N

## Story Details

### US-001: [Title]
| Check | Status | Notes |
|-------|--------|-------|
| Size | PASS | Single migration, focused change |
| Dependencies | PASS | No dependencies on later stories |
| Criteria Quality | PASS | All criteria verifiable |
| QRD Alignment | WARN | Missing edge case EC-001 handling |
| Completeness | PASS | Covers FR-1 |

**Suggestions:**
- Add criterion: "Existing tasks default to 'medium' priority" (from EC-004)

### US-002: [Title]
...
```

---

## Severity Rules

- **Any FAIL:** Story must be fixed before conversion to prd.json
- **WARN count > 3 per story:** Story should be reviewed and improved
- **All PASS:** Story is ready for Ralph execution

---

## Checklist

- [ ] Read both PRD and QRD
- [ ] Validated every story against all 5 checks
- [ ] Each finding has a specific, actionable suggestion
- [ ] No FAIL items remain (all resolved or documented)
- [ ] QRD edge cases (Critical/High) are covered in stories
