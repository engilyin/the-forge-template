---
name: "Spring Boot WebFlux"
description: "Quality and architecture guidance for Spring Boot WebFlux services."
user-invocable: false
---

# Spring Boot WebFlux — Quality Code Skill

> Apply this skill when designing, implementing, reviewing, or generating any Java Spring Boot WebFlux backend code. It covers project structure, architecture layers, reactive patterns, clean code principles, and anti-patterns to avoid.
>
> **Technology baseline:** Java 25 LTS · Spring Boot 4.x · Spring WebFlux · Jackson 3

---

## Project Structure

A well-organised Spring Boot WebFlux project follows a **domain-first package layout** — one top-level package per bounded context, inside each a consistent set of sub-packages by layer.

```
src/main/java/com/example/myapp/
│
├── Application.java                    ← Single main class
├── Consts.java                         ← Application-wide constants (API_BASE, etc.)
│
├── config/                             ← Cross-cutting Spring @Configuration classes
│   ├── SecurityConfig.java
│   ├── R2dbcConfig.java
│   └── WebFluxConfig.java
│
├── common/                             ← Shared utilities, not domain-specific
│   ├── exceptions/                     ← Base exception hierarchy
│   ├── mappers/                        ← Shared MapStruct mappers (enum converters etc.)
│   ├── web/                            ← GlobalExceptionHandler, web filters
│   └── model/                          ← Shared model objects (Page, Sort, etc.)
│
├── [domain-a]/                         ← e.g. municipalities/, reports/, users/
│   ├── controllers/
│   │   ├── [DomainA]Controller.java    ← Implements generated OpenAPI interface
│   │   ├── mappers/                    ← Controller-level MapStruct mappers
│   │   └── requests/                  ← Controller-level request records
│   │
│   ├── services/
│   │   ├── [DomainA]Service.java       ← Business logic
│   │   ├── mappers/                    ← Service-level MapStruct mappers
│   │   ├── models/                     ← Service-level records/data objects
│   │   └── requests/                  ← Service-level request records
│   │
│   ├── dao/
│   │   ├── repositories/
│   │   │   ├── [DomainA]Repository.java        ← ReactiveCrudRepository interface
│   │   │   └── [DomainA]QueryRepository.java   ← Custom dynamic queries (DatabaseClient)
│   │   ├── entities/                   ← R2DBC @Table entities
│   │   ├── mappers/                    ← DAO-level MapStruct mappers (row → DTO)
│   │   └── models/                     ← DAO result DTOs / projections
│   │
│   └── remote/                         ← 3rd-party / external communication
│       ├── [ExternalService]Client.java ← WebClient-based HTTP client
│       ├── [Topic]Producer.java         ← Messaging producer (Kafka / SQS)
│       ├── [Topic]Consumer.java         ← Messaging consumer / listener
│       ├── mappers/                    ← Mappers: service models ↔ remote payloads
│       └── models/                     ← Remote-layer payload records
│
└── [domain-b]/
    └── ...
```

### Key structural rules

- One package per bounded context at the top level — never a flat `controllers/`, `services/`, `repositories/` structure across domains.
- Minimize boilerplate: prefer convention-over-configuration when the tool/framework can infer behavior. Avoid redundant @Column annotations when the Java field name reliably maps to the database column name; prefer implicit mapping to reduce noisy boilerplate.
- Each layer owns its own data objects. No object crosses more than one layer boundary.
- `common/` contains only truly cross-domain utilities. If it's domain-specific, keep it in the domain package.
- Configuration lives in `config/` — never embedded in domain packages.
- Generated OpenAPI model classes live under a separate generated source root (e.g. `build/generated`) — never hand-edit them.

---

## Architecture Layers

### The four-layer contract

```
HTTP Request
    ↓
[ Controller Layer ]        ← Dumb. HTTP ↔ service boundary only. No business logic.
    ↓ (Controller request record)
[ Service Layer ]           ← All business logic. Orchestrates domain rules, security, transactions.
    ↓ (DAO request record)          ↓ (Remote request record)
[ DAO / Repository Layer ]  ← DB     [ Remote / Integration Layer ] ← External systems
    ↓                                    ↓
Database                           3rd-party APIs · Messaging · AWS · Firebase
```

**Absolute rules:**
- Data objects never skip layers. No entity reaches the controller. No OpenAPI model reaches the DAO or Remote layer.
- Similar data structures across layers are **acceptable** — duplication here is intentional decoupling, not waste.
- No cyclic dependencies between packages or layers.
- No more than one layer of coupling in any direction.
- The service layer is the **only** orchestrator — it decides whether to call DAO, Remote, or both.

### Layer responsibilities

| Layer | Owns | Does NOT own |
|-------|------|-------------|
| Controller | HTTP mapping, request record assembly, delegating to service | Business logic, validation beyond request syntax |
| Service | Business rules, orchestration, transactions — receives resolved identity and roles via request records (never perform authorization checks) | Authorization enforcement (use SecurityConfig, controller helpers such as CurrentUserController or method-level security), SQL, HTTP details, messaging details |
| DAO | Database query execution, row mapping; owns pagination and query shaping | Business rules, transactions |
| Remote | External HTTP calls, messaging produce/consume, 3rd-party SDK calls | Business rules, database |

### Remote / Integration Layer

All communication with external systems (other microservices, SaaS APIs, messaging brokers, AWS services) lives in this layer. It is parallel to `dao/` — both are downstream infrastructure that the service delegates to.

**Examples:**

```java
// WebClient-based REST client
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationApiClient {

    private final WebClient webClient;
    private final NotificationRemoteMapper mapper;

    public Mono<NotificationAck> sendNotification(NotificationRequest request) {
        return webClient.post()
                .uri("/notifications")
                .bodyValue(mapper.toPayload(request))
                .retrieve()
                .onStatus(HttpStatusCode::isError, this::handleError)
                .bodyToMono(NotificationAckPayload.class)
                .map(mapper::toAck)
                .doOnSuccess(ack -> log.debug("Notification sent id={}", ack.id()));
    }

    private Mono<? extends Throwable> handleError(ClientResponse response) {
        return response.bodyToMono(String.class)
                .map(body -> new NotificationDeliveryException("Remote error: " + body));
    }
}

// Kafka / SQS producer — always use SqsTemplate (Spring abstraction), never SqsAsyncClient directly
@Component
@RequiredArgsConstructor
@Slf4j
public class ReportEventProducer {

    private final SqsTemplate sqsTemplate;
    private final ReportEventMapper mapper;

    public Mono<Void> publishReportCreated(ReportCreated event) {
        return Mono.fromRunnable(() -> sqsTemplate.send("report-events", mapper.toMessage(event)))
                .doOnSuccess(v -> log.info("Published ReportCreated caseNumber={}", event.caseNumber()))
                .then();
    }
}
```

**Rules for the Remote layer:**
- Each remote class deals with exactly one external system or topic.
- Owns its own payload models (`models/`) — never exposes SDK types or raw `Map` to the service.
- Uses a MapStruct mapper to translate between service models and remote payloads.
- Errors from external systems are caught here and translated into domain exceptions before propagating up.
- **Always prefer Spring abstractions** — use `SqsTemplate` (not `SqsAsyncClient`) for SQS, `SesTemplate` for SES. Raw SDK clients are used only when the Spring abstraction does not cover a required feature.
- **Never manually serialize/deserialize messages** — pass typed records to `SqsTemplate`; never call `objectMapper.writeValueAsString()` or `objectMapper.readValue()` in producers or listeners. Spring Cloud AWS handles serialization automatically.
- **Claim-Check pattern for SQS messages** — send only the minimum identifier (e.g., `Long jobId`). Do NOT send full entity payloads in messages. The consumer fetches full details from the DB.

### SQS Listener Pattern

