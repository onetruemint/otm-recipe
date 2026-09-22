# Recipe App — MVP Build Plan

Handoff document for developer agents. The app name is not decided. Use `APP_NAME` as a placeholder in code and copy.

## 0. How to use this document

1. Build the phases in Section 10 in order. Each phase ends with a working app on both iOS and Android.
2. A phase is done only when every acceptance criterion passes on both platforms.
3. Decisions in Section 13 are final for the MVP. Do not reopen them. If one blocks you, flag it to the owner.
4. Anything in Section 14 (Future Ideas) is out of scope. Where the MVP design must leave room for a future idea, this document says so.

---

## 1. Problem

Recipe websites bury the recipe under pages of story. People want the photo, the ingredients, and the steps.

## 2. Solution

A Pinterest-style social app for recipes. A recipe is a photo, a list of ingredients, and numbered steps. Users scroll a wall of everyone's public recipes, post their own, like recipes, and organize recipes into collections.

---

## 3. MVP scope

1. **Accounts.** Sign in with Apple or Google. Choose a username and accept the terms at onboarding. Delete the account inside the app. Sign-in is required to use the app.
2. **Recipes.** Create, view, edit, delete. Each recipe is public or private.
3. **Photos.** Take a photo in the app or pick one from the library.
4. **The wall.** All users' public recipes, newest first, infinite scroll, staggered columns.
5. **Likes.** Like a recipe. View your own liked recipes.
6. **Collections.** Save recipes into user-made collections. Each collection is public or private.
7. **Profiles.** Username, avatar, a Recipes tab, and a Collections tab.
8. **Search.** Recipes by text. Users by username.
9. **Sharing.** Plain text through the phone's share sheet.
10. **Moderation.** Report, block, word filter, owner review in the database dashboard.

Platforms: iOS and Android, launched together. No web app.

### 3.1 Recipe fields

| Field | Required | Rules |
|---|---|---|
| Image | Yes | Exactly one. Aspect ratio clamped between 3:2 (landscape) and 2:3 (portrait). |
| Title | No | Max 100 characters. When empty, the app shows "Recipe by @username" wherever text is needed. |
| Description | No | Max 2,000 characters. |
| Ingredients | Yes, at least 1 | Max 50 rows. Ordered. Each row: quantity (optional), unit (optional), item (required, max 100 chars), note (optional, max 100 chars). |
| Steps | Yes, at least 1 | Max 50. Ordered. Each max 1,000 characters. |
| Servings | No | Integer 1–100. Shown under a collapsed "More details" section. |
| Total time | No | Minutes, 1–10,080. Shown under "More details". Displayed like "1 h 15 min". |
| Visibility | Yes | `public` (default) or `private`. |

Ingredients display as bullets. Steps display as numbers. Both keep the order the author entered.

### 3.2 Units

Fixed list, stored as codes: `tsp`, `tbsp`, `cup`, `fl_oz`, `pint`, `quart`, `gallon`, `ml`, `l`, `g`, `kg`, `oz`, `lb`, `pinch`, `dash`, `clove`, `slice`, `can`, `stick`, `bunch`, `package`.

Countable items with no unit (for example "3 eggs") leave unit empty. "Salt to taste" leaves quantity and unit empty and puts "to taste" in the note.

---

## 4. User stories

### Accounts
1. As a new user, I want to sign in with Apple or Google, so that I don't manage another password.
2. As an iPhone user who moves to Android, I want Sign in with Apple on Android too, so that I keep my account.
3. As a new user, I want to pick a unique username, so that people can see who posted a recipe and find me.
4. As a new user, I want to read and accept the terms before I see content, so that I know the rules.
5. As a user, I want to change my username, so that I can fix a choice I regret.
6. As a user, I want to add or change an avatar, so that my profile is recognizable.
7. As a user, I want to sign out.
8. As a user, I want to delete my account and all my content inside the app, so that I control my data.
9. As a user, I want a support contact in settings, so that I can reach the owner.

