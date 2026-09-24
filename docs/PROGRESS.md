# Progress log

## How to use this file

This is the running handoff log between agent sessions working on this project.
When you finish a story, append a dated entry at the top of the "Log" section
below with:

- What you built.
- Any decisions or deviations from `recipe-app-mvp-plan.md` or `STORIES.md`,
  and why.
- What's left for the next session.
- Open questions or blockers for the human owner (jmyeh51@gmail.com).

Do not rewrite history — only append. If a later story invalidates something
an earlier entry said, note that in the new entry rather than editing the old
one.

## Accounts note

Apple Developer and Google Play Console / Google Cloud OAuth accounts are
**not yet available**. Anything that needs them (native Sign in with Apple /
Google credentials, App Store or Play Store bundle registration) must be
stubbed with a clear marker rather than blocked on:

- `// TODO(owner): needs Apple Developer account`
- `// TODO(owner): needs Google Play/Cloud OAuth`

Expo/EAS and Supabase accounts **are** available, so work that only needs
those can proceed normally.

## Phase 0 status

- [x] 0.1 — Repo & app scaffolding
- [x] 0.2 — EAS config
- [x] 0.3 — Supabase local + prod init & type-gen
- [x] 0.4 — Sentry
- [x] 0.5 — CI

See `STORIES.md` for the full breakdown of each story.

## Phase 1 status

- [x] 1.1 — Database migration & RLS foundation
- [ ] 1.2 — Supabase Auth config & sign-in screen
- [ ] 1.3 — Session routing, onboarding, settings
- [ ] 1.4 — Terms and privacy placeholder pages

See `STORIES.md` for the full breakdown of each story.

## Log

### 2026-09-23 — Story 1.1: Database migration & RLS foundation

Built:

- First migration, `supabase/migrations/20260923021522_create_core_schema.sql`:
  `profiles`, `blocks`, `blocked_terms` tables exactly per plan Section 6.2;
  `is_blocked_between(a, b)` (`SECURITY DEFINER`, `STABLE`); RLS on all three
  tables for R6 (profiles visible to everyone except across a block), R7
  (blocks visible only to the blocker), R9 (write only your own rows) —
  `blocked_terms` gets RLS enabled with **no** policies at all, since it's
  owner-managed via the dashboard (service_role) and no API role needs any
  access to it; a generic word-filter trigger function
  (`check_blocked_terms()`, reads the target column via `TG_ARGV[0]` so
  later phases can attach it to new columns without redefining it) attached
  to `profiles.username` only; a generic `set_updated_at()` trigger attached
  to `profiles`; `complete_onboarding(p_username)` (`SECURITY INVOKER`, the
  default).
- Seed `supabase/seed/blocked_terms.sql`: 276 single-word, lowercase terms
  from the open-source LDNOOBW English list
  (github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words),
  filtered down from its full 403-entry list to just the single-word
  alphanumeric entries (dropped 124 multi-word phrases like "2 girls 1 cup"
  and 3 entries with punctuation/emoji like "g-spot" and "s&m") — the
  word-filter trigger tokenizes input on non-alphanumeric characters and
  checks whole-word membership, so a multi-word or punctuated `blocked_terms`
  row could never match anything and would just be dead data.
- pgTAP tests, `supabase/tests/` (22 assertions across 5 files, three users —
  owner, another user, a blocked user — per plan Section 11): profile write
  protection (R9: can't insert/update/delete another user's profile row);
  block visibility (R7: only the blocker can read a block row, not the
  blocked party or a third user; also covers R9 on `blocks` writes); profile
  visibility across a block (R6, at the RLS-select level on `profiles`
  directly — symmetric in both directions, uninvolved third party
  unaffected); the word filter (rejects a whole-word match case-insensitively
  on insert and on update, accepts a clean username, and specifically does
  **not** reject a term that only contains a blocked word as a substring,
  e.g. "analytics99"); `complete_onboarding` (lowercases the username, sets
  `terms_accepted_at`, and — since the function has no way to target
  another user's id by design — that the underlying RLS a user would have to
  bypass to forge someone else's profile row still blocks a direct insert
  attempt).
- Regenerated `mobile/src/lib/database.types.ts` for real via `npm run
  db:types` (Docker **was** available in this session — see below),
  replacing the Phase 0 hand-written placeholder.

