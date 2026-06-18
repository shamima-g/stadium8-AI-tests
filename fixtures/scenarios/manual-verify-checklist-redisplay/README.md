# Manual Verification Checklist Re-Display Fixtures (S8-80)

Placeholder snapshot fixtures for the `manual-verify-checklist-redisplay` scenario. Each `case-NN-*/expected-*.md` is the canonical text a tester should see at one of the four presentation points defined in [HOW-IT-WORKS.md §4.9 → "Manual Verification Checklist Contract"](../../../HOW-IT-WORKS.md#manual-verification-checklist-contract).

## Status

**All three cases are stubs awaiting harvest.** Phase 7 is intentionally lightweight — until a real Story 1 ("View task list") run produces an actual `verification-checklist.md`, there is no canonical text to snapshot. Each `expected-*.md` contains only a `TODO: harvest` note and a pointer to the run that should fill it in.

## How to populate

1. Run the workflow end-to-end against the Team Task Manager scenario in [TEST-INPUTS.md](../../../TEST-INPUTS.md), stopping at the QA manual-verification checkpoint for Story 1.
2. Locate the persisted file at `generated-docs/qa/epic-1-task-browsing/story-1-view-task-list-verification-checklist.md`.
3. Copy its contents verbatim into:
   - **`case-01-first-ask/expected-checklist.md`** — the text shown at the first `AskUserQuestion`.
   - **`case-02-fixcycle/expected-redisplay.md`** — the text shown after the §21b fix cycle resolves. Should be byte-identical to case-01.
   - **`case-03-freetext/expected-redisplay.md`** — the text shown after the §21c free-text reply is answered. Should also be byte-identical to case-01.
4. Run §21d (multi-cycle) and confirm the cycle-1 and cycle-2 on-screen texts are byte-identical to `case-02`. No separate fixture needed for §21d — it reuses `case-02`.
5. Commit the fixture files. They will then drive the byte-for-byte comparisons in [TEST-GUIDE §21a–§21c](../../../TEST-GUIDE.md#21-qa--manual-verification-checkpoint).

## Why three files, not one

All three cases SHOULD contain identical text — that is the contract. Keeping three separate files (rather than a single shared fixture) makes drift detectable: if a future regression caused the orchestrator to silently abbreviate on the fix cycle, only `case-02` would diverge from the live run, and the test would point exactly at the broken path.

## Cross-references

- Behavioural tests: [TEST-GUIDE.md §21a–§21e](../../../TEST-GUIDE.md#21-qa--manual-verification-checkpoint)
- Scripted inputs: [TEST-INPUTS.md → "Manual Verification Checklist Re-Display Inputs"](../../../TEST-INPUTS.md#manual-verification-checklist-re-display-inputs)
- Contract description: [HOW-IT-WORKS.md §4.9 → "Manual Verification Checklist Contract"](../../../HOW-IT-WORKS.md#manual-verification-checklist-contract)
- Tier 2 invariants that consume the on-disk checklist file (separate from these fixtures): `QA-TESTS/tier-2-log-replay/invariants/checklist-verbatim-*.test.ts`