### Recipes
10. As a user, I want to take a photo in the app or pick one from my library, so that posting is quick.
11. As a user, I want photos that are too wide or too tall cropped automatically with a preview, so that the wall stays tidy.
12. As a user, I want my photo's location data removed before upload, so that I don't reveal where I live.
13. As a user, I want to enter ingredients as rows of quantity, unit, item, and note, so that recipes are clear and consistent.
14. As a user, I want to type quantities like "1/2", "1 1/2", or "0.5", so that I can enter them the way recipes are written.
15. As a user, I want to add, remove, and reorder ingredients and steps, so that the recipe reads in the right order.
16. As a user, I want title and description to be optional, so that posting is fast.
17. As a power user, I want servings and total time under "More details", so that the main form stays short.
18. As a user, I want to make a recipe public or private, so that I can keep drafts and family recipes to myself.
19. As a user, I want to edit my recipe, so that I can fix mistakes. Everyone who saved it sees the update.
20. As a user, I want to delete my recipe.

### The wall
21. As a user, I want a wall of public recipes that keeps loading as I scroll, so that I can browse without waiting.
22. As a user, I want wall cards to show only the photo, so that the wall feels calm.
23. As a user, I want to pull to refresh, so that I see new recipes.
24. As a user, I want to tap a recipe and see its ingredients and steps immediately, with no story.

### Likes
25. As a user, I want to like a recipe with one tap.
26. As a user, I want to see a recipe's like count on its page.
27. As a user, I want a private list of the recipes I liked.

### Collections
28. As a user, I want to save a recipe to one or more collections from a bottom sheet.
29. As a user, I want to create a new collection from that sheet.
30. As a user, I want new collections to be private by default, so that nothing goes public by accident.
31. As a user, I want to rename, delete, and change the visibility of my collections.
32. As a user, I want to remove a recipe from a collection.
33. As a visitor, I want to open someone's public collection as its own wall.

### Profiles
34. As a user, I want to view anyone's profile with their public recipes and public collections.
35. As a user, I want to see my own private recipes and collections on my profile, marked with a lock.
36. As a user, I want to reach my liked recipes from my profile.

### Search
37. As a user, I want to search recipes by words in the title, description, or ingredients, so that I can find something to cook with what I have.
38. As a user, I want to search users by username.

### Sharing
39. As a user, I want to share a recipe as plain text through any messaging app, so that a friend gets it without the app.

### Moderation
40. As a user, I want to report a recipe or a user and pick a reason.
41. As a user, I want to block a user so that neither of us sees the other's content.
42. As a user, I want to see the users I blocked and unblock them.
43. As a user, I want offensive words rejected when anyone posts, so that the app stays clean.
44. As the owner, I want to review reports and remove content in the database dashboard, without an admin app.

---

## 5. Tech stack

| Area | Choice |
|---|---|
| Mobile | Expo (React Native), TypeScript strict mode, Expo Router |
| Builds | EAS Build with development builds (not Expo Go, because Google Sign-In needs a native module), EAS Submit |
| Server data | TanStack Query (`useInfiniteQuery` for every wall) |
| Staggered columns | FlashList masonry layout |
| Images | `expo-image-picker` (camera and library), `expo-image-manipulator` (crop, resize, re-encode), `expo-image` (display and caching) |
| Sign-in | Supabase Auth with native ID tokens: `expo-apple-authentication` on iOS, `@react-native-google-signin/google-signin` on both platforms. Apple on Android uses Supabase's OAuth browser flow. |
| Backend | Supabase: Postgres, row-level security (RLS), Storage, Edge Functions |
| Search | Postgres full-text search, plus `pg_trgm` for usernames |
| Session storage | AsyncStorage, per Supabase's React Native guidance |
| DB types | Generated with the Supabase CLI and committed |
| Tests | Jest for app modules, pgTAP via `supabase test db` for database rules |
| CI | GitHub Actions |
| Crash reporting | Sentry (Expo integration) |
| Legal pages | Terms and privacy policy as static pages on any static host. This is not a web app. |

There is no custom API server. The app talks to Supabase directly. All permission rules live in the database (Section 7).

### 5.1 Repo layout

```
/mobile     Expo app
/supabase   migrations, seed data, Edge Functions, pgTAP tests
/docs       this plan, moderation runbook, decisions
```

### 5.2 Environments

1. **Local:** Supabase CLI (Docker) for development and tests.
2. **Production:** one hosted Supabase project on a paid plan, so it never pauses and has backups.
3. The closed beta runs on production. Recipes posted in the beta become the launch content.
4. Every migration runs locally with `supabase db reset` and passes pgTAP before `supabase db push` to production.

