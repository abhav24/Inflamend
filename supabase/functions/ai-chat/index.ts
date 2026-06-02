type VerifiedUser = {
  id: string;
  email?: string;
};

const redFlagPatterns = [
  /severe abdominal pain/i,
  /lots of blood|heavy bleeding|significant blood|black stool|tarry stool/i,
  /high fever|fever.*(103|104|105)/i,
  /faint|passed out|passing out/i,
  /dehydrated|can't keep fluids down|cannot keep fluids down/i,
  /chest pain|shortness of breath/i,
  /rapid weight loss|rapidly worse|rapid worsening/i,
  /suicidal|self harm|kill myself/i
];

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" }
  });
}

async function verifyUser(req: Request): Promise<VerifiedUser> {
  const auth = req.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) {
    throw new Error("missing_authorization");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !anonKey) {
    throw new Error("server_not_configured");
  }

  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      authorization: auth,
      apikey: anonKey
    }
  });

  if (!userResponse.ok) {
    throw new Error("invalid_jwt");
  }

  const user = await userResponse.json();
  return { id: user.id, email: user.email };
}

function hasRedFlag(text: string): boolean {
  return redFlagPatterns.some((pattern) => pattern.test(text));
}

function safetyResponse(message: string): string {
  if (hasRedFlag(message)) {
    return [
      "Some of what you described can be serious. Inflamend cannot diagnose or triage emergencies.",
      "Please contact urgent medical care, emergency services, or your clinician now if symptoms feel severe, are rapidly worsening, include heavy bleeding, fainting, chest pain, shortness of breath, or dehydration.",
      "If you are in immediate danger, call local emergency services."
    ].join(" ");
  }

  if (/stop|change|skip|increase|decrease|quit/i.test(message) && /mesalamine|steroid|prednisone|biologic|azathioprine|medicine|medication|dose/i.test(message)) {
    return "Medication changes should be made with your GI clinician or pharmacist. Inflamend can help you prepare questions and summarize what you have logged, but it cannot recommend starting, stopping, or changing a prescription.";
  }

  return "Inflamend is a tracking and education assistant, not a doctor. I can explain general IBD concepts, suggest what to track, and help you prepare questions for your clinician.";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const user = await verifyUser(req);
    const body = await req.json().catch(() => ({}));
    const message = String(body.message ?? "").trim();

    if (!message) {
      return json({ error: "message_required" }, 400);
    }

    const safety = safetyResponse(message);
    const providerKey = Deno.env.get("AI_PROVIDER_API_KEY");

    if (!providerKey || hasRedFlag(message)) {
      return json({
        user_id: user.id,
        red_flag_detected: hasRedFlag(message),
        response: safety,
        scaffolded: !providerKey,
        provider_status: providerKey ? "bypassed_for_safety" : "not_configured"
      });
    }

    return json({
      user_id: user.id,
      red_flag_detected: false,
      response: `${safety} Provider call scaffold is configured here; wire the selected AI provider with a server-side system prompt before production.`,
      scaffolded: true,
      provider_status: "scaffold_only"
    });
  } catch (error) {
    const code = error instanceof Error ? error.message : "unknown_error";
    const status = code === "missing_authorization" || code === "invalid_jwt" ? 401 : 500;
    return json({ error: code }, status);
  }
});
