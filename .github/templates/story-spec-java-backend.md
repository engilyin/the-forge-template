---
id: US-XX-XX
title: "TITLE"
iteration: N
phase: P
type: feature | bugfix | rework
agent: java-backend-developer
project: PROJECT_NAME
points: N
priority: must-have | should-have | could-have
dependencies: []
status: draft | ready | preprocessed | implementing | done | failed | blocked
---

## Story

**As a** [ACTOR],
**I want** [ACTION via VERB /api/v2/audience/resource],
**So that** [BUSINESS VALUE].

## Context

<!-- 2-3 sentences of domain context. No links to external files.
     Include ONLY facts the agent needs to implement THIS story. -->

## Implementation Target

### Files to Create

| Layer | File Path | Description |
|-------|-----------|-------------|
| Controller | `src/main/java/com/PACKAGE/controllers/DomainController.java` | Implements generated OpenAPI interface |
| Controller Mapper | `src/main/java/com/PACKAGE/controllers/mappers/DomainApiMapper.java` | MapStruct: service model → API response |
| Service | `src/main/java/com/PACKAGE/services/domain/FunctionalNameService.java` | Business logic |
| Service Request | `src/main/java/com/PACKAGE/services/domain/models/NameRequest.java` | `@Builder` record, 3+ params |
| Service Mapper | `src/main/java/com/PACKAGE/services/domain/mappers/DomainServiceMapper.java` | MapStruct: entity → service model |
| DAO Repository | `src/main/java/com/PACKAGE/dao/EntityRepository.java` | R2DBC repository |
| DAO Projection | `src/main/java/com/PACKAGE/dao/projections/NameProjection.java` | Read-query projection (if needed) |
| Unit Test | `src/test/java/com/PACKAGE/services/domain/FunctionalNameServiceTest.java` | StepVerifier-based tests |

### Files to Modify

| File Path | What Changes |
|-----------|-------------|
| `file.java` | Add method X / Add field Y |

<!-- Use "None" if no modifications needed -->

## Code Skeleton

### Controller

```java
package com.PACKAGE.controllers;

import com.PACKAGE.controllers.mappers.DomainApiMapper;
import com.PACKAGE.services.domain.FunctionalNameService;
// imports from generated openapi interface ...

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@RestController
@RequiredArgsConstructor
public class DomainController implements DomainApi {

    private final FunctionalNameService service;
    private final DomainApiMapper apiMapper;

    @Override
    public Mono<ResponseEntity<DomainResponse>> methodName(
            /* generated params */
            ServerWebExchange exchange) {
        // TODO: implement
        // Pattern: currentUserId(exchange)
        //   .flatMap(uid -> service.doSomething(...))
        //   .map(apiMapper::toApi)
        //   .map(r -> ResponseEntity.status(HttpStatus.XXX).body(r));
    }
}
```

### Service

```java
package com.PACKAGE.services.domain;

import com.PACKAGE.services.domain.mappers.DomainServiceMapper;
import com.PACKAGE.dao.EntityRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class FunctionalNameService {

    private final EntityRepository repository;
    private final DomainServiceMapper mapper;

    // TODO: implement methods per acceptance criteria
    // Pattern: return repository.findById(id)
    //   .switchIfEmpty(Mono.error(new NotFoundException("Entity", id)))
    //   .map(mapper::toView);
}
```

### Controller Mapper (MapStruct)

```java
package com.PACKAGE.controllers.mappers;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface DomainApiMapper {
    // TODO: define mapping methods
    // DomainResponse toApi(DomainView view);
}
```

### Service Mapper (MapStruct)

```java
package com.PACKAGE.services.domain.mappers;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface DomainServiceMapper {
    // TODO: define mapping methods
    // DomainView toView(DomainEntity entity);
}
```

### Unit Test

```java
package com.PACKAGE.services.domain;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.test.StepVerifier;

@ExtendWith(MockitoExtension.class)
class FunctionalNameServiceTest {

    @Mock
    private EntityRepository repository;
    @Mock
    private DomainServiceMapper mapper;

    @InjectMocks
    private FunctionalNameService service;

    // TODO: one @Test per acceptance scenario
    // SC-1: Successful case
    // SC-2: Not found case
    // SC-3: Validation failure case
}
```

## Acceptance Criteria

**SC-1: [Scenario name]**
- Given [precondition]
- When [action]
- Then [expected outcome]

**SC-2: [Scenario name]**
- Given [precondition]
- When [action]
- Then [expected outcome]

<!-- One SC per testable scenario. These map 1:1 to test methods. -->

## Mandatory Rules (Inline — DO NOT SKIP)

### Layer Rules
1. Controller MUST implement the generated OpenAPI interface — NO `@PostMapping`/`@GetMapping` on the controller
2. Controller MUST NOT contain business logic — only HTTP ↔ service mapping
3. Service MUST NOT import anything from `controllers.*` or `com.*.controllers.openapi.*`
4. Service MUST NOT throw `ResponseStatusException` or reference `HttpStatus`
5. Service throws domain exceptions (`NotFoundException`, `ConflictException`) — controller/global handler maps to HTTP

### Mapper Rules
6. MapStruct mapper at EVERY layer boundary (controller↔service, service↔dao)
7. Mapper interfaces use `@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)`
8. Controller mapper maps service models ↔ OpenAPI generated models
9. Service mapper maps entities ↔ service-layer records/views
10. NO manual field-by-field copying — MapStruct handles all mapping

### Reactive Rules
11. NO `.block()` calls anywhere
12. Use method references in `.map()` / `.flatMap()` where readable
13. Use `switchIfEmpty(Mono.error(...))` for not-found cases
14. Return `Mono<ResponseEntity<T>>` or `Flux<T>` from controller methods

### Test Rules
15. One `@Test` method per acceptance scenario (SC-1, SC-2, ...)
16. Use `StepVerifier` for reactive assertions
17. Mock all dependencies with `@Mock` / `@InjectMocks`

### Style Rules
18. NO `*Impl` class names — use functional names (`PartnerCreationService`, not `PartnerServiceImpl`)
19. `@Builder` record for service request if method has 3+ parameters
20. Import classes, never fully-qualify inline (`com.example.Foo` inline = violation)

## Validation Commands

Run these IN ORDER after implementation:

```bash
# 1. Format code
./gradlew spotlessApply

# 2. Compile + unit tests
./gradlew clean build

# 3. Integration tests (if applicable)
# ./gradlew integrationTest
```

If any command fails: fix the error, re-run the failing command. If it fails twice, commit as WIP.

## Commit Command

```bash
git add .
git commit -m "feat(US-XX-XX): TITLE"
```

NO `Co-authored-by` trailer. Author is taken from local git config (set via `setauthor.sh` or `.forge/config.env`).

## Definition of Done

- [ ] OpenAPI spec verified; `./gradlew openApiGenerate` run before coding
- [ ] Controller implements generated interface (no manual mapping annotations)
- [ ] Service layer has no HTTP/controller imports
- [ ] MapStruct mappers at controller and service layer boundaries
- [ ] Unit tests cover all acceptance scenarios
- [ ] `./gradlew spotlessApply` run
- [ ] `./gradlew clean build` green
- [ ] Committed with correct author