---

## 6. Data model

### 6.1 Enums

| Enum | Values | Note |
|---|---|---|
| `visibility` | `public`, `private` | Future `followers` value is added with `ALTER TYPE ... ADD VALUE`. Do not use a boolean. |
| `ingredient_unit` | codes from Section 3.2 | |
| `report_target` | `recipe`, `user` | |
| `report_reason` | `spam`, `inappropriate`, `harassment`, `not_a_recipe`, `other` | |
| `report_status` | `open`, `actioned`, `dismissed` | |

### 6.2 Tables

**profiles**

| Column | Type | Rules |
|---|---|---|
| id | uuid PK | Equals `auth.users.id`. On delete cascade. |
| username | text, unique | Matches `^[a-z0-9._]{3,30}$`. App lowercases input. |
| avatar_path | text, null | Path in `avatars` bucket |
| terms_accepted_at | timestamptz, not null | Set at onboarding |
| created_at, updated_at | timestamptz | |

**recipes**

| Column | Type | Rules |
|---|---|---|
| id | uuid PK | |
| author_id | uuid FK → profiles | On delete cascade |
| title | text, null | Max 100 |
| description | text, null | Max 2,000 |
| image_full_path | text, not null | |
| image_thumb_path | text, not null | |
| image_width, image_height | int, not null | Dimensions of the full image. Width/height between 2/3 and 3/2, with 1% tolerance for rounding. |
| servings | int, null | 1–100 |
| total_time_minutes | int, null | 1–10,080 |
| visibility | visibility, default `public` | |
| like_count | int, default 0 | Maintained by trigger |
| search_vector | tsvector | Set by `save_recipe` |
| created_at, updated_at | timestamptz | |

Indexes: `(created_at desc, id desc) where visibility = 'public'`; `(author_id, created_at desc)`; GIN on `search_vector`.

**recipe_ingredients**

| Column | Type | Rules |
|---|---|---|
| id | uuid PK | |
| recipe_id | uuid FK → recipes | On delete cascade |
| position | int | Unique per recipe, starting at 0 |
| quantity | numeric(10,3), null | Greater than 0 |
| unit | ingredient_unit, null | |
| item | text, not null | 1–100 chars |
| note | text, null | Max 100 |

**recipe_steps**

| Column | Type | Rules |
|---|---|---|
| id | uuid PK | |
| recipe_id | uuid FK → recipes | On delete cascade |
| position | int | Unique per recipe, starting at 0 |
| body | text, not null | 1–1,000 chars |

**likes**: `user_id` (FK profiles, cascade), `recipe_id` (FK recipes, cascade), `created_at`. PK `(user_id, recipe_id)`. Index `(user_id, created_at desc)`.

**collections**: `id`, `owner_id` (FK profiles, cascade), `name` (1–60 chars, unique per owner ignoring case), `visibility` (default `private`), `created_at`, `updated_at`.

**collection_items**: `collection_id` (FK, cascade), `recipe_id` (FK, cascade), `added_at`. PK `(collection_id, recipe_id)`. Index `(collection_id, added_at desc)`.

**blocks**: `blocker_id`, `blocked_id` (both FK profiles, cascade), `created_at`. PK `(blocker_id, blocked_id)`. Check `blocker_id <> blocked_id`.

**reports**: `id`, `reporter_id` (FK profiles, on delete set null), `target_type`, `target_id` (uuid, no FK), `reason`, `details` (text, max 500, null), `status` (default `open`), `created_at`. Unique `(reporter_id, target_type, target_id)`.

**blocked_terms**: `term` (text PK, lowercase). Seeded from an open-source list of offensive words. Managed by the owner in the dashboard.

### 6.3 Storage

| Bucket | Read | Path | Write |
|---|---|---|---|
| `recipe-images` | Public | `{user_id}/{recipe_id}/{uuid}-full.jpg` and `-thumb.jpg` | Only inside the caller's own `{user_id}/` folder |
| `avatars` | Public | `{user_id}/{uuid}.jpg` | Only inside the caller's own folder |

Paths contain random UUIDs and buckets are not listable. A private recipe's image is reachable only by someone who has its exact URL. This is an accepted MVP trade-off (Section 13).

