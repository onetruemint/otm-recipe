-- Word-filter trigger (plan Section 6.5 #3), attached to profiles.username
-- in this migration. Whole-word, case-insensitive against blocked_terms.

create extension if not exists pgtap with schema extensions;

begin;

select plan(4);

insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner@test.com'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'clean@test.com'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'notasubstring@test.com');

-- An offensive whole-word username, case-insensitive ('anal' is seeded in
-- blocked_terms), is rejected.
select throws_ok(
  $$insert into public.profiles (id, username, terms_accepted_at)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'anal.chef', now())$$,
  'blocked_term',
  'offensive username is rejected'
);

-- A clean username is accepted.
select lives_ok(
  $$insert into public.profiles (id, username, terms_accepted_at)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'chef_maria', now())$$,
  'clean username is accepted'
);

-- Matching is whole-word, not substring: a token that merely contains a
-- blocked term ('analytics' contains 'anal') is not rejected.
select lives_ok(
  $$insert into public.profiles (id, username, terms_accepted_at)
    values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'analytics99', now())$$,
  'a username that only contains a blocked term as a substring is accepted'
);

-- The trigger also fires on UPDATE of username, not just INSERT.
select throws_ok(
  $$update public.profiles set username = 'assmunch' where username = 'chef_maria'$$,
  'blocked_term',
  'renaming to an offensive username is rejected'
);

select * from finish();

rollback;
