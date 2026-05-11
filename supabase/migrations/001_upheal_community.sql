-- UpHeal Community + Group Chat — run in Supabase SQL Editor (or supabase db push)
--
-- Order: apply your core schema first if it defines public.users (roadmaps, XP, etc.).
-- This file creates public.profiles and community tables; do not run before users exists if your
-- handle_new_user trigger must insert into public.users (trigger runs after profiles is created here).
--
-- After applying: Dashboard → Database → Replication → enable supabase_realtime for:
--   posts, post_likes, post_saves, comments, groups, group_members, group_messages,
--   message_reactions, focus_room_state, profiles

-- Extensions
create extension if not exists "pgcrypto";

-- Profiles mirror auth.users (extend via trigger)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'UpHeal member',
  avatar_url text,
  level int not null default 1,
  streak_days int not null default 0,
  reputation int not null default 0,
  community_xp int not null default 0,
  badges text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_name text;
begin
  v_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    nullif(trim(split_part(new.email, '@', 1)), ''),
    'UpHeal member'
  );

  v_email := coalesce(
    nullif(trim(new.email), ''),
    'anon+' || replace(new.id::text, '-', '') || '@upheal.local'
  );

  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'users'
  ) then
    insert into public.users (id, email, created_at, updated_at)
    values (new.id, v_email, now(), now())
    on conflict (id) do update set
      email = excluded.email,
      updated_at = now();
  end if;

  insert into public.profiles (id, display_name)
  values (new.id, v_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Posts feed
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  image_urls text[] not null default '{}',
  tags text[] not null default '{}',
  like_count int not null default 0,
  comment_count int not null default 0,
  save_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_saves (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create or replace function public.trg_post_like_delta()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set like_count = like_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists post_likes_ai on public.post_likes;
create trigger post_likes_ai after insert on public.post_likes
  for each row execute procedure public.trg_post_like_delta();

drop trigger if exists post_likes_ad on public.post_likes;
create trigger post_likes_ad after delete on public.post_likes
  for each row execute procedure public.trg_post_like_delta();

create or replace function public.trg_post_save_delta()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set save_count = save_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set save_count = greatest(save_count - 1, 0) where id = old.post_id;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists post_saves_ai on public.post_saves;
create trigger post_saves_ai after insert on public.post_saves
  for each row execute procedure public.trg_post_save_delta();

drop trigger if exists post_saves_ad on public.post_saves;
create trigger post_saves_ad after delete on public.post_saves
  for each row execute procedure public.trg_post_save_delta();

-- Comments (nested via parent_id)
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  parent_id uuid references public.comments (id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.trg_comment_count()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists comments_ai on public.comments;
create trigger comments_ai after insert on public.comments
  for each row execute procedure public.trg_comment_count();

drop trigger if exists comments_ad on public.comments;
create trigger comments_ad after delete on public.comments
  for each row execute procedure public.trg_comment_count();

-- Groups / Discord-style rooms
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  group_type text not null default 'general'
    check (group_type in ('study','focus_room','gym','coding','recovery','general')),
  image_url text,
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text default '',
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.message_reactions (
  message_id uuid not null references public.group_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create table if not exists public.message_reads (
  message_id uuid not null references public.group_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

-- Focus room synchronized pomodoro state (one row per focus group)
create table if not exists public.focus_room_state (
  group_id uuid primary key references public.groups (id) on delete cascade,
  phase text not null default 'idle' check (phase in ('idle','focus','break')),
  phase_started_at timestamptz,
  focus_seconds int not null default 1500,
  break_seconds int not null default 300,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

-- Notifications queue (client polls or realtime)
create table if not exists public.community_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null,
  payload jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- XP audit (optional analytics)
create table if not exists public.community_xp_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null,
  points int not null,
  created_at timestamptz not null default now()
);

-- --- RLS ---
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_saves enable row level security;
alter table public.comments enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_messages enable row level security;
alter table public.message_reactions enable row level security;
alter table public.message_reads enable row level security;
alter table public.focus_room_state enable row level security;
alter table public.community_notifications enable row level security;
alter table public.community_xp_events enable row level security;

create policy "profiles_select_authenticated" on public.profiles for select to authenticated using (true);
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (auth.uid() = id);

create policy "posts_select" on public.posts for select to authenticated using (true);
create policy "posts_insert_own" on public.posts for insert to authenticated with check (auth.uid() = author_id);
create policy "posts_update_own" on public.posts for update to authenticated using (auth.uid() = author_id);

create policy "post_likes_all" on public.post_likes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "post_saves_all" on public.post_saves for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "comments_select" on public.comments for select to authenticated using (true);
create policy "comments_insert_own" on public.comments for insert to authenticated with check (auth.uid() = author_id);
create policy "comments_delete_own" on public.comments for delete to authenticated using (auth.uid() = author_id);

create policy "groups_select" on public.groups for select to authenticated using (true);
create policy "groups_insert" on public.groups for insert to authenticated with check (auth.uid() = created_by);

create policy "gm_select" on public.group_members for select to authenticated using (true);
create policy "gm_insert_self" on public.group_members for insert to authenticated with check (auth.uid() = user_id);
create policy "gm_delete_self" on public.group_members for delete to authenticated using (auth.uid() = user_id);

create policy "gmsg_select" on public.group_messages for select to authenticated using (
  exists (select 1 from public.group_members m where m.group_id = group_messages.group_id and m.user_id = auth.uid())
);
create policy "gmsg_insert" on public.group_messages for insert to authenticated with check (
  auth.uid() = sender_id and exists (select 1 from public.group_members m where m.group_id = group_messages.group_id and m.user_id = auth.uid())
);

create policy "mreact_all" on public.message_reactions for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "mread_all" on public.message_reads for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "focus_select" on public.focus_room_state for select to authenticated using (
  exists (select 1 from public.group_members m where m.group_id = focus_room_state.group_id and m.user_id = auth.uid())
);
create policy "focus_update" on public.focus_room_state for update to authenticated using (
  exists (select 1 from public.group_members m where m.group_id = focus_room_state.group_id and m.user_id = auth.uid())
);
create policy "focus_insert" on public.focus_room_state for insert to authenticated with check (
  exists (select 1 from public.group_members m where m.group_id = focus_room_state.group_id and m.user_id = auth.uid())
);

create policy "notif_own" on public.community_notifications for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "xp_events_own" on public.community_xp_events for select to authenticated using (auth.uid() = user_id);
create policy "xp_events_insert" on public.community_xp_events for insert to authenticated with check (auth.uid() = user_id);

-- Client upsert on public.users (same id as auth.users); only if core schema has this table.
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'users'
  ) then
    alter table public.users enable row level security;

    drop policy if exists "upheal_users_select_own" on public.users;
    drop policy if exists "upheal_users_insert_own" on public.users;
    drop policy if exists "upheal_users_update_own" on public.users;

    create policy "upheal_users_select_own" on public.users
      for select to authenticated using (id = auth.uid());

    create policy "upheal_users_insert_own" on public.users
      for insert to authenticated with check (id = auth.uid());

    create policy "upheal_users_update_own" on public.users
      for update to authenticated
      using (id = auth.uid())
      with check (id = auth.uid());
  end if;
end $$;

-- Storage bucket (create in Dashboard → Storage → New bucket `community-media`, public read)
-- Policies for storage.objects must be added separately for bucket community-media.