### 6.4 Database functions

All functions are `SECURITY INVOKER` so RLS applies, unless marked otherwise.

| Function | Purpose |
|---|---|
| `is_blocked_between(a, b)` | `SECURITY DEFINER`, stable. True if either user blocked the other. |
| `can_view_recipe(author_id, visibility)` | True if the caller is the author, or the recipe is public and no block exists. |
| `complete_onboarding(username)` | Creates the caller's profile with `terms_accepted_at = now()`. |
| `save_recipe(payload jsonb) → uuid` | Creates or updates a recipe, replaces its ingredients and steps, and recomputes `search_vector`, in one transaction. Caller must be the author. Validates every limit in Section 3.1. |
| `get_wall(before_created_at, before_id, limit = 24)` | Public recipes, newest first, keyset pagination on `(created_at, id)`. Returns id, thumb path, width, height, created_at. |
| `get_user_recipes(user_id, cursor, limit)` | A user's recipes. RLS returns private ones only to the owner. |
| `get_user_collections(user_id)` | Collections the caller may see, each with a cover: the thumbnail of the most recently added recipe the caller may see. |
| `get_collection_recipes(collection_id, cursor, limit)` | Newest-saved first, keyset on `(added_at, recipe_id)`. |
| `get_liked_recipes(cursor, limit)` | Caller's likes, newest first. |
| `search_recipes(query, offset, limit)` | Full-text search. Each word matches as a prefix. English stemming. Ordered by rank, then newest. Offset pagination, max 200 results. |
| `search_users(query, limit)` | Username prefix match, then trigram similarity. Excludes blocked users. |

`search_vector` weights: title A, ingredient items B, description C. Config `english`.

### 6.5 Triggers

1. **Like count:** on insert or delete in `likes`, update `recipes.like_count`. `SECURITY DEFINER`.
2. **updated_at:** on every table that has the column.
3. **Word filter:** on insert or update of `profiles.username`, `recipes.title`, `recipes.description`, `recipe_ingredients.item`, `recipe_ingredients.note`, `recipe_steps.body`, `collections.name`. Whole-word, case-insensitive match against `blocked_terms`. Raises an error with message `blocked_term`. The app shows "Please remove inappropriate language."

### 6.6 Edge Functions

**delete-account:** called by the signed-in user. Removes all of that user's files from both buckets, then deletes the auth user. Cascades remove the profile, recipes, ingredients, steps, likes, collections, collection items, and blocks. Reports they filed stay, with `reporter_id` set to null.

---

## 7. Visibility and permission rules

These rules are enforced in RLS and database functions. App code may hide things for UX, but must never be the only check.

- **R1.** A recipe is visible to a viewer if the viewer is the author, or the recipe is public and no block exists between viewer and author in either direction.
- **R2.** Ingredients and steps are visible only if their recipe is visible.
- **R3.** A collection is visible if the viewer is the owner, or it is public and no block exists between viewer and owner.
- **R4.** A collection only shows recipes visible under R1. When a recipe becomes private or is deleted, it disappears from other users' collections and liked lists. If a private recipe becomes public again, it reappears. No copies are ever stored.
- **R5.** A liked list is visible only to its owner. Like counts are public, shown on the recipe page only.
- **R6.** Profiles are visible to everyone except across a block. A blocked profile shows "This account isn't available."
- **R7.** Blocks are visible only to the blocker. The blocked user is not notified.
- **R8.** Users can create reports but cannot read any reports. The owner reviews them in the dashboard.
- **R9.** Users can only write their own rows and their own storage folder.
- **R10.** Users can only like or save recipes they can see.
- **R11.** Walls, search, and profiles return only rows allowed by R1–R6.

Performance: in policies, call `(select auth.uid())` rather than `auth.uid()`, and index every column a policy filters on.

---

## 8. Screens and navigation

Expo Router. Signed-out users see Sign in. Signed-in users without a profile see Onboarding. Everyone else sees four tabs: **Wall**, **Search**, **Create**, **Profile**.

