# Test plan — INTAKE writes a lean `## Project Overview` into CLAUDE.md

**Testing against:** the template clone at `C:\TestsArchives\stadium8-tests\28-09-2026`
(commit `34a574a`). This clone carries the **dev** marker (`<!-- stadium8-claude: template-dev -->`),
so the shipped end-user CLAUDE.md lives here as **`CLAUDE.user.md`** — the publish pipeline swaps it
in as `CLAUDE.md` in the release repo. **This distinction is load-bearing for the whole plan** (see
"Which file is under test").
**Run static tier (PowerShell):**
`$env:REPO_ROOT="C:\TestsArchives\stadium8-tests\28-09-2026"; $env:EXPECT_TEMPLATE="1"; npm run test:tier1`
(run from `c:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests`).

---

## The feature under test

At INTAKE, `/start` writes the `## Project Overview` section of `CLAUDE.md` so that a session which
never opens `generated-docs/project.md` still has the facts it needs, everything else is a pointer,
and the whole section fits a fixed budget. The section is written at exactly **two** points and
nowhere else: at INTAKE (`start.md` Step 9, item 4), and corrected — never rewritten — at every epic
merge (`continue.md` B7.2.6). Both are governed by the single spec
[.claude/shared/project-overview.md](.claude/shared/project-overview.md).

**Acceptance criterion (as given).** After intake, CLAUDE.md's project section:
1. **States the headline facts** — a fact is stated *only if getting it wrong would produce wrong
   code in a session that never opens `project.md`*: what the app does, the role names, the auth
   model, the data-source mode **by name only**.
2. **Points at everything else** — permissions, palette, compliance requirements, backend
   connectivity, the epic plan and briefs are **pointers**, not content.
3. **Fits a fixed budget** — the whole section stays **within 12 lines and 150 words**.

This maps onto the shipped spec: a two-sentence lead-in (what the app is + what each role does),
three bullets (Roles / Auth / Data source, each ending in the constraint that makes the fact
actionable), one pointer line of **exactly three** pointers (`project.md`, `epics/`,
`architecture.md`), a **Never-present** list (permissions, endpoints, palette, compliance, theme,
backend connectivity, epics, stories, progress, timestamps, slugs, NFRs), **silent** (no prompt, no
message), and **correct-don't-rewrite** semantics.

---

## The feature is already implemented — so this is a REGRESSION-GUARD + behavioural plan

`project-overview.md` already specifies the budget, the exact-three pointers, the never-present list,
the silence, and the two write points; `start.md` Step 9 (items 4–5) already invokes it and commits
`CLAUDE.md` on main; `continue.md` B7.2.6 already re-checks it at merge. So **every static check
passes today** — which means a static check proves nothing unless it can also *go red on the exact
regression it guards*. Therefore:

- **Tier 1 is a wording/wiring regression-guard only** (necessary, not sufficient). Every assertion
  is **mutation-coupled**: the plan states the edit that must turn it red, and a fixture applies that
  edit to a temp copy and asserts the detector fires. No AC is "verified" by Tier 1.
- **The AC as written is a live walkthrough** — the real verification is Tier 3.

---

## What the council changed about this plan (this is the reshaped v2)

A four-lens council (falsifiability, claim-accuracy, adversarial/vacuous-green, feasibility) read the
first draft against the actual files and found it leaned on **blocklists, substring matches, and
budget-as-proxy** — all evadable, several also false-*red* on compliant output — plus several factual
slips and under-scoped harness work. The single biggest change:

> **Invert the verification model.** Token-absent scans, `wc` budgets, and commit-message greps are
> demoted to **cheap necessary gates that can never, on their own, turn the AC green.** The
> load-bearing checks become: a **structural whitelist** (the section contains *only* the lead-in +
> three named bullets + three-pointer line — anything else is a leak by construction), **set-equality**
> against `project.md` (not subset/substring), and a **semantic judge** ruling per never-present
> *category* on meaning, not literal strings.

The specific corrections the council forced are folded into the tiers and the "honesty corrections"
below; the factual fixes are:

