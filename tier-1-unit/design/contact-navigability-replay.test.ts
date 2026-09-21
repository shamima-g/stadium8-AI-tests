/**
 * Navigability replay (AC3) over the real contact-form-design run — two-sided.
 *
 * A small single-page design build (one screen "Contact" at "/") captured from a real workflow run
 * into fixtures/design-capture/contact/. The PASS block runs the real helpers over the good capture;
 * the FAIL block mutates the same benchmark by one thing to prove each check goes RED on a bad run.
 * Both sides are driven by the benchmark's own truth in answers.json — the expected screens
 * (designReadback.screensExpected), the stated primary colour (intake.styling), the surfaced
 * uncertainty, and the screen→route map (navigability.screenRoutes).
 *
 * (The generic helper good/broken cases live in design-traces.test.ts; this file pins the checks
 * against THIS benchmark's real data.)
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import {
  digestReadyForIntake,
  digestSections,
  screenNames,
  appRoutePaths,
  unroutedScreens,
  surfacesUncertainty,
} from '../../helpers/design-digest';

const FIX = path.resolve(__dirname, '..', '..', 'fixtures', 'design-capture', 'contact');
const digest = fs.readFileSync(path.join(FIX, 'digest.md'), 'utf8');
const routeFiles = fs
  .readFileSync(path.join(FIX, 'app-routes.txt'), 'utf8')
  .split(/\r?\n/)
  .map((l) => l.trim())
  .filter(Boolean);

const answers = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, '..', '..', 'benchmark-files', 'contact-form-design', 'answers.json'),
    'utf8',
  ),
) as {
  navigability: { screenRoutes: Record<string, string> };
  intake: { styling: string };
  designReadback: { screensExpected: string[] };
};

// The benchmark's stated primary colour ("… primary #2563eb …") and the digest's actual primary,
// so a build that invents a different palette is caught.
const benchPrimary = (answers.intake.styling.match(/primary[^#]*(#[0-9a-f]{6})/i)?.[1] ?? '').toLowerCase();
const digestPrimary = (md: string): string =>
  ((digestSections(md)['Palette & Typography'] ?? '').match(/primary[^#\n]*(#[0-9a-f]{6})/i)?.[1] ?? '').toLowerCase();

describe('contact-form-design replay — good run (#14/AC3)', () => {
  it('design-digest-written: the intake digest is a filled read-back with a real uncertainty', () => {
    const r = digestReadyForIntake(digest);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.realScreens).toBe(1);
    expect(r.realUncertainties, 'surfaced ≥1 real uncertainty').toBeGreaterThanOrEqual(1);
  });

  it('design-uncertainties-surfaced: it flagged where the submitted message goes (no backend)', () => {
    expect(surfacesUncertainty(digest, /message go|sent anywhere|front-end only|backend/i)).toBe(true);
  });

  it('screens: the digest covers exactly the benchmark-expected screens', () => {
    expect(screenNames(digest)).toEqual(answers.designReadback.screensExpected); // ["Contact"]
  });

  it('palette: the digest carries the benchmark primary colour, not an invented one', () => {
    expect(benchPrimary, 'benchmark states a primary hex').toMatch(/^#[0-9a-f]{6}$/);
    expect(digestPrimary(digest), 'digest primary matches the benchmark').toBe(benchPrimary);
  });

  it('navigability: every designed screen has a live route — the user can move through it', () => {
    const routes = appRoutePaths(routeFiles);
    expect(routes, 'the built app serves exactly the / route').toEqual(['/']);
    const unrouted = unroutedScreens(answers.navigability.screenRoutes, routes);
    expect(unrouted, `screens with nowhere to live: ${unrouted.join(', ')}`).toEqual([]);
  });
});

/**
 * Fail cases — the same benchmark, deliberately broken by ONE change, to prove each check goes RED
 * on a bad run (not just green on the good one). Each mutates the REAL captured digest or uses the
 * REAL answers.json, so they are benchmark-driven, not synthetic. (Generic missing-section /
 * placeholder-screen breakage is already covered in design-traces.test.ts.)
 */
describe('contact-form-design replay — fail cases (benchmark-driven teeth)', () => {
  it('uncertainty-hidden: dropping the "where the message goes" note is caught (AC5 teeth)', () => {
    const hidden = digest.replace(/\n## Uncertainties[\s\S]*$/, '\n## Uncertainties\n\n- none\n');
    expect(surfacesUncertainty(hidden, /message go|sent anywhere|front-end only|backend/i)).toBe(false);
    expect(digestReadyForIntake(hidden).realUncertainties, 'no real uncertainty items').toBe(0);
  });

  it('palette: a build that used a different colour than the benchmark is caught', () => {
    const wrong = digest.replace(new RegExp(benchPrimary, 'gi'), '#ff0000');
    expect(digestPrimary(wrong), 'the invented colour no longer matches the benchmark').not.toBe(benchPrimary);
  });

  it('screens: a digest missing a benchmark-expected screen is caught', () => {
    const renamed = digest.replace('### Contact', '### Feedback');
    expect(screenNames(renamed)).not.toEqual(answers.designReadback.screensExpected);
  });

  it('navigability: a designed screen the build never served is caught (real map, no built routes)', () => {
    // The benchmark's own screen→route map ({ Contact: "/" }), but the built app served no routes —
    // e.g. the build failed to produce the page. The one designed screen is then homeless.
    expect(unroutedScreens(answers.navigability.screenRoutes, [])).toEqual(['Contact']);
  });

  it('navigability teeth: an extra designed screen with no route is caught', () => {
    expect(unroutedScreens({ Contact: '/', Privacy: '/privacy' }, appRoutePaths(routeFiles))).toEqual(['Privacy']);
  });
});