1. **Sign in:** Apple button, Google button, links to terms and privacy policy.
2. **Onboarding:** username field with format hint and live availability check; terms checkbox with links; Continue.
3. **Wall (tab):** two staggered columns of image-only cards, infinite scroll, pull to refresh, empty and error states.
4. **Recipe detail:** full image; title if set; author row (avatar, @username, taps to profile); action row with like button and count, Save, Share, and a ⋯ menu; description; "Serves 4 · 1 h 15 min" when set; Ingredients as bullets; Steps as numbers.
   - ⋯ on your own recipe: Edit, Make private / Make public, Delete.
   - ⋯ on someone else's: Report recipe, Report user, Block user.
5. **Create / Edit recipe (Create tab):** image area (choose Camera or Library, then crop preview); title; description; ingredient rows (add, remove, drag to reorder); steps (same); collapsed "More details" with servings and total time; visibility toggle; Save. Inline validation. Warn about unsaved changes on back.
6. **Save sheet (bottom sheet):** "New collection" at top, with inline name field. Below it, the user's collections with check marks. Tapping a collection adds or removes the recipe.
7. **Profile:** avatar, username, tabs **Recipes** and **Collections**.
   - Own profile: settings gear, "Liked" entry, lock icons on private items.
   - Other profiles: ⋯ with Report user and Block user.
   - Collections tab: grid of cards with cover, name, and a lock if private.
8. **Collection:** name header, wall of its recipes. Owner's ⋯: Rename, Make public / Make private, Delete. Recipes are removed through the Save sheet.
9. **Liked recipes:** wall of liked recipes.
10. **Search (tab):** text field, tabs **Recipes** and **Users**. Recipe results use the wall layout. User results are a list of avatar and username.
11. **Settings:** Edit profile (username, avatar), Blocked users (list with Unblock), Terms, Privacy policy, Contact support (email link), Sign out, Delete account (two-step confirmation).
12. **Report sheet:** list of reasons, optional details, Submit. Confirmation: "Thanks. We'll review this."

**One wall component.** The Wall, a profile's Recipes tab, a Collection, Liked recipes, and Search results all use the same `RecipeWall` component with a different data source.

---

## 9. Shared modules

Build these as self-contained modules with small interfaces. Each gets its own tests.

1. **Image pipeline.** `prepareRecipeImage(uri) → { fullUri, thumbUri, width, height }`.
   - Apply the photo's orientation.
   - Clamp ratio: with `r = width / height`, if `r > 3/2`, center-crop width to `height × 3/2`; if `r < 2/3`, center-crop height to `width × 3/2`.
   - Full: longest edge 1,600 px, JPEG quality 0.8. Thumb: width 600 px, JPEG quality 0.7.
   - Re-encoding strips all metadata, including GPS. Verify this in a test with a geotagged photo.
   - `prepareAvatar(uri)`: center square, 512 px, same stripping.
2. **Quantities.** Parse `"1/2"`, `"1 1/2"`, `"1½"`, `"0.5"` into numbers. Format numbers as the nearest common fraction (⅛, ¼, ⅓, ½, ⅔, ¾) when close, otherwise up to two decimals. Pluralize units that need it (cup → cups, clove → cloves).
3. **Time formatting.** Minutes → "45 min", "1 h", "1 h 15 min".
4. **Share text.** Recipe → plain text: title (or "Recipe by @username"), servings and time if set, ingredients as "- " lines, numbered steps, then "Shared from APP_NAME".
5. **Recipe validation.** One set of limits used by the form, matching the database checks exactly.
6. **Error mapping.** Database errors → user messages: blocked term, username taken, limit exceeded, not allowed.
7. **RecipeWall + useInfiniteRecipes.** A masonry list that takes any paginated data source. Cards are sized from stored width and height so the layout never jumps while images load. Prefetches the next page before the user reaches the end.
8. **Permission rules (database).** RLS policies and helper functions from Section 7.

---

## 10. Build phases

Each phase ends with a working app on iOS and Android. Every migration includes its RLS policies and pgTAP tests in the same change.

### Phase 0 — Foundations

1. Create the repo with `/mobile`, `/supabase`, `/docs`. Add this plan to `/docs`.
2. Create the Expo app: TypeScript strict, Expo Router, ESLint, Prettier.
3. Configure EAS: bundle identifiers, development builds for iOS and Android, `APP_NAME` placeholder.
4. Initialize local Supabase with the CLI. Create the production project on a paid plan. Store URL and anon key per environment.
5. Add a script that generates database types into `/mobile`.
6. Add Sentry.
7. CI on every pull request: lint, typecheck, Jest, `supabase test db`.

