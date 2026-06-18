<!--
TODO: harvest
============

This fixture is a placeholder. Drives **TEST-GUIDE §21b — Fix-cycle re-display**.
Once a Team Task Manager Story 1 run completes through one full QA fix cycle
(user types `Issues found` → `The button label says Submit but it should say
Save Task` → developer fix completes → re-verification ask), copy the contents
of:

    generated-docs/qa/epic-1-task-browsing/story-1-view-task-list-verification-checklist.md

verbatim into this file (replacing this comment block entirely). The text
should be byte-identical to `../case-01-first-ask/expected-checklist.md` —
that is the contract. Three separate files exist so a drift on one path is
visible immediately rather than masked by a shared fixture.

The §21b test will then compare the on-screen re-verification `AskUserQuestion`
text (after the developer fix completes) byte-for-byte against this file.
Any drift means the orchestrator paraphrased, abbreviated, or replaced the
checklist with a "see above" reference after the fix.

See the parent `README.md` for the full harvest procedure.
-->
