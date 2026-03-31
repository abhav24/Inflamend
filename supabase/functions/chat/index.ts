import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ChatMessageInput {
  role: "user" | "assistant";
  content: string;
}

interface RequestBody {
  messages: ChatMessageInput[];
  userId: string;
}

const SYSTEM_PROMPT = `You are a compassionate and knowledgeable IBD (Inflammatory Bowel Disease) health management assistant for the Inflamend app. You support people living with Crohn's Disease, Ulcerative Colitis, and other forms of IBD.

You can help with:
- Answering questions about IBD conditions, symptoms, and triggers
- Explaining how common IBD medications work (such as biologics, immunomodulators, aminosalicylates, steroids)
- Helping users understand and interpret their tracked symptoms and patterns
- Providing practical tips for managing flares, diet, stress, and lifestyle
- Offering emotional support and encouragement for the challenges of living with a chronic illness
- Explaining medical terminology in plain, easy-to-understand language
- Discussing the Bristol Stool Scale and what different stool types may indicate
- Suggesting questions users might want to ask their gastroenterologist

Important boundaries you must always observe:
- You cannot and do not provide medical diagnoses
- You cannot tell a user whether they are in a flare or not based on their description alone
- You always recommend consulting a qualified gastroenterologist or healthcare provider for any medical decisions, changes to medication, or concerning symptoms
- You do not recommend specific dosages or instruct users to start or stop medications
- If a user describes an emergency (e.g., severe bleeding, signs of obstruction, high fever, extreme pain), you strongly and immediately urge them to seek emergency medical care

Tone and style:
- Be warm, empathetic, and encouraging — living with IBD is genuinely hard
- Keep responses conversational and easy to read
- Use plain text only — no markdown formatting like asterisks, bullet dashes, or pound signs, since responses display inside chat bubbles
- Keep responses concise but thorough; avoid overly long walls of text
- When appropriate, gently remind users that their doctor knows their specific case best`;

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: RequestBody = await req.json();
    const { messages, userId } = body;

    if (!messages || !Array.isArray(messages)) {
      return new Response(
        JSON.stringify({ error: "Invalid request: messages array required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Invalid request: userId required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const apiKey = Deno.env.get("AI_API_KEY");
    if (!apiKey) {
      console.error("AI_API_KEY is not set");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Use only the last 20 messages to keep context manageable
    const recentMessages = messages.slice(-20);

    // Validate and sanitize messages
    const sanitizedMessages: ChatMessageInput[] = recentMessages
      .filter(
        (m) =>
          m &&
          typeof m.content === "string" &&
          m.content.trim().length > 0 &&
          (m.role === "user" || m.role === "assistant")
      )
      .map((m) => ({
        role: m.role,
        content: m.content.trim(),
      }));

    if (sanitizedMessages.length === 0) {
      return new Response(
        JSON.stringify({ error: "No valid messages provided" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const aiResponse = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-haiku-4-5-20251001",
          max_tokens: 1024,
          system: SYSTEM_PROMPT,
          messages: sanitizedMessages,
        }),
      }
    );

    if (!aiResponse.ok) {
      const errorBody = await aiResponse.text();
      console.error(`AI provider error ${aiResponse.status}:`, errorBody);

      if (aiResponse.status === 401) {
        return new Response(
          JSON.stringify({ error: "Authentication error with AI provider" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (aiResponse.status === 429) {
        return new Response(
          JSON.stringify({
            error: "The AI service is currently busy. Please try again in a moment.",
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({ error: "Failed to get response from AI provider" }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const aiData = await aiResponse.json();

    // Extract the text content from the response
    const content =
      aiData?.content?.[0]?.type === "text"
        ? aiData.content[0].text
        : null;

    if (!content) {
      console.error("Unexpected AI response shape:", JSON.stringify(aiData));
      return new Response(
        JSON.stringify({ error: "Unexpected response format from AI provider" }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify({ content }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("chat function error:", message);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
