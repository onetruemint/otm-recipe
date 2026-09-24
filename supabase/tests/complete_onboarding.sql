-- complete_onboarding(username): creates the caller's profile with
-- terms_accepted_at set. SECURITY INVOKER, so it can only ever create the
-- caller's own row — verified here by also checking that a direct insert
-- attempting to create someone else's row is blocked by the same RLS R9
-- policy the function relies on.

create extension if not exists pgtap with schema extensions;

begin;

select plan(4);

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner@test.com'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'other@test.com'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'nobody@test.com');

set local role authenticated;
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Call once and capture the result, since calling it twice for the same
-- user would violate the profiles primary key.
create temporary table onboarding_result as
select * from public.complete_onboarding('Chef_Owner');

select is(
  (select username from onboarding_result),
  'chef_owner',
  'complete_onboarding lowercases the username'
);

select ok(
  (select terms_accepted_at from onboarding_result) is not null,
  'complete_onboarding sets terms_accepted_at'
);

select isnt_empty(
  $$select 1 from public.profiles
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and username = 'chef_owner'$$,
  'the caller''s profile row exists after onboarding'
);

-- A different, not-yet-onboarded user cannot create a profile row for
-- someone else's id, e.g. by bypassing complete_onboarding with a direct
-- insert — RLS blocks it regardless.
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

select throws_ok(
  $$insert into public.profiles (id, username, terms_accepted_at)
    values ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'not_mine', now())$$,
  'new row violates row-level security policy for table "profiles"',
  'a user cannot create a profile row for someone else''s id'
);

select * from finish();

rollback;
