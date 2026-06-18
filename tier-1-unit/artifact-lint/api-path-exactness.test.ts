/**
 * TG-31 — API paths in generated code must match the OpenAPI spec exactly.
 *
 * Rule: every "/api/..." path used in web/src must be declared in
 * generated-docs/specs/api-spec.yaml (parameterised segments compared by shape).
 * Claude must never invent a path that isn't in the spec.
 *
 * The matcher is tested against fixtures; a regression scan runs it over the
 * real spec + endpoints when both exist, and is skipped (visibly) otherwise.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';
import { extractSpecPaths, findInventedPaths } from './linters';

const SPEC = `openapi: 3.0.3
paths:
  /api/v2/tasks:
    get: { responses: { '200': { description: ok } } }
  /api/v2/tasks/{id}:
    delete: { responses: { '204': { description: deleted } } }
`;

describe('TG-31 rule — findInventedPaths', () => {
  const specPaths = extractSpecPaths(SPEC);

  it('FAIL: flags a path not in the spec', () => {
    const code = `export const listTasks = () => fetch("/api/tasks");\n`; // should be /api/v2/tasks
    expect(findInventedPaths(code, specPaths)).toContain('/api/tasks');
  });

  it('PASS: accepts an exact spec match', () => {
    const code = `export const listTasks = () => fetch("/api/v2/tasks");\n`;
    expect(findInventedPaths(code, specPaths)).toHaveLength(0);
  });

  it('PASS: matches a parameterised path by shape', () => {
    const code = `export const deleteTask = (id: string) => fetch(\`/api/v2/tasks/\${id}\`);\n`;
    expect(findInventedPaths(code, specPaths)).toHaveLength(0);
  });

  it('PASS: ignores strings that are not /api paths', () => {
    const code = `const label = "/about"; const title = "Tasks";\n`;
    expect(findInventedPaths(code, specPaths)).toHaveLength(0);
  });
});

const SPEC_FILE = path.join(REPO_ROOT, 'generated-docs', 'specs', 'api-spec.yaml');
const ENDPOINTS = path.join(REPO_ROOT, 'web', 'src', 'lib', 'api', 'endpoints.ts');
const hasBoth = fs.existsSync(SPEC_FILE) && fs.existsSync(ENDPOINTS);

describe('TG-31 regression — real spec + endpoints', () => {
  it.skipIf(!hasBoth)('every code path matches the spec', () => {
    const specPaths = extractSpecPaths(fs.readFileSync(SPEC_FILE, 'utf8'));
    const invented = findInventedPaths(fs.readFileSync(ENDPOINTS, 'utf8'), specPaths);
    expect(invented, `Code paths not in spec: ${invented.join(', ')}`).toHaveLength(0);
  });
});
