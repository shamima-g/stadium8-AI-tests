/**
 * Story Metadata:
 * - Route: /login
 * - Target File: web/src/app/(authenticated)/layout.tsx
 *
 * Mocking strategy:
 * - Backend calls are ALWAYS mocked — this spec never contacts a live backend
 *   (testing-policy.md § "Playwright runs against mocks, never live"). The project
 *   is mock-only (project.md §Data Source): there is no backend at all.
 *   Intercept via: MSW (web/src/mocks/ is wired — MockProvider starts the browser
 *   worker when NEXT_PUBLIC_USE_MOCK_API=true, set in web/.env.local).
 *   - The MSW handlers in web/src/mocks/handlers.ts answer /auth/login, /auth/session
 *     and /auth/logout from the shared seeded users and `userInfoFor(role)`, so the
 *     spec installs no page.route() of its own and authors no response bodies.
 *   - Form-fill identities come from the shared seed (../src/mocks/data/user) and the
 *     expected landing pages from ../src/mocks/data/identity — never hard-coded.
 * - Implementation pattern this assumes:
 *   - The sign-in form is a client component that calls `login()` from the browser
 *     through the API client (so MSW intercepts it), and must not submit before
 *     the MSW worker has started.
 *   - A successful sign-in leaves a same-origin `session` cookie that the
 *     (authenticated) layout checks server-side; with no session, every app page
 *     (including `/`) redirects to /login.
 *   - Sign-out is a "Sign out" button in the authenticated shell that clears the
 *     session cookie and lands on /login; protected pages must not be restorable
 *     from the browser's back/forward cache once signed out.
 * - If the implementation diverges from these assumptions, this spec will not pass.
 *
 * E2E spec for Epic sign-in-and-app-shell, Story 1: Sign in, land on your page, and sign out.
 * These tests WILL FAIL until implemented (TDD red).
 */
import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

import { LANDING_PATH_BY_ROLE } from '../src/mocks/data/identity';
import { SEEDED_PASSWORD, seededUserFor } from '../src/mocks/data/user';

import type { Page } from '@playwright/test';
import type { Role } from '../src/types/api-generated';

/** NFR-base-1: WCAG 2.2 Level AA. */
const WCAG_22_AA_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

const SEEDED_ROLES: readonly Role[] = ['Visitor', 'Support Agent', 'Admin'];

const pathnameIs = (expectedPathname: string) => (url: URL) =>
  url.pathname === expectedPathname;

const signInHeading = (page: Page) => page.getByRole('heading', { name: /sign in/i });

async function signInAs(page: Page, role: Role): Promise<void> {
  await page.goto('/login');
  await expect(signInHeading(page)).toBeVisible();
  await page.getByLabel(/^email/i).fill(seededUserFor(role).email);
  await page.getByLabel(/^password/i).fill(SEEDED_PASSWORD);
  await page.getByRole('button', { name: /sign in/i }).click();
}

test.describe('Epic sign-in-and-app-shell, Story 1: Sign in, land on your page, and sign out', () => {
  test.beforeEach(async ({ context }) => {
    await context.clearCookies();
  });

  // AC-1
  test('each seeded account lands on its role page after signing in', async ({ browser }) => {
    for (const role of SEEDED_ROLES) {
      const context = await browser.newContext();
      const page = await context.newPage();

      await signInAs(page, role);
      await expect(page).toHaveURL(pathnameIs(LANDING_PATH_BY_ROLE[role]));

      await context.close();
    }
  });

  // AC-4
  test('a signed-out user opening any app URL, including the root, is sent to sign-in', async ({
    page,
  }) => {
    for (const appPath of ['/', '/contact', '/my-messages', '/inbox']) {
      await page.goto(appPath);
      await expect(page).toHaveURL(pathnameIs('/login'));
      await expect(signInHeading(page)).toBeVisible();
      await expect(page.getByRole('heading', { name: 'Welcome' })).toBeHidden();
    }
  });

  // AC-5
  test('after signing out, the Back button returns to sign-in rather than the previous app page', async ({
    page,
  }) => {
    await signInAs(page, 'Visitor');
    await expect(page).toHaveURL(pathnameIs(LANDING_PATH_BY_ROLE.Visitor));

    await page.getByRole('button', { name: /sign out/i }).click();
    await expect(page).toHaveURL(pathnameIs('/login'));
    await expect(signInHeading(page)).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(pathnameIs('/login'));
    await expect(signInHeading(page)).toBeVisible();
    await expect(page.getByRole('button', { name: /sign out/i })).toBeHidden();
  });

  // AC-6
  test('the sign-in screen is accessible, labelled and completable with the keyboard alone', async ({
    page,
  }) => {
    const emailField = page.getByLabel(/^email/i);
    const passwordField = page.getByLabel(/^password/i);
    const signInButton = page.getByRole('button', { name: /sign in/i });

    // Default state: settled, labelled, no violations.
    await page.goto('/login');
    await expect(signInHeading(page)).toBeVisible();
    await expect(emailField).toBeVisible();
    await expect(passwordField).toBeVisible();
    await expect(passwordField).toHaveAttribute('type', 'password');
    const defaultScan = await new AxeBuilder({ page }).withTags(WCAG_22_AA_TAGS).analyze();
    expect(defaultScan.violations).toEqual([]);

    // Error state: a wrong-password submit shows the error summary with no violations.
    await emailField.fill(seededUserFor('Visitor').email);
    await passwordField.fill(`${SEEDED_PASSWORD}-wrong`);
    await signInButton.click();
    await expect(page.getByRole('alert').filter({ hasText: /incorrect/i })).toBeVisible();
    const errorScan = await new AxeBuilder({ page }).withTags(WCAG_22_AA_TAGS).analyze();
    expect(errorScan.violations).toEqual([]);

    // Keyboard only: Tab to each field, type, and submit with Enter.
    await page.goto('/login');
    await expect(signInHeading(page)).toBeVisible();
    await page.keyboard.press('Tab');
    await expect(emailField).toBeFocused();
    await page.keyboard.type(seededUserFor('Support Agent').email);
    await page.keyboard.press('Tab');
    await expect(passwordField).toBeFocused();
    await page.keyboard.type(SEEDED_PASSWORD);
    await page.keyboard.press('Tab');
    await expect(signInButton).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL(pathnameIs(LANDING_PATH_BY_ROLE['Support Agent']));
  });
});
