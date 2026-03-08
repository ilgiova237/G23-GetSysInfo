export const config = { runtime: 'edge' };

export default async function handler(req) {
  const REDIS_URL   = process.env.UPSTASH_REDIS_REST_URL;
  const REDIS_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;

  const url = new URL(req.url);
  const pcName = url.pathname.split('/').pop();

  if (!pcName) {
    return new Response(JSON.stringify({ error: 'Missing pcName' }), { status: 400 });
  }

  const headers = { Authorization: `Bearer ${REDIS_TOKEN}` };
  const res = await fetch(`${REDIS_URL}/get/${encodeURIComponent(`specs:${pcName}`)}`, { headers });
  const data = await res.json();

  if (!data.result) {
    return new Response(JSON.stringify({ error: 'Not found' }), { status: 404 });
  }

  const parsed = JSON.parse(data.result);

  return new Response(JSON.stringify(parsed), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}
