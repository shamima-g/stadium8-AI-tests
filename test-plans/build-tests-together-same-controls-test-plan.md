# Test plan — one agent writes each story's Vitest + Playwright tests, so both expect the same controls

> **v2 — reshaped by a four-lens council** (falsifiability · claim-accuracy · adversarial/vacuous-green ·
> feasibility). The first draft's headline parity check was **vacuous on the actual bug** (it joined the two
> files on control *name*, so a name divergence — half of AC1 — silently fell out of the comparison), and the
> "tests fail before build" check proved only a non-zero exit, not per-story red-because-unbuilt. Both are
> fixed below. See **"What the council changed"**.

**Testing against:** the template snapshot at `C:\TestsArchives\stadium8-tests\stadium-builder 26-10`
(note the space in the folder name). `template-version.json` → `templateRef: v1.4.0`, `source: release`.
Git HEAD is **4 commits past / divergent from the `v1.4.0` tag** (`git rev-list --count v1.4.0..HEAD` = 4;
`git describe` shows `…-30-g057a164` only because the nearest ancestor tag is `stadium-builder-01`, not
`v1.4.0`). The single-agent change is one of those four `[Unreleased]` commits:

> `4666e23  feat(test-generator): write each story's Vitest and Playwright tests together so that they use the same controls`

This snapshot is already **release-shaped** (`source: release`, ships `CLAUDE.md` + `CLAUDE.user.md`), the
shape captures must run against. `generated-docs/epics/` does **not** exist yet — no dogfood BUILD has run,
so the Tier-3 capture starts clean.

