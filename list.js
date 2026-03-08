export const config = { runtime: 'edge' };

export default async function handler(req) {
  const REDIS_URL   = process.env.UPSTASH_REDIS_REST_URL;
  const REDIS_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;

  const headers = { Authorization: `Bearer ${REDIS_TOKEN}` };

  // Get all PC names from index
  const setRes = await fetch(`${REDIS_URL}/smembers/pc-index`, { headers });
  const setData = await setRes.json();
  const pcNames = setData.result || [];

  if (pcNames.length === 0) {
    return new Response(JSON.stringify([]), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  }

  // Get metadata for each PC
  const pipeline = pcNames.map(name => ['get', `specs:${name}`]);
  const pipeRes = await fetch(`${REDIS_URL}/pipeline`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify(pipeline),
  });
  const pipeData = await pipeRes.json();

  const list = pipeData
    .map((r, i) => {
      if (!r.result) return null;
      try {
        const parsed = JSON.parse(r.result);
        return { pcName: parsed.pcName, date: parsed.date, updatedAt: parsed.updatedAt };
      } catch { return null; }
    })
    .filter(Boolean)
    .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

  return new Response(JSON.stringify(list), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}
