---
name: "Expo React Native Mobile Quality Skill"
description: "Quality standards and architecture for Expo-managed React Native mobile apps; use for mobile feature work."
tags: [skill, mobile, expo]
type: skill
---

# Expo React Native Mobile Quality Skill

Use this skill for cross-platform mobile apps built with Expo and React Native. It is the primary quality reference for Android/iOS client code in FORGE projects.

---

## Baseline Stack

- Expo SDK: latest stable release supported by the project
- React Native: version paired with the Expo SDK
- React: version paired with the Expo SDK
- Language: TypeScript with `strict: true`
- Router: Expo Router (file-based navigation)
- Forms: React Hook Form with reusable field components
- Client state: Zustand
- Server state: TanStack Query when the app talks to a backend
- Error tracking: Sentry for production-like builds
- Distribution: EAS Build and EAS Update

Prefer the Expo managed workflow. Move to bare workflow only when there is a hard native requirement that Expo config plugins cannot satisfy.

---

## Architecture Principles

### Keep responsibilities separated

- `app/` owns routing, screen composition, and route guards
- `components/` owns reusable presentation and form widgets
- `hooks/` owns reusable UI and form logic
- `services/` owns side-effects: HTTP, file upload, notifications, analytics, submission orchestration
- `store/` owns persisted client state and cross-screen workflow state
- `utils/` owns pure helpers only
- `types/` owns shared TypeScript models and discriminated unions

Do not let screens become god objects. A screen should assemble hooks, render components, and delegate side-effects.

### Project structure

```text
solutions/<mobile-project>/
├── app/
│   ├── _layout.tsx                 <- root providers, fonts, route shell
│   ├── entry.ts                    <- startup side-effects only
│   ├── +not-found.tsx
│   ├── (auth)/
│   ├── (tabs)/
│   └── [feature]/
├── components/
│   ├── forms/
│   ├── widgets/
│   ├── layout/
│   └── [feature]/
├── context/                        <- only for true tree-wide runtime context
├── hooks/
├── services/
│   ├── api/
│   ├── auth/
│   ├── submission/
│   └── sentry.ts
├── store/
├── constants/
├── lib/                            <- third-party SDK initialization wrappers
├── utils/
├── types/
├── app.config.ts
├── package.json
└── tsconfig.json
```

Organize by feature where it helps readability, but keep routing, side-effects, and persisted state in their dedicated top-level homes.

---

## Startup And App Shell

### `app/entry.ts` is for global side-effects

Initialize things that must happen once when the app boots:

- Sentry setup
- global notification handler
- keyboard manager / platform bootstrap
- other one-time SDK setup that does not require React hooks

`app/entry.ts` must not render UI and must not contain React hooks.

```tsx
import * as Notifications from 'expo-notifications';
import * as Sentry from '@sentry/react-native';

export function initAppEntry() {
  if (!__DEV__ && process.env.EXPO_PUBLIC_SENTRY_DSN) {
    Sentry.init({ dsn: process.env.EXPO_PUBLIC_SENTRY_DSN });
  }

  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowAlert: true,
      shouldPlaySound: true,
      shouldSetBadge: true,
      shouldShowBanner: true,
      shouldShowList: true,
    }),
  });
}

initAppEntry();
```

### `app/_layout.tsx` composes providers once

The root layout should own:

- font loading
- splash screen hide timing
- theme providers
- `QueryClientProvider`
- design-system provider (`PaperProvider`, etc.)
- notification/auth providers
- route guards and welcome redirects

Keep singleton infrastructure outside render when possible. `QueryClient` should be created once, not per render.

```tsx
const queryClient = new QueryClient();

export default function RootLayout() {
  return (
    <ThemeProvider>
      <QueryClientProvider client={queryClient}>
        <NotificationProvider>
          <Stack screenOptions={{ headerBackButtonDisplayMode: 'minimal' }} />
        </NotificationProvider>
      </QueryClientProvider>
    </ThemeProvider>
  );
}
```

---

## Routing And Navigation

Use Expo Router as the single navigation model.

### Route organization

- route groups like `(auth)` and `(tabs)` separate navigation shells
- root `_layout.tsx` owns app-wide providers and redirects
- nested `_layout.tsx` files own stack/tab specifics for that route group
- dynamic segments like `[id].tsx` or `[caseNumber].tsx` for entity detail routes
- `+not-found.tsx` must exist for bad routes

### Navigation rules

- Use `router.push()` for additive navigation
- Use `router.replace()` after login, logout, onboarding, or mandatory redirects
- Read params with typed `useLocalSearchParams<T>()`
- Keep navigation decisions in screen or dedicated guard components, not deep child widgets

### Route guards

Use small guard components that react to auth or onboarding state and redirect when necessary.

```tsx
function WelcomeRedirect() {
  const hasSeenWelcome = useAuthStore((state) => state.hasSeenWelcome);
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (!hasSeenWelcome && segments[0] !== 'welcome') {
      router.replace('/welcome');
    }
  }, [hasSeenWelcome, segments, router]);

  return null;
}
```