> **The prior snapshot `stadium-builder23-10` is the BEFORE state** (two `test-generator` calls per story,
> vitest + playwright in parallel). It is the source of the **broken-case wording** for the Tier-1 guards —
> but note you **cannot** simply point `REPO_ROOT` at it to get a red: it is a .NET Bootstrapper repo whose
> defs are nested under `src\Bootstrapper.Framework\.claude\` and use `app-frontend/`, so a feature-detected
> detector finds no `<root>/.claude` and **skips Not-Applicable**. The broken case is produced by surgically
> patching the two-call wording onto a **temp copy of 26-10** (see RB-BT below).

**Run static tier (PowerShell, from `c:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests`):**
```
$env:REPO_ROOT="C:\TestsArchives\stadium8-tests\stadium-builder 26-10"; $env:EXPECT_TEMPLATE="1"; $env:EXPECT_TEMPLATE_REF="v1.4.0"; npm run test:tier1
```
This passes the identity guard: the guard compares `TEMPLATE_REF` — read from `template-version.json`
(`v1.4.0`) by `helpers/target.ts`, **not** from git — so `"v1.4.0" === "v1.4.0"`. The `EXPECT_*` comparison
is the **per-file guard idiom** (e.g. `tier-1-unit/plan-scope/plan-scope.test.ts:136-140`), not something
`target.ts` consumes; the new `build-tests-together/` test files must **copy that guard line** to be
ref-gated. (Note: this guard asserts the *declared* identity; it does not prove the feature commit is present
— that is the job of feature-detection below.)

---

## Path corrections to the AC text (this template version)

| AC text | Actual path in `26-10` |
|---|---|
| `web/src/tests/integration/epic-<slug>-story-<N>-*.test.tsx` | `web/src/__tests__/integration/epic-<slug>-story-<N>-<title>.test.tsx` (double-underscore `__tests__`; `vitest.config.ts` include = `src/**/__tests__/**`) |
| `web/e2e/epic-<slug>-story-<N>-*.spec.ts` | `web/e2e/epic-<slug>-story-<N>-<title>.spec.ts` ✓ |
| `generated-docs/epics/<slug>/state.json` | ✓ — `stories` is an **object keyed by story number** (`epic-state.js:26`); count the keys |

---

## The feature under test

At BUILD, before any story is coded, the orchestrator generates every story's tests. The change moves this
from **two agents per story** (one Vitest author, one Playwright author, each guessing controls
independently) to **one agent per story that writes both files**, so a control is described once and rendered
identically into both. Wiring points (all verified in `26-10`):

- **`continue.md` Step B0 (`:252`)** — *Epic mock-data bootstrap*: one `test-generator` call writes the
  epic's shared mock data under `web/src/mocks/data/`, writes no test files, runs **once before** the loop.
- **`continue.md` Step B0.2 (`:286`, `:290`)** — "For each story in the epic, launch **one** `test-generator`
  call (it writes both test files), all stories as one Task batch." `:300` — "Both files import the epic's
  shared mock data from `web/src/mocks/data/` (B0)". `:308` — a **missing-spec regeneration** path may
  re-invoke `test-generator` for offenders (matters for the count check, T3.1).
- **`test-generator.md`** — `mode: story` (`:22`) "writes both test files"; one-call-per-story (`:11`); the
  **parity mechanism** (`:296`) "List the story's controls before writing either file … fix its role and
  accessible name **once** … In both files, find each control the same way"; success criterion (`:384`)
  "Every control is found and interacted with the same way in both files"; each test carries an `// AC-N`
  tag (`:282`, `:301`); "no `vitest` tags → no Vitest file, return only the Playwright line" (`:298`);
  routable/`fixme` (`:90-91`); the `vitest | playwright | none` coverage enum (`:20`); acceptable
  red-before-build failure signatures (`:312`); `TESTS WRITTEN:` return line with the paths (`:358`).
- **`testing-policy.md`** — the coverage-tag system and three layers; `getByRole` query priority (`:101-112`,
  but `getByLabelText` is #2 and the template's own Playwright example fills inputs via `getByLabel`,
  `test-generator.md:254-255`); non-routable stubs (`:420-436`).
- **`naming-conventions.md` (`:26`)** + PreToolUse hook `enforce-generated-doc-names.js` — the spec/test
  filename regexes.

**Acceptance criteria (as given):**

1. **Each story's tests are written by one agent, and both files expect the same controls** — a control has
   the same **role** and **name** in the story's Vitest file and its Playwright spec.
2. **Every test file a developer needs is in place and failing before its story is built** — each story still
   gets both files (unless its agent reported no Vitest criteria), in the state a developer starts from.

---

## What the council changed (this is v2)

1. **Parity check compares (strategy, role) SIGNATURE SETS joined on accessible name, and reports what it
   cannot compare.** v1 built `{name → role}` and compared only roles. Two corrections:
   - **Join key is the accessible name, not the AC id.** (The council proposed joining on `// AC-N`; while
     building, verification of the real template showed that is wrong here — `coverage` is a *single* tag per
     AC (`vitest | playwright | none`, test-generator.md:20), so the two files cover **disjoint** ACs and an
     AC-join would find nothing. A control is matched across the files by its **name**.)
   - **Compare the set of (strategy, role) signatures, not just role.** This catches the reported bug (same
     name "Status", `radiogroup` vs `combobox`) **and** strategy divergence (`getByRole('textbox')` vs
     `getByLabel` for the same name — a violation of "find each control the **same way**", test-generator.md:296).
   - **The one case it cannot catch is reported, never swallowed:** same control named *differently* in each
     file (`'Priority'` vs `'Priority level'`) — nothing static ties the two names to one control. Those names
     surface in `uncompared.{vitestOnly, playwrightOnly}` for a human to eyeball in PROOF.md; a story with no
     shared name is `skipped-no-overlap` (never green); a file that contains queries but parses to zero refs
     **throws**.
2. **Extractor covers all accessibility queries and normalizes names.** Not just `getByRole` —
   `getByLabelText`/`getByPlaceholderText`/`getByDisplayValue`/`getByTestId` too (the template uses
   `getByLabel` for form fields). Names are normalized (strip regex delimiters/flags, `{exact}` wrappers,
   lowercase, collapse whitespace) so `/sign in/i` and `'Sign In'` match; statically-unresolvable names
   (variables, template literals) are recorded as **UNCOMPARED**, never silently dropped; the parser
   **throws on parse failure** (never returns an empty map that reads as green).
3. **"Fails before build" is per-story and failure-classified.** v1's epic-level `npm test` non-zero exit
   proved only that *something* failed. v2 asserts, **per story that has a Vitest file**, ≥1 non-`fixme`
   test, failing with a not-yet-implemented signature (`test-generator.md:312`), and explicitly **rejects**
   "no tests found" / skipped / parse / type errors as satisfying the check; adds a Vitest parse/collect gate
   alongside the Playwright `--list` gate.
4. **Missing-Vitest excuse is tag-checked, not self-reported.** A missing Vitest file is allowed **only** when
   the story's own ACs carry zero `vitest` tags — not merely because the agent returned a Playwright-only
   line (which is the very thing under test). A missing return line is red, not excused.
5. **Agent-count is robust.** Count **distinct de-duplicated** `test-generator` Task spawns by tool_use id /
   story target (B0.2 may regenerate, `:308`); exclude **parked/deferred** story keys; distinguish the
   `epic-mocks` call from `story` calls by **structured `subagent_type` + return line** (`MOCK DATA READY`
   vs `TESTS WRITTEN`) / files written, **not** by regexing a prose `mode:` token out of the prompt.
   `epic-mocks ∈ {0,1}` (skipped when the epic has no API behaviour; `contact-form` has a mock data source,
   so it runs — assert accordingly but don't hard-require 1 in general).
6. **Tier-1 broken-case scope corrected.** Only T1.1–T1.3 are coupled to the real two-call→one-call
   regression. B0-before-B0.2 ordering, the naming regex, and the fixme/vitest rules are **identical** in
   `23-10` and `26-10` — so T1.4–T1.6 are "adjacent invariants guarded by a **synthetic** mutation," not by
   the real baseline. The "red on 23-10" claim is scoped to T1.1–T1.3 and restated as "red on a 26-10 temp
   copy surgically patched with the 23-10 two-call wording."
7. **Calibration strengthened.** The radio-vs-combobox-same-name slot only exercises role-on-name-match (the
   already-working path). Added a **name-divergence** slot and a **query-strategy-divergence** slot
   (`getByLabelText` in one file vs `getByRole` in the other), plus an **unjustified-missing-Vitest** fixture.
8. **Tier-2 asserts recorded outputs, not live re-runs.** `loadGoldenRun` clones the bundle but does not
   `npm install`, and `node_modules` isn't bundled — re-running vitest/eslint in Tier-2 would break the
   fast/offline model. Tier-2 asserts over the command **outputs captured at Tier-3**; any live re-run is
   env-gated opt-in.

**No AI/LLM judge is used anywhere.** Every check — including control parity — is a deterministic parse of
the generated files/transcript or a deterministic command. There is no subjective residual to route to human
review.

---

## The feature is implemented — so this is a behavioural plan + regression-guard

The single-agent contract already exists in `26-10`, so static checks pass today; a static check proves
nothing unless it can also go red on the exact regression it guards. **Tier 1 is a wiring regression-guard
only** (necessary, not sufficient — no AC is marked green by Tier 1). **The ACs as written are a live
walkthrough** — the real verification is the **Tier-3 live capture**, frozen into a golden-run bundle and
replayed as **Tier-2** invariants.

---

## Tier 1 — static wiring regression-guards (no spend; run now)

Scope: the `26-10` template via `REPO_ROOT`. New files under `tier-1-unit/build-tests-together/`, each
feature-detected (`describeTemplate`) and ref-gated (copy the `EXPECT_TEMPLATE_REF` guard line); on a
template predating `4666e23` they **skip Not-Applicable**, never false-red.

**RB-BT (rollback recipe for the broken cases).** The broken case is produced by `temp-project.ts`-copying
`26-10` and applying **one surgical mutation per detector** (not a wholesale file swap — a swap would drag in
`app-frontend/` paths and red T1.5 for the wrong reason, breaking mutation-coupling). The two-call wording is
sourced verbatim from `23-10\src\Bootstrapper.Framework\.claude\commands\continue.md:290` and
`…\agents\test-generator.md:22`.

| ID | Detector | Coupled to real 23-10 regression? | Goes red when (named mutation) |
|---|---|---|---|
| T1.1 | continue.md B0.2 spawns **one** `test-generator` call per story that "writes both test files"; contains **no** per-story batch launching a separate `vitest` call and a separate `playwright` call. | **Yes** | Patch B0.2 to the 23-10 "launch two `test-generator` calls … vitest / playwright in parallel" block. |
| T1.2 | test-generator exposes **`mode: story`** ("writes both files"); defines no per-story `mode: vitest`/`mode: playwright` authoring. | **Yes** | Re-add the split `vitest`/`playwright` per-story modes. |
| T1.3 | test-generator carries the **parity step** (`:296`) + success criterion (`:384`). | **Yes** | Delete the "fix role and accessible name once / same way in both files" instruction. |
| T1.4 | **Ordering**: B0 (`epic-mocks`) before B0.2; B0.2 states both files import `web/src/mocks/data/`. | No — synthetic | Remove the ordering / shared-import clause. *(adjacent invariant; present in 23-10 too)* |
| T1.5 | naming regex (`:26`) + `web/src/__tests__/integration/…test.tsx` / `web/e2e/…spec.ts` output paths intact. | No — synthetic | Change the output dir or loosen the regex. |
| T1.6 | Policy rules present: "no `vitest` tags → no Vitest file"; non-routable → `test.fixme()` stub, forbidden on routable. | No — synthetic | Remove either rule. |

---

## Tier 3 — live behavioural capture (spends tokens; needs sign-in — see gate)

**⚠️ Spend / sign-in gate.** This phase runs `claude -p …` live against the template — **requires an
authenticated Claude CLI and spends tokens.** Print a notice naming the sign-in requirement + expected spend
and get explicit go-ahead first. Do **not** run it while merely drafting.

**Benchmark:** `contact-form` (lightest fixture with ≥2 roles + auth + a mock data source). **Caveat:** epic
decomposition is decided live at PLAN, so epic 1 is *not guaranteed* multi-story. **Target the first epic
with ≥2 stories** and assert `count(state.json.stories) ≥ 2` as a freeze gate; a cheap **PLAN-only dry run**
first confirms the decomposition before spending on the full capture.

**Setup (criterion-1 setup):** a portable dogfood scaffold from `26-10` (roots as params / `$PSScriptRoot`-
derived; benchmark docs → `documentation/`; `answers.json` → `TIER3-ANSWERS.json`; a bare local git remote
inited), driven `/start` → intake → PLAN → first (≥2-story) epic approved → BUILD. Model on
`capture-plan-design-update.ps1`.

**Stop point (load-bearing, and the weakest mechanism — guard it).** Criterion 2 needs "every test agent
finished" but stories **not yet built**. B0.2 is a *silent internal step* — no HTML gate, no commit, and
`state.json.phase` stays `BUILD` through the whole developer loop — so there is no natural pause to stop on.
The stop is a **prompt instruction** ("run BUILD only through test generation, then stop; do not code any
story"), and the capture is **accepted only if a deterministic post-hoc freeze gate holds**:
- all expected test files present under `web/src/__tests__/integration/` + `web/e2e/`, **and**
- **every `state.json.stories[N].startedAt` is `null`** (`epic-state.js:26,42-43` — stamped when a story goes
  in-progress at B1), **and**
- no developer-authored component/source files on the tree.

If a developer ran (overshoot), **reject and re-capture**.

**Artifacts the capture must preserve** (into `TestResults/build-tests-together@release-v1.4.0/<model>/<ts>/`
and the frozen bundle): the full `--output-format stream-json` transcript; `generated-docs/epics/<slug>/
state.json`; the generated `*.test.tsx` and `*.spec.ts`; and the captured **outputs** of `git status`,
`npm test -- epic-<slug>`, `npm run test:e2e -- --list`, `npm run lint` (these outputs are what Tier-2
asserts over).

### Criterion 1 — one agent per story; controls match

- **T3.1 — agent count.** From the transcript, collect **distinct** `Task` tool_use blocks with structured
  `subagent_type: test-generator` (dedupe by tool_use id / story target to absorb B0.2 regeneration, `:308`).
  Classify each by its return line / files written: exactly the `epic-mocks` call (`MOCK DATA READY`,
  writes `mocks/data/`) vs per-story `story` calls (`TESTS WRITTEN`, writes test files). Assert the number of
  **distinct stories covered** by `story` calls **equals the non-parked keys** in `state.json.stories`, and
  `epic-mocks ∈ {0,1}` (= 1 for `contact-form`).
- **T3.2 — no split.** Assert **no story is covered by more than one** `test-generator` `story` call, and
  there are **zero** calls that write only a Vitest file or only a Playwright file for a story (the 23-10
  signature). Detect via the return-line/files-written signal, **not** by substring-matching "vitest"/
  "playwright" in prompt prose (policy text quoted into the prompt would false-red a naive scan).
- **T3.3 — control role+name parity (core AC1), per story.** For each story, run `compareControls(vitestSrc,
  playwrightSrc)` (`helpers/control-refs.ts`, **built**). It joins the two files' control references on
  **normalized accessible name** and asserts the **set of (strategy, role) signatures is equal** for every
  name present in both. Record in `PROOF.md`, per story: the matched signatures, every **UNCOMPARED** name
  (`uncompared.vitestOnly` / `playwrightOnly` / `unresolved`), and the `skipped-no-overlap` status where a
  story shares no name (such a story is *not* counted as a pass).

  **Extractor (`helpers/control-refs.ts`, DONE):** regex over the generated files. Captures
  `getByRole('<role>', { name })`, and the non-role queries `getByLabelText`/`getByPlaceholderText`/
  `getByDisplayValue`/`getByTestId`/`getByText` + Playwright `getByLabel`/`getByPlaceholder` (handles
  `screen.`/`page.`/`within()`/locator chains and `All` variants). Normalizes names (regex→text, strip
  flags, lowercase, collapse whitespace); statically-unresolvable role/name (variable/template literal) →
  recorded `unresolved`; **throws** on a file that contains queries but parses to empty. Escalate to
  `ts-morph` only if skip counts prove material. Unit-tested + calibrated — see Tier 2.

### Criterion 2 — every file in place and failing before build

- **T3.4 — files present (git status), path-exact.** For each **non-parked** story: a new
  `web/e2e/epic-<slug>-story-<N>-*.spec.ts` **and** a new `web/src/__tests__/integration/
  epic-<slug>-story-<N>-*.test.tsx`. Cross-reference the **exact path** from that story's `TESTS WRITTEN:`
  line (`:358`) against the `git status` **new-file** list (not a `<N>-*` glob, which could match a stale /
  wrong-title file). A missing Vitest file is allowed **only if the story's ACs carry zero `vitest` coverage
  tags** (read from the story plan/brief) — the agent's self-report alone does not excuse it; a missing
  return line is red.
- **T3.5 — routable specs have a real test.** For each **routable** story (`route !== null`, read from the
  plan, not guessed), its spec has **≥1 `test(...)` whose body does not call `test.fixme()`**.
- **T3.6 — fails before build (per-story, classified).** For every story that **has** a Vitest file, run
  `(cd web && npm test -- epic-<slug>)` and assert that file reports **≥1 failing, non-`fixme` test** whose
  failure matches a **not-yet-implemented signature** (`Cannot find module` / "Unable to find element" /
  assertion failure — `test-generator.md:312`). **Reject** "no tests found", all-skipped, parse, and type
  errors as satisfying the check. Also run a **Vitest parse/collect gate** (e.g. `vitest list` /
  `tsc --noEmit` on the test files) so a broken-but-present file can't masquerade as the required red.
  Guard against `passWithNoTests` in `vitest.config.ts`.
- **T3.7 — specs parse.** `(cd web && npm run test:e2e -- --list)` lists every new spec, **no parse error**
  (no browser needed — `--list` only parses).
- **T3.8 — lint clean.** `(cd web && npm run lint)` reports **no errors in the new test files**.

**Freeze — DOCS+WEB TREE, not a git bundle.** The capture stops after B0.2, *before* the first story's B5
commit, so the generated test files are **uncommitted** — a `git bundle --all` would not contain them
(confirmed against existing bundle slots). Freeze the slot as a **flat working-tree copy**: copy the
post-B0.2 `generated-docs/` and `web/` trees into `fixtures/golden-runs/build-tests-together-contact-form/`
(loadGoldenRun's docs-only branch → `root = slot dir`, so `root/web/...` resolves to the real files),
alongside `transcript.jsonl`, a `recorded/` dir (`npm-test.txt`, `test-e2e-list.txt`, `lint.txt` for T2.5),
and `meta.json` (benchmark, template ref `v1.4.0`+`4666e23`, model, timestamp, story count, stop-point =
`post-B0.2`, `startedAt-all-null = true`). Only freeze when the capture is conforming (gate holds; one agent
per story; parity holds; files present).

---

## Tier 2 — recorded-run invariants (replay the frozen bundle; no live AI)

New files under `tier-2-recorded-run/build-tests-together/`, fed by the golden-run slot
(`helpers/golden-run.ts` `loadGoldenRun('build-tests-together-contact-form')`):

- **T2.1** = T3.1 + T3.2 over the frozen transcript (deduped count; no split; epic-mocks ∈ {0,1}).
- **T2.2** = T3.3 over the frozen files (**AC-scoped signature-set equality**, normalized; UNCOMPARED &
  SKIPPED recorded).
- **T2.3** = T3.4 over the frozen tree + `git status` output (both files per story, path-exact, or
  tag-justified absence).
- **T2.4** = T3.5 (routable specs have a non-`fixme` `test()`).
- **T2.5** = T3.6–T3.8 asserted over the **recorded command outputs** captured at Tier-3 (not a live re-run —
  the bundle has no `node_modules`). A live re-run is an **env-gated opt-in** (`describe.skipIf`) for anyone
  who wants to reproduce from source with `npm install`.

**Planted-bad calibrations (prove each sub-check behaves).** The extractor-level calibration fixture pairs
are **built** under `tier-1-unit/build-tests-together/fixtures/` and asserted by `control-refs.test.ts`; the
Tier-2 versions wrap them as golden-run slots once the live capture exists:
1. `role-divergent` — the reported bug: `radiogroup` (Vitest) vs `combobox` (Playwright) for name "Status":
   asserts `compareControls` returns `status: 'mismatch'`. ✅ built
2. `strategy-divergent` — `getByRole('textbox',{name:'Email'})` vs `getByLabel('Email')`: asserts a
   **mismatch** on "email" while "send" still agrees — enforces "find each control the same way". ✅ built
3. `name-divergent` — same control named `'Priority'` vs `'Priority level'`: asserts the uncatchable case is
   **surfaced** (`status: 'skipped-no-overlap'`, names in `uncompared`), **not** a false green. ✅ built
4. `good` — matching controls: asserts `status: 'match'`. ✅ built
5. **unjustified-missing-Vitest** fixture (Tier-3/Tier-2 file-presence, not extractor) — a story with a
   `vitest`-tagged AC but no Vitest file: asserts T2.3 reds. *(pending — belongs with the Tier-3 capture)*

---

## Acceptance-criteria → test traceability

| AC clause | Tier 1 (wiring guard) | Tier 2 (frozen invariant) | Tier 3 (live must-show) |
|---|---|---|---|
| 1 — one agent per story | T1.1, T1.2 | T2.1 (deduped count; no split) | T3.1, T3.2 |
| 1 — same role **and name** in both files | T1.3 (parity mechanism present) | T2.2 (**name-joined (strategy,role) signature-set equality**) + calibrations 1–4 | T3.3 (`compareControls`; signatures + UNCOMPARED in PROOF.md) |
| 1 — shared mocks before test agents | T1.4 *(synthetic guard)* | B0 artifacts present in bundle | `web/src/mocks/data/` exists pre-batch |
| 2 — both files present per story | T1.5 | T2.3 (path-exact git tree) | T3.4 |
| 2 — Vitest omitted only if no `vitest` tags | T1.6 | T2.3 + calibration 4 (tag-checked) | T3.4 (tag cross-check) |
| 2 — routable spec has a real `test()` | T1.6 | T2.4 | T3.5 |
| 2 — tests fail before build | — | T2.5 (recorded per-story failure + signature) | T3.6 (per-story, classified) + Vitest parse gate |
| 2 — specs parse / lint clean | T1.5 | T2.5 (recorded `--list` / `lint` output) | T3.7, T3.8 |

---

## Feasibility & prerequisites (council-verified)

**Already there:** `test:tier1`/`test:tier2`; `REPO_ROOT`/`TEMPLATE_REF` (`helpers/target.ts`); the
`EXPECT_TEMPLATE`/`EXPECT_TEMPLATE_REF` **per-file guard idiom** (copy it into the new files);
`describeTemplate` (`helpers/describe-template.ts`); golden-run multi-slot loader (`helpers/golden-run.ts`
`loadGoldenRun(slot)` — new slots drop straight in); `temp-project.ts`/`rollback.ts`; capture scaffold idiom
(`capture-plan-design-update.ps1`); `contact-form` benchmark + mock data source; `23-10` on disk for the
broken-case wording.

**Net-new build items:**
1. ✅ **DONE — `tier-1-unit/build-tests-together/`** (T1.1–T1.6, `rules.ts` + `wiring.test.ts`). Each detector
   is true on 26-10 and false on the verbatim 23-10 two-call wording; the real-template regression block is
   green against 26-10 and all six go red against the real 23-10 baseline.
2. ✅ **DONE — `helpers/control-refs.ts`** (`extractControlRefs` + `compareControls`; multi-query,
   name-normalizing, name-joined signature-set comparison, throw-on-empty). Unit-tested in
   `control-refs.test.ts`.
3. ✅ **DONE — `helpers/test-generator-spawns.ts`** (`parseTestGeneratorSpawns` + `analyzeTestGeneratorSpawns`).
   Parses the stream-json transcript: top-level (`caller.type: direct`) `subagent_type: test-generator`
   spawns, classified by the prompt's `- mode:` line with the return marker (`MOCK DATA READY` / `TESTS
   WRITTEN`) as corroboration/fallback; de-dups story coverage by story number; returns a verdict
   (`one-agent-per-story` / `two-agent-per-story` / `mixed`), `epicMocks`, `storySpawns`, `splitSpawns`,
   `distinctStories`. Unit-tested on synthetic one-agent/two-agent fixtures **and smoke-tested against a real
   captured two-agent transcript**. (Story numbers are unique only within an epic — fine, the capture stops
   after the first epic.)
4. **`tier-3-automated/capture-build-tests-together.ps1`** — phased, portable, spend-gated; stops after B0.2;
   freeze gate = files-present + `startedAt`-all-null + no-dev-source; targets the first ≥2-story epic. *(pending)*
5. ◑ **PARTIAL — calibration** built: the control-refs fixture pairs at `tier-1-unit/build-tests-together/
   fixtures/` **and** the Tier-2 planted-bad golden-run slot `fixtures/golden-runs/build-tests-together-
   divergent/` (a docs-tree one-agent run whose Story 2 files diverge — runs now, reds T2.2). The GOOD slot
   `build-tests-together-contact-form` + the unjustified-missing-Vitest case land with the live capture.
6. ◑ **PARTIAL — `tier-2-recorded-run/build-tests-together/parity.test.ts`** built: T2.1–T2.4 wired over the
   good slot (skip-until-present) + the divergent calibration runs green now (proves T2.2 reds on Story 2,
   not Story 1). **T2.5** (recorded `npm test`/`--list`/`lint` outputs) still pending — needs the capture.

**Prerequisites (verified):** Node ≥22 on the host (`web/package.json` engines + `preinstall` enforce);
Chromium **not** needed for `test:e2e --list`; MSW (`mock-setup-agent`, B0.1) runs inside the stop window for
`contact-form`'s mock source; bare git remote (before any push, so belt-and-braces).

**Decision to confirm:** whether to also carry a generated-code **lint rule** that fails any committed story
pair whose shared-AC controls disagree (a standing guard on every real build), or keep the parity check
capture-scoped. Recommend capture-scoped now; promote to a lint rule if the team wants it enforced live.

---

## Suggested order of work

1. **Tier 1** (T1.1–T1.6) + RB-BT — cheapest, runs now, proves the wiring guard catches the real regression
   (T1.1–T1.3) and the adjacent invariants (T1.4–T1.6).
2. Build + unit-test **`control-refs.ts`** (the signature extractor) — everything downstream depends on it.
3. Build the **calibration slots** (role-, name-, query-strategy-divergence, unjustified-missing-Vitest) and
   prove the extractor + checks go red on each **before** any live spend.
4. **PLAN-only dry run** to confirm a ≥2-story first epic; then gate, then run the **live capture** and freeze.
5. Wire **Tier-2** against the good + calibration slots; save `PROOF.md` (per-story signature tables,
   UNCOMPARED/SKIPPED lists, recorded command outputs) under `TestResults/`.

---

## Appendix — evidence (absolute paths in `stadium-builder 26-10`)

- `…\.claude\commands\continue.md` — B0 `:252`, B0.2 `:286`/`:290`, shared-import `:300`, regeneration `:308`,
  phase table `:28`, `state.json.stories[<N>]` init `:168`.
- `…\.claude\agents\test-generator.md` — one-call `:11`, `mode: story` `:22`, coverage enum `:20`, parity step
  `:296`, output paths `:304`/`:305`, "no vitest → no file" `:298`, routable/`fixme` `:90-91`, acceptable
  failures `:312`, `TESTS WRITTEN:` `:358`, success `:384`, `getByLabel` example `:254-255`.
- `…\.claude\policies\testing-policy.md` — getByRole priority `:101-112`, non-routable stubs `:420-436`.
- `…\.claude\shared\naming-conventions.md` `:26` + `…\.claude\hooks\enforce-generated-doc-names.js`.
- `…\.claude\scripts\lib\epic-state.js` `:26` (schema, `stories` object), `:42-43` (`startedAt`).
- `…\web\package.json` — `test`=`vitest run` `:18`, `test:e2e`=`playwright test` `:22`, `lint`=`eslint` `:11`;
  `web\vitest.config.ts` include `src/**/__tests__/**`.
- `…\CHANGELOG.md` — `[Unreleased] → Fixed`: "A story's two sets of automated tests are now written together,
  so they expect the same controls on the screen."
- `…\template-version.json` — `templateRef: v1.4.0`, `source: release`; `4666e23` is one of 4 commits in
  `v1.4.0..HEAD`.
- Harness: `AI-tests\helpers\target.ts` (`REPO_ROOT`/`TEMPLATE_REF`), the `EXPECT_TEMPLATE_REF` guard at
  `tier-1-unit\plan-scope\plan-scope.test.ts:136-140` (also `plain-stops`, `intake-overview`),
  `helpers\golden-run.ts` `loadGoldenRun`, `helpers\describe-template.ts`.
- Broken-case source: `C:\TestsArchives\stadium8-tests\stadium-builder23-10\src\Bootstrapper.Framework\
  .claude\commands\continue.md:290` ("launch **two** `test-generator` calls"), `…\agents\test-generator.md:22`
  ("fire in parallel"); .NET Bootstrapper repo, `app-frontend/` — wording source only, not a `REPO_ROOT`.
