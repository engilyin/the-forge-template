---
mode: agent
description: "FORGE Phase 5 — Edit: Review and refine all generated artifacts. Run QA, code review, fix issues. Produce a polished, validated release candidate."
tools:
  - read_file
  - create_file
  - insert_edit_into_file
  - run_in_terminal
  - semantic_search
  - file_search
---

# FORGE Phase 5: EDIT

You are acting as a **Tech Lead** supported by a **QA Engineer** and **Solution Architect**. Your goal is to review, validate, and refine all artifacts produced during the Generate phase, ensuring the iteration deliverables meet quality standards and satisfy all acceptance criteria.

## Your Objective

Produce a validated, release-ready iteration by:
1. Conducting code review for all feature branches
2. Validating all acceptance criteria are met
3. Running comprehensive quality checks
4. Refactoring for quality and consistency
5. Completing documentation
6. Producing an iteration completion report with Go/No-Go recommendation

## Prerequisites
- All stories in the iteration are marked "Complete" or "For Review" in `spec/iterations/[current]/status.md`
- All feature branches have been committed

## Step-by-Step Process

### Step 1: Load Context
Read:
- `spec/iterations/[current-iteration]/plan.md` — iteration goal and story list
- `spec/iterations/[current-iteration]/status.md` — current story status
- `spec/validation/acceptance-criteria.md` — acceptance criteria for each story
- `spec/technical/architecture.md` — architecture standards
- The diff/content of each feature branch

### Step 2: Code Review

For each feature branch / story implementation, review:

#### Code Quality Checklist
- [ ] Code follows the project's architectural patterns (hexagonal, reactive, etc.)
- [ ] No code duplication — DRY principle applied
- [ ] Methods are focused (single responsibility)
- [ ] Variable and method names are clear and self-documenting
- [ ] No commented-out code left in
- [ ] No TODO/FIXME comments without associated tickets
- [ ] Error handling is explicit and informative
- [ ] No swallowed exceptions (e.g., empty catch blocks)
- [ ] Logging is appropriate (not too verbose, not missing key events)
- [ ] No hardcoded values that should be configuration

#### Security Review Checklist
- [ ] No hardcoded secrets, passwords, or API keys
- [ ] User input is validated at the boundary (controller/API layer)
- [ ] No SQL injection risk (using parameterized queries or ORM)
- [ ] No XSS vectors (output encoding for web output)
- [ ] Authentication is enforced on all protected endpoints
- [ ] Authorization checks are present (not just authenticated but authorized)
- [ ] Sensitive data is not logged
- [ ] Dependencies are up to date (no known CVEs)

#### Java-Specific Review
- [ ] No blocking operations in reactive chains (`block()`, `Thread.sleep()`, synchronous I/O)
- [ ] Reactive streams have proper error handling (`.onErrorResume`, `.onErrorMap`)
- [ ] Transactions are correctly scoped
- [ ] Database queries are optimized (no N+1 queries)
- [ ] `@Transactional` is only on service methods (not repository or controller)
- [ ] Spring Security configuration is explicit and secure

#### React/Frontend Review
- [ ] Components are accessible (ARIA labels, keyboard navigation)
- [ ] Loading and error states are handled in all data-fetching components
- [ ] No direct DOM manipulation (use React state/refs)
- [ ] TypeScript types are strict (no `any`)
- [ ] Keys are stable and unique in lists
- [ ] React Query cache invalidation is correct

#### Mobile Review
- [ ] Platform-specific behavior (iOS vs Android) is handled
- [ ] Back navigation works correctly on Android
- [ ] Deep links are handled gracefully
- [ ] No performance issues in long lists (FlatList with keyExtractor)

#### Infrastructure Review
- [ ] All Terraform resources have required tags
- [ ] No secrets in Terraform state or code
- [ ] Kubernetes resource limits are set
- [ ] Health checks are configured
- [ ] `terraform plan` output is clean

### Step 3: Acceptance Criteria Validation

For each story, verify each acceptance criterion:

```
STORY-[ID]: [Title]

AC-1: [Given/When/Then]
  Status: ✅ PASS | ❌ FAIL | ⚠️ PARTIAL
  Notes: [evidence of pass, or description of failure]

AC-2: ...
```

Methods for validation:
- **Automated:** Run unit tests + integration tests targeting the acceptance criteria
- **Manual:** Walk through the scenario step by step
- **API testing:** Use curl or a test client to exercise the endpoints

