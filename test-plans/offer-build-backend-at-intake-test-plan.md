# Test plan — intake offers to build the backend in this project (v1.6)

**Branch:** `version-1.6` (AI-tests repo). **Feature target:** template `v1.6.0`.

> **v2 — council-hardened** (claim-accuracy · falsifiability · adversarial/vacuous-green · feasibility). Anchors
> verified accurate (no fabricated line numbers). Four substantive fixes: **(1)** AC3/G6 was testing behaviour
> the **baseline already exhibits** (`feature-planner.md:263` already auto-assigns every requirement;
> `:271-278` restricts blockers to conflict/regulatory/missing-capability — a no-screen requirement is already
> coverage-mapped and never blocked) → re-scoped to a **no-regression** guard, G6 dropped as a wiring guard;
> **(2)** the "guards go **red** on the v1.5.0 baseline" framing was wrong — feature-detected guards **skip-NA**
> on a pre-feature template; only the **in-test string mutation** reds (the intake-overview model) → framing
> corrected; **(3)** every `(recommended)` / option-present / negative-absence check must be **span-scoped to
> the specific Q2/Q3 AUQ block and to emitted prompt events** (a bare `(recommended)` already exists at
> `start.md:57`, `api-go-live.md:32`); **(4)** the Tier-3 stop point needs a concrete mechanism (Step 10
> auto-chains into `/continue`). See **What the council changed** at the end.

**Testing against (BEFORE / baseline):** the newest snapshot `.targets/dev-v1.5.0/` (identical wording to
`.targets/dev-default/`). This baseline **already** renamed BFF → **"Server-side authentication"**
(`authMethod: server-side`); the feature's *new* behaviour is **not** present yet. So this is a **spec-ahead
plan**. **How the Tier-1 guards bite (corrected):** following the intake-overview model
(`tier-1-unit/intake-overview/rules.ts:4-9`), each detector is exercised **both ways as a pure-string unit
test** — **true** on the v1.6 wording, **false** on a named mutation — and that mutation-pair is what proves it
discriminates. The **real-template** assertion (`describe.skipIf(!TEMPLATE_PRESENT)` + ref-gate) **greens on the
v1.6.0 snapshot** and **skips Not-Applicable on v1.5.0** (feature-detected). It does **not** red on v1.5.0 — a
feature-detected guard skips a pre-feature template, it does not fail it. The ACs' live walkthroughs are
verified by **two Tier-3 captures**, frozen and replayed as **Tier-2** invariants.

