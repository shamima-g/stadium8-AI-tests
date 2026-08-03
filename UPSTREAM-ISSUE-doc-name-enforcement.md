# Upstream template defect — epic-scoped doc-name enforcement is a silent no-op

> **Status:** found by this QA suite (branch `reconcile/v1.2.0`), 2026-08-03. Present
> on **both** channels at v1.2.0 (`stadium-software/stadium-8`,
> `Digiata/Stadium-Builder`) and back to v1.1.0 — **not a v1.2.0 regression**, a
> long-standing defect. Not yet filed as a GitHub issue (the fix lives in the external
> template repo, which this QA repo can't edit).

The QA tests that catch this are marked `it.fails()` (expected-fail): they stay green
while the bug exists and flip **red the instant the template ships the fix**, which is
the signal to remove the markers. See:

- `tier-1-unit/hooks/enforce-generated-doc-names.test.ts` (4 epic-scoped block cases)
- `tier-1-unit/scripts/validate-generated-doc-names.test.ts` (2 cases)

## What's broken

Both the PreToolUse hook `.claude/hooks/enforce-generated-doc-names.js` and the audit
`.claude/scripts/validate-generated-doc-names.js` share a `dirGlobToRegex()`:

```js
function dirGlobToRegex(glob) {
  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '[^/]*');
  const trimmed = escaped.replace(/\/$/, '');
  return new RegExp('^' + trimmed + '/?$');
}
```

It translates `*` → `[^/]*` but does **nothing** with the literal `<slug>` placeholder
used in `.claude/shared/generated-doc-conventions.json`:

```json
{ "id": "epic-brief", "dirGlob": "generated-docs/epics/<slug>/", ... }
```

`<` and `>` are ordinary characters in a JS regex, so the glob compiles to
`^generated-docs/epics/<slug>/?$` — which only matches the literal text
`generated-docs/epics/<slug>/`, never a real epic dir like
`generated-docs/epics/task-browsing/`.

## Blast radius

Every **epic-scoped** convention is a dead rule — its `dirGlob` never matches, so the
file is treated as *ungoverned* and passes unchecked:

| Convention | Correct name | Drift name that is wrongly ALLOWED |
|---|---|---|
| epic-brief | `brief.md` | `epic-brief.md` |
| epic-state | `state.json` | `epic-state.json` |
| epic-journal | `journal.md` | `epic-journal.md` |
| story-file | `story-<n>-<slug>.md` | `story-3.md` |

Only the two **flat-dir** conventions (`project-facts` in `generated-docs/`, `e2e-spec`
in `web/e2e/`) have no placeholder, so they still fire. The audit under-counts the same
way: epic-scoped files land in `ungoverned` instead of `ok`/`drift`.

Downstream: wrongly-named `state.json` / `brief.md` break `resolve-state-path.js` and
the Tier-2 golden-run invariants, so the damage isn't cosmetic.

## Fix (validated against 8 boundary cases)

Translate `<...>` placeholders to a single-segment wildcard, in **both** scripts:

```js
function dirGlobToRegex(glob) {
  const escaped = glob
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/<[^>]*>/g, '[^/]*')   // <slug> (and any <...> placeholder) → one path segment
    .replace(/\*/g, '[^/]*');
  const trimmed = escaped.replace(/\/$/, '');
  return new RegExp('^' + trimmed + '/?$');
}
```

`[^/]*` (not `.*`) keeps the match inside one path segment, so
`generated-docs/epics/<slug>/` matches `.../task-browsing/` but **not**
`.../task-browsing/stories/`, and the flat conventions keep working. (Alternative: change
the conventions to use `*` instead of `<slug>` — but translating the placeholder keeps the
conventions human-readable.)

## Suggested issue

- **Repo:** `stadium-software/stadium-8` (dev); note `Digiata/Stadium-Builder` (release)
  is equally affected.
- **Title:** *Epic-scoped doc-name enforcement is a silent no-op — `dirGlobToRegex`
  doesn't translate the `<slug>` placeholder*
- **Body:** the root cause, blast-radius table, and fix above; repro = run the QA suite's
  `enforce-generated-doc-names` / `validate-generated-doc-names` tests against any
  checkout, or the one-liner: a `Write` of `generated-docs/epics/x/epic-brief.md` through
  the hook exits 0 (allowed) instead of 2 (blocked).
