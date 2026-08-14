// FeedbackWall — small standalone API server (no deps; Node >=18).
// Implements the two endpoints in api.yaml over an in-memory store.
//   GET  /api/v1/messages  -> Message[] (newest first)
//   POST /api/v1/messages  -> 201 Message   (body { author, body })
// Run:  node server.mjs   (listens on http://localhost:4010)
import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';

const PORT = process.env.PORT || 4010;
/** @type {{id:string,author:string,body:string,createdAt:string}[]} */
const messages = [
  { id: randomUUID(), author: 'Ada', body: 'Love this!', createdAt: '2026-05-01T09:00:00.000Z' },
  { id: randomUUID(), author: 'Grace', body: 'Very handy.', createdAt: '2026-04-30T14:30:00.000Z' },
];

const json = (res, status, payload) => {
  res.writeHead(status, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
  });
  res.end(payload === undefined ? '' : JSON.stringify(payload));
};

const server = createServer((req, res) => {
  const url = (req.url || '').split('?')[0];
  if (req.method === 'OPTIONS') return json(res, 204);

  if (url === '/api/v1/messages' && req.method === 'GET') {
    const sorted = [...messages].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    return json(res, 200, sorted);
  }

  if (url === '/api/v1/messages' && req.method === 'POST') {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      let parsed;
      try { parsed = JSON.parse(raw || '{}'); } catch { return json(res, 400, { error: 'invalid JSON' }); }
      const author = typeof parsed.author === 'string' ? parsed.author.trim() : '';
      const body = typeof parsed.body === 'string' ? parsed.body.trim() : '';
      if (!author || !body) return json(res, 400, { error: 'author and body are required' });
      const msg = { id: randomUUID(), author, body, createdAt: new Date().toISOString() };
      messages.push(msg);
      return json(res, 201, msg);
    });
    return;
  }

  return json(res, 404, { error: 'not found' });
});

server.listen(PORT, () => console.log(`Feedback API on http://localhost:${PORT}`));
