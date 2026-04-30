---
name: "Testing"
description: "Testing strategies and patterns across unit, integration, and E2E layers."
user-invocable: false
---

# Testing Skill

> Comprehensive testing strategy and patterns for the FORGE technology stack. Apply when writing or reviewing tests at any layer.

---

## Testing Philosophy

1. **Test behavior, not implementation** — Tests should describe what the system does, not how it does it. A test that breaks when you refactor (without changing behavior) is a bad test.
2. **Test pyramid** — Most tests at the unit level (fast, isolated), fewer at integration level, fewest at E2E level. Invert this and your test suite becomes slow and brittle.
3. **Arrange-Act-Assert (AAA)** — Structure every test as: set up context → perform action → verify outcome.
4. **One logical assertion per test** — A test that fails should tell you exactly what broke. Multiple unrelated assertions obscure failures.
5. **Tests are documentation** — A well-named test describes the expected behavior of the system.

---

## Build Setup — Gradle Source Set Suites (Java)

**CRITICAL:** This project uses **Gradle source set suites**, NOT raw `testImplementation` blocks. Never add `testImplementation` dependencies directly to `build.gradle`. All test dependencies belong inside the `testing { suites { } }` block.

```groovy
// ✅ Correct — Gradle testing suites
testing {
    suites {
        test {
            useJUnitJupiter()
            dependencies {
              compileOnly 'org.projectlombok:lombok'
              annotationProcessor 'org.projectlombok:lombok'

              implementation 'org.mockito:mockito-junit-jupiter'
              implementation 'org.assertj:assertj-core'
              implementation 'org.hamcrest:hamcrest'
              implementation 'io.projectreactor:reactor-test'

              // Ensure JUnit 5 is available for the unit test suite
              implementation 'org.junit.jupiter:junit-jupiter-api'
              runtimeOnly   'org.junit.jupiter:junit-jupiter-engine'
            }
        }

        integrationTest(JvmTestSuite) {
            targets {
              all {
                testTask.configure {
                  systemProperty('spring.profiles.active', 'test')
                }
              }
            }


            useJUnitJupiter()
            sources {
                java.srcDirs = ['src/integrationTest/java']
                resources.srcDirs = ['src/integrationTest/resources']
            }
            dependencies {
                implementation project()
                
                implementation sourceSets.main.runtimeClasspath
                implementation sourceSets.test.runtimeClasspath

                compileOnly 'org.projectlombok:lombok'
                annotationProcessor 'org.projectlombok:lombok'

                implementation 'org.springframework.boot:spring-boot-starter-webflux-test'
                implementation 'org.springframework.security:spring-security-test'
                implementation "io.rest-assured:rest-assured:${restAssuredVersion}"
                implementation "io.rest-assured:spring-web-test-client:${restAssuredVersion}"
                implementation "io.rest-assured:json-path:${restAssuredVersion}"
                implementation 'io.r2dbc:r2dbc-h2'
            }
            sources {
                java {
                  srcDirs = [
                            'src/integrationTest/java', 
                            'src/main/java', 
                            "$buildDir/generated/openapi/src/main/java", 
                            "$buildDir/generated/sources/annotationProcessor/java/main"
                          ]
                }
                resources {
                  srcDirs = ['src/integrationTest/resources', 'src/main/resources']
                }
            }
        }
    }
}
```

```groovy
// ❌ FORBIDDEN — raw testImplementation
testImplementation 'org.springframework.boot:spring-boot-starter-test'
testImplementation 'org.springframework.boot:spring-boot-starter-webflux'
```

**Build sequence every story must follow:**
```
./gradlew openApiGenerate   # generate Java from OpenAPI spec FIRST
# ... implement the story ...
./gradlew spotlessApply     # format code
./gradlew clean build       # compile + unit tests
./gradlew integrationTest   # integration tests
```

---

## Test Naming Convention

```
[UnitUnderTest]_[Scenario]_[ExpectedOutcome]

Examples:
getUser_whenUserExists_returnsUserDto
getUser_whenUserNotFound_throwsNotFoundException
processPayment_whenCardDeclined_returnsPaymentFailedError
LoginForm_whenPasswordTooShort_showsValidationError
```

---