- **Fixture role strings are `Importer` / `Approver`, not "File Importer".** "File Importer" is only a
  seeded-user *display label* in `answers.json`; the canonical enum/personas are `Importer` /
  `Approver` (`requirements-2c.md` §7, `PrototypeBriefV2.md` §4, `answers.json`). **Tests must bind
  role assertions to the `project.md` §Roles headings the run actually produces — never to a
  hardcoded guess.** (The spec's *example* at `project-overview.md:28` also says "File Importer"; it's
  an illustration, not this project's truth.)
- **The fixture is not "live / no mocks".** `answers.json` says "build against mock data unless the
  backend is up." It ships **two backend service *specs*** (`auth-api.yaml`, `transactions-api.yaml`);
  the data-source *mode* is whatever the run records — don't assert "live".
- **`grep "Template repository"` is not zero-hit** while this plan lives in the tree (the plan quotes
  the phrase). The real check excludes the plan file and asserts absence **from template files only**.
- **`start.md` has no "Step 9.4/9.5" labels** — it's `## Step 9` with numbered items 4 (write) and 5
  (commit). Anchor guards on content, not on those labels.
- **The spec says "mocks or live", not "by name only".** "By name only" is AC/plan phrasing; guards
  must pin the spec's actual tokens.
- **`snapshot.ts` is a string normaliser, not a git-capture helper** — only `golden-run.ts` carries
  committed files + topology.

---

## Honesty corrections (kept from v1, sharpened)

1. **The "Template repository for building frontend applications" wording is a phantom anchor.** That
   string exists in no template file. The real pre-intake placeholder in the shipped-user file is
   *"No project yet. Run `/start` to describe what you're building — this section will then describe
   your app."* (`CLAUDE.user.md:12–14`). Asserting the AC's literal phrase is absent passes vacuously.
   **Bind the "placeholder gone" check to the real placeholder — via a single shared `PLACEHOLDER`
   constant imported by both the Tier-1 tripwire and the Tier-3 check, so they can never drift.**

2. **"Silent / never asked" is structural, not text-classification.** `/start` legitimately asks
   intake questions, so silence ≠ "zero questions", and tagging a question by whether its text says
   "overview" is unreliable both ways (a broken flow that asks *"approve this summary?"* passes; a
   benign question mentioning "overview" false-reds). **Define silence structurally: assert
   **zero** `AskUserQuestion` calls fire between intake-approval and the `CLAUDE.md` commit.**

3. **The budget check needs one fixed convention or it's non-reproducible — and it is necessary, not
   sufficient.**
   - **Lines (decision, not two options):** count from the `## Project Overview` heading line through
     the **last non-blank line** before the next `## ` heading; **exclude trailing blank lines** (so
     a cosmetic blank before the next heading can't flip 12→13). Assert **≤ 12**.
   - **Words:** `wc` is not the executing tool (the suite runs under Node/PowerShell). Define word
     count as an explicit algorithm — **whitespace-delimited token count over the extracted span** —
     and assert **≤ 150** (the spec says "within … 150", i.e. ≤150; v1's `<150` was off-by-one and
     stricter than the spec).
   - Budget alone rewards abuse (a 149-word run-on wall, or **dropping the `architecture.md` pointer
     to free up words**). So budget is a gate behind the **structural whitelist** below, never a
     stand-in for well-formedness.

---

## Which file is under test (do not skip)

- **Static tier** reads the **shipped end-user file**: `CLAUDE.user.md` in *this* dev clone (marker
  `user`), or `CLAUDE.md` in a release clone. The dev `CLAUDE.md` (marker `template-dev`) has **no
  maintained `## Project Overview`** — it imports `@CLAUDE.user.md` — so asserting against it tests
  the wrong artifact.
- **Marker resolver is net-new** (see Feasibility): no helper today reads the top-level file or the
  `stadium8-claude:` marker. A ~15-line helper (read `REPO_ROOT/CLAUDE.md`, sniff the marker, fall
  back to `CLAUDE.user.md` when `template-dev`) is a **prerequisite for every static assertion**.
- **Live tier (Tier 3)** must run against a **release** target (`-Target release`; there is **no
  `dry_run` target**) so the file INTAKE writes is named `CLAUDE.md`. Caveat: the tier-3 clone is
  `--depth 1` shallow, and this plan **assumes the release repo ships `CLAUDE.md` with the same
  placeholder** — confirm that against the release repo before relying on it.
- **Fail-closed is per-file, not central.** `EXPECT_TEMPLATE` is honoured only by a per-file top-level
  `it()` idiom (as in `plan-scope.test.ts` / `plain-stops.test.ts`), and `TEMPLATE_PRESENT` only
  probes `.claude/scripts` — it says nothing about the shipped-user file. So `intake-overview/` must
  (a) copy that guard idiom and (b) **extend it to assert the shipped-user file resolved**, else a
  cleaned-up overview target skips green.

---

## Setup (shared by Tier 2 capture and Tier 3)

A fresh clone of the release repo with a spec under `documentation/` that names **≥2 roles with
different permissions, an auth model, and a backend**. Use the existing **`transactions`** benchmark
fixture (`AI-tests/benchmark-files/transactions/`): roles `Importer` / `Approver` with a genuine RBAC
split (Importer can't approve/reject; Approver can't upload — `requirements-2c.md` §6.5), server-side
BFF cookie auth (`auth-api.yaml`), and two backend specs (`transactions-api.yaml` + auth). The tier-3
scaffold already copies `frontend/docs/*` + `backend/` into `documentation/` and drops `answers.json`
as `TIER3-ANSWERS.json`; `-Benchmark transactions` is the default. Run `/start`, approve intake.

---

## Tier 1 — static regression-guards over the spec + wiring (each mutation-coupled)

New suite `tier-1-unit/intake-overview/` (`rules.ts` detectors + `intake-overview.test.ts`), house
style copied from `plan-scope/`. **Every span-scoped detector must define its span as rigorously as
the budget span** — the recurring v1 bug was whole-file greps that stay green because the token also
occurs in an allowed context.

### Over `project-overview.md` (the governing spec)
- **Budget stated (pin the literals)** — assert the exact string `within 12 lines and 150 words`
  (`:7`), not a `within \d+ … \d+` pattern. Mutation: `12`→`20` or `150`→`200` → red.
- **Exactly-three pointers (count, don't just presence-check)** — parse the pointer line (`:17`),
  assert **exactly three** backticked `generated-docs/...` entries resolving to `project.md`,
  `epics/`, `architecture.md`, **and** the literal "exactly three". Mutation: append a 4th pointer
  (leaving the three intact) → red; drop `epics/` → red. *(v1's presence check couldn't catch a 4th.)*
- **Never-present list intact (span-scoped)** — define the span as the line beginning
  `**Never present:**` (`:19`) only, and assert each token *within that span*: `permissions`,
  `palette`, `compliance`, `backend connectivity`, `epics`, `stories`, `progress` (+ `endpoints`,
  `theme`, `timestamps`, `slugs`, `NFRs`). *(Whole-file greps stay green when `permissions`/`epics`
  are removed — they recur at `:11`/`:17`/`:32`.)* Mutation: move `permissions` out of the list into
  an allowed bullet → red. *Guard for AC-clause 2.*
- **Allowed-facts intact (pin real tokens)** — the three bullet rows Roles/Auth/Data source (`:9–13`)
  are present; Roles ends "closed list; exact string form", Auth ends "what it forbids", Data source
  says "mocks or live". *(Pin `mocks or live`, not "by name only" — that phrase isn't in the spec.)*
  Mutation: delete the Data-source row → red. *Guard for AC-clause 1.*
- **Silence stated** — "Silent — no prompt, no message" (`:43`). Mutation: delete → red. *(Necessary
  only; real silence is Tier 3.)*
- **Two-write-points stated** — "the only two points it is ever written" (`:3`) + "Never from an
  `epic/*` branch" (`:39`). Mutation: delete the epic-branch prohibition → red.
- **Correct-don't-rewrite stated** — "Correct, don't rewrite" (`:40`) + "leave `CLAUDE.md`
  byte-for-byte untouched" (`:41`). Mutation: delete the byte-for-byte clause → red.

### Over the wiring (`start.md`, `continue.md`) — anchor on content, not labels
- **INTAKE write wired** — the line `Write \`CLAUDE.md\`'s \`## Project Overview\`` referencing
  `project-overview.md` (`start.md:385`). Mutation: delete it → red.
- **INTAKE commit stages CLAUDE.md (line-scoped)** — assert `CLAUDE.md` is a token *on the staging
  line* `git add generated-docs/ documentation/ CLAUDE.md` (`start.md:390`), not anywhere in the file.
  Mutation: drop `CLAUDE.md` from that line → red. Tolerate a whole-tree `git add -A` refactor (still
  stages CLAUDE.md) so it doesn't false-red. *(v1's whole-file grep couldn't go red.)*
- **Merge-time re-check wired** — `continue.md` B7.2.6 aligns `## Project Overview` per the spec and
  `git checkout -- CLAUDE.md` when nothing changed (`:735–742`). Mutation: delete the alignment step → red.

### Must-survive tripwire
- **Placeholder anchor exists** — the shipped-user file's §Project Overview still contains the shared
  `PLACEHOLDER` constant (`No project yet` / `Run \`/start\` to describe`). Its value is that it forces
  the Tier-3 "placeholder gone" anchor to update in lockstep when the template is reworded.

### Dropped from Tier 1 (unfalsifiable statically)
- **"Commit lands on main, not an epic branch"** — `start.md` has no branch guard; "on main" is
  narrative prose (`:366`) nothing a single edit turns red. **Verified in Tier 3** via git topology,
  not presented as a Tier-1 guard.

---

## Tier 2 — recorded-run invariants (frozen from a captured intake golden run)

**Feasibility caveat up front (was under-scoped in v1):** the golden-run loader reads a **single fixed
slot** `fixtures/golden-run/`, currently occupied by the `minimal-concurrent` bundle that the whole
existing Tier-2 suite gates on. An intake golden run needs **net-new multi-golden support** (a named
slot / second loader) — it is *not* "capture once into the existing slot." It must be captured as a
`repo.bundle` with `CLAUDE.md` committed (the docs-only fallback exposes `generated-docs/` but not the
top-level file); reads use `golden.root/CLAUDE.md`. `snapshot.ts` is irrelevant here — cite
`golden-run.ts` only.

With that captured, assert deterministically:

- **Structural whitelist (the load-bearing shape check)** — the extracted section consists of
  *exactly*: a two-sentence lead-in, three bullets (Roles / Auth / Data source), one pointer line of
  three pointers — **and nothing else**. Anything beyond those shapes is a leak by construction. This
  is what actually enforces AC-clause 2, not the token scan.
- **Facts by set-equality, against the backend source** — the overview's role set **equals**
  `project.md` §Roles headings (set equality, not subset), the closed-list claim ("no other role
  exists") is **true**, auth matches §Authentication `Method` *including its forbid clause*, and the
  data-source line matches §Data Source mode. Compare role strings to the **backend identifier**
  (auth-spec enum) where it differs from a prettified heading. *(AC "all agreeing with project.md.")*
- **Never-present token scan (necessary gate only)** — no hex/palette token, permission verb, URL,
  smoke-test/health string, or epic/story/slug/progress string inside the section. Marked
  explicitly *necessary-not-sufficient*: paraphrase leaks are caught by the Tier-3 judge, not here.
- **Data-source carve-out** — the scan must **allow** the by-name data-source bullet (`existing API`,
  `mocks`, `two backend services`) while rejecting *connectivity* (URLs, "reachable now", smoke-test).
  Otherwise the allowed fact false-reds. *(Council finding 8.)*
- **Budget met** — extracted section ≤ 12 lines and ≤ 150 words under the fixed conventions.
- **Critical Rules + Policies unchanged by intake (self-diff, NOT vs template)** — compare the
  **pre-intake** file to the **post-intake** file, span-anchored on `## Critical Rules` / `## Policies`
  headings; assert those spans are byte-for-byte identical across the write. **Do not** compare to a
  frozen pristine template — that false-reds on user-added rules (spec `:42` protects the user's own
  words) and on `/upgrade` advancing the shipped rules. *(AC "unchanged", read correctly.)*
- **Intake commit introduced the facts** — `git blame`/diff the actual fact lines and assert the
  commit that introduced *this project's* role/auth/data-source bytes is the intake commit
  `docs(project): project setup + epic plan`, and its `CLAUDE.md` diff touches only the
  `## Project Overview` span. **Plus a non-placeholder assertion** (the committed span is real facts,
  not `No project yet`) so a placeholder-then-later-fill can't pass. *(Council finding 4.)*

---

## Tier 3 — behavioural (the AC walkthrough, the real verification)

Needs a **net-new intake scenario** (or the existing `build` scenario + post-run assertions — today
`build` runs `/start` and approves intake but asserts nothing about the overview) and a **net-new
`AskUserQuestion` extractor** over the retained (gzipped) raw `*-claude.jsonl` stream (`Read-ClaudeEvent`
records only file/command, never the tool name). Then, on the release target with the `transactions`
fixture:

- **Facts stated, correct, and would-break-code-if-wrong** — a judge confirms the app-purpose, both
  role names, the auth model, and the data-source mode are present, individually correct against
  `project.md` (incl. the lead-in's **role→action mapping** and the auth **forbid clause** — v1's
  bare Method match missed both), and are the kind of fact a `project.md`-blind session needs.
- **Placeholder replaced** — the shared `PLACEHOLDER` constant is gone (not the AC's phantom phrase).
- **Detail is pointered, not present (semantic judge per category)** — the judge rules, on *meaning*,
  that none of {permission detail, palette, compliance, backend connectivity, epics, stories,
  progress} is conveyed — catching paraphrase leaks the token scan can't ("GDPR" without "compliance",
  "a calm blue accent" without a hex, "Approvers can void…" without a lexicon verb). Each is replaced
  by a pointer.
- **Budget** — extract the section; assert ≤ 12 lines and ≤ 150 words under the fixed conventions.
- **Landed on main in the intake commit, silently** — `git log --oneline -- CLAUDE.md`: the commit
  that introduced the facts is the intake commit on `main` (not an `epic/*` branch); the extractor
  shows **zero `AskUserQuestion` between intake-approval and the CLAUDE.md commit**.
- **Critical Rules + Policies unchanged** — pre-vs-post self-diff of those spans is byte-identical.

**Budget/verbatim stress + tension (new, council finding 6):** the spec mandates *verbatim* role
strings and naming *every* role, which can collide with ≤150 words. Add a **near-ceiling fixture**
(3+ roles and/or long namespaced role identifiers) so the budget gate is actually exercised near its
limit, and **document the precedence** (which wins — budget or verbatim — when they conflict) and
assert against that decision. The `transactions` fixture alone (~80 words) never stresses the ceiling.

**Extension beyond the AC (second write point):** build one epic to merge; assert B7.2.6 either leaves
`CLAUDE.md` byte-for-byte untouched when nothing is stale (`git diff --quiet` holds) or *corrects* a
deliberately staled fact **without rewriting** untouched wording, still within budget and never-present.

---

## Acceptance-criteria → test traceability

| AC clause | Tier 1 (guard, mutation-coupled) | Tier 2 (frozen invariant) | Tier 3 (live must-show) |
|---|---|---|---|
| 1 — headline facts (app / roles / auth / data-source mode) | allowed-facts bullets present (real tokens) | set-equality vs `project.md`; closed-list true; forbid clause | judge: present, correct, role→action + forbid correct |
| 2 — everything else pointered | never-present list (span-scoped) + exactly-3 pointers (counted) | **structural whitelist** + token gate + data-source carve-out | **semantic judge per category** (paraphrase-proof) |
| 3 — budget ≤12 lines / ≤150 words | budget literals pinned | within budget (fixed conventions) | within budget; **near-ceiling fixture** stresses it |
| write on main, in intake commit, silently | Step 9 item 4/5 wiring; silence stated | intake commit *introduced the facts*; non-placeholder | `git log` topology on main; **zero AUQ** approval→commit |
| Critical Rules + Policies unchanged | correct-don't-rewrite stated | **pre-vs-post self-diff** (not vs template) | self-diff spans byte-identical |

---

## Feasibility & prerequisites (reshaped — net-new work now itemised)

**Already there:** `test:tier1`/`test:tier2` (`package.json:12–13`); `REPO_ROOT` (`target.ts`);
tier-1 house style (`plan-scope/`); `-Target release` + release entry in `targets.json`; the
`transactions` fixture wiring (default benchmark, scaffold copies docs + answers).

**Net-new but feasible (state these as build items, not assumptions):**
1. **Marker resolver** (~15 lines) — read top-level file, sniff `stadium8-claude:` marker, fall back
   to `CLAUDE.user.md`. Prerequisite for all static assertions.
2. **`EXPECT_TEMPLATE` + shipped-user fail-closed** — copy the per-file guard idiom and extend it to
   assert the shipped-user file resolved (`TEMPLATE_PRESENT` alone doesn't).
3. **Section extractor** — heading→last-non-blank-before-next-`##`; word/line algorithm; fail-closed
   on zero lines. Precedent: `design-digest.ts` `digestSections()` (copy, don't reuse).
4. **Second golden-run slot** — loader support for a named intake golden run alongside
   `minimal-concurrent`; capture as `repo.bundle` with `CLAUDE.md` committed. **Largest item.**
5. **Intake scenario + overview assertions** in `live-driver.ps1` (or `build` + post-run asserts).
6. **`AskUserQuestion` extractor** over raw `*-claude.jsonl(.gz)` (record tool name + inputs).
7. **Near-ceiling budget fixture** (3+ roles / long verbatim role strings).

**Doc/decision items:** confirm the release repo ships `CLAUDE.md` with the placeholder; decide
budget-vs-verbatim precedence; the tier-3 clone is shallow (`--depth 1`) — fine for the run-created
intake commit, limited for deep history.

---

## Suggested order of work

1. Marker resolver + `EXPECT_TEMPLATE`/shipped-user guard + Tier-1 spec/wiring guards **with mutation
   fixtures** (fast; proves each guard can fail today).
2. Section extractor + fixed budget conventions (unblocks Tier 2/3 budget + structural whitelist).
3. Build the intake scenario + `AskUserQuestion` extractor; run the Tier-3 walkthrough on `-Target
   release`; add the near-ceiling fixture.
4. Add the second golden-run slot; capture the intake run; freeze Tier-2 invariants (structural
   whitelist, set-equality, self-diff, commit-introduced-facts); add the B7.2.6 extension.

---

## Appendix — evidence

- Spec: [.claude/shared/project-overview.md](.claude/shared/project-overview.md) — budget `:7`,
  allowed-facts table `:9–13`, exactly-three pointers `:17`, Never-present list `:19`, example shape
  `:23–33` (~80 words, not 95), "only two points" `:3`, "Never from an `epic/*` branch" `:39`,
  "Silent" `:43`, "Correct, don't rewrite" `:40` / "byte-for-byte untouched" `:41`.
- Wiring: [start.md](.claude/commands/start.md) Step 9 item 4 write (`:385`), item 5
  `git add … CLAUDE.md` (`:390`) + `docs(project): project setup + epic plan` (`:395`), on-main
  narrative (`:366`); [continue.md](.claude/commands/continue.md) B7.2.6 (`:735–742`).
- Shipped-user file + placeholder: [CLAUDE.user.md](CLAUDE.user.md) marker `:1`, placeholder `:12–14`;
  dev-maintainer file marker + `@CLAUDE.user.md` import ([CLAUDE.md](CLAUDE.md) `:1`, `:80`).
- Phantom anchor: `grep -rn "Template repository"` hits **only this plan file** — absent from all
  template files; the real test must exclude the plan. Near-variant `CLAUDE.md:15`
  "production-ready front-end application" does not match "frontend applications".
- Fixture: `AI-tests/benchmark-files/transactions/` — roles `Importer`/`Approver` with distinct RBAC
  (`requirements-2c.md` §6.5/§7, `PrototypeBriefV2.md` §4, `answers.json`), server-side cookie auth
  (`auth-api.yaml`), `transactions-api.yaml`; `answers.json` says build against mocks unless backend
  up ("File Importer" appears there only as a seeded-user display label).
- Harness: `test:tier1`/`test:tier2` (`AI-tests/package.json:12–13`), `helpers/target.ts`
  (`REPO_ROOT`, `TEMPLATE_PRESENT` probes `.claude/scripts`), `helpers/describe-template.ts`
  (skips factory when absent), per-file `EXPECT_TEMPLATE` idiom (`plan-scope.test.ts`,
  `plain-stops.test.ts`), `helpers/golden-run.ts` (single `fixtures/golden-run/` slot, bundle vs
  docs-only), `helpers/design-digest.ts` `digestSections()` (extractor precedent),
  `tier-3-automated/Run-QATests.ps1` `Resolve-Tier3Template` (`:167`, `-Target release`, `--depth 1`),
  `tier-3-automated/live-driver.ps1` (`build`/`plan`/`concurrent` scenarios; `Read-ClaudeEvent`
  records file/command only), `targets.json` (release → `Digiata/Stadium-Builder`).
