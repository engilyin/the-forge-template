---
name: "API-First Design Skill"
description: "Design and author OpenAPI-first REST API contracts before implementation; use for spec-first workflows and generation."
tags: [skill, api-first]
type: skill
---

# API-First Design Skill

> Apply this skill when designing, authoring, reviewing, or generating any REST API specification for a backend project. API-First means the OpenAPI specification is written **before** any implementation code is produced.

---

## What Is API-First?

API-First is the practice of designing and agreeing on the API contract (OpenAPI YAML/JSON) **before writing implementation code**. The spec becomes the single source of truth that drives:

- Backend implementation (Spring controllers, DTOs)
- Frontend/mobile client code generation
- Contract testing (consumer-driven contracts)
- Documentation (auto-generated from the spec)
- Mocking (stub servers during parallel frontend/backend development)

In the FORGE workflow, API contracts belong in `spec/technical/` and are produced during the **Reconstruct phase** — before any Generate phase work begins.

---

## FORGE Integration

| Phase | API-First Activity |
|-------|-------------------|
| **Reconstruct** | Write OpenAPI spec in `spec/technical/api-contracts.yaml` |
| **Generate** | Generate Spring controllers and DTOs from the spec (code-gen or manual) |
| **Edit** | Validate spec against implementation; run Spectral lint |

The OpenAPI file is a versioned contract. Breaking changes require a new API version.

---

## Quick Authoring Checklist

Before submitting any OpenAPI spec for review, verify:

- [ ] All `paths` reference `components` for `requestBody`, responses, and parameters (no inline schemas)
- [ ] No inline object schemas exist inside operations
- [ ] All schemas defined under `components.schemas`
- [ ] Creation (POST) endpoints return `201` (or `202` for async)
- [ ] Every operation includes a `500` response
- [ ] Protected endpoints include `401` and `403` responses
- [ ] Error responses reference the shared `MessageResponse` schema
- [ ] Each schema has a `description` and at least one `example`
- [ ] Every operation has `summary`, `description`, `operationId`, and exactly one `tag`
- [ ] All tags declared globally in the root `tags` array

---

## Rules Reference

### 1. Components-Only (No Inline Schemas)

All schemas, request bodies, responses, parameters, and examples **must** live in `components`. Operations reference them via `$ref`.

```yaml
# ✅ Correct — reference from components
paths:
  /municipalities:
    post:
      requestBody:
        $ref: '#/components/requestBodies/CreateMunicipality'
      responses:
        '201':
          $ref: '#/components/responses/CreatedMunicipality'

# ❌ Wrong — inline schema in path operation
paths:
  /municipalities:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                name:
                  type: string
```

Paths must never reference `#/components/schemas` directly — only via `requestBodies` or `responses`.

---

### 2. Status Codes

| Situation | Status Code |
|-----------|------------|
| Synchronous creation (POST) | `201 Created` |
| Async creation / start-process | `202 Accepted` |
| Validation failure | `400 Bad Request` |
| Semantic/business rule failure | `422 Unprocessable Entity` |
| Unauthenticated | `401 Unauthorized` |
| Forbidden | `403 Forbidden` |
| Resource not found | `404 Not Found` |
| Server error (always required) | `500 Internal Server Error` |

---

### 3. Shared Error Schema — `MessageResponse`

Define once in `components.schemas`, reuse everywhere:

```yaml
components:
  schemas:
    MessageResponse:
      type: object
      description: Standard error response body
      required: [message]
      properties:
        message:
          type: string
          description: Human-readable error message
          example: "Resource not found"
        code:
          type: string
          description: Machine-readable error code
          example: "RESOURCE_NOT_FOUND"
        details:
          type: object
          description: Additional validation or domain-specific error detail
          additionalProperties: true
```

---

### 4. CRUD Operation Mapping

| Method | Path | Operation |
|--------|------|-----------|
| `GET` | `/entities` | List entities (paginated) |
| `POST` | `/entities` | Create new entity |
| `GET` | `/entities/{entityId}` | Get entity by ID |
| `PATCH` | `/entities/{entityId}` | Partial update (preferred) |
| `PUT` | `/entities/{entityId}` | Full update (only when PATCH is impractical) |
| `DELETE` | `/entities/{entityId}` | Delete entity |

`PATCH` is the **preferred update method**. Use `PUT` only when semantics require replacing the entire resource.

---

### 4a. PATCH Design Rules

**One PATCH endpoint per resource — never per field:**

```
✅ PATCH /entities/{entityId}        ← caller sends only changed fields
❌ PATCH /entities/{entityId}/status ← sub-path targeting a single field
❌ PATCH /entities/{entityId}/rate   ← sub-path targeting a single field
```

**PATCH vs POST (action) decision:**

| Operation type | HTTP method | Example |
|----------------|-------------|---------|
| Partial field update (idempotent, reversible) | `PATCH /resources/{id}` | Disable entity, update name |
| Semantic action with side effects | `POST /resources/{id}/action` | Cancel operation, rotate secret, approve entity |

Actions change system state in ways that go beyond simple field storage (state machines, notifications, external calls). Model those as `POST` on a sub-resource path, never as PATCH.

