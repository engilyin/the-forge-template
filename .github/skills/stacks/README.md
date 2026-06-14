# Stack Skills Layout and Tool Compatibility

This directory provides stable stack entry points that are compatible with:
- VS Code GitHub Copilot chat and prompt attachments
- Copilot CLI prompts and agent workflows
- Claude Code style prompt workflows

This folder is intentionally focused on stack-specific workflows. Shared, cross-stack knowledge lives in `.github/skills/domains/`.

## Contract

Each stack directory must contain these files:
- patterns.md
- review-checklist.md
- story-template.md

Optional files are allowed (for example phase0-template.md or feature-specific pattern docs).

## Why this layout

- Stable relative paths make prompts portable across tools.
- Stack folders stay small and actionable, while domain folders hold reusable guidance.

## Pluggable Model

- Stack registry: `.github/skills/stacks/_registry.md`
- Domain registry: `.github/skills/domains/_registry.md`
- Optional machine-readable catalog: `.github/skills/catalog.yaml`

When adding capabilities, decide first:
- If it is implementation workflow tied to a language/runtime/framework, add a stack.
- If it is reusable knowledge (API design, specs, testing strategy, documentation, Architecture as Code), add a domain.

## Authoring rules

1. Keep stack files as entry points, not duplicated long-form content.
2. Prefer links to canonical files in stack/domain folders first; use flat skill files only as compatibility references.
3. When adding a stack, update `_registry.md` and create a matching wrapper in `.agents/skills` when needed.
4. Ensure prompt references use repository-relative paths only.

## Path conventions for cross-tool compatibility

- Use forward-slash relative paths: .github/skills/stacks/react-web/patterns.md
- Avoid editor-specific URI schemes.
- Keep prompt instructions explicit about required input files.
