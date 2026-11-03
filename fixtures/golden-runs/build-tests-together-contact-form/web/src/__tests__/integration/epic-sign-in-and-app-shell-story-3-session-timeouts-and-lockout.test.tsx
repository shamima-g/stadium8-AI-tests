/**
 * Story Metadata:
 * - Route: /login
 * - Target File: web/src/app/login/page.tsx
 *
 * Tests for Epic 1 (sign-in-and-app-shell), Story 3: Session timeouts and account lockout.
 * Covers the lockout messaging on the sign-in screen (AC-1, AC-2). The time-driven
 * flows (lockout expiry, idle and absolute session timeouts) live in the Playwright spec.
 * These tests WILL FAIL until implemented (TDD red).
 */
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi, describe, it, expect, beforeEach } from 'vitest';
// Import based on Story Metadata Target File — will fail until implemented (TDD red)
import LoginPage from '@/app/login/page';
import { get, post } from '@/lib/api/client';
// Project-wide identity source — never re-define seeded users here.
import { SEEDED_PASSWORD, seededUserFor } from '@/mocks/data/user';
import type { APIError } from '@/types/api';

vi.mock('@/lib/api/client', () => ({
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  del: vi.fn(),
  apiClient: vi.fn(),
}));

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), refresh: vi.fn(), back: vi.fn() }),
  usePathname: () => '/login',
  useSearchParams: () => new URLSearchParams(),
  redirect: vi.fn(),
}));

const mockGet = get as ReturnType<typeof vi.fn>;
const mockPost = post as ReturnType<typeof vi.fn>;

const LOCKOUT_DURATION_MS = 15 * 60 * 1000;
const WRONG_PASSWORD = 'not-the-password';

/** The API client's rejection for a wrong email/password (spec: 401 INVALID_CREDENTIALS). */
const invalidCredentialsError = (): APIError => ({
  message: 'Unauthorized: Please log in to continue',
  statusCode: 401,
  details: ['Wrong email or password'],
  endpoint: '/auth/login',
});

/** The API client's rejection for a locked account (spec: 423 ACCOUNT_LOCKED; details carry the lockout end). */
const accountLockedError = (lockedUntil: Date): APIError => ({
  message: 'Account locked',
  statusCode: 423,
  details: [lockedUntil.toISOString()],
  endpoint: '/auth/login',
});

type UserEventInstance = ReturnType<typeof userEvent.setup>;

async function submitSignIn(user: UserEventInstance, email: string, password: string) {
  const emailField = screen.getByLabelText(/^email/i);
  await user.clear(emailField);
  await user.type(emailField, email);
  const passwordField = screen.getByLabelText(/^password/i);
  await user.clear(passwordField);
  await user.type(passwordField, password);
  await user.click(screen.getByRole('button', { name: /sign in/i }));
}

/** A failed sign-in has been processed once the password field is cleared (Story 1 AC-2). */
async function waitForFailedAttemptProcessed() {
  await waitFor(() => {
    expect(screen.getByLabelText(/^password/i)).toHaveValue('');
  });
}

describe('Epic 1, Story 3: Account lockout on the sign-in screen', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // No active session while on the sign-in screen.
    mockGet.mockRejectedValue({
      message: 'Unauthorized: Please log in to continue',
      statusCode: 401,
      details: ['No active session'],
      endpoint: '/auth/session',
    } satisfies APIError);
  });

  // AC-1
  it('says the account is locked for 15 minutes on the 5th consecutive failed sign-in', async () => {
    const user = userEvent.setup();
    const agentEmail = seededUserFor('Support Agent').email;
    mockPost
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(accountLockedError(new Date(Date.now() + LOCKOUT_DURATION_MS)));

    render(<LoginPage />);

    for (let attempt = 1; attempt <= 4; attempt += 1) {
      await submitSignIn(user, agentEmail, WRONG_PASSWORD);
      await waitForFailedAttemptProcessed();
    }
    // After four failures the account is not yet locked — the wrong-credentials error shows.
    expect(screen.getByRole('alert')).toHaveTextContent(/incorrect/i);
    expect(screen.getByRole('alert')).not.toHaveTextContent(/locked/i);

    await submitSignIn(user, agentEmail, WRONG_PASSWORD);

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/locked/i);
    });
    expect(screen.getByRole('alert')).toHaveTextContent(/15 minutes/i);
  });

  // AC-2
  it('refuses the correct password while the account is locked and shows the locked message again', async () => {
    const user = userEvent.setup();
    const adminEmail = seededUserFor('Admin').email;
    const lockedUntil = new Date(Date.now() + LOCKOUT_DURATION_MS);
    mockPost
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(invalidCredentialsError())
      .mockRejectedValueOnce(accountLockedError(lockedUntil))
      .mockRejectedValueOnce(accountLockedError(lockedUntil));

    render(<LoginPage />);

    for (let attempt = 1; attempt <= 5; attempt += 1) {
      await submitSignIn(user, adminEmail, WRONG_PASSWORD);
      await waitForFailedAttemptProcessed();
    }
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/locked/i);
    });

    await submitSignIn(user, adminEmail, SEEDED_PASSWORD);
    await waitForFailedAttemptProcessed();

    // Still on the sign-in screen, with the locked message rather than a successful sign-in.
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent(/locked/i);
  });
});
