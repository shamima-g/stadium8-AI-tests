/**
 * MSW Mock Handlers
 *
 * AUTO-GENERATED from generated-docs/specs/api-spec.yaml
 * by mock-setup-agent. Editable — /api-mock-refresh does smart
 * partial updates and will not overwrite handlers you have
 * customised, as long as the endpoint signature is unchanged.
 *
 * Regenerate with: /api-mock-refresh
 */

import { http, HttpResponse } from 'msw';

import { API_BASE_URL } from '@/lib/utils/constants';
import { seededEnquiries } from '@/mocks/data/enquiry';
import { userInfoFor } from '@/mocks/data/identity';
import { SEEDED_PASSWORD, seededUsers } from '@/mocks/data/user';
import { paginateByOffset, readScalarParam } from '@/mocks/handler-utils';
import type { ErrorResponse, User } from '@/types/api-generated';

const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000;

let signedInUser: User | null = null;
const failedAttemptsByEmail = new Map<string, number>();
const lockedUntilByEmail = new Map<string, number>();

const errorBody = (error: string, code: string, details?: string[]): ErrorResponse => ({
  error,
  code,
  ...(details ? { details } : {}),
});

const unauthenticated = () =>
  HttpResponse.json(errorBody('Authentication required', 'UNAUTHENTICATED'), { status: 401 });

export const handlers = [
  http.post(`${API_BASE_URL}/auth/login`, async ({ request }) => {
    const body = (await request.json().catch(() => null)) as {
      email?: string;
      password?: string;
    } | null;
    if (!body?.email || !body.password) {
      return HttpResponse.json(
        errorBody('Email and password are required', 'VALIDATION_ERROR'),
        { status: 400 },
      );
    }

    const email = body.email.trim().toLowerCase();
    const lockedUntil = lockedUntilByEmail.get(email);
    if (lockedUntil && lockedUntil > Date.now()) {
      return HttpResponse.json(
        errorBody('Account locked', 'ACCOUNT_LOCKED', [new Date(lockedUntil).toISOString()]),
        { status: 423 },
      );
    }

    const matchedUser = seededUsers.find((user) => user.email === email);
    if (!matchedUser || body.password !== SEEDED_PASSWORD) {
      const failedAttempts = (failedAttemptsByEmail.get(email) ?? 0) + 1;
      failedAttemptsByEmail.set(email, failedAttempts);
      if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
        const lockoutEnd = Date.now() + LOCKOUT_DURATION_MS;
        lockedUntilByEmail.set(email, lockoutEnd);
        failedAttemptsByEmail.delete(email);
        return HttpResponse.json(
          errorBody('Account locked', 'ACCOUNT_LOCKED', [new Date(lockoutEnd).toISOString()]),
          { status: 423 },
        );
      }
      return HttpResponse.json(
        errorBody('Wrong email or password', 'INVALID_CREDENTIALS'),
        { status: 401 },
      );
    }

    failedAttemptsByEmail.delete(email);
    lockedUntilByEmail.delete(email);
    signedInUser = matchedUser;
    return HttpResponse.json(userInfoFor(matchedUser.role));
  }),

  http.post(`${API_BASE_URL}/auth/logout`, () => {
    if (!signedInUser) return unauthenticated();
    signedInUser = null;
    return new HttpResponse(null, { status: 204 });
  }),

  http.get(`${API_BASE_URL}/auth/session`, () => {
    if (!signedInUser) {
      return HttpResponse.json(errorBody('No active session', 'UNAUTHENTICATED'), { status: 401 });
    }
    return HttpResponse.json(userInfoFor(signedInUser.role));
  }),

  http.get(`${API_BASE_URL}/enquiries`, ({ request }) => {
    if (!signedInUser) return unauthenticated();

    const url = new URL(request.url);
    const status = readScalarParam(url, 'status');
    const category = readScalarParam(url, 'category');

    let results = [...seededEnquiries];
    if (signedInUser.role === 'Visitor') {
      const visitorEmail = signedInUser.email;
      results = results.filter((enquiry) => enquiry.submittedByEmail === visitorEmail);
    }
    if (status) results = results.filter((enquiry) => enquiry.status === status);
    if (category) results = results.filter((enquiry) => enquiry.category === category);

    const { slice, total, limit, offset } = paginateByOffset(results, url);
    return HttpResponse.json({ items: slice, total, limit, offset });
  }),

  http.get(`${API_BASE_URL}/enquiries/:enquiryId`, ({ params }) => {
    if (!signedInUser) return unauthenticated();

    const enquiry = seededEnquiries.find((candidate) => candidate.id === Number(params.enquiryId));
    if (!enquiry) {
      return HttpResponse.json(errorBody('Enquiry not found', 'NOT_FOUND'), { status: 404 });
    }
    if (signedInUser.role === 'Visitor' && enquiry.submittedByEmail !== signedInUser.email) {
      return HttpResponse.json(errorBody('Not permitted', 'FORBIDDEN'), { status: 403 });
    }
    return HttpResponse.json(enquiry);
  }),
];
