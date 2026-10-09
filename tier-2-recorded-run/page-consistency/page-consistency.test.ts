/**
 * Review pages share one look and one hand-back (deterministic — offline once Chromium is installed).
 *
 * The three review pages are authored live by the orchestrator LLM from one prose spec
 * (`.claude/shared/approval-pattern.md`) with NO shared stylesheet — so nothing but a test keeps their
 * look and their hand-back wording consistent across different specs and across page types. Once a live
 * capture is frozen into `fixtures/page-consistency/projectA|B/` (by `tier-3-automated/capture-page-consistency.ps1`
 * — NOT committed yet; the consistency block skips until then), the checks compare each page's COMPUTED-STYLE
 * fingerprint (see `helpers/page-chrome.ts`). Visual dimensions (button colour, card, heading) are compared
 * with TOLERANCES — "close enough" — so spec-compliant variation between two independent generations passes
 * while clear drift still fails; button labels and the hand-back message stay an EXACT match (fixed wording).
 *
 * Criterion 1 — two projects (A=minimal-concurrent, B=transactions) built from different specs get the
 *   same styling + same button label on epic-plan-review.html and stories-review.html, and the same
 *   epic-plan hand-back message.
 * Criterion 2 — the three pages in project A share one look, and the Approve/Done hand-back message matches.
 *
 * Fail-closed: the consistency block SKIPS in dev when the capture is absent, RED under
 * REQUIRE_PAGE_CONSISTENCY=1 (mirrors REQUIRE_REVIEW). A hand-back is only honoured when it was observed on
 * the CLICK (not lifted from shared source), so two pages can't "match" on prose both copied verbatim.
 * NOTE: the "share one look" assertions have been exercised against synthetic pages only; they first run on
 * REAL output when a live capture is frozen.
 *
 * The calibration block is independent: it runs off committed, hand-authored planted-bad fixtures
 * (`fixtures/page-consistency/calibration/`), proving every check family can actually fail — even on a
 * checkout with no live capture. BOTH blocks need a headless Chromium; when one can't launch (not installed)
 * they SKIP with an install hint rather than erroring, so the default suite stays green without it.
 */
