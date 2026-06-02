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

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const userId = await verifyUser(req);
    const body = await req.json().catch(() => ({}));
    const reportType = String(body.report_type ?? "30_day");
    const format = String(body.format ?? "plain_text");

    if (!["7_day", "30_day", "custom"].includes(reportType)) {
      return json({ error: "invalid_report_type" }, 400);
    }
    if (!["plain_text", "csv", "pdf"].includes(format)) {
      return json({ error: "invalid_format" }, 400);
    }

    return json({
      user_id: userId,
      report_type: reportType,
      format,
      status: "scaffolded",
      content: [
        "Inflamend Doctor Report",
        "This report summarizes self-reported IBD tracking data.",
        "It is not a diagnosis and should be reviewed with a clinician.",
        "",
        "Sections: symptoms, bowel movement trends, medication adherence, possible patterns, notes, questions for doctor."
      ].join("\n")
    });
  } catch (error) {
    const code = error instanceof Error ? error.message : "unknown_error";
    return json({ error: code }, code.includes("authorization") || code === "invalid_jwt" ? 401 : 500);
  }
});
