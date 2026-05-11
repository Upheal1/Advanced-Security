-- Allow members to upsert (update) their own row in group_members.
-- Without this, Supabase upsert (INSERT ON CONFLICT DO UPDATE) fails because
-- upsert requires both INSERT and UPDATE policies to be satisfied.
create policy if not exists "gm_update_self" on public.group_members
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
