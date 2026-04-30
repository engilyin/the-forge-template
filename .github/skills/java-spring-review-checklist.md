---
name: "Java Spring Review Checklist"
description: "Mandatory pre-commit review checklist for every Java/Spring Boot WebFlux story. All items must pass before committing and raising a PR."
user-invocable: true
---

# Java Spring — Pre-Commit Review Checklist

> **Every Java/Spring story MUST pass this checklist before the code is committed and a PR is raised.**
> Validate each item against the changes made. Fix every ❌ before proceeding.
>
> **Mandatory build sequence (in order):**
> 1. `./gradlew openApiGenerate`  — regenerate API classes from spec
> 2. Implement the story
> 3. `./gradlew spotlessApply`    — auto-format code
> 4. `./gradlew clean build`      — compile + unit tests
> 5. `./gradlew integrationTest`  — integration tests
> 6. All items on this checklist pass
> 7. Commit do not setting the author and let Git use the default — NO Co-authored-by trailer
> 8. Push branch and open PR

---

## 1. API-First Compliance

- [ ] **OpenAPI spec updated first** — any new or changed endpoint exists in `spec/technical/api-contracts.yaml` before any implementation code was written.
- [ ] **`./gradlew openApiGenerate` was run** after pulling or modifying the spec. Java classes in `build/generated/openapi/` are up to date.
- [ ] **Controller implements the generated interface** — e.g., `implements MyEntityApi`. The controller does NOT redeclare `@PostMapping`, `@GetMapping`, or any other mapping annotations.
- [ ] **Validation annotations NOT duplicated** — `@Valid`, `@NotNull`, `@Size`, etc. declared in the generated interface are NOT re-annotated on the controller method parameters.
- [ ] **Generated model classes used** — no hand-written request/response classes that duplicate what the generator already produced (e.g., no custom `MyEntityRegistrationRequest` alongside a generated `MyEntity`).

---

## 2. Layer Separation — ABSOLUTE RULES

- [ ] **Service layer knows nothing about the controller layer** — service classes import nothing from `controllers.*` packages. No generated OpenAPI model class (`com.mycompany.controllers.openapi.*`) imported in a service.
- [ ] **No entity reaches the controller** — `@Table` entities are never returned from a service or mapped directly to API responses.
- [ ] **No OpenAPI model reaches the DAO** — generated API model classes are never passed into a repository or used as a DAO data object.
- [ ] **Each layer has its own data classes** — controller uses generated models and controller-level records, service uses `services.<domain>.models.*` records, DAO uses entity and projection records.
- [ ] **Service models in correct package** — service-layer data records live under `services.<domain>.models` (e.g., `com.mycompany.services.myentity.models.CreateMyEntityRequest`), not under `requests/` or any controller package.

---

## 3. Controller Correctness

- [ ] **Controller is dumb** — zero business logic. Only: assemble request records, delegate to service, map response.
- [ ] **Uses method references** — `service::method` and `mapper::toApi` in reactive chains, not multi-statement lambdas.
- [ ] **No `if` for business rules** — only structural null guards are acceptable.
- [ ] **Reactive chain correct** — `body.map(mapper::toRequest).flatMap(service::create).map(apiMapper::toApi)` — no `.block()` anywhere.
- [ ] **`@Override` on every generated-interface method** — ensures compile-time verification of contract adherence.

---

## 4. Service Layer Correctness

- [ ] **No service interface** — do NOT create `public interface MyEntityService` + `MyEntityServiceImpl`. This is an anti-pattern. Use a plain named `@Service` class (e.g., `MyEntityCreationService`).
- [ ] **Reactive patterns** — no `Mono.defer` for simple flows. Use `.switchIfEmpty(Mono.error(...))` for "not found" / "already exists" logic.
- [ ] **No imperative code inside reactive chain** — no mutable variables, no `if/else`, no multi-statement lambdas inside `.map()` or `.flatMap()`. Extract named private methods.
- [ ] **Duplicate-check pattern is correct**:
  ```java
  return repository.findByEmailIgnoreCase(request.email())
      .flatMap(existing -> Mono.error(new DuplicateResourceException(...)))
      .switchIfEmpty(Mono.defer(() -> Mono.just(toEntity(request)))
          .flatMap(repository::save)
          .map(this::toModel));
  ```
- [ ] **No useless null assignments** — do not set fields to `null` explicitly; they are null by default.
- [ ] **No setting entity default values to a fixed constant** — do not write `private boolean locked = true` in entity or in service logic unless that is the documented business rule (and it comes from the spec, not invented).
- [ ] **`@Transactional` on write methods** — service write operations annotated with `@Transactional`.

---

## 5. Repository / DAO Correctness

- [ ] **No unbounded `Flux<Entity> findAll()`** — never return all records without pagination. If you need a list, it must be paginated (cursor or offset). Violating this causes OOM under load.
- [ ] **Prefer naming-convention methods over `@Query`** — `findByEmailIgnoreCase`, `existsByName`, `findByEntityIdAndDisabled` etc. Use `@Query` only when naming convention cannot express the query.
- [ ] **Prefer projection records over full entities for read queries** — if a query needs only 3 fields, return a record with those 3 fields, not the whole entity.
- [ ] **Entities used for persistence only** — `save()`, `delete()`, `findById()` (full entity needed). All other reads should use projections.
- [ ] **No `@Query` for simple derivable queries** — if Spring Data can generate it from the method name, do not write `@Query`.

---

## 6. MapStruct Mapper Correctness

