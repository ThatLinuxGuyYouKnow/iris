// Netlify serverless function that proxies OpenAI-spec chat completions
// to Kimi K2.6 (vision-capable) hosted at opencode.ai.
// Holds the OPENCODE_API_KEY server-side so it never lands in the client bundle.
//
// POST /api/narration
// Body: { "messages": [...], "temperature": 0.2, "max_tokens": 1000 }
// Response: forwards the upstream response as-is.
//
// The model is pinned server-side to kimi-k2.6 so a compromised client
// cannot redirect to another model.

const ENDPOINT = 'https://opencode.ai/zen/go/v1/chat/completions';
const MODEL = 'mimo-v2.5-pro';

exports.handler = async (event) => {
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

  const apiKey = process.env.OPENCODE_API_KEY;
  if (!apiKey) {
    console.error('OPENCODE_API_KEY not set in Netlify environment.');
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Server misconfigured: OPENCODE_API_KEY not set.' },
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

  const { messages, temperature, max_tokens } = parsed;
  if (!Array.isArray(messages) || messages.length === 0) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Missing or invalid "messages" array.' },
      }),
    };
  }

  const payload = {
    model: MODEL,
    messages,
    temperature: temperature ?? 0.2,
    max_tokens: max_tokens ?? 1000,
  };

  try {
    const resp = await fetch(ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const text = await resp.text();
    return {
      statusCode: resp.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      body: text,
    };
  } catch (e) {
    console.error('Narration proxy fetch failed:', e);
    return {
      statusCode: 502,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Upstream narration request failed.' },
      }),
    };
  }
};
