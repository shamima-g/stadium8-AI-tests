// FeedbackWall — small standalone API server, SQL Server backed (Node >=18).
// Implements the two endpoints in api.yaml over a SQL Server table (dbo.Messages).
//   GET  /api/v1/messages  -> Message[] (newest first)
//   POST /api/v1/messages  -> 201 Message   (body { author, body })
//
// Persistence: a SQL Server database. Apply backend/schema.sql once, then run the server.
// Requires the `mssql` driver:  npm i mssql
//
// Connection via env vars (all optional except where noted):
//   SQLSERVER_HOST      default: localhost
//   SQLSERVER_PORT      default: 1433
//   SQLSERVER_USER      default: sa
//   SQLSERVER_PASSWORD  (required)
//   SQLSERVER_DATABASE  default: FeedbackWall
//   SQLSERVER_ENCRYPT   "true" | "false"  (default: true; use false for a local dev box)
//
// Run:  node server.mjs   (listens on http://localhost:4010)
import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';
import sql from 'mssql';

const PORT = process.env.PORT || 4010;

const dbConfig = {
  server: process.env.SQLSERVER_HOST || 'localhost',
  port: Number(process.env.SQLSERVER_PORT || 1433),
  user: process.env.SQLSERVER_USER || 'sa',
  password: process.env.SQLSERVER_PASSWORD || '',
  database: process.env.SQLSERVER_DATABASE || 'FeedbackWall',
  options: {
    encrypt: (process.env.SQLSERVER_ENCRYPT || 'true') === 'true',
    trustServerCertificate: true,
  },
};

const json = (res, status, payload) => {
  res.writeHead(status, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
  });
  res.end(payload === undefined ? '' : JSON.stringify(payload));
};

const toMessage = (row) => ({
  id: row.id,
  author: row.author,
  body: row.body,
  createdAt: new Date(row.createdAt).toISOString(),
});

let pool;
const getPool = async () => {
  if (!pool) pool = await sql.connect(dbConfig);
  return pool;
};

const server = createServer(async (req, res) => {
  const url = (req.url || '').split('?')[0];
  if (req.method === 'OPTIONS') return json(res, 204);

  try {
    if (url === '/api/v1/messages' && req.method === 'GET') {
      const db = await getPool();
      const result = await db.request().query(
        'SELECT id, author, body, createdAt FROM dbo.Messages ORDER BY createdAt DESC'
      );
      return json(res, 200, result.recordset.map(toMessage));
    }

    if (url === '/api/v1/messages' && req.method === 'POST') {
      let raw = '';
      req.on('data', (c) => (raw += c));
      req.on('end', async () => {
        let parsed;
        try { parsed = JSON.parse(raw || '{}'); } catch { return json(res, 400, { error: 'invalid JSON' }); }
        const author = typeof parsed.author === 'string' ? parsed.author.trim() : '';
        const body = typeof parsed.body === 'string' ? parsed.body.trim() : '';
        if (!author || !body) return json(res, 400, { error: 'author and body are required' });
        try {
          const id = randomUUID();
          const createdAt = new Date().toISOString();
          const db = await getPool();
          await db.request()
            .input('id', sql.UniqueIdentifier, id)
            .input('author', sql.NVarChar(200), author)
            .input('body', sql.NVarChar(sql.MAX), body)
            .input('createdAt', sql.DateTime2, new Date(createdAt))
            .query('INSERT INTO dbo.Messages (id, author, body, createdAt) VALUES (@id, @author, @body, @createdAt)');
          return json(res, 201, { id, author, body, createdAt });
        } catch (err) {
          return json(res, 500, { error: 'database error', detail: String(err && err.message || err) });
        }
      });
      return;
    }

    return json(res, 404, { error: 'not found' });
  } catch (err) {
    return json(res, 500, { error: 'database error', detail: String(err && err.message || err) });
  }
});

server.listen(PORT, () => console.log(`Feedback API (SQL Server) on http://localhost:${PORT}`));