import { describe, it, expect, beforeAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { fingerprintPages, lookOf, colorsClose, cardsClose, headingsClose, chromiumAvailable, type PageFingerprint } from '../../helpers/page-chrome';

// Probe once: can a headless Chromium actually launch here? If not, both blocks skip (install hint below)
// instead of throwing — otherwise `npm test` / `test:tier2` (which sweep this file in) would RED on any
// machine/CI without the browser. `npm run test:page-consistency` self-provisions it via its pretest hook.
const BROWSER_OK = await chromiumAvailable();
if (!BROWSER_OK) {
  // eslint-disable-next-line no-console
  console.warn('[page-consistency] headless Chromium not available — checks skipped. Run `npx playwright install chromium`.');
}

const SLOT = path.resolve(process.cwd(), 'fixtures', 'page-consistency');
const REQUIRE = /^(1|true|yes)$/i.test(process.env.REQUIRE_PAGE_CONSISTENCY ?? '');

/** First file matching `<projectDir>/epics/<any>/<leaf>`, or null. Slugs are discovered, not hard-coded. */
function underEpic(projectDir: string, leaf: string): string | null {
  const epics = path.join(projectDir, 'epics');
  if (!fs.existsSync(epics)) return null;
  for (const slug of fs.readdirSync(epics)) {
    const p = path.join(epics, slug, leaf);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

const A = path.join(SLOT, 'projectA');
const B = path.join(SLOT, 'projectB');
const files = {
  aEpicPlan: path.join(A, 'epic-plan-review.html'),
  aStories: underEpic(A, 'stories-review.html'),
  aManual: underEpic(A, 'manual-tests.html'),
  bEpicPlan: path.join(B, 'epic-plan-review.html'),
  bStories: underEpic(B, 'stories-review.html'),
};
const present = Object.values(files).every((f) => f && fs.existsSync(f));

// ── Prerequisite: the live capture ─────────────────────────────────────────────────────────────────
describe('page-consistency capture present', () => {
  (present || REQUIRE ? it : it.skip)(
    'the 5 captured pages exist in fixtures/page-consistency/ (run capture-page-consistency.ps1)',
    () => {
      expect(
        present,
        `missing capture — run: pwsh tier-3-automated/capture-page-consistency.ps1 -Phase setup … freeze\n` +
          Object.entries(files)
            .filter(([, f]) => !f || !fs.existsSync(f))
            .map(([k]) => `  - ${k}`)
            .join('\n')
      ).toBe(true);
    }
  );
});

if (!present) {
  // eslint-disable-next-line no-console
  console.warn('[page-consistency] capture slot absent — consistency checks skipped (set REQUIRE_PAGE_CONSISTENCY=1 to red)');
}

describe.skipIf(!present || !BROWSER_OK)('review pages share one look and one hand-back', () => {
  const fp: Record<string, PageFingerprint> = {};

  beforeAll(async () => {
    Object.assign(
      fp,
      await fingerprintPages({
        aEpicPlan: files.aEpicPlan!,
        aStories: files.aStories!,
        aManual: files.aManual!,
        bEpicPlan: files.bEpicPlan!,
        bStories: files.bStories!,
      })
    );
  }, 180_000);

  // ── Criterion 1: two projects, same page type — same styling + same fixed wording ──────────────────
  describe('criterion 1 — project A vs project B', () => {
    for (const pageType of ['EpicPlan', 'Stories'] as const) {
      const a = () => fp[`a${pageType}`];
      const b = () => fp[`b${pageType}`];
      const page = pageType === 'EpicPlan' ? 'epic-plan-review.html' : 'stories-review.html';

      describe(page, () => {
        it('main button is roughly the same colour (within tolerance)', () => {
          expect(lookOf(a()).buttonColor).not.toBeNull();
          expect(lookOf(b()).buttonColor).not.toBeNull();
          expect(colorsClose(lookOf(a()).buttonColor, lookOf(b()).buttonColor)).toBe(true);
        });
        it('cards are drawn roughly the same way (within tolerance)', () => {
          expect(lookOf(a()).card).not.toBeNull();
          expect(lookOf(b()).card).not.toBeNull();
          expect(cardsClose(lookOf(a()).card, lookOf(b()).card)).toBe(true);
        });
        it('page heading is roughly the same type (within tolerance)', () => {
          expect(lookOf(a()).heading).not.toBeNull();
          expect(lookOf(b()).heading).not.toBeNull();
          expect(headingsClose(lookOf(a()).heading, lookOf(b()).heading)).toBe(true);
        });
        it('buttons are labelled the same (exact)', () => {
          expect(a().primaryButton?.label).toBeTruthy();
          expect(a().primaryButton?.label).toBe(b().primaryButton?.label);
        });
      });
    }

    it('the epic-plan hand-back message is the same across projects', () => {
      expect(fp.aEpicPlan.handBackFromClick, 'A epic-plan confirmation was not observed on click').toBe(true);
      expect(fp.bEpicPlan.handBackFromClick, 'B epic-plan confirmation was not observed on click').toBe(true);
      expect(fp.aEpicPlan.handBackMessage).toBeTruthy();
      expect(fp.aEpicPlan.handBackMessage).toBe(fp.bEpicPlan.handBackMessage);
    });
  });

  // ── Criterion 2: the three pages in project A share one look + one hand-back ────────────────────────
  describe('criterion 2 — project A: manual-tests vs epic-plan', () => {
    it('main button is roughly the same colour (within tolerance)', () => {
      expect(lookOf(fp.aManual).buttonColor).not.toBeNull();
      expect(lookOf(fp.aEpicPlan).buttonColor).not.toBeNull();
      expect(colorsClose(lookOf(fp.aManual).buttonColor, lookOf(fp.aEpicPlan).buttonColor)).toBe(true);
    });
    it('cards are drawn roughly the same way (within tolerance)', () => {
      expect(lookOf(fp.aManual).card).not.toBeNull();
      expect(lookOf(fp.aEpicPlan).card).not.toBeNull();
      expect(cardsClose(lookOf(fp.aManual).card, lookOf(fp.aEpicPlan).card)).toBe(true);
    });
    it('page heading is roughly the same type (within tolerance)', () => {
      expect(lookOf(fp.aManual).heading).not.toBeNull();
      expect(lookOf(fp.aEpicPlan).heading).not.toBeNull();
      expect(headingsClose(lookOf(fp.aManual).heading, lookOf(fp.aEpicPlan).heading)).toBe(true);
    });
    it('the Approve hand-back message matches the Done hand-back message', () => {
      // Honoured only when BOTH confirmations were actually seen on click — never a match on shared source text.
      expect(fp.aEpicPlan.handBackFromClick, 'epic-plan confirmation was not observed on click').toBe(true);
      expect(fp.aManual.handBackFromClick, 'manual-tests confirmation was not observed on click').toBe(true);
      expect(fp.aEpicPlan.handBackMessage).toBeTruthy();
      expect(fp.aManual.handBackMessage).toBe(fp.aEpicPlan.handBackMessage);
    });
  });

  // ── Natural extension: all of A's pages share one look (the full "one look" claim) ─────────────────
  describe("criterion 2 (extended) — project A's stories page shares A’s look", () => {
    it('stories page shares A’s look (within tolerance)', () => {
      expect(lookOf(fp.aStories).buttonColor).not.toBeNull();
      expect(lookOf(fp.aStories).card).not.toBeNull();
      expect(lookOf(fp.aStories).heading).not.toBeNull();
      expect(colorsClose(lookOf(fp.aStories).buttonColor, lookOf(fp.aEpicPlan).buttonColor)).toBe(true);
      expect(cardsClose(lookOf(fp.aStories).card, lookOf(fp.aEpicPlan).card)).toBe(true);
      expect(headingsClose(lookOf(fp.aStories).heading, lookOf(fp.aEpicPlan).heading)).toBe(true);
    });
  });
});

// ── Calibration (committed; runs whenever Chromium is available): every check family must be able to FAIL. ──
const CAL = path.join(SLOT, 'calibration');
const calFiles = {
  baseline: path.join(CAL, 'baseline.html'),
  driftColour: path.join(CAL, 'drifted-colour.html'),
  driftCard: path.join(CAL, 'drifted-card.html'),
  driftHeading: path.join(CAL, 'drifted-heading.html'),
  driftLabel: path.join(CAL, 'drifted-label.html'),
  driftMessage: path.join(CAL, 'drifted-message.html'),
};

describe.skipIf(!BROWSER_OK)('calibration — the checks fail on drift (committed planted-bad fixtures)', () => {
  const cal: Record<string, PageFingerprint> = {};

  it('all calibration fixtures are present', () => {
    const missing = Object.entries(calFiles).filter(([, f]) => !fs.existsSync(f)).map(([k]) => k);
    expect(missing, `missing calibration fixtures: ${missing.join(', ')}`).toEqual([]);
  });

  beforeAll(async () => {
    const existing = Object.fromEntries(Object.entries(calFiles).filter(([, f]) => fs.existsSync(f)));
    if (Object.keys(existing).length === Object.keys(calFiles).length) {
      Object.assign(cal, await fingerprintPages(calFiles));
    }
  }, 120_000);

  // Each check also guards the BASELINE side as non-null, so a baseline-extraction failure can't make a
  // "drift is flagged" pass for the wrong reason (null vs value trivially compares not-close / not-equal).
  it('colour drift is flagged (button colour exceeds the colour tolerance)', () => {
    expect(lookOf(cal.baseline).buttonColor).not.toBeNull();
    expect(lookOf(cal.driftColour).buttonColor).not.toBeNull();
    expect(colorsClose(lookOf(cal.driftColour).buttonColor, lookOf(cal.baseline).buttonColor)).toBe(false);
  });
  it('card drift is flagged (card exceeds the card tolerances)', () => {
    expect(lookOf(cal.baseline).card).not.toBeNull();
    expect(lookOf(cal.driftCard).card).not.toBeNull();
    expect(cardsClose(lookOf(cal.driftCard).card, lookOf(cal.baseline).card)).toBe(false);
  });
  it('heading drift is flagged (heading exceeds the heading tolerances)', () => {
    expect(lookOf(cal.baseline).heading).not.toBeNull();
    expect(lookOf(cal.driftHeading).heading).not.toBeNull();
    expect(headingsClose(lookOf(cal.driftHeading).heading, lookOf(cal.baseline).heading)).toBe(false);
  });
  it('label drift is flagged (button label differs from baseline)', () => {
    expect(cal.baseline.primaryButton?.label).toBeTruthy();
    expect(cal.driftLabel.primaryButton?.label).toBeTruthy();
    expect(cal.driftLabel.primaryButton?.label).not.toBe(cal.baseline.primaryButton?.label);
  });
  it('message drift is flagged (hand-back differs from baseline, both seen on click)', () => {
    expect(cal.baseline.handBackFromClick).toBe(true);
    expect(cal.baseline.handBackMessage).toBeTruthy();
    expect(cal.driftMessage.handBackFromClick).toBe(true);
    expect(cal.driftMessage.handBackMessage).not.toBe(cal.baseline.handBackMessage);
  });
});
