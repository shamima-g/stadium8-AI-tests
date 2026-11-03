/**
 * Story Metadata:
 * - Route: none (infrastructure-only, non-routable)
 * - Target File: web/src/lib/data/enquiryStore.ts
 *
 * Tests for Epic 1, Story 4: Enquiry and user records with sample data.
 *
 * Contract this suite assumes of the target module:
 * - `enquiryStore` exposes async `list()`, `read(id)`, `create(input)`,
 *   `update(id, changes)` and `remove(id)` (the API-client shape later epics consume).
 * - `create` / `update` reject (throw) when a record breaks the brief's Data Model rules.
 * - State lives in module scope: it persists for the session and a fresh module load
 *   (the page reload) starts again from the seeded data.
 *
 * These tests WILL FAIL until implemented (TDD red).
 */
import { describe, expect, it, vi } from 'vitest';

import { createEnquiry } from '@/mocks/data/enquiry';
import type { Enquiry, EnquiryCategory, EnquiryStatus } from '@/types/api-generated';

const SEEDED_VISITOR_EMAIL = 'visitor@example.com';

async function loadFreshEnquiryStore() {
  vi.resetModules();
  const { enquiryStore } = await import('@/lib/data/enquiryStore');
  return enquiryStore;
}

function validNewEnquiryInput() {
  const template = createEnquiry();
  return {
    name: template.name,
    email: template.email,
    address: template.address,
    category: template.category,
    comment: template.comment,
    submittedByEmail: template.submittedByEmail,
  };
}

describe('Epic 1, Story 4: enquiry store and seeded data', () => {
  // AC-1
  it('seeds at least one enquiry for every Category and every Status', async () => {
    const enquiryStore = await loadFreshEnquiryStore();

    const seededEnquiries = await enquiryStore.list();

    expect(new Set(seededEnquiries.map((enquiry: Enquiry) => enquiry.category))).toEqual(
      new Set<EnquiryCategory>(['Feedback', 'Question', 'General Enquiry']),
    );
    expect(new Set(seededEnquiries.map((enquiry: Enquiry) => enquiry.status))).toEqual(
      new Set<EnquiryStatus>(['New', 'In Progress', 'Resolved']),
    );
  });

  // AC-2
  it('gives every seeded Resolved enquiry a Reply Note and includes one from the seeded Visitor', async () => {
    const enquiryStore = await loadFreshEnquiryStore();

    const seededEnquiries = await enquiryStore.list();
    const resolvedEnquiries = seededEnquiries.filter((enquiry: Enquiry) => enquiry.status === 'Resolved');

    expect(resolvedEnquiries).not.toEqual([]);
    for (const resolvedEnquiry of resolvedEnquiries) {
      expect(resolvedEnquiry.replyNote).toMatch(/\S/);
    }
    expect(seededEnquiries.map((enquiry: Enquiry) => enquiry.submittedByEmail)).toContain(
      SEEDED_VISITOR_EMAIL,
    );
  });

  // AC-3
  it('accepts a valid enquiry and rejects values outside the brief Data Model', async () => {
    const enquiryStore = await loadFreshEnquiryStore();
    const unlistedCategory: string = 'Complaint';
    const unlistedStatus: string = 'Closed';

    const createdEnquiry = await enquiryStore.create({
      ...validNewEnquiryInput(),
      category: 'Feedback',
    });
    expect(createdEnquiry.category).toBe('Feedback');
    expect(createdEnquiry.status).toBe('New');

    await expect(
      enquiryStore.create({
        ...validNewEnquiryInput(),
        category: unlistedCategory as EnquiryCategory,
      }),
    ).rejects.toThrow();
    await expect(
      enquiryStore.create({ ...validNewEnquiryInput(), email: 'not-an-email' }),
    ).rejects.toThrow();
    await expect(
      enquiryStore.create({ ...validNewEnquiryInput(), comment: 'Too short' }),
    ).rejects.toThrow();
    await expect(
      enquiryStore.update(createdEnquiry.id, { status: unlistedStatus as EnquiryStatus }),
    ).rejects.toThrow();
    await expect(
      enquiryStore.update(createdEnquiry.id, { status: 'Resolved', replyNote: null }),
    ).rejects.toThrow();
  });

  // AC-4
  it('shows a change on the next read and starts again from the seed after a fresh load', async () => {
    const enquiryStore = await loadFreshEnquiryStore();
    const seededEnquiries = await enquiryStore.list();
    const newEnquiry = seededEnquiries.find((enquiry: Enquiry) => enquiry.status === 'New');
    if (!newEnquiry) {
      throw new Error('Seed must contain an enquiry with status New');
    }
    const enquiryId = newEnquiry.id;

    await enquiryStore.update(enquiryId, {
      status: 'In Progress',
      handledBy: 'agent@example.com',
    });

    const enquiryAfterChange = await enquiryStore.read(enquiryId);
    expect(enquiryAfterChange?.status).toBe('In Progress');

    const reloadedEnquiryStore = await loadFreshEnquiryStore();
    const enquiryAfterReload = await reloadedEnquiryStore.read(enquiryId);
    expect(enquiryAfterReload?.status).toBe('New');
  });
});
