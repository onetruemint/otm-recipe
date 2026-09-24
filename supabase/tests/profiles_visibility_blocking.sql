-- R6: profiles are visible to everyone except across a block. Tested at the
-- RLS select level on public.profiles directly — the "This account isn't
-- available" UI behavior and any dedicated profile-fetch function are
-- Phase 4 work. Three users: owner, another (uninvolved) user, and a user
-- owner has blocked.

create extension if not exists pgtap with schema extensions;

begin;

select plan(5);

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner@test.com'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'other@test.com'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'blocked@test.com');

insert into public.profiles (id, username, terms_accepted_at) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'chef_owner', now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'chef_other', now()),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'chef_blocked', now());

-- owner blocks the blocked user (inserted directly, bypassing RLS as
-- postgres — blocks-insert RLS itself is covered in blocks_visibility.sql).
insert into public.blocks (blocker_id, blocked_id) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc');

set local role authenticated;

-- Owner sees an uninvolved user's profile fine.
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
select isnt_empty(
  $$select 1 from public.profiles where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'$$,
  'owner can see an uninvolved user''s profile'
);

-- Owner cannot see the profile of the user they blocked.
select is_empty(
  $$select 1 from public.profiles where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  'owner cannot see the profile of a user they blocked'
);

-- The blocked user cannot see the owner's profile either — the block is
-- symmetric for visibility.
set local request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
select is_empty(
  $$select 1 from public.profiles where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'a blocked user cannot see the blocker''s profile'
);

-- An uninvolved third party is unaffected by the block between owner and
-- the blocked user.
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
select isnt_empty(
  $$select 1 from public.profiles where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'an uninvolved user can still see the owner''s profile'
);
select isnt_empty(
  $$select 1 from public.profiles where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  'an uninvolved user can still see the blocked user''s profile'
);

select * from finish();

rollback;