## Unit Testing — Java / Spring Boot

### Rules — READ FIRST

- **No Spring context in unit tests.** Unit tests use `@ExtendWith(MockitoExtension.class)` only. Never use `@SpringBootTest`, `@WebFluxTest`, `@ContextConfiguration`, or any Spring test slice annotation in a unit test.
- **Prefer MockitoExtension style:** prefer `@Mock` + `@InjectMocks` fields with `@ExtendWith(MockitoExtension.class)` rather than manual `Mockito.mock(...)` calls. Avoid static `Mockito.mock(...)` in tests — it makes lifecycle and injection harder to reason about.
- **Only services are unit tested.** Controllers have zero business logic and are therefore NOT unit tested. Controller behavior (validation, HTTP status mapping) is covered by integration tests.
- **All dependencies mocked.** `@Mock` + `@InjectMocks`. No real DB, no real HTTP, no real file I/O.
- **`StepVerifier` for reactive assertions.** Never call `.block()` in tests. Prefer `StepVerifier` for all reactive unit test assertions to keep non-blocking and deterministic behavior.

### Unit Test Pattern

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;
    
    @Mock
    private EmailService emailService;

    @InjectMocks
    private UserService userService;

    // Arrange common test data
    private final User testUser = new User("user-123", "test@example.com", "John", "Doe");

    @Test
    void getUser_whenUserExists_returnsUserDto() {
        // Arrange
        when(userRepository.findById("user-123")).thenReturn(Mono.just(testUser));
        
        // Act
        var result = userService.getUser("user-123");
        
        // Assert
        StepVerifier.create(result)
            .assertNext(dto -> {
                assertThat(dto.id()).isEqualTo("user-123");
                assertThat(dto.email()).isEqualTo("test@example.com");
            })
            .verifyComplete();
    }

    @Test
    void getUser_whenUserNotFound_throwsUserNotFoundException() {
        // Arrange
        when(userRepository.findById("unknown")).thenReturn(Mono.empty());

        // Act & Assert
        StepVerifier.create(userService.getUser("unknown"))
            .expectError(UserNotFoundException.class)
            .verify();
    }
    
    @Test
    void createUser_whenEmailAlreadyExists_throwsDuplicateEmailException() {
        // Arrange
        var request = new CreateUserRequest("existing@example.com", "Password123!", "Jane", "Doe");
        when(userRepository.existsByEmail("existing@example.com")).thenReturn(Mono.just(true));
        
        // Act & Assert
        StepVerifier.create(userService.createUser(request))
            .expectError(DuplicateEmailException.class)
            .verify();
        
        // Verify side effects did NOT happen
        verify(emailService, never()).sendWelcomeEmail(any());
    }
}
```

### Reactive Test Patterns
```java
// Testing Flux (multiple items)
StepVerifier.create(userService.getAllUsers())
    .expectNextCount(3)
    .verifyComplete();

// Testing with timeout
StepVerifier.create(userService.getUser("slow-user"))
    .expectNextMatches(user -> user.email() != null)
    .verifyComplete(Duration.ofSeconds(5));

// Testing error properties
StepVerifier.create(userService.getUser("bad"))
    .expectErrorSatisfies(error -> {
        assertThat(error).isInstanceOf(UserNotFoundException.class);
        assertThat(error.getMessage()).contains("bad");
    })
    .verify();
```

---

## Integration Testing — Java / Spring Boot


---

**Notes:**
- Controller tests that require the full application context (security, filters, global advice) should live in the `integrationTest` source set (`src/integrationTest/java`) so they run in the integration pipeline. Prefer `WebTestClient` for controller and integration tests over `MockMvc`.
- For lightweight controller slice tests use `@WebFluxTest(controllers = ...)` and `@Import` to bring only the necessary security test config. For full-context controller tests, use `@SpringBootTest` + `@AutoConfigureWebTestClient` and place them under `src/integrationTest/java`.

## Unit Testing — React / TypeScript

### Setup
```bash
npm install -D vitest @testing-library/react @testing-library/user-event @testing-library/jest-dom jsdom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    coverage: { reporter: ['text', 'lcov'], threshold: { lines: 80 } },
  },
});
```

### Component Test Pattern
```tsx
// src/test/setup.ts
import '@testing-library/jest-dom';

