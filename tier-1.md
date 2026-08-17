# Tier 1 — automated unit tests

> This is one of the three tier files. Everything that is shared across all tiers —
> the rules every test follows, the surface-area map, the good-and-broken discipline,
> the helpers and rollbacks, the fixtures, version handling, the maintenance routine,
> and the coverage picture — stays in the hub: [workflow-tests.md](workflow-tests.md).
> This file covers **Tier 1 only**.

Standard Vitest (JavaScript) and Pester (PowerShell) tests. They run on every change
and finish in seconds. A few areas get extra care:

- **Epic-state machine.** The stage graph is pinned where it's defined: the `state.json`
  schema is single-sourced from `epic-state.js` (`EPIC_PHASES`), the full
  `VALID_TRANSITIONS` table is asserted against a hand-written literal (so adding a
  skip-a-stage edge or dropping the READY-TO-BUILD park fails the suite), and
  `epic-state.js --init` is proven **deterministic** — two runs produce an identical
  `state.json` once the `createdAt`/`lastUpdated` timestamps are set aside.
  `mark-epic-complete.js` freezes an epic's record correctly (idempotent, refuses
  premature phases, rejects path-traversal slugs), and `resolve-state-path.js` finds the
  right state file for the branch you're on. **Enforcing a move at runtime — refusing to
  advance a stage whose inputs aren't ready, and driving BUILD's per-story loop — is the
  orchestrator's job over these tables, so it's a Tier-3 behaviour, not something
  `epic-state.js` does itself (its only command is `--init`).**
- **Branch & merge machinery (git sandbox).** In a throwaway repo, we prove: an epic
  branch is named `epic/<slug>`; two epics that touch the central style file in
  *non-conflicting* ways combine cleanly on their own; and two epics that change the
  *same* style-token line, or pin the *same* outside tool to different versions,
  **conflict — leaving `<<<<<<<` markers that surface both versions** instead of
  guessing. **What the git sandbox can't decide — whether the workflow halts and
  surfaces the conflict to *you*, and that a merge into `main` lands only through an
  approved request rather than a silent direct push — is a running-workflow behaviour,
  confirmed in Tier 3 (these tests merge directly into `main`).**
- **Permission-hook fuzzing.** `bash-permission-checker.js` decides which shell
  commands are allowed. It's security-critical, so the enumerated dangerous commands
  (`rm -rf /`, SSH keys, `.pem`, credential reads) are **hard-asserted to deny**, and an
  adversarial fuzz suite — `rm -rf /` whitespace/flag-split variants, shell wrappers,
  command chains, and base64/hex/octal-encoded payloads — is asserted to **never
  auto-approve** (falling through to a human prompt is acceptable; the hook isn't
  expected to decode a disguised payload, only never to green-light one). One dangerous
  command auto-approved is the failure we most want to catch.
- **Generated-doc-name enforcement.** `enforce-generated-doc-names.js` (via
  `validate-generated-doc-names.js`) must allow a file written to the correct
  epic-scoped place (`generated-docs/epics/<epic>/…`) and block one with the wrong
  name or location.
- **Doc and config drift.** The biggest rot in a template is documentation that no
  longer matches the files. So we check: every agent file has valid frontmatter and
  appears in the agents `README.md`; every `/command` mentioned in `CLAUDE.md` exists;
  every hook command in `settings.json` points at a real file; and the agent list
  matches what's on disk.
- **JSON schema checks.** The per-epic `state.json` schema **single-sources** its
  stage/status enums from the template's own `epic-state.js` (`EPIC_PHASES` etc.), so
  it can't drift from the producer.
- **Generated-code linting.** The rules in [the surface area](workflow-tests.md#5-what-we-test--the-surface-area),
  proven on samples and then run over the real output when it exists.
