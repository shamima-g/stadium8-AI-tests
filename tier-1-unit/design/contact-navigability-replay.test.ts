/**
 * Navigability replay (AC3) over the real contact-form-design run.
 *
 * A small single-page design build (one screen "Contact" at "/") captured from a real workflow run
 * into fixtures/design-capture/contact/. This runs the real helpers over it: the digest is a filled
 * read-back with surfaced uncertainties, and — the AC3 point — every designed screen has a live
 * route, so the user can move through the app. The screen→route map is the benchmark's own
 * (answers.json navigability.screenRoutes); the routes are the built app's real page files.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import {
  digestReadyForIntake,
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
) as { navigability: { screenRoutes: Record<string, string> } };

describe('contact-form-design replay — navigability (#14/AC3)', () => {
  it('design-digest-written: the intake digest is a filled read-back with a real uncertainty', () => {
    const r = digestReadyForIntake(digest);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.realScreens).toBe(1);
    expect(r.realUncertainties, 'surfaced ≥1 real uncertainty').toBeGreaterThanOrEqual(1);
  });

  it('design-uncertainties-surfaced: it flagged where the submitted message goes (no backend)', () => {
    expect(surfacesUncertainty(digest, /message go|sent anywhere|front-end only|backend/i)).toBe(true);
  });

  it('navigability: every designed screen has a live route — the user can move through it', () => {
    const screens = screenNames(digest);
    expect(screens, 'the one designed screen').toEqual(['Contact']);

    const routes = appRoutePaths(routeFiles);
    expect(routes, 'the built app serves exactly the / route').toEqual(['/']);

    // The benchmark's authored screen→route map, checked against the REAL built routes.
    const unrouted = unroutedScreens(answers.navigability.screenRoutes, routes);
    expect(unrouted, `screens with nowhere to live: ${unrouted.join(', ')}`).toEqual([]);
  });

  it('navigability teeth: the check would catch a designed screen with no route', () => {
    const routes = appRoutePaths(routeFiles); // ['/']
    expect(unroutedScreens({ Contact: '/', Privacy: '/privacy' }, routes)).toEqual(['Privacy']);
  });
});
