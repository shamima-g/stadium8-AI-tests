import type { Enquiry } from '@/types/api-generated';

export const createEnquiry = (overrides: Partial<Enquiry> = {}): Enquiry => ({
  id: 1,
  name: 'Vera Visitor',
  email: 'visitor@example.com',
  address: '12 Harbour Road, Cape Town',
  category: 'Question',
  comment: 'Could you tell me when your support desk is open over the holidays?',
  status: 'New',
  replyNote: null,
  submittedAt: '2026-10-28T09:15:00.000Z',
  submittedByEmail: 'visitor@example.com',
  handledBy: null,
  ...overrides,
});

/**
 * Seed set (brief §Seeded data): every Category and every Status appears at least twice,
 * Resolved enquiries carry a Reply Note, and the seeded Visitor owns several so
 * "My messages" has content.
 */
export const seededEnquiries: readonly Enquiry[] = [
  createEnquiry({
    id: 1,
    category: 'Question',
    status: 'New',
  }),
  createEnquiry({
    id: 2,
    name: 'Vera Visitor',
    category: 'Feedback',
    comment: 'The new opening hours are much more convenient — thank you for the change.',
    status: 'Resolved',
    replyNote: 'Thanks for letting us know. We have shared your feedback with the team.',
    submittedAt: '2026-10-20T14:02:00.000Z',
    handledBy: 'agent@example.com',
  }),
  createEnquiry({
    id: 3,
    name: 'Daniel Mokoena',
    email: 'daniel.mokoena@example.org',
    address: null,
    category: 'General Enquiry',
    comment: 'I would like to know whether you offer group bookings for schools.',
    status: 'In Progress',
    submittedAt: '2026-10-25T11:40:00.000Z',
    submittedByEmail: 'daniel.mokoena@example.org',
    handledBy: 'agent@example.com',
  }),
  createEnquiry({
    id: 4,
    name: 'Priya Naidoo',
    email: 'priya.naidoo@example.org',
    address: '7 Long Street, Durban',
    category: 'Feedback',
    comment: 'The checkout page kept timing out on my phone yesterday evening.',
    status: 'New',
    submittedAt: '2026-10-30T18:25:00.000Z',
    submittedByEmail: 'priya.naidoo@example.org',
  }),
  createEnquiry({
    id: 5,
    name: 'Vera Visitor',
    category: 'General Enquiry',
    comment: 'Please update the postal address on my account to the new one.',
    status: 'In Progress',
    submittedAt: '2026-10-26T08:05:00.000Z',
    handledBy: 'admin@example.com',
  }),
  createEnquiry({
    id: 6,
    name: 'Tom Fischer',
    email: 'tom.fischer@example.net',
    address: null,
    category: 'Question',
    comment: 'Is there a way to download my past invoices as a PDF?',
    status: 'Resolved',
    replyNote: 'Yes — open Billing, choose an invoice and select Download PDF.',
    submittedAt: '2026-10-18T10:30:00.000Z',
    submittedByEmail: 'tom.fischer@example.net',
    handledBy: 'admin@example.com',
  }),
];
