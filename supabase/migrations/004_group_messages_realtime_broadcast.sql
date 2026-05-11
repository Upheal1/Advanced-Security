-- Realtime: broadcast new group_messages to private topic `group:{group_id}`.
-- Matches Flutter [CommunityRepository.subscribeToGroupMessages]: channel `group:$groupId`,
-- private channel, broadcast event name `INSERT`, payload shape includes `new` row.
--
-- Prerequisites (Supabase Dashboard):
-- • Edge Function `send-message` inserts into public.group_messages after auth + moderation.
-- • Realtime Authorization policies for `realtime.messages` so members only receive allowed topics.
-- • See https://supabase.com/docs/guides/realtime/broadcast#broadcast-from-the-database

-- Allow authenticated clients to read broadcast payloads (tune with Realtime RLS for production).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'realtime'
      AND tablename = 'messages'
      AND policyname = 'authenticated_can_select_realtime_messages'
  ) THEN
    CREATE POLICY "authenticated_can_select_realtime_messages"
      ON realtime.messages
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.broadcast_group_message_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM realtime.broadcast_changes(
    'group:' || NEW.group_id::text,
    TG_OP,
    TG_OP,
    TG_TABLE_NAME,
    TG_TABLE_SCHEMA,
    NEW,
    NULL
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS broadcast_group_messages_insert ON public.group_messages;
CREATE TRIGGER broadcast_group_messages_insert
  AFTER INSERT ON public.group_messages
  FOR EACH ROW
  EXECUTE PROCEDURE public.broadcast_group_message_insert();