```java
// SQS consumer — use @SqsListener + @Payload; never block(); never ObjectMapper
@Service
@Slf4j
@RequiredArgsConstructor
public class JobRoutingListener {

    private final JobRoutingService jobRoutingService;

    @SqsListener("${app.routing.queue-name}")
    public void onRoutingEvent(@Payload JobRoutingEvent event) {
        log.debug("Received routing event for jobId={}", event.jobId());
        jobRoutingService
                .route(event.jobId())
                // Fire-and-forget: routing is async; log errors but do not rethrow
                .subscribe(null, ex -> log.error("Routing failed for jobId={}; see stacktrace", event.jobId(), ex));
    }
}

// Claim-check event — only the primary key
public record JobRoutingEvent(Long jobId) {}
```

**Rules for SQS listeners:**
- The `@Payload`-annotated parameter type must be a record matching the JSON structure. Spring + Jackson deserializes automatically.
- **NEVER call `.block()`** even inside `@SqsListener`. Use `.subscribe(null, ex -> log.error(...))` for fire-and-forget reactive chains.
- **NEVER inject `ObjectMapper`** to deserialize message bodies manually.
- State-guarded repository updates: any update triggered by a queue message must include a `WHERE status IN (...)` guard and return `Mono<Integer>` (row count) so the caller can detect and log 0-row updates.

---

## Controller Layer

### Controller is dumb

A controller's only jobs are:
1. Implement the generated OpenAPI interface (`XxxApi`)
2. Assemble a **controller request record** from incoming parameters plus current user identity
3. Delegate to the service via a method reference
4. Map the service response to the API model

```java
@RestController
@RequestMapping(API_BASE)
@Validated
@RequiredArgsConstructor
@Slf4j
public class MunicipalitiesController implements MunicipalitiesApi {

    private final MunicipalityService municipalityService;
    private final MunicipalitiesApiMapper apiMapper;

    @Override
    public Flux<MunicipalityApi> listMunicipalities(
            ServerWebExchange exchange,
            Integer first, Integer max, String lastId,
            String order, String filter) {

        var page = Page.of(order, first, max, lastId);

        return currentUserId(exchange)
                .map(userId -> MunicipalitiesRequest.builder()
                        .page(page)
                        .filter(filter)
                        .userId(userId)
                        .build())
                .flatMapMany(municipalityService::listMunicipalities)
                .map(apiMapper::toApi);
    }

    @Override
    public Mono<ResponseEntity<MunicipalityApi>> createMunicipality(
            Mono<MunicipalityCreate> body, ServerWebExchange exchange) {

        return body
                .map(controllerMapper::toCreate)
                .flatMap(municipalityService::createMunicipality)
                .map(apiMapper::toApi)
                .map(m -> ResponseEntity.created(URI.create(API_BASE + "/" + m.id())).body(m));
    }
}
```

**Rules:**
- Never place an `if` for business logic in a controller. Only structural guards (null → empty) are acceptable.
- Use `.map(...).flatMap(service::method)` — never a multi-statement lambda `-> { ... }` in the reactive chain.
- Use method references (`service::method`, `mapper::toApi`) to keep pipelines concise.
- Do not re-declare validation annotations present on the generated API interface.

### Request records

When an endpoint has **3 or more parameters**, group all parameters into a **request record** with Lombok `@Builder`. With 3+ positional constructor arguments, callers lose track of argument order and the risk of bugs rises sharply.

```java
// Controller-level request record
@Builder
public record MunicipalitiesRequest(
    Page page,
    String filter,
    Long userId
) {}

// Service-level request record (different shape — only what the service needs)
@Builder
public record FindMunicipalitiesRequest(
    Page page,
    String filter,
    Long userId,
    Integer resolvedRegionId    // resolved from userId by service
) {}
```

**Naming:** Keep names short and domain-focused. No `DTO`, `Impl`, `I` prefixes/suffixes.

---

## Service Layer

### Structure

- One service class per focused responsibility (SRP). Prefer small, named services over one large `MunicipalityService`.
- **NEVER create a service interface.** Do NOT write `public interface EntityService` backed by `EntityServiceImpl`. This is an explicit anti-pattern in this codebase. Use a plain named `@Service` class (e.g., `EntityCreationService`). There is no circumstance where a service interface is required.
- `@Transactional` (reactive) on write operations.
- Resolve parallel context (roles, agency, user data) with `Mono.zip()`.
- **Service layer knows nothing about the controller layer.** Never import classes from `controllers.*` packages or generated OpenAPI model classes (`com.mycompany.controllers.openapi.*`) into a service. Services define their own request/response records in `services.<domain>.models.*`.
- **Service models belong in `models` subpackage** — e.g., `com.mycompany.admin.services.entities.models.CreateEntityRequest`. Not `requests/`, not the controller package.
 - **Service models belong in `models` subpackage** — e.g., `com.mycompany.admin.services.entities.models.CreateEntityRequest`. Not `requests/`, not the controller package.
 - **Prefer persisted fields over derived computation** — if a value exists in the DB (for example `jobs.duration`), services should use that persisted value. Do not infer or recompute persisted fields from other tables unless the spec explicitly requires it.
 - **Use mappers to translate between layers** — service code must not manually construct service records by copying entity fields. Create a `@Mapper` in `services.<domain>.mappers` (MapStruct) and use it to map `Entity` → `ServiceModel`.

### Authorization and pagination (important additions)

- **Authorization must NOT live in the service layer.** Enforcement of who can call which endpoint belongs in the security layer (SecurityConfig, method-level security annotations, or controller-level guards). Controllers should assert caller identity and roles (via a shared helper like `CurrentUserController.extractUserId(ServerWebExchange)` or a `@ControllerAdvice` helper) and pass a request record containing the resolved identity/roles into the service. Services operate on resolved context and may enforce business rules based on the provided roles/identity, but must not retrieve or validate authentication tokens or JWTs directly.

- **Pagination belongs in the DAO/Repository layer.** Repositories/QueryRepositories must own paging and cursor logic. Services should not call `collectList()` to implement pagination or fetch full datasets into memory — they should pass pagination parameters through to the DAO and work with the paged `Flux` returned. This prevents OOMs and keeps DB query shaping where it belongs.

### Reactive patterns in service methods

- **No `Mono.defer` for simple flows.** Use `.switchIfEmpty(Mono.error(...))` for duplicate/not-found checks.
- **No imperative code inside reactive chains.** No mutable variables, no `if/else` inside `.map()` or `.flatMap()`. Extract named private methods.
- **No useless null assignments.** Do not write `entity.setField(null)` — fields are null by default.

**Correct duplicate-check pattern:**
```java
public Mono<EntityView> register(CreateEntityRequest request) {
    return repository.findByEmailIgnoreCase(request.contactEmail())
            .flatMap(existing -> Mono.<Entity>error(
                    new DuplicateResourceException("Email already registered: " + request.contactEmail())))
            .switchIfEmpty(Mono.fromSupplier(() -> toEntity(request))
                    .flatMap(repository::save))
            .map(this::toModel);
}

private Entity toEntity(CreateEntityRequest request) {
    var entity = new Entity();
    entity.setName(request.name());
    entity.setEmail(request.contactEmail());
    entity.setDisabled(false);
    return entity;
}
```

