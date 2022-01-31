/*
 * Read about our publ/app_hidden/priv schemas here:
 * https://www.graphile.org/postgraphile/namespaces/#advice
 *
 * Note this pattern is not required to use PostGraphile, it's merely the
 * preference of the author of this package.
 */

create schema publ;
create schema priv;

-- The 'visitor' role (used by PostGraphile to represent an end user) may
-- access the public, publ and app_hidden schemas (but _NOT_ the
-- priv schema).
grant usage on schema public, publ to :DATABASE_VISITOR;

-- We want the `visitor` role to be able to insert rows (`serial` data type
-- creates sequences, so we need to grant access to that).
alter default privileges in schema public, publ
  grant usage, select on sequences to :DATABASE_VISITOR;

-- And the `visitor` role should be able to call functions too.
alter default privileges in schema public, publ
  grant execute on functions to :DATABASE_VISITOR;
