# Domain Skill Registry

> This file lists cross-stack skill domains supported by this FORGE scaffold.

---

## Active Domains

| Domain | Directory | Purpose | Canonical References |
|---|---|---|---|
| API Design | `api-design/` | API-First conventions, OpenAPI quality, endpoint semantics | `.github/skills/domains/api-design/api-first.md` |
| Specification Authoring | `spec-authoring/` | OpenSpec authoring lifecycle and traceability | `.github/skills/domains/spec-authoring/openspec-authoring.md` |
| Quality Engineering | `quality-engineering/` | Shared testing, review, and refactoring guidance | `.github/skills/domains/quality-engineering/testing.md`, `.github/skills/domains/quality-engineering/code-review.md`, `.github/skills/domains/quality-engineering/refactoring.md` |
| AWS Platform | `aws-platform/` | AWS infrastructure provisioning and ECS/Fargate runtime/deployment guidance | `.github/skills/domains/aws-platform/aws-terraform-jenkins-infrastructure.md`, `.github/skills/domains/aws-platform/aws-ecs-fargate-runtime-deployments.md` |
| Documentation and AaC | `documentation-aac-structurizr/` | Documentation standards and Architecture as Code with Structurizr DSL | `.github/skills/domains/documentation-aac-structurizr/documentation.md`, `.github/skills/domains/documentation-aac-structurizr/architecture-as-code-structurizr.md` |

---

## Adding a New Domain

1. Create directory: `.github/skills/domains/<domain-name>/`
2. Create canonical files in that directory (for example `api-first.md`, `testing.md`, `documentation.md`).
3. Add the domain to the **Active Domains** table.
4. Update `.github/skills/catalog.yaml`.
5. Add `.agents/skills/<domain-skill>/SKILL.md` wrapper if direct invocation is useful.

## Removing a Domain

1. Remove the domain directory.
2. Remove it from the **Active Domains** table.
3. Remove it from `.github/skills/catalog.yaml`.
4. Remove wrappers only after all prompts no longer reference the domain.