**❌ Anti-patterns:**
```java
// WRONG — unnecessary Mono.defer for a simple supplier
return Mono.defer(() -> {
    var entity = new Entity(); // imperative inside reactive
    entity.setName(request.name());
    return repository.save(entity);
});

// WRONG — creating a service interface
public interface EntityService { Mono<EntityView> register(CreateEntityRequest r); }

// WRONG — service importing controller/OpenAPI types
import com.mycompany.controllers.openapi.admin.model.Entity; // ← illegal in service
```

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class EntityCreationService {

    private final EntityRepository repository;
    private final EntityServiceMapper mapper;
    private final RegionResolver regionResolver;

    @Transactional
    public Mono<MunicipalityView> createMunicipality(EntityCreate create) {
        return regionResolver.resolveRegion(create.regionCode())
                .map(region -> mapper.toEntity(create, region))
                .flatMap(repository::save)
                .map(mapper::toView)
                .doOnSuccess(m -> log.debug("Created entity id={}", m.id()));
    }
}
```

### Parallel context resolution

Use `Mono.zip()` when you need results from independent reactive sources before building the DAO request:

```java
public Flux<MunicipalityView> listEntities(EntityRequest request) {
    return Mono.zip(
                    regionResolver.resolveRegionId(request.regionCode(), request.userId()),
                    roleService.findRoles(request.userId())
            )
            .map(t -> FindEntityRequest.builder()
                    .page(request.page())
                    .filter(request.filter())
                    .resolvedRegionId(t.getT1())
                    .userRoles(t.getT2())
                    .userId(request.userId())
                    .build())
            .flatMapMany(queryRepository::findEntities)
            .map(mapper::toView);
}
```

---

## DAO Layer

### Repository patterns

Prefer `ReactiveCrudRepository` and **derived queries** (Spring Data method naming) over explicit `@Query` annotations:

```java
public interface EntityRepository extends ReactiveCrudRepository<Entity, Long> {

    Mono<Entity> findByEmailIgnoreCase(String email);
    Mono<Boolean> existsByName(String name);
    // findByRegionId, existsByNameAndRegionId etc.
}
```

**Prefer naming-convention methods over `@Query` whenever possible.** Use `@Query` only when a derived name cannot express the SQL needed (e.g., complex joins, aggregations):

```java
// ❌ Unnecessary @Query — naming convention handles this
@Query("SELECT * FROM entities WHERE email = :email")
Mono<Entity> findByEmail(@Param("email") String email);

// ✅ Correct — derived method
Mono<Entity> findByEmailIgnoreCase(String email);
```

**NEVER return unbounded `Flux<Entity>` for a collection of unknown size.** Fetching all rows without pagination can exhaust memory under load. Every collection-returning repository method must be paginated:

```java
// ❌ FORBIDDEN — no pagination; OOM risk
Flux<PartnerEntity> findAllByOrderByNameAsc();

// ✅ Required — always paginate
Flux<PartnerEntity> findByDisabledOrderByName(boolean disabled, Pageable pageable);
// or cursor-based:
Flux<PartnerEntity> findByPartnerIdLessThanOrderByPartnerIdDesc(Long lastId, int limit);
```

```java
@Modifying
@Query("UPDATE municipalities SET name = :name WHERE municipality_id = :id")
Mono<Integer> updateName(@Param("id") Integer id, @Param("name") String name);
```

Always annotate query parameters with `@Param`. Use Java multiline text blocks for SQL:

```java
@Query("""
    SELECT m.municipality_id, m.name, r.region_code
    FROM municipalities m
    JOIN regions r ON r.region_id = m.region_id
    WHERE m.municipality_id = :id
    """)
Mono<MunicipalityRow> findDetailById(@Param("id") Integer id);
```

### Dynamic queries (DatabaseClient)

Use `DatabaseClient` only for queries that cannot be expressed with derived names or fixed `@Query`:

```java
@RequiredArgsConstructor
public class MunicipalityQueryRepository {

    private final DatabaseClient client;

    public Flux<MunicipalityRow> findMunicipalities(FindMunicipalitiesRequest request) {
        var sql = buildSql(request);
        var params = buildParams(request);
        return client.sql(sql)
                .bindValues(params)
                .map((row, meta) -> ResultSetProcessor.toMap(meta, row))
                .all()
                .map(rowMapper::fromMap);
    }

    private String buildSql(FindMunicipalitiesRequest request) { ... }
    private Map<String, Object> buildParams(FindMunicipalitiesRequest request) { ... }
}
```

### DAO data objects

- Return **projection records** (not entities) from queries that select a subset of columns.
- Never return a `@Table` entity from methods that need only a few columns — use a projection record.
- Entities are for persistence operations (`save`, `delete`) only.
- **Do not set default field values in entity classes.** Entity classes must not have initializers like `private boolean locked = true`. Default values belong in service logic (when building the entity to save), not in the entity class definition.

```java
// ❌ Anti-pattern — default value baked into entity
@Table("entities")
public class Entity {
    private boolean locked = true; // WRONG — entities must be neutral
}

// ✅ Correct — entity is neutral; service sets defaults
private Entity toEntity(CreateEntityRequest request) {
    var entity = new Entity();
    entity.setDisabled(false); // business default set in service
    entity.setName(request.name());
    return entity;
}
```

```java
// DAO result record — only the columns the query returns
public record PartnerRow(
    Long partnerId,
    String name,
    String email,
    boolean disabled
) {}
```

### Pagination with lastId

`lastId` is a **cursor anchor** for DESC-ordered results — not an offset. It guarantees page stability when new records arrive at the top. Use it to anchor the `WHERE` clause:

```sql
WHERE created_at < (SELECT created_at FROM municipalities WHERE municipality_id = :lastId)
ORDER BY created_at DESC
LIMIT :first
```

---

## Mapping with MapStruct

### Layer placement — CRITICAL

Each mapper lives in the layer that **owns its output**. **Never import a class from a higher layer inside a lower-layer mapper.**

| Mapper location | Maps between | May import |
|-----------------|-------------|------------|
| `controllers/{domain}/mappers/` | Service model → OpenAPI-generated API model | `controllers.openapi.*`, `services.{domain}.model.*` |
| `services/{domain}/mappers/` | DAO/Remote DTO → Service model | `services.{domain}.model.*`, `dao.*` |
| `dao/{domain}/mappers/` | DB row → DAO DTO | `dao.*` |
| `controllers/utils/` | Utility type/enum converters shared across controller mappers | `controllers.openapi.*`, `Consts.*` |


- One `@Mapper` interface per layer boundary (controller→service, service→entity, entity→view, row→DTO).
- Do **not** add `@Mapping` for fields with identical names — MapStruct infers them automatically.
- Use constructor injection when the mapper has Spring dependencies:

```java
@Mapper(
    componentModel = "spring",
    injectionStrategy = InjectionStrategy.CONSTRUCTOR
)
public interface MunicipalityServiceMapper {
    MunicipalityEntity toEntity(MunicipalityCreate create);
    MunicipalityView toView(MunicipalityEntity entity);

