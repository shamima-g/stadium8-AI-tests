# Tier 3 — automated live test (get started)

This runs the **whole workflow with a real AI**, by itself, against an example app —
then times it, scores it, and writes up a report. No person needs to sit and watch.

New here? The full design is in **[PLAN.md](PLAN.md)**. This page is just the
quick start. For the **whole test-suite** (all three tiers) start at the
[suite README](../README.md).

---

## Before you start

You need the **Claude command-line tool installed and signed in**. Everything else
(Node, PowerShell bits, test tools, browsers) is installed for you the first time you
run — see "What setup installs" below.

---

## Run it

Open PowerShell 7 in this folder and run:

```powershell
# Simplest — default AI model (opus), default example app:
./Run-QATests.ps1 -IncludeTier3

# Choose the AI model:
./Run-QATests.ps1 -IncludeTier3 -Tier3Model sonnet

# Choose which example app to build:
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions
```

It runs in the background — you get your machine back while it works. If the PC is
switched off partway, just run the same command again and it carries on from where it
stopped.

---

## Where the results go

Everything is kept **separated per example app**, newest run at the top:

```
TestResults/<app>/
├── index.md              the list of runs (last 10 per AI model)
├── tier3-metrics.html    charts — open in a browser
└── <model>/<time>/       one run: the report, the timing, and a zip of the built app
```

The app the AI built is left on disk **outside the test suite**, under
`C:\temp\tier3-builds\<app>\<model>\<time>\` (overridable with `-BuildRoot`), so you
can open and run it. A zipped snapshot is also kept in the run's results folder above.

---

## Handy options

| Option | What it does |
|---|---|
| `-IncludeTier3` | Turn the live AI run on (off by default). |
| `-Tier3Model <name>` | Pick the AI model (e.g. `opus`, `sonnet`). Default: `opus`. |
| `-Benchmark <name>` | Pick which example app to build. Default: the only one there. |
| `-BuildRoot <path>` | Where the app is built. Default: `C:\temp\tier3-builds` (outside the suite). |
| `-KeepDeps` | Keep the app instantly runnable (don't strip `node_modules`). |
| `-NoTeardown` | Clean up nothing — leave everything exactly as it was. |
| `-Cleanup` | Clean up the most — remove the working folder (the zip is still kept). |

Drop a file named **`PAUSE`** into a run's `tier3-live/` folder to freeze its clock;
delete it to carry on.

---

## What setup installs (first run)

Setup checks what's already on your machine and installs only what's missing — the
test tools, the app's parts, the PowerShell test module, and the click-through
browsers. If something essential can't be installed on its own, it stops and tells you
in plain English what to install. It never changes your sign-ins.

---

## The score never fails the run

The AI's work is scored and written into the report and history, but a poor score
**never** turns the run red — it's recorded for you to read, not used as a gate.
