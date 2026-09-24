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
- [x] 1.2 — Supabase Auth config & sign-in screen
- [ ] 1.3 — Session routing, onboarding, settings
- [x] 1.4 — Terms and privacy placeholder pages

See `STORIES.md` for the full breakdown of each story.

## Log

### 2026-09-24 — Story 1.4 follow-up: live-URL verification

PR #7 merged to `main`. The `Deploy legal pages` GitHub Actions workflow
ran automatically on that merge and completed successfully. Verified both
URLs are actually live:

- `curl -I https://onetruemint.github.io/otm-recipe/terms.html` → `200 OK`
- `curl -I https://onetruemint.github.io/otm-recipe/privacy.html` → `200 OK`

This closes the "TODO(owner or next session)" left in the 1.4 entry below —
no further action needed on Pages for this story.

### 2026-09-23 — Story 1.2: Supabase Auth config & sign-in screen

Built everything that can be built without a real Apple Developer or Google
Cloud OAuth account, per the Accounts note above, so the only remaining work
once the owner has those accounts is filling in config values — no code
changes.

- `mobile/src/lib/supabase.ts`: the shared Supabase client, per plan Section
  5's tech stack row. `createClient<Database>(...)` from
  `EXPO_PUBLIC_SUPABASE_URL`/`EXPO_PUBLIC_SUPABASE_ANON_KEY`, typed against
  `database.types.ts` (now the real generated types, since story 1.1's
  migration landed on `main` before this session started). Session storage
  is AsyncStorage-backed (`@react-native-async-storage/async-storage`) with
  `autoRefreshToken: true`, `persistSession: true`, `detectSessionInUrl:
  false`, plus the `AppState`-driven `startAutoRefresh`/`stopAutoRefresh`
  toggle Supabase's React Native guide recommends (RN has no window-focus
  event to drive the refresh timer otherwise). Throws at import time if the
  env vars are missing — intentional, since Supabase credentials are
  assumed already configured per the Accounts note (unlike the Google/Apple
  pieces below, which degrade gracefully instead). Exports just `supabase`,
  per the task's ask to keep the interface simple for story 1.3 to reuse.
- `mobile/src/lib/auth.ts`: `signInWithApple()` and `signInWithGoogle()`.
  Both get a native ID token from the platform SDK
  (`expo-apple-authentication` / `@react-native-google-signin/google-signin`)
  and call `supabase.auth.signInWithIdToken({ provider, token })`. Each
  returns a `SignInResult` (`{status: 'ok' | 'cancelled' | 'error', message?}`)
  instead of throwing, so the caller never has to distinguish "user
  cancelled" from "real failure" — cancellation is silent, everything else
  surfaces `message`. Apple cancellation is detected via the
  `ERR_REQUEST_CANCELED` rejection code documented by
  `expo-apple-authentication`; Google cancellation comes back as a `{type:
  'cancelled'}` response object from `GoogleSignin.signIn()` in this SDK
  version (not a thrown error, which older docs/examples suggest — verified
  against the installed package's own `.d.ts` files, since AGENTS.md warns
  Expo/RN APIs move fast and not to trust training data). `signInWithGoogle`
  short-circuits with a "not configured" error, without touching the native
  SDK at all, when `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` is empty — this is the
  "fails gracefully" behavior the task asked to verify, and it's covered by
  a test (see below). Apple only shares the user's name on their very first
  sign-in, so `signInWithApple` opportunistically saves it via
  `supabase.auth.updateUser` when present.