    // Only add @Mapping when names differ or conversion is needed
    @Mapping(target = "regionCode", source = "region.code")
    MunicipalityView toView(MunicipalityRow row);
}
```

**❌ Service-layer mapper importing OpenAPI model classes** — this is a hard architecture violation:
```java
// WRONG — service mapper must NOT reference API-layer classes
package com.acme.admin.services.guardians.mapper;
import com.acme.controllers.openapi.admin.model.GuardianProfile; // ← illegal cross-layer import
```

**✅ Controller-layer mapper is the correct home for API model mapping:**
```java
// CORRECT
package com.acme.admin.controllers.guardians.mappers;
import com.acme.controllers.openapi.admin.model.GuardianProfile; // ← allowed
```


- For `Map<String, Object>` → record mapping from dynamic queries:

```java
@Mapper(componentModel = "spring")
public interface MunicipalityRowMapper {
    MunicipalityRow fromMap(Map<String, Object> source);
}
```

- Reuse shared mappers (e.g. enum converters) via `uses = { CommonEnumMapper.class }` in `@Mapper`.

---

### Rules

- One `@Mapper` interface per layer boundary (controller→service, service→entity, entity→view, row→DTO).
- **Never** add `@Mapping` for fields with identical names — MapStruct infers them automatically. Avoid redundant `@Mapping` annotations; they add noise and risk copy-paste errors.
- **Import annotation types** — always `import org.mapstruct.Mapping;` (and other MapStruct annotations) at the top of the file. Do **not** use fully-qualified annotation names like `@org.mapstruct.Mapping(...)` inline in code. Fully-qualified annotation usage is harder to read and hinders refactoring.

  ```java
  // ❌ Redundant — MapStruct already handles same-name fields
  @Mapping(target = "guardianId", source = "guardianId")
  @Mapping(target = "email", source = "email")
  GuardianProfile toProfile(GuardianEntity entity);

  // ✅ Only annotate when names differ or special conversion is required
  @Mapping(target = "userId", source = "guardianId")
  @Mapping(target = "avatarUrl", ignore = true)
  GuardianProfile toProfile(GuardianEntity entity);
  ```

- **Reuse utility mappers — two patterns depending on the utility type:**

  **Pattern A — Plain interface utilities (preferred): use `extends`**

  When the utility is a plain Java interface with `default` conversion methods (no `@Mapper` annotation) — e.g. `InstantMapper`, `IdentityVerificationStatusMapper`, `JobStatusMapper` — **extend it directly**. MapStruct sees the default methods and wires them automatically. `Mappers.getMapper()` works in tests without touching any generated `Impl` class.

  ```java
  // ❌ Wrong — inlining a conversion that already exists in a shared utility interface
  @Named("toOffsetDateTime")
  default OffsetDateTime toOffsetDateTime(Instant instant) { ... }

  // ✅ Correct — extend the shared utility interface
  @Mapper(componentModel = "spring")
  public interface GuardianMapper extends InstantMapper, IdentityVerificationStatusMapper {
      @Mapping(target = "avatarUrl", ignore = true)
      GuardianProfile toProfile(GuardianEntity entity);
  }
  ```

  Test (no Spring context, no Impl class reference):
  ```java
  class GuardianMapperTest {
      private final GuardianMapper mapper = Mappers.getMapper(GuardianMapper.class);
  }
  ```

  **Pattern B — `@Mapper`-annotated dependencies: use `uses` + `injectionStrategy = CONSTRUCTOR`**

  When the dependency is itself a `@Mapper`-annotated interface (MapStruct generates a Spring bean for it), use `uses` and always add `injectionStrategy = InjectionStrategy.CONSTRUCTOR`. This makes the generated `Impl` constructor-based so tests can instantiate it by passing the dependencies explicitly without a Spring context.

  ```java
  @Mapper(
      componentModel = "spring",
      uses = {AddressMapper.class},
      injectionStrategy = org.mapstruct.InjectionStrategy.CONSTRUCTOR
  )
  public interface GuardianFullMapper {
      GuardianFullProfile toFullProfile(GuardianEntity entity, List<Address> addresses);
  }
  ```

  Test (manually construct the impl via its generated constructor):
  ```java
  class GuardianFullMapperTest {
      private final GuardianFullMapper mapper =
              new GuardianFullMapperImpl(new AddressMapperImpl());
  }
  ```

- **Reserve `qualifiedByName` for hierarchical / complex mapping** — when you must build a nested object from a flat source (e.g., assembling a `Location` record from multiple flat fields on a DAO row). See `JobShortInfoMapper` as the canonical example.

- For `Map<String, Object>` → record mapping from dynamic queries:

  ```java
  @Mapper(componentModel = "spring")
  public interface MunicipalityRowMapper {
      MunicipalityRow fromMap(Map<String, Object> source);
  }
  ```

- **If a utility mapper for a type does not yet exist, create it** as a plain Java interface with `default` methods in `controllers/utils/` before reaching for `qualifiedByName`.

### Utility mapper conventions (controllers/utils/)

| Class | Converts |
|-------|---------|
| `InstantMapper` | `Instant` ↔ `OffsetDateTime` |
| `IdentityVerificationStatusMapper` | `Consts.IdentityVerificationStatus` → API `IdentityVerificationStatus` |
| `JobStatusMapper` | `Consts.JobStatus` → API `JobStatus` |
| `UserRoleMapper` | `Consts.Roles` → API `UserRole` |
| `ResourceMapper` | `byte[]` ↔ Spring `Resource` |

When a new enum or type needs mapping across the controller boundary, **add a new utility mapper** to this package rather than adding inline conversion logic to the consuming mapper.

---

## Partial Update (PATCH) Pattern

> **This is the canonical pattern for all `PATCH` endpoints in this codebase.** All PATCH operations must follow this convention — never deviate.

### The rule: one PATCH endpoint per resource, never per field

```
✅ PATCH /portal/api/v2/entity/{entityId}         ← one endpoint, caller sends only changed fields
❌ PATCH /portal/api/v2/entity/{entityId}/status  ← anti-pattern: targets a sub-field, not a resource
❌ PATCH /portal/api/v2/entity/{entityId}/rate    ← anti-pattern: targets a sub-field, not a resource
```

Sub-path PATCH endpoints behave like PUT on a sub-resource. They force callers to make multiple round-trips to change several fields and they leak the internal field structure into the API contract. Use a single PATCH with optional fields instead.

### When PATCH vs POST (action endpoint)

| Use | When |
|-----|------|
| `PATCH /resources/{id}` | Updating stored fields (partial resource update, idempotent) |
| `POST /resources/{id}/action` | Triggering an action with side effects beyond field changes (cancel, rotate, approve) |

Examples:
- `PATCH /jobs/{id}` with `{ownerId}` — reassign a owner (field update, idempotent)
- `POST /jobs/{id}/cancel` — cancel a job (action: triggers state machine, sends notifications)

### Null-safe MapStruct mapper (the implementation pattern)

Use `@BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)` on the entity update method. MapStruct will call setters only for non-null fields — null = absent = no change.

```java
// Service-layer DAO mapper — for PATCH operations
@Mapper(componentModel = "spring")
public interface EntityPatchMapper {

    // PATCH: null fields are IGNORED (entity field unchanged)
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntity(PatchEntityRequest request, @MappingTarget Entity entity);
}
```

**Reference implementation:** `com.acme.admin.controllers.users.UserManagementController.patchUsersUserId` → `UpdateUserService` → `UserEntityMapper`. Study this before implementing any new PATCH endpoint.

### Service layer pattern

```java
@Service
@RequiredArgsConstructor
public class EntityUpdateService {

    private final EntityRepository entityRepository;
    private final EntityPatchMapper patchMapper;

