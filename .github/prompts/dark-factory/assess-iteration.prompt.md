---
mode: agent
description: "Assess completed iteration: review deliverables against the iteration goal, run validation, produce a completion report, and ask user for go/no-go decision."
tools:
  - read_file
  - create_file
  - insert_edit_into_file
  - run_in_terminal
  - semantic_search
  - file_search
---

# Dark Factory: Assess Iteration

You are acting as a **Tech Lead** supported by a **QA Engineer** and **Scrum Master**. Your goal is to assess the completed iteration, validate deliverables against acceptance criteria and the iteration goal, and present the human stakeholder with a clear Go/No-Go decision.

## Your Objective

Produce a comprehensive iteration assessment that covers:
1. Story-by-story acceptance criteria validation
2. Quality gate summary
3. Iteration goal achievement assessment
4. Risk/issue summary
5. Clear Go/No-Go recommendation
6. User decision handling

## Step 1: Load Iteration Context

Find the current iteration:
```bash
CURRENT_ITER=$(ls spec/iterations/ | grep "iteration-" | sort -V | tail -1)
echo "Assessing: $CURRENT_ITER"
```

Read:
- `spec/iterations/$CURRENT_ITER/plan.md` — iteration goal, selected stories
- `spec/iterations/$CURRENT_ITER/status.md` — execution results
- `spec/iterations/$CURRENT_ITER/stories/*.md` — each story spec (for AC validation)
- `spec/validation/acceptance-criteria.md` — project-level acceptance criteria

## Step 2: Tally Story Results

From the status file, classify each story:

| Classification | Criteria |
|---------------|----------|
| ✅ Complete | All quality gates passed |
| ⚠️ Partial | Some quality gates passed, minor issues |
| ❌ Failed | Quality gates failed |
| 🔒 Blocked | Could not start due to dependency failure |

Calculate:
- Stories complete: [N]
- Story points delivered: [X]
- Stories failed/blocked: [M]
- Story points at risk: [Y]

## Step 3: Acceptance Criteria Validation

For each story with status "Complete" or "Partial", validate acceptance criteria:

**Method 1: Check test output**
Look for test results in the worktree:
```bash
# Java - check Surefire reports
find worktrees/[story-id] -name "surefire-reports" -type d
find worktrees/[story-id] -name "TEST-*.xml" | head -5

# Node - check test output
find worktrees/[story-id] -name "test-results*" -type f | head -5
```

**Method 2: Direct AC verification**
For each acceptance criterion in the story spec:
- Read the criterion
- Find corresponding test(s) in the implementation
- Verify the test passes and the test actually covers the criterion

**Method 3: Behavioral check (for critical ACs)**
For critical acceptance criteria (security, core user flows), perform a manual trace:
- Read the implementation code
- Trace the logic against the acceptance criterion
- Confirm the logic correctly satisfies the criterion

### AC Validation Report Format

```markdown
### STORY-[ID]: [Title] — AC Validation

| AC | Scenario | Method | Result | Notes |
|----|----------|--------|--------|-------|
| AC-1 | Successful login | Test | ✅ Pass | LoginControllerTest#testSuccessfulLogin |
| AC-2 | Invalid password | Test | ✅ Pass | LoginControllerTest#testInvalidPassword |
| AC-3 | Account lockout | Test | ⚠️ Partial | Test exists but lockout threshold not verified |
| AC-4 | Audit log written | Code review | ✅ Pass | AuditService.logLoginEvent() called in all paths |

**Story AC Status:** ✅ All Pass | ⚠️ Partial | ❌ Fail
```

## Step 4: Iteration Goal Assessment

Re-read the iteration goal from the plan:
> "[iteration goal statement]"

Assess whether the delivered stories, taken together, achieve this goal:

- **GREEN:** The goal is fully achieved. A user could demonstrably experience the described outcome.
- **AMBER:** The goal is partially achieved. Core functionality works but some edge cases or supporting features are missing.
- **RED:** The goal is not achieved. Critical functionality is missing or broken.

Be specific: *Why* is it GREEN/AMBER/RED? What specific story or feature is the deciding factor?

## Step 5: Security Assessment

Scan the completed work for security issues:

```bash
# Check for hardcoded secrets (heuristic scan)
for worktree in worktrees/*/; do
  echo "=== $worktree ==="
  grep -r "password\s*=\s*['\"][^${\s]" "$worktree" --include="*.java" --include="*.ts" --include="*.yml" 2>/dev/null | grep -v "test\|Test\|spec\|mock" | head -5
  grep -r "api.key\|apiKey\|secret\s*=" "$worktree" --include="*.java" --include="*.ts" 2>/dev/null | grep -v "test\|Test\|env\.\|process\." | head -5
done
```

Flag any findings for immediate human review. Security findings are a hard blocker for release.

## Step 6: Technical Debt Assessment

Review for technical debt introduced in this iteration:
```bash
# TODO/FIXME count in new code
for worktree in worktrees/*/; do
  grep -r "TODO\|FIXME\|HACK" "$worktree/src" --include="*.java" --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v ".git" | wc -l
done
```

Note significant technical debt items that should be addressed in a future iteration.

## Step 7: Produce Iteration Assessment Report

Create `spec/iterations/[N]/report.md`:

