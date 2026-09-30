/**
 * B8 — loadGoldenRun named slots. The default `loadGoldenRun()` (fixtures/golden-run/) is covered by
 * the Tier-2 recorded-run suite; here we pin the NEW multi-slot routing: a named slot resolves under
 * fixtures/golden-runs/<slot>/, fails closed when missing, and loads a docs-only capture — so a second
 * golden run (intake, parked design-update, …) can sit alongside the original without overwriting it.
 */
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { loadGoldenRun } from '../../helpers/golden-run';

const SLOTS_ROOT = path.resolve(__dirname, '..', '..', 'fixtures', 'golden-runs');

describe('loadGoldenRun — named slots (B8)', () => {
  it('a missing named slot fails closed, naming the slot path (not a vacuous pass)', () => {
    const g = loadGoldenRun('does-not-exist-slot');
    expect(g.present).toBe(false);
    expect(g.reason).toMatch(/golden-runs\/does-not-exist-slot/);
    expect(g.docsDir).toBeNull();
    expect(g.hasGit).toBe(false);
  });

  it('loads a docs-only named slot, isolated under fixtures/golden-runs/<slot>/', () => {
    const slot = `__b8-test-${Date.now()}__`;
    const dir = path.join(SLOTS_ROOT, slot);
    const createdRoot = !fs.existsSync(SLOTS_ROOT);
    fs.mkdirSync(path.join(dir, 'generated-docs'), { recursive: true });
    fs.writeFileSync(path.join(dir, 'meta.json'), JSON.stringify({ epicSlug: 'demo' }));
    try {
      const g = loadGoldenRun(slot);
      expect(g.present).toBe(true);
      expect(g.hasGit).toBe(false); // docs-only → git-topology checks skip
      expect(g.docsDir).toBe(path.join(dir, 'generated-docs'));
      expect(g.meta.epicSlug).toBe('demo');
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
      if (createdRoot) { try { fs.rmdirSync(SLOTS_ROOT); } catch { /* not empty / ignore */ } }
    }
  });
});
