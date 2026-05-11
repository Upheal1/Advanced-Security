-- ============================================================
-- Migration 006 — Performance indexes, content constraints,
--                  and server-side rate limiting
-- ============================================================
-- Apply via Supabase dashboard → SQL Editor, or:
--   supabase db push
-- ============================================================

-- ---- 1. Feed performance indexes ----------------------------

-- Primary feed query: ORDER BY created_at DESC, id DESC
-- Used by fetchPostsFeedPage() cursor-based pagination.
create index if not exists idx_posts_feed
  on public.posts (created_at desc, id desc);

-- Author-scoped lookups (profile page, watchPosts stream)
create index if not exists idx_posts_author
  on public.posts (author_id);

-- Comment thread loading (ORDER BY created_at ASC per post)
create index if not exists idx_comments_post_time
  on public.comments (post_id, created_at asc);

-- Group chat loading (ORDER BY created_at DESC per group)
create index if not exists idx_group_messages_room_time
  on public.group_messages (group_id, created_at desc);

-- Notification bell queries (newest-first per user)
create index if not exists idx_notifications_user_time
  on public.community_notifications (user_id, created_at desc);

-- XP audit lookups by user
create index if not exists idx_xp_events_user
  on public.community_xp_events (user_id, created_at desc);


-- ---- 2. Content length constraints --------------------------
-- Prevent empty / excessively-long posts from being inserted.
-- The Flutter client validates before sending, but DB is the
-- authoritative last line of defence.

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'chk_posts_body_length'
  ) then
    alter table public.posts
      add constraint chk_posts_body_length
      check (length(trim(body)) >= 1 and length(body) <= 5000);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'chk_comments_body_length'
  ) then
    alter table public.comments
      add constraint chk_comments_body_length
      check (length(trim(body)) >= 1 and length(body) <= 2000);
  end if;
end;
$$;


-- ---- 3. Server-side rate limiting ---------------------------
-- Allows max 10 posts per authenticated user per rolling hour.
-- Called from the posts INSERT RLS policy so no client-side
-- code can bypass it.
--
-- Uses security definer + explicit uid parameter to avoid the
-- Supabase gotcha where auth.uid() returns NULL inside security
-- definer functions (the caller's JWT is not propagated to the
-- definer execution context).

create or replace function public.fn_posts_rate_ok(p_uid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select count(*) < 10
  from public.posts
  where author_id = p_uid
    and created_at > now() - interval '1 hour';
$$;

-- Rebuild the INSERT policy to embed the rate limit check.
drop policy if exists "posts_insert_own" on public.posts;

create policy "posts_insert_own"
  on public.posts
  for insert
  to authenticated
  with check (
    auth.uid() = author_id
    and public.fn_posts_rate_ok(auth.uid())
  );


-- ---- 4. Explicit profiles INSERT guard ----------------------
-- Prevent any authenticated user from creating a profile row
-- for someone else (defense-in-depth on top of the trigger).
-- Already exists in migration 001 but recreated here for clarity.
-- Only recreate if missing.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'profiles'
      and policyname = 'profiles_insert_own'
  ) then
    execute $policy$
      create policy "profiles_insert_own"
        on public.profiles
        for insert
        to authenticated
        with check (auth.uid() = id)
    $policy$;
  end if;
end;
$$;