**OpenAPI schema for PATCH requests — all fields optional:**

```yaml
components:
  schemas:
    PatchEntityRequest:
      type: object
      description: Partial update payload for an entity. Send only fields that should change.
      properties:
        locked:
          type: boolean
          nullable: true
          description: "true = lock entity (deny access); false = unlock/approve. Absent = no change."
        internalComments:
          type: string
          nullable: true
          description: "Staff-only notes. Absent = no change; empty string = clear."
        someRate:
          type: number
          format: decimal
          nullable: true
          description: "Custom billing rate. Absent = no change; explicit null = clear to platform default."
        entityCallbackUrl:
          type: string
          format: uri
          nullable: true
          description: "Webhook URL for event notifications. Absent = no change; empty = clear."
      # No 'required' array — all fields are optional
```

**Key spec conventions for PATCH schemas:**
- No `required` array — every field is optional
- Use `nullable: true` (OAS 3.0) or `nullable: true` under the field schema to allow explicit `null`
- Document the semantics of explicit `null` vs absent in the field `description`
- Return the full updated resource in the response (not just the changed fields)
- Response `200 OK` for successful PATCH (not `204` — always return the updated state)

---

### 5. Pagination for List Endpoints

Every `GET /entities` list operation should support:

| Parameter | Type | Purpose |
|-----------|------|---------|
| `first` | integer | Page size / number of records to return |
| `max` | integer | Maximum results cap |
| `last-id` | string/integer | Cursor-based pagination anchor |
| `order` | string | Sort field and direction (e.g., `createdAt:desc`) |
| `filter` | string | Free-text search filter |
| `from` | string (date-time) | Start of time range |
| `to` | string (date-time) | End of time range |

---

### 6. Naming Conventions

| Parameter Type | Notation | Example |
|----------------|----------|---------|
| Query parameter | `kebab-lower-case` | `last-id`, `created-after` |
| Path parameter | `camelCase` | `municipalityId`, `userId` |
| Header | `Capitalized-Kebab-Case` prefixed with `X-` | `X-Request-Id`, `X-Correlation-Id` |

---

### 7. Schema Validation Requirements

Every schema in `components.schemas` must include:

- `description` at the schema level
- Field-level `description` for non-trivial fields
- At least one `example` (schema-level or in `components.examples`)
- Validation constraints as appropriate:
  - Strings: `minLength`, `maxLength`, `pattern`, `format`
  - Numbers: `minimum`, `maximum`, `format`
  - Enumerations: `enum`
  - Required fields: `required` array
- `readOnly: true` for server-controlled fields (`id`, `createdAt`, `updatedAt`)
- `writeOnly: true` for write-only secrets (passwords, tokens)

---

### 8. Operation Metadata

Every operation requires:

```yaml
summary: Short imperative description (e.g., "Create a municipality")
description: |
  Longer description explaining the business purpose, side effects,
  and any important notes for clients.
operationId: createMunicipality   # verbEntityQualifier camelCase, stable
tags: [Municipalities]            # exactly ONE tag, defined globally
```

`operationId` naming pattern: `verb` + `Entity` + optional `Qualifier`
- `createMunicipality`, `listMunicipalities`, `getMunicipalityById`
- `updateMunicipalityAddress`, `deleteMunicipality`

---

### 9. Tags

```yaml
# Root level — declare ALL tags here first
tags:
  - name: Municipalities
    description: Operations related to municipality management
  - name: Users
    description: Operations related to user management

# Each operation uses exactly one of these tag names
paths:
  /municipalities:
    post:
      tags: [Municipalities]   # ONE tag only
```

**Never** introduce a tag name inside an operation that has not been declared at the root level.

---

### 10. Headers

```yaml
components:
  headers:
    Location:
      description: URL of the created resource
      schema:
        type: string
        format: uri
    X-Request-Id:
      description: Unique request identifier for tracing
      schema:
        type: string
        format: uuid

  responses:
    CreatedMunicipality:
      description: Municipality successfully created
      headers:
        Location:
          $ref: '#/components/headers/Location'
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Municipality'
```

---

## Complete Minimal Example

