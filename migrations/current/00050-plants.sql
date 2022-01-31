
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

grant select on table publ.plants to :DATABASE_VISITOR;


create function publ.get_plant_user(plant_id uuid) returns publ.users as $$
    select usr.*
    from publ.users as usr
    inner join publ.plants as plt on plt.user_id = usr.id
    where plt.id = plant_id;
$$ language sql stable;


alter table publ.plants enable row level security;

drop policy if exists select_own_plants
on publ.plants;
create policy select_own_plants
on publ.plants
for select
to :DATABASE_VISITOR
using ((user_id = publ.current_user_id()));


create trigger _500_update_timestamp
    before update on publ.plants
    for each row
    execute procedure publ.update_timestamp();
