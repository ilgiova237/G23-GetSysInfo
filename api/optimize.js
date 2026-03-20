export const config = { runtime: 'edge' };

const SYSTEM_PROMPT = `INSERISCI QUI IL TUO PROMPT`;

export default async function handler(req) {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const ANTHROPIC_KEY = process.env.ANTHROPIC_API_KEY;
  if (!ANTHROPIC_KEY) {
    return new Response(JSON.stringify({ error: 'API key not configured' }), { status: 500 });
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400 });
  }

  const { specs } = body;
  if (!specs) {
    return new Response(JSON.stringify({ error: 'Missing specs' }), { status: 400 });
  }

  const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: `Here are the system specs for this PC:\n\n${specs}`,
        },
      ],
    }),
  });

  const data = await claudeRes.json();

  if (!claudeRes.ok) {
    return new Response(JSON.stringify({ error: data }), { status: 500 });
  }

  const text = data.content?.[0]?.text || '';

  return new Response(JSON.stringify({ result: text }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}
