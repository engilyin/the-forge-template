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
> 7. Commit with author from local git config — NO Co-authored-by trailer
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
- [ ] **Service layer must NOT reference controller exception types** — services and DAO layers MUST NOT import or throw `org.springframework.web.server.ResponseStatusException`, `org.springframework.http.HttpStatus`, or any other controller-specific classes. Throw domain/service exceptions (e.g., `NotFoundException`, `ForbiddenException`) and let the controller or a global exception handler map them to HTTP responses.
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
- [ ] **Controller implements only the generated API interface** — a `@RestController` must implement exactly one `XxxApi` interface. It must **never** additionally `implement` a mapper or enum-converter interface (e.g., `implements SupportApi, SupportEnumMapper` is forbidden). All type conversion belongs in the injected mapper bean.
 - [ ] **Controller does not transform or wrap exceptions** — controllers must not perform exception translation or use `.onErrorMap` to change exception types. GlobalExceptionHandler handles error-to-HTTP mapping. Use controller-local `@ExceptionHandler` only when an error is truly controller-specific and cannot be mapped globally.

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
 - [ ] **Use persisted fields where specified** — do not compute data derived from persistence (e.g., do not compute job duration from logs when the `jobs.duration` DB column exists). Service must trust and return persisted values unless the spec requires computation.
 - [ ] **MapStruct for layer mapping** — do not manually copy or construct service models from entities in service code. Use a service-layer mapper (`services.<domain>.mappers`) to convert `Entity` → `ServiceModel` and `Entity` → `ServiceProjection`.
 
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
- [ ] **Field names aligned across layers** — if a field is named `eventType` in the OpenAPI spec, it MUST also be named `eventType` in the service model record AND in the DAO projection record. Mismatched names across layers (e.g., `eventName` in DAO vs `eventType` in service) force unnecessary `@Mapping` annotations and signal a design problem. Exception: `@Table` entities are exempt because they follow DB column naming conventions — use a DAO projection with `@Query` and explicit SQL column aliases to bridge the gap (DD-12).
- [ ] **`componentModel = "spring"` on every `@Mapper`** — every `@Mapper`-annotated interface MUST declare `componentModel = "spring"`. No mapper may omit this attribute.
- [ ] **Extend utility interfaces, do NOT use `uses` for plain interfaces (DD-01)** — controller-layer mappers that need `InstantMapper`, `JobStatusMapper`, or any other plain utility interface MUST extend those interfaces directly. Using `uses = {InstantMapper.class}` for plain Java utility interfaces is forbidden. See `spec/technical/g2sentry-portal-api-design-decisions.md`.
- [ ] **No inline `@Named` duplicating a shared utility (DD-02)** — if a conversion already exists in a shared utility mapper (`InstantMapper.toOffsetDateTime`, `JobStatusMapper.toApiStatus`, etc.), do NOT re-implement it with `@Named` in the consuming mapper. Extend the utility interface instead.

---

## 7. Testing Correctness

- [ ] **Unit tests are lightweight** — `@ExtendWith(MockitoExtension.class)` only. No `@SpringBootTest`, no `@ContextConfiguration`, no Spring context of any kind in unit tests.
- [ ] **Do not use `Mockito.mock(...)` statically in unit tests** — prefer `@Mock` fields + `@InjectMocks` with `MockitoExtension`. Static `Mockito.mock()` hides lifecycle and makes injection brittle.
- [ ] **NO `spring-boot-starter-test` as `testImplementation`** — tests use Gradle source set suites (`testing { suites { } }`). Unit test dependencies declared in the `test` suite, integration test dependencies in the `integrationTest` suite.
- [ ] **Services tested with unit tests** — `@ExtendWith(MockitoExtension.class)` + `@InjectMocks` + `@Mock` dependencies + `StepVerifier` for reactive assertions.
- [ ] **Controllers NOT unit tested** — controllers have no business logic and are therefore not unit-tested. Controller validation and integration flows are covered by integration tests.
 - [ ] **All service dependencies mocked** — unit tests must isolate the class-under-test: mock every dependency (repositories, mappers, HTTP clients, file I/O, etc.). No real DB, no real HTTP, no real filesystem access in unit tests.
 - [ ] **No logic inside unit tests** — tests must contain no business logic, conditional branches, loops, or computation. A unit test is a specification of expected behavior, not an algorithm. If you need helper behavior, extract it to a clearly named test utility method that contains no assertions and is easy to review.
 - [ ] **Avoid complex Mockito Answers / closures** — do not encode business logic inside Mockito Answer lambdas that mutate arguments or implement conditional flows. These are brittle and hide behavior from readers. Prefer simple stubs that return a concrete object.
 - [ ] **Prefer simple instantiated return objects in tests** — when a mocked dependency must return a value, instantiate a straightforward return object in the test and have the mock return it (e.g., `when(mapper.toX(...)).thenReturn(someX)`). This is explicit, deterministic, and easy to assert against.
 - [ ] **`StepVerifier` used for reactive assertions** — never `.block()` in tests.
 - [ ] **MapStruct mappers must be stubbed to return non-null values in unit tests** — when a MapStruct mapper is injected into the class under test, unit tests MUST mock its mapping methods to return a concrete, non-null object (instantiating a simple return object in the test is preferred). Do not leave mapper calls unstubbed (which yields null) and avoid mutable Mockito Answers; prefer returning a fresh object for clarity and determinism.