    public Mono<EntityView> patch(UUID entityId, PatchEntityRequest request) {
        return entityRepository.findById(entityId)
                .switchIfEmpty(Mono.error(new NotFoundException("Entity not found: " + entityId)))
                .map(entity -> {
                    patchMapper.updateEntity(request, entity);  // null-safe: only non-null fields applied
                    return entity;
                })
                .flatMap(entityRepository::save)
                .map(serviceMapper::toView);
    }
}
```

### Request record

All fields **nullable** — a field absent from the JSON payload deserialises as `null`; the mapper skips it.

```java
// All fields optional — null = "don't change this field"
public record PatchEntityRequest(
    Boolean locked,
    String comments,
    BigDecimal jobRate,
    String entityCallbackUrl
) {}
```

### Special case: explicit null = clear to default

Some fields have semantic meaning when explicitly set to `null` (e.g., `jobRate: null` clears the custom rate, falling back to the platform default). The standard `NullValuePropertyMappingStrategy.IGNORE` pattern cannot distinguish between absent (no-change) and explicit null (clear).

**Recommended approach:** Accept that `null` JSON value = "clear to default" for these fields. Document this in the OpenAPI spec with a note in the field description: `"null clears this field to platform default"`. The mapper skips null fields, so handle the clear explicitly in the service:

```java
// In the service, after applying the patch mapper:
if (request.jobRate() != null) {
    entity.setJobRate(request.jobRate());
} else if (requestBodyIncludesJobRateKey) {
    entity.setJobRate(null); // explicit null = clear
}
// If jobRate key is absent entirely, entity.jobRate remains unchanged
```

**Simpler rule when the tradeoff is acceptable:** Treat `null` JSON as "clear" for nullable fields and document accordingly. This avoids complex Optional wrappers and is sufficient for most admin use cases where staff users explicitly choose values.

### Controller pattern

```java
@Override
public Mono<ResponseEntity<EntityResponse>> patchEntity(
        ServerWebExchange exchange,
        UUID entityId,
        Mono<PatchEntityRequest> requestMono) {

    return requestMono
            .flatMap(request -> entityUpdateService.patch(entityId, request))
            .map(apiMapper::toResponse)
            .map(ResponseEntity::ok);
}
```

### Anti-patterns

```
❌ Multiple PATCH endpoints per resource (one per field)
❌ Using PUT instead of PATCH for partial updates
❌ @BeanMapping without NullValuePropertyMappingStrategy.IGNORE (overwrites all fields with null)
❌ Manually checking each field in the service (verbose, error-prone, doesn't scale)
❌ Trusting the client to send the full object on a PATCH (that's PUT semantics)
```

---

## Java Records and Data Objects

| Situation | Preferred type |
|-----------|---------------|
| Immutable DTO with 1–2 fields, no inheritance | `record` (plain constructor is still readable) |
| Immutable DTO with 3+ fields | `record` + Lombok `@Builder` (3 positional args = already borderline) |
| Data object needing inheritance | Lombok `@Value` class |
| Mutable entity (`@Table`) | Regular class (R2DBC requires mutable or constructor binding) |
| Configuration properties | `record` with `@ConfigurationProperties` |

The rule of thumb: **if a caller of the constructor cannot immediately tell which argument is which without looking at the definition, use `@Builder`**. Three parameters is that threshold.

```java
// Simple record — 2 fields, plain constructor is still clear
public record MunicipalityCreate(String name, String regionCode) {}

// Record with builder — 3+ fields, builder is mandatory
@Builder
public record FindMunicipalitiesRequest(
    Page page,
    String filter,
    Long userId,
    Integer resolvedRegionId,
    Set<Role> userRoles
) {}
```

**Naming:** Never use `DTO`, `Impl`, `I`, `Model` as suffixes or prefixes. Use domain-meaningful names that describe the shape or intent: `MunicipalityView`, `MunicipalityCreate`, `MunicipalityRow`.

---

### List Endpoints: Always `Flux<T>`, Never `Mono<Page<T>>`

Collection-returning endpoints MUST produce `Flux<T>` — a reactive stream of items. The client starts consuming items immediately as they arrive from the database, without waiting for the full result set to materialise.

```java
// ✅ REQUIRED — streaming list
@Override
public Flux<AgencyShortInfo> listRootAgencies(
        Long xAgencyId, Integer offset, Integer max, String sort,
        String name, String state, Boolean active, ServerWebExchange exchange) {
    int o = offset != null ? offset : 0;
    int m = max != null ? max : DEFAULT_PAGE_SIZE;
    return agencyService.list(name, state, active, sort, o, m)
            .map(mapper::toShortInfo);
}

// ❌ FORBIDDEN — materialises full result, runs COUNT query
@Override
public Mono<AgenciesPage> listRootAgencies(...) {
    return agencyService.list(...).map(mapper::toPage);
}
```

In the OpenAPI spec, always use `type: array` with `items: $ref` for list responses — the generator will emit `Flux<T>` from this schema. Never use a wrapper object schema (`AgenciesPage`, `JobPage`, etc.) for a general list endpoint.
---

## Clean Code Principles

### Naming

- Use full English words. No abbreviations unless universally understood (`id`, `url`, `dto` is NOT universally understood).
- No Hungarian notation (`strName`, `intCount`, `bFlag` — all forbidden).
- Method names should read like sentences: `findActiveMunicipalitiesByRegion`, `resolveCurrentUserAgency`.
- Variable names should describe their content, not their type.

### Method length and abstraction

- Keep methods to one screen (≤ ~25 lines).
- **Do not mix abstraction levels in one method.** A method that orchestrates should call named helpers; it should not interleave high-level logic with low-level detail.
- "Comment-worthy" blocks are a signal to **extract a method** with an expressive name instead.

```java
// ❌ Mixed abstraction levels
public Mono<Report> generateReport(ReportRequest request) {
    log.info("Generating report");
    var startDate = request.from() != null ? request.from() : Instant.now().minus(30, DAYS); // default 30 days
    var endDate = request.to() != null ? request.to() : Instant.now();
    return repository.findByDateRange(startDate, endDate)
            .collectList()
            .flatMap(items -> {
                var grouped = items.stream().collect(groupingBy(Item::category));
                // ... build report structure ...
            });
}

// ✅ One level of abstraction per method
public Mono<Report> generateReport(ReportRequest request) {
    var range = resolveDateRange(request);
    return repository.findByDateRange(range.from(), range.to())
            .collectList()
            .map(this::buildReport);
}

private DateRange resolveDateRange(ReportRequest request) { ... }
private Report buildReport(List<Item> items) { ... }
```

### SOLID applied to Spring

| Principle | Spring application |
|-----------|-------------------|
| **SRP** | One service per use case. Controllers do not contain business logic. No "God service" with 20 methods. |
| **OCP** | Extend behavior via composition (strategy pattern, functional parameters) rather than modifying existing classes. |
| **LSP** | Relevant for domain hierarchies; sealed classes + pattern matching enforce exhaustive handling. |
| **ISP** | Prefer narrow repository/service interfaces. A service depending on 10 methods it uses 2 of is a violation. |
| **DIP** | Depend on abstractions (interfaces) at architectural boundaries. Don't depend on `DatabaseClient` in a service — depend on a repository interface. |

### Dependencies

- Aim for **≤ 3 injected dependencies** per class. More is a strong signal of SRP violation.
- Always use **constructor injection** — never field injection (`@Autowired` on a field is forbidden for production code).
- Never use `@Autowired` — use `@RequiredArgsConstructor` (Lombok) with `final` fields.

---

## Reactive Programming (WebFlux / Project Reactor)

### Fundamental rules

1. **Never block the reactive chain.** `.block()`, `Thread.sleep()`, blocking JDBC, blocking HTTP clients — all forbidden inside a reactive pipeline.
2. **Never mix functional and imperative style.** A lambda body with braces (`-> { ... }`) containing multiple statements is an anti-pattern. Extract a named method instead.
3. **Put terminal operators last.** `.subscribe()`, `.block()` belong only at application boundaries.
4. **Think in pipelines.** Compose small, named transformation functions rather than building one long chain.

### Operator guide

| Goal | Operator |
|------|---------|
| Transform one element | `.map(fn)` |
| Transform to another reactive type | `.flatMap(fn)` / `.flatMapMany(fn)` |
| Transform with sequential guarantee | `.concatMap(fn)` |
| Parallel independent calls | `Mono.zip(a, b, c)` |
| Default when empty | `.defaultIfEmpty(val)` / `.switchIfEmpty(Mono.just(val))` |
| Error when empty | `.switchIfEmpty(Mono.error(ex))` |
| Side effect (logging, metrics) | `.doOnNext(fn)` / `.doOnSuccess(fn)` / `.doOnError(fn)` |
| Filter elements | `.filter(predicate)` |
| Collect to list | `.collectList()` |
| Retry on transient error | `.retryWhen(Retry.backoff(...))` |
| Circuit breaker | `.transformDeferred(CircuitBreaker.ofDefaults("name")::toFluxOperator)` |

### MDC context propagation

Reactor does not propagate `ThreadLocal` (MDC) automatically across thread switches. Use `contextWrite` and the MDC bridge:

```java
// Preserve MDC when switching threads (Reactor Context → MDC)
Flux.just(requestId)
    .contextWrite(Context.of("requestId", requestId))
    .doOnEach(signal -> {
        if (!signal.isOnComplete()) {
            MDC.put("requestId", signal.getContextView().getOrDefault("requestId", ""));
        }
    })
```

Use a `WebFilter` to capture incoming headers (trace ID, correlation ID) and seed the Reactor Context. Verify via logging tests that MDC values appear in log lines after thread switches.

### Parallel IO

Use `Mono.zip()` for independent IO operations that can proceed in parallel:

```java
// ✅ Parallel — both calls start simultaneously
return Mono.zip(
        userRepository.findById(userId),
        permissionRepository.findByUser(userId)
    )
    .map(t -> buildResponse(t.getT1(), t.getT2()));

// ❌ Sequential — second call waits for first
return userRepository.findById(userId)
    .flatMap(user -> permissionRepository.findByUser(userId)
        .map(perms -> buildResponse(user, perms)));
```

---

## Error Handling

### Domain exceptions

Define a hierarchy of domain-specific `RuntimeException` subclasses. Never throw generic `RuntimeException` or `Exception` from business code.

```java
// Base
public class ApplicationException extends RuntimeException {
    public ApplicationException(String message) { super(message); }
    public ApplicationException(String message, Throwable cause) { super(message, cause); }
}

// Domain-specific
public class MunicipalityNotFoundException extends ApplicationException {
    public MunicipalityNotFoundException(Integer id) {
        super("Municipality not found: " + id);
    }
}

public class DuplicateMunicipalityException extends ApplicationException {
    public DuplicateMunicipalityException(String name) {
        super("Municipality already exists: " + name);
    }
}
```

### Global exception handler

Map domain exceptions to HTTP responses in one central `@RestControllerAdvice`. Use Problem Details (RFC 9457):

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(MunicipalityNotFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(MunicipalityNotFoundException ex) {
        log.warn("Not found: {}", ex.getMessage());
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Municipality Not Found");
        return ResponseEntity.of(problem).build();
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ProblemDetail> handleValidation(ConstraintViolationException ex) {
        var detail = ex.getConstraintViolations().stream()
                .map(v -> v.getPropertyPath() + ": " + v.getMessage())
                .collect(joining(", "));
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, detail);
        problem.setTitle("Validation Failed");
        return ResponseEntity.of(problem).build();
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ProblemDetail> handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        var problem = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        problem.setTitle("Internal Server Error");
        return ResponseEntity.of(problem).build();
    }
}
```

- Controllers **never** catch exceptions. Throw and let the handler deal with it.
- Use specific exception types — the handler's granularity is the only location where HTTP status codes are assigned.

---

## Logging

### Rules

- Use `@Slf4j` (Lombok). Never instantiate a logger manually.
- Always use SLF4J placeholders — never string concatenation:

```java
// ✅
log.info("Created municipality id={} name={}", municipality.id(), municipality.name());
log.debug("Resolved region id={} for code={}", regionId, regionCode);

// ❌
log.info("Created municipality id=" + municipality.id());  // Forbidden
```

- Use `debug` for detailed operational logs that would flood production. Use `info` for business events. Use `warn` for recoverable situations. Use `error` only for genuine errors with a stack trace.
- Log at service entry for writes at `info` level. Log at `debug` for reads or high-frequency operations.
- Do not log PII (Personally Identifiable Information) — emails, names, document numbers.
- Ensure correlation IDs (trace ID, request ID) are present in MDC before the first log statement in a request.

---

## Configuration and Properties

Always use `@ConfigurationProperties` with a typed record or class — never scattered `@Value` for structured config:

```java
@ConfigurationProperties(prefix = "app.municipalities")
@Validated
public record MunicipalityProperties(
    @NotNull Duration cacheTtl,
    @Min(1) @Max(500) int maxPageSize,
    @NotBlank String defaultRegionCode
) {}
```

Register with `@EnableConfigurationProperties(MunicipalityProperties.class)` in your config class or use the `@ConfigurationPropertiesScan` annotation on the main class.

---

## Jackson 3 (Spring Boot 4)

Spring Boot 4 ships with **Jackson 3**, which moved to the `tools.jackson.*` package tree. The `com.fasterxml.jackson.*` packages are gone. The central configuration API has changed: there is no `ObjectMapper` bean to declare — instead configure Jackson via `JsonMapperBuilderCustomizer`.

### Configuring serialization / deserialization

```java
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.MapperFeature;
import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.cfg.DateTimeFeature;
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;

@Bean
public JsonMapperBuilderCustomizer jacksonCustomizer() {
    return builder -> builder
            // Date/time: do not serialize as timestamps (use ISO-8601 strings)
            .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS,
                     DateTimeFeature.WRITE_DURATIONS_AS_TIMESTAMPS)
            // Deserialization: be tolerant of evolving schemas
            .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES,
                     DeserializationFeature.FAIL_ON_IGNORED_PROPERTIES)
            // Allow a single value where an array is expected
            .enable(DeserializationFeature.ACCEPT_SINGLE_VALUE_AS_ARRAY)
            // Serialization: do not fail on empty beans
            .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
            // Ordering: do not force alphabetical property order
            .disable(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY)
            // Auto-register all modules on classpath (JavaTimeModule etc.)
            .findAndAddModules()
            .build();
}
```

### Key Migration Notes Jackson 2 → Jackson 3

| Jackson 2 | Jackson 3 |
|---|---|
| `com.fasterxml.jackson.databind.ObjectMapper` | No direct `ObjectMapper` bean; use `JsonMapperBuilderCustomizer` |
| `com.fasterxml.jackson.*` | `tools.jackson.*` |
| `@JsonIgnoreProperties` from `com.fasterxml...` | Same annotation, new package |
| `Jackson2ObjectMapperBuilderCustomizer` | `JsonMapperBuilderCustomizer` |
| Manual `JavaTimeModule` registration | `.findAndAddModules()` discovers it automatically |

### Do NOT
- Declare an `ObjectMapper` `@Bean` — it no longer integrates into WebFlux auto-configuration the same way.
- Import from `com.fasterxml.jackson.*` — those classes do not exist in Jackson 3.

---

## Testing

### Test strategy — choose the right scope

Use the **narrowest possible test scope** for each concern. Full `@SpringBootTest` + Testcontainers is expensive and slow; reserve it for cases where nothing narrower will do.

| Test Type | Annotation | Loads | Use When |
|-----------|-----------|-------|----------|
| Unit test | `@ExtendWith(MockitoExtension.class)` | Nothing | Pure logic, service business rules, mappers |
| Web layer slice | `@WebFluxTest` | Only WebFlux infra + listed controllers | HTTP mapping, request validation, status codes, security |
| DAO slice | `@DataR2dbcTest` | Only R2DBC infra + repositories | Repository queries against an in-memory DB |
| Full integration | `@SpringBootTest` + Testcontainers | Full context + real DB | End-to-end flows, only when slices can't cover it |

---

### Unit tests (pure service logic)

Fastest tests. No Spring context. Mock all dependencies with Mockito.

```java
@ExtendWith(MockitoExtension.class)
class MunicipalityCreationServiceTest {

    @Mock MunicipalityRepository repository;
    @Mock MunicipalityServiceMapper mapper;
    @Mock RegionResolver regionResolver;
    @InjectMocks MunicipalityCreationService service;

    @Test
    void shouldCreateMunicipalitySuccessfully() {
        var create = new MunicipalityCreate("Springfield", "US-IL");
        var entity = new MunicipalityEntity();
        var view = new MunicipalityView(1, "Springfield", "US-IL");

        when(regionResolver.resolveRegion("US-IL")).thenReturn(Mono.just(new Region(42, "US-IL")));
        when(mapper.toEntity(any(), any())).thenReturn(entity);
        when(repository.save(entity)).thenReturn(Mono.just(entity));
        when(mapper.toView(entity)).thenReturn(view);

        StepVerifier.create(service.createMunicipality(create))
                .expectNext(view)
                .verifyComplete();
    }

    @Test
    void shouldPropagateErrorWhenRegionNotFound() {
        var create = new MunicipalityCreate("Springfield", "INVALID");
        when(regionResolver.resolveRegion("INVALID"))
                .thenReturn(Mono.error(new RegionNotFoundException("INVALID")));

        StepVerifier.create(service.createMunicipality(create))
                .expectError(RegionNotFoundException.class)
                .verify();
    }
}
```

---

### Web layer slice tests (`@WebFluxTest`)

**Use this for controller tests.** Loads only the WebFlux infrastructure and the controllers you list. Mock all service dependencies with `@MockitoBean`. Import only the necessary config classes (security test config, WebFlux converter config). Do **not** import `JwtConfig` or other beans that require external resources (RSA keys, database connections).

```java
@WebFluxTest(controllers = {MunicipalitiesController.class, GlobalExceptionHandler.class})
@Import({SecurityTestConfig.class, WebFluxConfig.class})
class MunicipalitiesControllerTest {

    @MockitoBean
    MunicipalityService municipalityService;

    @MockitoBean
    MunicipalitiesApiMapper apiMapper;

    @MockitoBean
    JwtTokenProvider jwtTokenProvider;      // mock: avoids loading RSA keys

    @Autowired
    WebTestClient webTestClient;

    @Test
    void createMunicipality_happyPath_returns201() {
        var view = new MunicipalityView(1, "Springfield", "US-IL");
        var apiModel = new MunicipalityApi().id(1).name("Springfield");

        when(municipalityService.createMunicipality(any())).thenReturn(Mono.just(view));
        when(apiMapper.toApi(view)).thenReturn(apiModel);

        webTestClient.post().uri(Consts.API_BASE + "/municipalities")
                .header("Authorization", "Bearer token-x")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue("""
                        {"name":"Springfield","regionCode":"US-IL"}
                        """)
                .exchange()
                .expectStatus().isCreated()
                .expectHeader().exists("Location")
                .expectBody().jsonPath("$.name").isEqualTo("Springfield");
    }

    @Test
    void createMunicipality_validationFailure_returns400() {
        webTestClient.post().uri(Consts.API_BASE + "/municipalities")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue("{}")                      // missing required fields
                .exchange()
                .expectStatus().isBadRequest();
    }

    @Test
    void createMunicipality_domainError_mappedByAdvice() {
        when(municipalityService.createMunicipality(any()))
                .thenReturn(Mono.error(new DuplicateMunicipalityException("Springfield")));

        webTestClient.post().uri(Consts.API_BASE + "/municipalities")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue("{\"name\":\"Springfield\",\"regionCode\":\"US-IL\"}")
                .exchange()
                .expectStatus().is4xxClientError();
    }
}
```

**Key points:**
- `@MockitoBean` (Spring Boot 4) replaces `@MockBean`.
- Always include `GlobalExceptionHandler` so exception-to-HTTP mapping is exercised.
- `SecurityTestConfig` provides a minimal `SecurityFilterChain` for tests — permit-all or a test JWT issuer that does not need real RSA keys.
- Cover: happy path, validation failure, domain exception mapping.

---

### DAO slice tests (`@DataR2dbcTest`)

**Use this to test repository queries.** Loads only R2DBC infrastructure. Use H2 R2DBC in-memory with the `test` profile. Only reach for Testcontainers when queries use PostgreSQL-specific syntax H2 cannot handle.

```java
@ExtendWith(SpringExtension.class)
@DataR2dbcTest
@ActiveProfiles("test")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MunicipalityRepositoryTest {

    @Autowired
    MunicipalityRepository repository;

    @Test
    void findByRegionId_returnsMatchingMunicipalities() {
        StepVerifier.create(repository.findByRegionId(1))
                .assertNext(m -> {
                    assertThat(m.municipalityId()).isEqualTo(1);
                    assertThat(m.name()).isEqualTo("Springfield");
                })
                .verifyComplete();
    }

    @Test
    void findByRegionId_emptyForUnknownRegion() {
        StepVerifier.create(repository.findByRegionId(9999))
                .verifyComplete();
    }
}
```

For custom `DatabaseClient` repositories, import the class explicitly:

```java
@DataR2dbcTest
@Import({MunicipalityQueryRepository.class, MunicipalityRowMapperImpl.class})
@ActiveProfiles("test")
class MunicipalityQueryRepositoryTest {

    @Autowired MunicipalityQueryRepository queryRepository;

    @Test
    void findMunicipalities_withFilter_returnsFilteredResults() {
        var request = FindMunicipalitiesRequest.builder()
                .page(Page.of("name:asc", 10, 100, null))
                .filter("Spring")
                .userId(1L)
                .build();

        StepVerifier.create(queryRepository.findMunicipalities(request))
                .assertNext(row -> assertThat(row.name()).contains("Spring"))
                .verifyComplete();
    }
}
```

`src/test/resources/application-test.yml`:

```yaml
spring:
  r2dbc:
    url: r2dbc:h2:mem:///testdb;DB_CLOSE_DELAY=-1
    username: sa
    password:
  sql:
    init:
      mode: always
      schema-locations: classpath:db/schema-h2.sql
      data-locations: classpath:db/test-data.sql
```

---

### Mapper unit tests

Pure functions — no Spring context needed:

```java
class MunicipalityServiceMapperTest {

    private final MunicipalityServiceMapper mapper = Mappers.getMapper(MunicipalityServiceMapper.class);

    @Test
    void toEntity_mapsAllFields() {
        var create = new MunicipalityCreate("Springfield", "US-IL");
        assertThat(mapper.toEntity(create).getName()).isEqualTo("Springfield");
    }
}
```

When the mapper extends plain utility interfaces, `Mappers.getMapper()` works directly — no Spring context, no generated Impl class reference:

```java
class GuardianMapperTest {

    // Works without Spring — utility interface default methods are baked in by MapStruct
    private final GuardianMapper mapper = Mappers.getMapper(GuardianMapper.class);

    @Test
    void toProfile_mapsNameFields() {
        var entity = buildGuardianEntity();
        var profile = mapper.toProfile(entity);
        assertThat(profile.getEmail()).isEqualTo(entity.getEmail());
        assertThat(profile.getAvatarUrl()).isNull(); // ignored field
    }
}
```

When the mapper uses `uses = {SomeDependentMapper.class}` with `injectionStrategy = CONSTRUCTOR`, pass dependencies via the generated constructor:

```java
class GuardianFullMapperTest {

    private final GuardianFullMapper mapper =
            new GuardianFullMapperImpl(new AddressMapperImpl());

    @Test
    void toFullProfile_includesAddresses() { ... }
}
```

---

### Full context tests (use sparingly)

Only when slices cannot cover the scenario. Use Testcontainers with `@DynamicPropertySource`so the container port is wired without hard-coded config:

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@ActiveProfiles("integration")
class MunicipalitiesFullIT {

    @Container
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>("postgres:17-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.r2dbc.url", () ->
                "r2dbc:postgresql://%s:%d/testdb".formatted(
                        postgres.getHost(), postgres.getFirstMappedPort()));
        registry.add("spring.r2dbc.username", postgres::getUsername);
        registry.add("spring.r2dbc.password", postgres::getPassword);
    }

    @Autowired WebTestClient webClient;

    @Test
    void fullFlow_createAndRetrieveMunicipality() { /* ... */ }
}
```

---

## Gradle Build Organisation

### All versions live in `gradle.properties`

No hardcoded version strings inside `build.gradle`. Every dependency version, plugin version, and BOM version is declared in `gradle.properties` so upgrades are a single-file change and diffs are clean.

```properties
# gradle.properties
springBootVersion=4.0.0
springCloudVersion=2025.0.0
javaVersion=25

jacksonVersion=3.0.0
mapstructVersion=1.6.3
lombokVersion=1.18.36
postgresqlVersion=42.7.4
r2dbcPostgresqlVersion=1.0.7.RELEASE

testcontainersVersion=1.20.4
mockkVersion=1.13.14
```

### Plugin and BOM wiring

Use the Spring Boot BOM via `dependencyManagement` so you never need to specify versions for Spring-managed dependencies.

```groovy
// build.gradle
plugins {
    id 'org.springframework.boot'           version "${springBootVersion}"
    id 'io.spring.dependency-management'    version '1.1.7'
    id 'com.diffplug.spotless'              version '7.0.3'
    id 'org.openapi.generator'              version '7.11.0'
    id 'java'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of("${javaVersion}")
    }
}

