# PROOF — build-tests-together (good slot: build-tests-together-contact-form)

Live Tier-3 capture, `release-v1.5.0` template, benchmark `contact-form`, epic `sign-in-and-app-shell`.
Stop point: post-B0.2 (tests generated, no story coded — all `startedAt` null).
Parity rule: signature-set **overlap** (a shared name agrees when both files share ≥1 (strategy,role);
a mismatch is a fully disjoint set). Extra same-named elements only one layer checks are allowed
(test-plan-shared-controls.md Check 6).

## T2.1 — one agent per story (transcript)

- verdict: **one-agent-per-story**
- epic-mocks spawns: 1
- story spawns: 4
- split (vitest/playwright) spawns: 0
- distinct stories covered: 1, 2, 3, 4

## T2.2 — control parity per story

### Story 1 — status: **match** (compared 3 shared name(s))

| control name | vitest | playwright | agree? | note |
|---|---|---|---|---|
| email | label | label | ✅ |  |
| password | label | label | ✅ |  |
| sign in | role=button | role=button, role=heading | ✅ | shared signature agrees; extra same-named element one layer checks |

### Story 2 — status: **match** (compared 2 shared name(s))

| control name | vitest | playwright | agree? | note |
|---|---|---|---|---|
| contact | role=link, text | role=link | ✅ | shared signature agrees; extra same-named element one layer checks |
| inbox | role=button, role=link, text | role=link | ✅ | shared signature agrees; extra same-named element one layer checks |

### Story 3 — status: **match** (compared 3 shared name(s))

| control name | vitest | playwright | agree? | note |
|---|---|---|---|---|
| email | label | label | ✅ |  |
| password | label | label | ✅ |  |
| sign in | role=button | role=button | ✅ |  |

### Story 4 — status: **skipped-no-overlap** (compared 0 shared name(s))

## Interpretation

All shared controls agree under the overlap rule: for every name in both files the two sides share at least one (strategy,role) signature, so the control they both reference is described the same way. Where a name carries an extra signature on one side (e.g. a page heading titled "Sign in" beside the "Sign in" button, nav text "Contact"/"Inbox"), that is a different element only one test layer checks — allowed, not a defect. A fully disjoint set (e.g. radiogroup vs combobox) would still red.