- [ ] **Integration tests in `src/integrationTest/java`** — controller and full-context tests must live in the integration test source set, not mixed with unit tests in `src/test/java`.
- [ ] **Integration tests properly annotated** — use `@WebFluxTest(controllers=...)` for controller slice tests and `@SpringBootTest(webEnvironment = RANDOM_PORT)` + `@AutoConfigureWebTestClient` for full-context controller/integration tests. Integration tests should use Testcontainers (`@Testcontainers`) and `@ActiveProfiles("test")`.
- [ ] **Delete legacy IT classes when migrating** — if you move tests into `src/integrationTest/java`, remove the matching legacy `*IT` classes from `src/test/java` to avoid duplicate execution and confusion.
- [ ] **Integration tests use Testcontainers** — real PostgreSQL container, not H2 (unless the test is a known H2-compatible DAO slice test).

---

## 8. Code Style & Imports

- [ ] **No fully qualified type names** — every class used in code has a corresponding `import` statement. Fully qualified names are only acceptable when two classes have the exact same simple name in the same compilation unit.
- [ ] **No unused imports** — no leftover imports from deleted or replaced code.
- [ ] **`spotlessApply` was run** — code is formatted before committing. Never commit unformatted code.
- [ ] **No unnecessary files** — no placeholder files, no "removed" comment-only files, no scaffolding scripts unrelated to the story.

---

## 8b. Messaging / SQS Correctness

- [ ] **Always prefer Spring abstractions for SQS** — use `@SqsListener` with `@Payload` for consumers. Never inject raw `SqsAsyncClient` / `SqsClient` to manually send or receive messages. For producers, prefer `SqsTemplate` over `SqsAsyncClient.sendMessage()` directly.
- [ ] **Never deserialize messages manually** — do NOT inject `ObjectMapper` and call `objectMapper.readValue(messageBody, ...)` in a listener. Declare the target type as the `@Payload` parameter and let the Spring Cloud AWS / Jackson integration handle deserialization automatically.
- [ ] **Claim-Check pattern for message payloads** — SQS messages must be as small as possible. Send only the primary identifier (e.g., `Long jobId`) and let the consumer look up full details from the DB. Never send full entity payloads in messages.
- [ ] **NEVER use `.block()` in a listener** — `@SqsListener` runs on a thread-pool thread, but calling `.block()` on a reactive chain from that thread stalls the listener thread and can cause deadlocks under load. Use `.subscribe(null, ex -> log.error(...))` for fire-and-forget routing and let the reactive chain complete asynchronously.
- [ ] **SQS update queries must be state-guarded** — an `updateEntityId` or similar mutation must include a `WHERE status IN (...)` guard to prevent silently overwriting records that are not in a routable state. The method must return `Mono<Integer>` (row count) so the caller can detect and log a 0-row update as a warning.

---

## 9. Files to Delete and DB Migrations

- [ ] **Files explicitly removed** — if a file was made redundant by the story (replaced by generated class, refactored away, moved), it is **deleted**, not emptied or commented out.
- [ ] **Legacy duplicates removed** — no two classes serving the same purpose at the same layer (e.g., both a hand-written `MyEntityRegistrationRequest` and the generated `MyEntity` request model).
- [ ] **DB migration scripts located correctly** — database migration SQL files must be created under the repository root path `/db/migration/` and follow Flyway naming conventions (e.g., `V3__add_owner_table.sql`). Migration scripts are applied by the CD pipeline — do NOT attempt to apply migrations from application startup. For DB schema changes, create a separate worktree in the target project repository (e.g., `solutions/acme-api` or the service repo) and make schema and application changes there.

