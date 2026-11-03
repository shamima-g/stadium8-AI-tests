/**
 * Story Metadata:
 * - Route: /inbox
 * - Target File: web/src/app/(authenticated)/layout.tsx
 *
 * Mocking strategy:
 * - Backend calls are ALWAYS mocked — a Playwright spec never contacts a live
 *   backend (see testing-policy.md § "Playwright runs against mocks, never live").
 *   Intercept via: page.route() — the project is mock-only (auth simulated, PI-01).
 *   - `**\/auth/login`, `**\/auth/session` and `**\/auth/logout` are fulfilled with
 *     bodies from the shared identity source (`userInfoFor(role)`); the session
 *     endpoint answers 401 until the mocked login succeeds, then 200 for that role.
 *   - Service workers are blocked so the app's MSW worker cannot answer these
 *     calls ahead of page.route() (Playwright does not see requests a service
 *     worker serves).
 * - Implementation pattern this assumes:
 *   - The user signs in through the real /login form ("Email", "Password",
 *     "Sign in" button) using the seeded mock account (`visitor@example.com` /
 *     `agent@example.com` with the mock-only seeded password).
 *   - Any browser-side auth call goes through the API client to `/auth/*`, so
 *     page.route() can intercept it; a server-side simulated user store that
 *     accepts the same seeded accounts also satisfies this spec.
 *   - The session survives a direct page.goto() to another app page (the session
 *     cookie set on login, or a fresh GET /auth/session on load).
 *   - The permission-denied banner renders with role="alert", names the missing
 *     permission, and holds one link to the user's landing page named after it.
 * - If the implementation diverges from these assumptions, this spec will not pass.
 *
 * E2E spec for Epic 1, Story 2: Role-based menu and permission-denied banner.
 * These tests WILL FAIL until implemented (TDD red).
 */
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// Shared identity + seeded mock accounts — relative imports, not @/.
import { userInfoFor } from '../src/mocks/data/identity';
import { SEEDED_PASSWORD, seededUserFor } from '../src/mocks/data/user';

import type { Page } from '@playwright/test';
import type { Role } from '../src/types/api-generated';

const WCAG_22_AA_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

/**
 * Mock the auth chain at the browser boundary for one role. Install before navigating.
 */
async function mockAuthChain(page: Page, roleName: Role): Promise<void> {
  let signedIn = false;

  await page.route('**/auth/login', (route) => {
    signedIn = true;
    return route.fulfill({
      status: 200,
      headers: { 'set-cookie': 'session=mock-token; Path=/; HttpOnly; SameSite=Strict' },
      contentType: 'application/json',
      body: JSON.stringify(userInfoFor(roleName)),
    });
  });

  await page.route('**/auth/session', (route) =>
    signedIn
      ? route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(userInfoFor(roleName)),
        })
      : route.fulfill({
          status: 401,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'No active session', code: 'UNAUTHENTICATED' }),
        }),
  );

  await page.route('**/auth/logout', (route) => {
    signedIn = false;
    return route.fulfill({ status: 204 });
  });
}

async function signInAs(page: Page, roleName: Role): Promise<void> {
  const seededUser = seededUserFor(roleName);
  await mockAuthChain(page, roleName);

  await page.goto('/login');
  await page.getByLabel(/^email$/i).fill(seededUser.email);
  await page.getByLabel(/^password$/i).fill(SEEDED_PASSWORD);
  await page.getByRole('button', { name: /sign in/i }).click();

  await expect(page).toHaveURL(new RegExp(`${userInfoFor(roleName).landingPath}$`));
}

const permissionDeniedBanner = (page: Page) =>
  page.getByRole('alert').filter({ hasText: /permission/i });

test.describe('Epic 1, Story 2: Role-based menu and permission-denied banner', () => {
  test.use({ serviceWorkers: 'block' });

  test.beforeEach(async ({ context }) => {
    await context.clearCookies();
  });

  // AC-3
  test('a Visitor opening /inbox directly sees the banner naming the missing permission and is linked back to Contact', async ({
    page,
  }) => {
    await signInAs(page, 'Visitor');

    await page.goto('/inbox');
    await expect(page).toHaveURL(/\/inbox$/);

    const banner = permissionDeniedBanner(page);
    await expect(banner).toBeVisible();
    await expect(banner).toContainText(/view inbox/i);
    await expect(page.getByText(/\b403\b/)).toHaveCount(0);

    const { violations } = await new AxeBuilder({ page }).withTags(WCAG_22_AA_TAGS).analyze();
    expect(violations).toEqual([]);

    await banner.getByRole('link', { name: /contact/i }).click();
    await expect(page).toHaveURL(/\/contact$/);
    await expect(permissionDeniedBanner(page)).toHaveCount(0);
  });

  // AC-4
  test('a Support Agent opening /contact or /my-messages directly sees the banner and is linked back to the Inbox', async ({
    page,
  }) => {
    await signInAs(page, 'Support Agent');

    await page.goto('/my-messages');
    await expect(page).toHaveURL(/\/my-messages$/);
    const myMessagesBanner = permissionDeniedBanner(page);
    await expect(myMessagesBanner).toBeVisible();
    await expect(myMessagesBanner).toContainText(/view my messages/i);
    await expect(myMessagesBanner.getByRole('link', { name: /inbox/i })).toHaveAttribute(
      'href',
      '/inbox',
    );

    await page.goto('/contact');
    await expect(page).toHaveURL(/\/contact$/);
    const contactBanner = permissionDeniedBanner(page);
    await expect(contactBanner).toBeVisible();
    await expect(contactBanner).toContainText(/submit an enquiry/i);

    await contactBanner.getByRole('link', { name: /inbox/i }).click();
    await expect(page).toHaveURL(/\/inbox$/);
    await expect(permissionDeniedBanner(page)).toHaveCount(0);
  });
});
