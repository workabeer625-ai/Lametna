// ============================================================
// لمّتنا / Lametna — cleanup-rooms
// Scheduled maintenance for the Supabase free tier:
// closes stale rooms, trims chat/round history, expires guests.
//
// Schedule it with pg_cron (see DEPLOYMENT.md) or any free
// cron pinger, sending the header:  x-cron-secret: <secret>
// ============================================================
import { adminClient } from "../_shared/client.ts";
import { assertCronSecret, json, preflight } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  const denied = assertCronSecret(req);
  if (denied) return denied;

  try {
    const supabase = adminClient();
    const { data, error } = await supabase.rpc("cleanup_stale_rooms");
    if (error) throw error;
    return json({ ok: true, report: data });
  } catch (e) {
    console.error("cleanup-rooms failed", e);
    return json({ ok: false, error: String((e as Error).message ?? e) }, 500);
  }
});
