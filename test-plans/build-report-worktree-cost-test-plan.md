# Test plan — build reports count parallel-worktree /plan spend (case-insensitively) and name what fed the figures

**Testing against:** the template clone at `C:\TestsArchives\stadium8-tests\28-09-2026` (commit `34a574a`,
dev marker).
**Run the unit spine (the AC's own command):**
`node .claude/scripts/lib/report-core.tests.js` (standalone harness — verified 27 passed). Also
`node .claude/scripts/generate-build-effort.tests.js` (30 passed) and
`node .claude/scripts/generate-build-report-html.tests.js` (51 passed).

---

## The feature under test

Build reports sweep `~/.claude/projects/<slug>/` for a project's session transcripts and total their
token spend. A session **started in a git worktree** records under a folder that extends the slug
(`<slug>-<suffix>`) and, on Windows, can differ from the project's own folder by the **case of the
drive letter** (`C:\…` vs `c:\…` — one folder on Windows). The bug: a case-sensitive sweep **silently
drops** that folder, understating `totalCostUsd` and distorting `costUplift` — the multiplier the
fully-loaded figures and the sizing calculator are built on — and nothing reported what fed the
figures, so a partial sweep looked identical to a complete one.

**Acceptance criteria.**
1. **A parallel-planning session is counted whatever case its folder has.** The sweep matches
   **case-insensitively**, so a worktree session recorded under a differently-cased name is picked up —
   while a checkout that merely shares the project's name (not a git worktree) stays out.
2. **The maintainer report says which sessions fed its figures** (count + names); the console surfaces
   the count too; the **stakeholder** report carries neither.

---

## Already implemented AND already unit-tested — a REGRESSION-GUARD plan (verified)

Both ACs are in this dev clone, and the AC's own "run `report-core.tests.js`, observe every test
passes" **is** the Tier-1 spine — it already exists, and the council **reverted the fix and confirmed
the tests go red** on the exact regression:

- **AC1:** `report-core.mjs` — `norm = toLowerCase` (:112), git-`worktree list` matcher
  (`worktreeMatcher` :135–147), case-insensitive primary/sibling selection (:190, :197–199),
  `transcriptsOverride` (:178, fallback :204–210), returns `folders`/`extras` (:182). Tested by
  `report-core.tests.js`: differently-cased worktree in / `-QA` out (:210, folder created via
  `slugOf(worktree).toUpperCase()` :220, `extras` assert :232), git-can't-answer → strangers out (:164),
  real worktree whatever-suffix (:184), cased primary → on-disk name (:237), records merged across
  worktree dirs (:406). **Verified mutation-coupled:** reverting `norm`→identity fails :210 and :237 (and
  only those); making `worktreeMatcher` accept-all fails :164, :184 (and :210's `-QA` assertion).
- **AC2:** `generate-build-effort.mjs` carries `transcriptFolders` into `build-effort-data.json` and its
  stdout JSON (:139, :263, :295–300) and **also names the folder on the console**
  (`generate-build-effort.tests.js:176` already asserts this); `collect-build-report-data.js` renders
  "read N session folder(s): …" into Data quality (:838); `generate-build-report-html.js` renders that
  section (:811–818). **Verified mutation-coupled:** rendering `transcriptFolders` on the client page
  fails the maintainer-names/client-omits test (`generate-build-report-html.tests.js:229–239`, which
  asserts exclusion with real `!client.includes(...)` guards at :238–239).

So the plan's job is **coverage-audit + close the residual gaps + frame Tier-3 honestly**.

---

## What the council changed / honesty corrections

### The core shape: assert conservation invariants COMPUTED THROUGH THE SAME FUNCTIONS — never re-derive an "expected" figure
The first draft strengthened three soft checks into "exact delta / must increase / drops to 1" without
accounting for the three mechanisms that legitimately break naive exactness. Each is fixed to a
conservation invariant read back through the very code under test:

1. **`totalCostUsd` delta — via `gatherUsageRecords`, not a hand-summed folder.** `gatherUsageRecords`
   dedups by message id **across all dirs** and drops timestamp-less records (report-core.mjs:250, :262).
   So a hand-summed "sum of the worktree folder's records" false-reds when the worktree shares a message
   id with the primary (deduped away) or has ts-less records (filtered out), and a double-counting
   discovery bug could still land near the naive sum (false-green). **Assert instead:**
   `gatherUsageRecords(allDirs).totalCost − gatherUsageRecords(primaryDirs).totalCost` equals the
   worktree's contribution *by construction* (same function, same dedup + ts-filter on both sides).
   Read **full-precision `data.totals`**, never the `.toFixed(2)` console `totalCostUsd`/`costUplift`
   (:301, :305).

2. **`costUplift` — assert the mechanism (`overheadCost` up, `inStoryCost` unchanged), NOT a
   direction.** Attribution buckets purely by timestamp: `hits = stories.filter(st => r.ts >= st.start
   && r.ts < st.end)` (generate-build-effort.mjs:144). "Parks an epic, builds no story" only means the
   /plan session makes no window of its own — under the **parallel** premise its timestamps can fall
   **inside another epic's** open story window, landing its spend **in-story**: then `(T+X)/(I+X) < T/I`
   and `costUplift` **falls**. So "costUplift must increase" is a false-red on correct behaviour.
   **Assert instead:** the fixture places the worktree records **provably outside every `state.json`
   window** (verify, don't assume), then `overheadCost_after − overheadCost_before == the worktree
   contribution` and `inStoryCost` unchanged — from which the uplift rise follows by construction. In
   the **live** Tier-3, drop the direction claim unless the operator confirms no story window was open
   during the /plan session.

3. **Count/names — set membership, not a literal 2→1.** `git worktree list` names **every** worktree of
   the repo (stale branch worktrees included), so on a real machine the count can exceed 2. **Assert
   instead:** the primary folder is present, the specific expected worktree folder is present-then-absent
   across the delete, and record whatever other confirmed worktrees discovery reports as the baseline —
   never assert the total is exactly 2 or 1.

### The snapshot gap-tests CANNOT reach the worktree-accept path — split the coverage honestly
`worktreeMatcher` runs `git worktree list` against the **real** `projectRoot`, and the slug is derived
from `projectRoot` — so a fabricated folder in a `--transcripts` snapshot is accepted **only if the real
repo actually has that worktree** (report-core.mjs:135, 138, 179). Two consequences the first draft
missed:
- A snapshot test that fabricates a "worktree" folder but points `--project-root` at a non-repo temp dir
  → git can't answer → the sibling is **rejected**, primary matches so the fallback doesn't fire → the
  test **false-reds** on a correct implementation.
- If arranged so the primary matches nothing, the fallback (report-core.mjs:206–210) scoops **every**
  subdir (including a `-QA` stranger) with `extras=[]` → a **vacuous green** that survives deleting
  `worktreeMatcher` entirely and never exercises AC1.
- The effort generator reads only `folders`, **never `extras`** (generate-build-effort.mjs:139), so
  `transcriptFolders` is its only observable.

**So:** the case-insensitive **git-confirmed accept** is proven at the discovery level by
`report-core.tests.js:210` (real `git init` + `git worktree add`). The effort-level gap tests below run
over the **fallback** path and prove **cost-wiring** ("two folders' spend reaches the totals; costUplift
tracks the out-of-window addition; `transcriptFolders` tracks the store") — **not** case-selection.
Label them as such. To traverse the accept branch end-to-end at the effort level, a test must create a
**real git worktree** as :210 does (net-new git setup in `generate-build-effort.tests.js`, small — not a
blocker; budget it only if end-to-end accept coverage is wanted).

### Tier-3 exercises DISCOVERY over a manually-created worktree session — not /plan's own recording
`report-core.mjs`'s own header (:132–134, :152–155) states /plan's throwaway worktree is driven by
`git -C` **from a window opened on the project**, so its sessions record into the **project's own**
folder — never a worktree folder. So a routine /plan run produces **nothing** for discovery to pick up.
The AC manufactures the condition by `git worktree add` **and running a session inside the worktree**
(cwd = worktree, e.g. via VS Code) — which is what slugifies to a worktree-named folder. State plainly:
Tier-3 proves discovery/reporting handle **a session started in a worktree**, not /plan's `git -C`
recording. (If "count parallel /plan spend" is meant literally, first establish whether /plan ever
records outside the project folder at all — a question for the feature owner.)

### Deleting real transcripts is hazardous — the feature's own case-ambiguity is the trap
The delete step asks the operator to remove "the plan worktree's folder" from the **real**
`~/.claude/projects/`, where it differs from the primary only by case — mis-picking deletes the
**primary's irreplaceable history**. **Prefer the override** (`transcriptsOverride`) for the count-drop
check and keep the live delete out entirely; if a live delete is unavoidable, delete **by the exact
on-disk name discovery reported (`extras`)**, copy it aside first, and re-run discovery to confirm the
primary survives.

### Minor
- Console legibility is **already partly tested** (generate-build-effort.tests.js:176 asserts stdout
  names the folder) — the only genuine gap is its **coexistence with the sub-agent warning** (:315),
  which goes to **stderr** (both are captured by the `run()` helper).
- The Data quality object literal begins at collect-build-report-data.js:**844** (:842 is the describing
  comment).

---

## Tier 1 — the unit spine (mostly EXISTS; confirm + close gaps)

**Confirm the existing guards (verified mutation-coupled — keep as the regression net):**
report-core.tests.js:210/:164/:184/:237/:406; generate-build-effort.tests.js:175–176;
generate-build-report-html.tests.js:229–239.

**Gaps to add — all in `generate-build-effort.tests.js`, over the `--transcripts` fallback (cheap, no
git), a near-clone of the existing post-delivery-exclusion test (:239–255):**
- **Cost reaches the totals + uplift arithmetic (labelled cost-wiring, not case-selection):** a store
  with one primary record **inside** a `state.json` story window and one second-folder record **outside**
  every window (verify the fixture's timestamps against the windows). Assert `overheadCost` rose by the
  second record's contribution, `inStoryCost` unchanged, `costUplift` rose by construction — reading
  **full-precision `data.totals`/`benchmarks`**, not the rounded console fields.
- **Count/names track the store:** run the same store with, then without, the second folder → assert
  `transcriptFolders` **set membership** changes (worktree name present→absent), not positional equality
  (sort or use set membership — the fallback returns `readdirSync` order).
- **Console + warning coexist:** assert the effort generator's stdout carries `transcriptFolders`
  (names/length) **and** the `WARNING: no sub-agent transcripts found` line appears (stderr) on the
  no-subagent path — the count and the warning together (AC2).
- **(Optional, end-to-end accept)** if the effort test should also prove the *git-confirmed cased*
  worktree feeds the totals (not just the fallback), add a real `git init`+`git worktree add` as
  report-core.tests.js:210 does. Otherwise rely on :210 (discovery) + the merge test :406 for that link.

---

## Tier 2 — recorded-run invariants

These coincide with the Tier-1 gaps: `discoverTranscriptDirs`/the generators take a `transcriptsOverride`,
so the "recorded-run" checks ARE deterministic unit tests over a captured store snapshot (add/remove a
folder in the override; assert totals and `transcriptFolders` track it). Not a separate live capture —
state that plainly. The **only** thing the override cannot exercise is the git-confirmed accept branch
(above); that stays at report-core.tests.js:210.

---

## Tier 3 — behavioural (the AC walkthrough) — MANUAL, Windows-only, environment-gated

The AC procedure by hand on Windows, as corroboration of the **discovery/report** path (not /plan's
recording — see the honesty note):
1. Confirm/manufacture the drive-letter-case mismatch (AC setup): compare `process.cwd()`'s drive-letter
   case against the `~/.claude/projects` folder; if they match, open the project in VS Code and run a
   session so a cased folder is recorded.
2. `/build-report-maintainer`; **snapshot the baseline** discovery output and note `totalCostUsd`,
   `costUplift`, and which folders are named.
3. `git worktree add ../<project>-plan-<epic>`; run a `/plan` session **inside** that worktree to the
   epic park (cwd = worktree, so it records under a worktree folder).
4. `/build-report-maintainer` again → `totalCostUsd` rose; `costUplift` **only if** no story window was
   open during the session (else assert `overheadCost` rose instead); Data quality **names** the new
   worktree folder (set membership vs the baseline, not a literal count); the console shows the folder
   beside the sub-agent warning.
5. `/build-report-stakeholders` → carries neither count nor folder names.
6. Count-drop: prefer the override; if live, delete **by the exact on-disk name** discovery reported,
   after copying it aside, and confirm the primary still resolves.
7. `node .claude/scripts/lib/report-core.tests.js` → all pass, incl. :210 and :164/:184.

**Not harness-automatable:** confirmed — the tier-3 `live-driver` plans in worktrees but **never** invokes
the build report, inspects `~/.claude/projects`, or checks transcript totals (grep for
`build-report|build-effort|\.claude.projects|costUplift` across `tier-3-automated/` → zero hits). Manual
only; deterministic coverage lives in Tier 1.

---

## Acceptance-criteria → test traceability

| AC | Existing guard (verified mutation-coupled) | Gap to add (Tier 1) | Live (Tier 3, manual) |
|---|---|---|---|
| 1 — cased git-worktree counted, stranger out | report-core.tests.js:210, :164, :184, :237, :406; effort:175 | (optional) effort-level end-to-end via a real `git worktree add` | totalCostUsd rises after a session run in the worktree |
| 1 — spend reaches totals / uplift not distorted | :406 (merge) | overheadCost delta + inStoryCost unchanged over the fallback (full-precision) | costUplift rises *iff* no story window open (else overheadCost) |
| 2 — report names what fed the figures | html.tests:229–239; effort:175–176 | count/names track the store (set membership); console + warning coexist | Data quality names the worktree (set membership); delete → gone; stakeholder omits |

---

## Feasibility & prerequisites

- **Unit spine runs now:** all three test files are plain `node`-runnable (custom `test-harness.js`),
  git is present (the :210 real-worktree test passed). The AC's `node …report-core.tests.js` works today.
- **Gap tests are cheap:** `generate-build-effort.tests.js` already has `writeProject`/`writeTranscripts`/
  `usageLine`/`story`/`run` (spawn) helpers and a fixed `LINE_COST`; the delta/count/console tests are a
  near-clone of the :239–255 exclusion test. Effort generator is CLI-only → exercised via `spawnSync`
  over `--transcripts`/`--project-root` (the established pattern).
- **Caveat (load-bearing):** the fallback path bypasses `worktreeMatcher`, so the cheap gap tests prove
  cost-wiring, not case-selection; the git-confirmed cased accept is proven only by report-core.tests.js:210.
  End-to-end accept at the effort level needs a real `git worktree add` (small net-new setup).
- **Tier 3 is manual-only** (no harness scenario) and must not mutate the live store (use the override).

---

## Suggested order of work

1. Run the three test files; confirm green and that the named reverts (norm→identity; worktreeMatcher
   accept-all; render folders on client) each go red (the council verified they do).
2. Add the Tier-1 gap tests to `generate-build-effort.tests.js` over the `--transcripts` fallback:
   `overheadCost`/`costUplift` conservation (full-precision), count set-membership tracking, console +
   warning coexistence. Label them cost-wiring, not case-selection.
3. (Optional) add a real-`git worktree add` effort test if end-to-end accept coverage is wanted.
4. Keep the AC walkthrough as a manual Tier-3 checklist — Windows/env-gated, discovery-not-/plan-recording,
   snapshot-safe.

---

## Appendix — evidence

- Case-insensitive sweep + matcher: [report-core.mjs](.claude/scripts/lib/report-core.mjs) `norm` :112,
  `worktreeMatcher` :135–147 (git-confirmed, siblings-only), primary/sibling selection :190/:197–199,
  dedup-by-id :250 + ts-filter :262, `transcriptsOverride` :178/:204–210, `folders`/`extras` :182,
  drive-letter rationale :108–111, git-`-C`-records-into-project note :132–134/:152–155.
- AC1 tests: [report-core.tests.js](.claude/scripts/lib/report-core.tests.js) :210 (+`toUpperCase` :220,
  `extras` :232), :164, :184, :237, :406.
- Effort figures + folders: [generate-build-effort.mjs](.claude/scripts/generate-build-effort.mjs)
  timestamp attribution :144, `overheadCost`/`inStoryCost` around :145/:163, discovery :139,
  `transcriptFolders` :263, stdout JSON :295–300, sub-agent warning :315, `totalCostUsd` :301,
  `costUplift=totalCost/inStoryCost` :183 / out :305; tests: data file + console name the folder :164–177
  (assert :175/:176), post-delivery-exclusion precedent :239–255.
- Data quality: [collect-build-report-data.js](.claude/scripts/collect-build-report-data.js)
  transcriptFolders :622–624, "read N session folder(s)" fact :838, Data quality object :844;
  [generate-build-report-html.js](.claude/scripts/generate-build-report-html.js) section :811–818;
  maintainer-names/client-omits [generate-build-report-html.tests.js](.claude/scripts/generate-build-report-html.tests.js):229–239.
- Cost report totals: [generate-build-cost-report.mjs](.claude/scripts/generate-build-cost-report.mjs)
  discovery :76, `totalCostUsd` :566.
- Harness: `lib/test-harness.js` (standalone), `generate-build-effort.tests.js` helpers
  `writeProject`/`writeTranscripts`/`usageLine`/`story`/`run`; tier-3 `live-driver.ps1` has no
  build-report/`~/.claude/projects` scenario.
