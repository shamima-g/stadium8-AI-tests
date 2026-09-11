/**
 * S8-134-145 — "Voice and volume" output discipline (Tier 1, static).
 *
 * Scope (per the plan): the three governed commands — /start, /continue, /plan.
 *
 * Two layers, per the suite's convention:
 *   1. Detector tests — inline good/bad samples; these are the real contract and
 *      always run.
 *   2. Regression scans — run the SAME detectors over the real template under
 *      TEMPLATE_DIR. Skipped VISIBLY (not silently) when no template is present,
 *      so a clean checkout can't show a vacuous green.
 *
 * Point the suite at the template under test with REPO_ROOT, e.g.:
 *   REPO_ROOT="C:\TestsArchives\stadium8-tests\s8-134-145Tests" npm run test:tier1
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { TEMPLATE_DIR, TEMPLATE_PRESENT, NO_TEMPLATE_REASON } from '../../helpers';
import {
  agentNamesFromFilenames,
  extractEpicPhases,
  checkVoiceAndVolume,
  missingRuleParts,
  loadsSharedRule,
  hasWorkflowOnlyMarker,
  hasVerbatimLeftover,
  GOVERNED_COMMANDS,
} from './rules';

// ---------------------------------------------------------------------------
// 1. Detector tests (always run) — the real contract
// ---------------------------------------------------------------------------

describe('agentNamesFromFilenames', () => {
  it('strips .md and drops README', () => {
    const names = agentNamesFromFilenames(['developer.md', 'test-generator.md', 'README.md']);
    expect(names).toEqual(['developer', 'test-generator']);
  });

  it('excludes non-.md entries (e.g. a stray file or dir name)', () => {
    const names = agentNamesFromFilenames(['developer.md', 'notes.txt', 'shared']);
    expect(names).toEqual(['developer']);
  });
});

describe('extractEpicPhases', () => {
  it('parses the frozen phase array', () => {
    const js =
      "const EPIC_PHASES = Object.freeze([\n  'PLAN',\n  'BUILD',\n  'COMPLETE'\n]);\n";
    expect(extractEpicPhases(js)).toEqual(['PLAN', 'BUILD', 'COMPLETE']);
  });

  it('returns [] when the block is absent', () => {
    expect(extractEpicPhases('const OTHER = [1,2,3];')).toEqual([]);
  });
});

describe('checkVoiceAndVolume / missingRuleParts', () => {
  const good =
    '## Voice and volume\n\n' +
    '**Every message is a decision, a result, or a progress marker.** Anything else is not shown.\n\n' +
    '**Never shown:**\n- File and state paths\n\n' +
    '**The one carve-out:** any of the above may appear when it is the thing being reported.\n';

  it('PASS: a complete rule has no missing parts', () => {
    expect(missingRuleParts(good)).toEqual([]);
  });

  it('FAIL: a rule missing the "Never shown" list is flagged', () => {
    const bad = good.replace(/\*\*Never shown:\*\*[\s\S]*?\n\n/, '');
    expect(missingRuleParts(bad)).toContain('neverShown');
  });

  it('FAIL: a rule missing the three-kinds sentence is flagged', () => {
    const bad = good.replace(/\*\*Every message is[^\n]*\n\n/, '');
    expect(missingRuleParts(bad)).toContain('threeKinds');
  });

  it('FAIL: a rule missing the carve-out is flagged', () => {
    const bad = good.replace(/\*\*The one carve-out:\*\*[^\n]*\n/, '');
    expect(missingRuleParts(bad)).toContain('carveOut');
  });

  it('FAIL: prose without the section heading is flagged', () => {
    expect(checkVoiceAndVolume('some unrelated prose').section).toBe(false);
  });
});

describe('loadsSharedRule', () => {
  it('PASS: a command that cats the rule in', () => {
    expect(loadsSharedRule('cat "${CLAUDE_PROJECT_DIR}/.claude/shared/orchestrator-rules.md"')).toBe(true);
  });

  it('FAIL: a mere hyperlink is not loading it', () => {
    expect(loadsSharedRule('see [the rules](../shared/orchestrator-rules.md#voice) for detail')).toBe(false);
  });
});

describe('agent-return markers', () => {
  it('hasWorkflowOnlyMarker detects the label', () => {
    expect(hasWorkflowOnlyMarker('DEVELOPER COMPLETE\n(For the workflow only)')).toBe(true);
    expect(hasWorkflowOnlyMarker('DEVELOPER COMPLETE')).toBe(false);
  });

  it('hasVerbatimLeftover detects the stale wording', () => {
    expect(hasVerbatimLeftover('the block — it is shown to the user verbatim.')).toBe(true);
    expect(hasVerbatimLeftover('the block is for the workflow only.')).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// 2. Regression scans over the real template (skip visibly when absent)
// ---------------------------------------------------------------------------

const read = (...p: string[]) => fs.readFileSync(path.join(TEMPLATE_DIR, ...p), 'utf8');

describe.skipIf(!TEMPLATE_PRESENT)('regression — the shared rule is present and wired', () => {
  it('orchestrator-rules.md carries the complete Voice-and-volume rule', () => {
    const content = read('shared', 'orchestrator-rules.md');
    const missing = missingRuleParts(content);
    expect(missing, `Missing rule parts: ${missing.join(', ')}`).toEqual([]);
  });

  it.each(GOVERNED_COMMANDS)('/%s loads the shared rule verbatim', (cmd) => {
    expect(loadsSharedRule(read('commands', `${cmd}.md`))).toBe(true);
  });
});

describe.skipIf(!TEMPLATE_PRESENT)('regression — source-of-truth name lists (feed Tier 2)', () => {
  it('agent names derive from the agents dir and include the key agents', () => {
    const files = fs.readdirSync(path.join(TEMPLATE_DIR, 'agents'));
    const names = agentNamesFromFilenames(files);
    expect(names.length).toBeGreaterThan(0);
    expect(names).toEqual(expect.arrayContaining(['developer', 'test-generator']));
  });

  it('phase names derive from EPIC_PHASES', () => {
    const phases = extractEpicPhases(read('scripts', 'lib', 'epic-state.js'));
    expect(phases).toEqual(
      expect.arrayContaining(['PLAN', 'BUILD', 'EPIC-END', 'MANUAL-TEST', 'COMPLETE']),
    );
  });
});

describe.skipIf(!TEMPLATE_PRESENT)('regression — agent-return exception (AC3, accepted)', () => {
  it('the developer block carries the "(For the workflow only)" marker', () => {
    expect(hasWorkflowOnlyMarker(read('agents', 'developer.md'))).toBe(true);
  });

  // TRIPWIRE — expected RED until the engineer removes the stale line from
  // developer.md (see plan §Known findings #2). It goes green on that one-line fix.
  it('developer.md no longer claims the block is "shown to the user verbatim"', () => {
    expect(
      hasVerbatimLeftover(read('agents', 'developer.md')),
      'Stale wording still in developer.md line ~13 — engineer to remove; contradicts "(For the workflow only)".',
    ).toBe(false);
  });
});

if (!TEMPLATE_PRESENT) {
  // eslint-disable-next-line no-console
  console.warn(NO_TEMPLATE_REASON);
}
