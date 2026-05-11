-- Optional schema additions for timeline feed + edge-function moderation clients.
-- Apply after 001_upheal_community.sql when using create-post / send-message functions
-- and private Realtime broadcast channels.

create table if not exists public.timeline_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  likes_count int not null default 0,
  comments_count int not null default 0,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create index if not exists timeline_posts_status_created_idx
  on public.timeline_posts (status, created_at desc);

alter table public.profiles
  add column if not exists badge text;

alter table public.groups
  add column if not exists slug text unique;

alter table public.group_members
  add column if not exists status text not null default 'active'
    check (status in ('active', 'left', 'banned'));

alter table public.group_messages
  add column if not exists content text;

-- Keep body / content in sync when only one side is written (legacy vs edge clients).
create or replace function public.trg_group_messages_body_content_sync()
returns trigger
language plpgsql
as $$
begin
  if new.content is null or trim(new.content) = '' then
    new.content := coalesce(nullif(trim(new.body), ''), '');
  end if;
  if new.body is null or trim(new.body) = '' then
    new.body := coalesce(nullif(trim(new.content), ''), '');
  end if;
  return new;
end;
$$;

drop trigger if exists group_messages_body_content_bi on public.group_messages;
create trigger group_messages_body_content_bi
  before insert or update on public.group_messages
  for each row execute procedure public.trg_group_messages_body_content_sync();

alter table public.timeline_posts enable row level security;

-- Add SELECT/INSERT policies for timeline_posts and tune Realtime broadcast authorization
-- to match your Supabase project (private channels + database triggers).