**Done when:** a development build runs on an iOS simulator and an Android emulator; local Supabase starts; CI passes.

### Phase 1 — Accounts and core schema

1. Migration: all enums, `profiles`, `blocks`, `blocked_terms`, `is_blocked_between`, RLS for R6, R7, R9. Seed `blocked_terms`.
2. Word-filter trigger function, attached to `profiles.username`.
3. Configure Supabase Auth: Apple (native on iOS, OAuth browser flow on Android) and Google (iOS, Android, and web client IDs).
4. Sign-in screen using `signInWithIdToken` for native tokens.
5. Session persistence and routing: signed out → Sign in; no profile → Onboarding; otherwise tabs.
6. Onboarding screen and `complete_onboarding`.
7. Publish placeholder terms and privacy pages and link them.
8. Temporary settings screen with Sign out.

**Done when:**
- A new user signs in with Apple and with Google on both platforms, picks a username, and lands on the tabs.
- Relaunching the app keeps the session.
- Taken, badly formatted, and offensive usernames are rejected with clear messages.
- pgTAP: a user cannot write another user's profile; blocks are readable only by the blocker.

### Phase 2 — Create and view recipes

1. Migration: `recipes`, `recipe_ingredients`, `recipe_steps`, `can_view_recipe`, `save_recipe`, word-filter triggers, RLS for R1, R2, R9.
2. `recipe-images` bucket with folder policies.
3. Image pipeline, quantities, time formatting, validation, and error mapping modules, with tests.
4. Create screen: camera and library (with permission text on iOS), crop preview, all fields, row editors with reorder, "More details", visibility.
5. Save flow: prepare images → upload full and thumb → `save_recipe`. Show progress. If the save fails, delete the uploaded files.
6. Recipe detail screen with all sections and the title fallback.
7. Edit: prefilled form. A new image uploads new files, saves, then deletes the old files.
8. Delete (with confirmation): delete the row, then the files. Visibility toggle from the ⋯ menu.

**Done when:**
- Recipes can be created from camera and library on both platforms.
- A 4:1 panorama and a 1:3 tall photo are cropped to 3:2 and 2:3.
- Uploaded files contain no location or other metadata, tested with a geotagged photo.
- "1 1/2 cup" saves as 1.5 and displays as "1½ cups".
- pgTAP: another user cannot read a private recipe or its ingredients and steps.
- Editing updates every field. Deleting removes the row and both files.

### Phase 3 — The wall

1. `get_wall` and its partial index.
2. `RecipeWall` and `useInfiniteRecipes`: two masonry columns, image-only cards sized from stored dimensions, `expo-image` placeholders, next-page prefetch, pull to refresh, empty and error states.
3. Tapping a card opens Recipe detail.
4. Local seed script: 20 users, 500 recipes with sample images.

**Done when:**
- Scrolling through all 500 seeded recipes shows no duplicates and no gaps, including when new recipes are posted mid-scroll.
- Layout does not shift as images load.
- Private recipes and recipes across a block never appear.

### Phase 4 — Profiles

1. Profile screen for yourself and others. Recipes tab via `RecipeWall` and `get_user_recipes`. Lock icons on your own private recipes.
2. Author row on Recipe detail opens the profile.
3. Settings → Edit profile: change username, set or replace avatar (`avatars` bucket, `prepareAvatar`, delete the old file).
4. "This account isn't available" state across a block.

**Done when:**
- Visitors see only public recipes. The owner sees all, with locks.
- A username change shows everywhere after refresh.
- Avatar files have no metadata.

### Phase 5 — Likes

1. Migration: `likes`, like-count trigger, RLS for R5, R10, `get_liked_recipes`.
2. Like button with count on Recipe detail, updated optimistically.
3. Liked recipes screen, reached from your own profile.

**Done when:**
- Liking and unliking updates the count, and the count is correct on a second device after refresh.
- pgTAP: liked lists are private; liking another user's private recipe fails.
- A recipe made private disappears from other users' liked lists, and reappears when made public again.

### Phase 6 — Collections

