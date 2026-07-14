/**
 * Tests for .claude/scripts/run-smoke-test.js
 *
 * Executes one HTTP smoke test for api-connectivity-agent. Its headline contract is
 * a security invariant: credential VALUES must never appear in stdout or the
 * re-runnable .sh artifact — the artifact carries env-var REFERENCES only, and any
 * credential echoed back in a response body is redacted.
 *
 * Uses an in-process echo server (via async spawn — NOT runScript's spawnSync, which
 * would block the event loop and deadlock the server) and a known-closed port for the
 * connection-refused path. No external network.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { spawn } from 'node:child_process';
import http from 'node:http';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = path.join(REPO_ROOT, '.claude', 'scripts', 'run-smoke-test.js');
const TOKEN = 'echo-secret-xyz-9182'; // unique so it can't collide with the runner's real env

interface SmokeResult {
  status: string;
  result: string;
  category: string;
  httpStatus: number | null;
  bodyExcerpt: string | null;
  missingCredentials: string[];
  errorMessage: string | null;
  shellArtifactPath: string | null;
}

/** Run the script as a real subprocess (async spawn) so an in-process server can respond. */
function runSmoke(cwd: string, configPath: string): Promise<{ code: number; stdout: string; stderr: string }> {
  return new Promise((resolve) => {
    const child = spawn('node', [SCRIPT, '--config', configPath], { cwd });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => (stdout += d));
    child.stderr.on('data', (d) => (stderr += d));
    child.on('close', (code) => resolve({ code: code ?? 1, stdout, stderr }));
  });
}

/** Listen on an ephemeral port, then close it — the port is now reliably closed. */
function closedPort(): Promise<number> {
  return new Promise((resolve) => {
    const srv = http.createServer();
    srv.listen(0, '127.0.0.1', () => {
      const port = (srv.address() as { port: number }).port;
      srv.close(() => resolve(port));
    });
  });
}

describe('run-smoke-test.js — credential safety', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: reports credentials_missing (without printing the value) when an env var is unset', async () => {
    project.write('.env.smoke', '# no SMOKE_MISSING_TOKEN defined here\n');
    const cfg = project.write('smoke.json', JSON.stringify({
      baseUrl: 'http://127.0.0.1:1',
      path: '/health',
      headers: [{ name: 'Authorization', valueTemplate: 'Bearer ${SMOKE_MISSING_TOKEN}' }],
      envFile: project.join('.env.smoke'),
      writeShellArtifact: 'generated-docs/specs/api-smoke-test.sh',
    }));
    const { code, stdout } = await runSmoke(project.root, cfg);
    expect(code).toBe(0);
    const res = JSON.parse(stdout) as SmokeResult;
    expect(res.result).toBe('credentials_missing');
    expect(res.missingCredentials).toContain('SMOKE_MISSING_TOKEN');
  });

  it('PASS: the .sh artifact carries an env-var REFERENCE, never the credential value', async () => {
    const port = await closedPort();
    project.write('.env.smoke', `SMOKE_TOKEN=${TOKEN}\n`);
    const cfg = project.write('smoke.json', JSON.stringify({
      baseUrl: `http://127.0.0.1:${port}`,
      path: '/health',
      headers: [{ name: 'Authorization', valueTemplate: 'Bearer ${SMOKE_TOKEN}' }],
      envFile: project.join('.env.smoke'),
      writeShellArtifact: 'generated-docs/specs/api-smoke-test.sh',
    }));
    const { stdout } = await runSmoke(project.root, cfg);
    // No credential value anywhere in stdout.
    expect(stdout).not.toContain(TOKEN);
    // Artifact references the var, not the value.
    const artifact = project.read('generated-docs/specs/api-smoke-test.sh');
    expect(artifact).toContain('${SMOKE_TOKEN');
    expect(artifact).not.toContain(TOKEN);
  });

  it('PASS: a credential echoed back in the response body is redacted', async () => {
    // Echo server returns the Authorization header value in the body — a reflective
    // endpoint. The script must redact the resolved credential from bodyExcerpt.
    const server = http.createServer((req, res) => {
      res.writeHead(200, { 'content-type': 'text/plain' });
      res.end(`auth was: ${req.headers['authorization']}`);
    });
    await new Promise<void>((r) => server.listen(0, '127.0.0.1', r));
    const port = (server.address() as { port: number }).port;
    try {
      project.write('.env.smoke', `SMOKE_TOKEN=${TOKEN}\n`);
      const cfg = project.write('smoke.json', JSON.stringify({
        baseUrl: `http://127.0.0.1:${port}`,
        path: '/echo',
        headers: [{ name: 'Authorization', valueTemplate: 'Bearer ${SMOKE_TOKEN}' }],
        envFile: project.join('.env.smoke'),
        writeShellArtifact: null,
      }));
      const { stdout } = await runSmoke(project.root, cfg);
      const res = JSON.parse(stdout) as SmokeResult;
      expect(res.result).toBe('success');
      expect(res.httpStatus).toBe(200);
      expect(res.bodyExcerpt).toContain('***REDACTED***');
      expect(res.bodyExcerpt).not.toContain(TOKEN);
      expect(stdout).not.toContain(TOKEN);
    } finally {
      await new Promise<void>((r) => server.close(() => r()));
    }
  });
});

describe('run-smoke-test.js — error shapes', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: a refused connection is categorised (result failure / connection_refused), not a crash', async () => {
    const port = await closedPort();
    const cfg = project.write('smoke.json', JSON.stringify({
      baseUrl: `http://127.0.0.1:${port}`,
      path: '/health',
      headers: [],
      envFile: project.join('.env.smoke'),
      writeShellArtifact: null,
      timeoutMs: 3000,
    }));
    project.write('.env.smoke', '\n');
    const { code, stdout } = await runSmoke(project.root, cfg);
    expect(code).toBe(0); // completed (the HTTP failure is data, not a script crash)
    const res = JSON.parse(stdout) as SmokeResult;
    expect(res.status).toBe('completed');
    expect(res.result).toBe('failure');
    expect(res.category).toBe('connection_refused');
  });

  it('FAIL: a missing --config exits non-zero with a status:error payload', async () => {
    const { code, stdout } = await new Promise<{ code: number; stdout: string }>((resolve) => {
      const child = spawn('node', [SCRIPT], { cwd: project.root });
      let stdout = '';
      child.stdout.on('data', (d) => (stdout += d));
      child.on('close', (c) => resolve({ code: c ?? 1, stdout }));
    });
    expect(code).toBe(1);
    expect(JSON.parse(stdout).status).toBe('error');
  });
});
