-- R9: users can only write their own rows. Covers public.profiles.

create extension if not exists pgtap with schema extensions;

begin;

select plan(4);

-- Fixtures (inserted as postgres, which bypasses RLS as a superuser).
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner@test.com'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'other@test.com'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'nobody@test.com');

insert into public.profiles (id, username, terms_accepted_at) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'chef_owner', now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'chef_other', now());

set local role authenticated;
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Owner cannot create a profile row for someone else's auth.users id.
select throws_ok(
  $$insert into public.profiles (id, username, terms_accepted_at)
    values ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'stolen_id', now())$$,
  'new row violates row-level security policy for table "profiles"',
  'cannot insert a profile row for another user''s id'
);

-- Owner's UPDATE against another user's row matches zero rows (RLS filters
-- it out silently rather than erroring). The data-modifying WITH must be at
-- the top level of the statement, so it wraps the is() call rather than
-- sitting inside it.
with affected as (
  update public.profiles set username = 'hijacked'
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  returning 1
)
select is(
  (select count(*) from affected),
  0::bigint,
  'cannot update another user''s profile row'
);

-- Same for DELETE.
with affected as (
  delete from public.profiles
  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  returning 1
)
select is(
  (select count(*) from affected),
  0::bigint,
  'cannot delete another user''s profile row'
);

-- Sanity: the owner can still update their own row.
with affected as (
  update public.profiles set username = 'chef_owner_renamed'
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  returning 1
)
select is(
  (select count(*) from affected),
  1::bigint,
  'can update own profile row'
);

select * from finish();

rollback;