1. Migration: `collections`, `collection_items`, word filter on `name`, RLS for R3, R4, R9, R10, `get_user_collections`, `get_collection_recipes`.
2. Save sheet with inline "New collection" (default private).
3. Profile Collections tab.
4. Collection screen via `RecipeWall`, with owner actions: Rename, visibility, Delete.

**Done when:**
- One recipe can be in several collections.
- Visitors see only public collections, and inside them only recipes they may see.
- The cover is the latest-added recipe the viewer may see, and it updates when items are added or removed.
- Deleting a collection does not delete its recipes.

### Phase 7 — Search

1. Migration: enable `pg_trgm`, username trigram index, `search_recipes`, `search_users`, backfill `search_vector` for existing recipes.
2. Search screen: input debounced by 300 ms, Recipes and Users tabs, no-results states. Recipe results use `RecipeWall` with an offset data source.

**Done when:**
- "chick" finds chicken recipes. "eggs" finds recipes with "egg".
- Words in title, description, and ingredient items all match.
- pgTAP: private recipes and anything across a block are never returned.
- Username prefix search works.

### Phase 8 — Sharing

1. Share text module (from Section 9) wired to a Share button on Recipe detail, using the system share sheet.

**Done when:** shared text matches Section 9 and arrives intact in Messages, WhatsApp, and email on both platforms.

### Phase 9 — Moderation

1. Migration: `reports`, RLS for R8.
2. Report sheet from the recipe ⋯ menu and the profile ⋯ menu.
3. Block and unblock. Blocking from a recipe or profile returns to the previous screen. Settings → Blocked users.
4. Word-filter error messages on every form.
5. Write `/docs/moderation.md` for the owner: check open reports daily in the dashboard; SQL to remove a recipe; how to ban a user through Supabase Auth or delete their account; how to mark a report actioned or dismissed; how to add blocked terms.

**Done when:**
- After A blocks B, neither sees the other's profile, recipes, collections, or search results. A can unblock.
- Reports appear in the dashboard. A duplicate report shows a friendly message.

### Phase 10 — Account deletion, settings, legal

1. `delete-account` Edge Function.
2. Finish Settings: Terms, Privacy policy, Contact support, Sign out, Delete account.
3. Publish final terms and privacy policy at stable URLs. Terms include a zero-tolerance clause for objectionable content and abusive users. Privacy policy lists data collected and how deletion works.

**Done when:**
- Deleting an account removes the profile, recipes, images, likes, collections, and blocks.
- That user's recipes disappear from other users' collections.
- The same Apple or Google account can sign up again as a new user.

### Phase 11 — Beta and launch

1. App icon, splash screen, store listings, screenshots.
2. App Store Connect: privacy nutrition label, age rating, review notes explaining sign-in, reporting, and blocking.
3. Google Play Console: Data safety form, content rating, **closed testing** track. If the developer account is a new personal account, Google requires at least 12 testers opted in for 14 continuous days before production access. Recruit 15–20 Android testers to absorb dropouts.
4. TestFlight external group.
5. Invite 10–30 home cooks. They post their own recipes with their own photos. No scraped content and no public recipe datasets.
6. Owner reviews reports daily during the beta.
7. Launch when the wall has about 300 public recipes, every acceptance criterion passes, and there are no open crash-level bugs.
8. Submit for public release on both stores.

---

## 11. Testing strategy

1. Test behavior through public interfaces, not implementation details.
2. **pgTAP:** every rule R1–R11, each with at least three users: owner, another user, and a blocked user.
3. **Jest:** image pipeline math (crop and resize dimensions), quantities, time formatting, share text, validation, error mapping.
4. **Manual QA checklist** per phase on a real iPhone and a real Android phone, covering that phase's acceptance criteria.
5. Automated end-to-end tests are a Future Idea.

---

## 12. Defaults not discussed with the owner

These were set while writing the plan. Confirm with the owner if one causes trouble.

1. Sign-in is required to use the app. Terms are accepted before any content is shown.
2. Photos outside the 3:2–2:3 range are center-cropped automatically, with a preview. No manual crop tool.
3. Image buckets are public-read with unguessable paths. Private recipe images are protected by obscurity, not by permission checks.
4. Search uses English stemming.
5. The closed beta runs on the production backend.
6. Sentry for crash reporting.
7. No offline mode.

---

## 13. Decisions log

