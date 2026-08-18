# Build-from-design coverage map + work plan

The six acceptance criteria (ACs) for the build-from-design feature, the honest state of test
coverage after a council audit (2026-08-11, branch `S8-129`), and the prioritised plan to close
the gaps.

> **STATUS NOW (2026-08-12 → confirmed 2026-08-18): all six ACs covered.** The work plan below
> landed all six tasks; the table immediately below is the **pre-work 2026-08-11 snapshot** kept for
> the record — read the "Status now" column (and the work plan) for the current state. Two ACs (AC1,
> AC2) are covered by **record-only operator-eyeball** rules, not by an automated suite assertion —
> called out explicitly in the table and in DESIGN-SCENARIO.md.

## Coverage map (pre-work snapshot 2026-08-11 → status now)

| AC | Criterion (plain) | Label (2026-08-11) | What actually backed it then | Status now |
|----|-------------------|:-----:|------------------------|-----------|
| 1 | Design is the **only** input; no written spec added | Partial | Fixture is design-only + `#13` proves the digest *wiring* — **but nothing asserts a spec didn't creep into `documentation/`**. | **Covered (record-only)** — `design-only-input` in DESIGN-SCENARIO.md (operator eyeball; no automated assert). |
| 2 | Design → running app via **normal approvals only** (no renaming/fixing/coding) | Partial | An answers-driven run completed and built green — **but no rule (even record-only) asserts the human didn't hand-fix**. Weakest partial. | **Covered (record-only)** — `design-no-manual-intervention` in DESIGN-SCENARIO.md (operator eyeball; can't be auto-asserted from traces). |
| 3 | Built app has the **screens + is navigable** | Partial | Suite checks screen *existence* + scoped rebuild (`design-capture-replay.test.ts`). **Navigability is checked nowhere by the suite.** | **Covered** — `contact-navigability-replay.test.ts` maps each digest screen → a route and asserts no unrouted screens. |
| 4 | Runs against the **real backend**; stand-in data → **real calls** | **Not covered** | `design-taskboard` is mock-only by design; no benchmark pairs a design with a real backend. **Largest hole.** | **Covered** — `feedback-api-design` benchmark + `feedback-api-replay.test.ts` runs the exact-path matcher over real captured `api-spec.yaml`+`endpoints.ts` (gates, doesn't skip). |
| 5 | Anything it **can't use is shown**, not dropped | Covered | Held up by `design-capture-replay.test.ts` over the real run (Uncertainties non-empty + names the due-date). | **Covered (hardened)** — `digestReadyForIntake` now requires ≥1 real Uncertainties item; `design-traces.test.ts` has present-but-empty + can't-use good/broken. |
| 6 | Usual **quality checks pass** before done | Covered (workflow) | The workflow's CI gate genuinely blocks (security/tsc/eslint/prettier/build/vitest). | **Covered (hardened)** — `quality-gates.test.ts` now drives the real runner (`--checks lint`), proving pass-when-green / fail-when-red. |

## Evidence corrections (things previously over-stated)

1. **AC3 — the cited Tier-2 trace does not exist.** "Every routable story has a live Playwright
   spec" is **prose in `workflow-tests.md`, not implemented** in `tier-2-recorded-run/recorded-run.test.ts`.
   And Tier-2 **skips the design run** anyway (the staged run lives in a subfolder `helpers/golden-run.ts`
   ignores). Real suite coverage for AC3 is screen *existence* + scoping only — **not navigability**.
   *(Since resolved — see the progress note above: a `/plan` run is now the active golden run so Tier-2
   gates, and a navigability trace was added.)*
2. **AC5 — the stated gate WAS inert.** `digestReadyForIntake` required the Uncertainties **section to
   exist**, not to contain anything (`ok` depended on screens + palette, never Uncertainties content),
   so an empty section passed. *(Since resolved — `digestReadyForIntake` now requires ≥1 real
   Uncertainties item, with a present-but-empty broken case; the gate is no longer inert. See work
   plan task 5.)*
3. **AC6 — two mis-citations, now addressed.** Playwright is **not** a quality gate (absent from
   `quality-gates.yml`) — still true. `quality-gates.test.ts` **was** a `--help` smoke test that never
   ran a real gate green/red. *(Since resolved — it now drives the real runner (`--checks lint`,
   `scriptLocation:'temp'`) and proves pass-when-green / fail-when-red. See work plan task 6.)* AC6 also
   holds on the workflow's own CI gate.

---

## Work plan — prioritised by leverage

> **COMPLETE (2026-08-12):** all six tasks are DONE on `S8-129`.
> - **1 (AC4)** ✅ — `feedback-api-design` benchmark (design + standalone API) built; the build
>   produced `api-spec.yaml` + `endpoints.ts`, and `feedback-api-replay.test.ts` runs the exact-path
>   matcher over them (no invented paths, shared client, no raw fetch). Real backend, not mock —
>   TG-31 now gates on a design build instead of skipping.
>
> Original prioritised plan (all landed):
> - **2 (AC3)** ✅ — navigability trace built (`screenNames`/`appRoutePaths`/`unroutedScreens` + synthetic
>   good/broken) and replayed over a real single-page contact-form design run
>   (`contact-navigability-replay.test.ts`: 1 screen → `/`, no unrouted screens). The Tier-2 **golden
>   run** is a separate `/plan` run (`minimal-concurrent`, build-one-park-one) committed as a
>   `repo.bundle`, which activates **all three** Tier-2 blocks (artifact + git-topology + `/plan`
>   parked-epic). The design **content** traces gate independently via the `fixtures/design-capture/`
>   replays. (No commit-subject reconcile was needed — the git-topology invariant asserts commit
>   *count* ≥ stories, not a subject format.)
> - **5 (AC5)** ✅ — the Uncertainties gate now requires ≥1 real item (`uncertaintiesItems` /
>   `surfacesUncertainty`), with a present-but-empty broken case and a can't-use-element good/broken
>   (commit `d6cd325`). The inert gate is fixed.
> - **6 (AC6)** ✅ — `quality-gates.test.ts` now drives the real runner (`--checks lint`,
>   `scriptLocation:'temp'`) and proves pass-when-green / fail-when-red (commit `6ff4410`).
> - **3 (AC2)** ✅ and **4 (AC1)** ✅ — record-only rules `design-no-manual-intervention` and
>   `design-only-input` added to `DESIGN-SCENARIO.md` (table + capture checklist).
>
> **All tasks landed.** Every AC is covered — with the honest caveat that **AC1 and AC2 are
> record-only** (operator-eyeball rules `design-only-input` / `design-no-manual-intervention` in
> DESIGN-SCENARIO.md), not automated suite assertions; AC3–AC6 are automated. The Tier-2 golden run
> (a `/plan` run) has all three invariant blocks gating; and the missing-journal finding was refined
> into a decision-trail check (`epicHasDecisionTrail` + `tier-1-unit/design/decision-trail.test.ts`).

The original plan is kept below as the record of what was done. (Ordered so the biggest,
most-isolated hole came first; each task lists where it lives and what "done" meant.)

### 1. AC4 — a design **+ real-backend** benchmark  *(Large; the only true hole)*
- **Goal:** prove a design build replaces stand-in data with **real backend calls**.
- **Do:** add a `design-taskboard`-style benchmark wired to an existing benchmark backend (reuse the
  `transactions` backend, or add a small API), so the build produces `generated-docs/specs/api-spec.yaml`
  + `web/src/lib/api/endpoints.ts`.
- **Then it's testable:** the existing `api-path-exactness` linter (TG-31) fires only when those files
  exist — so real-backend correctness (exact paths, no raw `fetch`, shared client) becomes gating.
- **Done when:** a design-driven build hits a real backend and the api-path linter runs (not skips) over it.

### 2. AC3 — golden run + a **navigability** trace  *(Large + Medium)*  ✅ DONE
- **Goal:** make Tier-2 actually gate a real run, and check "user can move through it".
- **Outcome (golden run):** the feared per-story-commit reconcile was moot — the git-topology
  invariant checks commit *count* ≥ stories, not a `feat(...)` subject format. A `/plan` run
  (`minimal-concurrent`) was captured as `fixtures/golden-run/repo.bundle` (local heads only, to
  exclude a polluted shared remote), activating all three Tier-2 blocks including parked-epic.
- **Do (navigability):** add a trace mapping the digest **Screens → live `(app)` routes** — a page/route
  exists per designed screen, and (via the workflow's per-story e2e specs) each is reachable.
- **Done when:** Tier-2 no longer skips the design run, and a suite test maps each digest screen to a route.

### 3. AC2 — record-only rule `design-no-manual-intervention`  *(Small)*
- **Goal:** capture "no renaming/fixing/hand-coding" instead of leaving it purely narrative.
- **Do:** add the rule id to `DESIGN-SCENARIO.md` (table + capture checklist) — operator confirms, during
  the run, that no out-of-band edits were needed. Record-only (can't be fully auto-asserted).
- **Done when:** the checklist has the eyeball step and a rule id to file the verdict under.

### 4. AC1 — record-only rule `design-only-input`  *(Small)*
- **Goal:** guard against a written spec creeping in.
- **Do:** add the rule id to `DESIGN-SCENARIO.md` — precondition check that `documentation/` (and
  `generated-docs/specs/`) hold only the design, no hand-written spec. Could later be a deterministic
  precondition assert over the captured tree.
- **Done when:** the checklist records design-only input as a verified precondition.

### 5. AC5 — make the Uncertainties gate real + add a degrade case  *(Small–Medium)*
- **Goal:** stop the inert section-existence gate; prove a genuinely **can't-use** element is surfaced.
- **Do:** in `helpers/design-digest.ts`, make `digestReadyForIntake` require **≥1 real (non-`[placeholder]`)
  Uncertainties item**; update `design-traces.test.ts` good/broken. Add a case proving a can't-use element
  (a not-a-design / partial-degrade verdict, an undecodable asset) is shown, not dropped.
- **Done when:** an empty Uncertainties section fails readiness, and a degrade-path case is covered.

### 6. AC6 — harden the gate test + capture the design build's gate status  *(Small–Medium)*
- **Goal:** make the suite actually verify truthful pass/fail, and record the design run's gate result.
- **Do:** strengthen `tier-1-unit/scripts/quality-gates.test.ts` to run the real gate over a **clean** tree
  (expect pass) and an **injected-fault** tree (expect fail) — not just `--help`. Add a record-only
  final-gate-status capture that reads the design run's `generated-docs/quality-gate-runs.jsonl`.
- **Done when:** the gate test proves pass-when-green / fail-when-red, and the design run's gate status is filed.

---

### Quick-start for tomorrow
- **Warm-up (small, high-confidence):** tasks 3, 4 (doc/rule-id edits) and 5 (the Uncertainties helper +
  test) — closes the cheap gaps and tightens the two inert asserts.
- **Main effort:** task 1 (design+backend benchmark) — the real hole; start by picking which backend to reuse.
- **Then:** task 2 (promote + navigability) — unblocks real AC3 and AC6 suite coverage at once.
- Full context: `DESIGN-SCENARIO.md` (rule ids + capture checklist), `fixtures/design-capture/README.md`
  (the captured verdicts), `workflow-tests.md` §14 (implemented tests).
