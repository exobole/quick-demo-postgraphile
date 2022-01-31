
create table publ.users (
    id uuid default gen_random_uuid() primary key,
    first_name text not null  check(length(first_name) between 2 and 60 ),
    last_name text not null  check(length(last_name) between 2 and 60),
    email citext unique not null  check(email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
grant select on table publ.users to :DATABASE_VISITOR;
grant update (first_name, last_name) on table publ.users to :DATABASE_VISITOR;


create table priv.user_secrets (
    user_id uuid references publ.users on delete cascade,
    password_hash text
);

insert into publ.users (first_name, last_name, email ) values 
    ('Louis', 'Lecointre', 'loUis@obole.eu'),
    ('Clé', 'Pirault', 'cLemence@obole.eu'),
    ('Jean', 'Dupont', 'jd@testmail.test');

create trigger _500_update_timestamp
    before update on publ.users
    for each row
    execute procedure publ.update_timestamp();


-- custom query

alter table publ.users enable row level security;

create policy select_all 
on publ.users 
for select 
to :DATABASE_VISITOR
using (true);

create policy update_self 
on publ.users
for update
to :DATABASE_VISITOR
using ((id = publ.current_user_id()))
with check ((id = publ.current_user_id()));

