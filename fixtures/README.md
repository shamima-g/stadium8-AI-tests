# Fixtures

Deterministic test inputs. See [workflow-tests.md §11](../workflow-tests.md#11-test-inputs-and-fixtures)
for how the canonical scenario is used.

## scenarios/

The **Team Task Manager** scenario and its variants — the canonical inputs, held as
data so tests read them directly:

- `team-task-manager/` — main scenario (no compliance, frontend-only auth, backend in
  development); `answers.json` + `frs-expected.md`
- `variant-a-bff/` — sign-in handled by your own server (BFF) with real auth URLs
- `variant-b-no-backend/` — no data source at all (stand-in data only)
- `variant-c-user-spec/` — you already provided a data-service description
  (`task-api.yaml`, OpenAPI using `/api/v2/tasks`) — proves the generated code honours
  the exact paths

Each folder contains the exact scripted answers, expected outputs, and any source
files the variant introduces.

## checkpoints/

Tarball fixtures for `CP-0` … `CP-5` (the epic-branch starting states — see
[workflow-tests.md §10](../workflow-tests.md#10-helpers-checkpoints-and-rollbacks)).
Each is a `.tar` of `generated-docs/` (and `web/src/`) at the corresponding state.

**These are NOT committed by default** (see `.gitignore`). To harvest, from a real run
that's reached the checkpoint:

```bash
tar -cf fixtures/checkpoints/CP-1.tar generated-docs/
```

If the tarballs are absent, `loadCheckpoint()` synthesises a minimum checkpoint —
enough for state-machine tests but not for full snapshot tests.

## golden-run/

The recorded real run that Tier 2 replays — a `repo.bundle` (git history of the
`epic/<slug>` branch + merge) and/or a copy of the `generated-docs/` tree. See
[workflow-tests.md §7](../workflow-tests.md#7-tier-2--invariants-over-a-recorded-run)
for what's captured and when to re-record.
