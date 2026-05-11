-- Integrated into 001_upheal_community.sql (handle_new_user, profiles_insert_own, users RLS).
--
-- Apply order:
--   1) Your core app schema (must include public.users if you use roadmap/clinical tables)
--   2) 001_upheal_community.sql  ← creates public.profiles first, then policies + trigger
--
-- This file is a no-op so older docs that mention "002" do not fail when profiles does not exist yet.
select 1;