Decisions / deviations:

- **Enum scoping (plan Section 6.1): deferred all five enums** (`visibility`,
  `ingredient_unit`, `report_target`, `report_reason`, `report_status`) to
  the migrations that introduce the tables that actually use them (Phase 2
  for `visibility`/`ingredient_unit`, Phase 9 for the `report_*` enums).
  None of this phase's tables (`profiles`, `blocks`, `blocked_terms`)
  reference any of them, so creating them now would just be dead schema
  sitting unused for several phases. This does mean enum definitions aren't
  all in one migration, but keeps each migration self-contained around what
  it actually needs.
- **Word-filter trigger is attached only to `profiles.username` in this
  migration**, per the task brief — the function itself
  (`check_blocked_terms()`) is written generically (target column name is a
  trigger argument, read via `to_jsonb(NEW) ->> TG_ARGV[0]`) specifically so
  that Phase 2 (`recipes.title`/`description`, `recipe_ingredients.item`/
  `note`, `recipe_steps.body`) and Phase 6 (`collections.name`) only need to
  add a `create trigger ... execute function
  public.check_blocked_terms('<column>')` in their own migrations, not touch
  this function. **Flagging for those future sessions: don't forget to wire
  that trigger up on each new word-filtered column** — nothing else will
  remind you.
- Matching algorithm for the word filter: tokenize the (lowercased) column
  value on runs of non-alphanumeric characters and check exact membership
  against `blocked_terms`, rather than building a per-term regex. This gives
  correct whole-word matching without needing to escape arbitrary terms as
  regex metacharacters (a couple of the source list's entries contain `-`
  and `&`, which would otherwise need escaping) and is a single indexed
  join instead of N regex evaluations.
- `profiles.terms_accepted_at` has **no default** — it's only ever meant to
  be set once, explicitly, at onboarding (`complete_onboarding` passes
  `now()` itself), so an implicit default felt like it would mask a caller
  forgetting to set it via any other path.
- RLS policies explicitly call `(select auth.uid())` rather than bare
  `auth.uid()` everywhere, per the plan's performance note in Section 7.
- **Docker was available in this session** (unlike Phase 0's dev sandbox
  noted in the 0.3 log entry) — `supabase start`, `supabase db reset`, and
  `supabase test db` all ran and passed for real against this migration and
  seed, more than once, including one full reset-from-scratch pass right
  before finishing. Also regenerated `mobile/src/lib/database.types.ts` for
  real (see above) — the Phase 0 placeholder is gone. `mobile/.env` still
  points at the **production** project, per the Phase 0.3 TODO that's still
  open — the owner should still point local dev at the local stack's
  URL/anon key day to day; not changed here since it's outside this story's
  scope and the production project has no tables yet regardless.
- pgTAP role-switching pattern used throughout (no external test-helper
  extension): fixtures are inserted directly by the `postgres` role (a
  superuser, so it bypasses RLS automatically) inside `auth.users` and
  `public.profiles`/`public.blocks`; assertions then run under `set local
  role authenticated; set local request.jwt.claim.sub = '<uuid>';`, which is
  exactly what `auth.uid()` reads (confirmed by reading its actual
  definition in the running local Postgres image). Deliberately did not pull
  in `basejump-supabase_test_helpers` (which needs `dbdev`/`pg_tle` and a
  network call to database.dev during `db reset`) — this keeps `db reset`
  and CI fully offline-capable.
- `npm ci` was needed in `/mobile` before `db:types`/`typecheck`/`lint`/
  `test` would run in this session — `node_modules` wasn't present in this
  worktree. `npm run typecheck`, `npm run lint`, and `npm test` all pass
  with the regenerated types in place.

What's left: stories 1.2 (Supabase Auth config & sign-in screen), 1.3
(session routing, onboarding, settings), 1.4 (terms/privacy placeholder
pages) — see the Phase 1 breakdown just added to `STORIES.md`. Did not touch
`/mobile` auth screens, sign-in, or session routing, per the task brief —
that's 1.2/1.3.

Open questions / blockers for the owner (jmyeh51@gmail.com): none new. The
Phase 0.3 TODO (point `mobile/.env` at local Supabase for day-to-day dev, and
upgrade `mint-recipe-prod` to a paid plan before beta) is still open and
still the owner's call.

