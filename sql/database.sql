create extension if not exists pgcrypto with schema public;
create extension if not exists citext with schema public;
drop schema if exists publ cascade;
create schema publ;


create table publ.users (
    id uuid default gen_random_uuid() primary key,
    first_name text not null  check(length(first_name) between 2 and 60 ),
    last_name text not null  check(length(last_name) between 2 and 60),
    email citext unique not null  check(email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

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

-- Creation d'une custom mutation pour la création d'un plant

