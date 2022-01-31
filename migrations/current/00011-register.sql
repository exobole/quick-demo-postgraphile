
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
grant execute on function publ.register to :DATABASE_VISITOR;

