# Why the runs interleave — `A B B A` counterbalancing

You compare arms by running each one several times. But conditions **drift** over a long batch — so
the *order* you run them in can fake a result. This is the trap the runner avoids, and how.

The runner interleaves by default; `-NoInterleave` turns it off. See the schedule logic in
[`Run-Experiment.ps1`](Run-Experiment.ps1) → `Get-ExperimentSchedule`.

---

## 1. The setup — conditions don't hold still

Over a batch that lasts hours, the machine warms up, the model's servers get busier in the afternoon,
background apps wake. Early runs happen under **fresh, fast** conditions; later ones under **slower**
ones. Nothing about your arms changed — the *environment* did.

```
 fast ────────────────────────────────────────────► slow
 start of batch                              end of batch
 (this drift sits underneath every diagram below)
```

---

## 2. The trap — clumps bake drift into one arm

The obvious way: all of **A** (build), then all of **B** (plan). But look where each arm lands on the
drift — every A runs while things are fast, every B while things are slow.

```
 fast ──────────────────────────────────────────► slow

   A   A   A   A   A   │   B   B   B   B   B
  └──── fast zone ─────┘   └──── slow zone ─────┘
```

**B comes out looking slower** — but you can't tell if `plan` is genuinely slower, or if it just *ran
at a slower time*. Two causes are mixed into one number. That mixing has a name: **confounding**.

---

## 3. The fix — interleave, and drift hits both arms equally

Alternate the arms so each is spread evenly across the whole batch. Now A and B each get some fast runs
and some slow runs. Whatever the drift does, it does to **both** — so it cancels out, and what's left
in the difference is the real arm-vs-arm effect.

```
 fast ──────────────────────────────────────────► slow

   A   B   B   A   A   B   B   A   A   B
   ↑   ↑           ↑           ↑       ↑
   both colours appear in the fast zone AND the slow zone
```

This is **counterbalancing**.

---

## 4. The detail — why `A B B A`, not `A B A B`?

Simple alternation still has a subtle bias: in `A B A B`, **A always runs in the slot right before B**.
If there's any "second slot of a pair runs a touch slower" effect, it lands on B every single time.

```
 A B A B  — A always leads:        A B · B A — order flips each cycle:

  [A]lead [B]                       [A]lead [B]
  [A]lead [B]                       [B]lead [A]   ◄ reversed
  [A]lead [B]                       [A]lead [B]
```

Reversing every other cycle means sometimes A leads, sometimes B does. Now even the **ordering effect**
is balanced out — not just the slow-drift-over-time one.

---

## 5. Your run — three arms, five cycles

With `-Arms build,plan,concurrent -Runs 5`, the runner applies the same rule to three arms: keep the
order on even cycles, reverse it on odd ones. The exact 15-run sequence:

```
 Cycle 1  (forward)    1 build    2 plan     3 conc
 Cycle 2  (reversed ⇄) 4 conc     5 plan     6 build
 Cycle 3  (forward)    7 build    8 plan     9 conc
 Cycle 4  (reversed ⇄) 10 conc    11 plan    12 build
 Cycle 5  (forward)    13 build   14 plan    15 conc
```

Every arm is scattered through the batch instead of clumped — run 1 and run 15 are far apart, but
`build`, `plan`, and `concurrent` each show up early, middle, and late.

> **Notice:** `plan` is run **2** — it starts the moment run 1 (`build`) finishes. A mid-batch peek at
> run 1 won't show `plan` yet: it's *next*, not missing.

---

## 6. The escape hatch — `-NoInterleave`

Passing `-NoInterleave` runs the arms in strict clumps (all of A, then all of B) — the trap from §2.
Only useful when you specifically want that ordering. Interleaving is the default precisely because it
gives the cleaner, drift-proof comparison.