---

## Screen, Component, Hook, Service Boundaries

### Screens

Screens should:

- read route params
- call hooks
- compose reusable widgets
- show loading, empty, error, and success states
- trigger navigation

Screens should not:

- construct raw HTTP requests
- own token refresh logic
- own upload orchestration logic
- embed notification registration logic

### Hooks

Hooks are the right place for:

- form setup
- local controller logic
- derived view state
- reusable interaction behavior

Hooks are not the right place for global startup side-effects that should run once on import.

### Services

Services own side-effects and long-running workflows:

- API clients
- refresh-token flow
- background-like submission orchestration
- file uploads with progress
- push token registration
- SDK wrappers

When a workflow needs to outlive one screen mount, use a service module plus store state instead of trapping the whole process inside a component.

---

## API Communication

### Centralize HTTP clients

Create API clients in `services/api/`. Do not call `fetch` or `axios` directly from screens.

Prefer a split like:

- authenticated client
- tokenless/public client

Both clients should share:

- base URL from environment store or config
- request interceptors for headers like device ID
- response normalization for backend error payloads

### Interceptors belong in the client layer

Keep auth refresh, retry, and common headers inside the API client, not duplicated across screens.

```ts
const apiClient = axios.create({ baseURL: apiUrl });

apiClient.interceptors.request.use(async (config) => {
  const token = authStore.getState().accessToken;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true;
      await refreshAccessToken();
      return apiClient(error.config);
    }
    return Promise.reject(error);
  },
);
```

### API layer rules

- One module owns one API concern: `auth`, `reports`, `jurisdiction`, `submission`
- Export typed service functions, not raw axios calls from components
- Normalize backend errors into a stable shape before they hit UI code
- Add device or install identifiers in the client layer when required by backend design
- Keep request/response mapping close to the API boundary

### Do not do this

- screens calling `axios.get()` directly
- duplicating auth header logic across multiple hooks
- reading `process.env` all over the UI tree
- silently swallowing backend error bodies

---

## State Management

Choose the smallest state tool that fits the problem.

| State Type | Tool | Examples |
|-----------|------|----------|
| Ephemeral UI state | `useState` / `useReducer` | dialog open, selected tab, local draft field |
| Form state | React Hook Form | report form, profile form, login OTP flow |
| Server state | TanStack Query | fetched profile, lists, lookup data |
| Cross-screen client workflow state | Zustand | auth session, report draft, onboarding flags |

### Zustand rules

- Persist only what must survive reload or app restart
- Use `partialize` so volatile fields are not stored
- Keep store actions pure when practical
- Use `store.getState()` in service modules instead of calling selector hooks outside React

Do not persist transient progress bars, loading flags, or derived values unless resume behavior truly requires it.

```ts
export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      accessToken: null,
      hasSeenWelcome: false,
      setAuthState: (data) => set(data),
    }),
    {
      name: 'auth-store',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        accessToken: state.accessToken,
        hasSeenWelcome: state.hasSeenWelcome,
      }),
    },
  ),
);
```

### Secure storage

- Prefer `expo-secure-store` for access tokens, refresh tokens, device secrets, and verification tokens
- Use AsyncStorage only for non-sensitive persisted UI or workflow state
- If Zustand persistence is used for auth, provide a SecureStore-backed storage adapter instead of plain AsyncStorage when security requirements matter

---

## Forms And Validation

Use React Hook Form for all non-trivial forms.

### Form rules

- Forms live in screens or feature container components
- Reusable field widgets live in `components/forms/` or `components/widgets/`
- Validation rules are explicit and close to the field definitions
- Patch-style forms submit only changed fields when the API supports partial updates
- Reset forms carefully when initial values change

```ts
export function usePatchForm<T extends FieldValues>(
  initial: Partial<T> | undefined,
  onSubmit: (data: Partial<T>) => void,
) {
  const form = useForm<T>({
    defaultValues: (initial ?? {}) as DefaultValues<T>,
    mode: 'onChange',
  });

  const save: SubmitHandler<T> = () => {
    const dirty = form.formState.dirtyFields;
    const values = form.getValues();
    const patch: Partial<T> = {};

    (Object.keys(dirty) as Array<keyof T>).forEach((key) => {
      patch[key] = values[key];
    });

    onSubmit(patch);
  };

  return { ...form, save: form.handleSubmit(save) };
}
```

### Form anti-rules

- do not build large manual `useState` forms field by field
- do not duplicate validation logic across multiple screens
- do not submit unchanged fields in patch flows if backend semantics care about partial updates

---

## Notifications

Treat push notifications as a cross-cutting runtime feature, not a screen detail.

### Recommended design

1. `app/entry.ts` sets the global Expo notification handler
2. `NotificationProvider` requests permission, obtains the Expo push token, and wires listeners
3. A service registers/unregisters the token with the backend
4. Route handling for notification taps is centralized, not scattered through screens