### 2026-09-22 — Story 0.5: CI

Built:

- Added Jest to `/mobile`: `jest-expo` (`~57.0.5`, matching the installed
  `expo ~57.0.24`), `jest`, and `@types/jest`, all resolved via
  `npx expo install ... --dev` for SDK-compatible versions. Configured via
  the `jest` key in `mobile/package.json` (`"preset": "jest-expo"`), added
  `"jest"` to `types` in `mobile/tsconfig.json`, and added `npm test`
  (`jest --watchAll`, per Expo's own docs — GitHub Actions sets `CI=true`
  automatically, which makes Jest ignore `--watchAll` and run once, so the
  CI step passes `--watchAll=false` explicitly to be unambiguous either
  way). Added one trivial smoke test at `mobile/src/lib/smoke.test.ts`
  (`1 + 1 === 2`) purely so the CI job has something real to execute — real
  coverage starts with Phase 2's shared modules per Section 9/11 of the
  plan.
- Added `.github/workflows/ci.yml` with two jobs, triggered on every pull
  request and on push to `main`:
  - `mobile`: `actions/checkout@v4`, `actions/setup-node@v4` (Node 22, npm
    cache keyed on `mobile/package-lock.json`), `npm ci`, then
    `npm run lint`, `npm run typecheck`, `npm test -- --watchAll=false`,
    all with `working-directory: mobile`.
  - `supabase`: `actions/checkout@v4`, `supabase/setup-cli@v1`, then
    `supabase start`, `supabase db reset` (applies migrations — currently
    none, which resets cleanly to an empty schema), then a guarded pgTAP
    step (`working-directory: supabase`).
- Verified this is not an assumption: this session actually had a running
  Docker daemon (unlike the one noted in the 0.1/0.3 log entries), so I ran
  `supabase start`, `supabase db reset`, and `supabase test db` for real
  against this repo's empty `supabase/tests/` directory before writing the
  workflow. **`supabase test db` exits `1`** ("no pgTAP tests found ...")
  when there are no `.sql`/`.pg` test files — it does **not** pass
  gracefully on an empty directory, contrary to what the task brief
  hoped. So the CI step first checks
  `find tests -type f \( -name '*.sql' -o -name '*.pg' \) | grep -q .`
  and only invokes `supabase test db` when that finds a match; otherwise it
  echoes a message and exits 0. This will start running real pgTAP tests
  automatically once Phase 1 adds the first ones under `supabase/tests/` —
  no workflow change needed then. Stopped the local stack
  (`supabase stop`) afterward to leave Docker clean.
