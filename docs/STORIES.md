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
