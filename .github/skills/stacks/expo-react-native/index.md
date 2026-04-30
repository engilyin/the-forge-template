# Expo / React Native (Mobile) — Tech Stack Index

## Overview

Cross-platform mobile apps built with Expo SDK, React Native, Expo Router for navigation,
React Hook Form for forms, Zustand for state, and Sentry for error tracking.
Built and deployed via EAS (Expo Application Services).

## Stack Files

| File | Purpose |
|------|---------|
| [`patterns.md`](patterns.md) | → `.github/skills/expo-react-native.md` — Route structure, API communication, forms, Zustand, notifications, config, performance |
| `review-checklist.md` | *(planned)* — Mobile-specific pre-commit review gate |
| `story-template.md` | *(planned)* — Mobile story spec template with code skeletons |

> **Migration path:** As patterns grow, split into focused files:
> - `patterns-navigation.md` — Expo Router, deep links, tab/stack layout
> - `patterns-forms.md` — React Hook Form + custom fields
> - `patterns-state.md` — Zustand stores, offline-first, sync
> - `patterns-notifications.md` — Push notifications, Expo Notifications API
> - `patterns-platform.md` — Platform-specific code, iOS/Android differences
> - `patterns-performance.md` — FlatList, memo, image optimization, bundle size

## Build & Validation Commands

```bash
# 1. Install dependencies
yarn install

# 2. Type check
npx tsc --noEmit

# 3. Lint
npx eslint .

# 4. Start dev (web)
npx expo start --web

# 5. EAS build (local)
eas build --platform android --profile development --local
eas build --platform ios --profile development --local
```

## Mandatory Development Workflow

1. `yarn install` — ensure dependencies are installed
2. Implement the story following `patterns.md` (`.github/skills/expo-react-native.md`)
3. **Run the Mobile Review Checklist** (`review-checklist.md`) — fix ALL findings before proceeding *(checklist planned; skip step until file exists)*
4. `npx tsc --noEmit` — must pass with zero type errors
5. `npx eslint .` — must pass with zero errors
6. `npx expo start --web` — verify the app starts without runtime errors (spot-check affected screens)
7. Commit with `git commit` (author set by `.forge/init-worktree.sh`)
8. Push and open PR with `gh pr create --base $FORGE_BASE_BRANCH`

## Agent

`mobile-developer` — see `.github/agents/mobile-developer.md`

## Secret/Config Files

Files to copy to worktrees (gitignored):
- `.env`
- `.env.local`
