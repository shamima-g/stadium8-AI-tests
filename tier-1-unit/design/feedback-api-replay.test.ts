/**
 * AC4 replay over the real feedback-api-design run.
 *
 * A design + standalone-API build (single-page feedback wall backed by GET/POST /api/v1/messages)
 * captured into fixtures/design-capture/feedback/ (the OpenAPI spec + the generated endpoints).
 * This is the design counterpart to the mock-only runs: the build produced a real API client, so
 * the exact-path rule (TG-31) — which SKIPS on a mock-only build — gates here. Runs the real
 * matcher (extractSpecPaths / findInventedPaths, shared with api-path-exactness.test.ts) over the
 * captured artifacts: every /api path the client uses must be declared in the spec, via the shared
 * client, with nothing invented.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { extractSpecPaths, findInventedPaths } from '../artifact-lint/linters';

const FIX = path.resolve(__dirname, '..', '..', 'fixtures', 'design-capture', 'feedback');
const spec = fs.readFileSync(path.join(FIX, 'api-spec.yaml'), 'utf8');
const endpoints = fs.readFileSync(path.join(FIX, 'endpoints.ts'), 'utf8');

describe('feedback-api-design replay — real backend, exact paths (AC4)', () => {
  it('AC4: every /api path in the generated client matches the spec exactly (no invented paths)', () => {
    const specPaths = extractSpecPaths(spec);
    expect(specPaths.length, 'the spec declares at least one path').toBeGreaterThan(0);
    const invented = findInventedPaths(endpoints, specPaths);
    expect(invented, `paths not in the spec: ${invented.join(', ')}`).toHaveLength(0);
  });

  it('AC4: the client calls through the shared API client, not raw fetch or a stand-in layer', () => {
    expect(endpoints, 'imports the shared client').toMatch(/from '@\/lib\/api\/client'/);
    expect(endpoints, 'no raw fetch in the endpoints module').not.toMatch(/\bfetch\(/);
    expect(endpoints, 'uses the real spec path').toMatch(/\/api\/v1\/messages/);
  });

  it('AC4 teeth: an invented path would be caught', () => {
    const specPaths = extractSpecPaths(spec);
    const badCode = `export const listComments = () => get('/api/v1/comments');`; // not in the spec
    expect(findInventedPaths(badCode, specPaths)).toContain('/api/v1/comments');
  });
});
