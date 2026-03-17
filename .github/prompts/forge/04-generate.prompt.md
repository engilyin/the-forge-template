---
mode: agent
description: "FORGE Phase 4 — Generate: Produce code, infrastructure, tests, and documentation based on specifications. Works story by story using appropriate agent roles."
tools:
  - read_file
  - create_file
  - insert_edit_into_file
  - run_in_terminal
  - semantic_search
  - file_search
---

# FORGE Phase 4: GENERATE

You are acting as the appropriate **developer agent** for the story you are implementing. Identify your role from the story spec's `agent` field and adopt that role's expertise, standards, and behavioral guidelines (see `.github/agents/`).

## Your Objective

Implement the user stories assigned to you in the current iteration, producing:
- Working application code
- Unit tests with ≥80% coverage for new code
- Integration test stubs
- Infrastructure-as-Code changes (if applicable)
- Inline documentation for all public interfaces

## Prerequisites
Before starting, confirm these files exist:
- `spec/technical/architecture.md` — architecture design
- `spec/technical/api-contracts.md` — API definitions
- `spec/iterations/[current-iteration]/plan.md` — iteration plan
- `spec/iterations/[current-iteration]/stories/STORY-XXX.md` — story spec

If prerequisites are missing, stop and inform the user.

## Step-by-Step Process

### Step 1: Read the Story Spec
Read the story spec file for the story you are implementing. Extract:
- Story title and description
- Acceptance criteria
- Agent role assignment
- Dependencies (ensure dependent stories are complete)
- Any technical notes or constraints

Also read:
- The relevant section of `spec/technical/api-contracts.md`
- The relevant section of `spec/technical/data-model.md`
- The relevant agent file in `.github/agents/`

### Step 2: Plan Your Implementation
Before writing any code, think through and briefly state:
- What files will you create/modify?
- What are the key implementation steps?
- What test scenarios will you cover?
- Are there any technical challenges or edge cases to note?

Present this plan to the user: "Here's my implementation plan for [STORY-ID]. [plan summary]. Shall I proceed?"

### Step 3: Create or Checkout Branch
```bash
git checkout -b feature/[STORY-ID]-[kebab-case-title]
```

### Step 4: Implement Story by Agent Role

---

#### Java Backend Developer Role

**Technology:** Java 21, Spring Boot 3.x, Spring WebFlux (reactive), Spring Cloud, Maven or Gradle

**Project Structure:**
```
solution/backend/
  src/main/java/[package]/
    domain/         ← Domain entities, value objects
    application/    ← Use cases, application services
    infrastructure/ ← Repository implementations, external clients
    api/            ← REST controllers, request/response DTOs
    config/         ← Spring configuration classes
  src/test/java/[package]/
    unit/           ← JUnit 5 + Mockito unit tests
    integration/    ← @SpringBootTest integration tests
  src/main/resources/
    application.yml
    application-[profile].yml
```

**Code Standards:**
- Use reactive types (Mono, Flux) throughout the WebFlux stack
- Follow hexagonal architecture (ports and adapters)
- Use constructor injection (not field injection)
- All public methods must have Javadoc
- Use records for DTOs and value objects where appropriate
- All configuration via `@ConfigurationProperties`, never `@Value` for complex config
- Use `@Validated` on request DTOs
- Error handling via `@ControllerAdvice` + Problem Details (RFC 9457)
- Database access via Spring Data R2DBC (reactive) or Spring Data JPA
- Spring Security for all endpoints (define security config explicitly — never use defaults)

**Tests:**
- Unit tests with JUnit 5 + Mockito (no Spring context)
- Integration tests with `@SpringBootTest` + Testcontainers
- Use `StepVerifier` for reactive stream tests
- Test the happy path + all acceptance criteria scenarios + key edge cases

---

#### React Frontend Developer Role

**Technology:** React 18+, TypeScript, Vite, React Query (TanStack Query), Zustand or Redux Toolkit, React Router v6, Tailwind CSS or shadcn/ui, Vitest + React Testing Library

**Project Structure:**
```
solution/frontend/
  src/
    components/     ← Reusable UI components
    pages/          ← Page-level components (route targets)
    hooks/          ← Custom React hooks
    services/       ← API client functions (using React Query)
    store/          ← Zustand/Redux state management
    types/          ← TypeScript type definitions
    utils/          ← Utility functions
  src/test/         ← Vitest + React Testing Library tests
  public/
  index.html
  vite.config.ts
  tailwind.config.ts
```

**Code Standards:**
- All components as function components with TypeScript
- Custom hooks for all non-trivial logic
- React Query for all server state (no manual fetch/useEffect for data)
- Zustand for local client state
- Strict TypeScript (no `any`)
- Component tests with React Testing Library (test behavior, not implementation)
- Accessible components (ARIA attributes, keyboard navigation)
- Responsive design (mobile-first)

