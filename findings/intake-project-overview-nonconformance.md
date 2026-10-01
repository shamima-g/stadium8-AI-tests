# Bug report — INTAKE writes a non-conforming `## Project Overview`

**Component:** `/start` INTAKE → `CLAUDE.md` `## Project Overview`
**Spec violated:** `.claude/shared/project-overview.md`
**Severity:** Medium (output contradicts its own governing spec; the Roles violation is functionally load-bearing)
**Status:** Reproducible — **2 of 2 completed intake runs failed** (captured 2026-09-30)

## Summary

When `/start` runs INTAKE, `start.md` Step 9 writes the `## Project Overview` section of `CLAUDE.md`.
That section is governed by `.claude/shared/project-overview.md`. On every completed run we captured, the
written section **violated that spec** — and the *way* it failed varied run to run, so the INTAKE step is
not reliably producing the shape the spec defines.

Benchmark used: the `contact-form` fixture (3 roles — Visitor / Support Agent / Admin — with auth and a
data source). Template under test: release-shaped snapshot of 28-09-2026.

## Defects (present in both completed runs)

1. **No pointer line.** The spec requires exactly one closing line pointing to the three docs
   (`generated-docs/project.md`, `generated-docs/epics/`, `generated-docs/architecture.md`) — and calls
   it the *one* clause that transfers verbatim to every project. Both runs omitted it entirely.
2. **Roles written as prose, not exact backticked strings.** The spec requires the Roles bullet to list
   the exact role names in backticks (shape example: `` - Roles: `File Importer`, `Approver` ``), because
   those strings are the app's real RBAC identifiers. Both runs wrote descriptive prose instead
   (e.g. `Visitor (submits enquiries, views own)`), losing the exact-string guarantee.
3. **Third bullet labelled "Data" instead of "Data source."** Minor, but diverges from the spec's named
   bullet.

## Additional variance (run 3 only)

- The **Auth bullet was dropped entirely**.
- Bullets were written as **bold paragraphs, not a list** (no `-` markers).

## Evidence

Spec (`.claude/shared/project-overview.md`): "three bullets, one pointer line — within 12 lines and 150
words"; Roles bullet = "closed list; exact string form"; "Pointer line, exactly three: …"; and
"The shape, not the wording … except the pointer line."

**Run 1** (commit `docs(project): project setup + epic plan`):

```markdown
## Project Overview

**Contact & Enquiry Management** — A public-facing contact form for Visitors to submit enquiries ...

- **Roles:** Visitor (submits enquiries, views own), Support Agent (triages inbox), Admin (can also delete)
- **Auth:** Server-side (simulated client-side for prototype)
- **Data:** Mock-only with in-memory fixtures
```

**Run 3** (commit `docs(project): project setup + epic plan`):

```markdown
## Project Overview

**Contact & Enquiry Management** — A contact enquiry capture and back-office triage application. ...

**Roles:** Visitor (submits enquiries, views own submissions) · Support Agent (triages and resolves enquiries) · Admin (everything an Agent can do, plus delete)

**Data:** Mock-only with in-memory fixtures (prototype — all server behaviour simulated client-side)
```

Both audit as non-conforming (`structure.ok = false`, `roles.equal = false`); budget is fine (≤12 lines /
≤150 words) and no forbidden tokens leak — the failures are structural, not length/leak.

## Likely cause

`start.md` Step 9 (where the section is written) is not tightly coupled to `project-overview.md`'s required
shape — the pointer line, the backticked-roles rule, and the exact bullet labels aren't being enforced at
write time, so the model's phrasing drifts each run.

## Suggested fix

Have Step 9 emit the section from the spec's "Shape to match" template verbatim (pointer line included,
backticked role names, labels `Roles` / `Auth` / `Data source`), then fill in only the per-project facts —
rather than free-writing the section.

## How to reproduce

Run `/start` INTAKE against a release-shaped template with the `contact-form` answers, stop after the
`docs(project)` commit, and compare `CLAUDE.md`'s `## Project Overview` to `.claude/shared/project-overview.md`.
(Two of two completed runs reproduced the first three defects.)
