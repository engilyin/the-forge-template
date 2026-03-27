# Workflow: Review

> How to efficiently review agent-generated artifacts using VS Code and CLI together.

---

## Principles

1. **Review everything before merge** — autonomous does not mean unreviewed.
2. **VS Code for reading, CLI for acting** — use the right tool for the job.
3. **Feedback is structured** — agents can act on well-formatted feedback.
4. **Small PRs are fast PRs** — one story = one branch = one PR per project.

---

## Review cycle

```
Fleet finishes → /tasks shows completion
  → Open VS Code (code .)
    → Review diffs + run tests
      → Approve OR leave feedback
        → Agents fix → re-review
          → Merge
```

---

## VS Code review workflow

### 1. Open the workspace

```bash
code .
```

VS Code sees all projects under `solutions/` and the spec files in the root.

### 2. Review generated specs

Check `spec/` for new or modified files:
- `spec/iterations/iteration-N/report.md` — what agents say they did.
- `spec/iterations/iteration-N/acceptance.md` — self-assessment.
- `spec/technical/` — any new ADRs or API contract changes.

### 3. Review code changes

For each project with changes:

```bash
git -C solutions/acme-api diff main..feature/US-01-01
git -C solutions/acme-api log --oneline main..feature/US-01-01
```

Or use the VS Code Source Control panel — it shows diffs per repo.

### 4. Run tests locally

```bash
cd solutions/acme-api
./mvnw test                    # or npm test, etc.
cd ../..
```

### 5. Check for common issues

- [ ] No hardcoded secrets or credentials.
- [ ] Tests exist for new code.
- [ ] API changes match `spec/technical/api-contracts.yaml`.
- [ ] No unrelated files modified.
- [ ] Commit messages follow conventions.
- [ ] No `_ref-` projects accidentally modified.

---

## Providing feedback

Choose the approach that fits:

### Option A: Edit directly (preferred for small fixes)

```bash
git -C solutions/acme-api checkout feature/US-01-01
# edit in VS Code
git -C solutions/acme-api add -A
git -C solutions/acme-api commit -m "fix: address review comments for US-01-01"
```

### Option B: Feedback file (for agent-actionable feedback)

Create `spec/FEEDBACK.md`:

```markdown
## Review feedback — Iteration 1

### STORY-001 (acme-api)
- [ ] Missing input validation on POST /users endpoint
- [ ] Test for edge case: empty email field

### STORY-003 (acme-web)
- [ ] Loading spinner not shown during API call
```

Then in CLI:

```text
Read @spec/FEEDBACK.md and implement all requested changes.
```

### Option C: GitHub issues (for larger discussions)

```bash
gh issue create --title "Review: STORY-001 missing validation" --body "Details..."
```

### Option D: Iterative CLI discussion

```text
Read solutions/acme-api/src/main/java/com/acme/UserController.java and suggest 3 improvements.
```

Review the suggestions, pick what you want, and ask the agent to apply them.

---

## PR workflow

After review is complete:

```bash
# push the feature branch
git -C solutions/acme-api push origin feature/US-01-01

# open a PR (requires gh CLI)
gh pr create --repo your-org/acme-api --base main --head feature/US-01-01 \
  --title "feat(US-01-01): user authentication" \
  --body "Implements STORY-001. See spec/iterations/iteration-1/stories/STORY-001.md"
```

For spec changes in the root repo:

```bash
git add spec/
git commit -m "docs: iteration-1 specs and reports"
git push origin main
```

---

## Review tips

| Situation | What to do |
|-----------|------------|
| Minor style issues | Fix directly, don't send back to agent |
| Missing tests | Create `spec/FEEDBACK.md` entry, let agent generate them |
| Wrong approach | Stop, discuss in CLI, possibly re-plan the story |
| Security concern | Block merge, file an issue, review with team |
| "Looks good" | Merge and move on — don't over-review routine code |

---

## Parallel review with fleet

While the fleet works on iteration N+1, you can review iteration N:

```
Terminal 1 (CLI):  /fleet working on iteration 2
Terminal 2 (bash): reviewing iteration 1 PRs, running tests
VS Code:           reading diffs, checking specs
```

This pipeline keeps you productive — you're always either reviewing or the fleet is implementing.
