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

## Two decisions needed before building

1. **When dev and release look different, should the tests go RED (fail), or just quietly
   note the difference in the report?**
   *(Fail = louder, forces attention. Note = calmer, you read it yourself.)*

2. **Should there be one "expected recipe" (release's) and let dev show up as "different"?
   Or keep two separate recipes, one for each?**
   *(One recipe = less to maintain and you get the dev-vs-release difference for free.
   Two recipes = cleaner but more upkeep.)*
