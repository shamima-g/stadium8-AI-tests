# Tier 2 — Telemetry Invariants

Asserts behavioural and timing/token invariants over the **telemetry ledger**
(`generated-docs/context/telemetry.ndjson`) and the reports derived from it by
`.claude/scripts/generate-telemetry-report.js`.

> **Retired:** Tier 2 previously replayed harvested `.claude/logs/*.md` session
> logs (`parseSessionLog`, `loadGoldenLog`, the `assertions` helper). The current
> 4-phase template does **not** emit `.claude/logs`, so that mechanism — and the
> ~13 invariants that depended on it — were removed. See git history if you need
> the old replay approach.

## How it works

1. The capture layer emits events to `generated-docs/context/telemetry.ndjson`:
   - `transition-phase.js` writes `phase_enter` / `phase_exit` (macro spans).
   - the `telemetry.js` hook writes `agent_start` / `agent_stop` (granular spans),
     `turn_end`, and `user_input` (the user-wait window that active-time excludes).
2. `generate-telemetry-report.js` derives the four reports (estimate, timing,
   tokens, final variance). Tokens come from the transcript `usage` blocks, joined
   onto spans by timestamp.
3. Tests run the generator against a committed synthetic run
   (`../fixtures/golden-telemetry/sample-run/`) and assert the numbers; a real
   harvested baseline anchors the estimate/variance and freshness canary.

## Invariants implemented

| File | Covers | Status |
|---|---|---|
| `telemetry-ledger-shape.test.ts` | ledger structure (span pairing, monotonic ts) | Implemented |
| `telemetry-report-math.test.ts` | timing (wait-excluded), token attribution, per-story variance, baseline round-trip | Implemented |
| `stale-log-canary.test.ts` | telemetry-baseline freshness vs orchestrator-rules / settings | Implemented |

## Why not just live-test?

Live tests (Tier 3, `/TEST-GUIDE.md`) are expensive — a full workflow pass takes
~30 minutes. Tier 2 amortises that: the deterministic report math is checked in
milliseconds on every PR against the synthetic fixture, with no live run needed.

## Re-harvesting the baseline

The synthetic `sample-run` is enough for the report-math tests. To anchor the
estimate/variance reports against a real profile, harvest a baseline from a live
run — see `../fixtures/golden-telemetry/README.md`. The freshness canary warns
when that baseline goes stale relative to `orchestrator-rules.md` / `settings.json`.
