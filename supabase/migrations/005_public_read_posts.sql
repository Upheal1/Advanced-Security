-- ============================================================
-- Migration 005 — Public read access for community feed
-- ============================================================
-- Problem:
--   posts_select and profiles_select_authenticated are both
--   restricted to the `authenticated` role.  An anon user
--   (anonymous auth disabled, guest mode) gets either 0 rows
--   or a PostgREST 403 on the profiles JOIN, causing the Flutter
--   app to display "Couldn't load feed".
--
-- Fix:
--   Extend SELECT policies to also cover the `anon` role so the
--   community feed is publicly readable, while INSERT / UPDATE /
--   DELETE remain restricted to authenticated users only.
--
-- Apply via Supabase dashboard → SQL Editor, or:
--   supabase db push  (if you have the CLI set up)
-- ============================================================

-- ---- posts -------------------------------------------------
drop policy if exists "posts_select" on public.posts;

create policy "posts_select_public"
  on public.posts
  for select
  to authenticated, anon
  using (true);

-- ---- profiles (required for the posts JOIN) ----------------
drop policy if exists "profiles_select_authenticated" on public.profiles;

create policy "profiles_select_public"
  on public.profiles
  for select
  to authenticated, anon
  using (true);

-- Existing INSERT / UPDATE policies are untouched and still
-- require an authenticated session, so only real users can
-- create or modify profiles.
