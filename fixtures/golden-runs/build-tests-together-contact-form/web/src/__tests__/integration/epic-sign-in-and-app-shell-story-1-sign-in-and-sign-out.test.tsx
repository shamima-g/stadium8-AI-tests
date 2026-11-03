/**
 * Story Metadata:
 * - Route: /login
 * - Target File: web/src/app/(authenticated)/layout.tsx
 * - Sign-in screen under test: web/src/app/login/page.tsx (default export, renderable
 *   in jsdom; its form calls `login()` from @/lib/api/endpoints, i.e.
 *   `post('/auth/login', ...)` through the API client)
 *
 * Epic sign-in-and-app-shell, Story 1: Sign in, land on your page, and sign out.
 * Covers the sign-in failure states (wrong credentials vs connection problem).
 * These tests WILL FAIL until implemented (TDD red).
 */
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi, describe, it, expect, beforeEach } from 'vitest';

import LoginPage from '@/app/login/page';
import { post } from '@/lib/api/client';
import { SEEDED_PASSWORD, seededUserFor } from '@/mocks/data/user';
import type { APIError } from '@/types/api';

vi.mock('@/lib/api/client', () => ({ get: vi.fn(), post: vi.fn() }));

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), refresh: vi.fn() }),
  usePathname: () => '/login',
  useSearchParams: () => new URLSearchParams(),
  redirect: vi.fn(),
}));

const mockPost = post as ReturnType<typeof vi.fn>;

/** The error the API client throws when /auth/login answers 401 (wrong email or password). */
const wrongCredentialsError: APIError = {
  message: 'Unauthorized: Please log in to continue',
  statusCode: 401,
  details: ['Your session may have expired. Please log in again.'],
  endpoint: '/auth/login',
};

/** The error the API client throws when the sign-in service cannot be reached. */
const connectionFailureError: APIError = {
  message: 'Network error: Unable to connect to the API server',
  statusCode: 0,
  details: ['Please check your internet connection and try again.'],
  endpoint: '/auth/login',
};

const visitor = seededUserFor('Visitor');

async function submitSignIn(email: string, password: string) {
  const user = userEvent.setup();
  render(<LoginPage />);
  await user.type(screen.getByLabelText(/^email/i), email);
  await user.type(screen.getByLabelText(/^password/i), password);
  await user.click(screen.getByRole('button', { name: /sign in/i }));
}

describe('Epic sign-in-and-app-shell, Story 1: sign-in failures', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // AC-2
  it('shows an inline wrong-credentials error, keeps the email, clears the password and focuses the error summary', async () => {
    mockPost.mockRejectedValue(wrongCredentialsError);

    await submitSignIn(visitor.email, 'NotTheRightPassword1');

    const errorSummary = await screen.findByRole('alert');
    expect(errorSummary).toHaveTextContent(/email or password is incorrect/i);
    await waitFor(() => {
      expect(errorSummary).toHaveFocus();
    });
    expect(screen.getByLabelText(/^email/i)).toHaveValue(visitor.email);
    expect(screen.getByLabelText(/^password/i)).toHaveValue('');
  });

  // AC-3
  it('shows a connection-problem error, distinct from the wrong-credentials error, when the sign-in service cannot be reached', async () => {
    mockPost.mockRejectedValue(connectionFailureError);

    await submitSignIn(visitor.email, SEEDED_PASSWORD);

    const errorSummary = await screen.findByRole('alert');
    expect(errorSummary).toHaveTextContent(/connection/i);
    expect(errorSummary).not.toHaveTextContent(/email or password is incorrect/i);
  });
});
