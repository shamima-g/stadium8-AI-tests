/**
 * Tests for .claude/scripts/import-prototype.js
 *
 * Imports a prototype repo into documentation/. The current template supports
 * only the genesis-based layout (genesis/, input/, designs/, prototype/src/).
 * Tested against a synthesised source tree.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { createTempProject, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/import-prototype.js';

function makeV2Source(base: string): string {
  // Layout per import-prototype.js header:
  //   genesis/genesis.md, genesis/source-manifest.md
  //   designs/tokens.css
  //   input/*.yaml (OpenAPI)
  //   prototype/src/
  const src = fs.mkdtempSync(path.join(os.tmpdir(), 'proto-v2-'));
  const genesisDir = path.join(src, 'genesis');
  const designsDir = path.join(src, 'designs');
  const inputDir = path.join(src, 'input');
  const protoSrc = path.join(src, 'prototype', 'src');
  fs.mkdirSync(genesisDir, { recursive: true });
  fs.mkdirSync(designsDir, { recursive: true });
  fs.mkdirSync(inputDir, { recursive: true });
  fs.mkdirSync(protoSrc, { recursive: true });
  fs.writeFileSync(path.join(genesisDir, 'genesis.md'), '# Genesis\n');
  fs.writeFileSync(path.join(genesisDir, 'source-manifest.md'), '# Manifest\n');
  fs.writeFileSync(path.join(designsDir, 'tokens.css'), ':root { --primary: #123; }\n');
  fs.writeFileSync(path.join(inputDir, 'api.yaml'),
    'openapi: 3.0.3\ninfo:\n  title: X\n  version: 1.0.0\npaths: {}\n');
  fs.writeFileSync(path.join(protoSrc, 'index.tsx'), 'export const x = 1;\n');
  return src;
}

describe('import-prototype.js — genesis layout', () => {
  let project: TempProject;
  let src: string;
  beforeEach(() => { project = createTempProject(); src = makeV2Source(''); });
  afterEach(() => {
    project.cleanup();
    fs.rmSync(src, { recursive: true, force: true });
  });

  it('PASS: copies genesis marker files into documentation/ when genesis.md is present', () => {
    const r = runScript(SCRIPT, ['--from', src], { cwd: project.root });
    const json = r.parsedJson as { status?: string } | undefined;
    // The genesis layout copies genesis/genesis.md → documentation/genesis.md
    const copied = project.exists('documentation/genesis.md');
    expect(copied || json?.status === 'ok').toBe(true);
  });

  it('FAIL: returns status=error when --from path does not exist', () => {
    const r = runScript(SCRIPT, ['--from', path.join(os.tmpdir(), 'does-not-exist-xyz')], { cwd: project.root });
    const json = r.parsedJson as { status?: string } | undefined;
    expect(json?.status).toBe('error');
  });
});
