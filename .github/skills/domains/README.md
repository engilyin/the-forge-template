# Domain Skills Layout

Domain skills are reusable capability packs that apply across multiple implementation stacks.

Use domain skills for concerns such as:
- API design and contracts
- Specification authoring and traceability
- Testing and quality practices
- Documentation and Architecture as Code

## Registry

- Domain registry: `.github/skills/domains/_registry.md`
- Global catalog: `.github/skills/catalog.yaml`

## Authoring Rules

1. Keep one domain per folder with direct canonical files (no index entrypoint).
2. Keep domain files focused and composable.
3. Reference stack files that consume the domain.
