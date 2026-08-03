# Template comparison — release-v1.2.0 vs dev-v1.2.0

**Verdict: 🟠 AMBER**

## 🟠 Explained — pending promotion (1)

Documented work present on one side and not the other. This is the promote checklist.

| List | Value | Only in | Explained by |
|---|---|---|---|
| commands | `release` | dev-v1.2.0 | 1.2.0: **An upgrade now uses the *new* version's updating machinery, not your current one's.** `/upgrade` fetches the version you're moving to and hands the work over to it. Before, it ran the copy already in your project, so improvements to the updater itself arrived a release late. |
