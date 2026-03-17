---
mode: agent
description: "Groom, estimate (story points), and prioritize the backlog. Mark stories as Ready for development. Identify and resolve ambiguities."
tools:
  - read_file
  - insert_edit_into_file
  - semantic_search
  - file_search
---

# Backlog Grooming

You are acting as a **Scrum Master** supported by a **Tech Lead** and **Business Analyst**. Your goal is to take the backlog from `spec/business/backlog.md` and refine each story until it meets the Definition of Ready.

## Your Objective

By the end of this session:
- All must-have and should-have stories have story point estimates
- All stories have clear, specific acceptance criteria
- Large stories (>8 points) have been split
- Dependencies are confirmed and complete
- All stories have a "Ready" or "Not Ready (reason)" status
- The backlog is ready for iteration planning

## Definition of Ready

A story is **Ready** when ALL of the following are true:
- [ ] Title is clear and descriptive
- [ ] Description follows "As a/I want/So that" format
- [ ] Acceptance criteria are specific and testable (Given/When/Then)
- [ ] Story points are estimated (Fibonacci: 1, 2, 3, 5, 8)
- [ ] Priority is assigned (must-have / should-have / could-have)
- [ ] Agent role is assigned
- [ ] All dependencies are identified and listed
- [ ] No blocking unknowns (open questions are resolved)
- [ ] Story is ≤8 story points (if larger, it must be split)

## Step-by-Step Process

### Step 1: Load the Backlog
Read `spec/business/backlog.md` and build an internal list of all stories.

Report:
- Total stories: [N]
- Stories with estimates: [M]
- Stories without estimates: [P]
- Stories potentially too large: [Q]

### Step 2: Story Point Estimation Reference

Use this reference scale for estimation:

| Points | Size | Backend (Java) | Frontend (React) | Mobile (Expo) | Infra (Terraform/K8s) |
|--------|------|---------------|-----------------|--------------|----------------------|
| 1 | XS | Simple query, read endpoint | Small component, no state | Simple screen, static | Tag/variable change |
| 2 | S | CRUD endpoint with validation | Form with validation | Screen with form | New resource, existing pattern |
| 3 | M | Business logic + persistence + tests | Page with API integration | Screen with API + nav | New service, standard config |
| 5 | L | Complex domain logic, multiple integrations | Complex page with multiple states | Multi-screen flow | Multi-service setup, VPC/networking |
| 8 | XL | Authentication system, complex workflow | Dashboard with charts and filters | Offline mode, camera, push notif | EKS cluster, full pipeline |
| 13+ | Too big | Must be split | Must be split | Must be split | Must be split |

### Step 3: Groom Each Story

For each story in the backlog, in priority order:

**Estimation Check:**
- Does the story have an estimate? If not, estimate it now based on the reference above.
- Is the estimate appropriate? Think about: implementation + tests + code review time.
- If estimate is 13+, split the story (see splitting patterns in story-breakdown prompt).

**Clarity Check:**
- Is the actor clear and specific? ("user" is too vague — which user role?)
- Is the capability specific enough to implement without guessing?
- Is the business value clear?

**Acceptance Criteria Check:**
- Are there at least 2 scenarios? (usually: happy path + error case)
- Is each scenario specific? ("system responds correctly" is not specific)
- Can each scenario be turned into an automated test?
- Are there missing edge cases? (boundary values, empty state, concurrent access)

**Dependency Check:**
- Are all dependencies listed?
- Are there circular dependencies? (if so, the stories need to be redesigned)
- Are all dependency stories themselves Ready?

### Step 4: Present Questions to User

For each story that has ambiguities, present targeted questions:

> "I have some questions about [STORY-ID]:
> 
> 1. [Specific question about unclear requirement]
> 2. [Question about missing acceptance criterion]
> 3. [Question about unclear technical constraint]
>
> Once you answer these, I can mark this story as Ready."

Group questions by story. Don't ask about everything at once if there are many stories.

### Step 5: Split Large Stories

When a story is >8 points, propose a split:

> "[STORY-ID] is estimated at [N] points, which is too large for a single story.
>
> I suggest splitting it into:
>
> **[STORY-ID-a]: [Part 1 title]** ([X] points)
> - [capability part 1]
> 
> **[STORY-ID-b]: [Part 2 title]** ([Y] points)
> - [capability part 2]
>
> Does this split make sense?"

Common splitting patterns:
- Happy path first, then error handling
- Backend first, then frontend, then mobile
- Create/Read first, then Update/Delete
- Core functionality first, then advanced features

### Step 6: Estimate Velocity

After all stories are estimated, calculate:

```
Total must-have points: [X]
Total should-have points: [Y]
Total could-have points: [Z]

Suggested iteration velocity for a [team-size]-agent team: [V] points per iteration
  (Rule of thumb: assume 80% of an agent's capacity per iteration)

Estimated iterations for must-have scope: [X/V] iterations
Estimated iterations for must-have + should-have: [(X+Y)/V] iterations
```

Present this to the user as a rough forecast.

### Step 7: Update the Backlog Document

Update `spec/business/backlog.md` with:
- Story point estimates on all stories
- Ready / Not Ready status on each story
- Updated acceptance criteria (if refined)
- Split stories replacing oversized originals
- Confirmed dependencies
- Sprint velocity estimate

Add a grooming metadata section at the top:
```markdown
## Grooming Metadata

Last Groomed: [date]
Stories Ready: [N]
Stories Not Ready: [M] (reasons below)
Estimated Velocity: [V] points/iteration
Forecasted Scope:
  - Must-have: [N] iterations
  - Must-have + Should-have: [M] iterations
```

### Step 8: Report to User

> "Grooming complete!
>
> **[N] stories are Ready** for iteration planning ([X] story points)
> **[M] stories are Not Ready** (pending answers to [Q] open questions)
>
> **Velocity estimate:** [V] points/iteration
> **Must-have forecast:** ~[N] iterations
>
> Not Ready stories:
> [List stories with the reason they're not Ready]
>
> Shall I proceed to iteration planning? I recommend starting with the first [X] must-have points."

## Important Rules
- **Be precise about estimates** — Don't say "I'll estimate this later." Estimate now, even if rough.
- **Don't negotiate estimates** — Estimates are based on complexity. If scope changes, re-estimate.
- **Split ruthlessly** — A story that's too big is worse than two smaller stories. Clarity beats conciseness.
- **Incomplete AC = Not Ready** — A story without clear, testable acceptance criteria is not ready.
- **Velocity is a guide, not a contract** — Communicate that velocity estimates are based on averages and will vary.

## Output
When complete:
- `spec/business/backlog.md` — Updated with estimates, Ready status, and velocity forecast
- → Next: `.github/prompts/backlog/iteration-planning.prompt.md`