---

## 9b. OpenAPI Spec Correctness

- [ ] **POST create endpoints return `201`** — any POST endpoint that creates a resource responds with `201 Created`, not `200 OK` (DD-07).
- [ ] **Enum query parameters use `$ref` to schema** — a query parameter whose value set is an enum must use `$ref: '#/components/schemas/EnumName'` as its schema type. Never use `type: string` for an enum parameter; this loses the generated Java type (DD-08).
 - [ ] **Enum fields modeled as separate schema objects** — any object property whose type is an enumeration must reference a separate enum schema under `components.schemas` (e.g., `$ref: '#/components/schemas/SupportStatus'`). Do NOT use `type: string` for enum fields.
 - [ ] **Enums declared first** — all enum schema objects must be defined at the start of `components.schemas` before object models. This ordering ensures deterministic codegen and readability.
- [ ] **Shared parameters defined in `components/parameters`** — common query params (`dateFrom`, `dateTo`, `entityId`, `offset`, `max`, `status` filters) must be defined once and referenced via `$ref`. No inline duplication across endpoints (DD-09).
- [ ] **Pagination parameters are `offset`/`max`** — never `page`/`size` (DD-05).
- [ ] **List responses use `type: array` schema, not a page wrapper** — a `GET` endpoint returning a collection MUST declare its response schema as `type: array` with `items: $ref` so the generator emits `Flux<T>`. Returning a wrapped object like `{ content: [...], totalPages: N }` from a list endpoint is **forbidden** unless the product explicitly requires count metadata (DD-14).

---

## 10. Build Verification (mandatory before commit)

- [ ] `./gradlew spotlessApply` — no formatting violations remain
- [ ] `./gradlew clean build` — **BUILD SUCCESSFUL**, zero compile errors
- [ ] `./gradlew integrationTest` — **BUILD SUCCESSFUL**, all integration tests pass
- [ ] No regressions — all tests that existed before the story still pass

---

## 11. Commit & PR

- [ ] **Author is default set on the repo** — use `git commit -m "..."` with no `--author` flag, no `Co-authored-by` trailers. The commit author must be the default configured on the local machine, with no additional trailers.
- [ ] **NO `Co-authored-by: Copilot` trailer** — this trailer must never appear in any commit message in this repository
- [ ] **Branch name matches story** — `feature/US-XX-YY` format
- [ ] **PR created in the correct project repo** — not in the scaffold root repo
- [ ] **Story status updated** — story file `spec/iterations/iteration-2/stories/US-XX-YY.md` status changed to `done`, and `spec/iterations/iteration-2/status.md` row updated

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
| `@Mapper(uses = {InstantMapper.class})` for plain utility | `implements InstantMapper` via `extends` (DD-01) |
| `@Named("toOffsetDateTime")` inlined in mapper body | Extend `InstantMapper` — the method already exists (DD-02) |
| `@Mapper` without `componentModel = "spring"` | Always add `componentModel = "spring"` (DD-03) |
| `class FooController implements FooApi, SomeEnumMapper` | `implements FooApi` only; call `mapper.convert(x)` instead (DD-04) |
| `POST /resources` returning `200` | Must return `201 Created` (DD-07) |
| OpenAPI `type: string` for enum query param | `schema: $ref: '#/components/schemas/EnumName'` (DD-08) |
| Inline parameter definition repeated per endpoint | Define once in `components/parameters`, reference via `$ref` (DD-09) |
| `@Mapper(uses = {InstantMapper.class})` for plain utility | `implements InstantMapper` via `extends` (DD-01) |
| `sqsAsyncClient.sendMessage(...)` in producer | Use `SqsTemplate.send(...)` — prefer Spring abstraction |
| `.block()` inside `@SqsListener` handler | Use `.subscribe(null, ex -> log.error(...))` — fully async |
| Full entity / all fields in SQS message | Claim-Check: send only `Long jobId`; consumer fetches details from DB |
| Service throwing `ResponseStatusException` or referencing `HttpStatus` | Throw domain/service exceptions (e.g., `NotFoundException`, `ForbiddenException`) and map them in the controller/global handler |