> **Open dependency (flag, don't block):** the v1.6.0 snapshot that *implements* the feature does not exist on
> disk yet (only v1.5.0 is snapshotted). The Tier-1 **mutation unit tests** can be written and run now (they
> need no template); the real-template block **skips** until a `.targets/<ch>-v1.6.0/` snapshot (or a CLI build
> of this story) exists, then greens. Tier-3 likewise needs the built feature.

**Run static tier (PowerShell, from `c:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests`):**
```
$env:REPO_ROOT="…\.targets\<ch>-v1.6.0"; $env:EXPECT_TEMPLATE="1"; $env:EXPECT_TEMPLATE_REF="v1.6.0"; npm run test:tier1
```
**Discrimination is proved by the in-test mutation pairs, not by a baseline checkout.** Do **not** point
`REPO_ROOT` at `dev-v1.5.0` expecting a meaningful red: with `EXPECT_TEMPLATE_REF=v1.6.0` the identity guard
(`plan-scope.test.ts:136-140`) reds on the **version mismatch** (masking detector behaviour), and without it the
feature-detected block simply skips-NA. The real-template block is a **green-on-v1.6.0** confirmation; the reds
live in the unit mutations.

---

## The feature under test

Today intake assumes the backend **exists and runs elsewhere**: `/start` Q3 "Backend Readiness"
(`start.md:183`) offers only *running / in-development / N/A-no-backend*, server-side auth is **not**
recommended and its three follow-up URLs are **always** asked (`authentication-intake.md:25`), and the Step 6
smoke test writes `generated-docs/specs/api-smoke-test.sh` for any `existing-api`. The feature makes **building
the backend inside this project** the recommended answer, with **server-side sign-in built by that backend**,
and the epic plan covering the backend's work — while keeping the "backend elsewhere / no backend" paths
exactly as they are.

**Acceptance criteria (as given):**

1. **Intake recommends building the backend in this project** — a new Q3 answer "build the backend in this
   project", **marked recommended**; a "no backend" answer stays offered; a "backend elsewhere/running" answer
   stays offered.
2. **Sign-in and the backend are recorded as built in this project** — "Server-side authentication" is
   **recommended**; with nothing external to connect to, intake asks **no backend address or sign-in
   (login/userinfo/logout) address or credential**, runs **no connection test**, writes **no
   `api-smoke-test.sh`**; `project.md` §Data Source says the backend is **built in this project**, and
   §Authentication says sign-in is **built by this project's backend**.
3. **A requirement with no screen is planned into an epic like any other** — a backend-only requirement (a
   nightly archive job) is **assigned to an epic** in the coverage map, raises **no blocker**, and the owning
   epic's `brief.md` **lists** it with an **Out of Scope that does not exclude back-end work**.
   > **Council note — AC3 is a no-regression criterion, not a new-wiring one.** The v1.5.0 baseline **already**
   > does this: `feature-planner.md:263` auto-assigns every requirement to exactly one epic ("accidental gaps
   > never reach the user") and `:271-278` restricts blockers to `conflict | regulatory | missing-capability`
   > (a no-screen archive job is none), and `intake-agent.md:176`'s Out-of-Scope default never auto-excludes
   > back-end work. So there is **no v1.5→v1.6 behavioural delta** to mutation-couple. AC3 is tested as a
   > **regression guard inside the new backend-in-project path** (A-T6/A-T7/A-T8) — it confirms the new
   > `dataSource` branch does not regress coverage/blocker behaviour. It is **not** a Tier-1 wiring guard.
4. **A backend that runs elsewhere still gets its sign-in addresses and connection test** — the existing
   path is unchanged: userinfo/other addresses are asked, an unreachable backend is **reported**, and
   `api-smoke-test.sh` **exists**.
5. **The workflow guide describes intake as it now runs** — `Agent-Workflow-Guide.md` §Intake says the backend
   **can be built in this project** and that the connection test **runs only for a backend that runs
   elsewhere**.

**Template wiring the feature must introduce (anchors in `.targets/dev-v1.5.0/` baseline — the guard targets):**

| # | Where | Baseline today | Feature change (what a guard asserts on v1.6.0) |
|---|---|---|---|
| W1 | `.claude/commands/start.md` Q3 (`:183-201`) | options *running / in-dev / N/A* | add a **"build the backend in this project"** option carrying a **`(recommended)`** marker (house convention, e.g. `start.md:57`, `api-go-live.md:32`); keep a no-backend option; new `dataSource` value (impl-named, e.g. `backend-in-project`) |
| W2 | `.claude/commands/start.md` Q2 (`:168-181`) | three options, none recommended | mark **"Server-side authentication"** `(recommended)` |
| W3 | `.claude/policies/authentication-intake.md` Rule 4 (`:25`) | server-side **always** asks login/userinfo/logout + note | make the three URL follow-ups + note fire **only when the backend runs elsewhere**, not for backend-in-project |
| W4 | `.claude/commands/start.md` Step 6 (`:204-212`) + `api-connectivity-agent.md` (`writeShellArtifact :371`) | smoke test runs for `existing-api`, writes `api-smoke-test.sh` | **skip** the connectivity check (⇒ no `api-smoke-test.sh`) for backend-in-project; unchanged for `existing-api` |
| W5 | `.claude/agents/intake-agent.md` §Authentication (`:103`) + §Data Source (`:104`) + `.claude/templates/project.md` (§Auth ~`:62`, §Data Source ~`:76`) | maps `existing/new/mock` sources + endpoints | §Data Source renders **"built in this project"** and §Authentication **"sign-in built by this project's backend"** for the new value |
| ~~W6~~ | — | **baseline already coverage-maps every requirement and never blocks a no-screen one** (`feature-planner.md:263,:271-278`) | **No wiring change.** AC3 is a no-regression guard tested live (A-T6/7/8), not a Tier-1 mutation guard — see the council note under AC3. |
| W7 | `.template-docs/users/Help/Agent-Workflow-Guide.md` §Intake (connection-test sentence `:41`) | "If your project uses a real backend, Claude Code also runs a quick connection test…" | say the backend **can be built in this project** and the connection test runs **only for a backend elsewhere** |

---

## Tiering philosophy for this feature (mirrors `intake-claudemd-project-overview-test-plan.md`)

- **Tier 1 — static, mutation-coupled wiring regression-guards (no spend; run now).** Each guard is a pure
  detector in `rules.ts`, exercised **both ways** as a unit test (**true** on the v1.6 wording, **false** on a
  named mutation — this pair is what proves it bites), **and** asserted against the real template under
  `REPO_ROOT` (**green on v1.6.0; skips-NA on v1.5.0** — feature-detected, never false-red). Every detector is
  **span-scoped to the specific question block / line it guards** — a `(recommended)` marker check scopes to the
  Q2/Q3 `AskUserQuestion` options block (a bare `(recommended)` already exists at `start.md:57`,
  `api-go-live.md:32`, so a whole-file match is vacuous-green). **Necessary, not sufficient** — no AC is marked
  green by Tier 1.
- **Tier 3 — live behavioural captures (spend + sign-in gated).** The ACs are live `/start` walkthroughs. Two
  captures are the real verification: **Capture A** (backend-in-project, drives AC1–AC3+AC5-artifact) and
  **Capture B** (backend-elsewhere regression, drives AC4). Every check is a **deterministic parse of emitted
  events** — the `AskUserQuestion` tool-call's options array (option present + `(recommended)` marker **inside
  that block**), the **absence of a specific prompt event** (an emitted `AskUserQuestion`/plain-text address
  prompt — *not* a substring of transcript prose, which may quote the option/URL names), the connection-failure
  line, and generated-file existence/wording.
- **Tier 2 — deterministic invariants over the two frozen captures** (`loadGoldenRun('<slot>')`), plus
  planted-bad calibration slots so each check is shown to go red.
- **No AI/LLM judge anywhere.** The two mildly-worded residuals (AC2 §Data Source "built in this project",
  §Authentication "built by this project's backend") are asserted as **anchored-phrase checks agreed with the
  implementer** (coupling the test to the shipped wording, documented in the plan), never routed to a judge. If
  the team wants an eyeball residual, reuse the existing `reviewSuite`/`human-review.ts` harness as an
  **optional** skip-until-verdict check — not required for green.

---

## New fixtures/benchmarks to add (`benchmark-files/`)

No existing benchmark matches the feature's `demo-app` (orders list + nightly archive job). The ACs prescribe
the scaffold exactly, so create two minimal benchmarks:

- **`benchmark-files/demo-app/`** — `documentation/requirements.md` with the **two** AC lines verbatim:
  *"Staff can see a list of orders and their status."* and *"Every night, orders older than 90 days are
  archived automatically."* Plus `answers.json` selecting **Q2 = Server-side authentication**,
  **Q3 = build the backend in this project**, roles = any (e.g. Internal Tool). Model `answers.json` on
  `contact-form/answers.json` (the "no external backend" shape). Drives AC1–AC3, AC5-artifact.
- **`benchmark-files/demo-app-outside/`** — `documentation/requirements.md` with **only** the orders line;
  `answers.json` selecting **Q2 = Server-side authentication**, **Q3 = backend already running elsewhere**,
  and sign-in addresses on **`http://localhost:9999`** (userinfo `…/userinfo`), an **unused port** so the
  connection test fails. Model on `transactions/answers.json` (the "backend elsewhere" shape). Drives AC4.

Both are front-end-only scaffolds — no `backend/` dir needed (the backend is built-in-project for A, and
deliberately unreachable for B).

---

## Tier 1 — static wiring regression-guards

New files `tier-1-unit/intake-backend-offer/rules.ts` + `intake-backend-offer.test.ts`, modelled on
`tier-1-unit/intake-overview/{rules.ts,intake-overview.test.ts}`: pure span-scoped detectors. **Copy** the
local scoping helpers `commandLines(md)` / `nonFenceText(md)` from `intake-overview/rules.ts` (they live there,
**not** in `helpers/`), the real-template block `describe.skipIf(!TEMPLATE_PRESENT)` + the `EXPECT_TEMPLATE_REF`
guard line. Each detector is asserted **true on v1.6 wording / false on a named mutation**, and **scoped to the
specific question block** (not a whole-file grep).

| ID | Detector (over which file) | Asserts (v1.6 green) | Goes red when (baseline / mutation) | AC |
|---|---|---|---|---|
| G1 | `start.md` Q3 options block (`:187-189`), span-scoped | a "build the backend in this project" option **with `(recommended)`** *inside the Q3 block*; a no-backend option still present; a backend-running-elsewhere option still present | mutation: Q3 block without the build-in-project option / without its marker | 1 |
| G2 | `start.md` Q2 options block (`:174-176`), span-scoped | "Server-side authentication" carries `(recommended)` *inside the Q2 block* | mutation: Q2 block without the marker (must not match the unrelated `(recommended)` at `:57`) | 2 |
| G3 | `authentication-intake.md` Rule 4 | the login/userinfo/logout follow-ups + backend note are **gated on backend-elsewhere**, not unconditional on server-side | baseline unconditional Rule 4 | 2,4 |
| G4 | `start.md` Step 6 + `api-connectivity-agent.md` | the connectivity check / `api-smoke-test.sh` write is **skipped** for the backend-in-project `dataSource`; still runs for `existing-api` | baseline (runs for all `existing-api`; no backend-in-project branch) | 2,4 |
| G5 | `intake-agent.md` §Data Source + §Authentication rows + `templates/project.md` | the new `dataSource` maps to a §Data Source "built in this project" line and §Authentication "built by this project's backend" line | baseline mapping (external endpoints only) | 2 |
| ~~G6~~ | **dropped** | — | AC3 has no v1.5→v1.6 wiring delta (baseline already coverage-maps + never blocks a no-screen requirement, `feature-planner.md:263,:271-278`). Tested live as a no-regression guard (A-T6/7/8). | 3 |
| G7 | `Agent-Workflow-Guide.md` §Intake, scoped to the connection-test sentence (`:41`) | says backend **can be built in this project** AND connection test **only for a backend elsewhere** | mutation: the baseline `:41` "If your project uses a real backend…" sentence | 5 |

Guards are feature-detected (skip Not-Applicable on a template predating v1.6.0 — never false-red) and
ref-gated. On a Bootstrapper-shaped dev build (defs nested under `src/Bootstrapper.Framework/.claude/`), the
detector resolves the nested path like the existing intake suite, or skips NA if absent.

---

## Tier 3 — live behavioural captures (spend + sign-in gated)

**⚠️ Spend / sign-in gate.** Both captures run `claude -p … --dangerously-skip-permissions` live against the
template and **spend tokens on an authenticated CLI.** Print a notice naming the sign-in requirement + expected
spend and get explicit go-ahead before any live phase. A cheap **plan-dry** probe runs first.

**Driver changes (net-new build item).** `live-driver.ps1` answers intake **non-interactively via
`TIER3-ANSWERS.json` + an embedded prompt directive** — there is no menu-keystroke driver. The embedded
sign-in string currently hard-codes the **BFF** answer (`live-driver.ps1:97-99,:135`); it must be updated to
drive the feature's choices (**Server-side auth**, **build backend in project** for A; **backend elsewhere** +
localhost:9999 addresses for B). The deterministic AC checks ("option offered", "marked recommended") read the
**`AskUserQuestion` options array in the transcript**, which records the full option list regardless of which
answer the driver selects. New capture script `tier-3-automated/capture-intake-backend-offer.ps1`, `-Phase`
gated (`dryrun|setup|plan-dry|build|freeze`), dot-sourcing `live-driver.ps1` / `New-Tier3Scaffold`, modelled on
`capture-build-tests-together.ps1`.

