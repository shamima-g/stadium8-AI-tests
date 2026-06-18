# Golden Telemetry

Telemetry fixtures for Tier 2. **Replaces the retired `.claude/logs` session-log
replay** — the current 4-phase template no longer emits `.claude/logs/*.md`, so Tier 2
now asserts over the telemetry ledger and the reports derived from it.

## What's here

- **`sample-run/`** — a small SYNTHETIC run used to unit-test the report math
  (`generate-telemetry-report.js`) against known-good numbers. It is hand-authored
  and clearly labelled; it is NOT a captured session. Layout:
  ```
  sample-run/
    transcript.jsonl                              # 2 usage records
    generated-docs/context/telemetry.ndjson       # the event ledger
    generated-docs/context/telemetry-meta.json    # transcript path (relative)
    generated-docs/context/workflow-state.json    # 1 epic / 1 story
  ```
- **`baseline.json`** *(not committed; created by a real harvest)* — the
  golden-harvest-derived per-unit baseline that anchors the estimate/variance
  reports and the freshness canary.

## How to harvest a real baseline

The telemetry ledger is produced live by the capture layer
(`.claude/scripts/lib/telemetry.js` + the `telemetry.js` hook). To capture a real
baseline:

1. Register the telemetry hook in `.claude/settings.json` (see
   `.claude/hooks/telemetry.js` header / the project setup notes).
2. Run a clean `/start` → … → COMPLETE cycle with the Team Task Manager answers
   from `/TEST-INPUTS.md`. The ledger accumulates at
   `generated-docs/context/telemetry.ndjson`.
3. Write the baseline:
   ```bash
   node .claude/scripts/generate-telemetry-report.js --write-baseline \
     --baseline QA-TESTS/fixtures/golden-telemetry/baseline.json
   ```
4. Optionally copy the run's `generated-docs/context/` into a new
   `golden-telemetry/<date>-full-happy-path/` directory to add a real replay run.
5. Commit. The freshness canary then warns when this baseline goes stale relative
   to `orchestrator-rules.md` / `settings.json`.

## What Tier 2 asserts

- **Ledger shape** — phase spans pair up, timestamps are monotonic, every
  `agent_start` has an `agent_stop`.
- **Report math** — timing (active time excludes user-wait), tokens (attributed by
  timestamp join), per-story rollups, and estimate/variance against a baseline.
