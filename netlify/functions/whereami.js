// Netlify serverless function that proxies the RapidAPI WhatIsHere endpoint.
// Holds the RAPIDAPI_KEY server-side so it never lands in the client bundle.
//
// POST /api/whereami
// Body: { "lat": 48.8719556, "lng": 2.3415407, "lang": "en", "country": "ng" }
// Response: forwards the RapidAPI response as-is.
//
// Mirrors the pattern in netlify/functions/gemini.js — the client calls this
// endpoint in production and uses --dart-define for local dev.

const RAPIDAPI_HOST = 'maps-data.p.rapidapi.com';
const ENDPOINT = 'https://maps-data.p.rapidapi.com/whatishere.php';

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

  const apiKey = process.env.RAPIDAPI_KEY;
  if (!apiKey) {
    console.error('RAPIDAPI_KEY not set in Netlify environment.');
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Server misconfigured: RAPIDAPI_KEY not set.' },
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

  const { lat, lng, lang, country } = parsed;
  if (lat == null || lng == null) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Missing "lat" or "lng" in request.' },
      }),
    };
  }

  const params = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
    lang: lang || 'en',
    country: country || 'ng',
  });

  const url = `${ENDPOINT}?${params.toString()}`;

  try {
    const resp = await fetch(url, {
      method: 'GET',
      headers: {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': RAPIDAPI_HOST,
      },
    });

    const text = await resp.text();
    return {
      statusCode: resp.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      body: text,
    };
  } catch (e) {
    console.error('RapidAPI proxy fetch failed:', e);
    return {
      statusCode: 502,
      headers: corsHeaders,
      body: JSON.stringify({
        error: { message: 'Upstream RapidAPI request failed.' },
      }),
    };
  }
};
