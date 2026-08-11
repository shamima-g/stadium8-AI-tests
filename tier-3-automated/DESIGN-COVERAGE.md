# Build-from-design coverage map + work plan

The six acceptance criteria (ACs) for the build-from-design feature, the honest state of test
coverage after a council audit (2026-08-11, branch `S8-129`), and the prioritised plan to close
the gaps. The audit **confirmed all six coverage labels**; it corrected the *evidence* behind three
of them (below) — i.e. some checks were credited with doing more than they actually do.

## Corrected coverage map

| AC | Criterion (plain) | Label | What actually backs it |
|----|-------------------|:-----:|------------------------|
| 1 | Design is the **only** input; no written spec added | Partial | Fixture is design-only + `#13` proves the digest *wiring* — **but nothing asserts a spec didn't creep into `documentation/`**. |
| 2 | Design → running app via **normal approvals only** (no renaming/fixing/coding) | Partial | An answers-driven run completed and built green — **but no rule (even record-only) asserts the human didn't hand-fix**. Weakest partial. |
| 3 | Built app has the **screens + is navigable** | Partial | Suite checks screen *existence* + scoped rebuild (`design-capture-replay.test.ts`). **Navigability is checked nowhere by the suite.** |
| 4 | Runs against the **real backend**; stand-in data → **real calls** | **Not covered** | `design-taskboard` is mock-only by design; no benchmark pairs a design with a real backend. **Largest hole.** |
| 5 | Anything it **can't use is shown**, not dropped | Covered | Held up by `design-capture-replay.test.ts` over the real run (Uncertainties non-empty + names the due-date). **Closest call.** |
| 6 | Usual **quality checks pass** before done | Covered (workflow) | The workflow's CI gate genuinely blocks (security/tsc/eslint/prettier/build/vitest). |

## Evidence corrections (things previously over-stated)

1. **AC3 — the cited Tier-2 trace does not exist.** "Every routable story has a live Playwright
   spec" is **prose in `workflow-tests.md`, not implemented** in `tier-2-recorded-run/recorded-run.test.ts`.
   And Tier-2 **skips the design run** anyway (the staged run lives in a subfolder `helpers/golden-run.ts`
   ignores). Real suite coverage for AC3 is screen *existence* + scoping only — **not navigability**.
2. **AC5 — the stated gate is inert.** `digestReadyForIntake` requires the Uncertainties **section to
   exist**, not to contain anything (`ok` depends on screens + palette, never Uncertainties content),
   so an empty section passes. The real teeth are the replay asserts over the captured run.
3. **AC6 — two mis-citations.** Playwright is **not** a quality gate (absent from `quality-gates.yml`).
   `quality-gates.test.ts` is a `--help` **smoke test**, not a truthfulness verifier — it never runs a
   real gate green/red. AC6 holds on the workflow's CI gate, not on suite coverage.

---

## Work plan (tomorrow) — prioritised by leverage

Ordered so the biggest, most-isolated hole comes first. Each task lists where it lives and what
"done" means. Small = a Tier-1 test / doc edit; Large = a fixture/benchmark or a live re-capture.

### 1. AC4 — a design **+ real-backend** benchmark  *(Large; the only true hole)*
- **Goal:** prove a design build replaces stand-in data with **real backend calls**.
- **Do:** add a `design-taskboard`-style benchmark wired to an existing benchmark backend (reuse the
  `transactions` backend, or add a small API), so the build produces `generated-docs/specs/api-spec.yaml`
  + `web/src/lib/api/endpoints.ts`.
- **Then it's testable:** the existing `api-path-exactness` linter (TG-31) fires only when those files
  exist — so real-backend correctness (exact paths, no raw `fetch`, shared client) becomes gating.
- **Done when:** a design-driven build hits a real backend and the api-path linter runs (not skips) over it.

### 2. AC3 — promote the staged run + add a **navigability** trace  *(Large + Medium)*
- **Goal:** make Tier-2 actually gate the design feature, and check "user can move through it".
- **Do (promote):** reconcile the per-story-commit invariant — this run uses `feat(<slug>/story-N)`,
  Tier-2 expects `feat(epic-N-story-M)` (see `fixtures/golden-run/design-capture/meta.json`) — then move
  the run to `fixtures/golden-run/` root (re-capture a `repo.bundle` from the baseline commit if topology
  checks are wanted).
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
