/**
 * The page opener works on every OS, not just Windows (post-v1.2.0) — planned #12.
 *
 * Dashboards, approval pages and reports open in the browser via `open-page.js`. Parts of the
 * workflow used to be Windows-only and quietly did nothing on a Mac or Linux box. The opener
 * now resolves a real command per platform: `explorer`/`rundll32` on Windows, `open` on macOS,
 * `xdg-open` (then `wslview` under WSL) on Linux.
 *
 * `openerCandidates(target, platform)` takes an explicit platform, so this checks all three
 * without needing to run on each. Feature-detected on the script; skips on older cuts. It reads
 * the live module directly (CJS) — the seam a host-only subprocess run can't reach.
 */

import { it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { describeTemplate as describe } from '../../helpers';
import { REPO_ROOT } from '../../helpers';

const OPEN_PAGE_ABS = path.join(REPO_ROOT, '.claude', 'scripts', 'open-page.js');
const PRESENT = fs.existsSync(OPEN_PAGE_ABS);

const require = createRequire(import.meta.url);

type Candidate = { command: string; args: string[] };
type OpenPage = { openerCandidates: (target: string, platform: NodeJS.Platform) => Candidate[] };

describe('open-page.js resolves an opener on every OS (post-v1.2.0)', () => {
  it.skipIf(!PRESENT)('PASS: macOS and Linux get a real opener, and Windows still works', () => {
    const { openerCandidates } = require(OPEN_PAGE_ABS) as OpenPage;
    const target = '/tmp/page.html';
    const commandsFor = (p: NodeJS.Platform) => openerCandidates(target, p).map((c) => c.command);

    // The fix: macOS and Linux resolve to their real opener — no longer a silent no-op.
    expect(commandsFor('darwin'), 'macOS uses `open`').toContain('open');
    expect(commandsFor('linux'), 'Linux uses `xdg-open` (wslview under WSL)').toContain('xdg-open');
    // Windows still resolves an opener too.
    expect(commandsFor('win32').length, 'Windows still has an opener').toBeGreaterThan(0);

    // Broken case / teeth: no platform returns an empty (no-op) list, and every candidate
    // actually carries the target path — so a Windows-only regression (empty macOS/Linux) is red.
    for (const p of ['win32', 'darwin', 'linux'] as NodeJS.Platform[]) {
      const list = openerCandidates(target, p);
      expect(list.length, `${p} must resolve at least one opener`).toBeGreaterThan(0);
      for (const c of list) {
        expect(c.args, `${p} opener passes the target path`).toContain(target);
      }
    }
  });
});