- Validated the workflow YAML with `actionlint` (downloaded the v1.7.12
  Windows binary directly since it isn't preinstalled here) — zero
  findings.
- No new secrets required: `supabase/setup-cli` and all local CLI commands
  (`start`, `db reset`, `test db`) work against the local Dockerized stack
  with no auth. Did not touch EAS or Sentry config/secrets (stories 0.2,
  0.4).

Decisions / deviations:

- Node 22 for CI (no `.nvmrc`/`engines` pin existed in `/mobile` to match;
  22 is the current LTS as of this session).
- Kept the smoke test intentionally trivial and decoupled from app code
  (no `@testing-library/react-native`, no component render) to avoid
  coupling CI setup to code that will change under Phase 2 — per the task
  brief's "don't over-build this."
- This branch started from before stories 0.4 (Sentry) and 0.2 (EAS) merged
  to `main`; merged `main` back in twice (once for each, as they landed) to
  pick them up before this PR could merge conflict-free, which is why those
  boxes below are already checked — that work is the two entries just below
  this one, not something done in this story.

What's left: nothing for Phase 0 — with this story, all five boxes above are
checked. **Phase 0 is complete** per the plan's Section 10 "done when"
criteria, modulo the on-device verification of the EAS builds still marked
pending in the 0.2 entry below (the builds themselves succeeded; installing
and booting them on an actual simulator/emulator hasn't been confirmed from
any agent session yet — no simulator/emulator has been available in this
environment). Phase 1 (Accounts and core schema) is next.

Open questions / blockers for the owner (jmyeh51@gmail.com): please confirm
the two EAS development builds from the 0.2 entry below actually install and
boot on an iOS simulator and Android emulator, to fully close out Phase 0's
"done when" criteria.

### 2026-09-22 — Story 0.2: EAS config

Built:

- Created the EAS project `@jyeh20/mobile` (project ID
  `0cfb3e98-decc-49d0-af94-de6d478d3887`) via `eas init`, linked in
  `mobile/app.json` under `expo.extra.eas.projectId` / `expo.owner`.
- Added `mobile/eas.json` with `development`, `preview`, and `production`
  build profiles (standard Expo convention). `development` sets
  `developmentClient: true`, `distribution: "internal"`, and
  `ios.simulator: true` so an iOS development build can be produced without
  an Apple Developer Program membership. `production` sets
  `autoIncrement: true`. Added an empty `submit.production` block as a
  placeholder for EAS Submit, which needs store accounts we don't have yet.
- Installed `expo-dev-client` (`npx expo install`), required for
  `developmentClient: true` builds.
- Set placeholder reverse-DNS bundle identifiers in `mobile/app.json`:
  `ios.bundleIdentifier` and `android.package` both
  `com.onetruemint.recipeapp`. **These are placeholders** — revisit once
  real Apple Developer / Google Play accounts exist and a final product
  name is chosen (see the Accounts note above; `expo.name` stays the
  `APP_NAME` placeholder per the plan, unchanged here).
- Ran both development builds via EAS Build using the Expo/EAS account
  (`eas whoami` confirmed authenticated as `jyeh20`):
  - iOS simulator build (`eas build --profile development --platform ios`):
    succeeded. Build:
    https://expo.dev/accounts/jyeh20/projects/mobile/builds/81ab76d8-ccbe-4178-9c23-f1c21a5eda4b
  - Android development build (`eas build --profile development --platform
    android`), using an EAS-managed debug keystore (no Google Play/Cloud
    account needed): succeeded. Build:
    https://expo.dev/accounts/jyeh20/projects/mobile/builds/57b186f5-1bb9-4758-8593-3a496f84e30d
  - Neither build needed an Apple Developer or Google Play/Cloud account,
    consistent with the Accounts note above.
- `npm run typecheck` and `npm run lint` pass with the new dependency and
  config in place.

Decisions / deviations:

- Both builds were originally triggered from a different local checkout of
  this repo (a sibling worktree used by the concurrent 0.3/Supabase
  session, `P:\projects\mint-recipe`) before the mixup was caught and
  reverted; `app.json`/`eas.json` in *this* worktree were then re-created
  with identical content and re-linked to the same EAS project (by
  project ID) that the builds ran under, so the committed config here
  matches exactly what actually built. The builds themselves were **not**
  re-run a second time from this worktree — re-running would hit the
  identical project with identical `app.json`/`eas.json` content, so it
  would only burn EAS build minutes without changing the result.
- **On-device verification is pending.** This environment has no iOS
  simulator or Android emulator available, so the next session (or the
  owner) should download the two builds above and confirm they install and
  boot: the iOS one via the Expo/EAS "Open in Simulator" flow, the Android
  one as an installable APK/AAB in an emulator or device. Both EAS builds
  themselves completed successfully, which is the part verifiable from
  here.
- Did not touch Supabase, Sentry, or CI config — those are stories 0.3,
  0.4, 0.5.

What's left: on-device verification of the two builds above (see
deviations); stories 0.4, 0.5.

Open questions / blockers for the owner (jmyeh51@gmail.com): none. Bundle
identifiers are placeholders as noted — flag before any real App
Store/Play Store submission if `com.onetruemint.recipeapp` isn't the final
choice.

### 2026-09-21 — Story 0.4: Sentry

Built:

- Installed `@sentry/react-native` (`npx expo install @sentry/react-native`),
  which auto-added the `@sentry/react-native` config plugin to
  `mobile/app.json`'s `plugins` array. In this SDK version that plugin
  resolves to the same code as the documented `@sentry/react-native/expo`
  entry point (`app.plugin.js` re-exports `./expo`), so both names are
  equivalent — left it as `expo install` configured it.
