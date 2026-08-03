# Bug report & fix guide — epic-scoped doc-name enforcement is a silent no-op

| | |
|---|---|
| **Component** | `.claude/hooks/enforce-generated-doc-names.js` + `.claude/scripts/validate-generated-doc-names.js` |
| **Severity** | High — a safety guard that silently enforces nothing (fails open) |
| **Type** | Latent defect (not a v1.2.0 regression) |
| **Affected repos** | `stadium-software/stadium-8` (dev) **and** `Digiata/Stadium-Builder` (release) |
| **Affected versions** | v1.1.0 and v1.2.0 (both channels; likely earlier) |
| **Found by** | QA suite `reconcile/v1.2.0` — the 6 tests below are marked `it.fails()` and will flip **red** (unexpected pass) the moment this fix lands, which is the signal to remove the markers |
| **Fix size** | One line, applied identically in two files |

---

## TL;DR

Both the write-time hook and the audit script decide whether a generated doc's filename
is governed by matching the file's parent directory against a `dirGlob` from
`.claude/shared/generated-doc-conventions.json`. Four of the six conventions use a
`<slug>` placeholder in that glob (`generated-docs/epics/<slug>/`). The glob→regex
converter translates `*` but **not** `<slug>`, so it emits a regex that matches only the
literal text `<slug>` — never a real epic folder. Every epic-scoped naming rule is a
dead branch: wrongly-named `brief.md`, `state.json`, `journal.md`, and story files are
written and audited **without any check**.

---

## Root cause

`dirGlobToRegex()` is byte-identical in both files:

- `enforce-generated-doc-names.js` **lines 34–38**
- `validate-generated-doc-names.js` **lines 37–41**

```js
function dirGlobToRegex(glob) {
  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '[^/]*');
  const trimmed = escaped.replace(/\/$/, '');
  return new RegExp('^' + trimmed + '/?$');
}
```

It handles `*`, but `<` and `>` are ordinary characters in a JS regex and are left
untouched. Walk it through for the `epic-brief` convention
(`generated-docs/conventions.json` → `"dirGlob": "generated-docs/epics/<slug>/"`):

| Step | Value |
|---|---|
| input glob | `generated-docs/epics/<slug>/` |
| after escape + `*`→`[^/]*` | `generated-docs/epics/<slug>/` *(unchanged — no `*`, `<slug>` is literal)* |
| trim trailing `/` | `generated-docs/epics/<slug>` |
| final regex | `^generated-docs/epics/<slug>/?$` |

That regex matches the literal string `generated-docs/epics/<slug>/` and nothing else.
A real file's parent dir is `generated-docs/epics/task-browsing/`, so the test at
`enforce-generated-doc-names.js:100` / `validate-generated-doc-names.js:97`
(`if (!dirGlobToRegex(c.dirGlob).test(parentDir)) continue;`) is **always false** for
epic-scoped conventions → the convention is skipped → the file is treated as
*ungoverned* → allowed. The two flat conventions (`project-facts` →
`generated-docs/`, `e2e-spec` → `web/e2e/`) have no placeholder, so they still work —
which is why the bug hides.

---

## Reproduction

Against any checkout of the template (`ROOT` = a project dir with the conventions file):

```bash
# Hook: a drift-named epic file should be BLOCKED (exit 2) but is ALLOWED (exit 0)
echo '{"tool_name":"Write","tool_input":{"file_path":"generated-docs/epics/task-x/epic-brief.md"}}' \
  | node .claude/hooks/enforce-generated-doc-names.js ; echo "exit=$?"
# => exit=0   (BUG — should be exit=2 "Blocked by filename-convention guard")

# Control: a flat-dir drift file IS correctly blocked
echo '{"tool_name":"Write","tool_input":{"file_path":"generated-docs/project-facts.md"}}' \
  | node .claude/hooks/enforce-generated-doc-names.js ; echo "exit=$?"
# => exit=2   (correct)
```

The audit under-counts the same way: seed an epic tree with a drift-named
`epic-state.json` and run `node .claude/scripts/validate-generated-doc-names.js
--format=json`; it reports the file as `ungoverned` (drift count 0) instead of `drift`.

---

## Impact / blast radius

Every **epic-scoped** convention is unenforced end to end (write-time and audit):

