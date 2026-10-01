// Shared CORS headers for all Lametna Edge Functions.
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function preflight(req: Request): Response | null {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  return null;
}

/** Guard for scheduled (cron) functions. Compares against CLEANUP_CRON_SECRET. */
export function assertCronSecret(req: Request): Response | null {
  const expected = Deno.env.get("CLEANUP_CRON_SECRET");
  if (!expected) return json({ error: "CRON_SECRET_NOT_CONFIGURED" }, 500);
  const got = req.headers.get("x-cron-secret");
  if (got !== expected) return json({ error: "FORBIDDEN" }, 403);
  return null;
}