- [ ] **No redundant `@Mapping` for same-name fields** — MapStruct infers same-name fields automatically. Never write `@Mapping(target = "name", source = "name")`.
- [ ] **`@Mapping` imported, not fully qualified** — always `import org.mapstruct.Mapping;` at the top; never use `@org.mapstruct.Mapping(...)` inline.
- [ ] **No fully qualified type names anywhere** — use imports for all types, unless there is an actual naming conflict between two classes with the same simple name.
- [ ] **Mappers placed in the correct layer** — controller mappers in `controllers/<domain>/mappers/`, service mappers in `services/<domain>/mappers/`, DAO mappers in `dao/<domain>/mappers/`.
- [ ] **No expression mappings for simple cases** — `expression = "java((String) null)"` or `expression = "java(model.getX())"` for trivial cases is a red flag. If you need an expression, first ask: does the field exist in the source? If not, add it.
- [ ] **No unmapped required fields** — MapStruct warnings about unmapped target properties must be resolved (add `@Mapping(target="field", ignore=true)` only if the field is truly unused, otherwise add the mapping).
- [ ] **Field names aligned across layers** — if a field is named `entityId` in the OpenAPI spec, it should be `entityId` in the service model and `entityId` in the entity. Inconsistent naming forces extra `@Mapping` annotations and signals a design problem.

---

## 7. Testing Correctness

- [ ] **Unit tests are lightweight** — `@ExtendWith(MockitoExtension.class)` only. No `@SpringBootTest`, no `@ContextConfiguration`, no Spring context of any kind in unit tests.
- [ ] **NO `spring-boot-starter-test` as `testImplementation`** — tests use Gradle source set suites (`testing { suites { } }`). Unit test dependencies declared in the `test` suite, integration test dependencies in the `integrationTest` suite.
- [ ] **Services tested with unit tests** — `@ExtendWith(MockitoExtension.class)` + `@InjectMocks` + `@Mock` dependencies + `StepVerifier`.
- [ ] **Controllers NOT unit tested** — controllers have no business logic and are therefore not unit-tested. Controller validation and integration flows are covered by integration tests.
- [ ] **All service dependencies mocked** — no real DB, no real HTTP, no real file I/O in unit tests.
- [ ] **`StepVerifier` used for reactive assertions** — never `.block()` in tests.
- [ ] **Integration tests in `src/integrationTest/java`** — not mixed with unit tests in `src/test/java`.

---

## 8. Code Style & Imports

- [ ] **No fully qualified type names** — every class used in code has a corresponding `import` statement. Fully qualified names are only acceptable when two classes have the exact same simple name in the same compilation unit.
- [ ] **No unused imports** — no leftover imports from deleted or replaced code.
- [ ] **`spotlessApply` was run** — code is formatted before committing. Never commit unformatted code.
- [ ] **No unnecessary files** — no placeholder files, no "removed" comment-only files, no scaffolding scripts unrelated to the story.

---

## 9. Files to Delete

- [ ] **Files explicitly removed** — if a file was made redundant by the story (replaced by generated class, refactored away, moved), it is **deleted**, not emptied or commented out.
- [ ] **Legacy duplicates removed** — no two classes serving the same purpose at the same layer (e.g., both a hand-written `MyEntityRegistrationRequest` and the generated `MyEntity` request model).

---

## 10. Build Verification (mandatory before commit)

- [ ] `./gradlew spotlessApply` — no formatting violations remain
- [ ] `./gradlew clean build` — **BUILD SUCCESSFUL**, zero compile errors
- [ ] `./gradlew integrationTest` — **BUILD SUCCESSFUL**, all integration tests pass
- [ ] No regressions — all tests that existed before the story still pass

---

## 11. Commit & PR

- [ ] **Author is default which could be returned by `git config user.name` and `git config user.email`** — use `git commit -m "..."` without `--author` flag, so that the commit author is the actual committer.
- [ ] **NO `Co-authored-by: Copilot` trailer** — this trailer must never appear in any commit message in this repository
- [ ] **Branch name matches story** — `feature/US-XX-YY` format
- [ ] **PR created in the correct project repo** — not in the scaffold root repo
- [ ] **Story status updated** — story file `spec/iterations/iteration-<iterationNo>/stories/US-XX-YY.md` status changed to `done`, and `spec/iterations/iteration-<iterationNo>/status.md` row updated

---

## Quick Reference — Common Anti-Patterns to Reject

| Anti-Pattern | Correct Approach |
|---|---|
| `public interface MyEntityService` + `MyEntityServiceImpl` | Plain `@Service MyEntityCreationService` — no interface |
| `Flux<MyEntity> findAll()` without pagination | Paginated query with cursor or offset parameter |
| `@Query("SELECT ...")` for a simple filter | `findByEmailIgnoreCase(String email)` naming convention |
| `private boolean locked = true` default in entity | Set defaults in service logic, not in entity field declarations |
| `@Mapping(target = "name", source = "name")` | Omit — MapStruct infers same-name fields automatically |
| `@org.mapstruct.Mapping(...)` fully qualified | `import org.mapstruct.Mapping;` + `@Mapping(...)` |
| `expression = "java((String) null)"` in mapper | Add the field to the source record/entity so it can be mapped |
| `Mono.defer(() -> Mono.just(x)).flatMap(...)` for simple flow | `Mono.just(x).flatMap(...)` or extract method |
| Service importing `com.mycompany.controllers.openapi.*` | Service defines its own model in `services.<domain>.models.*` |
| `testImplementation 'org.springframework.boot:...'` | Use `testing { suites { test { dependencies { implementation '...' } } } }` |
| `@SpringBootTest` in a service unit test | `@ExtendWith(MockitoExtension.class)` only |
| Re-annotating `@NotNull` on controller params from generated interface | Remove — validation is inherited from the interface |
| Committing without running `spotlessApply` | Always run `./gradlew spotlessApply` first |
| `Co-authored-by: Copilot` in commit message | Remove — only default author, no trailers |
