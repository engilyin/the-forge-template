---
name: "Documentation Skill"
description: "Standards and practices for writing and maintaining project documentation within the repository."
tags: [skill, docs]
type: skill
---

# Documentation Skill

> Apply this skill when generating, reviewing, or maintaining project documentation. Good documentation is part of the Definition of Done.

---

## Documentation Philosophy

1. **Documentation is code** — It lives in the repo, is version-controlled, and reviewed like code.
2. **Document the why, not just the what** — Code explains what happens. Documentation explains why decisions were made.
3. **Minimal but complete** — Don't over-document. Document what will not be obvious to a new contributor in 6 months.
4. **Keep it close** — Documentation should live as close as possible to the code it describes.
5. **Always up to date** — Outdated documentation is worse than no documentation. Update docs with every relevant code change.

---

## Documentation Types and Locations

### API Documentation (OpenAPI)
**Location:** Generated from code annotations, served at `/api-docs` or `/swagger-ui`
**When to update:** Every time an API endpoint is added, changed, or removed

**Spring Boot OpenAPI Example:**
```java
@Operation(
    summary = "Get user by ID",
    description = "Returns the user profile for the given user ID. Requires authentication.",
    security = @SecurityRequirement(name = "bearerAuth"),
    responses = {
        @ApiResponse(responseCode = "200", description = "User found",
            content = @Content(schema = @Schema(implementation = UserDto.class))),
        @ApiResponse(responseCode = "404", description = "User not found",
            content = @Content(schema = @Schema(implementation = ProblemDetail.class))),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    }
)
@GetMapping("/{id}")
public Mono<ResponseEntity<UserDto>> getUser(@PathVariable String id) { ... }
```

### Architecture Decision Records (ADRs)
**Location:** `spec/technical/architecture.md` — ADR section
**When to write:** Every time a significant architectural or technology decision is made
**Format:**

```markdown
## ADR-N: [Decision Title]

**Date:** YYYY-MM-DD
**Status:** proposed | accepted | deprecated | superseded by ADR-M

### Context
[1-3 paragraphs: Why did this decision need to be made? What forces were at play?]

### Decision
[The decision that was made, stated clearly and directly]

### Rationale
[Why this option was chosen over alternatives]

### Alternatives Considered
- **[Alternative 1]:** [Brief description and why it was rejected]
- **[Alternative 2]:** [Brief description and why it was rejected]

### Consequences
**Positive:**
- [Benefit 1]
- [Benefit 2]

**Negative:**
- [Trade-off or cost 1]
- [Trade-off or cost 2]

**Neutral:**
- [Observation that's neither good nor bad]
```

### README Files
**Location:** `solutions/<project-name>/README.md`
**Required sections:**

```markdown
# [Component Name]

Brief one-paragraph description of what this component does.

## Architecture

Brief description of the component's architecture and key patterns.

## Prerequisites

- Java 21+ / Node.js 20+ (as appropriate)
- Docker Desktop (for local services)
- AWS CLI (if infrastructure interaction needed)

## Getting Started

### 1. Clone and Set Up
```bash
git clone ...
cd solutions/<api-project>
cp src/main/resources/application-local.yml.example src/main/resources/application-local.yml
# Edit application-local.yml with your local settings
```

### 2. Start Local Dependencies
```bash
docker compose up -d postgres redis
```

### 3. Run the Application
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

### 4. Verify
```bash
curl http://localhost:8080/actuator/health
```

## Running Tests
```bash
./mvnw verify          # All tests
./mvnw test           # Unit tests only
./mvnw verify -Pit    # Integration tests only
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DB_URL` | PostgreSQL JDBC URL | — | Yes |
| `JWT_PUBLIC_KEY_PATH` | Path to RS256 public key | — | Yes |

## Project Structure

[Directory tree with descriptions]
```

### Inline Code Comments

**When to add comments:**
- Complex algorithms that aren't obvious from the code
- Business rules that aren't captured elsewhere
- Workarounds for known bugs or limitations (with a link to the issue)
- Non-obvious performance optimizations

