# Calibration — planted-bad pages that MUST fail each check

These are **hand-authored, committed** fixtures (the same discipline as `fixtures/human-review-calibration/`):
they prove the consistency checks can actually FAIL, independently of any live capture. `baseline.html` is a
spec-shaped review page; each `drifted-*.html` differs from it in exactly one dimension:

| File | Drifted dimension | Check it proves bites |
|---|---|---|
| `baseline.html` | — (reference) | — |
| `drifted-colour.html` | primary button background colour | "main button is the same colour" |
| `drifted-card.html` | card radius / shadow / padding | "cards are drawn the same way" |
| `drifted-heading.html` | h1 font family / size / weight | "page heading is set in the same type" |
| `drifted-label.html` | primary button label text | "buttons are labelled the same" |
| `drifted-message.html` | the on-click hand-back wording | "the hand-back message matches" |

`tier-2-recorded-run/page-consistency/page-consistency.test.ts` fingerprints these and asserts each drift
differs from `baseline.html` on its dimension. This block runs **always** (committed), so the mechanism is
validated even on a checkout with no live `fixtures/page-consistency/projectA|B/` capture.