| Decision | Reason |
|---|---|
| Social app. Wall shows all users' public recipes, newest first, no ranking algorithm. | Likes and the Pinterest feel need other people's content. Ranking is not needed at MVP scale. |
| No following. Visibility is `public` / `private` only, stored as an extensible enum. | Followers-only visibility means nothing without follow requests, which add significant scope. |
| Visibility per recipe and per collection. No account-level privacy. | Private accounts only make sense with approved followers. |
| Private or deleted recipes disappear from others' collections and likes. No copies. | Copies mean duplicate data and stale versions. |
| Moderation: report, two-way block, word filter, terms at signup, review in the database dashboard. No admin app. | Meets app store rules for user content. An admin panel is a second app. |
| Sign in with Apple and Google only. | No passwords, resets, or verification emails. Apple requires its own option when Google sign-in is offered. |
| In-app account deletion. | Required by both app stores. |
| Structured ingredient rows. No line parser. | Future nutrition and ingredient matching depend on structure. The parser is the first post-MVP feature. |
| No URL import in the MVP. | Depends on the parser. Imported photos and text belong to the source sites, so imports could not go on the public wall. |
| Closed beta to seed the wall. | An empty wall loses new users. Scraped or dataset images can't be published. |
| Title optional. Exactly one image. | The image carries the card. Fewer fields means faster posting. |
| Servings and total time under "More details". | Keeps the form calm. Servings is needed later for nutrition and scaling. |
| Staggered columns, crop between 3:2 and 2:3. | Pinterest feel. Very tall photos would take over the screen. |
| Basic full-text search on recipes, username search on users. | Many users come to find recipes, not post them. Postgres handles it without another service. |
| Like count on recipe page only. Liked list private. No list of likers. | Keeps the wall quiet. Saves a screen and a privacy decision. |
| Collections: bottom-sheet save, many per recipe, default private, automatic cover. | Nothing goes public by accident. No cover picker to build. |
| Profile: username and avatar only. | Smallest useful profile. |
| Plain-text sharing only. | Works everywhere with no website. |
| No push notifications. | Nothing in the MVP needs them. |
| Expo and Supabase. No custom API. | Supabase covers sign-in, database, storage, and search. Less custom code for the agents to get wrong. |
| Row-level security enforces visibility. | A missed check in app code can't leak private content or ignore a block. |
| No graph database. | MVP relationships are one step (likes, saves, blocks). Postgres handles them, and following later. |
| Hosted, not self-hosted. | Public, image-heavy app. Supabase is open source, so self-hosting later stays possible. |
| Mobile only. | Web is a separate project. |

---

## 14. Future Ideas (out of scope)

### Next release, right after MVP
1. **Ingredient-line parser.** Type "2 cups flour, sifted" and the app fills quantity, unit, item, and note.
2. **URL import.** Paste a recipe site link. The app reads the site's structured recipe data and returns the recipe without the story. Depends on the parser. Imported recipes stay private unless the user replaces the photo and rewrites the text.

### Committed
3. **Print flow.** Turn a recipe into a PDF and open the system print dialog.

### Later
4. **Ingredient-based recommendations.** Enter several ingredients and get ranked matches. MVP search already covers a single ingredient by text.
5. **Nutrition tracking.** Calculated per serving from structured ingredients, using averages for items like "1 egg" and exact values for weights like "50 g sugar".
6. **Following.**
7. **Followers-only visibility with follow requests.** Adds the `followers` value to the `visibility` enum.
8. **Private accounts.** Depends on follow requests.
9. **Email and password sign-in.**
10. **More social sign-in options** (Meta and others).
11. **Multiple images per recipe,** up to 5.
12. **Hashtags in descriptions.** Existing descriptions become searchable retroactively, so users can start typing hashtags in the MVP.
13. **Like notifications** (push).
14. **List of who liked a recipe.**
15. **Collection cover picker.**
16. **Display name and bio.**
17. **Links that open a recipe in the app,** or the app store if the app isn't installed.
18. **Public web page per recipe.** Single recipe view only, no wall or search. Pending the owner's research on web versus phone browsing.
19. **Manual crop tool.**
20. **Permission-checked image URLs** for private recipes, if obscurity proves insufficient.
21. **Cleanup job for orphaned image files.**
22. **Automated end-to-end tests.**
