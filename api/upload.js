export const config = { runtime: 'edge' };

export default async function handler(req) {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const REDIS_URL   = process.env.UPSTASH_REDIS_REST_URL;
  const REDIS_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;

  if (!REDIS_URL || !REDIS_TOKEN) {
    return new Response(JSON.stringify({ error: 'Redis not configured' }), { status: 500 });
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400 });
  }

  const { pcName, content, date } = body;
  if (!pcName || !content) {
    return new Response(JSON.stringify({ error: 'Missing pcName or content' }), { status: 400 });
  }

  const headers = {
    Authorization: `Bearer ${REDIS_TOKEN}`,
    'Content-Type': 'application/json',
  };

  const key = `specs:${pcName}`;
  const record = JSON.stringify({ pcName, content, date, updatedAt: new Date().toISOString() });

  // Save the report using Upstash REST pipeline
  const pipeline = [
    ["set", key, record],
    ["sadd", "pc-index", pcName]
  ];

  const res = await fetch(`${REDIS_URL}/pipeline`, {
    method: 'POST',
    headers,
    body: JSON.stringify(pipeline),
  });

  const result = await res.json();

  return new Response(JSON.stringify({ ok: true, pcName, redis: result }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}
