/**
 * Story Metadata:
 * - Route: /login
 * - Target File: web/src/app/login/page.tsx
 *
 * Mocking strategy:
 * - Backend calls are ALWAYS mocked — this spec never contacts a live backend
 *   (see testing-policy.md § "Playwright runs against mocks, never live").
 *   Intercept via: MSW (wired at web/src/mocks/, started by MockProvider when
 *   NEXT_PUBLIC_USE_MOCK_API=true). The MSW handlers compose the shared mock data
 *   (seededUsers / SEEDED_PASSWORD from mocks/data/user, userInfoFor from
 *   mocks/data/identity), so this spec authors no response bodies of its own.
 * - Implementation pattern this assumes:
 *   - Sign-in calls POST /auth/login from the browser through the API client, so the
 *     browser MSW worker answers it (401 INVALID_CREDENTIALS, 423 ACCOUNT_LOCKED,
 *     200 SessionResponse).
 *   - Per BR6 the idle (30 min) and absolute (12 h) session timers and the 15-minute
 *     lockout window are evaluated in the browser against Date.now()/browser timers,
 *     so page.clock drives them with the REAL configured durations — no test-only
 *     shortened durations in production code.
 *   - "Activity" that resets the idle timer includes pointer movement and key presses.
 *   - On expiry the app navigates to /login and shows a "session expired" message.
 *   - A failed sign-in clears the password field (Story 1 AC-2); the spec uses that to
 *     know each attempt has been processed.
 * - If the implementation diverges from these assumptions, this spec will not pass.
 *
 * E2E spec for Epic 1 (sign-in-and-app-shell), Story 3: Session timeouts and account lockout.
 * These tests WILL FAIL until implemented (TDD red).
 */
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
// Shared identity source — relative imports, not @/.
import { LANDING_PATH_BY_ROLE } from '../src/mocks/data/identity';
import { SEEDED_PASSWORD, seededUserFor } from '../src/mocks/data/user';

import type { Page } from '@playwright/test';

const WRONG_PASSWORD = 'not-the-password';
const WCAG_22_AA_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

const landingPathPattern = (landingPath: string) => new RegExp(`${landingPath}$`);

async function submitSignIn(page: Page, email: string, password: string): Promise<void> {
  await page.getByLabel(/^email/i).fill(email);
  await page.getByLabel(/^password/i).fill(password);
  await page.getByRole('button', { name: /sign in/i }).click();
}

async function submitFailedSignIn(page: Page, email: string, password: string): Promise<void> {
  await submitSignIn(page, email, password);
  await expect(page.getByLabel(/^password/i)).toHaveValue('');
}

const sessionExpiredMessage = (page: Page) => page.getByText(/session (has )?expired/i);

test.describe('Epic 1, Story 3: Session timeouts and account lockout', () => {
  test.beforeEach(async ({ context }) => {
    await context.clearCookies();
  });

  // AC-3
  test('a locked account can sign in with the correct password once 15 minutes have passed', async ({
    page,
  }) => {
    const agent = seededUserFor('Support Agent');
    await page.clock.install();
    await page.goto('/login');

    for (let attempt = 1; attempt <= 5; attempt += 1) {
      await submitFailedSignIn(page, agent.email, WRONG_PASSWORD);
    }
    const lockedAlert = page.getByRole('alert').filter({ hasText: /locked/i });
    await expect(lockedAlert).toBeVisible();
    await expect(lockedAlert).toContainText(/15 minutes/i);

    // Locked state is accessible.
    const { violations } = await new AxeBuilder({ page }).withTags(WCAG_22_AA_TAGS).analyze();
    expect(violations).toEqual([]);

    // Just short of the lockout window, the correct password is still refused.
    await page.clock.fastForward('14:00');
    await submitFailedSignIn(page, agent.email, SEEDED_PASSWORD);
    await expect(lockedAlert).toBeVisible();

    // Past the 15-minute lockout, the correct password signs in to the role's page.
    await page.clock.fastForward('01:05');
    await submitSignIn(page, agent.email, SEEDED_PASSWORD);
    await expect(page).toHaveURL(landingPathPattern(LANDING_PATH_BY_ROLE['Support Agent']));
  });

  // AC-4
  test('after 30 minutes with no activity, the user is returned to sign-in with a session-expired message', async ({
    page,
  }) => {
    const visitor = seededUserFor('Visitor');
    await page.clock.install();
    await page.goto('/login');
    await submitSignIn(page, visitor.email, SEEDED_PASSWORD);
    const landingPath = landingPathPattern(LANDING_PATH_BY_ROLE.Visitor);
    await expect(page).toHaveURL(landingPath);

    // Not yet idle for 30 minutes — still signed in.
    await page.clock.fastForward('29:00');
    await expect(page).toHaveURL(landingPath);
    await expect(sessionExpiredMessage(page)).toBeHidden();

    // Crossing the 30-minute idle limit ends the session.
    await page.clock.fastForward('01:05');
    await expect(page).toHaveURL(/\/login/);
    await expect(sessionExpiredMessage(page)).toBeVisible();

    // Session-expired state is accessible.
    const { violations } = await new AxeBuilder({ page }).withTags(WCAG_22_AA_TAGS).analyze();
    expect(violations).toEqual([]);
  });

  // AC-5
  test('a user who keeps working is still signed out with the session-expired message after 12 hours', async ({
    page,
  }) => {
    const admin = seededUserFor('Admin');
    await page.clock.install();
    await page.goto('/login');
    await submitSignIn(page, admin.email, SEEDED_PASSWORD);
    const landingPath = landingPathPattern(LANDING_PATH_BY_ROLE.Admin);
    await expect(page).toHaveURL(landingPath);

    // Stay active: 24 × 29 minutes = 11 h 36 min, with activity before each idle limit.
    for (let interval = 1; interval <= 24; interval += 1) {
      await page.clock.fastForward('29:00');
      await page.mouse.move(100 + interval, 200 + interval);
      await page.keyboard.press('Shift');
    }
    await expect(page).toHaveURL(landingPath);
    await expect(sessionExpiredMessage(page)).toBeHidden();

    // 24 min 30 s later: past the 12-hour cap, yet well inside the 30-minute idle window.
    await page.clock.fastForward('24:30');
    await expect(page).toHaveURL(/\/login/);
    await expect(sessionExpiredMessage(page)).toBeVisible();
  });
});
