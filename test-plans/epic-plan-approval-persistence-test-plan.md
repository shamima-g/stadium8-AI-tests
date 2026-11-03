# Test plan — approving the epic plan persists it to main and starts the first epic (v1.6)

**Branch:** `version-1.6` (AI-tests repo). **Testing against:** `.targets/dev-v1.5.0/` (== `dev-default`).

> **v2 — council-hardened** (claim-accuracy · falsifiability · adversarial/vacuous-green · feasibility). Anchors
> verified clean (every `start.md`/`intake-agent.md` line, the commit strings, the staged set, the
> stop-after-intake slot). Five design fixes applied: **(1)** assert artifacts ≡ the run's **frozen proposal**,
> not literal payload slugs (the slugs were a hidden decomposition-equality gate); **(2)** P9 rewritten — a
> `decompose` always runs at Step 7.5, so scope it to "exactly one, before the approve turn"; **(3)** the stop
> point was impossible as worded (Step 10 auto-chains into `/continue` with no prompt, `start.md:456`) — moved
> to the first `/continue` PLAN stories approval; **(4)** the frozen proposal is gitignored, so the capture must
> copy it out before cleanup; **(5)** `CLAUDE.md` is **modified** not added — assert presence-in-commit, not
> status `A`. See **What the council changed** at the end.

**What this tests (chosen subject — approval → persistence):** when the user approves the epic plan at INTAKE
by pasting the page payload `{ decision: "epic-plan", edited: false, epics: [...] }` (or typing `approved`),
`/start` must take the **approve → commit → hand-off** path (`start.md:341` → Step 9 → Step 10): write one
`brief.md` per epic, write `epic-plan.md`, write `CLAUDE.md` §Project Overview, commit all to **main**, then
start the first dependency-free epic on its branch and announce it. This is **existing v1.5 behaviour** — so
this plan is a **regression-guard + recorded-run invariant**, not a spec-ahead feature plan.

**The approved-plan fixture (the pasted payload, verbatim):** the `contact-form` app — 4 epics, with
`sign-in-and-app-shell` the only dependency-free root:

| # | slug | name | dependsOn |
|---|---|---|---|
| 1 | `sign-in-and-app-shell` | Sign-in and App Shell | — (root) |
| 2 | `contact-and-my-messages` | Contact Form and My Messages | Sign-in and App Shell |
| 3 | `enquiry-inbox` | Enquiry Inbox | Sign-in and App Shell |
| 4 | `enquiry-handling` | Working an Enquiry | Enquiry Inbox |

