# Workflow: Autonomous (Dark Factory)

> Maximum automation. You define specs and guard rails; agents do the rest.

---

## When to use

- Iteration plan is approved and stories are well-defined.
- Stories have clear acceptance criteria and no unresolved blockers.
- You trust the skills, agents, and test suites to catch issues.

## How it works

```
Specs (you write/approve)
  → Backlog (agents break down)
    → /fleet (agents implement in parallel worktrees)
      → PRs + test results (you review)
        → Merge & release
```

## Step-by-step

### 1. Ensure specs are solid

Before handing off to `/fleet`, verify:

- `spec/business/frame.md` — goals, actors, scope are clear.
- `spec/technical/architecture.md` — tech decisions locked.
- `spec/technical/api-contracts.yaml` — API surface agreed.
- `spec/iterations/iteration-N/plan.md` — stories assigned, dependencies resolved.

### 2. Set git identity and branch rules

```bash
for proj in solutions/*/; do
  git -C "$proj" config user.name "Your Name"
  git -C "$proj" config user.email "you@example.com"
done
```

### 3. Launch the fleet

```text
/model GPT-5 Mini
Read @spec/iterations/iteration-1/plan.md and summarize the plan.
/fleet implement the approved iteration plan using the relevant custom agents, keep status documents updated, and stop on blocking issues.
```

Agents will:
- Pick the right persona per story (backend dev, frontend dev, devops, etc.).
- Create worktrees under `solutions/worktrees/<project>/<branch>/`.
- Implement, test, and commit in small incremental steps.
- Write iteration status to `spec/iterations/iteration-N/report.md`.
- Stop and flag blocking issues rather than guessing.

### 4. Monitor progress

```text
/tasks          # see what each agent is doing
/usage          # check token spend
```

Keep VS Code open on the side — watch for file changes, run tests manually if you want extra confidence.

### 5. Assess the iteration

```text
Read @.github/prompts/dark-factory/assess-iteration.prompt.md and assess the completed iteration.
```

The assessment agent will:
- Verify acceptance criteria per story.
- Check test coverage.
- Flag incomplete or suspicious changes.
- Produce `spec/iterations/iteration-N/acceptance.md`.

### 6. Review and merge

See [workflow-review.md](workflow-review.md) for the detailed review process.

---

## Maximizing autonomy

| Lever | How |
|-------|-----|
| **Better specs** | More detail in acceptance criteria = fewer agent questions |
| **Skills** | Well-defined `.github/skills/` reduce bad patterns |
| **Tests** | Strong test suites let agents self-verify |
| **Small stories** | One concern per story = predictable agent behavior |
| **Guard rails** | Branch protection, CI checks, linting — catch mistakes before merge |

## When to intervene

- Agent stops with a blocking issue → resolve the blocker, update the spec, re-run.
- Security-sensitive code → review before merge, never auto-merge.
- Architecture decisions → pause fleet, discuss, record ADR, then resume.
- Ambiguous requirements → clarify in the spec, don't let agents guess.

## Reference project trick

Need a pattern from another codebase? Clone it temporarily:

```bash
cd solutions
git clone https://github.com/other-org/reference-app _ref-reference-app
cd ..
```

Tell the agent to study it:

```text
Analyze @solutions/_ref-reference-app for auth patterns. Extract the approach and propose how to apply it to @solutions/acme-api. Do NOT modify the reference project.
```

Remove when done:

```bash
rm -rf solutions/_ref-reference-app
```

---

## Anti-patterns

- Launching `/fleet` without approved specs — agents will invent requirements.
- Not setting git identity — commits show wrong author.
- Ignoring `/tasks` output — blocked agents waste tokens looping.
- Skipping assessment — bugs slip through to next iteration.
