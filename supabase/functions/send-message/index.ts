// @ts-ignore: JSR type-only side-effect import is resolved by Supabase Edge runtime tooling
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// @ts-ignore: JSR specifier resolved by Deno/Supabase Edge runtime
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401 }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return new Response(
        JSON.stringify({ error: "Invalid user" }),
        { status: 401 }
      );
    }

    const body = await req.json();

    const groupId = body.group_id;
    const content = body.content;

    if (!groupId || !content) {
      return new Response(
        JSON.stringify({ error: "Missing fields" }),
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("group_messages")
      .insert({
        group_id: groupId,
        sender_id: user.id,
        content: content,
      })
      .select()
      .single();

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500 }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: data,
      }),
      { status: 200 }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "Unknown error" }),
      { status: 500 }
    );
  }
});