`edited: false` ⇒ this is a **straight Approve** (no page edits). The payload is the **frozen approved plan**
the capture is pinned to; the test asserts the written artifacts + commits + hand-off **faithfully realize the
approved proposal** — it does **not** assert that live decomposition independently *produces* this exact plan
(that's a separate decomposition-correctness concern, deliberately out of scope here).

> **Fidelity, not decomposition.** For `edited:false` the persisted plan equals the blocker-free proposal the
> user accepted. The capture lets `feature-planner decompose` run live, approves the result `edited:false`, and
> Tier-2 asserts persistence **against the frozen proposal** (`epic-plan-proposal.md` / `review-payload.json`
> captured in the run) — using the payload above as the expected *shape* (4 epics, sign-in-first) to author the
> calibrations and confirm the capture is the intended scenario. A material divergence of the live proposal
> from the payload is logged as a decomposition note, never a failure of this persistence test.

---

## The persistence contract (what approval must do — anchors in `start.md`)

On the Approve branch (`start.md:365-413`, then Step 10 `:450-454`):

1. **Briefs** — loop `intake-agent` `mode: epic-only`, **one call per epic**, as a parallel Task batch
   (`:369-380`); each writes `generated-docs/epics/<slug>/brief.md`. Confirm one `BRIEF_FILE` per epic matched
   **by slug**, not by counting (`:382`).
2. **Plan** — write `generated-docs/epic-plan.md` from the approved proposal (`:384`), in the
   §epic-plan.md format (`:415-446`): a §Epics table (name, slug, goal, Builds-on) + a §Coverage table
   (every requirement → an epic) ending `_<N> requirements, all assigned._`.
3. **Overview** — write `CLAUDE.md` `## Project Overview` (`:386`).
4. **Commit to main** — `git add generated-docs/ documentation/ CLAUDE.md` (+ `transcript-collection.json` if
   present); commit message **`docs(project): project setup + epic plan`**; push best-effort (`:388-399`).
5. **Start first ready epic** — pick the first epic whose `dependsOn` is empty (`:403`); `git checkout -b
   epic/<firstSlug>`; `node .claude/scripts/epic-state.js --init --name "<firstName>"` (root ⇒ no
   `--depends-on`); commit **`docs(<firstSlug>): start epic`**; `state.json` lands at `phase: PLAN` (`:413`).
   The other epics remain **drafts on main** — `brief.md`, **no** `state.json` (`:401`).
6. **Hand off** — one line: `"Plan approved. Starting on <first epic name>."` (`:450-454`).

For **this payload** the first ready epic is **`sign-in-and-app-shell`**; the started branch is
**`epic/sign-in-and-app-shell`**.

---

## Tiering

- **Tier 1** — static regression-guards on the Step 9/10 wiring (necessary, not sufficient; no AC green here).
- **Tier 3** — one live capture of `contact-form` driven **through** the epic-plan approval and the seamless
  Step 10 hand-off, halted at the **first `/continue` PLAN stories approval** (Step 10 auto-chains into
  `/continue` with no prompt — `start.md:456` — so there is no pause at the hand-off itself), spend + sign-in
  gated.
- **Tier 2** — deterministic invariants over the frozen capture (git bundle ⇒ tree + log assertable), plus
  planted-bad calibration slots. **No AI judge** — every check is a tree/transcript/git parse.

---

## Tier 1 — static wiring regression-guards

New `tier-1-unit/epic-plan-persistence/{rules.ts,epic-plan-persistence.test.ts}`, modelled on
`tier-1-unit/intake-overview/`. Span-scoped detectors over `start.md` (and `intake-agent.md`), each
mutation-coupled (true on the real wording, false on a named mutation) and asserted against the real template
under `REPO_ROOT` (`describe.skipIf(!TEMPLATE_PRESENT)` + `EXPECT_TEMPLATE_REF`).

| ID | Detector | Goes red when (mutation) |
|---|---|---|
| S1 | `start.md:341` — pasted `{decision:"epic-plan"}` with `edited:false` (or typed `approved`) routes to **Approve** (no re-decompose), and **only** the `edited:true` branch re-invokes `decompose` with `revisionFeedback` + a coverage re-check ("never write the plan straight from the pasted JSON without the coverage re-check") | collapse the two branches / drop the re-check clause |
| S2 | Step 9 order present: briefs via `intake-agent epic-only` (parallel) → `epic-plan.md` → `CLAUDE.md` §Project Overview → commit → start first epic | reorder (e.g. commit before briefs) or drop a step |
| S3 | First-ready-epic = first `dependsOn`-empty; other epics stay **drafts on main** (brief, no `state.json`) | change to "first listed" / start all epics |
| S4 | `epic-plan.md` format block intact — §Epics + §Coverage + `_<N> requirements, all assigned._` | remove the Coverage table or the all-assigned line |
| S5 | Commit messages exact: `docs(project): project setup + epic plan` and `docs(<slug>): start epic`; the project commit stages `generated-docs/ documentation/ CLAUDE.md` | change a message or the staged set |

---

## Tier 3 — live capture (spend + sign-in gated)

**⚠ Spend / sign-in gate.** Runs `claude -p …` live; print the sign-in + cost notice and get go-ahead; a cheap
`plan-dry` probe first.

**Capture (`contact-form`).** The benchmark + its `answers.json` (with `approvals.*`) already exist, and the
memory note **[[intake-capture benchmark]]** records the current `intake-contact-form` slot as
**stop-after-intake** (project.md only — it stops *before* this approval). This capture continues **one step
further**: `/start` → "Share what I have" → intake → `feature-planner decompose` → **epic-plan approval,
approved** → Step 9 persistence → Step 10 hand-off → `/continue` auto-chains → **halt at the first `/continue`
PLAN stories approval** (the first natural pause after persistence). New `-Phase`-gated
`tier-3-automated/capture-epic-plan-persistence.ps1`, modelled on `capture-build-tests-together.ps1`.

> **Approve is driven as typed `"approved"`, not pasted JSON.** `contact-form/answers.json` has
> `approvals.intakeApproval.action: "approve"`; per `start.md:341` a typed `approved` routes **identically** to
> `edited:false` (straight Approve, no re-decompose). The pasted payload is illustrative; the capture need not
> paste JSON unless `live-driver.ps1` is extended to. "`edited:false`" in the checks below therefore means
> "accepted-as-is" (typed-approved **or** `edited:false`), both of which are the no-re-decompose path.

**Live must-show checks (deterministic).** The **expected epic set/goals/edges is read from the run's own
frozen proposal** (`epic-plan-proposal.md` / `review-payload.json`, copied out at freeze — see below), **not**
from the literal pasted slugs. This keeps the test **persistence-fidelity** (approved proposal → written
artifacts) rather than a hidden decomposition-equality gate: a faithful run whose `decompose` named an epic
differently must still pass. The only literal structural invariant is **"the started epic is the
dependency-free root"**. (The pasted 4-epic payload remains the *expected shape* used to author the
calibrations and confirm the capture is the intended scenario.)

