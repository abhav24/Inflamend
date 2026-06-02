type RiskInput = {
  stool_count?: number;
  baseline_stool_count?: number;
  blood?: "none" | "trace" | "visible" | "significant";
  urgency_score?: number;
  pain_score?: number;
  sleep_hours?: number;
  missed_medication?: boolean;
  rapid_worsening?: boolean;
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" }
  });
}

async function verifyUser(req: Request): Promise<string> {
  const auth = req.headers.get("authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!auth?.startsWith("Bearer ")) throw new Error("missing_authorization");
  if (!supabaseUrl || !anonKey) throw new Error("server_not_configured");

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { authorization: auth, apikey: anonKey }
  });
  if (!response.ok) throw new Error("invalid_jwt");
  const user = await response.json();
  return user.id;
}

function clamp(score: number): number {
  return Math.max(0, Math.min(100, Math.round(score)));
}

function computeRisk(input: RiskInput) {
  let score = 15;
  const factors: string[] = [];

  if ((input.stool_count ?? 0) > Math.max(3, (input.baseline_stool_count ?? 2) + 2)) {
    score += 15;
    factors.push("Bowel frequency is above the logged baseline.");
  }
  if (input.blood === "trace") {
    score += 10;
    factors.push("Trace blood was logged.");
  }
  if (input.blood === "visible" || input.blood === "significant") {
    score += 25;
    factors.push("Visible or significant blood was logged.");
  }
  if ((input.urgency_score ?? 0) >= 7) {
    score += 15;
    factors.push("Urgency is high.");
  }
  if ((input.pain_score ?? 0) >= 7) {
    score += 15;
    factors.push("Pain is high.");
  }
  if ((input.sleep_hours ?? 8) < 5) {
    score += 8;
    factors.push("Sleep was short.");
  }
  if (input.missed_medication) {
    score += 12;
    factors.push("Medication was missed or skipped.");
  }
  if (input.rapid_worsening) {
    score += 18;
    factors.push("Symptoms may be worsening quickly.");
  }

  const finalScore = clamp(score);
  return {
    score: finalScore,
    tier: finalScore < 30 ? "low" : finalScore < 60 ? "medium" : "high",
    factors,
    disclaimer: "This deterministic score is for tracking patterns only. It is not medically validated and is not a diagnosis."
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const userId = await verifyUser(req);
    const body = await req.json().catch(() => ({}));
    return json({ user_id: userId, ...computeRisk(body as RiskInput) });
  } catch (error) {
    const code = error instanceof Error ? error.message : "unknown_error";
    return json({ error: code }, code.includes("authorization") || code === "invalid_jwt" ? 401 : 500);
  }
});