### Capture A — `demo-app` (backend-in-project) — AC1, AC2, AC3, AC5-artifact

Scaffold `demo-app` (per the AC: `stadium-builder init demo-app` from this story's CLI build, or
`New-Tier3Scaffold` from the v1.6 snapshot), seed the two-line `requirements.md`, drive
`/start` → "Share what I have" → intake → epic-plan approval. **Stop mechanism (concrete):** Step 10
auto-chains into `/continue` with no prompt (`start.md:456`), so there is no natural pause at "Starting on
<first epic>". Stop one of two ways: **(a)** an **intake-only driver directive** in the capture prompt that
forbids invoking `/continue` after the hand-off line, or **(b)** a **transcript-watch kill** on the hand-off
line before `/continue` writes any `web/` source. Freeze gate below proves BUILD was not entered.

- **A-T1 (AC1)** — in the **Q3 `AskUserQuestion` tool-call's options array**: an option to **build the backend
  in this project** is present, it carries the **recommended** marker *in that option*, **and** a no-backend
  option is present. (Scoped to the Q3 options array — not a transcript-wide string match.)
- **A-T2 (AC2 recommended)** — in the **Q2 options array**: "Server-side authentication" carries the
  **recommended** marker in that option.
- **A-T3 (AC2 no external prompts)** — between Q2/Q3 and plan approval there is **no emitted prompt event** (an
  `AskUserQuestion` or plain-text input request) for a backend address or a login/userinfo/logout address or
  credential. Asserted over **prompt/tool-call events**, not substring presence in prose (the orchestrator may
  *quote* the URL names, `start.md:179`).