- **P1 — plan written.** `generated-docs/epic-plan.md` present; its §Epics set (names, goals, `Builds-on`
  edges) **equals the frozen proposal's `epics`** (same slugs, goals, `dependsOn`). No literal slug list is
  hard-coded in the assertion.
- **P2 — full coverage.** §Coverage maps **every** requirement to one of the 4 epics; ends
  `_<N> requirements, all assigned._`; zero unassigned.
- **P3 — briefs written.** For **every epic in the frozen proposal**, `generated-docs/epics/<slug>/brief.md`
  exists; each opens with the inheritance line (`Inherits roles, auth, data source, compliance, and styling
  from project.md.`, `intake-agent.md:166`) and lists **its** requirement slice; Goal matches that epic's
  proposal goal.
- **P4 — overview written.** `CLAUDE.md` `## Project Overview` is populated (placeholder gone).
- **P5 — one project commit on main.** A commit `docs(project): project setup + epic plan` whose
  `git show --stat <sha>` **lists** `generated-docs/epic-plan.md`, `generated-docs/project.md`, and each epic's
  `brief.md` as added, and `CLAUDE.md` as **modified** (it pre-exists as the placeholder, so it shows `M` not
  `A`). The enumerated set is non-exclusive — the same commit also stages `documentation/` and
  `transcript-collection.json` when present (`start.md:391-392`).
- **P6 — first epic started.** The **dependency-free root** epic's branch `epic/<rootSlug>` exists (for this
  payload, `epic/sign-in-and-app-shell`); its `state.json` at `phase: PLAN`, **root** (no `dependsOn`); commit
  `docs(<rootSlug>): start epic`. `<rootSlug>` is derived from the frozen proposal (the `dependsOn:[]` epic),
  not hard-coded.
- **P7 — others are drafts.** Every **non-root** proposal epic has a `brief.md` on main but **no** `state.json`
  and **no** `epic/<slug>` branch.
- **P8 — hand-off line.** Transcript contains `Starting on <root epic name>` (`Plan approved. Starting on …`).
- **P9 — exactly one decompose, before approval.** The transcript shows **exactly one** `feature-planner`
  `decompose` Task call (the legitimate Step 7.5 one, `start.md:239-251`) and it **precedes** the approve
  message — i.e. **no `decompose` after the approve turn** (the `edited:false` path must not re-decompose). A
  naive "no decompose anywhere" check is always-red because Step 7.5 always runs.