```tsx
useEffect(() => {
  registerForPushNotificationsAsync().then(setExpoPushToken, setError);

  notificationListener.current =
    Notifications.addNotificationReceivedListener(setNotification);

  responseListener.current =
    Notifications.addNotificationResponseReceivedListener((response) => {
      // map payload to route here
    });

  return () => {
    notificationListener.current?.remove();
    responseListener.current?.remove();
  };
}, []);
```

### Notification rules

- Feature-flag notifications if the app can run without them
- Ask for permission in a controlled, user-meaningful flow
- Register push tokens with the backend only after a token is available
- Remove listeners on cleanup
- Keep tap-to-route logic centralized and typed
- Handle unsupported environments like Expo Go where some push behavior differs

### Do not do this

- request notification permission from random screens on every mount
- add listeners without removing them
- mix backend registration calls directly into view components
- ignore token refresh / token change scenarios

---

## Native Capabilities And Config

### `app.config.ts` is the source of truth

Use `app.config.ts` for:

- environment-specific app name, bundle IDs, package names
- permissions
- plugin configuration
- deep links and URL schemes
- icons and splash setup

Prefer config plugins and Expo-supported configuration over manual edits in native folders.

### Native module rule

If a feature requires a native module that changes native build output:

- document that it requires a new EAS build
- do not pretend an OTA update alone can deliver it
- keep the implementation optional or feature-flagged until the build rollout is ready

---

## Error Handling And Observability

- Initialize Sentry in startup code, not inside random screens
- Capture startup failures without crashing the app if recovery is possible
- Convert backend or network errors into user-friendly messages near the service/UI boundary
- Avoid logging PII, access tokens, refresh tokens, or secrets
- Show actionable errors to the user: retry, check connection, continue later

If the app has long-running submission flows, surface explicit state transitions such as `creating`, `uploading`, `finalizing`, `success`, `error` instead of a single ambiguous loading flag.

---

## Performance And UX

- Use `FlatList` or `FlashList` for variable-length lists
- Avoid `ScrollView` plus `.map()` for large collections
- Keep expensive startup work outside the initial render path when possible
- Use memoization only where it solves a demonstrated render problem
- Avoid creating new provider instances, query clients, or large style objects every render
- Prefer progressive UI states: skeleton, empty, retry, success
- Respect safe areas, keyboard behavior, dark mode, and dynamic text size

---

## Testing Strategy

### Unit and component tests

- Jest with `jest-expo`
- React Native Testing Library for components and hooks
- test service modules separately from screens
- test auth and notification edge cases with mocks, not real devices in CI

### Manual validation matrix

For every significant mobile story, verify:

- iOS simulator
- Android emulator
- fresh install path
- returning user path
- offline or unstable network behavior if relevant
- push-notification behavior if relevant
- large text / accessibility basics

### Build validation

- `npx expo start --clear` for local sanity
- `npx expo export --platform all --dry-run` when validating exportability
- EAS build checks for features requiring native capabilities

---

## Anti-Patterns

| Anti-pattern | Instead |
|-------------|---------|
| `axios` or `fetch` directly in screens | Call typed service functions from `services/api/` |
| One huge screen with API, form, and upload logic mixed together | Split into screen, hooks, service, and store responsibilities |
| Persisting everything in Zustand | Persist only the fields needed across restarts |
| Tokens in plain AsyncStorage by default | Use SecureStore or a secure persistence adapter |
| Notification listeners added in screens | Centralize in a provider or service |
| Creating `QueryClient` inside a component render | Create one singleton client |
| Global startup logic inside React components | Put one-time side-effects in `app/entry.ts` |
| ScrollView for long lists | Use FlatList or FlashList |
| Route decisions spread across child widgets | Centralize redirects in guards or top-level screens |
| Editing native files directly for simple Expo config | Prefer `app.config.ts` and config plugins |

---

## Checklist For Every Story

- [ ] Route files are organized clearly under `app/` with the right layout boundaries
- [ ] Screen only composes UI and delegates side-effects to hooks/services
- [ ] API calls go through centralized clients and typed service functions
- [ ] Auth refresh and shared headers live in interceptors, not duplicated in screens
- [ ] State tool matches the problem: local state vs form vs server state vs Zustand
- [ ] Persisted Zustand state is intentionally scoped with `partialize`
- [ ] Sensitive tokens or secrets are not stored in plain AsyncStorage without justification
- [ ] Forms use React Hook Form and reusable field components
- [ ] Notification setup is centralized and listeners are cleaned up
- [ ] `app.config.ts` captures permissions/plugins for new native capabilities
- [ ] Loading, empty, error, and retry states are present where needed
- [ ] Lists use FlatList or FlashList where data size is unbounded
- [ ] Accessibility basics are present on interactive elements
- [ ] Story is validated on both Android and iOS paths when behavior can differ