dependencyManagement {
    imports {
        mavenBom org.springframework.boot.gradle.plugin.SpringBootPlugin.BOM_COORDINATES
        mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
    }
}
```

### Dependencies — no inline version for BOM-managed libs

```groovy
dependencies {
    compileOnly         "org.projectlombok:lombok"
    annotationProcessor "org.projectlombok:lombok"

    annotationProcessor "org.projectlombok:lombok-mapstruct-binding:${mapstructBindingVersion}"
    annotationProcessor "org.mapstruct:mapstruct-processor:${mapstructVersion}"

    implementation 'org.springframework.boot:spring-boot-starter-webflux'    // version from BOM
    implementation 'org.springframework.boot:spring-boot-starter-data-r2dbc'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation "org.postgresql:r2dbc-postgresql"
}
```

### Testing suites — no raw `testImplementation` blocks

Use the `testing { suites { } }` API. Define `test` and `integrationTest` as separate suites with their own source sets. The task-dependency `check.dependsOn integrationTest` wires them into the standard build lifecycle.

```groovy
testing {
    suites {
        test {
            useJUnitJupiter()
            dependencies {
                implementation 'org.springframework.boot:spring-boot-starter-test'
                implementation 'io.projectreactor:reactor-test'
                // H2 for @DataR2dbcTest slices
                implementation 'io.r2dbc:r2dbc-h2'
                implementation 'com.h2database:h2'
            }
        }

        integrationTest(JvmTestSuite) {
            useJUnitJupiter()
            sources {
                java.srcDirs = ['src/integrationTest/java']
                resources.srcDirs = ['src/integrationTest/resources']
            }
            dependencies {
                implementation project()
                implementation 'org.springframework.boot:spring-boot-starter-test'
                implementation 'io.projectreactor:reactor-test'
                implementation "org.testcontainers:testcontainers:${testcontainersVersion}"
                implementation "org.testcontainers:junit-jupiter:${testcontainersVersion}"
                implementation "org.testcontainers:postgresql:${testcontainersVersion}"
                implementation "org.testcontainers:r2dbc:${testcontainersVersion}"
            }
        }
    }
}