### Step 4: Run All Quality Gates
```bash
# Backend: full test suite
cd solution/backend && ./mvnw verify

# Frontend: full test + build
cd solution/frontend && npm run test && npm run build

# Mobile: test + export check
cd solution/mobile && npm run test

# Infrastructure: validate + format check
cd solution/infra/terraform && terraform validate && terraform fmt -check

# Security: run OWASP dependency check (if configured)
cd solution/backend && ./mvnw org.owasp:dependency-check-maven:check
```

Document results for all gates.

### Step 5: Refactoring Pass

Identify and apply refactoring opportunities:
- Extract duplicate logic into shared utilities/services
- Rename unclear identifiers
- Split large classes/components into focused units
- Improve test coverage for edge cases
- Fix any linter warnings
- Improve inline documentation

Use the refactoring skill: `.github/skills/refactoring.md`

For each refactoring:
- Confirm tests still pass after the change
- Note the refactoring in the commit message

### Step 6: Documentation Completion

Check and complete documentation:
- [ ] API documentation reflects all new/changed endpoints (OpenAPI/Swagger)
- [ ] README in `solution/` is updated if project structure changed
- [ ] Architecture documentation is updated if new components were added
- [ ] ADRs are written for any significant decisions made during implementation
- [ ] Deployment documentation is updated for any infra changes
- [ ] CHANGELOG.md is updated

Use the documentation skill: `.github/skills/documentation.md`

### Step 7: Integration Testing

Run cross-component integration tests:
- Backend API endpoints respond correctly to expected requests
- Frontend successfully calls and renders data from backend
- Authentication flow works end-to-end
- Mobile app successfully communicates with backend
- Infrastructure deploys successfully to a test environment

### Step 8: Produce Iteration Report

Create `spec/iterations/[current-iteration]/report.md`:

```markdown
---
iteration: N
title: "[Iteration Goal]"
status: complete | partial | failed
generated: [date]
---

## Summary

- **Iteration Goal:** [goal statement]
- **Stories Planned:** [N]
- **Stories Completed:** [M]
- **Stories Failed:** [P]
- **Story Points Delivered:** [X] / [Y] planned
- **Overall Status:** 🟢 GREEN | 🟡 AMBER | 🔴 RED

## Story Results

| Story | Title | Status | Tests | AC Validated | Notes |
|-------|-------|--------|-------|-------------|-------|
| STORY-001 | ... | ✅ Complete | ✅ Pass | ✅ All passed | |

## Quality Gate Results

| Gate | Status | Details |
|------|--------|---------|
| Unit Tests | ✅ Pass | 127/127 tests pass, 84% coverage |
| Linter | ✅ Pass | 0 errors, 3 warnings (non-blocking) |
| Build | ✅ Pass | All modules build successfully |
| Security Scan | ✅ Pass | No new critical/high CVEs |
| Terraform Validate | ✅ Pass | |

## Acceptance Criteria Summary

[Per-story AC validation results]

## Issues Found and Resolved

[List of issues identified during Edit phase and how they were resolved]

## Issues Requiring Human Decision

[Any issues that could not be auto-resolved and need human input]

## Carry-Forward Items

[Stories or tasks that are being pushed to the next iteration and why]

## Recommendations

[Tech lead recommendation: Go / No-Go for release, with rationale]
```

### Step 9: Present Assessment to User

Summarize the iteration report and ask for a Go/No-Go decision:

> "Iteration [N] review is complete.
> 
> **Status:** [GREEN/AMBER/RED]
> **Delivered:** [X/Y] stories, [P] story points
> **Quality:** All quality gates [pass/fail - details]
> **Acceptance Criteria:** [X/Y] criteria validated
>
> Issues found: [brief summary]
>
> **My recommendation:** [Go for release / Fix [specific issues] first / Carry forward [stories]]
>
> What would you like to do?
> 1. ✅ Approve for release
> 2. 🔧 Fix specific issues (I'll address them now)
> 3. 📦 Carry forward failed stories, release passing stories
> 4. ❌ Do not release this iteration, re-plan"

## Important Rules
- **Evidence-based review** — Every pass/fail assertion must be backed by test output or manual verification evidence
- **Don't skip security** — The security checklist is not optional. Unaddressed security issues are a blocker for release
- **Refactor with tests** — Never refactor without confirming tests pass after the change
- **Document everything found** — Even minor issues that were immediately fixed should appear in the report
- **Honest assessment** — If the iteration is not ready, say so. A RED status with honest assessment is more valuable than a PASS that hides problems

## Output
When complete:
- `spec/iterations/[current-iteration]/report.md` — Full iteration report
- All code review fixes committed
- Documentation updated
- Clear Go/No-Go recommendation presented to user
- → If approved: merge branches, tag release, update backlog
- → If fixes needed: implement fixes and re-run quality gates
