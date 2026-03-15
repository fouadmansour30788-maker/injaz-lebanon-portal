// Cloudflare Pages single worker — handles /functions/config and /functions/claude
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Serve Supabase config
    if (url.pathname === '/functions/config') {
      const supabaseUrl = env.SUPABASE_URL || '';
      const supabaseKey = env.SUPABASE_ANON_KEY || '';
      return new Response(
        `window.SUPABASE_URL="${supabaseUrl}";window.SUPABASE_ANON_KEY="${supabaseKey}";`,
        {
          headers: {
            'Content-Type': 'application/javascript',
            'Cache-Control': 'no-store, no-cache'
          }
        }
      );
    }

    // Proxy Anthropic API
    if (url.pathname === '/functions/claude' && request.method === 'POST') {
      const apiKey = env.ANTHROPIC_API_KEY;
      if (!apiKey) {
        return new Response(JSON.stringify({ error: 'API key not configured' }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        });
      }
      try {
        const body = await request.json();
        const response = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01'
          },
          body: JSON.stringify(body)
        });
        const data = await response.json();
        return new Response(JSON.stringify(data), {
          status: response.status,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type'
        }
      });
    }

    // All other requests — serve static files
    return env.ASSETS.fetch(request);
  }
};
