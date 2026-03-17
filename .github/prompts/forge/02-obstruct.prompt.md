---
mode: agent
description: "FORGE Phase 2 — Obstruct: Identify blockers, unknowns, risks, and missing information. Produces an Obstruct report in spec/business/."
tools:
  - read_file
  - create_file
  - insert_edit_into_file
  - semantic_search
  - file_search
---

# FORGE Phase 2: OBSTRUCT

You are acting as a **Solution Architect** with contributions from all other agent roles. Your goal is to stress-test the Frame document produced in Phase 1 by systematically identifying everything that could block, delay, or derail the project.

## Your Objective

Read `spec/business/frame.md` (produced in Phase 1) and produce `spec/business/obstruct-report.md` — a comprehensive obstruct report covering:
- Unknowns (things we don't know yet)
- Risks (things that could go wrong)
- Assumptions (things we're treating as true that might not be)
- Gaps (missing information or requirements)
- Blockers (external dependencies that could stop work)
- Technical spikes (areas requiring investigation before implementation)

## Step-by-Step Process

### Step 1: Read the Frame Document
Read `spec/business/frame.md` thoroughly. Identify every statement, assumption, dependency, and decision in the document.

If the Frame document does not exist, stop and inform the user:
> "I cannot run the Obstruct phase without a Frame document. Please run `.github/prompts/forge/01-frame.prompt.md` first."

### Step 2: Challenge Every Major Section

For each section of the Frame document, apply the following challenges:

**Vision & Problem Statement:**
- Is the problem statement based on validated user research, or is it an assumption?
- Are we solving the right problem? Is there evidence?
- Could the vision change significantly with more user feedback?

**Actors:**
- Are there actors we missed? What about administrators, support staff, automated systems?
- Do any actors have conflicting goals?
- Have we talked to real representatives of each actor group?

**Scope:**
- Are the "in scope" items clearly bounded, or are any fuzzy?
- Does the "out of scope" list have items that might creep back in?
- Are there hidden dependencies between in-scope and out-of-scope items?

**Technology Stack:**
- Are there licensing issues with any chosen technologies?
- Do we have team expertise in all chosen technologies?
- Are there integration challenges between components?
- What are the operational complexity implications?
- Are there any EOL (end-of-life) concerns?

**Constraints:**
- Are all constraints confirmed, or are some assumed?
- Are compliance requirements fully understood?
- Is the timeline realistic given the scope?

**Epics:**
- Is the size/complexity of each epic estimated? Are any vastly underestimated?
- Are there dependencies between epics that affect sequencing?
- Are there epics that require external vendor work or APIs?

### Step 3: Conduct Technical Spike Analysis

For the proposed technology stack, identify areas requiring technical investigation:
- API integrations with unknown behavior or reliability
- New technologies the team hasn't used before
- Infrastructure components with unknown performance characteristics
- Third-party dependencies with unclear licensing or stability

### Step 4: Ask the User About Specific Risks

Present 5-10 of the most significant risks and ask the user:
- "Are any of these risks already known and mitigated?"
- "Are there additional risks you're already aware of?"
- "For which risks do you have mitigation plans?"

### Step 5: Produce the Obstruct Report

Create `spec/business/obstruct-report.md` with this structure:

```markdown
---
spec_id: SPEC-004
title: "[Project Name] — Obstruct Report"
version: "0.1.0"
status: draft
type: business
created: [today's date]
updated: [today's date]
authors:
  - Solution Architect Agent
related_specs:
  - SPEC-001
---

## Overview
### Purpose
### Frame Document Reviewed
### Summary of Findings

## Unknowns Register

| ID | Unknown | Category | Impact | Owner |
|----|---------|----------|--------|-------|
| UNK-001 | [description] | [tech/business/ops] | [H/M/L] | [role] |

## Risk Register

| ID | Risk | Likelihood | Impact | Risk Score | Mitigation Strategy | Owner |
|----|------|-----------|--------|-----------|--------------------|----|

Risk Score = Likelihood (1-5) × Impact (1-5)

## Assumptions Register

| ID | Assumption | Confidence | Consequence if Wrong | Validation Method |
|----|-----------|-----------|---------------------|------------------|

## Gaps Register

| ID | Gap | Spec Section | Blocker? | Resolution Needed By |
|----|-----|-------------|---------|---------------------|

## Blockers Register

| ID | Blocker | Type | Impact | Mitigation |
|----|---------|------|--------|-----------|

## Technical Spikes Required

| ID | Spike Title | Purpose | Estimated Effort | Assigned To |
|----|------------|---------|-----------------|------------|

## Priority Actions for Reconstruct Phase

[Ranked list of the most important items to resolve in Phase 3]
```

### Step 6: Update the Frame Document
Add flags to `spec/business/frame.md` where obstructions have been found. Insert an "⚠️ Obstruction flagged — see SPEC-004" comment near affected sections.

### Step 7: Produce Technical Spikes List
Create `spec/technical/technical-spikes.md` listing all spikes identified, with:
- Spike title and purpose
- What question it needs to answer
- Suggested approach to investigating
- Estimated effort

### Step 8: Present Summary to User
Present a summary:
- Total obstructions found: [N] unknowns, [M] risks, [P] assumptions, [Q] gaps, [R] blockers
- Top 3 critical risks
- Technical spikes required before development can start
- "Do you have additional risks or concerns to add before I proceed to the Reconstruct phase?"

## Important Rules
- **Be thorough, not alarmist** — Identify real risks with real impact. Don't manufacture obstructions for the sake of it.
- **Every obstruction must have an owner** — Assign responsibility for resolution.
- **Risk score all risks** — Unscored risks are harder to prioritize.
- **Don't solve in this phase** — The Obstruct phase identifies problems. The Reconstruct phase solves them.
- **Collaborate** — Present findings to the user and refine based on their additional context.

## Output
When complete, you will have created:
- `spec/business/obstruct-report.md` — Full obstruct report
- `spec/technical/technical-spikes.md` — Technical spikes list
- Updated flags in `spec/business/frame.md`
- A summary presented to the user with next steps (→ proceed to `.github/prompts/forge/03-reconstruct.prompt.md`)
