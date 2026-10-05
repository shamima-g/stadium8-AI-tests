# Human-review harness (no AI judge) — BUILT (design + decision record)

**Status (2026-10-02): built and wired.** Replaces model-graded subjective checks with a human-in-the-loop
browser review whose verdict is recorded and read deterministically — no AI at test time. Every piece was
built step-by-step, each councilled. This is the record of *what it is, why, and what's in/out of scope*;
the step-by-step "plan to build" is spent.

## What it is
A capture emits a self-contained **`review.html`**; a person answers **Yes/No** per criterion (a Yes needs a
one-line evidence citation); they copy the verdict and run **`npm run ingest-verdict <slotReviewDir>`**, which
validates it and files the recorded result — kept **separate from the committed review inputs** — under the
Tier-3 results convention: **`TestResults/review/<benchmark>/<yyyyMMdd-HHmmss>/`** (both `verdict.json` and a
human-readable `PROOF.md`). The test reads the **newest dated verdict whose stamp still matches** the capture:
- unreviewed/stale ⇒ **skip** (dev) / **red** under **`REQUIRE_REVIEW`**; reviewed **No** ⇒ red; reviewed
  **Yes** (with citation) ⇒ green. An aggregate **"N of M reviewed"** line keeps coverage visible. Each
  review makes a new dated folder, so the results are a history; a re-review supersedes, and an older review of
  byte-identical evidence (same stamp) is still honoured.

Files: `helpers/human-review.ts` (verdict core + stamp), `build-review.ts` (`review.html` + `writeReview`),
`ingest-verdict.ts` (+ the `ingest-verdict` npm script), `review-suite.ts` / `review-logic.ts` (vitest
wiring + `REQUIRE_REVIEW`). Calibration: `fixtures/human-review-calibration/`.

## Why these design choices (council-driven)
- **No server; copy + `ingest-verdict`.** A browser page can't choose a save path (`showSaveFilePicker` is
  barred on `file://`), so copy-to-clipboard/textarea is the output and the CLI places the file.
- **Stamp = content hash of the exact evidence shown** (normalized LF/trailing-ws, computed identically at
  build and read). **Fail-closed:** a missing/empty stamp on either side ⇒ skip; mismatch ⇒ stale (so a
  changed capture can't reuse an old Yes). NOT a commit SHA (dirty trees).
- **Honesty safeguards:** `REQUIRE_REVIEW` turns unreviewed→red for releases (mirrors `EXPECT_TEMPLATE`); a
  Yes requires an evidence citation (determinism ≠ authenticity); a **planted-bad calibration** proves the
  harness can actually fail (rule 1). Self-contained, zero-network `review.html`; binaries not embedded.

## Scope — what's auto-wired vs manual (DECIDED 2026-10-02)
**Auto-wired + gating** (artifact-reviewable — judged from committed capture files), both skip-until-reviewed
with a drift guard (committed bundle == a fresh rebuild):
- **Intake** `#476` facts-correct + `#478` detail-pointed → `tier-2-recorded-run/intake-overview/intake-review.test.ts`
  (`helpers/intake-review.ts`). (The deterministic parts — role set-equality, the never-present/whitelist
  leak gates — stay in `auditOverview`, not review.)
- **Design** artifact residue of #14/#15 — digest faithfulness (the read-back artifact) + held-decision
  clarity (the conflict outcome) → `.../plan-scope/plan-design-review.test.ts` (`helpers/plan-review.ts`).

**Manual (by hand)** — message-based checks that judge the tool's *user-facing messages*, which the capture
slots don't commit and can't be singled out without the declined message-tagging (B14) or a paid live
capture: the **5 verbosity ACs** (3/4/5/7/8; criteria list in `helpers/verbosity-review-checks.ts`), the
**plain-language** half of `#214`, **plain-stops** plainness, and the **live #14/#15 cores** (was the
read-back SHOWN / the conflict ASKED). These stay in the manual-tests docs / coverage matrix.

**Not subjective at all:** `#214`'s "at approval, not at build" placement and `#480` silence are
deterministic-once-extracted (need the stream extractor, not review).

## Decisions on record (2026-10-02)
1. **AI judge retired** — `tier-3-automated/judge/` deleted; its 5 verbosity criteria re-homed as a LIST and
   kept manual.
2. **Design #14/#15 split** — the artifact residue gates (wired, a No reds); the live "shown?/asked?" cores
   stay manual. "A No on the design check fails the build" holds for what's artifact-checkable.
3. **plain-stops** — the manual doc stays the live walkthrough; its plainness verdict is message-based, so it
   stays **manual** too (not on the review screen). Grep tripwires remain code checks.

## How a user knows a review is waiting
A pending/stale review is never buried in a "skipped" count:
- **In-run notice** — `reviewSuite` prints `[review pending|stale] <label> …` with the `review.html` to open
  and the exact `npm run ingest-verdict <dir>` command, during a normal `npm run test:tier2`.
- **On-demand** — **`npm run review:status`** (`helpers/review-status.ts`) lists every slot as
  reviewed / pending / stale with the same open + ingest lines, without running the suite.

## Proof
`ingest-verdict` writes a **`PROOF.md`** next to each `verdict.json` under
`TestResults/review/<benchmark>/<yyyyMMdd-HHmmss>/`: the benchmark/slot, reviewer + when, every criterion with
its Yes/No/— outcome and citation, and clickable `file:///` links to `review.html` and `verdict.json` so they
open straight from the result.

## What would unblock the manual set
The message-based checks become auto-wireable only if **message-tagging (B14)** is revisited (so user-facing
messages can be isolated) or a **live message capture** is funded. Until then they stay manual by hand.
