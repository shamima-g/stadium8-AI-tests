/**
 * Story Metadata:
 * - Route: none (infrastructure-only, non-routable)
 * - Target File: web/src/lib/data/enquiryStore.ts
 *
 * Mocking strategy:
 * - Backend calls are ALWAYS mocked — a Playwright spec never contacts a live
 *   backend (see testing-policy.md § "Playwright runs against mocks, never live").
 *   Intercept via: MSW (web/src/mocks/ is wired) once consumer stories promote this spec.
 * - Implementation pattern this assumes: none yet — this story has no browser surface;
 *   the seeded enquiries are displayed by the Contact, My messages and Inbox epics.
 *
 * E2E spec for Epic 1, Story 4: Enquiry and user records with sample data.
 */
import { test } from '@playwright/test';

test.describe('Epic 1, Story 4: Enquiry and user records with sample data', () => {
  // Non-routable: in-memory enquiry store and seed have no page; later epics display them.
  test('Epic 1, Story 4: enquiry data and seed (deferred to consumer stories)', () => {
    test.fixme();
  });
});
