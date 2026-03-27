# Copilot CLI Runbook

> Quick-reference for day-to-day usage. Autonomous-first, manual as fallback.
> Detailed workflow guides: [autonomous](docs/workflow-autonomous.md) · [controlled](docs/workflow-controlled.md) · [review](docs/workflow-review.md)

---

## 1. Bootstrap

```bash
copilot login && copilot --version
copilot                          # start interactive session
```

Load workspace context and skills:

```text
Read @.github/copilot-instructions.md and follow it for this repository.
/skills reload
/skills list
```

Set the default (cheap) model — switch to premium only for framing, analysis, or architecture:

```text
/model GPT-5 Mini
```

---

## 2. Managing Projects in `solutions/`

All product repositories live under `solutions/`. The scaffold repo itself never contains implementation code.

### Add a product project

```bash
cd solutions
git clone https://github.com/your-org/acme-api
cd ..
```

After cloning, reload context:

```text
/skills reload
```

### Add a reference / sample project (temporary)

Clone any repo you want to study for patterns or ideas. Prefix the folder name with `_ref-` so agents know to ignore it during implementation:

```bash
cd solutions
git clone https://github.com/other-org/cool-project _ref-cool-project
cd ..
```

When done extracting ideas, remove it:

```bash
rm -rf solutions/_ref-cool-project    # bash / Git Bash
# PowerShell:
Remove-Item -Recurse -Force solutions\_ref-cool-project
```

### Remove a product project

```bash
# clean up worktrees first
git -C solutions/acme-old worktree list
git -C solutions/acme-old worktree prune
rm -rf solutions/worktrees/acme-old
rm -rf solutions/acme-old
```

Update any story specs that reference the removed project.

---

## 3. Autonomous (Dark Factory) Flow — Primary

This is the default way to work. Let agents handle implementation end-to-end.

### 3a. Kick-off (greenfield or brownfield)

**Greenfield** — switch to a premium model, then:

```text
Read @.github/prompts/project/greenfield-init.prompt.md and run that flow. Ask clarifying questions first.
```

Continue through FORGE phases: `01-frame` → `02-obstruct` → `03-reconstruct`.

**Brownfield** — clone projects into `solutions/`, then:

```text
Read @.github/prompts/project/brownfield-analysis.prompt.md and analyze all projects under @solutions.
```

Switch back to `GPT-5 Mini` after analysis.

### 3b. Build the backlog

```text
Read @.github/prompts/backlog/story-breakdown.prompt.md and break the approved specs into stories.
Read @.github/prompts/backlog/backlog-grooming.prompt.md and groom the backlog.
Read @.github/prompts/backlog/iteration-planning.prompt.md and plan the next iteration.
```

### 3c. Fleet — execute the iteration

```text
Read @spec/iterations/iteration-1/plan.md and summarize the plan.
```

Then launch the fleet:

```text
/fleet implement the approved iteration plan using the relevant custom agents, keep status documents updated, and stop on blocking issues.
```

Monitor:

```text
/tasks
/usage
```

### 3d. Assess

```text
Read @.github/prompts/dark-factory/assess-iteration.prompt.md and assess the completed iteration.
```

---

## 4. Controlled (Manual) Flow — Fallback

Use when you need fine-grained control over a single story or tricky change.

```text
/agent                            # pick the right persona
/model GPT-5 Mini
Read @spec/iterations/iteration-1/stories/STORY-001.md and implement it following @.github/copilot-instructions.md.
```

Press `Shift+Tab` before confirming to review the plan.

---

## 5. Agile Day-to-Day Work

### Add a new requirement

Write a short spec or user story in `spec/business/` or open a GitHub issue, then:

```text
Read @spec/business/new-requirement.md and add it to the backlog. Groom and prioritize.
```

### Register a bug

Create a bug report in `spec/iterations/iteration-N/bugs/` or via GitHub:

```bash
gh issue create --title "BUG: ..." --body "Steps to reproduce, expected vs actual"
```

Then let the agent triage:

```text
Read the latest bugs under @spec/iterations and add fix stories to the backlog.
```

### Re-prioritize and re-plan

```text
Read @.github/prompts/backlog/backlog-grooming.prompt.md and re-groom. New requirements and bugs have been added.
Read @.github/prompts/backlog/iteration-planning.prompt.md and re-plan the current iteration.
```

---

## 6. Review (VS Code in Parallel)

Keep VS Code open alongside the CLI for reviewing generated artifacts.

```bash
code .    # open the scaffold workspace
```

**Quick review cycle:**

1. CLI generates code / specs.
2. In VS Code: review diffs, run tests, read generated docs.
3. Provide feedback via:
   - Edit files directly → commit to a review branch.
   - Create `spec/FEEDBACK.md` — agents read and act on it.
   - Open a GitHub issue for large changes.

See [workflow-review.md](docs/workflow-review.md) for the full review process.

---

## 7. Git Identity & Commits

Set repo-local identity so agent commits are attributable:

```bash
for proj in solutions/*/; do
  git -C "$proj" config user.name "Your Name"
  git -C "$proj" config user.email "you@example.com"
done
```

PowerShell equivalent:

```powershell
Get-ChildItem solutions -Directory | ForEach-Object {
  git -C $_.FullName config user.name "Your Name"
  git -C $_.FullName config user.email "you@example.com"
}
```

---

## 8. Verify Stage Completion

| Phase | Check |
|-------|-------|
| Frame | `spec/business/frame.md` exists with goals and actors |
| Obstruct | `spec/business/obstruct-report.md` has risks and mitigations |
| Reconstruct | `spec/technical/architecture.md` + `api-contracts.yaml` reviewed |
| Generate | Code in `solutions/`, iteration report written |
| Edit | PRs merged, CI green, acceptance doc signed |

```bash
ls spec/business spec/technical
ls solutions/
git -C solutions/acme-api log --oneline -5
/tasks
```

---

## 9. Non-Interactive / CI Usage

```bash
copilot -s -p "Read @.github/copilot-instructions.md and summarize the next FORGE step."
copilot -s --agent devops-engineer -p "Review @solutions/acme-iac and suggest safe deployment changes."
```

---

## 10. Quick Reference

| Command | Purpose |
|---------|---------|
| `/model` | Switch model |
| `/agent` | Pick agent persona |
| `/skills list` | Show loaded skills |
| `/skills reload` | Reload after project changes |
| `/fleet` | Launch autonomous fleet |
| `/tasks` | Track fleet progress |
| `/usage` | Check token/cost usage |
| `/session` | Session info |
| `/help` | All commands |
| `Shift+Tab` | Plan mode before execution |
