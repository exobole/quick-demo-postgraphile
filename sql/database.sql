-- ne lancer qu'une fois au demarrage du projet
-- create role demo_visitor;





create extension if not exists pgcrypto with schema public;
create extension if not exists citext with schema public;

drop schema if exists publ cascade;
create schema publ;
grant usage on schema publ to demo_visitor;

drop schema if exists priv cascade;
create schema priv;

alter default privileges in schema public, publ grant usage, select on sequences to demo_visitor;


create table publ.users (
    id uuid default gen_random_uuid() primary key,
    first_name text not null  check(length(first_name) between 2 and 60 ),
    last_name text not null  check(length(last_name) between 2 and 60),
    email citext unique not null  check(email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
grant select on table publ.users to demo_visitor;
grant update (first_name, last_name) on table publ.users to demo_visitor;


create table priv.user_secrets (
    user_id uuid references publ.users on delete cascade,
    password_hash text
);

create function publ.register(first_name text, last_name text, email citext, password text) returns publ.users as $$
    declare
        v_user publ.users;
    begin
        insert into publ.users (first_name, last_name, email) 
        values (first_name, last_name, email)
        returning * into v_user;

        insert into priv.user_secrets (user_id, password_hash)
        values (v_user.id, crypt(password, gen_salt('bf')));
    
        return v_user;
    end;
$$ language plpgsql volatile security definer;
grant execute on function publ.register to demo_visitor;


insert into publ.users (first_name, last_name, email ) values 
    ('Louis', 'Lecointre', 'loUis@obole.eu'),
    ('Clé', 'Pirault', 'cLemence@obole.eu'),
    ('Jean', 'Dupont', 'jd@testmail.test');

create table publ.plants (
    id uuid default gen_random_uuid() primary key,
    name text not null  check(length(name) between 2 and 60 ),
    description text not null  check(length(description) between 2 and 500),
    user_id uuid references publ.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

insert into publ.plants(name, description, user_id) values 
    ('Pomme de terre', 'Pomme de terre', (select id from publ.users where email = 'louis@obole.eu')),
    ('Baobab', 'Arbre d''Afrique', (select id from publ.users where email = 'clemence@obole.eu')),
    ('Arbre', 'Arbre d''Afrique', (select id from publ.users where email = 'clemence@obole.eu'));

grant select on table publ.plants to demo_visitor;

-- Création d'une procédure pour la mise à jour dsu champ updated_at
create function publ.update_timestamp() returns trigger as $$
begin
    NEW.updated_at := now();
    return NEW;
end;
$$ language plpgsql volatile;

create trigger _500_update_timestamp
    before update on publ.plants
    for each row
    execute procedure publ.update_timestamp();

create trigger _500_update_timestamp
    before update on publ.users
    for each row
    execute procedure publ.update_timestamp();


-- custom query
create function publ.get_plant_user(plant_id uuid) returns publ.users as $$
    select usr.*
    from publ.users as usr
    inner join publ.plants as plt on plt.user_id = usr.id
    where plt.id = plant_id;
$$ language sql stable;


create type publ.jwt as (
    sub uuid,
    exp bigint
);

create or replace function publ.authenticate(
  email citext,
  password text
) returns publ.jwt as $$
declare
  v_secret priv.user_secrets;
begin
  select sec.* into v_secret
  from priv.user_secrets as sec
  where sec.user_id = (select id from publ.users as usr where usr.email = $1);

  if v_secret.password_hash = crypt(password, v_secret.password_hash) then
    return (v_secret.user_id, extract(epoch from (now() + interval '2 days')))::publ.jwt;
  else
  raise exception 'Invalid credentials' using errcode='CREDS';
    return null;
  end if;
end;
$$ language plpgsql stable security definer;
grant execute on function publ.authenticate to demo_visitor;

create function publ.current_user_id() returns uuid as $$
    select id from publ.users 
    where id = nullif(current_setting('jwt.claims.sub', true), '')::uuid;
$$ language sql stable;
grant execute on function publ.current_user_id() to demo_visitor;

alter table publ.users enable row level security;

create policy select_all 
on publ.users 
for select 
to demo_visitor
using (true);

create policy update_self 
on publ.users
for update
to demo_visitor
using ((id = publ.current_user_id()))
with check ((id = publ.current_user_id()));


alter table publ.plants enable row level security;

drop policy select_own_plants
on publ.plants;
create policy select_own_plants
on publ.plants
for select
to demo_visitor
using ((user_id = publ.current_user_id()));