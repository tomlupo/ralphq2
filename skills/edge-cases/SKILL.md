---
name: edge-cases
description: "Analyze a PRD for edge cases, failure modes, and risks. Use after a PRD exists to strengthen acceptance criteria. Triggers on: find edge cases, analyze edge cases, what could go wrong, risk analysis, failure modes."
---

# Edge Case Analyzer

Systematically analyze a PRD for edge cases, failure modes, and risks. Produces findings that feed into the QRD and strengthen story acceptance criteria.

---

## The Job

1. Read the PRD from `tasks/prd-[feature-name].md`
2. Read the QRD from `tasks/qrd-[feature-name].md` (if it exists)
3. Analyze across 7 edge case categories
4. Output findings with severity and recommended mitigations
5. Update the QRD's Edge Case & Risk Register (Section 5)
6. Suggest additional acceptance criteria for affected stories

---

## Analysis Categories

Analyze every user story and functional requirement against these 7 categories:

### 1. Input Boundaries
- Empty, null, undefined inputs
- Maximum length / size limits
- Special characters (unicode, emojis, HTML, SQL)
- Type mismatches (string where number expected)
- Boundary values (0, -1, MAX_INT, empty array)

### 2. State Transitions
- Invalid state transitions (e.g., deleting already-deleted item)
- Race conditions (two users editing same resource)
- Stale data (UI shows outdated information)
- Interrupted operations (network drop mid-save)
- Initial state (first-time use, empty database)

### 3. Data Integrity
- Orphaned records (parent deleted, child remains)
- Duplicate detection and handling
- Referential integrity across tables
- Data migration edge cases (null columns, type changes)
- Cascade effects (deleting X affects Y and Z)

### 4. Authentication & Authorization
- Unauthenticated access attempts
- Accessing other users' resources
- Expired sessions during operations
- Role-based permission gaps
- CSRF/XSS vectors in user inputs

### 5. Performance & Scale
- Large dataset behavior (1K, 10K, 100K records)
- Pagination edge cases (last page, empty page)
- N+1 query patterns
- Memory leaks from event listeners or subscriptions
- Slow network / timeout handling

### 6. UI/UX Edge Cases
- Empty states (no data yet)
- Loading states (slow responses)
- Error states (API failures)
- Responsive layout (mobile, tablet, desktop)
- Keyboard navigation and accessibility
- Long text overflow / truncation

### 7. External Dependencies
- Third-party API downtime
- Rate limiting
- Schema/format changes in external data
- Network failures during external calls
- Timeout handling for external services

---

## Output Format

For each finding:

```markdown
### EC-[NNN]: [Short Title]
- **Category:** [1-7 from above]
- **Affected Story:** [US-XXX or "All"]
- **Severity:** Critical | High | Medium | Low
- **Description:** What could go wrong
- **Mitigation:** How to prevent or handle it
- **Suggested Criteria:** Acceptance criterion to add to the story
```

**Severity guide:**
- **Critical:** Data loss, security breach, system crash
- **High:** Feature doesn't work for common cases
- **Medium:** Feature works but edge case produces confusing behavior
- **Low:** Minor UX issue, cosmetic problem

---

## Minimum Findings

You MUST find at least **5 edge cases** across at least **3 different categories**. If you find fewer than 5, you haven't looked hard enough — go back and re-examine.

---

## After Analysis

1. **Update the QRD:** Add all findings to the Edge Case & Risk Register (Section 5) in the QRD
2. **Suggest story updates:** For each Critical/High finding, recommend adding acceptance criteria to the affected story
3. **Report summary:** List total findings by severity

---

## Checklist

- [ ] Analyzed all user stories against all 7 categories
- [ ] Found at least 5 edge cases across 3+ categories
- [ ] Each finding has severity, mitigation, and suggested criteria
- [ ] Updated QRD Edge Case & Risk Register
- [ ] Recommended acceptance criteria additions for Critical/High findings
