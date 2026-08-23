-- Local integration-test fixture grants only.
--
-- Production intentionally exposes privileged mutations through reviewed RPCs
-- instead of direct service_role table access. The browser-facing integration
-- fixtures need temporary CRUD access to create isolated rows. The guarded
-- runner applies these grants only to the verified loopback database and always
-- restores the canonical migration chain with `supabase db reset --local`.

grant usage on schema public to service_role;
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;