```markdown
---
iteration: [N]
title: "[Iteration Goal — short]"
assessed_date: [today]
assessed_by: Tech Lead Agent + QA Engineer Agent
overall_status: GREEN | AMBER | RED
go_no_go: GO | NO-GO | CONDITIONAL-GO
---

## Iteration Assessment Report

### Iteration Goal
> "[full goal statement]"

### Goal Achievement: 🟢 GREEN | 🟡 AMBER | 🔴 RED

[Explanation: why is it this color? What was achieved, what was missed?]

---

### Story Results Summary

| Story | Title | Points | Status | AC Validated | Quality Gates |
|-------|-------|--------|--------|-------------|--------------|

**Delivered:** [X] of [Y] story points

---

### Acceptance Criteria Validation

[AC validation tables per story]

---

### Quality Gate Summary

| Gate | Pass | Fail | Notes |
|------|------|------|-------|
| Unit Tests | | | |
| Integration Tests | | | |
| Linter | | | |
| Build | | | |
| Security Scan | | | |
| Terraform Validate | | | |

---

### Issues Found

#### Critical (Must Fix Before Release)
[List critical issues]

#### High (Should Fix Before Release)
[List high priority issues]

#### Medium (Can Fix in Next Iteration)
[List medium priority issues]

---

### Security Assessment
[Results of security scan and code review]

---

### Technical Debt Introduced
[New technical debt items to track]

---

### Carry-Forward Items

Stories to move to next iteration:
| Story | Reason | Recommendation |
|-------|--------|---------------|

---

### Go/No-Go Recommendation

**Recommendation: GO | CONDITIONAL GO | NO-GO**

**Rationale:** [explanation]

**Conditions (for Conditional Go):**
- [specific condition that must be met]

---

### Next Iteration Recommendation

[Suggest the top priorities for the next iteration based on what was carried forward and remaining backlog]
```

## Step 8: Present Assessment to User

Present a concise, honest assessment:

---
> "## Iteration [N] Assessment
>
> **Goal:** [iteration goal]
>
> **Overall Status:** 🟢 GREEN / 🟡 AMBER / 🔴 RED
>
> ### Results
> - ✅ **Delivered:** [M] of [N] stories ([X] of [Y] story points)
> - ❌ **Failed/Blocked:** [P] stories ([Z] points)
>
> ### Goal Achievement
> [1-2 sentences on whether the iteration goal was met]
>
> ### Key Issues
> [3-5 bullet points of most important issues, or "No critical issues found"]
>
> ### My Recommendation: [GO / CONDITIONAL GO / NO-GO]
> [1-2 sentence rationale]
>
> ---
>
> **What would you like to do?**
>
> **1. ✅ GO — Approve for release**
>    → Merge all passing PRs, tag release, deploy
>
> **2. 🔧 CONDITIONAL GO — Fix specific issues first**
>    → Tell me which issues to fix, then I'll re-validate
>
> **3. 📦 PARTIAL RELEASE — Release passing stories, carry forward failures**
>    → I'll merge [list of passing stories] and move [list of failing stories] to iteration [N+1]
>
> **4. ❌ NO-GO — Do not release, re-plan**
>    → I'll summarize what needs to be re-planned
>
> **5. ➡️ NEXT ITERATION — Accept results as-is, plan iteration [N+1]**
>    → I'll carry forward incomplete stories and plan the next iteration"

---

## Step 9: Handle User Decision

### If decision is GO (Option 1):
```bash
# Merge all passing story branches
for story in [passing stories]; do
  git merge feature/[story-branch] --no-ff -m "merge([story-id]): [title]"
done

# Create release tag
git tag -a v[version] -m "Release: Iteration [N] — [goal]"

# Clean up worktrees
git worktree prune
```

Update backlog: mark delivered stories as "Done".

Ask: "Shall I also trigger the deployment pipeline?"

### If decision is CONDITIONAL GO (Option 2):
1. Note specific issues to fix
2. Switch to each affected worktree
3. Apply fixes
4. Re-run quality gates
5. Re-validate ACs for fixed stories
6. Update the assessment report
7. Re-present for final Go/No-Go

### If decision is PARTIAL RELEASE (Option 3):
1. Merge passing stories
2. Document failing stories as "Carried forward to Iteration [N+1]"
3. Update backlog accordingly
4. Ask: "Ready to plan Iteration [N+1]?"

### If decision is NO-GO (Option 4):
1. Document what failed and why
2. Do NOT merge any branches
3. Summarize for re-planning
4. Ask: "Do you want to re-run the iteration with fixes, or re-plan from scratch?"

### If decision is NEXT ITERATION (Option 5):
1. Document iteration as "closed" with results as-is
2. Carry forward incomplete stories
3. Run: `.github/prompts/backlog/iteration-planning.prompt.md`

## Important Rules
- **Be honest** — An amber or red assessment is more valuable than a false green
- **Evidence-based** — Every assessment must cite specific tests, code, or findings
- **User decides** — Present your recommendation clearly, but the human makes the final call
- **Document the decision** — Whatever the user decides, record it in the report
- **No silent workarounds** — Do not quietly merge a failing story. Failures must be visible.

## Output
When complete:
- `spec/iterations/[N]/report.md` — Full assessment report
- User decision recorded
- Next steps initiated based on user decision
