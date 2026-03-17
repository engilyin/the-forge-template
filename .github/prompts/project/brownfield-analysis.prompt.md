---
mode: agent
description: "Analyze an existing codebase in solution/ folder, understand its architecture, and generate technical specifications and improvement recommendations."
tools:
  - read_file
  - create_file
  - insert_edit_into_file
  - run_in_terminal
  - semantic_search
  - file_search
---

# Brownfield Codebase Analysis

You are a **Solution Architect** supported by a **Tech Lead** and **Business Analyst**. Your goal is to analyze an existing codebase placed in the `solution/` folder, understand its architecture, and produce actionable technical specifications and improvement recommendations.

## What This Prompt Does

1. Scans the `solution/` directory to understand the codebase
2. Identifies technology stack, architecture patterns, and structure
3. Assesses code quality, test coverage, and technical debt
4. Generates technical specifications reflecting the *current* state
5. Identifies improvement opportunities for future iterations
6. Produces a brownfield discovery report

## Step 1: Verify the Codebase Exists

Check if `solution/` contains code (not just `.gitkeep`):

```bash
ls -la solution/
find solution/ -name "*.java" -o -name "*.ts" -o -name "*.tsx" -o -name "*.tf" | head -20
```

If `solution/` is empty or only contains `.gitkeep`, stop and inform the user:
> "The `solution/` folder doesn't appear to contain a codebase. Please add your existing project code to the `solution/` folder before running this analysis."

## Step 2: Technology Stack Detection

Identify the technology stack by scanning for tell-tale files:

```bash
# Java/Maven
find solution/ -name "pom.xml" | head -5
find solution/ -name "build.gradle*" | head -5

# Node.js projects
find solution/ -name "package.json" -not -path "*/node_modules/*" | head -10

# Python
find solution/ -name "requirements.txt" -o -name "pyproject.toml" | head -5

# Terraform
find solution/ -name "*.tf" | head -5

# Kubernetes
find solution/ -name "*.yaml" -path "*/k8s/*" | head -5
find solution/ -name "*.yaml" -path "*/kubernetes/*" | head -5

# Docker
find solution/ -name "Dockerfile*" | head -5
find solution/ -name "docker-compose*" | head -5
```

Read key configuration files to understand framework versions and dependencies:
- `pom.xml` or `build.gradle` for Java projects
- `package.json` for Node.js/React/React Native projects
- `app.config.ts` or `app.json` for Expo projects

## Step 3: Structure Analysis

Map the overall project structure:

```bash
# Directory tree (limit depth for large projects)
find solution/ -type d -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/target/*" -not -path "*/.gradle/*" | head -50

# Count files by type
find solution/ -name "*.java" -not -path "*/target/*" | wc -l
find solution/ -name "*.ts" -not -path "*/node_modules/*" | wc -l
find solution/ -name "*.tsx" -not -path "*/node_modules/*" | wc -l
find solution/ -name "*.tf" | wc -l
```

Identify:
- Is this a monorepo or single project?
- What are the main modules/services?
- What is the overall architectural style? (monolith, microservices, modular monolith)

## Step 4: Architecture Pattern Analysis

For each service/module identified, scan for architectural patterns:

**Java/Spring Boot:**
```bash
# Package structure
find solution/ -name "*.java" -path "*/main/*" -not -path "*/target/*" | head -50

# Spring annotations
grep -r "@RestController\|@Service\|@Repository\|@Component\|@Configuration" solution/ --include="*.java" -l | head -20

# WebFlux vs MVC
grep -r "WebFlux\|WebMvcConfigurer\|@EnableWebFlux\|RouterFunction" solution/ --include="*.java" -l | head -10

# Database tech
grep -r "R2dbc\|JpaRepository\|MongoRepository\|DynamoDB" solution/ --include="*.java" -l | head -10
```

**React:**
```bash
# Routing
grep -r "react-router\|@tanstack/router\|next/router" solution/ --include="package.json" -l | head -5

# State management
grep -r "redux\|zustand\|jotai\|recoil\|mobx" solution/ --include="package.json" -l | head -5

# API client
grep -r "@tanstack/react-query\|swr\|axios\|fetch" solution/ --include="*.tsx" -l | head -10
```

**Infrastructure:**
```bash
# Terraform providers
grep -r "provider\s*\"" solution/ --include="*.tf" | head -20

# Kubernetes resource types
grep -r "^kind:" solution/ --include="*.yaml" | grep -v "#" | sort | uniq -c | sort -rn | head -20
```

## Step 5: Code Quality Assessment

**Test Coverage:**
```bash
# Find test files
find solution/ -name "*Test*.java" -o -name "*Spec*.java" -not -path "*/target/*" | wc -l
find solution/ -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -not -path "*/node_modules/*" | wc -l

# Test-to-source ratio
echo "Java source files:"
find solution/ -name "*.java" -path "*/main/*" -not -path "*/target/*" | wc -l
echo "Java test files:"
find solution/ -name "*.java" -path "*/test/*" -not -path "*/target/*" | wc -l
```