- Initialized Sentry in `mobile/src/app/_layout.tsx`: reads
  `EXPO_PUBLIC_SENTRY_DSN` from the environment and calls `Sentry.init({ dsn
  })` only when it's set; otherwise Sentry stays uninitialized (a no-op) so
  the app runs fine without it. Wrapped the exported root layout with
  `Sentry.wrap(...)` per Sentry's Expo docs — this is safe to call even when
  `Sentry.init` was skipped (it only adds a touch-event/profiler boundary).
- Added an `EXPO_PUBLIC_SENTRY_DSN=` (empty) line, with a comment explaining
  it's optional, to `mobile/.env.example` (which story 0.3 had already
  created for the Supabase env vars — appended rather than replacing it).
- `npm run lint` and `npm run typecheck` pass in `/mobile`.

Decisions / deviations:

- No Sentry account/project/DSN exists yet for this app. Did not add
  `project`/`organization`/`url` options to the config plugin in `app.json`
  since there is nothing real to point them at yet; the plugin works fine
  without them (source-map upload during native builds is simply skipped
  until a `SENTRY_AUTH_TOKEN` and project are configured).
- Did not touch EAS, Supabase, or CI config — those are stories 0.2, 0.3,
  0.5.

What's left: **TODO(owner): create a Sentry project and set
`EXPO_PUBLIC_SENTRY_DSN` in the real `.env` once ready.** Once that exists,
also consider adding `organization`/`project` to the `@sentry/react-native`
plugin entry in `app.json` and a `SENTRY_AUTH_TOKEN` for source-map uploads
in CI/EAS builds.

Open questions / blockers: none.

### 2026-09-21 — Story 0.3: Supabase local + prod init & type-gen

Built:

- Ran `supabase init` (CLI 2.117.0, via `npx supabase`) targeting the
  existing `/supabase` directory. It created `supabase/config.toml` and
  `supabase/.gitignore`, and left the existing `migrations/`, `seed/`,
  `functions/`, and `tests/` folders (with their `.gitkeep`s) untouched.
  Note for future sessions: `supabase init` always creates its project files
  under `<cwd>/supabase/`, so it must be run from the **repo root**, not
  from inside `/supabase` itself and not with `--workdir supabase` (both of
  those produce a nested `supabase/supabase/`).
- Set `project_id = "mint-recipe"` in `config.toml` (was defaulting to
  `"supabase"`, the directory name).
- Pointed `db.seed.sql_paths` at `./seed/*.sql` instead of the CLI's default
  `./seed.sql`, to match our existing `/supabase/seed` folder convention
  (Section 5.1 of the plan) rather than a single top-level file. No seed
  files exist yet — that's Phase 3.
- Created the production Supabase project via Supabase MCP tools: name
  `mint-recipe-prod`, org `OneTrueMint` (`exsjpitdelqwejuxscqc`), region
  `us-east-1`, project ref `dzimtfgwwejaaofqrqkl`, **free tier** (did not
  purchase/upgrade a paid plan — that's the owner's call; see TODO below).
  No tables exist in it yet; that starts in Phase 1.
- Added `mobile/.env.example` (documented, no real values) and a real,
  gitignored `mobile/.env`. `mobile/.gitignore` only ignored `.env*.local`
  before this change, which does **not** match a plain `.env` — added an
  explicit `.env` line so it's actually excluded. Verified `.env` does not
  show up in `git status` after the change.
- `mobile/.env` is currently populated with the **production** project's
  URL and anon key, not local ones — see deviation below.
- Documented environment setup and type regeneration in `mobile/README.md`
  ("Environment setup" section).
- Added `mobile/src/lib/database.types.ts` and wired
  `npm run db:types` (`mobile/package.json`) to
  `npx supabase gen types typescript --local --workdir .. > src/lib/database.types.ts`,
  runnable from `/mobile`. Verified the command resolves the project
  correctly (it reaches the "connect to Docker" step rather than erroring on
  path), consistent with the Docker blocker below.

Decisions / deviations:

