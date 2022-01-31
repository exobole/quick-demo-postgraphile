
create function publ.current_user_id() returns uuid as $$
    select nullif(current_setting('jwt.claims.sub', true), '')::uuid;
$$ language sql stable;
grant execute on function publ.current_user_id() to :DATABASE_VISITOR;
