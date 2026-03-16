// Cloudflare Pages Function — proxies Google Gemini API
export async function onRequestPost(context) {
  const GEMINI_API_KEY = context.env.GEMINI_API_KEY || 'AIzaSyDaiZvBJItgKBF26sdy3Ah1gc4ynZ2YgpI';
  if (!GEMINI_API_KEY) {
    return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not configured' }), { status: 500 });
  }

  try {
    const body = await context.request.json();

    // Convert Anthropic message format to Gemini format
    const messages = body.messages || [];
    const prompt = messages.map(m => m.content).join('\n');

    const geminiBody = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        maxOutputTokens: body.max_tokens || 2000,
        temperature: 0.7
      }
    };

    const response = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=' + GEMINI_API_KEY,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(geminiBody)
      }
    );

    const data = await response.json();

    if (!response.ok) {
      return new Response(JSON.stringify({ error: data.error?.message || 'Gemini API error' }), { status: response.status });
    }

    // Convert Gemini response to Anthropic-compatible format
    // so the portal code doesn't need to change
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text || 'No response generated.';
    const compatible = {
      content: [{ type: 'text', text: text }],
      model: 'gemini-1.5-flash'
    };

    return new Response(JSON.stringify(compatible), {
      status: 200,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    }
  });
}
