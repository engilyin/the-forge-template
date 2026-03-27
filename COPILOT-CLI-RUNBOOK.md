# Copilot CLI Runbook

## 1. Start the CLI

```bash
copilot login
copilot --version
copilot
```

## 2. Set the default model

Use `GPT-5 Mini` for normal work.

```text
/model GPT-5 Mini
```

Use a premium model only for:

- greenfield framing
- brownfield analysis
- large architecture analysis
- explicit user request

After analysis, switch back:

```text
/model GPT-5 Mini
```

## 3. Load repo context

```text
Read @.github/instructions/copilot-instructions.md and follow it for this repository.
/skills reload
/skills list
/agent

### 3.a Clone projects for Brownfield

If you are using Brownfield mode you must clone the existing project repositories into the workspace `solutions/` directory. Example workflow:

```bash
cd solutions
git clone https://github.com/your-org/acme-api
git clone https://github.com/your-org/acme-web
git clone https://github.com/your-org/acme-mobile
cd ..
```

To add a new project incrementally later:

```bash
cd solutions
git clone https://github.com/your-org/acme-iac
cd ..
```

After cloning, return to the workspace root and run:

```bash
copilot  # start or refresh CLI context
/skills reload
```
```

## 4. Greenfield flow

```text
Read @.github/prompts/project/greenfield-init.prompt.md and run that flow with me. Ask clarifying questions first.
```

Then continue phase by phase:

```text
Read @.github/prompts/forge/01-frame.prompt.md and continue from the current repo state.
Read @.github/prompts/forge/02-obstruct.prompt.md and continue from the current repo state.
Read @.github/prompts/forge/03-reconstruct.prompt.md and continue from the current repo state.
```

Switch back to `GPT-5 Mini` before implementation.

```text
/model GPT-5 Mini
Read @.github/prompts/backlog/story-breakdown.prompt.md and break the approved specs into stories.
Read @.github/prompts/backlog/backlog-grooming.prompt.md and groom the current backlog.
Read @.github/prompts/backlog/iteration-planning.prompt.md and create the next iteration plan.
```

## 5. Brownfield flow

Clone existing project repositories into `solutions/`, then run:

```text
Read @.github/prompts/project/brownfield-analysis.prompt.md and analyze all projects under @solutions. Produce technical specs under @spec/technical.
```

After the analysis is done, switch back to `GPT-5 Mini` and continue with backlog and implementation work.

## 6. Single-story implementation flow

```text
/model GPT-5 Mini
Read @spec/iterations/iteration-1/stories/STORY-001.md and implement it following @.github/instructions/copilot-instructions.md. The story's projects field lists which repos under @solutions to modify.
```

If needed, pick a role first:

```text
/agent
```

## Reviewing generated documents and requesting changes

Copilot can generate specification and implementation artifacts, but reviewing in VS Code is often more convenient. Recommended review workflow:

1. Generate artifacts with Copilot CLI as usual.
2. Open the workspace in VS Code and review the files under `spec/` and `solutions/`.

```bash
code .
```

3. Provide feedback using one of these approaches (choose what's most convenient):

- Make edits directly in VS Code and commit them to a review branch (preferred):

	```bash
	git checkout -b review/spec-changes
	# edit files in VS Code
	git add spec/
	git commit -m "docs: review updates for generated specs"
	git push origin review/spec-changes
	# open a GitHub PR for formal review
	```

- Or leave structured feedback next to the generated docs by creating a `spec/FEEDBACK.md` entry listing requested changes. Agents will read and act on that file.

- Or open issues in the repo for large or blocking changes (use `gh` or the GitHub UI):

	```bash
	gh issue create --title "Spec feedback: ..." --body "Details and file references"
	```

4. If you prefer to discuss iteratively with Copilot before committing changes, run targeted prompts such as:

```text
Read spec/technical/api-contracts.yaml and propose the top 3 clarifying questions.
```

Agents will respond and can generate diffs or patch files you can apply locally.

Note: For traceability prefer the commit/PR route so human reviewers and CI can validate changes.

## 7. Dark Factory /fleet flow

Use this after the iteration plan is approved.

```text
/model GPT-5 Mini
Read @spec/iterations/iteration-1/plan.md and summarize the implementation plan.
```

If you want plan mode first, press `Shift+Tab` and refine the plan.

Then run:

```text
/fleet implement the approved iteration plan using the relevant custom agents, keep status documents updated, and stop on blocking issues.
```

Track work:

```text
/tasks
/usage
```

Assess the result:

```text
Read @.github/prompts/dark-factory/assess-iteration.prompt.md and assess the completed iteration.
```

## 8. Useful session commands

```text
/help
/session
/agent
/skills list
/skills reload
/model
/usage
/tasks

## Git committer identity (recommended)

To ensure commits created during Copilot runs attribute to your chosen automation or service account (and not to any other user), set a repository-local Git identity in each project before letting agents commit. Example:

```bash
# set a repo-local git identity for each project
for proj in solutions/*/; do
  git -C "$proj" config user.name "Your Automation Bot"
  git -C "$proj" config user.email "bot+solution@example.com"
done

# confirm for a specific project
git -C solutions/acme-api config user.name && git -C solutions/acme-api config user.email
```

Guidelines:
- Use an account/email you control for auditability.
- Avoid names or emails containing "copilot" unless that is your intended committer identity.
- For GitHub actions or CI, prefer a machine/service user and document its keys/permissions securely.

## How to verify stage completion

Use a small checklist to confirm a FORGE phase is complete. Agents produce artifacts in predictable locations — use these checks:

- Frame complete: `spec/business/frame.md` exists and has the actor registry and goals.
- Obstruct complete: `spec/business/obstruct-report.md` exists with identified risks and mitigation notes.
- Reconstruct complete: `spec/technical/api-contracts.yaml` and `spec/technical/architecture.md` exist and are reviewed.
- Generate complete: `solutions/` contains the implemented code for agreed stories and `spec/iterations/iteration-N/report.md` documents outputs.
- Edit complete: PRs merged, CI passing, and `spec/iterations/iteration-N/acceptance.md` contains signed QA validation.

Quick commands to help verify:

```bash
# list expected spec files
ls spec/business spec/technical || true

# list all projects
ls solutions/

# check for recent commits in a project
git -C solutions/acme-api log --oneline -n 10

# view open PRs (requires gh CLI)
gh pr list --repo ORG/REPO --state open

# Copilot task list
/tasks
```

For automation, agents can also write a `spec/stage-manifest.yaml` that records timestamps and agent names for each completed phase — consider adding this as a lightweight project convention.
```

## 9. Simple non-interactive usage

```bash
copilot -s -p "Read @.github/instructions/copilot-instructions.md and summarize the next FORGE step for this repo."
```

Use `--agent` when you want a specific custom agent:

```bash
copilot -s --agent devops-engineer -p "Review @solutions/acme-iac and suggest the next safe deployment change."
```