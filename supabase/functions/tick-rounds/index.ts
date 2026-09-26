// ============================================================
// لمّتنا / Lametna — tick-rounds
// The authoritative clock. Any round whose server-side `ends_at`
// has passed is resolved here, even if every client disconnected.
// This is what makes timers impossible to cheat: the device clock
// is never trusted, only `rounds.ends_at` in Postgres.
//
// Recommended schedule: every 10 seconds (pg_cron) — see DEPLOYMENT.md
// ============================================================
import { adminClient } from "../_shared/client.ts";
import { assertCronSecret, json, preflight } from "../_shared/cors.ts";

const MAX_PER_TICK = 40;

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  const denied = assertCronSecret(req);
  if (denied) return denied;

  const supabase = adminClient();
  const resolved: string[] = [];
  const failed: Array<{ id: string; error: string }> = [];

  try {
    const { data: due, error } = await supabase
      .from("rounds")
      .select("id, ends_at")
      .is("resolved_at", null)
      .lt("ends_at", new Date().toISOString())
      .order("ends_at", { ascending: true })
      .limit(MAX_PER_TICK);
    if (error) throw error;

    for (const round of due ?? []) {
      const { error: rpcError } = await supabase.rpc("resolve_round", { p_round: round.id });
      if (rpcError) failed.push({ id: round.id, error: rpcError.message });
      else resolved.push(round.id);
    }

    return json({ ok: true, resolved: resolved.length, failed });
  } catch (e) {
    console.error("tick-rounds failed", e);
    return json({ ok: false, error: String((e as Error).message ?? e) }, 500);
  }
});
