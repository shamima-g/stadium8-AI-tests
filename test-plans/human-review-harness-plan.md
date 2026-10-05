# Plan — human-review harness (no AI judge) — councilled v2

**Status (updated 2026-10-02):** Steps 1–6 **BUILT** (each councilled) — the verdict core + stamp
(`helpers/human-review.ts`), the review-page generator + `writeReview` (`build-review.ts`), the
`ingest-verdict` command, the test wiring + `REQUIRE_REVIEW` (`review-suite.ts`/`review-logic.ts`), the
broken-case calibration, and the **AI judge is RETIRED** (`tier-3-automated/judge/` deleted; its 5
verbosity criteria re-homed in `helpers/verbosity-review-checks.ts`). **Step 7 DONE** — two real captures
wired end-to-end (each councilled + drift-guarded): intake #476/#478 (`intake-contact-form`) and design
digest/decision (`plan-design-update`), both skip-until-reviewed.

**Scope boundary — DECIDED 2026-10-02.** The harness auto-wires the **artifact-reviewable** subjective
checks (judged from the committed capture files): intake #476/#478, and the design **artifact residue** of
#14/#15 (digest faithfulness + held-decision clarity). The **message-based** checks — the 5 verbosity ACs,
the "does it read plainly" half of #214, and the **live** #14/#15 cores (was the read-back SHOWN / the
conflict ASKED) — judge the tool's *user-facing messages*, which these capture slots don't commit and which
can't be singled out cleanly (the raw stream exists but is un-tagged — the correct hand-back can't be
isolated without the declined message-tagging/B14, or a paid live capture + best-effort guessing).
**The user chose to keep those BY HAND** (the manual-tests docs / coverage matrix), not auto-wired.
(Note: #214's "at approval, not at build" PLACEMENT half is deterministic-once-extracted, not subjective —
it's pending the stream extractor, same class as #480, not a manual review.) The build is COMPLETE for the
artifact-reviewable set; the message-based set stays manual unless B14 is revisited or a live capture is funded.

(Originally plan-only; revised after a 3-lens council that fixed v1's blocker, honesty holes, and mis-mappings.)

Replaces model-graded subjective checks with a human-in-the-loop browser review whose verdict is recorded
and read deterministically. No AI at test time.

## Why
Some checks can't be settled by a lookup — "are the stated facts correct?", "does this read as plain
language?", "is this leak a paraphrase the token-gate missed?". Instead of a model judging them, a person
judges them once per capture and the test reads the saved verdict.

---

## 1. Mechanism (corrected — v1's save-to-path was impossible)

A browser page **cannot choose where a download is saved** (it goes to Downloads; `showSaveFilePicker` is
barred on `file://` and non-Chromium). So:

- The capture emits a **self-contained `review.html`** with evidence **pre-rendered at build time**
  (markdown → HTML in `build-review.mjs`; HTML mockups embedded in a sandboxed `<iframe srcdoc>` with all
  external refs inlined/stripped; **binaries like `brand-export.bin` are NOT embedded** — they can't be
  eyeballed, so they stay deterministic scorers). Explicit UTF-8.
- The page offers **copy-to-clipboard of the verdict JSON** and a select-all `<textarea>` as the
  first-class output (a Blob download is a secondary convenience — Safari opens JSON inline, and repeat
  downloads become `verdict (1).json`, so download is NOT the trusted path).
- A harness command **`npm run ingest-verdict <slot>`** reads the verdict (from the clipboard, or the
  newest matching `verdict*.json` in Downloads) and **places it in the slot's `review/` folder**, after
  validating the stamp. The user never hand-places a file into a deep path. (No server — an ingest CLI
  step, consistent with the "no server" choice.)

## 2. The stamp (fail-closed content hash — not a commit SHA)
- The stamp is a **hash over the canonically-normalized bytes of the exact evidence shown** (fixed LF line
  endings, trimmed trailing whitespace, stable key order) — computed identically in `build-review.mjs` and
  in `loadVerdict`. A commit SHA is rejected: captures run on dirty trees (SHA unchanged, evidence
  changed) and the SHA doesn't exist pre-commit.
- **Fail-closed:** a missing/empty stamp on **either** side ⇒ **skip** (never `undefined === undefined`
  → pass). Mismatch ⇒ skip (stale, re-review needed). A Windows unit test must prove build-time and
  test-time hashes agree (CRLF/LF).

## 3. Honesty safeguards (added after the council)
- **`REQUIRE_REVIEW=1` mode** (mirrors `EXPECT_TEMPLATE`, workflow-tests §16): for release runs it turns
  every unreviewed/stale subjective **skip → red**, so "all green" can never coexist with "nothing was
  reviewed." Default (dev) stays skip.
- **Aggregate line:** every run prints **"N of M subjective checks reviewed"** so a reader sees coverage
  at a glance, not a bare green.
- **Evidence citation required on each Yes** (short free-text, e.g. "`#2563eb` kept, no `#7c3aed`"), the
  way `DESIGN-CAPTURE-LOG.md` already does — a bare Yes is rejected. Determinism at test time is NOT
  listed as an authenticity safeguard (a hand-edited verdict reads reproducibly; the citation + the
  REQUIRE_REVIEW gate are what give confidence, not determinism).
- **Broken-case calibration (workflow-tests §2 rule 1):** ship a **planted-bad capture** fixture and a
  recorded "reviewer correctly clicked No" calibration verdict, plus unit tests for `build-review.mjs`
  and `loadVerdict`. Without a proven broken case the harness is an untested detector.

---

## 4. What actually needs human review (scope corrected)

| Check | Human-review residual ONLY | Stays deterministic (code scorer) |
|---|---|---|
| **Intake #476** | role→**action** mapping is right; the auth **forbid clause** is correct | **role set-equality** vs project.md (`roleSetEquals`/`auditOverview`, already gating Tier-2) |
| **Intake #478** | a **within-shape paraphrase** leak using no never-present token (e.g. "meets GDPR") | the extra-bullet whitelist + `neverPresentTokenLeaks` (already catch literal/structural leaks) |
| **Plan #214** | does the "what moved" diff read as **plain language** | **"at approval, not at build"** placement = a transcript-position fact (deterministic once extracted — same class as #480; needs the B14 extraction, which is the real hard part) |
| **Verbosity ACs 3/4/5/7/8** | all five (first-line-actionable, at-a-glance, only-actionable-part, shown-once, no-blind-approvals) — **re-homed to `helpers/verbosity-review-checks.ts`** when the AI judge was retired | — |

**Correctly EXCLUDED (not subjective):** #480 silence (zero `AskUserQuestion`) — deterministic once the
stream extractor exists; it needs B1/AUQ extraction, not review.

---

## 5. Integration — reconcile, don't run a second parallel path (council's biggest fix)

- **AI-judge seam retired ✅ (2026-10-02).** `tier-3-automated/judge/` (rubric/calibration/`JudgeAdapter`,
  ACs 3/4/5/7/8) is **deleted** and dropped from the vitest `include`; its five verbosity criteria are
  re-homed in `helpers/verbosity-review-checks.ts` as the canonical criteria LIST — but kept MANUAL (by
  hand), NOT auto-wired (message-based; see the scope boundary at the top, decided 2026-10-02).
- **plain-stops — keep both, split by role (DECIDED).** The manual doc (`manual-tests/B-plain-stops.md`,
  `qa/test-plans` branch) **stays** as the live behavioural walkthrough (delete brief+story → `/continue`
  restores silently; the give-up loop fires). The **plain-language verdict** ("does the message read
  plainly") **moves onto the gating review screen**; the manual doc points to that verdict instead of
  re-asking it. No duplicated Yes/No; grep tripwires stay as code checks.
- **Design cores #14/#15 — split (RESOLVED 2026-10-02).** Their ARTIFACT residue IS wired and gates: the
  digest (read-back artifact, #14) via `plan-design-digest-faithful`, and the held conflict outcome (#15)
  via `plan-design-decision-clear` — both skip-until-reviewed, a No reds. The LIVE cores — was the read-back
  actually SHOWN at intake (#14), was the conflict actually ASKED at plan time (#15) — are message/live,
  stay MANUAL (the walkthrough + `DESIGN-CAPTURE-LOG.md`, record-only/eyeballed), NOT auto-wired. So the
  earlier "a No on the design check fails the build" holds for the artifact-checkable parts; the live
  "shown?/asked?" behaviour remains a manual eyeball.

---

## 6. Pieces to build (when approved)
| Piece | What |
|---|---|
| review-manifest shape | `{id, criterion, guidance, evidence, stamp}` a capture emits; evidence pre-rendered |
| `build-review.mjs` | manifest → self-contained `review.html` (copy/textarea primary, sandboxed mockups, UTF-8); + unit tests |
| `ingest-verdict` CLI | clipboard/Downloads → slot `review/verdict.json`, validates stamp; + unit tests |
| `loadVerdict` helper | reads verdict, **fail-closed** stamp check, returns `{present, stale, results}`; + Windows CRLF hash test |
| test wiring | `describe.skipIf(!present||stale)`; `expect(results[id]).toBe('pass')`; `REQUIRE_REVIEW` → skip becomes red; aggregate "N of M reviewed" line |
| calibration fixture | a planted-bad capture + a recorded "No" verdict proving the review can fail |
| per-check manifests | the residuals in §4 (incl. the 5 verbosity ACs migrated off the retired judge) |

## 7. Result/proof (the user's ask, kept)
`PROOF.md` lists `verdict.json` and `review.html` as **clickable `file:///` links** (forward slashes,
percent-encoded spaces; mind Windows MAX_PATH) so the verdict and the review page open straight from the
result file.

## 8. Open decisions for you
1. ✅ **DONE (2026-10-02): retired `tier-3-automated/judge/`** (deleted) and re-homed its 5 verbosity
   criteria (ACs 3/4/5/7/8) to `helpers/verbosity-review-checks.ts`; kept MANUAL (message-based — see the
   scope boundary, decided 2026-10-02), not auto-wired.
2. ✅ **DECIDED (2026-10-02): design #14/#15 — split by artifact vs live.** The ARTIFACT residue GATES and
   IS wired: `plan-design-digest-faithful` (the read-back digest, #14) + `plan-design-decision-clear` (the
   held conflict outcome, #15) — skip-until-reviewed, a No reds. The **LIVE cores** (was the read-back
   SHOWN at intake / the conflict ASKED at plan time) are message/live and **stay MANUAL** (the walkthrough
   + `DESIGN-CAPTURE-LOG.md`, record-only/eyeballed), not auto-wired. So "a No fails the build" holds for
   what's artifact-checkable; the live "shown?/asked?" behaviour stays a manual eyeball. (Later: if you want
   the live cores to gate too, that needs the message pipeline — currently declined.)
3. ✅ **DECIDED (2026-10-02): plain-stops — BOTH, but the plainness verdict stays MANUAL.** The manual doc
   stays as the live behavioural walkthrough (delete brief+story → `/continue` restores silently; the
   give-up loop fires). The "does the message read plainly" judgement is **message-based**, so per the scope
   boundary it stays a **manual** check (the verbosity manual doc / coverage matrix), NOT auto-wired onto
   the review screen. (The grep tripwires stay as code checks either way.)
