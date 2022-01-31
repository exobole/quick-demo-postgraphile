

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
grant execute on function publ.authenticate to :DATABASE_VISITOR;
