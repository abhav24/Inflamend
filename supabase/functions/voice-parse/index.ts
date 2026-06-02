type ParsedDraft = {
  type: string;
  confidence: "high" | "medium" | "ambiguous";
  fields: Record<string, unknown>;
  requires_confirmation: true;
  safety_flags: string[];
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

function parseNumber(text: string): number | undefined {
  const match = text.match(/\b(\d+(?:\.\d+)?)\b/);
  return match ? Number(match[1]) : undefined;
}

function safetyFlags(text: string): string[] {
  const flags: string[] = [];
  if (/blood|bleeding|black|tarry/i.test(text)) flags.push("blood_or_bleeding");
  if (/severe pain|pain.*(8|9|10)/i.test(text)) flags.push("severe_pain");
  if (/dehydrat|dizzy|faint/i.test(text)) flags.push("dehydration_or_fainting");
  if (/fever/i.test(text)) flags.push("fever");
  return flags;
}

function parseTranscript(transcript: string): ParsedDraft {
  const text = transcript.toLowerCase();
  const flags = safetyFlags(transcript);

  if (/bowel|movement|bristol|stool|poop/.test(text)) {
    const bristol = text.match(/bristol\s*(\d)/)?.[1] ?? text.match(/type\s*(\d)/)?.[1];
    const count = text.match(/(\d+)\s*(bowel|movement|stool)/)?.[1];
    return {
      type: "bowel",
      confidence: bristol || count ? "medium" : "ambiguous",
      fields: {
        bristol_type: bristol ? Number(bristol) : undefined,
        stool_count: count ? Number(count) : undefined,
        blood: /no blood/.test(text) ? "none" : /blood/.test(text) ? "visible" : undefined,
        urgency_score: text.match(/urgency\s*(\d+)/)?.[1]
      },
      requires_confirmation: true,
      safety_flags: flags
    };
  }

  if (/took|taken|med|medicine|mesalamine|dose|pill/.test(text)) {
    return {
      type: "medication",
      confidence: "medium",
      fields: {
        medication_name: transcript.match(/mesalamine|azathioprine|prednisone|vitamin d/i)?.[0],
        status: /skip|miss/.test(text) ? "skipped" : "taken"
      },
      requires_confirmation: true,
      safety_flags: flags
    };
  }

  if (/ate|meal|breakfast|lunch|dinner|snack|food/.test(text)) {
    return {
      type: "meal",
      confidence: "medium",
      fields: {
        description: transcript,
        meal_type: transcript.match(/breakfast|lunch|dinner|snack/i)?.[0]?.toLowerCase()
      },
      requires_confirmation: true,
      safety_flags: flags
    };
  }

  if (/slept|sleep|woke|bathroom/.test(text)) {
    return {
      type: "sleep",
      confidence: "medium",
      fields: {
        duration_hours: parseNumber(transcript),
        bathroom_wakes: text.match(/woke up\s*(\d+)/)?.[1]
      },
      requires_confirmation: true,
      safety_flags: flags
    };
  }

  if (/weight|pounds|lbs|kg/.test(text)) {
    return {
      type: "weight",
      confidence: parseNumber(transcript) ? "medium" : "ambiguous",
      fields: {
        weight_value: parseNumber(transcript),
        unit: /kg|kilogram/.test(text) ? "kg" : "lb"
      },
      requires_confirmation: true,
      safety_flags: flags
    };
  }

  if (/pain|fatigue|urgency|rough|flare|feel/.test(text)) {
    return {
      type: "symptom",
      confidence: "medium",
      fields: {
        pain_score: text.match(/pain\s*(is\s*)?(\d+)/)?.[2],
        fatigue_score: text.match(/fatigue\s*(is\s*)?(\d+)/)?.[2],
        note: transcript
      },
      requires_confirmation: true,
      safety_flags: flags
    };
  }

  return {
    type: "note",
    confidence: "ambiguous",
    fields: { note: transcript },
    requires_confirmation: true,
    safety_flags: flags
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const userId = await verifyUser(req);
    const body = await req.json().catch(() => ({}));
    const transcript = String(body.transcript ?? "").trim();
    if (!transcript) return json({ error: "transcript_required" }, 400);

    return json({
      user_id: userId,
      draft: parseTranscript(transcript),
      raw_audio_stored: false
    });
  } catch (error) {
    const code = error instanceof Error ? error.message : "unknown_error";
    return json({ error: code }, code.includes("authorization") || code === "invalid_jwt" ? 401 : 500);
  }
});
