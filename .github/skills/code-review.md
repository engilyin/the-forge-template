---
name: "Code Review"
description: "Guidance and checklists for conducting code reviews."
user-invocable: false
---

# Code Review Skill

> This skill defines how to conduct code reviews in the FORGE template. Apply when reviewing any code change as part of the Edit phase or PR review process.

---

## Purpose

Code review is the primary mechanism for catching bugs, enforcing standards, sharing knowledge, and improving code quality before it reaches production. In the FORGE workflow, code review is performed by the **Tech Lead** agent (optionally supported by the **QA Engineer** for test coverage review and the **Solution Architect** for architecture compliance).

---

## Code Review Principles

1. **Be specific** — Vague feedback is not actionable. Every comment must say what is wrong, why it's wrong, and what to do instead.
2. **Be constructive** — The goal is to improve the code, not to judge the author.
3. **Be consistent** — Apply standards uniformly. If it's a problem in one PR, it's a problem in every PR.
4. **Prioritize** — Distinguish between blockers (must fix before merge) and suggestions (optional improvements).
5. **Review the spec too** — Check that the implementation matches what was specified, not just that it's well-written code.

---

## Review Checklist

### 1. Specification Compliance
- [ ] Does the implementation satisfy all acceptance criteria from the story spec?
- [ ] Are there any features implemented that weren't specified? (Gold plating — flag it)
- [ ] Are there any specified features missing from the implementation?
- [ ] Does the code align with the API contracts in `spec/technical/api-contracts.md`?
- [ ] Does the code align with the data model in `spec/technical/data-model.md`?

### 2. Correctness
- [ ] Does the code do what the developer claims it does?
- [ ] Are there logic errors in conditional statements?
- [ ] Are edge cases handled? (null/empty/zero/max values)
- [ ] Are concurrent access / race condition scenarios safe?
- [ ] Are database operations transactional where required?
- [ ] Are error responses appropriate (correct HTTP status codes, meaningful messages)?

### 3. Security
- [ ] No hardcoded secrets, passwords, API keys, or tokens
- [ ] User input is validated at the boundary (not just in the database layer)
- [ ] No SQL injection vulnerability (parameterized queries or ORM)
- [ ] No XSS vulnerability in output rendering
- [ ] Authorization checks are present on all protected resources
- [ ] Sensitive data is not logged (passwords, tokens, PII)
- [ ] File upload endpoints (if any) validate file type and size
- [ ] Error messages do not reveal system internals or sensitive data to end users

### 4. Code Quality
- [ ] Methods are focused (single responsibility principle)
- [ ] Names are clear and self-documenting (no cryptic abbreviations)
- [ ] No code duplication (DRY principle)
- [ ] No dead code (unused methods, commented-out blocks)
- [ ] No TODO/FIXME comments without a linked ticket
- [ ] Complexity is manageable (cyclomatic complexity — alert if method > 10 branches)
- [ ] No magic numbers or strings (use named constants)

### 5. Error Handling
- [ ] All exceptions are handled explicitly (no empty catch blocks)
- [ ] Errors are logged with sufficient context for debugging
- [ ] The error handling strategy is consistent with the rest of the codebase
- [ ] Retryable errors are distinguished from non-retryable errors

### 6. Testing
- [ ] Unit tests cover all new business logic
- [ ] Unit tests cover happy path AND error paths
- [ ] Integration tests cover critical paths
- [ ] Test names describe what is being tested (not just "testMethod")
- [ ] Tests do not depend on external services (use mocks/stubs)
- [ ] Tests are not flaky (no random timing dependencies)
- [ ] Test coverage ≥80% for new code

### 7. Architecture Compliance
- [ ] Follows the established layer structure (controller → service → repository)
- [ ] No layer bypasses (e.g., controller calling repository directly)
- [ ] New dependencies are justified (no added libraries without discussion)
- [ ] Reactive stack: no `.block()` calls inside reactive chains (Java WebFlux)
- [ ] TypeScript strict: no `any` type (React/Mobile)

### 8. Performance
- [ ] No obvious N+1 query problems
- [ ] Database queries use indexes where appropriate
- [ ] No synchronous I/O in reactive chains
- [ ] Large responses are paginated
- [ ] Expensive operations are not repeated unnecessarily (cache where appropriate)

### 9. Documentation
- [ ] All public methods/functions have documentation (Javadoc/JSDoc)
- [ ] Complex algorithms have inline explanations
- [ ] API endpoints are documented (OpenAPI annotations)
- [ ] README is updated if project structure has changed

### 10. Build & Tooling
- [ ] Code builds without errors
- [ ] All tests pass
- [ ] Linter produces no errors
- [ ] Commit messages follow Conventional Commits format

---

## Comment Severity Labels

Use these labels in code review comments:

| Label | Meaning | Action Required |
|-------|---------|-----------------|
| `[BLOCKER]` | Must fix before merge. Correctness, security, or architecture issue. | Fix before merge |
| `[MAJOR]` | Significant quality issue. Strongly recommend fixing. | Fix in this PR or create follow-up ticket |
| `[MINOR]` | Style or preference. | Fix if easy, otherwise note and move on |
| `[QUESTION]` | Something unclear — asking for explanation or justification | Author explains or fixes |
| `[SUGGESTION]` | Optional improvement with no impact on mergeability | Author's discretion |
| `[PRAISE]` | Good code worth highlighting | No action needed |

---

## Code Review Comment Template

When leaving a review comment, use this structure:

```
[BLOCKER] Short description of the issue

**Problem:** [What is wrong and why it's a problem]
**Impact:** [What could happen if not fixed]
**Suggestion:** [Specific code change or approach to fix it]

Example:
[BLOCKER] Missing authorization check on DELETE endpoint

**Problem:** The `/users/{id}` DELETE endpoint checks that the user is authenticated but does not verify that the authenticated user is deleting their own account (or is an admin).
**Impact:** Any authenticated user can delete any other user's account.
**Suggestion:** Add `@PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")` to the method, or implement the authorization check in the service layer.
```

---

## Approval Criteria

### Approve (PR is ready to merge)
- All `[BLOCKER]` comments are resolved
- All `[MAJOR]` comments are resolved or have accepted follow-up tickets
- Tests pass
- Build passes
- Linter passes

### Request Changes
- Any unresolved `[BLOCKER]` comment
- Test coverage below threshold
- Build or linter failures

### Approve with Comments
- Only `[MINOR]` or `[SUGGESTION]` comments remain
- Test coverage meets threshold
- All automated checks pass

---

## Language-Specific Review Patterns

### Java / Spring Boot
Watch for:
- `@Autowired` field injection (use constructor injection)
- `@Transactional` on `@Repository` classes (should only be on service layer)
- Non-reactive blocking operations in WebFlux stack (`.block()`, `Thread.sleep()`, synchronous JDBC)
- Missing `@Valid` on request body parameters
- Generic `Exception` in throws clauses (use specific exceptions)
- Missing error mapping in reactive chains (`.onErrorMap`, `.onErrorResume`)

### React / TypeScript
Watch for:
- `any` type usage
- Missing dependencies in `useEffect` dependency array
- `useEffect` used for data fetching instead of React Query
- Keys derived from array index (unstable keys in lists)
- Unhandled loading and error states in data-fetching components
- Missing accessibility attributes (`aria-label`, `role`)

### Terraform
Watch for:
- Missing required tags
- Hardcoded values that should be variables
- Resources without lifecycle rules (accidental destroy protection missing for stateful resources)
- Security groups that are too permissive (0.0.0.0/0 ingress)
- Missing encryption for storage resources
