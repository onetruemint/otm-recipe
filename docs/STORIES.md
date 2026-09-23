# Stories

Story breakdown for building `recipe-app-mvp-plan.md`. Phase 0 is fully
broken out below. Phases 1–11 (see the plan's Section 10) will get their own
story breakdowns added here as each phase is planned.

## Phase 0 — Foundations

### 0.1 — Repo & app scaffolding

Create `/mobile`, `/supabase`, `/docs`. Move the MVP plan into `/docs`.
Scaffold the Expo app (TypeScript strict, Expo Router, ESLint, Prettier).
`npm run lint` and `npm run typecheck` pass from `/mobile`. Create
`PROGRESS.md` and this file.

### 0.2 — EAS config

Configure EAS: bundle identifiers, development builds for iOS and Android,
`APP_NAME` placeholder wired through `app.json`/`eas.json`.

### 0.3 — Supabase local + prod init & type-gen

Initialize local Supabase with the CLI. Create the production project on a
paid plan. Store URL and anon key per environment. Add a script that
generates database types into `/mobile`.

### 0.4 — Sentry

Add Sentry crash reporting (Expo integration).

### 0.5 — CI

GitHub Actions on every pull request: lint, typecheck, Jest,
`supabase test db`.

**Phase 0 done when:** a development build runs on an iOS simulator and an
Android emulator; local Supabase starts; CI passes.

## Phase 1 -- Accounts and core schema

### 1.1 -- Database migration & RLS foundation
Migration: all enums (Section 6.1), `profiles`, `blocks`, `blocked_terms` tables,
`is_blocked_between` function, RLS for rules R6/R7/R9 (Section 7), seed
`blocked_terms`. Word-filter trigger function attached to `profiles.username`.
`complete_onboarding(username)` function. pgTAP tests for all of the above.

### 1.2 -- Supabase Auth config & sign-in screen
Configure Supabase Auth for Apple (native iOS, OAuth browser flow Android) and
Google (iOS/Android/web client IDs) sign-in. Sign-in screen using
`signInWithIdToken`. Blocked in part on missing Apple Developer / Google
Cloud OAuth accounts -- stub what can't be configured yet, per the Accounts
note in PROGRESS.md.

### 1.3 -- Session routing, onboarding, settings
Session persistence and routing (signed out -> Sign in; no profile ->
Onboarding; else tabs). Onboarding screen wired to `complete_onboarding`.
Temporary settings screen with Sign out. Depends on 1.1 and 1.2.

### 1.4 -- Terms and privacy placeholder pages
Publish placeholder terms and privacy policy as static pages on any static
host, and link them from the sign-in/onboarding screens built in 1.2/1.3.

**Phase 1 done when:** see plan Section 10 -- a new user signs in with Apple
and Google on both platforms (blocked until real accounts exist -- see 1.2),
picks a username, lands on the tabs; relaunching keeps the session; bad
usernames are rejected with clear messages; pgTAP covers profile write
protection and block-list privacy.
