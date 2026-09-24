-- R7: blocks are visible only to the blocker. R9: users can only write their
-- own rows, applied to public.blocks. Three users: owner (the blocker),
-- another user, and the blocked user.

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

set local role authenticated;
set local request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Owner can create a block row where they are the blocker.
select lives_ok(
  $$insert into public.blocks (blocker_id, blocked_id)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc')$$,
  'owner can create a block row as the blocker'
);

-- Owner (the blocker) can read their own block row.
select isnt_empty(
  $$select 1 from public.blocks
    where blocker_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'blocker can read their own block row'
);

-- Another, uninvolved user cannot see the owner's block row.
set local request.jwt.claim.sub = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

select is_empty(
  $$select 1 from public.blocks
    where blocker_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'an uninvolved user cannot read another user''s block row'
);

-- The other user cannot forge a block row on the owner's behalf.
select throws_ok(
  $$insert into public.blocks (blocker_id, blocked_id)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')$$,
  'new row violates row-level security policy for table "blocks"',
  'cannot insert a block row as someone else'
);

-- The blocked user is not notified: they cannot see the block against them
-- either, even though they are named in the row.
set local request.jwt.claim.sub = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

select is_empty(
  $$select 1 from public.blocks
    where blocker_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'the blocked user cannot read the block row against them'
);

select * from finish();

rollback;
