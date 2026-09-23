-- Phase 1.1: profiles, blocks, blocked_terms, is_blocked_between,
-- complete_onboarding, word-filter trigger, RLS for R6/R7/R9.
--
-- Enum scoping decision (see docs/PROGRESS.md): none of plan Section 6.1's
-- enums (visibility, ingredient_unit, report_target, report_reason,
-- report_status) are referenced by this phase's tables, so they are deferred
-- to the migrations that introduce the tables that actually use them
-- (Phase 2 for visibility/ingredient_unit, Phase 9 for report_*).

-- =============================================================================
-- profiles
-- =============================================================================

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  avatar_path text,
  terms_accepted_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[a-z0-9._]{3,30}$')
);

alter table public.profiles enable row level security;

-- =============================================================================
-- blocks
-- =============================================================================

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_no_self_block check (blocker_id <> blocked_id)
);

alter table public.blocks enable row level security;

-- =============================================================================
-- blocked_terms
-- =============================================================================

create table public.blocked_terms (
  term text primary key,
  constraint blocked_terms_lowercase check (term = lower(term))
);

alter table public.blocked_terms enable row level security;
-- No policies: only service_role (which bypasses RLS) can read or write.
-- Managed by the owner in the dashboard, per plan Section 6.2.

-- =============================================================================
-- is_blocked_between(a, b) — SECURITY DEFINER so it can see both sides of a
-- block regardless of the caller's own RLS-visible rows (R7 restricts
-- `blocks` reads to the blocker only, but this check needs to see blocks
-- either party made).
-- =============================================================================

create or replace function public.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.blocks
    where (blocker_id = a and blocked_id = b)
       or (blocker_id = b and blocked_id = a)
  );
$$;

grant execute on function public.is_blocked_between (uuid, uuid) to anon, authenticated;

-- =============================================================================
-- RLS: profiles (R6 visible to everyone except across a block, R9 write own row)
-- =============================================================================

create policy "profiles_select_not_blocked" on public.profiles
for select
using (
  not public.is_blocked_between((select auth.uid()), id)
);

create policy "profiles_insert_own" on public.profiles
for insert
with check (id = (select auth.uid()));

create policy "profiles_update_own" on public.profiles
for update
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "profiles_delete_own" on public.profiles
for delete
using (id = (select auth.uid()));

-- =============================================================================
-- RLS: blocks (R7 visible only to the blocker, R9 write own row)
-- =============================================================================

create policy "blocks_select_own" on public.blocks
for select
using (blocker_id = (select auth.uid()));

create policy "blocks_insert_own" on public.blocks
for insert
with check (blocker_id = (select auth.uid()));

create policy "blocks_delete_own" on public.blocks
for delete
using (blocker_id = (select auth.uid()));

-- =============================================================================
-- Word-filter trigger (plan Section 6.5 #3).
--
-- Generic: reads the target column via TG_ARGV[0] so later phases can attach
-- it to recipes.title/description, recipe_ingredients.item/note,
-- recipe_steps.body, and collections.name without redefining the function —
-- only `create trigger ... execute function public.check_blocked_terms('<col>')`
-- is needed once those tables exist. This migration attaches it only to
-- profiles.username, the only word-filtered column that exists yet.
--
-- Matching is whole-word and case-insensitive: the column value is lowercased
-- and split into tokens on runs of non-alphanumeric characters, then checked
-- for exact membership against blocked_terms. This avoids building a per-term
-- regex (which would need escaping arbitrary terms) while still doing
-- whole-word matching rather than a substring match.
-- =============================================================================

create or replace function public.check_blocked_terms()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  col_name text := TG_ARGV[0];
  col_value text;
begin
  col_value := to_jsonb(NEW) ->> col_name;

  if col_value is not null and exists (
    select 1
    from regexp_split_to_table(lower(col_value), '[^a-z0-9]+') as word
    join public.blocked_terms bt on bt.term = word
  ) then
    raise exception 'blocked_term';
  end if;

  return NEW;
end;
$$;

create trigger profiles_username_blocked_terms
  before insert or update of username on public.profiles
  for each row
  execute function public.check_blocked_terms('username');

-- =============================================================================
-- updated_at trigger (plan Section 6.5 #2)
-- =============================================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

-- =============================================================================
-- complete_onboarding(p_username) (plan Section 6.4).
--
-- SECURITY INVOKER (the default — not set explicitly): runs as the calling
-- role, so the profiles_insert_own RLS policy applies naturally and a caller
-- can never create anyone's profile but their own.
-- =============================================================================

create or replace function public.complete_onboarding(p_username text)
returns public.profiles
language plpgsql
set search_path = public
as $$
declare
  new_profile public.profiles;
begin
  insert into public.profiles (id, username, terms_accepted_at)
  values ((select auth.uid()), lower(p_username), now())
  returning * into new_profile;

  return new_profile;
end;
$$;

grant execute on function public.complete_onboarding (text) to authenticated;