| Convention | `dirGlob` | Correct name | Drift name silently ALLOWED |
|---|---|---|---|
| `epic-brief` | `generated-docs/epics/<slug>/` | `brief.md` | `epic-brief.md` |
| `epic-state` | `generated-docs/epics/<slug>/` | `state.json` | `epic-state.json` |
| `epic-journal` | `generated-docs/epics/<slug>/` | `journal.md` | `epic-journal.md` |
| `story-file` | `generated-docs/epics/<slug>/stories/` | `story-<n>-<slug>.md` | `story-3.md` |

Only `project-facts` and `e2e-spec` (flat globs) still enforce. Downstream, a
misnamed `state.json` / `brief.md` breaks `resolve-state-path.js` resolution and the
Tier-2 golden-run invariants — so this is a correctness risk, not cosmetics.

---

## The fix

Add one `.replace()` that turns any `<...>` placeholder into a single-path-segment
wildcard, **before** the `*` translation. Apply the **same** change in both files.

**`.claude/hooks/enforce-generated-doc-names.js` (lines 34–38)** and
**`.claude/scripts/validate-generated-doc-names.js` (lines 37–41):**

```diff
 function dirGlobToRegex(glob) {
-  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '[^/]*');
+  const escaped = glob
+    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
+    .replace(/\*/g, '[^/]*')
+    .replace(/<[^>]*>/g, '[^/]*');  // <slug> (and any <...> placeholder) → one path segment
   const trimmed = escaped.replace(/\/$/, '');
   return new RegExp('^' + trimmed + '/?$');
 }
```

> Translate the `<...>` placeholder **after** the `*` step (not before), so the inserted
> `[^/]*` isn't re-processed by the `*` rule. This yields a clean
> `^generated-docs\/epics\/[^/]*\/?$`. Verified against the 8 boundary cases below (all pass).

> **Keep the two copies identical.** They already are, and the QA suite treats any
> divergence as drift. (Optional follow-up: hoist `dirGlobToRegex` into a shared module
> both files require, so this can't drift again.)

### Why `[^/]*` and not `.*`

`[^/]*` matches within a single path segment, which is what an epic slug is. That keeps
the conventions correctly scoped:

- `generated-docs/epics/<slug>/` → `^generated-docs/epics/[^/]*/?$` matches
  `generated-docs/epics/task-browsing/` but **not** `.../task-browsing/stories/` (the
  `[^/]*` can't cross the `/`), so a brief can't be confused with a story.
- `generated-docs/epics/<slug>/stories/` → `^generated-docs/epics/[^/]*/stories/?$`
  matches the stories dir only.

`.*` would span `/` and let `epic-brief` wrongly match files under `stories/`. Validated
against 8 boundary cases (each epic-scoped dir, the stories subdir, and both flat dirs).

---

## Verification

1. **Repro commands above now behave:** the epic-brief write returns `exit=2`; the audit
   reports the drift file as `drift`.
2. **Add a template regression test** (there is currently no co-located coverage of the
   `<slug>` case). Minimal unit assertion:

   ```js
   // dirGlobToRegex must resolve the <slug> placeholder to a real epic dir
   assert(dirGlobToRegex('generated-docs/epics/<slug>/').test('generated-docs/epics/task-browsing/'));
   assert(!dirGlobToRegex('generated-docs/epics/<slug>/').test('generated-docs/epics/task-browsing/stories/'));
   assert(dirGlobToRegex('generated-docs/epics/<slug>/stories/').test('generated-docs/epics/task-browsing/stories/'));
   ```

3. **The QA suite confirms the fix externally.** These cases are currently `it.fails()`
   (expected-fail); after the fix they pass, so the `it.fails()` markers turn **red**
   (unexpected pass) — that red is the cue to delete the markers:
   - `tier-1-unit/hooks/enforce-generated-doc-names.test.ts` — the 4 epic-scoped
     "drift-named new file is blocked" cases
   - `tier-1-unit/scripts/validate-generated-doc-names.test.ts` — the 2 `[KNOWN DEFECT]`
     cases

---

## Rollout checklist

- [ ] Apply the one-line fix in **both** files (dev repo `stadium-software/stadium-8`).
- [ ] Add the `dirGlobToRegex` `<slug>` regression test (co-located).
- [ ] Confirm the repro commands now block/flag correctly.
- [ ] Ship to the release repo `Digiata/Stadium-Builder` (equally affected) via the normal
      publish path.
- [ ] In the QA suite, once the template ships the fix: remove the `it.fails()` markers in
      the two test files and delete this doc's references.
