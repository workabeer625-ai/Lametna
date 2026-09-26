// ============================================================
// لمّتنا / Lametna — resolve-round
// Player-triggered resolution. Used when every player has already
// answered so the room does not have to wait for the timer.
// The function only *asks* the database to resolve; the outcome is
// computed entirely inside the SECURITY DEFINER `resolve_round`
// function, which is idempotent and validates membership itself.
// ============================================================
import { userClient } from "../_shared/client.ts";
import { json, preflight } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  try {
    const { round_id } = await req.json().catch(() => ({ round_id: null }));
    if (!round_id || typeof round_id !== "string") {
      return json({ error: "round_id is required" }, 400);
    }

    const supabase = userClient(req);
    const { data: user } = await supabase.auth.getUser();
    if (!user?.user) return json({ error: "AUTH_REQUIRED" }, 401);

    const { data, error } = await supabase.rpc("resolve_round", { p_round: round_id });
    if (error) return json({ error: error.message }, 400);

    return json({ ok: true, result: data });
  } catch (e) {
    console.error("resolve-round failed", e);
    return json({ ok: false, error: String((e as Error).message ?? e) }, 500);
  }
});