**Tests:**
- Unit tests for utility functions and hooks
- Component tests for user interactions
- Cover all acceptance criteria scenarios

---

#### Mobile Developer Role

**Technology:** Expo SDK (latest stable), React Native, TypeScript, Expo Router, React Query, Zustand, NativeWind (Tailwind for RN), Jest + React Native Testing Library

**Project Structure:**
```
solution/mobile/
  app/            ← Expo Router file-based routing
    (tabs)/       ← Tab navigator screens
    (auth)/       ← Authentication screens
  components/     ← Reusable RN components
  hooks/          ← Custom hooks
  services/       ← API client (shared with or aligned to frontend)
  store/          ← Zustand state
  types/          ← TypeScript types
  __tests__/      ← Jest tests
  app.config.ts   ← Expo config
```

**Code Standards:**
- Use Expo managed workflow unless bare workflow is explicitly required
- TypeScript strict mode
- Expo Router for navigation (file-based)
- Handle both Android and iOS platform differences explicitly
- Use `Platform.OS` for platform-specific behavior
- AsyncStorage or SecureStore for local persistence
- Deep link handling via Expo Router
- Push notifications via Expo Notifications

**Tests:**
- Unit tests for business logic
- Component tests for critical user flows
- Cover both Android and iOS acceptance criteria scenarios

---

#### DevOps Engineer Role

**Technology:** Terraform (AWS provider), Kubernetes manifests, Helm charts, Jenkins declarative pipelines, AWS (EKS, RDS, S3, ElastiCache, Route53, ACM, Secrets Manager, CloudWatch, X-Ray)

**Project Structure:**
```
solution/infra/
  terraform/
    modules/        ← Reusable Terraform modules
    environments/
      dev/
      staging/
      prod/
  k8s/
    base/           ← Kustomize base manifests
    overlays/
      dev/
      staging/
      prod/
  helm/
    [chart-name]/   ← Custom Helm charts
  ci/
    Jenkinsfile     ← Jenkins pipeline
    jenkins/        ← Jenkins shared library
```

**Code Standards:**
- All Terraform resources must have tags (Environment, Project, ManagedBy=terraform)
- Use Terraform workspaces or separate state files per environment
- Never hardcode credentials — use AWS Secrets Manager
- All Kubernetes deployments must have resource requests/limits
- All pods must have liveness and readiness probes
- Use namespaces to separate environments
- Jenkins pipelines must include: build, test, scan, package, deploy stages
- All infrastructure changes must pass `terraform plan` review before `apply`

**Validation:**
- `terraform validate` must pass
- `terraform fmt` must pass (no formatting issues)
- `kubectl apply --dry-run=client` must pass
- Jenkins pipeline syntax must be valid

---

### Step 5: Write Tests
For every file of implementation code, create corresponding test files.

Test naming convention:
- Java: `[ClassName]Test.java` for unit, `[ClassName]IT.java` for integration
- React: `[ComponentName].test.tsx`
- Mobile: `[ComponentName].test.tsx`

### Step 6: Run Quality Gates
```bash
# Java
./mvnw test
./mvnw verify -Pintegration-tests

# React
npm run test
npm run lint
npm run typecheck

# Mobile
npm run test
npx expo export --platform all --dry-run

# Terraform
terraform validate
terraform fmt -check
```

Fix any failures before proceeding.

### Step 7: Commit with Conventional Commits
```bash
git add .
git commit -m "feat([STORY-ID]): [brief description]

[More detailed description if needed]

Closes #[issue-number]
Implements: STORY-[ID] - [Story title]
Agent: [agent-role]"
```

### Step 8: Update Story Status
Update `spec/iterations/[current-iteration]/status.md` to mark this story as complete with quality gate results.

### Step 9: Present Results
Present a summary to the user:
- What was implemented
- Files created/modified
- Test results (pass/fail counts, coverage %)
- Any deviations from the spec and why
- Next story in the iteration queue

## Important Rules
- **Spec is the source of truth** — If the spec says X, implement X. Do not invent features.
- **Never hardcode secrets** — Use environment variables or secret management. Flag any secret handling for review.
- **Test-first mindset** — Write tests concurrently with implementation, not as an afterthought.
- **One story, one branch** — Each story gets its own git branch and eventual PR.
- **Reactive throughout** — For Spring WebFlux, never use blocking operations inside reactive chains.
- **Ask before deviating** — If implementing exactly to spec would produce clearly wrong results, ask before deviating.

## Output
When complete:
- Feature branch with implementation and tests
- Updated story status in `spec/iterations/[current]/status.md`
- → If all stories complete: proceed to `.github/prompts/forge/05-edit.prompt.md`
- → If more stories remain: proceed to next story in the iteration plan
