# Plan — human-review harness (no AI judge) — councilled v2

**Status:** PLAN ONLY (not built). Decided 2026-10-02; **revised after a 3-lens council** (feasibility,
honesty, coverage/integration) that corrected v1's blocker, honesty holes, and several mis-mappings.

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
| **Verbosity ACs 3/4/5/7/8** | all five (first-line-actionable, at-a-glance, only-actionable-part, shown-once, no-blind-approvals) — **currently the built AI-judge seam** | — |

**Correctly EXCLUDED (not subjective):** #480 silence (zero `AskUserQuestion`) — deterministic once the
stream extractor exists; it needs B1/AUQ extraction, not review.

---

## 5. Integration — reconcile, don't run a second parallel path (council's biggest fix)

- **Retire the built AI-judge seam.** `tier-3-automated/judge/` (rubric/calibration/`JudgeAdapter`, ACs
  3/4/5/7/8) is the *actual* AI judge and the user doesn't want it. This plan must **remove it** and route
  its five verbosity criteria into this human-review harness (they become five review checks). Until then
  it is orphaned but still in the vitest `include`.
- **plain-stops — keep both, split by role (DECIDED).** The manual doc (`manual-tests/B-plain-stops.md`,
  `qa/test-plans` branch) **stays** as the live behavioural walkthrough (delete brief+story → `/continue`
  restores silently; the give-up loop fires). The **plain-language verdict** ("does the message read
  plainly") **moves onto the gating review screen**; the manual doc points to that verdict instead of
  re-asking it. No duplicated Yes/No; grep tripwires stay as code checks.
- **Decide the design cores #14/#15.** They are **record-only eyeball cores** today (`DESIGN-CAPTURE-LOG.md`;
  "record-only, never gate"). Converting them to **gating** review checks is a real change of policy —
  decide gating-vs-record-only, and pick **one** verdict store (this harness's `verdict.json` OR
  `DESIGN-CAPTURE-LOG.md`), not both. v1's claim that this "fits the existing record-only model" was wrong:
  this harness **gates**, so it's a new mechanism that needs this reconciliation.

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
1. ✅ **DECIDED (2026-10-02): retire `tier-3-automated/judge/`** and move its 5 verbosity criteria
   (ACs 3/4/5/7/8) into human review. (A build action when we build the harness.)
2. ✅ **DECIDED (2026-10-02): the design cores #14/#15 GATE** — a "No" on read-back or ask-before-overwrite
   turns the check **red and fails the run** (no longer record-only). Consequence: these two cores move
   into the gating review harness; their verdict lives in the harness `verdict.json` (the single store),
   and `DESIGN-CAPTURE-LOG.md` / `DESIGN-SCENARIO.md` / `DESIGN-COVERAGE.md` must be updated from
   "record-only, never gate" to "gating human-review" when built.
3. ✅ **DECIDED (2026-10-02): BOTH** — keep the separate manual doc **and** add it to the review screen,
   split so the same thing isn't judged twice: the **manual doc stays as the live behavioural walkthrough**
   (the steps only a person running the scenario can do — delete brief+story → `/continue` restores
   silently; the give-up loop actually fires), and the **"does the message read plainly" judgement moves
   onto the gating review screen** (Yes/No on the captured message). The manual doc points to the review
   screen for the plainness verdict rather than duplicating that Yes/No. (The grep tripwires stay as code
   checks either way.)
