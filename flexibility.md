# Test Suite Flexibility — Testing Any Template, Any Version

A plain-English explanation of how to let QA test any template at any version, and
compare dev against release before promoting.

---

## The situation

You have a test suite. It checks a "template" (the `.claude/` folder). That template
exists in **two places**:

- **Dev** version → lives at `https://github.com/stadium-software/stadium8`
- **Release** version → lives at `https://github.com/digiata/stadium8`

And each of those can have different **tagged versions** (like v8.2, v8.3).

You want QA to be able to say: *"Test THIS template, at THIS version"* — easily, without
editing the tests each time. And you want to **compare** dev against release, so you know
it's safe to move dev into release.

---

## The good news

Your test suite is already built to point at **one folder at a time**. There's a single
setting (`REPO_ROOT`) that says "the template I'm testing is over here." Everything in the
suite obeys that setting.

So you don't need to rebuild anything. You just need to add a small step **in front** that
says which folder to point at.

---

## What this looks like (in everyday terms)

Think of it like a TV remote:

1. **A short list of channels.** A tiny file that just says: `dev = this GitHub link`,
   `release = that GitHub link`. Adding a new template later = adding one line.

2. **A "tune in" button.** QA runs one command like *"test **dev** at version **v8.3**."*
   The suite downloads that exact version of that exact template into a scratch folder and
   points itself at it. Done. No file editing.

3. **A "you're off-script" warning.** The suite is written to expect the template to look a
   certain way (this is `template-contract.json` — think of it as the *expected recipe*).
   If QA tests a version whose recipe has changed, the suite prints: *"Heads up — this
   version is different from what I was written for, so failures here might just be 'it
   changed', not 'it broke.'"* That stops people panicking over false alarms.

4. **Labelled results.** Every test run gets filed under its name and version — e.g. a
   folder called `release-v8.2` and another called `dev-v8.3`. So you can lay the two side
   by side and see the difference. **That side-by-side is exactly your "is dev ready to
   become release?" check.**

---

## Where this pattern comes from

The LINX test suite next door already does this trick. The only difference: LINX tests a
*tool it installs*, and this suite tests a *template it downloads from GitHub*. Same idea —
"aim the tests at any version, warn if it's different, save results per version" — just
swapping "install the tool" for "download the repo."

| LINX concept                     | This suite's equivalent                        |
| -------------------------------- | ---------------------------------------------- |
| Install a specific tool version  | Download a specific template repo + version    |
| Version = a single number        | Version = **which repo (dev/release) × which tag** |
| Aim the run with a flag          | Aim the run with a target + ref                |
| The folder the tool installs to  | `REPO_ROOT` (already exists here)              |

---

## The bottom line

You get two things:

- **"Test any template, any version"** = pick a name + a version, hit run.
- **"Compare before promoting"** = results saved per version, laid side by side.

And it's built almost entirely on switches your suite already has — mostly wrapping, very
little rebuilding.

---

## Decisions made

### 1. When dev and release differ → RED **and** written into the report

When the suite finds that dev and release differ, the run **fails (goes red)** *and* the
exact difference is **written into the report**. Loud and documented — no silent drift.

### 2. Two recipes — one per version (Option B)

There are **two** expected recipes, kept separately:

- `template-contract.dev.json` — the correct shape for the **dev** template.
- `template-contract.release.json` — the correct shape for the **release** template.

Each version is judged against **its own** recipe:

- Test **release** against the release recipe → ✅ green when release is correct.
- Test **dev** against the dev recipe → ✅ green when dev is correct.

So neither version "fails" just for being ahead or behind the other. Green means that
version genuinely matches what it's supposed to be.

**Upkeep:** when dev changes, its recipe (`template-contract.dev.json`) is updated to
match; same for release. Two files to keep current.

### How the two decisions fit together

Because each version has its own recipe (decision 2), the normal per-version tests stay
green as long as each version is internally correct. The "go red when dev and release
differ" from decision 1 is therefore a **separate dev-vs-release comparison step**:

1. **Per-version checks** — is dev correct against the dev recipe? Is release correct
   against the release recipe? (Each green on its own.)
2. **Comparison step** — line the two versions up against each other. If they differ, the
   run goes **red** and the report lists exactly what dev has that release doesn't (and
   vice versa). This is your *"what still needs to be promoted from dev into release"*
   checklist.

So: two clean green per-version runs, plus one comparison that goes loud when the two
drift apart.

---

## Handling version skew (testing an old version with a newer suite)

**The scenario:** QA wants to run the tests (e.g. the L6 tests) against a dev template that
is, say, **3 versions old**. But the test code itself was written for **today's** template
— 3 versions *newer*. How do we let someone run tests for *any* version at *any* time
without getting fake failures?

### The problem in plain terms

Two separate things each have a version:

1. **The template** — the thing being tested (the old one).
2. **The test suite** — the code doing the testing (written for the new one).

Trouble happens when they're far apart. The newer suite might check for a stage, a status,
a rule, or a command that **didn't exist yet** in the old template. The test fails — but
nothing is actually broken. That's a **fake failure caused only by the version gap**, not a
real bug. For L6 especially: Claude's app would be graded against **today's** rules when it
should be graded against the rules that existed back then.

The honest truth: you can't force a test written for the new version to pass against an old
version that genuinely lacks the feature. So the goal is not "make old versions pass
everything" — it's **"never let a version gap look like a bug."** Four layers do that:

### Layer A — Always show the gap

Every run prints and saves three facts: *what version the suite was written for*, *what
version it's actually testing*, and *the gap between them*. If they differ, it warns:
*"this suite is written for the new version but you're testing an old one — failures below
may just be the version gap, not real bugs."* Nobody misreads a gap as a break.

### Layer B — Each test knows which versions it applies to

This is the key switch for "any version, any time." Every test says which versions it
applies to — e.g. *"this check only applies from v8.2 onwards."*

- Testing an old version → checks for features that arrived **later** are **skipped as "Not
  Applicable"**, not failed.
- A check for something later removed → skipped on newer versions.

So the suite automatically shrinks to just the checks that make sense for the version in
front of it. **Green** = correct for what this version is. **Skipped** = not part of this
version yet. **Red** = a genuine problem. No fake reds.

### Layer C — Judge each version by its *own* rules, not today's

Wherever possible the suite reads the template's **own** values (its stages, its rules, its
document names) straight from the version being tested — rather than hard-coding today's.
Point it at the old version → it reads the *old* version's rules and measures against those.
**For L6 this is essential:** the app Claude builds must be graded against the rules that
shipped *with the version under test*, never against today's rules.

### Layer D — The clean guarantee: match the suite to the version

The most fool-proof option: the **test suite is versioned too**, tagged alongside each
template release. To test the 3-versions-old template, you run the test suite **as it was
when that version was current**. Now the tests and the template are from the *same era* —
zero gap, because the tests were literally written for that template. This is the fullest
meaning of "any version, any time": you move *both* pieces back together.

### How they combine (recommended)

- **Default to Layer D** (run the matching-era suite) for a true like-for-like run — least
  surprise.
- **Back it with A + B + C** so a *single* suite can still stretch across nearby versions
  honestly: the banner shows the gap, version-gating skips checks that don't apply, and
  each version is judged by its own rules.
- **L6 rule:** always grade against the rules of the version under test, and file the result
  under its version + the suite version used — so comparisons stay honest across time.

**In one line:** to test an old version, either move the suite back to that version too
(Layer D), or let a newer suite run against it while clearly labelling the gap (A), skipping
checks that didn't exist yet (B), and grading by that version's own rules (C) — so the gap
is always visible and never counted as a bug.

### One thing to decide

For Layers A/B/C to work, the suite needs to **read a version number** from somewhere. Pick
where it lives:

- a `VERSION` file inside the template, or
- the git tag the template was checked out at, or
- a field in one of the template's own JSON files.
