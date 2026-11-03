# Mock Data Context

Generated: 2026-11-03
Source spec: generated-docs/specs/api-spec.yaml

## Data Conventions
- ID format: integer sequence
- Pagination envelope: `{ items, total, limit, offset }` (offset-based, via `paginateByOffset`)
- Date format: ISO 8601

## Entities and Sample Values
### Enquiry
- Source: factory `web/src/mocks/data/enquiry.ts` (`seededEnquiries`, 6 items, 2 per status and per category)
### User / Session
- Source: factories `web/src/mocks/data/user.ts` and `identity.ts` (`userInfoFor(role)`)
- Seeded accounts: visitor@, agent@, admin@example.com; shared password from `SEEDED_PASSWORD`

## Sample Data Used
None — entities come from the shared factories.

## Assumptions
- Session is a single in-memory signed-in user (reset on page reload).
- Login locks an email for 15 minutes after 5 failed attempts (423, lockout end in `details`); lockout duration is an assumption.
- Visitors only see enquiries where `submittedByEmail` matches; other enquiry ids return 403.
- Filters `status` and `category` are single-valued per the spec.