- **A-T4 (AC2 no smoke test)** — `demo-app/generated-docs/specs/api-smoke-test.sh` **does not exist**; no
  `api-connectivity-agent` Call B / `run-smoke-test.js` **tool invocation** in the transcript.
- **A-T5 (AC2 project.md)** — `project.md` §Data Source & Backend Integration says the backend is **built in
  this project** (anchored phrase); §Authentication says sign-in is **built by this project's backend**
  (anchored phrase).
- **A-T6 / A-T7 / A-T8 (AC3 — no-regression guards, not feature-delta).** At plan approval, **no blocker** about
  archiving old orders is raised (A-T6); `generated-docs/epic-plan.md` §Coverage assigns the **archiving**
  requirement to an epic (A-T7); the owning epic's `brief.md` **lists** it and its **§Out of Scope does not
  exclude back-end work** (A-T8). **These hold on the baseline too** (`feature-planner.md:263,:271-278`) — their
  value here is confirming the **new backend-in-project `dataSource` path** does not regress coverage/blocker
  behaviour, *not* detecting new behaviour. Labelled as such so they are never read as proof of a feature delta.

**Stop point & freeze gate (accept only if all hold):** `project.md` + `epic-plan.md` + per-epic `brief.md`
present on main; **no** developer-authored source on the `web/` tree **and no `generated-docs/epics/*/stories/`
files** (neither `/continue` PLAN nor BUILD entered); the hand-off line was emitted. If the run overshot, reject
and re-capture.

