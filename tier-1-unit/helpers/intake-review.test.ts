/**
 * Step 7 unit test — the intake review-manifest builder (`helpers/intake-review.ts`). Pure over strings:
 * it turns a captured CLAUDE.md + project.md into the two subjective review checks (#476 facts-correct,
 * #478 detail-pointed), with the right evidence shown to the reviewer.
 */
import { describe, it, expect } from 'vitest';
import { buildIntakeReviewManifest, INTAKE_REVIEW_CHECKS } from '../../helpers/intake-review';

const CLAUDE = `# CLAUDE.md

## Project Overview

Contact & Enquiry Management — a public contact form with a role-gated inbox.

- **Roles:** Visitor, Support Agent, Admin
- **Data:** Mock-only

## Repository Structure
...`;
const PROJECT = `## Roles & Permissions
| Permission | Visitor | Support Agent | Admin |
## Authentication
Server-side session.
## Compliance
UNRELATED_COMPLIANCE_SENTINEL — should not ride into the review evidence.`;

describe('buildIntakeReviewManifest', () => {
  const m = buildIntakeReviewManifest(CLAUDE, PROJECT, 'intake-contact-form');

  it('produces exactly the two subjective checks with the catalog ids', () => {
    expect(m.items.map((i) => i.id)).toEqual(INTAKE_REVIEW_CHECKS.map((c) => c.id));
    expect(m.items).toHaveLength(2);
  });

  it('the facts check shows the overview + the FACT sections of project.md (not the whole file)', () => {
    const facts = m.items.find((i) => i.id === 'intake-facts-correct')!;
    expect(facts.evidence).toContain('Support Agent');          // from the overview
    expect(facts.evidence).toContain('Server-side session.');   // from project.md §Authentication (a fact)
    expect(facts.evidence).not.toContain('UNRELATED_COMPLIANCE_SENTINEL'); // §Compliance scoped out
  });

  it('the detail check shows the overview (checking nothing is dumped there)', () => {
    const detail = m.items.find((i) => i.id === 'intake-detail-pointed')!;
    expect(detail.evidence).toContain('role-gated inbox');
    expect(detail.evidence).not.toContain('Server-side session.'); // detail check is overview-only
  });

  it('the captureLabel carries the slot name', () => {
    expect(m.captureLabel).toMatch(/intake-contact-form/);
  });

  it('falls back gracefully when there is no overview section', () => {
    const m2 = buildIntakeReviewManifest('# CLAUDE.md\n\nno overview', PROJECT);
    expect(m2.items[0].evidence).toMatch(/no ## Project Overview section/);
  });
});
