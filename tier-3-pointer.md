# Tier 3 — the human walkthrough

Tier 3 is the manual, live-AI walkthrough — the final word before a release. It is
**not** an npm command.

- **What to run and confirm:** see [workflow-tests.md §8 — Tier 3](workflow-tests.md#8-tier-3--the-human-walkthrough).
- **Ground it in the version under test**, not in any QA-side doc: read that
  template's own `.claude/WORKFLOWS.md` and `.template-docs/users/` (Getting-Started,
  Agent-Workflow-Guide, Quality-Gates) before you start — the stages, gates, and
  commands are whatever that version defines.
- **Aim at a specific version** with `npm run test:target -- --target <dev|release> --ref <tag>`
  (see [workflow-tests.md §12](workflow-tests.md#12-testing-any-template-any-version)).

## When to run Tier 3

- Before a major template release
- After changes to the orchestrator rules, an agent, or the hook configuration
- When the Tier 2 golden run needs re-recording (a clean Tier 3 pass is the moment to
  re-record it — see [workflow-tests.md §7](workflow-tests.md#7-tier-2--invariants-over-a-recorded-run))

## What Tier 3 catches that Tiers 1 and 2 cannot

- The real AI behaviour of each agent, not just the scripts supporting it
- Interactions between hooks, agents, and commands that only manifest in live sessions
- Whether Claude actually obeys the policy rules (facts-over-template, plain language)
- End-to-end feel — the hands-on check, the dashboard, the dev-server interaction

Tier 3 is expensive but irreplaceable. Tiers 1 and 2 exist to catch most regressions
cheaply so Tier 3 only needs to run occasionally.
