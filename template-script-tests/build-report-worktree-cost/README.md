# Build-report worktree-cost — gap tests

These tests belong to a **different layer** than the vitest suites in `tier-1-unit/`. They extend the
template's **own shipped script suite** — `.claude/scripts/generate-build-effort.tests.js` — which is a
standalone Node harness run as `node .claude/scripts/generate-build-effort.tests.js` (no vitest, no
REPO_ROOT). Because the tests only run *inside* a template checkout (they drive
`generate-build-effort.mjs` end-to-end), they can't live as runnable files here; they are carried as a
**reapplyable patch** so they're version-controlled in this repo and can be applied to any template
checkout (or landed upstream in `stadium-software/stadium-8`).

## What they cover

Three gap tests for the parallel-worktree cost feature (see
[../../test-plans/build-report-worktree-cost-test-plan.md](../../test-plans/build-report-worktree-cost-test-plan.md)):

1. **conservation** — a second session folder's out-of-story spend raises `overheadCost` and
   `costUplift`, leaving `inStoryCost` intact (measured as a with/without delta through the generator's
   own totals, full-precision).
2. **named list tracks the store** — `transcriptFolders` set membership drops when a folder is removed
   (AC2 "not fixed text").
3. **console + warning coexist** — the folders are named on stdout beside the missing-sub-agent warning.

They run over the discovery **override fallback**, so they prove **cost-wiring**, not case-selection.
The case-insensitive, git-confirmed worktree *accept* (AC1) is proven by the template's existing
`report-core.tests.js` (the "differently-cased worktree still counts" test).

## Apply

```bash
cd <a stadium-8 template checkout>
git apply <this dir>/generate-build-effort.gap-tests.patch
node .claude/scripts/generate-build-effort.tests.js   # 33 passed
```

The patch was cut against template commit `34a574a` (the `28-09-2026` snapshot). If
`generate-build-effort.tests.js` has moved on, re-cut it from that checkout.

## Note

The right long-term home for these is upstream in the template's `generate-build-effort.tests.js`. This
patch is the harness-repo record of the work; landing it upstream (or reverting the snapshot-clone edit
in favour of that) is the follow-up.
