# Architecture as Code with Structurizr DSL

## Purpose

Define, version, and validate architecture models as code using Structurizr DSL so diagrams stay aligned with implementation.

## When to Use

- You need maintainable C4 diagrams in source control.
- Architecture docs change frequently across services.
- You want reviewable architecture changes in pull requests.

## When Not to Use

- One-off static diagram exports with no planned maintenance.
- Small spikes where architecture has not stabilized.

## Baseline Conventions

1. Keep Structurizr files in a predictable location (for example `docs/architecture/` or `architecture/`).
2. Maintain one workspace DSL file as the entry point.
3. Model C4 levels progressively: system context, containers, components (when useful).
4. Keep names and tags stable to reduce diagram churn.
5. Reuse styles and themes; avoid ad-hoc visual choices per diagram.
6. Treat architecture model updates as part of feature delivery, not a separate afterthought.

## Suggested Repository Structure

```text
architecture/
  workspace.dsl
  views/
  styles.dsl
  decisions/
```

## Review Checklist

- Model reflects current deployed topology.
- Every new service/component in code is represented in DSL.
- Relationship directions and protocols are explicit.
- External dependencies are tagged and bounded.
- Generated diagrams are readable without manual edits.

## CI Validation

- Parse/validate Structurizr DSL in CI on pull requests.
- Fail the build when DSL is invalid.
- Optionally export diagrams as build artifacts.

## Integration with FORGE

- During Reconstruct: define baseline architecture model and scope.
- During Generate: update DSL alongside implementation changes.
- During Edit: validate model correctness and readability.
- During Amend: update architecture model when decisions evolve.
