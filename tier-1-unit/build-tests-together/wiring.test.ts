/**
 * build-tests-together — Tier 1 wiring guards (T1.1–T1.6).
 *
 * 1. Detector unit tests — each true on the real 26-10 wording AND false on the two-call baseline
 *    wording taken verbatim from stadium-builder23-10 (the regression it guards).
 * 2. Regression over the real template at REPO_ROOT (green-now; pins the wording against a revert).
 *
 * Point at the feature-bearing checkout (PowerShell):
 *   $env:REPO_ROOT="C:\TestsArchives\stadium8-tests\stadium-builder 26-10"; $env:EXPECT_TEMPLATE="1"; $env:EXPECT_TEMPLATE_REF="v1.4.0"; npm run test:tier1
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { TEMPLATE_DIR, TEMPLATE_PRESENT, TEMPLATE_REF } from '../../helpers';
import {
  spawnsOneTestGeneratorPerStory,
  testGeneratorStoryModeBoth,
  hasParityMechanism,
  hasParitySuccessCriterion,
  sharedMocksBeforeTestBatch,
  specNameRegexIntact,
  testGeneratorOutputPaths,
  noVitestTagsNoFile,
  routableNeedsLiveTest,
} from './rules';

// ---- Good (26-10) vs broken (23-10) wording fixtures ----------------------

const B02_ONE_CALL = `### Step B0.2: Batch test generation (once — all stories)
For each story in the epic, launch one \`test-generator\` call (it writes both test files), all stories as one Task batch:
\`\`\`
Agent batch (per story N):
  - subagent_type: test-generator
    mode: story
\`\`\`
Both files import the epic's shared mock data from \`web/src/mocks/data/\` (B0).
### Step B0.3: Design tokens
`;

const B02_TWO_CALLS = `### Step B0.2: Batch test generation (once — all stories)
For each story in the epic, launch two \`test-generator\` calls — Vitest and Playwright are independent files — as one big Task batch (all stories × both modes):
\`\`\`
Agent batch (per story N):
  - subagent_type: test-generator
    mode: vitest
  - subagent_type: test-generator
    mode: playwright
\`\`\`
Both modes import the epic's shared mock data from \`app-frontend/src/mocks/data/\` (B0).
### Step B0.3: Design tokens
`;

const TG_STORY = `**Role:** One call per story writes both its files: a Vitest file and a Playwright E2E spec.
- \`mode\`: \`"epic-mocks"\` (runs once) · \`"story"\` (writes both test files)`;

const TG_SPLIT = `**Role:** Two artifacts per story: a Vitest file and (when routable) a Playwright E2E spec.
- \`mode\`: \`"epic-mocks"\` (runs once) · \`"vitest"\` · \`"playwright"\` (the \`vitest\`+\`playwright\` calls fire in parallel)`;

const TG_PARITY = `4. **List the story's controls before writing either file.** For each interactive control the ACs touch, fix its role and accessible name once — e.g. \`radiogroup\` "Status". In both files, find each control the same way and interact with it the same way.`;

// ---------------------------------------------------------------------------
// 1. Detector unit tests — true on 26-10, false on the 23-10 regression
// ---------------------------------------------------------------------------

describe('T1.1 one test-generator call per story (coupled to the real regression)', () => {
  it('true on the one-call wording', () => expect(spawnsOneTestGeneratorPerStory(B02_ONE_CALL)).toBe(true));
  it('false on the two-call baseline (23-10)', () => expect(spawnsOneTestGeneratorPerStory(B02_TWO_CALLS)).toBe(false));
});

describe('T1.2 mode "story" writes both files; no vitest/playwright split', () => {
  it('true on the story-mode wording', () => expect(testGeneratorStoryModeBoth(TG_STORY)).toBe(true));
  it('false on the split-mode baseline (23-10)', () => expect(testGeneratorStoryModeBoth(TG_SPLIT)).toBe(false));
});

describe('T1.3 parity mechanism present', () => {
  it('true when the "list controls / same way in both files" step is present', () =>
    expect(hasParityMechanism(TG_PARITY)).toBe(true));
  it('false when that step is deleted (the regression)', () =>
    expect(hasParityMechanism('4. Render the tags mechanically — one tag → one test.')).toBe(false));
  it('success criterion detector is mutation-coupled', () => {
    expect(hasParitySuccessCriterion('- [ ] Every control is found and interacted with the same way in both files')).toBe(true);
    expect(hasParitySuccessCriterion('- [ ] Each file has the right test count')).toBe(false);
  });
});

describe('T1.4 shared mocks (B0) before the batch (B0.2), imported there', () => {
  it('true when B0 precedes B0.2 and the batch imports the shared data', () => {
    const doc = `### Step B0: Epic mock-data bootstrap\nshared mock data.\n${B02_ONE_CALL}`;
    expect(sharedMocksBeforeTestBatch(doc)).toBe(true);
  });
  it('false when the shared-import clause is removed (synthetic mutation)', () => {
    const noImport = B02_ONE_CALL.replace(/Both files import[^\n]*\n/, '');
    const doc = `### Step B0: Epic mock-data bootstrap\nshared mock data.\n${noImport}`;
    expect(sharedMocksBeforeTestBatch(doc)).toBe(false);
  });
});

describe('T1.5 filename regex + Rule-10 output paths', () => {
  it('spec-name regex detector is mutation-coupled', () => {
    expect(specNameRegexIntact('| E2E spec | `^epic-[a-z][a-z0-9-]*-story-\\d+-[a-z][a-z0-9-]*\\.spec\\.ts$` |')).toBe(true);
    expect(specNameRegexIntact('| E2E spec | `^story-\\d+-.*\\.spec\\.ts$` |')).toBe(false);
  });
  it('output-paths detector is mutation-coupled', () => {
    const good = 'Vitest at `web/src/__tests__/integration/epic-<slug>-story-<N>-<title>.test.tsx`\nPlaywright at `web/e2e/epic-<slug>-story-<N>-<title>.spec.ts`';
    expect(testGeneratorOutputPaths(good)).toBe(true);
    expect(testGeneratorOutputPaths(good.replace('web/e2e/', 'app-frontend/e2e/'))).toBe(false);
  });
});

describe('T1.6 policy rules (no-vitest-tags → no file; routable needs a live test)', () => {
  it('no-vitest-tags detector is mutation-coupled', () => {
    expect(noVitestTagsNoFile('No `vitest` tags → write no Vitest file and return only the Playwright line.')).toBe(true);
    expect(noVitestTagsNoFile('Always write a Vitest file for every story.')).toBe(false);
  });
  it('routable-needs-live-test detector is mutation-coupled', () => {
    expect(routableNeedsLiveTest('- [ ] Routable stories have at least one live `test()`, not a stub')).toBe(true);
    expect(routableNeedsLiveTest('- [ ] Every story may use test.fixme() freely')).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Fail-closed: template present (and the right one) when explicitly expected
// ---------------------------------------------------------------------------

it('the template under test is present (and the right ref) when EXPECT_TEMPLATE is set', () => {
  if (!process.env.EXPECT_TEMPLATE) return;
  expect(TEMPLATE_PRESENT).toBe(true);
  if (process.env.EXPECT_TEMPLATE_REF) expect(TEMPLATE_REF).toBe(process.env.EXPECT_TEMPLATE_REF);
});

// ---------------------------------------------------------------------------
// 2. Regression over the real template (green-now; pins the single-agent wiring)
// ---------------------------------------------------------------------------

const read = (p: string) => fs.readFileSync(p, 'utf8');
const CONTINUE = path.join(TEMPLATE_DIR, 'commands', 'continue.md');
const TEST_GENERATOR = path.join(TEMPLATE_DIR, 'agents', 'test-generator.md');
const NAMING = path.join(TEMPLATE_DIR, 'shared', 'naming-conventions.md');

describe.skipIf(!TEMPLATE_PRESENT)('regression — single-agent wiring is present in the template', () => {
  it('T1.1 continue.md B0.2 launches one test-generator per story', () => {
    expect(spawnsOneTestGeneratorPerStory(read(CONTINUE))).toBe(true);
  });
  it('T1.2 test-generator mode "story" writes both files, no split', () => {
    expect(testGeneratorStoryModeBoth(read(TEST_GENERATOR))).toBe(true);
  });
  it('T1.3 test-generator carries the parity mechanism + success criterion', () => {
    const md = read(TEST_GENERATOR);
    expect(hasParityMechanism(md), 'parity step').toBe(true);
    expect(hasParitySuccessCriterion(md), 'success criterion').toBe(true);
  });
  it('T1.4 shared mocks (B0) precede and feed the batch (B0.2)', () => {
    expect(sharedMocksBeforeTestBatch(read(CONTINUE))).toBe(true);
  });
  it('T1.5 naming regex + output paths intact', () => {
    expect(specNameRegexIntact(read(NAMING)), 'spec regex').toBe(true);
    expect(testGeneratorOutputPaths(read(TEST_GENERATOR)), 'output paths').toBe(true);
  });
  it('T1.6 policy rules present', () => {
    const md = read(TEST_GENERATOR);
    expect(noVitestTagsNoFile(md), 'no-vitest-tags').toBe(true);
    expect(routableNeedsLiveTest(md), 'routable live test').toBe(true);
  });
});