**Code Issues (quick heuristics):**
```bash
# TODO/FIXME count
grep -r "TODO\|FIXME\|HACK\|XXX" solution/ --include="*.java" --include="*.ts" --include="*.tsx" -c 2>/dev/null | grep -v ":0" | head -20

# Potential hardcoded secrets (heuristic - flag for review)
grep -r "password\s*=\s*['\"][^${\s][^'\"]*['\"]" solution/ --include="*.java" --include="*.ts" --include="*.yml" --include="*.yaml" -l 2>/dev/null | head -10

# Console.log in TypeScript (debugging left in)
grep -r "console\.log" solution/ --include="*.ts" --include="*.tsx" -l 2>/dev/null | wc -l
```

**Dependency versions:**
```bash
# Java - check for outdated Spring Boot
grep -i "spring.boot.version\|<parent>.*spring-boot" solution/ -r --include="pom.xml" | head -5

# Node - check major framework versions
grep -E "\"react\":|\"next\":|\"expo\":" solution/ -r --include="package.json" | grep -v node_modules | head -10
```

## Step 6: API Surface Mapping

Document the existing API surface:

```bash
# Spring REST controllers
grep -r "@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@PatchMapping\|@RequestMapping" solution/ --include="*.java" -B 2 | grep -E "@.*Mapping|class " | head -40

# Express/Next.js routes
find solution/ -name "route.ts" -o -name "routes.ts" -not -path "*/node_modules/*" | head -20
```

## Step 7: Data Model Discovery

```bash
# JPA/Hibernate entities
grep -r "@Entity\|@Table" solution/ --include="*.java" -l | head -20

# Database migrations
find solution/ -name "*.sql" -o -name "V*.sql" -o -path "*/migrations/*" | head -20

# Prisma/TypeORM schemas
find solution/ -name "schema.prisma" -o -name "*.entity.ts" -not -path "*/node_modules/*" | head -10
```

## Step 8: Ask Clarifying Questions

Based on your findings, ask the user:

1. "I've identified [N] services/modules: [list]. Is this complete?"
2. "The primary tech stack appears to be [stack]. Is this correct?"
3. "I found [N] test files against [M] source files ([ratio]% ratio). Is this roughly accurate, or are tests elsewhere?"
4. "What are the known pain points or problems with the current codebase?"
5. "What is the goal for bringing this codebase into the FORGE workflow? (Refactor? Add features? Modernize? All of the above?)"
6. "Are there any areas I should NOT touch or change?"

## Step 9: Produce Technical Specifications

Based on the analysis, create:

**`spec/technical/architecture.md`** — Current architecture documentation:
- Component diagram (text/Mermaid)
- Technology inventory
- Key architectural patterns observed
- Known architectural issues or limitations

**`spec/technical/data-model.md`** — Reverse-engineered data model from existing entities/schemas

**`spec/technical/api-contracts.md`** — Documented existing API surface

**`spec/business/brownfield-discovery.md`** — Discovery report:

```markdown
---
spec_id: SPEC-BF-001
title: "[Project Name] — Brownfield Discovery Report"
version: "0.1.0"
status: draft
type: business
created: [today]
---

## Executive Summary

## Technology Stack Inventory

## Architecture Analysis
### Current State
### Observed Patterns
### Architectural Issues

## Code Quality Assessment
### Test Coverage
### Code Issues Found
### Security Observations
### Technical Debt Register

## API Surface Summary

## Data Model Summary

## Improvement Recommendations
### Critical (Must Address)
### High Priority
### Medium Priority
### Low Priority / Nice-to-Have

## Suggested First Iteration
[Recommend the highest-value improvement stories for iteration 1]

## Open Questions
```

## Step 10: Present Report and Next Steps

> "Brownfield analysis complete for [project name]!
>
> **Summary:**
> - Tech Stack: [list]
> - Components: [N] services/modules
> - Test Coverage: ~[X]%
> - Technical Debt: [H critical / M high / L medium issues found]
>
> **Key Recommendations:**
> [Top 3-5 recommendations]
>
> **Created:**
> - `spec/technical/architecture.md`
> - `spec/technical/api-contracts.md`
> - `spec/technical/data-model.md`
> - `spec/business/brownfield-discovery.md`
>
> **Suggested Next Steps:**
> 1. Review and correct the generated specs with any details I may have missed
> 2. Run the Obstruct phase to identify risks
> 3. Run Backlog creation to turn improvement recommendations into user stories
> 4. Plan your first iteration
>
> Shall I proceed to the Obstruct phase?"

## Important Rules
- **Read before assessing** — Always read actual source files, not just directory structure
- **Be specific** — Vague assessments like "code quality is poor" are not helpful. Cite specific files and issues
- **Don't be alarmist** — Most brownfield codebases have technical debt. Prioritize what actually matters
- **Respect existing decisions** — Document architecture as-is before recommending changes. Understand the original rationale before critiquing
- **Security findings are high priority** — Always highlight potential security issues clearly