**Freeze gate (accept capture only if):** P1–P8 hold on the frozen tree **and** the stop landed at the first
`/continue` PLAN stories approval with the first epic still at `phase: PLAN` — gated on **no `web/` source** and
**no `generated-docs/epics/*/stories/` files** (PLAN's story files not yet written; BUILD not entered). Freeze
as a **git bundle** slot at `fixtures/golden-runs/epic-plan-persist-contact-form/` with `repo.bundle` +
`transcript.jsonl` + the **copied-out** `epic-plan-proposal.md`/`review-payload.json` (these are **gitignored**,
`start.md:253` — the capture must copy them out of the live tree **before `cleanup`**, as they are *not* in
`repo.bundle`) + `meta.json` (benchmark, template ref, model, timestamp, scenario `approve-persist`).

---

## Tier 2 — recorded-run invariants (replay the frozen bundle; no live AI)

New `tier-2-recorded-run/epic-plan-persistence/persistence.test.ts`, fed by
`loadGoldenRun('epic-plan-persist-contact-form')` (git bundle ⇒ `golden.hasGit`), asserting **P1–P9** over the
frozen tree + `golden.git(...)` log + `transcript.jsonl`. `describe.skipIf(!golden.present)`; `afterAll` →
`golden.cleanup()`.

**Planted-bad calibration slots (prove each check reds):**
1. `…-MISSINGBRIEF` — `enquiry-handling/brief.md` absent → **reds P3**.
2. `…-UNASSIGNED` — `epic-plan.md` §Coverage leaves one requirement unassigned (and the count line wrong) →
   **reds P2**.
3. `…-WRONGSTART` — `epic/enquiry-handling` started instead of the root → **reds P6/P7**.
4. `…-PLACEHOLDER` — `CLAUDE.md` still the "No project yet" placeholder → **reds P4**.
5. `…-REDECOMPOSE` — transcript with a **second** `decompose` Task call **after** the approve message (the
   `edited:true`-style re-check wrongly taken on an accepted-as-is plan) → **reds P9** (the always-present Step
   7.5 decompose alone must stay green).

---

## Acceptance → test traceability

| Contract clause | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| `edited:false` ⇒ straight Approve (no re-decompose) | S1 | P9 + calib 5 | P9 |
| epic-plan.md written (Epics + edges) | S2, S4 | P1 | P1 |
| full coverage, all assigned | S4 | P2 + calib 2 | P2 |
| one brief per epic, scoped + inheriting | S2 | P3 + calib 1 | P3 |
| CLAUDE.md §Project Overview written | S2 | P4 + calib 4 | P4 |
| single project commit staging the bundle | S5 | P5 | P5 |
| first deps-free epic started at PLAN; rest drafts | S3 | P6, P7 + calib 3 | P6, P7 |
| hand-off announces the first epic | S2 | P8 | P8 |

---

## Feasibility & build items

**Reuse:** `contact-form` benchmark + `answers.json`; `loadGoldenRun`; the Tier-1 `rules.ts` detector idiom +
`EXPECT_TEMPLATE_REF` guard; `New-Tier3Scaffold` + `-Phase` gating; `golden.git(...)` history asserts.

**Net-new:** (1) `tier-1-unit/epic-plan-persistence/` (S1–S5) — writable + runnable now; (2)
`capture-epic-plan-persistence.ps1` driving the approval to the first `/continue` PLAN approval (copying the
gitignored proposal out before cleanup); (3) the frozen
GOOD slot `epic-plan-persist-contact-form` (git bundle) + the 5 calibration slots; (4)
`tier-2-recorded-run/epic-plan-persistence/persistence.test.ts`.

**Prereqs:** authenticated CLI + token budget for the capture. The persistence/branch/log assertions read the
**local** bundle history, so a remote is **not** required for them — `push` is best-effort/skip-silently
(`start.md:398,:410`); add a bare remote only if you want the `push` steps exercised. The capture must halt at
the first `/continue` PLAN stories approval (before PLAN writes `generated-docs/epics/*/stories/` or any `web/`
source) and copy the gitignored proposal/review-payload out before cleanup.

## Suggested order

1. Tier 1 (S1–S5) + the 5 **planted-bad calibration slots** (hand-authored git-bundle trees) — prove each
   check reds, no spend.
2. `plan-dry` probe (confirms contact-form decomposes to a blocker-free, sign-in-first plan) behind the gate.
3. Run the live capture `edited:false`, apply the freeze gate, freeze the GOOD slot.
4. Wire Tier 2 (P1–P9) over the good + calibration slots; save `PROOF.md` under `TestResults/`.

## Appendix — evidence (anchors in `.targets/dev-v1.5.0/.claude/commands/start.md` unless noted)

- `:330-346` approval step (page payload, AUQ, revision routing); `:341` `edited:false`→Approve / `edited:true`
  →re-decompose+coverage re-check.
- `:365-413` Step 9 (briefs `:369-382`, epic-plan.md `:384`, CLAUDE.md overview `:386`, commit `:388-399`,
  start first epic `:403-411`, drafts on main `:401`).
- `:415-446` epic-plan.md format (Epics + Coverage + all-assigned line); `:450-454` Step 10 hand-off.
- `:456` Step 10 **auto-chains** into `/continue` ("seamless — no user prompt"); `:458` `/continue` sees
  `phase: PLAN` and drives the stories approval — hence the stop is the first `/continue` PLAN approval, not the
  hand-off line.
- `agents/intake-agent.md` — `epic-only` mode `:38`, inheritance line `:166`, §Out of Scope `:176`.
- `agents/feature-planner.md` — `decompose` mode header `:251`; the proposal field tuple
  (`requirementInventory` / `epics` / `coverage` / `blockers`) is defined at `:261-269`.

---

## What the council changed (this is v2)

1. **Fidelity, not decomposition — enforced, not just stated.** P1/P3/P6/P7 now assert `epic-plan.md` + briefs
   **≡ the run's frozen proposal** (read from `review-payload.json`), with the only literal being "the started
   epic is the dependency-free root." v1 hard-coded the four payload slugs, which would red a faithful run
   whose `decompose` named an epic differently — a decomposition-equality gate wearing a persistence label.
2. **P9 was always-red.** A `decompose` always runs at Step 7.5 (`start.md:239-251`), so "no decompose in the
   transcript" fails on the GOOD run too. Rewritten to "**exactly one** decompose, **before** the approve
   turn"; calib 5 injects a **second, post-approve** one.
3. **The stop point was impossible as worded.** Step 10 auto-invokes `/continue` with no prompt (`:456`), so
   there is no pause at the hand-off. Moved to the **first `/continue` PLAN stories approval**; freeze gate now
   keys on "no `web/` source **and** no `generated-docs/epics/*/stories/`."
4. **Gitignored proposal.** `epic-plan-proposal.md`/`review-payload.json` are gitignored (`:253`) — not in
   `repo.bundle`. The capture must copy them out **before cleanup**; P1/P3/P6 depend on them.
5. **CLAUDE.md is modified, not added;** P5 now asserts presence-in-commit via `git show --stat` (CLAUDE.md
   `M`, the plan/project/briefs `A`), a non-exclusive set. And a remote is **not** needed for the assertions
   (local bundle history), only to exercise `push` — prereq wording corrected.
6. **Approve is driven as typed `"approved"`** (what `contact-form/answers.json` carries), which routes
   identically to `edited:false`; the pasted JSON is illustrative unless the driver is extended.

**Anchors: verified clean.** Every cited `start.md`/`intake-agent.md` line, both commit messages, the staged
set, and the `intake-contact-form` stop-after-intake slot were confirmed against the files.
- `agents/feature-planner.md` — `decompose` proposal (requirementInventory/epics/coverage/blockers) `:251`.
- Harness: `helpers/golden-run.ts` (`loadGoldenRun`, `.git`, `.hasGit`); existing slot
  `fixtures/golden-runs/intake-contact-form/` (**stop-after-intake** — this plan extends past it); precedent
  `test-plans/intake-claudemd-project-overview-test-plan.md`. See memory **[[intake-capture benchmark]]**.
