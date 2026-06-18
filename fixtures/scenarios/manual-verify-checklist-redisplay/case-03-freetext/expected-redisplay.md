<!--
TODO: harvest
============

This fixture is a placeholder. Drives **TEST-GUIDE §21c — Free-text re-ask**.
Once a Team Task Manager Story 1 run completes a free-text re-ask cycle (at
the manual-verification ask, the tester types the canonical free-text question
`What URL should I be on for AC-2?` instead of picking an option, the
orchestrator answers, then re-asks), copy the contents of:

    generated-docs/qa/epic-1-task-browsing/story-1-view-task-list-verification-checklist.md

verbatim into this file (replacing this comment block entirely). The text
should be byte-identical to both `../case-01-first-ask/expected-checklist.md`
and `../case-02-fixcycle/expected-redisplay.md` — that is the contract. Three
separate files exist so a drift on one path is visible immediately rather than
masked by a shared fixture.

The §21c test will then compare the on-screen re-ask `AskUserQuestion` text
(after the orchestrator answers the free-text question) byte-for-byte against
this file. Any drift means the orchestrator forgot to re-display the full
checklist after answering.

See the parent `README.md` for the full harvest procedure.
-->