- `mobile/src/app/sign-in.tsx`: Apple button (iOS only, via
  `expo-apple-authentication`'s native `AppleAuthenticationButton`) and
  Google button (`GoogleSigninButton`, both platforms), each wired to the
  helpers above. Shows an inline error message (no crash) on failure;
  clears it on the next attempt. Links to the terms and privacy pages using
  the exact URLs story 1.4 published
  (`https://onetruemint.github.io/otm-recipe/terms.html` /
  `.../privacy.html`) — this session started after 1.4 merged to `main`, so
  these are the real URLs, not placeholders (the task brief anticipated
  this might still be in flight and suggested placeholders of the same
  shape, which turned out to match exactly). Not wired into any navigator —
  session-based routing (deciding when a signed-out user actually lands
  here) is story 1.3's job, per the task brief's explicit instruction not
  to touch that.
- Packages added via `npx expo install`: `@supabase/supabase-js`,
  `@react-native-async-storage/async-storage`, `react-native-url-polyfill`
  (Supabase's documented RN dependency for `URL`/`structuredClone` gaps),
  `expo-apple-authentication`, `@react-native-google-signin/google-signin`.
  `expo install` auto-added the `@react-native-google-signin/google-signin`
  config plugin to `app.json`; added `expo-apple-authentication` to the
  plugins array and `ios.usesAppleSignIn: true` by hand (Expo's install
  step didn't add either automatically).
- `mobile/.env.example`: added `EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID` and
  `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID`, both empty, each with a comment on
  where to get the value and a `TODO(owner): needs Google Cloud OAuth`
  marker, plus a `TODO(owner): needs Apple Developer account` marker
  documenting that Apple sign-in on Android needs a Services ID and
  redirect URL configured directly in the Supabase dashboard (not an env
  var — there's no code-side client ID for that flow). Updated
  `mobile/README.md`'s "Environment setup" section to match.
- Tests: `mobile/src/lib/auth.test.ts` (5 cases) covers the two behaviors
  the task asked to verify without real credentials — cancellation
  handled silently for both providers, and Google's "not configured"
  path never touches the native SDK — plus the success path for each
  provider, with `expo-apple-authentication`, `@react-native-google-signin/
  google-signin`, and `@/lib/supabase` all mocked. Each test reloads the
  module registry (`jest.resetModules()`) because `auth.ts` reads its
  Google env vars once at module load time, so exercising both the
  "configured" and "not configured" states needs fresh module instances
  per test, not just a changed `process.env`.
  `mobile/src/app/sign-in.test.tsx` (2 cases, `react-test-renderer`)
  confirms the screen renders without crashing and that a failed
  Google sign-in surfaces the inline error text instead of throwing.
  Getting these green required two small, pre-existing-gap fixes
  unrelated to this story's logic but necessary to run any component
  test at all: `mobile/node_modules` didn't exist yet in this worktree
  (this is apparently the first session to run a full `npm ci` here —
  ran it before installing anything new), and Jest had no
  `moduleNameMapper` for `.css` imports (`src/constants/theme.ts` imports
  `src/global.css` for the web build), so any test that transitively
  imported `theme.ts` — which is most of the component tree, via
  `themed-text`/`themed-view` — failed on a CSS parse error. Added
  `mobile/scripts/jest-css-stub.js` and a `moduleNameMapper` entry in
  `package.json`'s `jest` config to stub `.css` imports to `{}` in tests.
- `npm run lint`, `npm run typecheck`, and `npm test -- --watchAll=false`
  all pass. `npm run format:check` currently flags nearly every file in
  `/mobile`, including ones untouched by this session (e.g. `README.md`,
  `_layout.tsx`) — pre-existing, not something introduced here, and not
  part of the CI gate in `ci.yml` (which only runs lint/typecheck/test),
  so left alone rather than reformatting the whole tree in an auth PR.

Decisions / deviations:

- This branch started 6 commits behind `main`; both story 1.1 (db
  migration — merged as PR #6) and story 1.4 (terms/privacy pages — merged
  as PR #7) had landed by the time this session started. Fast-forward
  merged `main` in before opening a PR, per the task brief's instruction.
  No conflicts — 1.1 only touched `database.types.ts` on the mobile side
  (regenerated with the real `profiles` table), which this story's
  `supabase.ts` now imports the benefit of.
- Did not attempt a real end-to-end sign-in — no real Apple Developer or
  Google Cloud OAuth credentials exist in this environment, per the
  Accounts note. Verified instead via typecheck, lint, and the two test
  files above, plus manual reasoning about the "not configured" and
  cancellation code paths.
- `GoogleSignin.configure()` is called lazily, on first `signInWithGoogle()`
  call, not at module load — avoids doing native setup work for a button
  the user may never press, and avoids configuring with an empty
  `webClientId` before we've even checked whether one exists.
- Left `@react-native-google-signin/google-signin`'s `iosUrlScheme` plugin
  option unset in `app.json` — that value is the *reversed* iOS OAuth
  client ID (e.g. `com.googleusercontent.apps.XXXX`), a separate value
  from the client ID itself, needed only for the native URL-scheme
  redirect. There's no real iOS client ID yet to reverse, and `app.json` is
  static (no `app.config.js` in this repo, so it can't be derived from an
  env var at build time either). **TODO(owner or next session): once a
  real Google Cloud iOS OAuth client ID exists, add its reversed form as
  `iosUrlScheme` to the `@react-native-google-signin/google-signin` plugin
  entry in `mobile/app.json`** — see the library's Expo setup docs.

What's left — itemized, everything below needs a real credential or
dashboard action only the owner can take:

1. **Google Cloud OAuth**: create iOS and Web OAuth client IDs in Google
   Cloud Console, set `EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID` and
   `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` in the real `.env`, and add the
   reversed iOS client ID as `iosUrlScheme` in `app.json` (see deviation
   above). Once these three things are done, Google sign-in should work
   with no code changes.
2. **Apple Developer Program membership**: needed for the
   `usesAppleSignIn` capability to actually work in a real (non-simulator)
   build, and for Sign in with Apple on Android — which per plan Section 5
   goes through Supabase's OAuth browser flow, not this session's native
   code path at all. That needs an Apple Services ID and a redirect URL
   configured directly in Authentication → Providers → Apple in the
   Supabase dashboard; nothing to wire up in the app itself for that part.
3. Once both of the above exist, a development build (`eas build --profile
   development`) is needed to actually test either flow — neither
   `expo-apple-authentication` nor `@react-native-google-signin/
   google-signin` works in Expo Go, since both ship native code.
4. Story 1.3 (session routing, onboarding, settings) is next — it decides
   when a signed-out user actually lands on this sign-in screen, which
   this story intentionally left undone.

Open questions / blockers for the owner (jmyeh51@gmail.com): none blocking
further work — this story is complete modulo the real credentials itemized
above, which only the owner can supply.

### 2026-09-23 — Story 1.4: Terms and privacy placeholder pages

Built:

- Added `/legal/terms.html` and `/legal/privacy.html`: plain static HTML
  (shared `/legal/style.css`, no build step, no framework), each for
  `APP_NAME` per the plan's placeholder-name convention. Both carry a
  visible draft banner: "Draft placeholder — not final. Real terms,
  including required content-moderation clauses, are written before public
  launch (see project plan Phase 10)." `terms.html` covers user-generated
  content, no warranty, and a contact-email placeholder. `privacy.html`
  covers what's collected (account info from Apple/Google sign-in,
  username, avatar, recipe content and photos) and that in-app account
  deletion removes it.
- Put these under a new top-level `/legal` directory (not `/docs`, which is
  internal project docs).
- Enabled GitHub Pages for `onetruemint/otm-recipe` via `gh api
  repos/onetruemint/otm-recipe/pages -X POST -f build_type=workflow`.
  GitHub Pages' branch-source mode only supports serving from repo root or
  `/docs`, not an arbitrary folder like `/legal`, so used Pages' newer
  "workflow" build type instead: added
  `.github/workflows/pages.yml`, which runs `actions/configure-pages`,
  `actions/upload-pages-artifact` (`path: legal`), and
  `actions/deploy-pages` on every push to `main` that touches `legal/**`
  (plus `workflow_dispatch` for manual runs).
- **Final URLs** (site root serves the contents of `/legal`, so no
  `/legal/` path segment):
  - Terms: `https://onetruemint.github.io/otm-recipe/terms.html`
  - Privacy: `https://onetruemint.github.io/otm-recipe/privacy.html`
  - These are stable now — story 1.2's sign-in screen and later Settings
    can link to them regardless of merge order.

Decisions / deviations:

- **Live verification is pending merge to `main`.** GitHub's
  `workflow_dispatch` API refuses to run a workflow that isn't yet present
  on the repository's default branch (`gh workflow run pages.yml --ref
  <this-branch>` failed with "workflow pages.yml not found on the default
  branch"), and the `push` trigger is also scoped to `main`. So the
  deploy-pages workflow has not run yet and the URLs above are not live as
  of this commit — they will build automatically on the first merge of
  `legal/**` or `.github/workflows/pages.yml` into `main`. Per the task
  brief's guidance not to block on things outside this session's control,
  documenting this rather than stopping.
- Used `gh api ... -f build_type=workflow` rather than the Pages UI/CLI
  wizard (which defaults to branch-source mode and would have forced a
  `gh-pages` branch or root/`/docs` restriction) — this was the more direct
  path to serving `/legal` specifically, per the task's own suggestion to
  fall back to a `gh-pages`-style Actions workflow if a plain folder source
  isn't supported.
- The concurrent 1.1 session (database migration & RLS) independently added
  the same "Phase 1 status" section while this story was in flight, with
  slightly different story numbering/scope (1.1–1.4, no separate 1.5 for
  Settings). Reconciled on merge to their numbering — it's already the one
  live on `main` — and just checked 1.4.

What's left: **TODO(owner or next session): after this PR merges to
`main`, confirm the Pages deploy workflow ran (Actions tab) and `curl -I`
both URLs above to confirm they're live (200, not 404).** Phase 10
replaces these with final, lawyer-reviewed terms/privacy before public
launch, per the plan.

Open questions / blockers for the owner (jmyeh51@gmail.com): none blocking
— just the post-merge live-URL confirmation above.

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