**When NOT to add comments:**
- Code that is self-explanatory
- Comments that just restate what the code does ("// increment counter")
- Commented-out code (delete it; git remembers)

```java
// ✅ Good comment — explains the WHY
// We use RS256 instead of HS256 to allow token validation
// without sharing the signing key (needed for microservice architecture)
Jwts.builder().signWith(privateKey, Jwts.SIG.RS256)

// ❌ Bad comment — restates the code
// Create the JWT builder and sign with RS256
Jwts.builder().signWith(privateKey, Jwts.SIG.RS256)

// ✅ Good comment — explains a workaround
// DynamoDB does not support transactions across tables in the same request.
// We handle this by using the outbox pattern (see OrderOutboxService).
// See: https://github.com/org/repo/issues/123
orderRepository.save(order)
```

### Javadoc Standards

```java
/**
 * Retrieves a user by their unique identifier.
 *
 * @param userId the unique identifier of the user — must not be null or empty
 * @return a {@link Mono} emitting the user DTO, or empty if the user does not exist
 * @throws IllegalArgumentException if userId is null or empty
 */
public Mono<UserDto> getUser(String userId) { ... }
```

**Required Javadoc on:**
- All public methods in application services
- All public methods in domain classes
- All REST controller methods (supplemented by OpenAPI annotations)
- All public interfaces

**Not required Javadoc on:**
- Private methods (unless particularly complex)
- Obvious getter/setter methods
- Test methods

### TypeScript JSDoc

```typescript
/**
 * Fetches a user by ID from the API.
 * @param userId - The unique identifier of the user
 * @returns The user data or throws an error if not found
 */
async function fetchUser(userId: string): Promise<User> { ... }
```

---

## CHANGELOG Maintenance

Every release should update `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format:

```markdown
# Changelog

## [Unreleased]

## [1.2.0] - 2024-03-15

### Added
- User profile picture upload feature (#45)
- Dark mode support across all pages (#52)

### Changed
- Login page redesigned for improved UX (#48)
- Password validation strengthened to require special characters (#51)

### Fixed
- Fixed race condition in cart update handler (#49)
- Email verification link now correctly handles URL encoding (#50)

### Security
- Updated Spring Security to 6.2.3 (CVE-2024-XXXX)
- Enabled HSTS header on all responses

## [1.1.0] - 2024-02-01
...
```

---

## Documentation Review Checklist (Edit Phase)

When reviewing documentation as part of the Edit phase:

### API Documentation
- [ ] All new endpoints are documented in OpenAPI
- [ ] All modified endpoints have updated documentation
- [ ] Error responses are documented for all endpoints
- [ ] Request/response schemas are accurate and complete
- [ ] Authentication requirements are documented

### Architecture Documentation
- [ ] New architectural decisions have ADRs
- [ ] Architecture diagrams are updated for new components
- [ ] The component inventory is current
- [ ] Technology versions are accurate

### README
- [ ] Getting started instructions are accurate and complete
- [ ] Prerequisites are current
- [ ] Environment variables table is complete
- [ ] Running tests instructions are accurate
- [ ] Project structure description reflects current state

### Inline Comments
- [ ] Complex logic has explanatory comments
- [ ] No commented-out code
- [ ] No stale comments (comments that no longer match the code)

### CHANGELOG
- [ ] Changes for this release are listed
- [ ] Breaking changes are clearly marked
- [ ] Security fixes are in the Security section

---

## Documentation Automation

### Generate OpenAPI Spec
```bash
# Spring Boot — generate at startup and export
curl http://localhost:8080/v3/api-docs > spec/technical/openapi.json
# Convert to YAML for readability
npx @redocly/cli bundle spec/technical/openapi.json -o spec/technical/openapi.yaml
```

### Generate TypeScript Types from OpenAPI
```bash
npx openapi-typescript spec/technical/openapi.yaml -o solutions/<web-project>/src/types/api.types.ts
npx openapi-typescript spec/technical/openapi.yaml -o solutions/<mobile-project>/src/types/api.types.ts
```
