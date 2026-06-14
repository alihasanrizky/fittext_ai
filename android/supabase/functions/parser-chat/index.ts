import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apiKey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { message } = await req.json()
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

    if (!GEMINI_API_KEY) {
      return new Response(JSON.stringify({
        intent: "CLARIFICATION",
        clarification_message: "Eror: GEMINI_API_KEY belum dipasang di secrets Supabase!"
      }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: `You are a deterministic parsing engine. Analyze input under Indonesian context.
          Output ONLY valid JSON matching this schema precisely:
          {
            "intent": "FOOD_LOG" | "WORKOUT_LOG" | "WEIGHT_LOG" | "CLARIFICATION",
            "confidence": number,
            "error_code": "AMBIGUOUS" | "OUT_OF_CONTEXT" | "INCOMPLETE" | null,
            "clarification_message": string | null,
            "extracted_data": [
              {
                "food_name": string, "quantity": number, "unit": string, "calories": number,
                "exercise_name": string, "sets": number, "reps": number, "weight_kg": number, "weight_entry": number
              }
            ] | null
          }

          User input: ${message}` }] }],
        generationConfig: { responseMimeType: "application/json" }
      })
    })

    const data = await response.json()

    // 🔥 BLOK PENGAMAN: Cek jika Gemini mengembalikan pesan eror resmi
    if (data.error) {
      return new Response(JSON.stringify({
        intent: "CLARIFICATION",
        clarification_message: `Eror Gemini API (${data.error.code}): ${data.error.message}`
      }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    // 🔥 BLOK PENGAMAN: Cek jika candidates kosong/diblokir oleh safety filter Google
    if (!data.candidates || data.candidates.length === 0) {
      return new Response(JSON.stringify({
        intent: "CLARIFICATION",
        clarification_message: "Eror: Gemini tidak mengembalikan jawaban (Kemungkinan prompt diblokir/aman)."
      }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    const cleanJsonString = data.candidates[0].content.parts[0].text
    return new Response(cleanJsonString, { headers: { ...corsHeaders, "Content-Type": "application/json" } })

  } catch (e) {
    return new Response(JSON.stringify({
      intent: "CLARIFICATION",
      clarification_message: `Server Crash: ${e.message}`
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
  }
})