// Netlify serverless function that proxies Gemini API calls.
// Holds the GEMINI_API_KEY server-side so it never lands in the client bundle.
//
// POST /api/gemini
// Body: { "model": "gemini-2.5-flash", "body": { ...generateContent JSON... } }
// Response: forwards the Gemini API response as-is.
//
// The client (GeminiService) calls this endpoint in production. For local dev
// without the proxy, the client falls back to direct Gemini calls when the
// GEMINI_API_KEY dart-define is set.

const ENDPOINT_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

exports.handler = async (event) => {
  // CORS headers for local `netlify dev` and any cross-origin callers.
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: corsHeaders, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: corsHeaders,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY not set in Netlify environment.');
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: {
          message: 'Server misconfigured: GEMINI_API_KEY not set.',
        },
      }),
    };
  }

  let parsed;
  try {
    parsed = JSON.parse(event.body || '{}');
  } catch (e) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Invalid JSON body.' },
      }),
    };
  }

  const { model, body } = parsed;
  if (!model || !body) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Missing "model" or "body" in request.' },
      }),
    };
  }

  // Only allow the models this app is designed to call. Belt-and-braces
  // against a compromised client trying to reach other models.
  const allowedModels = new Set([
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash',
  ]);
  if (!allowedModels.has(model)) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: `Model "${model}" is not allowed.` },
      }),
    };
  }

  const url = `${ENDPOINT_BASE}/${encodeURIComponent(model)}:generateContent?key=${apiKey}`;

  try {
    const resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const text = await resp.text();
    return {
      statusCode: resp.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      body: text,
    };
  } catch (e) {
    console.error('Gemini proxy fetch failed:', e);
    return {
      statusCode: 502,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Upstream Gemini request failed.' },
      }),
    };
  }
};