### Capture B — `demo-app-outside` (backend elsewhere, port 9999 unused) — AC4

Scaffold `demo-app-outside`, seed the single orders line, leave **port 9999 unused**, drive `/start` →
"Share what I have" → Q3 **backend already running elsewhere** (`existing-api` — this is what gates the Step 6
Call B smoke test) → Q2 **Server-side authentication** → answer sign-in addresses on `http://localhost:9999`
(userinfo `…/userinfo`). **The `demo-app-outside/answers.json` must assert Q3 = "Yes, it's running" explicitly**
(don't model the mock-fallback wording of `transactions/answers.json`, which steers to "build against mocks
unless the backend is up") so the connection test actually *runs* against the unreachable `:9999` and fails.

- **B-T1 (AC4 asks)** — an emitted prompt event **requests a user-info address** (and the other server-side URLs).
- **B-T2 (AC4 fails)** — Claude **reports it could not reach the backend** (expect `connection_refused` on
  `:9999`; assert the failure category, not just a substring).
- **B-T3 (AC4 artifact)** — `demo-app-outside/generated-docs/specs/api-smoke-test.sh` **exists**.

**Artifacts preserved** (into `TestResults/intake-backend-offer-<app>@<ch>-v1.6.0/<model>/<ts>/` and the frozen
slot): full `--output-format stream-json` transcript, `generated-docs/` tree (`project.md`, `epic-plan.md`,
`epics/*/brief.md`, `specs/` listing), and a `recorded/` dir with the connection-test output (B).

---

## Tier 2 — recorded-run invariants (replay frozen captures; no live AI)

New files `tier-2-recorded-run/intake-backend-offer/*.test.ts`, fed by
`loadGoldenRun('intake-backend-offer-demo-app')` and `loadGoldenRun('intake-backend-offer-outside')` (slots
under `fixtures/golden-runs/`, each with `generated-docs/`, `transcript.jsonl`, `recorded/`, `meta.json`;
`describe.skipIf(!golden.present)`).

- **T2-A** = A-T1…A-T8 over the frozen Capture-A transcript + `generated-docs` tree.
- **T2-B** = B-T1…B-T3 over the frozen Capture-B transcript + `recorded/` connection output.

**Planted-bad calibration slots (prove each check reds), hand-authored docs-tree fixtures:**
1. `…-demo-app-SMOKE` — Capture-A tree **with** an `api-smoke-test.sh` present → **reds A-T4**.
2. `…-demo-app-EXTERNAL` — §Data Source still says "external / runs elsewhere" → **reds A-T5**.
3. `…-demo-app-BLOCKER` — archiving raised as a blocker / parked in Out-of-Scope as back-end work →
   **reds A-T6/A-T8**, and absent from the Coverage table → **reds A-T7**.
4. `…-outside-NOSMOKE` — Capture-B tree **without** `api-smoke-test.sh` → **reds B-T3**.

Calibration slot 3 (`…-demo-app-BLOCKER`) is a **constructed** adversarial tree (it does not arise from the
baseline, which never blocks a no-screen requirement) — it proves A-T6/7/8 *can* red, i.e. they'd catch a
regression in the new path. The Tier-1 reds live in the **in-test mutation pairs**, not in a v1.5.0 checkout
(which skips-NA).

---

## Acceptance-criteria → test traceability

| AC clause | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| 1 — build-in-project offered, recommended, no-backend still offered | G1 | T2-A (A-T1) | A-T1 |
| 2 — server-side recommended | G2 | T2-A (A-T2) | A-T2 |
| 2 — no address/credential prompt, no connection test | G3, G4 | T2-A (A-T3) + calib 2 | A-T3 |
| 2 — no `api-smoke-test.sh` | G4 | T2-A (A-T4) + calib 1 | A-T4 |
| 2 — project.md Data Source / Authentication wording | G5 | T2-A (A-T5) + calib 2 | A-T5 |
| 3 — no archiving blocker *(no-regression)* | — *(no delta)* | T2-A (A-T6) + calib 3 | A-T6 |
| 3 — archiving coverage-mapped to an epic *(no-regression)* | — | T2-A (A-T7) + calib 3 | A-T7 |
| 3 — brief lists it; Out-of-Scope keeps back-end *(no-regression)* | — | T2-A (A-T8) + calib 3 | A-T8 |
| 4 — asks addresses, reports unreachable, smoke-test exists | G3, G4 | T2-B + calib 4 | B-T1, B-T2, B-T3 |
| 5 — guide §Intake wording | G7 | — | — (static) |

---

## Feasibility, build items, and prerequisites

**Already there (reuse):** `test:tier1`/`test:tier2`; `REPO_ROOT`/`TEMPLATE_REF`/`TEMPLATE_PRESENT`
(`helpers/target.ts`) + the `EXPECT_TEMPLATE_REF` per-file guard idiom; `commandLines`/`nonFenceText` scoping
helpers (local to `tier-1-unit/intake-overview/rules.ts` — **copy**, not a shared import); `loadGoldenRun(slot)`
multi-slot loader (`helpers/golden-run.ts`); `resolveShippedUserFile`;
`New-Tier3Scaffold` + `Invoke-ClaudeHeadless` + `-Phase` gating (`live-driver.ps1`,
`capture-build-tests-together.ps1`); `contact-form`/`transactions` `answers.json` shapes to model the two new
benchmarks on; the `reviewSuite`/`human-review.ts` harness if an optional eyeball residual is wanted.

**Net-new build items:**
1. `tier-1-unit/intake-backend-offer/{rules.ts,intake-backend-offer.test.ts}` — G1–G5, G7 (G6 dropped),
   mutation-coupled, span-scoped, ref-gated. The **mutation unit tests** can be written + run **now** (they
   need no template); the real-template block skips until the v1.6.0 snapshot exists.
2. `benchmark-files/demo-app/` and `benchmark-files/demo-app-outside/` (+ `answers.json`).
3. `live-driver.ps1` — replace the hard-coded BFF sign-in directive (`:97-99,:135`) with the feature's choices;
   extend the answer directive to drive **Q3 = build-in-project** and the backend-elsewhere + localhost:9999
   answers.
4. `tier-3-automated/capture-intake-backend-offer.ps1` — `-Phase`-gated, two scenarios (A/B), freeze gate +
   slot write, then runs the Tier-2 suite as the conformance gate.
5. `tier-2-recorded-run/intake-backend-offer/*.test.ts` + the 4 planted-bad calibration slots (calibrations
   can be built before the live capture; the GOOD slots land with the capture).

**Prerequisites:** an authenticated Claude CLI + token budget for Tier-3; the **v1.6.0 feature build/snapshot**
for Tier-3 green (open dependency above); Node ≥22 on the host.

---

## Suggested order of work

1. **Tier 1** mutation unit tests (G1–G5, G7) — cheapest, runs now, each proved by its true-on-v1.6 /
   false-on-mutation pair (not by a baseline checkout); the real-template block greens when the v1.6.0 snapshot
   lands.
2. Add the two **benchmarks** + `answers.json`; build the 4 **planted-bad Tier-2 calibration slots** and prove
   each check reds **before** any live spend.
3. Update **`live-driver.ps1`** + write **`capture-intake-backend-offer.ps1`**; run a cheap **plan-dry** probe
   (confirms the archiving requirement is coverage-mapped, not blocked) behind the spend gate.
4. Run **Capture A** + **Capture B** live, apply the freeze gates, freeze both GOOD slots.
5. Wire **Tier 2** against the good + calibration slots; save `PROOF.md` (per-AC transcript excerpts + file
   checks) under `TestResults/intake-backend-offer-…/`.

---

## Appendix — evidence (anchors in `.targets/dev-v1.5.0/`)

- `.claude/commands/start.md` — Q2 auth `:168-181` (options `:174-176`, follow-ups `:178-181`); Q3 backend
  readiness `:183-201` (options `:186-189`, matrix `:191-200`); Step 6 smoke test `:204-212`; Step 7 project.md
  `:216-219`; epic-plan.md + §Coverage format `:415-446`; handoff "Starting on <first epic>" `:450-454`;
  "(recommended)" label convention `:57`.
- `.claude/policies/authentication-intake.md` — user-facing Rule 4 (server-side ⇒ 3 URLs) `:25`; Backend API
  Auth "always run the check except mock-only/new-api" `:43`.
- `.claude/agents/intake-agent.md` — §Authentication mapping `:103`, §Data Source & Backend Integration mapping
  `:104`, §Out of Scope default `:176`.
- `.claude/agents/api-connectivity-agent.md` — `api-smoke-test.sh` path `:70`, `writeShellArtifact` `:371`,
  shell-artifact write `:401`, checklist `:502`.
- `.claude/agents/feature-planner.md` — decompose mode `:13,:26,:251`; **requirement auto-assign** `:263`;
  **blocker categories** (`conflict | regulatory | missing-capability`) `:271-278` (why AC3 has no delta).
- `.claude/templates/project.md` — §Authentication `:64`, §Data Source & Backend Integration `:78`
  (incl. `Smoke-test mode` row).
- `.template-docs/users/Help/Agent-Workflow-Guide.md` — §Intake `:38-41`; connection-test sentence is line
  `:41` (`:40` is blank).
- Harness: `helpers/target.ts`, `helpers/golden-run.ts` (`loadGoldenRun`), the `EXPECT_TEMPLATE_REF` guard at
  `tier-1-unit/plan-scope/plan-scope.test.ts:136-140`; `tier-1-unit/intake-overview/{rules.ts,
  intake-overview.test.ts}` (local `commandLines`/`nonFenceText`, and the "feature already implemented →
  mutation-pair, not baseline-red" model at `rules.ts:4-9`); `tier-3-automated/live-driver.ps1`
  (`New-Tier3Scaffold` `:37`, prompt `:78/:123`, hard-coded sign-in `:96-99`), `capture-build-tests-together.ps1`
  (`-Phase` model).
- Closest precedent plan: `test-plans/intake-claudemd-project-overview-test-plan.md`.

---

## What the council changed (this is v2)

1. **AC3 has no v1.5→v1.6 wiring delta — G6 dropped.** The baseline already auto-assigns every requirement
   (`feature-planner.md:263`) and restricts blockers to `conflict|regulatory|missing-capability` (`:271-278`),
   and never auto-excludes back-end work (`intake-agent.md:176`). A no-screen archive job is already
   coverage-mapped and never blocked, so there was nothing to mutation-couple. AC3 is now an explicit
   **no-regression** guard (A-T6/7/8) inside the new backend-in-project path, with a **constructed** adversarial
   calibration (calib 3) to show the checks can red.
2. **"Red on the v1.5.0 baseline" was wrong.** Feature-detected guards **skip-NA** on a pre-feature template;
   only the **in-test string mutation** reds (the `intake-overview/rules.ts:4-9` model). Framing corrected
   throughout; the run-section no longer claims a meaningful baseline red (with `EXPECT_TEMPLATE_REF=v1.6.0` a
   v1.5.0 checkout reds on *version identity*, masking detector behaviour).
3. **Vacuous-green scoping.** A bare `(recommended)` already exists at `start.md:57` / `api-go-live.md:32`, so
   every marker / option-present detector is now **span-scoped to the Q2/Q3 `AskUserQuestion` block**, and the
   Tier-3 negative-absence checks (A-T3/A-T4) assert over **emitted prompt/tool-call events**, not substrings of
   prose (which may quote the URL/option names, `start.md:179`).
4. **Feasibility.** Stop point given a concrete mechanism (Step 10 auto-chains into `/continue`, `:456`) —
   intake-only directive **or** transcript-watch kill, with a `no stories/ + no web/ source` freeze gate;
   `demo-app-outside/answers.json` must force Q3 = "running" so the smoke test actually fires at the unreachable
   `:9999`; `commandLines`/`nonFenceText` are **copied** from intake-overview (not shared helpers).
5. **Anchors.** Minor drift corrected: Agent-Workflow-Guide connection sentence `:41` (not `:40-41`);
   `project.md` §Auth `:64` / §Data Source `:78` (were tilde-approximate); live-driver sign-in `:96-99`.

**Anchor axis was otherwise clean** — Q2/Q3/Step-6/handoff, `authentication-intake.md:25/:43`,
`intake-agent.md:103/:104/:176`, `api-connectivity-agent.md` artifact anchors, and the harness references all
verified correct.
