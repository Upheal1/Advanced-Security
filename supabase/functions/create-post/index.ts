// @ts-ignore: JSR type-only side-effect import is resolved by Supabase Edge runtime tooling
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// @ts-ignore: JSR specifier resolved by Deno/Supabase Edge runtime
import { createClient } from "jsr:@supabase/supabase-js@2"

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: CORS_HEADERS },
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    )

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired session" }),
        { status: 401, headers: CORS_HEADERS },
      )
    }

    const payload = await req.json()

    // Required: body text (matches the `posts.body` column)
    const body: string = (payload.body ?? "").trim()
    if (body.length === 0) {
      return new Response(
        JSON.stringify({ error: "Post body is required" }),
        { status: 400, headers: CORS_HEADERS },
      )
    }
    if (body.length > 5000) {
      return new Response(
        JSON.stringify({ error: "Post body must be 5000 characters or fewer" }),
        { status: 400, headers: CORS_HEADERS },
      )
    }

    // Optional fields
    const tags: string[] = Array.isArray(payload.tags) ? payload.tags : []
    const imageUrls: string[] = Array.isArray(payload.image_urls) ? payload.image_urls : []

    // Rate-limit check: max 10 posts per user per hour (mirrors DB policy)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
    const { count, error: countError } = await supabase
      .from("posts")
      .select("id", { count: "exact", head: true })
      .eq("author_id", user.id)
      .gte("created_at", oneHourAgo)

    if (countError) {
      return new Response(
        JSON.stringify({ error: "Rate-limit check failed: " + countError.message }),
        { status: 500, headers: CORS_HEADERS },
      )
    }

    if ((count ?? 0) >= 10) {
      return new Response(
        JSON.stringify({ error: "Rate limit: max 10 posts per hour" }),
        { status: 429, headers: CORS_HEADERS },
      )
    }

    // Insert into `posts` (the live community table)
    const { data, error: insertError } = await supabase
      .from("posts")
      .insert({
        author_id: user.id,
        body,
        tags,
        image_urls: imageUrls,
      })
      .select()
      .single()

    if (insertError) {
      return new Response(
        JSON.stringify({ error: insertError.message }),
        { status: 500, headers: CORS_HEADERS },
      )
    }

    return new Response(
      JSON.stringify({ success: true, post: data }),
      { status: 201, headers: CORS_HEADERS },
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "Unknown error" }),
      { status: 500, headers: CORS_HEADERS },
    )
  }
})