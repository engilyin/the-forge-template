# Workflow: Controlled (Hands-On)

> You drive. Copilot assists. Full control over every decision.

---

## When to use

- Exploratory work — you're not sure what the right approach is yet.
- Complex or risky changes — security, data migration, breaking API changes.
- Learning a new codebase — brownfield onboarding.
- Single tricky story that needs human judgment at every step.
- Debugging a production issue.

## How it works

```
You pick a story / task
  → You choose the agent persona
    → Agent proposes a plan (Shift+Tab to review)
      → You approve / edit the plan
        → Agent implements step-by-step
          → You review each step before proceeding
```

---

## Step-by-step

### 1. Pick the story

```text
/model GPT-5 Mini
Read @spec/iterations/iteration-1/stories/STORY-005.md and summarize requirements.
```

### 2. Choose the right agent

```text
/agent
```

Select based on the story type (backend dev, frontend dev, devops, etc.).

### 3. Plan before executing

Press `Shift+Tab` after your prompt to enter plan mode. The agent proposes steps without executing them. Review, adjust, then confirm.

```text
Read @spec/iterations/iteration-1/stories/STORY-005.md and implement it following @.github/copilot-instructions.md.
[Shift+Tab → review plan → confirm]
```

### 4. Work incrementally

Ask the agent to implement one logical piece at a time:

```text
Start with the database schema changes only. Show me the migration before applying.
```

```text
Now implement the repository layer. Run tests before moving on.
```

```text
Now add the REST controller. Verify against @spec/technical/api-contracts.yaml.
```

### 5. Commit frequently

After each verified step:

```text
Commit the current changes with message "feat(US-01-05): add user repository layer"
```

### 6. Switch to VS Code for detailed review

```bash
code .
```

Review diffs in the VS Code Source Control panel. Run tests from the IDE. Return to CLI when ready to continue.

---

## Common controlled scenarios

### Debugging

```text
/agent                           # pick tech-lead or relevant dev agent
Read the error log below and diagnose the root cause in @solutions/acme-api.

<paste error>
```

### Exploring a reference project

```bash
cd solutions
git clone https://github.com/other-org/cool-service _ref-cool-service
cd ..
```

```text
Analyze @solutions/_ref-cool-service for their event-sourcing implementation. Explain the pattern and trade-offs.
```

No code changes — just learning. Remove when done.

### Spike / proof of concept

Create a throwaway branch:

```bash
git -C solutions/acme-api checkout -b spike/new-cache-strategy
```

```text
Implement a Redis cache layer for the product catalog endpoint as a spike. Keep it minimal — we'll decide later if we keep it.
```

If it works, promote to a proper story. If not, delete the branch.

### Brownfield onboarding

Use a premium model for initial analysis:

```text
/model [premium]
Read @.github/prompts/project/brownfield-analysis.prompt.md and analyze @solutions/acme-api. Focus on architecture, tech debt, and test coverage gaps.
/model GPT-5 Mini
```

Walk through findings interactively, then create improvement stories.

---

## Mixing controlled + autonomous

You can start controlled for the tricky parts, then hand off the rest:

1. Implement the critical/risky pieces manually (controlled).
2. Commit and push.
3. Update the iteration plan — mark completed stories, leave remaining ones.
4. Switch to autonomous for the straightforward stories:

```text
/fleet implement remaining stories from @spec/iterations/iteration-1/plan.md
```

---

## Tips

- Use `Shift+Tab` liberally — reviewing the plan is free and catches bad approaches early.
- Ask the agent to explain before implementing: "Explain how you'd approach this, then wait for my approval."
- For security reviews, explicitly ask: "Review this change for OWASP Top 10 vulnerabilities before I commit."
- Don't forget to update the iteration report when working manually — agents won't do it for you in controlled mode.
