/**
 * Epic baseline: sign-in-and-app-shell
 *
 * Cross-story invariants for the authenticated app shell introduced in Story 1
 * (web/src/app/(authenticated)/layout.tsx renders the shell around every app page).
 * Later stories in this epic extend this file only with genuinely new shared-surface
 * invariants; they do not re-assert these.
 *
 * Shell under test: web/src/components/shell/AppShell.tsx — a component taking the
 * signed-in `session` (the SessionResponse from /auth/session) and the page content.
 * These tests WILL FAIL until implemented (TDD red).
 */
import { render, screen, within } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';

import { AppShell } from '@/components/shell/AppShell';
import { userInfoFor } from '@/mocks/data/identity';

vi.mock('@/lib/api/client', () => ({ get: vi.fn(), post: vi.fn() }));

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), refresh: vi.fn() }),
  usePathname: () => '/',
  useSearchParams: () => new URLSearchParams(),
}));

describe('Epic sign-in-and-app-shell baseline: authenticated app shell', () => {
  // Runtime-only: the (authenticated) layout composing this shell around every page is verified during manual checklist
  // AC-5 (Story 1)
  it.each(['Visitor', 'Support Agent', 'Admin'])(
    'gives a signed-in %s a Sign out control alongside the page content',
    (roleName) => {
      render(
        <AppShell session={userInfoFor(roleName)}>
          <section aria-label="Page content">Landing page body</section>
        </AppShell>,
      );

      const pageContent = screen.getByRole('region', { name: 'Page content' });
      expect(within(pageContent).getByText('Landing page body')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /sign out/i })).toBeInTheDocument();
    },
  );
});