// Component test
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock React Query's useQuery for isolated tests
vi.mock('../hooks/use-user', () => ({
  useUser: vi.fn(),
}));

describe('UserProfile', () => {
  const user = userEvent.setup();

  it('shows user information when data is loaded', () => {
    vi.mocked(useUser).mockReturnValue({
      data: { id: '1', email: 'test@example.com', firstName: 'John', lastName: 'Doe' },
      isLoading: false,
      error: null,
    } as any);

    render(<UserProfile userId="1" />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('test@example.com')).toBeInTheDocument();
  });

  it('shows loading skeleton while fetching', () => {
    vi.mocked(useUser).mockReturnValue({ data: undefined, isLoading: true, error: null } as any);
    render(<UserProfile userId="1" />);
    expect(screen.getByTestId('user-profile-skeleton')).toBeInTheDocument();
  });

  it('shows error state when request fails', () => {
    vi.mocked(useUser).mockReturnValue({
      data: undefined,
      isLoading: false,
      error: new Error('Failed to fetch'),
    } as any);
    render(<UserProfile userId="1" />);
    expect(screen.getByRole('alert')).toHaveTextContent('Failed to load user');
  });
});
```

### Form Interaction Test
```tsx
it('submits form with correct data', async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText('Email'), 'test@example.com');
  await user.type(screen.getByLabelText('Password'), 'Password123!');
  await user.click(screen.getByRole('button', { name: 'Log In' }));

  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'Password123!',
    });
  });
});

it('shows validation error for invalid email', async () => {
  render(<LoginForm onSubmit={vi.fn()} />);

  await user.type(screen.getByLabelText('Email'), 'not-an-email');
  await user.tab(); // trigger blur

  expect(await screen.findByRole('alert')).toHaveTextContent('Invalid email');
});
```

---

## Unit Testing — React Native / Expo

### Setup
```bash
npm install -D jest @testing-library/react-native jest-expo
```

```json
// package.json
{
  "jest": {
    "preset": "jest-expo",
    "setupFilesAfterFramework": ["@testing-library/react-native/extend-expect"]
  }
}
```

### Mobile Component Test
```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

describe('LoginScreen', () => {
  it('navigates to home on successful login', async () => {
    const mockLogin = vi.fn().mockResolvedValue({ token: 'abc' });
    vi.mocked(useLoginMutation).mockReturnValue({ mutateAsync: mockLogin } as any);
    
    render(<LoginScreen />);
    
    fireEvent.changeText(screen.getByTestId('email-input'), 'test@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'Password123!');
    fireEvent.press(screen.getByText('Log In'));
    
    await waitFor(() => expect(mockLogin).toHaveBeenCalled());
  });
});
```

---

## API Testing (REST)

### Using curl for manual verification
```bash
# Health check
curl -s http://localhost:8080/actuator/health | jq .

# Login
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Password123!"}' \
  | jq -r '.access_token')

# Authenticated request
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/users/me | jq .
```

---

## Performance Testing (k6)

```javascript
// k6 load test script
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up to 20 users
    { duration: '1m', target: 20 },   // Stay at 20 users
    { duration: '10s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],  // 95% of requests under 200ms
    http_req_failed: ['rate<0.01'],    // Error rate under 1%
  },
};

export default function () {
  const response = http.get('http://staging.api.example.com/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
  sleep(1);
}
```

---

## Test Coverage Targets

| Component | Unit Coverage | Integration Coverage |
|-----------|-------------|---------------------|
| Java Application Services | ≥90% | All use cases |
| Java Controllers | ≥80% | All endpoints + error paths |
| Java Repositories | ≥70% | All custom queries |
| React Components | ≥80% | Critical user interactions |
| React Custom Hooks | ≥90% | All state transitions |
| React Pages | ≥70% | Happy path + error state |
| Mobile Screens | ≥70% | Critical user flows |

---

## Continuous Testing in CI

```bash
# These run in the CI pipeline on every PR:
./mvnw verify                    # Java: unit + integration tests
npm run test -- --coverage       # React/Mobile: unit tests with coverage
npx playwright test              # E2E: critical user journeys (staging deploy required)
```
