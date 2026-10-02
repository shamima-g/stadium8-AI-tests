# Implementation plan — unblocking the parked behavioural tests (councilled v2)

**Scope:** the `it.todo` in `tier-1-unit/intake-overview/` and `tier-1-unit/plan-scope/` + the manual
`plain-stops` behavioural checks. All are *behavioural* / *recorded-run* — the static guards are built
and green.

> **Status (2026-10-01) — Phase 1 Tier-2 landed; Tier-3 still pending.** The intake **recorded-run** half
> is built: the five intake invariants (#461–465) now run against a live `/start` `contact-form` capture
> in the `intake-contact-form` golden slot. #464/#465 pass; the full-overview audit (#461–463) is a
> documented `it.fails` **KNOWN PRODUCT GAP** — the live INTAKE output doesn't conform to the template's
> own `project-overview.md` (see `findings/intake-project-overview-nonconformance.md`). The deterministic
> #477 (placeholder-gone) and #481 (CR/Policies self-diff) are now covered in Tier 2, so they're no
> longer separate Tier-3 todos. **Remaining parked:** intake **5** Tier-3 (#476 facts-judge, #478
> detail-judge, #479 budget near-ceiling, #480 silence, #482 merge-recheck) + plan-scope **10** = **15**
> (was 22). Built in Phase 1: **B5, B6 (build-capture variant), B8** (on top of the Phase-0 B1–B4 work).
> Phases 2–4 below are unchanged and still gated on §6 (real-GitHub merge sandbox).
>
> **UPDATE (2026-10-02) — the AI judge is RETIRED; B7 / §6.3 / "Phase 2 — Judge" are SUPERSEDED.** The
> subjective checks (#476 facts, #478 detail, #214 told-what-moved, plain-stops, and the 5 verbosity ACs
> 3/4/5/7/8) are now judged by a person via the **human-review harness** (recorded verdict, gates), not an
> LLM. `tier-3-automated/judge/` is deleted; the verbosity criteria are re-homed in
> `helpers/verbosity-review-checks.ts`. Authoritative design + remaining build:
> `test-plans/human-review-harness-plan.md`. Read the judge references below as historical.

**Grounding:** a capability inventory of `tier-3-automated/` and the Tier-2 golden-run infra. A council
verified the harness facts (all citations correct) and found several dependency/effort/feasibility
defects, now folded in. Effort tags S / M / L. Evidence in the appendix.

---

## 1. Two root constraints — one is effort, one is conceptual

**(a) No mid-run control (effort).** The Tier-3 harness drives **one autonomous `claude -p` call** with a
**static `TIER3-ANSWERS.json`**; scoring is read from git + `generated-docs/` after the run. It can't
pause, inject a commit, swap files, or answer one gate differently. That makes design-swap, `/upgrade`,
pre-staling, per-gate answers, and merge the expensive work.

**(b) Two capabilities are conceptually gated, not just unbuilt (the council's biggest finding):**
- **The merge path cannot be reached without real GitHub + `gh`.** `/continue` B7.2 short-circuits when
  there's no remote (continue.md:648), and with a remote it runs `gh pr create` → `gh pr merge` →
  **B7.2.6**. `gh` is absent from the harness and from `Setup.ps1`. A **bare** local remote makes the
  short-circuit *not* fire, so the run hits `gh pr create` and **fails** — any "merge" the `concurrent`
  scenario achieves is the AI **improvising an off-script `git merge`** that **never executes B7.2.6**.
  → **Every merge-time todo is reachable only by standing up a real throwaway GitHub repo + `gh` auth.**
  There is no cheap local substitute.
- **The judge is record-only, so it can't turn a `.todo` green by itself.** `JUDGE_GATES_THE_BUILD =
  false`; the judge logs metrics, never a pass/fail gate, and its `JudgeAdapter` (the model call) is
  unimplemented. A Vitest `it.todo` only becomes a *passing* test by asserting something; asserting
  `verdict === 'pass'` means the judge now gates a **test result** (non-deterministic, costs per call,
  needs auth `Setup.ps1` doesn't provision). → **The semantic todos can be "recorded" but not
  legitimately "green" until we add a test-only gate mode + repeat-sampling, or reclassify them.**

Also: the features under test are **`[Unreleased]`** or dev-only, so the runner must target a checkout
where the feature actually exists.

---

## 2. Building blocks

| ID | Block | Effort | Notes (incl. council corrections) |
|----|-------|:------:|------|
| **B1** | Stream extraction upgrade (`Read-ClaudeEvent`/`stream.ps1` keep tool **name**, AUQ inputs, assistant **text**) | M | Highest leverage. **Must COMPLETE** before #480 and all of Phase 2 — it's the critical path, not a "start in Phase 0" item. |
| **B2** | `project.md` §Roles parser in `helpers/project-overview.ts` | S | Net-new; only the overview side is parsed today. |
| **B3** | `plan-facts-changed` scorer split (live-driver.ps1:887 + `expectFactsChange` on PLAN-A `$Expect`) | S | Concurrent lane (:1162) unchanged. |
| **B4** | Local/two-root target for `Resolve-Tier3Template` via a **copy-cloner** | S→M | Upgrade needs a **base + feature pair** of local roots; the default `git clone --depth1 --branch` can't check out an **uncommitted** feature and `targets.json` points at GitHub URLs (feature must be pushed). **Note:** the existing `-Target dev` may already reach the feature if it's pushed to `stadium-software/stadium-8` — B4's local variant may be *optional for Phase 1*, required for upgrade. |
| **B5** | Tier-2 orchestrator helper (golden `CLAUDE.md` → resolve → run the pure checks) | S | Analysis functions already exist. |
| **B6** | `intake` scenario + capture | M | **Risk:** "stop after the intake commit" is prompt-hope in a single call, and `New-Tier3Scaffold` excludes `.git`, so intake git-scoring relies on `/start` initialising git mid-run (verify). **Cheaper fallback:** score the deterministic intake todos off a normal `build` capture (its history already contains the intake commit) — no new stop needed. B6 does **not** need B9. |
| ~~**B7**~~ | ~~JudgeAdapter (real model call) + calibration + gate mode~~ **— RETIRED 2026-10-02** | — | Superseded: no AI judge. The subjective checks move to the **human-review harness** (`helpers/*review*.ts`, `test-plans/human-review-harness-plan.md`); `tier-3-automated/judge/` deleted; verbosity criteria re-homed in `helpers/verbosity-review-checks.ts`. |
| **B8** | Multi-golden slot (`loadGoldenRun(slot)` + per-slot `.gitignore`) | M | Single `fixtures/golden-run/` slot occupied by `minimal-concurrent`. |
| **B9** | Two-phase / interruptible driver | L | Prereq for B10/B12 + pre-staling + per-gate answers. **Sequencing risk:** if B6's prompt-stop proves unreliable, B9 moves ahead of Phase 1. |
| **B10** | `design` scenario (swap) | L | = **B9 + a NEW design-diff scorer** (`parkedDesignUpdate`/`designFingerprint`/`designDecisions[]`, digest-not-on-main, told-what-moved) **+ a B8 slot** — not "mostly free once B9". Fixture is complete. |
| **B11** | **Real GitHub + `gh` merge sandbox** (throwaway repo + `gh` auth added to Setup) | **L** | The **only** path that runs B7.2.6. The bare-remote "option (a)" is struck — it cannot reach B7.2.6. |
| **B12** | `upgrade` scenario | L | Needs B9 + B4(two-root) + B11 + a real **old-base→feature** pair. |
| **B13** | Concurrent **same-fact-conflict** variant + scorer | M | **Scorer ✅ landed (2026-10-01)** — `Get-Tier3ConflictRulesMissed` + 10 Pester tests (encodes `policies/epic-branch-concurrency.md` §6.2). **Still unbuilt:** the colliding `/plan` scenario (the existing `concurrent` drives a *non-colliding* epic and hardwires `blockedMergeRefused=$null`), a `Get-Tier3ConflictFacts` gatherer, and the "both values" check needs **B14** (declined). |
| **B14** | **Message-tagging** (separate user-facing text from internal chatter) | M | The declined design decision (§6.4). Needed to locate "the diff shown at approval" (#214) and to automate plain-stops plainness. B1 retains text but does **not** tag audience. |

---

## 3. Phased plan

### Phase 0 — Foundation (pure code, no live run) — **S–M**
B2, B3, B4(local variant), B5, the near-ceiling fixture, and **complete B1** (its finish gates Phase 1
#480 and all of Phase 2 — treat B1 as the critical path, not a background "start").

### Phase 1 — INTAKE recorded-run + non-judge behavioural — ✅ **Tier-2 recorded-run DONE (2026-09-30)**; non-judge Tier-3 still pending — **needs B6 (or build-capture fallback), B8, B5, B4/`-Target dev`, and B1 for #480**
**Done:** intake T2 ×5 (#461-465) run against the `contact-form` capture — #464/#465 pass, #461-463 is a
documented `it.fails` KNOWN PRODUCT GAP; the deterministic #477/#481 are now folded into Tier-2.
**Still pending (Tier-3):** non-judge #479 (needs a near-ceiling fixture) and #480 (needs B1 + an AUQ
extractor). #476/#478 are judge → Phase 2; #482 is merge → Phase 4.
*All eight deterministic intake todos share the SAME single capture and therefore the SAME
feature-target dependency (B4 or `-Target dev`).*
**Capture benchmark: `contact-form`** (decided 2026-09-30) — the lightest fixture that still has ≥2
roles with distinct permissions (Visitor/Support Agent/Admin), an auth model (BFF/session), and a data
source, so it exercises every intake check; rejected minimal-concurrent (1 role/no auth), transactions
(~6× heavier), e-commerce (2 MB). Target = the `28-09-2026` snapshot via `-TemplateRoot`; run stops
after the intake commit; golden slot `intake-contact-form`. Recorded in the capture's `meta.json` and
the Tier-2 test header too.

### Phase 2 — Judge — **needs B7 (needs B1) + a resolved §6.3, and B14 for #214** — *may be "recorded" not "green"*
intake #476 (facts judge), #478 (per-category judge), plan-scope #214 (told-what-moved — **also needs
B14**, it hits the declined message-tagging wall, not B1 alone), and plain-stops plainness. **These flip
to a passing test only if §6.3 adds a test-only gate + repeat-sampling; otherwise they remain recorded
metrics.**

### Phase 3 — `/plan` behavioural + design-swap — **needs B9, B10 (=B9+scorer+B8), B3, B13**
plan-scope positive completion incl. design-update (#212, needs B9+B10+B3), clean abandon (#215),
draft-vs-new (#218), decline (#219), the same-fact-halt/additive-union part of concurrency (#217 → B13),
and captures the parked design-update golden run → plan-scope T2 #200/#201.

### Phase 4 — Merge / upgrade — **needs B11 (real GitHub) + B9 (+B12)** — *gated on §6.1*
intake #482 (B7.2.6 — real-GitHub only), plan-scope #213 (confirm+inherit) & #216 (park→build apply),
and the behavioural tiers of the merge-recheck & upgrade-backfill plans. **None of these is reachable
without a real GitHub+`gh` sandbox.**

---

## 4. Traceability (corrected)

**intake-overview (12):** #461-465 → B6/B8/B5 + feature-target (Phase 1); #477/#481 → same (Phase 1);
#479 → same + near-ceiling fixture (Phase 1); #480 → + **B1** (Phase 1, after B1); #476/#478 → +B1+B7
(**Phase 2, recorded-vs-green per §6.3**); #482 → **B11(real GitHub)+B9** (Phase 4).

**plan-scope (10):** #200 → B3+B8 + a /plan capture (Phase 3); #201 → B8+**B9+B10** (Phase 3); #212 →
B3+**B9**+B10+B4 (Phase 3); #213 → B3+B9+**B11** (Phase 4); #214 → B1+**B14**+plan scenario (**Phase 2**,
tagging-gated); #215 → B9+B10 (Phase 3); #216 → B9+B10+**B11** (Phase 4); #217 → **B13** (scorer ✅ done; colliding scenario + `Get-Tier3ConflictFacts` + B14 pending) (+B14 for the
"both values" message) (Phase 3); #218 → B9+plan scenario (Phase 3); #219 → B9+plan scenario (Phase 3).

**plain-stops (manual):** B1 + B7 + **B14** (message-tagging, declined) + B9 (delete-files-mid-run for
self-repair). Stays manual until §6.4 is revisited.

---

## 5. Tier-2 durability (new — the council flagged this)

Every Tier-2 green is a **single frozen sample**: it proves *the one recorded run* had property X, not
that the feature reliably does X — a real risk for #480 ("zero AskUserQuestion") and #465 ("the intake
commit introduced the fact bytes"). And any template wording/format change **stales the bundle**, whose
re-capture is a **live AI run** (cost, flakiness, signed-in CLI), not a code edit. So this plan adds:
- a **re-capture trigger + owner + cost note** (which template changes invalidate which golden, who
  re-runs, expected cost), and
- an **N-run stability requirement** before any sensitive assertion (#480 zero-AUQ, #465
  commit-introduced) is trusted — capture several runs and confirm the property holds across all.

---

## 6. Decisions needed from you (they gate whole phases)

1. **Merge sandbox (§Phase 4).** Reframed: it is **not** "faithful vs cheap." Only a **real throwaway
   GitHub repo + `gh` auth** runs B7.2.6; the bare-remote local merge **structurally cannot**. So either
   we stand that up (L, adds `gh` to Setup) **or Phase 4 (intake #482, plan-scope #213/#216, the
   merge-recheck & upgrade-backfill behavioural tiers) is not implementable.**
2. **Feature availability (B4/B12).** Publish the `[Unreleased]` features as **fetchable tags** (so
   `-Target dev/release -Ref` works), or add a **copy-cloner local target**. Upgrade needs a resolvable
   **old-base + feature** pair — decide before B12.
3. **Judge — can the Phase-2 todos ever be "green"?** Either (i) **reclassify** #476/#478/#214/plain-stops
   as **recorded, not green** (matching the record-only design) and drop them from the "turns green"
   count, or (ii) build a **test-only gate mode + repeat-sampling** on top of the adapter (bigger B7),
   accepting a non-deterministic, paid, auth'd judge in CI.
4. **plain-stops message-tagging (B14).** Revisit the declined tagging (unblocks #214 + plain-stops
   plainness automation) or keep those manual.

---

## 7. Recommended path & how to proceed

**Phase 0 is still the right, safe start** — pure code, unit-testable, unblocks downstream, no live run,
no decision needed. First PR: **B2** (`parseProjectRoles`), **B3** (scorer split), **B5** (Tier-2
orchestrator) — all S with good/broken tests — and **B1** (the critical-path M item).

**Then Phase 1** turns the largest single group green: **9 todos** (8 before B1), via the intake
scenario/capture + multi-golden slot — and the cheapest route may be scoring them off a normal `build`
capture rather than a new stop-after-intake scenario.

**Before Phases 2–4, you must answer §6:** Phase 4 is **impossible without a real GitHub sandbox**
(decision 1), and Phase 2's four todos are **"recorded, not green"** unless you fund a test-gating judge
(decision 3). These are conceptual gates, not just effort — the plan can't hide them.

**Critical path & risks:** B1 must *complete* before Phase 1 #480 / Phase 2; B9 (two-phase driver) is
the big lift and a *sequencing risk* (if B6's prompt-stop is unreliable, B9 jumps ahead of Phase 1);
`gh` and judge-auth must be added to `Setup.ps1` as Phase-4 / Phase-2 entry conditions.

> On branch `plan/parked-tests-implementation` (uncommitted). Suggested first action: I implement
> **Phase 0** (B2/B3/B5 — S, in-repo, no decisions), while you settle §6.1 (real-GitHub merge) and
> §6.3 (judge green-vs-recorded), which gate the back half.

---

## Appendix — capability evidence (council-verified: all citations correct)

- Single-call drive + static answers: `live-driver.ps1:184` (`Invoke-ClaudeHeadless`), `:68-69`/`:78`
  (`TIER3-ANSWERS.json`); scenarios `('build','plan','concurrent')` `Run-QATests.ps1:30`,
  `live-driver.ps1:1336`.
- **Merge path:** `gh` absent everywhere + not in `Setup.ps1` prereqs (`:335-363`); `New-Tier3BareRemote`
  `live-driver.ps1:1047-1065`; concurrent scorer hardwires `blockedMergeRefused=$null` `:1250`.
  continue.md B7.2: no-remote short-circuit `:648`, `gh pr create` `:658`, `gh pr merge` `:715`, B7.2.6
  `:747`.
- Stream capture file/command only: `Read-ClaudeEvent` `live-driver.ps1:319-320`, `stream.ps1:57-60`;
  raw jsonl retained `Run-QATests.ps1:213-238`; phase heuristic `timing.ps1:227-240` (no event markers).
- Target resolution: `Resolve-Tier3Template` `Run-QATests.ps1:167-208`, injectable `$Cloner :166`,
  cloner `git clone --depth1 --branch :196-199`; `targets.json` (repo root) has `dev`/`release` (GitHub
  URLs), no `local`; default no-`-Target` builds against the nested `..` template `:175-176`.
- ~~Judge: `judge/rubric.ts` …~~ **(historical — `tier-3-automated/judge/` was DELETED 2026-10-02; these
  line citations no longer resolve.** The 5 criteria are re-homed in `helpers/verbosity-review-checks.ts`;
  verification is now human review, not an LLM judge.)
- Golden run: `helpers/golden-run.ts:26-29` single slot, `:62` `loadGoldenRun()` no args, bundle = `git
  bundle --all` (git topology + every state.json + top-level CLAUDE.md); slot = `minimal-concurrent`.
- Analysis helpers: `helpers/project-overview.ts` extractSection:127, analyzeStructure:191,
  neverPresentTokenLeaks:249, roleSetEquals:280, criticalRulesAndPoliciesUnchanged:316, parseOverviewRoles:269
  (overview only — B2 net-new).
- Scorer bug: `live-driver.ps1:972-974` (fact over-broad), `:887` PLAN-A, `:1162` PLAN-B (correct).
- Design fixture complete: `benchmark-files/design-taskboard/` (`#2563eb` → `update/ #7c3aed`,
  `answers.json` conflict, README); `DESIGN-SCENARIO.md:15` "not yet wired".
- Scaffold excludes `.git`: `New-Tier3Scaffold` `live-driver.ps1:34`. Message-tagging declined:
  `tier-1-unit/plain-stops/plain-stops.test.ts:290-299`.