check.dependsOn integrationTest
tasks.named('integrationTest').configure { mustRunAfter(test) }
```

### OpenAPI Generator — generate into version-ignored directory

```groovy
openApiGenerate {
    generatorName   = 'spring'
    inputSpec       = "$projectDir/src/main/resources/openapi/api.yaml"
    outputDir       = "$buildDir/generated/openapi"
    modelPackage    = "${group}.generated.model"
    apiPackage      = "${group}.generated.api"
    configOptions   = [
        reactive          : 'true',
        interfaceOnly     : 'true',
        useSpringBoot3    : 'true',
        skipDefaultInterface: 'true',
    ]
}

compileJava.dependsOn tasks.openApiGenerate
sourceSets.main.java.srcDir "${buildDir}/generated/openapi/src/main/java"
```

### Spotless code formatting

```groovy
spotless {
    java {
        googleJavaFormat('1.25.2').aosp().reflowLongStrings()
        importOrder('java', 'javax', 'jakarta', '', 'org', 'com')
        removeUnusedImports()
    }
}

compileJava.dependsOn spotlessApply
```

---

## Anti-Patterns — What NOT To Do

### Architecture anti-patterns

| Anti-pattern | Instead |
|---|---|
| Controller calls repository directly | Always go through the service layer |
| Entity passed to the controller layer | Map to a view/DTO at the service boundary |
| Business logic in a controller | Move to service |
| `XxxServiceImpl` class | Just name the service meaningfully: `MunicipalityCreationService` |
| One giant `XxxService` with 15 methods | Break into focused services per use case |
| Cyclic dependency between packages | Introduce a shared model or event |
| Shared domain objects across bounded contexts | Each context owns its own model |

### Reactive anti-patterns

| Anti-pattern | Instead |
|---|---|
| `.block()` inside a reactive chain | Compose with `flatMap` |
| `-> { var x = ...; return ...; }` multi-statement lambda | Extract a named method |
| Sequential `flatMap` for independent calls | `Mono.zip(a, b)` for parallel execution |
| `subscribe()` inside a service method | Return the `Mono`/`Flux`; let the framework subscribe |
| `try/catch` inside reactive chain | `.onErrorMap(...)` / `.onErrorResume(...)` |
| Blocking JDBC/`RestTemplate` in WebFlux | R2DBC + `WebClient` |
| Losing MDC across thread boundaries | `contextWrite` + MDC bridge filter |

### Java / Clean code anti-patterns

| Anti-pattern | Instead |
|---|---|
| Hungarian notation (`strName`) | Just `name` |
| `DTO`, `Impl`, `I` name suffixes/prefixes | Meaningful domain names (`MunicipalityView`) |
| `@Autowired` field injection | Constructor injection via `@RequiredArgsConstructor` |
| `@Value` for structured config | `@ConfigurationProperties` record |
| Method longer than one screen | Extract named helpers |
| Comment explaining what the code does | Extract method with expressive name |
| String concatenation in log messages | SLF4J placeholders `log.info("{}", val)` |
| Catching `Exception` or `Throwable` in domain code | Catch specific exceptions or use domain hierarchy |
| `Optional.get()` without `isPresent()` check | `.orElseThrow(...)` |
| `null` as a return value from a service | Return `Optional<T>` or throw a domain exception |
| Raw `Map` as a data transfer structure across layers | Typed records |
| `*` wildcard imports | Explicit, individual imports |
| Fully qualified class names in code body | Import the class; use FQN only on name conflicts |

### Testing anti-patterns

| Anti-pattern | Instead |
|---|---|
| `reactor.block()` in tests | `StepVerifier` |
| Testing implementation details (private methods) | Test via public API |
| Mock everything including the class under test | Keep the class under test real |
| One test per class with 50 assertions | Small focused tests, one scenario per test |
| `Thread.sleep()` for async wait in tests | `StepVerifier.withVirtualTime(...)` |

---

## Checklist for Every Story

Use this as a pre-PR self-review:

- [ ] Controller implements generated OpenAPI interface; no business logic inside
- [ ] Controller uses request records (Lombok `@Builder`) for endpoints with >3 params
- [ ] Reactive chain uses method references, not multi-statement lambdas
- [ ] No `.block()` anywhere in the reactive stack
- [ ] Each layer has its own data objects — no objects crossing two layers
- [ ] Service class is named after its use case, not `XxxServiceImpl`
- [ ] `@Transactional` applied on write service methods
- [ ] MapStruct mappers exist for every layer boundary
- [ ] Domain exceptions thrown for all error cases; `GlobalExceptionHandler` maps them to HTTP
- [ ] All log messages use `{}` placeholders; no PII logged
- [ ] MDC context propagated through thread switches
- [ ] Test scope chosen correctly: unit for logic, `@WebFluxTest` for web layer, `@DataR2dbcTest` for DAO, Testcontainers only when slices cannot cover it
- [ ] No `*` wildcard imports; no fully qualified names in method bodies
- [ ] Constructor injection used everywhere; no `@Autowired` on fields
- [ ] Methods are ≤ one screen; no mixed abstraction levels in one method
