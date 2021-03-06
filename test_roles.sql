\qecho '---------- Schema setup ------------'

create schema if not exists test_roles;
set search_path to test_roles;

-- table
create table if not exists messages (
  id int generated by default as identity primary key,
  from_user name not null default current_user,
  to_user name not null,
  body text
);
alter table messages enable row level security;

-- policies
create policy messages_owners on messages
  using ((from_user = current_user) or (to_user = current_user))
  with check (from_user = current_user);

-- roles and grants
create role user_a;
create role user_b;
create role user_c;
grant all privileges on messages to user_a;
grant all privileges on messages to user_b;
grant all privileges on messages to user_c;

-- fail on any error below this line
\set ON_ERROR_STOP TRUE

\qecho
\qecho
\qecho '---------- Test row locks ------------'

\qecho
\qecho '--- create some messages as user_a'
begin;
  set local role 'user_a';
  insert into messages(to_user, body) values ('user_b', 'hello user b');
  select * from messages;
commit;

\qecho
\qecho '--- create some messages as user_b'
begin;
  set local role 'user_b';
  insert into messages(to_user, body) values ('user_a', 'hello hello');
  select * from messages;
commit;

\qecho
\qecho '--- check all the messages as user_c (returns no rows)'
begin;
  set local role 'user_c';
  select * from messages;
commit;

\qecho
\qecho '--- try to pretend to be user_b as user_c (fails with error)'
begin;
  set local role 'user_c';
  insert into messages(from_user, to_user, body) values ('user_a', 'user_b', 'hello hello');
end;
