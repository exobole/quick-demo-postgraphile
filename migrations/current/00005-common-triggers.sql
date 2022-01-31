
-- Création d'une procédure pour la mise à jour dsu champ updated_at
create function publ.update_timestamp() returns trigger as $$
begin
    NEW.updated_at := now();
    return NEW;
end;
$$ language plpgsql volatile;