```yaml
openapi: 3.0.3
info:
  title: My Service API
  version: 1.0.0
  description: Example service following API-First conventions

tags:
  - name: Resources
    description: Operations related to resource management

paths:
  /resources:
    get:
      summary: List resources
      description: Returns a paginated list of resources.
      operationId: listResources
      tags: [Resources]
      parameters:
        - $ref: '#/components/parameters/First'
        - $ref: '#/components/parameters/LastId'
        - $ref: '#/components/parameters/Filter'
        - $ref: '#/components/parameters/Order'
      responses:
        '200':
          $ref: '#/components/responses/ResourceList'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'
    post:
      summary: Create a resource
      description: Creates a new resource and returns it.
      operationId: createResource
      tags: [Resources]
      requestBody:
        $ref: '#/components/requestBodies/CreateResource'
      responses:
        '201':
          $ref: '#/components/responses/CreatedResource'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '500':
          $ref: '#/components/responses/InternalError'

  /resources/{resourceId}:
    get:
      summary: Get resource by ID
      operationId: getResourceById
      tags: [Resources]
      parameters:
        - $ref: '#/components/parameters/ResourceId'
      responses:
        '200':
          $ref: '#/components/responses/ResourceDetail'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'
    patch:
      summary: Update resource
      operationId: updateResource
      tags: [Resources]
      parameters:
        - $ref: '#/components/parameters/ResourceId'
      requestBody:
        $ref: '#/components/requestBodies/UpdateResource'
      responses:
        '200':
          $ref: '#/components/responses/ResourceDetail'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'
    delete:
      summary: Delete resource
      operationId: deleteResource
      tags: [Resources]
      parameters:
        - $ref: '#/components/parameters/ResourceId'
      responses:
        '204':
          description: Resource deleted successfully
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

components:
  parameters:
    ResourceId:
      name: resourceId
      in: path
      required: true
      schema:
        type: string
      description: Unique identifier of the resource
    First:
      name: first
      in: query
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
      description: Number of records to return
    LastId:
      name: last-id
      in: query
      schema:
        type: string
      description: Cursor for pagination (ID of last record seen)
    Filter:
      name: filter
      in: query
      schema:
        type: string
      description: Free-text filter applied to searchable fields
    Order:
      name: order
      in: query
      schema:
        type: string
        example: "createdAt:desc"
      description: "Sort expression: field:asc or field:desc"

  schemas:
    Resource:
      type: object
      description: Full representation of a resource
      properties:
        id:
          type: string
          readOnly: true
          description: Server-assigned unique identifier
          example: "res-001"
        name:
          type: string
          description: Display name of the resource
          example: "My Resource"
        createdAt:
          type: string
          format: date-time
          readOnly: true
          description: Timestamp when the resource was created
          example: "2026-01-15T10:30:00Z"

    ResourceCreate:
      type: object
      description: Payload to create a new resource
      required: [name]
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 200
          description: Display name for the new resource
          example: "My New Resource"

    ResourceUpdate:
      type: object
      description: Partial update payload for a resource
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 200
          description: New display name
          example: "Updated Name"

    MessageResponse:
      type: object
      description: Standard error response body
      required: [message]
      properties:
        message:
          type: string
          example: "Resource not found"
        code:
          type: string
          example: "RESOURCE_NOT_FOUND"
        details:
          type: object
          additionalProperties: true

  requestBodies:
    CreateResource:
      description: Payload to create a resource
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ResourceCreate'

    UpdateResource:
      description: Partial update payload for a resource
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ResourceUpdate'

  responses:
    ResourceDetail:
      description: Single resource
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Resource'

    ResourceList:
      description: Paginated list of resources
      content:
        application/json:
          schema:
            type: array
            items:
              $ref: '#/components/schemas/Resource'

    CreatedResource:
      description: Resource created successfully
      headers:
        Location:
          description: URL of the newly created resource
          schema:
            type: string
            format: uri
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Resource'

    BadRequest:
      description: Invalid request payload or parameters
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/MessageResponse'

    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/MessageResponse'

    Forbidden:
      description: Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/MessageResponse'

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/MessageResponse'

    InternalError:
      description: Unexpected server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/MessageResponse'
```

---

## Spectral Lint Rules (Conceptual)

Consider enforcing these rules in CI via a `spectral.yaml` ruleset:

| Rule | What It Enforces |
|------|-----------------|
| `no-inline-schemas` | Every schema in path operations must be a `$ref` |
| `require-500-response` | Every operation must declare a `500` response |
| `post-returns-201` | POST create operations must have a `201` response |
| `error-uses-message-response` | Error responses must reference `MessageResponse` |
| `single-tag-per-operation` | Each operation has exactly one tag |
| `tags-declared-globally` | Operation tag names must exist in the root `tags` array |
| `operation-has-metadata` | Every operation has `summary`, `description`, `operationId` |

---

## In the FORGE Workflow

### Reconstruct Phase — Writing the Spec

1. Create `spec/technical/api-contracts.yaml`
2. Define the global `tags` and `info` section first
3. Define all `components.schemas` before writing paths
4. Write `components.requestBodies` and `components.responses`
5. Write `paths` last — only using `$ref` references
6. Run Spectral lint before committing the spec to the repository

### Generate Phase — Implementing from the Spec

The Java Backend Developer should:
1. Use the spec as the contract — **do not deviate from it**
2. Generate or manually create Spring controller interfaces that match every `operationId`
3. Create request/response DTO records matching every schema shape
4. Annotate controllers with `@Operation`, `@ApiResponse` (SpringDoc) referencing the spec
5. Validate that the running app's `/v3/api-docs` output matches the committed spec

If the spec needs to change during implementation, update `spec/technical/api-contracts.yaml` **first**, get it reviewed, then change the implementation.

### Edit Phase — Validation

- Run `spectral lint spec/technical/api-contracts.yaml`
- Run integration tests that assert HTTP status codes match the spec
- Verify `Location` header is returned on all `201` responses
- Confirm error responses return `MessageResponse`-shaped JSON
- Component names MUST NOT end with 'Request' or 'Response'. Use concise names for schemas, requestBodies and responses.