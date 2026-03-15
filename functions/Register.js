// Cloudflare Pages Function — serves Supabase config securely
export async function onRequest(context) {
  const url = context.env.SUPABASE_URL || '';
  const key = context.env.SUPABASE_ANON_KEY || '';
  return new Response(
    `window.SUPABASE_URL="${url}";window.SUPABASE_ANON_KEY="${key}";`,
    {
      headers: {
        'Content-Type': 'application/javascript',
        'Cache-Control': 'no-store'
      }
    }
  );
}