- **Docker is not available in this environment**: `docker ps` / `supabase
  start` both fail with `failed to connect to the docker API at
  npipe:////./pipe/dockerDesktopLinuxEngine` — the Docker CLI is installed
  (v29.4.2) but the daemon isn't running here. Per the story instructions
  this doesn't block the rest of the story, but it does mean:
  - `supabase start` has **not** been verified end-to-end in this session.
    **TODO(next session / owner):** run `supabase start` from the repo root
    on a machine with Docker Desktop running, confirm it comes up cleanly,
    and swap the local `API URL` / `anon key` it prints into `mobile/.env`
    for day-to-day development (prod is fine for occasional use, but every
    dev hitting prod during Phase 1+ schema churn is not the intended
    workflow).
  - `mobile/src/lib/database.types.ts` is a **hand-written placeholder**
    matching the standard empty-schema shape the CLI emits for a project
    with no tables — it was not produced by actually running the
    generator (no Docker for `--local`, no CLI auth for a remote
    generation against `mint-recipe-prod`). It's marked as such in a
    top-of-file comment. Regenerate for real via `npm run db:types` once
    Docker is available, and again after every migration from Phase 1
    onward.
- `TODO(owner): upgrade mint-recipe-prod to a paid plan before beta, per plan
  Section 5.2 — free tier projects auto-pause after inactivity.` The other
  Supabase projects already in the OneTrueMint org (`Atomic Void`,
  `landing`, `macromaxer`, `Savest`) are all showing `INACTIVE` status,
  which is exactly this failure mode — a live reminder not to leave this one
  unattended once real usage starts.
- Did not touch EAS, Sentry, or CI config (stories 0.2, 0.4, 0.5). This
  worktree is shared with a concurrent session doing 0.2 — `mobile/app.json`,
  `mobile/package-lock.json`, and `mobile/eas.json` had uncommitted changes
  from that work when this session started; left them alone and did not
  stage them in this story's commit.

What's left: stories 0.2 (in progress concurrently), 0.4, 0.5. Local
Supabase verification (see TODO above) once Docker is available. Phase 1
will add the first migration, at which point `mobile/.env` and
`database.types.ts` should move to real local-dev values.

Open questions / blockers for the owner (jmyeh51@gmail.com):

- See the paid-plan TODO above — a financial decision, not made here.
- Please verify `supabase start` locally when convenient; this session
  could not confirm it due to no running Docker daemon.

### 2026-09-21 — Story 0.1: Repo & app scaffolding

Built:

- Repo layout per plan Section 5.1: `/mobile` (Expo app), `/supabase`
  (empty `migrations/`, `seed/`, `functions/`, `tests/` with `.gitkeep`
  placeholders), `/docs`.
- Moved `recipe-app-mvp-plan.md` to `/docs/recipe-app-mvp-plan.md`.
- Scaffolded `/mobile` with `create-expo-app` (SDK 57): TypeScript strict
  mode (already on in the template's `tsconfig.json`), Expo Router, ESLint
  (`eslint-config-expo` flat config), Prettier (with `eslint-config-prettier`
  to avoid rule conflicts). Left the default Expo Router template
  screens/components as-is.
- Set `app.json`'s `expo.name` to the `APP_NAME` placeholder per the plan's
  instruction not to invent a final app name. Left `slug` as `mobile` since
  it's a technical identifier, not a display name.
- Added `npm run lint`, `npm run typecheck`, `npm run format`, and
  `npm run format:check` scripts in `/mobile`.
- Created `/docs/PROGRESS.md` (this file) and `/docs/STORIES.md`.

Decisions / deviations:

- `expo-env.d.ts` is generated by the Expo CLI at dev time and is gitignored
  by the template. Since `npm run typecheck` needs it to exist, added a
  `pretypecheck` script (`scripts/generate-expo-env.js`) that writes the same
  static content Expo's CLI would write, only if the file is missing. This
  keeps the file out of git (matching upstream convention) while keeping
  typecheck reproducible on a fresh checkout or in CI.
- The template's `src/hooks/use-color-scheme.web.ts` triggered an
  `eslint-plugin-react-hooks` `set-state-in-effect` error on its hydration
  flag pattern (a standard SSR-hydration technique). Added a targeted
  `eslint-disable-next-line` with a comment explaining why, rather than
  restructuring template code that later phases will likely touch anyway.
- Did not add EAS, Supabase, Sentry, or CI config — those are stories 0.2,
  0.3, 0.4, and 0.5.

What's left: stories 0.2–0.5 (see `STORIES.md`), then Phase 1 (Accounts and
core schema).

Open questions / blockers: none. Apple Developer and Google Play/Cloud OAuth
accounts are still pending on the owner's side — noted above so future
sessions stub around them instead of blocking.
