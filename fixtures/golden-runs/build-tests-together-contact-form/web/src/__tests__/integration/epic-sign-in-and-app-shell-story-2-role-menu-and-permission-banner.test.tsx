/**
 * Story Metadata:
 * - Route: /inbox
 * - Target File: web/src/app/(authenticated)/layout.tsx
 *
 * Tests for Epic 1, Story 2: Role-based menu and permission-denied banner.
 *
 * The (authenticated) layout is an async server component, so these tests
 * render the two client components it composes:
 * - `AppNav` (`@/components/shell/AppNav`) — the role-scoped top menu, given the
 *   signed-in session (`SessionResponse`). It renders a single `<nav>` whose
 *   links are exactly the role's menu items; sign-out lives outside this nav.
 * - `PermissionDeniedBanner` (`@/components/shell/PermissionDeniedBanner`) — the
 *   in-page banner, given the missing permission name and the signed-in session.
 *   Its back link points at `session.landingPath` and is named after that page.
 *
 * These tests WILL FAIL until implemented (TDD red).
 */
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi, describe, it, expect, beforeEach } from 'vitest';

import { AppNav } from '@/components/shell/AppNav';
import { PermissionDeniedBanner } from '@/components/shell/PermissionDeniedBanner';
import { userInfoFor } from '@/mocks/data/identity';

vi.mock('@/lib/api/client', () => ({
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  del: vi.fn(),
}));

vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    refresh: vi.fn(),
    prefetch: vi.fn(),
    back: vi.fn(),
  }),
  usePathname: () => '/contact',
  useSearchParams: () => new URLSearchParams(),
}));

const menuItemNames = (navigation: HTMLElement): string[] =>
  within(navigation)
    .getAllByRole('link')
    .map((link) => link.textContent?.trim() ?? '');

describe('Epic 1, Story 2: Role-based menu and permission-denied banner', () => {
  beforeEach(() => vi.clearAllMocks());

  // AC-1
  it('shows a Visitor exactly Contact and My messages, with no Inbox item in any form', () => {
    render(<AppNav session={userInfoFor('Visitor')} />);

    const navigation = screen.getByRole('navigation');
    expect(menuItemNames(navigation)).toEqual(['Contact', 'My messages']);
    expect(within(navigation).getByRole('link', { name: 'Contact' })).toHaveAttribute(
      'href',
      '/contact',
    );
    expect(within(navigation).getByRole('link', { name: 'My messages' })).toHaveAttribute(
      'href',
      '/my-messages',
    );
    expect(within(navigation).queryByRole('link', { name: /inbox/i })).not.toBeInTheDocument();
    expect(within(navigation).queryByRole('button', { name: /inbox/i })).not.toBeInTheDocument();
    expect(screen.queryByText(/inbox/i)).not.toBeInTheDocument();
  });

  // AC-2
  it('shows a Support Agent and an Admin exactly Inbox, with no Contact or My messages item in any form', () => {
    for (const roleName of ['Support Agent', 'Admin']) {
      const { unmount } = render(<AppNav session={userInfoFor(roleName)} />);

      const navigation = screen.getByRole('navigation');
      expect(menuItemNames(navigation)).toEqual(['Inbox']);
      expect(within(navigation).getByRole('link', { name: 'Inbox' })).toHaveAttribute(
        'href',
        '/inbox',
      );
      expect(screen.queryByText(/contact/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/my messages/i)).not.toBeInTheDocument();
      expect(within(navigation).queryByRole('button')).not.toBeInTheDocument();

      unmount();
    }
  });

  // AC-5
  it('announces the banner on load and lets the keyboard reach its back link', async () => {
    const user = userEvent.setup();
    render(<PermissionDeniedBanner permission="View inbox" session={userInfoFor('Visitor')} />);

    const banner = screen.getByRole('alert');
    expect(banner).toHaveTextContent(/view inbox/i);

    const backLink = within(banner).getByRole('link', { name: /contact/i });
    expect(backLink).toHaveAttribute('href', '/contact');

    await user.tab();
    expect(backLink).toHaveFocus();
  });
});
