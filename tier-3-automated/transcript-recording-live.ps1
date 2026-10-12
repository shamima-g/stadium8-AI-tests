<#
.SYNOPSIS
  LIVE, record-only checks for session recording that determinism can't prove (spends tokens / needs sign-in).

.DESCRIPTION
  The deterministic acceptance net is tier-1-unit/transcript-sync (notice hook, headless & dev-repo
  suppression, committed id + clone-same-id, /status line, send-gate). Two things need a real Claude Code:

    -Phase headless  (LIVE, spends): scaffold a FRESH project that has never had an interactive session, run
                     `claude -p "hello"`, and assert NO transcript-collection.json appears at its root. This is
                     the only way to prove a real `claude -p` sets a CLAUDE_CODE_ENTRYPOINT the hook treats as
                     headless (the unit test sets that env by hand). Record-only: it prints PASS/FAIL, never
                     gates a suite.

    -Phase notice    (MANUAL): prints the human walkthrough for "the notice appears UNDER the first message"
                     (criterion 1) — a person opens the project in VS Code, sends a first message, and confirms
                     the SESSION RECORDING notice renders under it and the help link resolves. The template's
                     logic is already covered by the unit tests; only the VS Code rendering is human-confirmed.

  PORTABILITY: no hard-coded machine paths (roots are parameters / derived). SPEND SAFETY: nothing signs in or
  spends unless -Phase headless is named, and it prints a sign-in + cost notice first.

.PARAMETER TemplateRoot
  A checkout that HAS the feature (.claude/hooks/transcript-sync-hook.js). The reference build is the archive
  the plan was written against.

.PARAMETER Phase
  dryrun (default, no spend) | headless (LIVE) | notice (manual walkthrough text).

.EXAMPLE
  pwsh -File transcript-recording-live.ps1 -TemplateRoot C:\path\to\checkout -Phase headless
#>
param(
  [Parameter(Mandatory)][string]$TemplateRoot,
  [ValidateSet('dryrun','headless','notice')][string]$Phase = 'dryrun',
  [string]$RepoRoot  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$WorkRoot  = ([System.IO.Path]::GetTempPath()),
  [string]$Benchmark = 'minimal-concurrent',
  [string]$Model     = 'opus',
  [int]$TimeoutSeconds = 300
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'live-driver.ps1')   # New-Tier3Scaffold, Stop-ProcessTree

function Say([string]$m) { Write-Output $m }

function Do-Headless {
  if (-not (Test-Path (Join-Path $TemplateRoot '.claude/hooks/transcript-sync-hook.js'))) {
    throw "TemplateRoot $TemplateRoot has no transcript-sync-hook.js — point it at a checkout with the feature."
  }
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Say "SKIP: the 'claude' CLI is not on PATH — cannot run the live headless check here."
    return
  }
  $work = Join-Path $WorkRoot 'tsync-headless-run'
  if (Test-Path $work) { Remove-Item $work -Recurse -Force }
  $bench = Join-Path $RepoRoot "benchmark-files/$Benchmark"
  New-Tier3Scaffold -TemplateRoot $TemplateRoot -WorkingDir $work -BenchmarkDir $bench | Out-Null

  # CRITICAL: the scaffold copies the template's .release-ignore, which would make the hook suppress via the
  # DEV-REPO path and never exercise headless detection — a guaranteed false PASS. Strip it so this is a real
  # end-user project where ONLY the headless gate can suppress.
  Remove-Item (Join-Path $work '.release-ignore') -Force -ErrorAction SilentlyContinue
  $collection = Join-Path $work 'transcript-collection.json'
  if (Test-Path $collection) { Remove-Item $collection -Force }

  Say "─────────────────────────────────────────────────────────────"
  Say "LIVE STEP 'headless': runs ``claude -p ""hello""`` — uses the signed-in Claude CLI and SPENDS tokens."
  Say "  workdir=$work"
  Say "─────────────────────────────────────────────────────────────"
  # Point the receiver at a DEAD host: a configured receiver is required for minting to even be attempted, but
  # if headless detection regressed, a broken run would try to contact this dead host rather than exfiltrate the
  # 'hello' transcript to the real Azure receiver.
  $env:STADIUM_RECEIVER_URL = 'https://receiver.invalid'
  $out = Join-Path $WorkRoot 'tsync-headless.out'
  $err = "$out.err"
  # Launch via cmd.exe, as live-driver.ps1 does: Start-Process can't launch a .cmd shim directly, and its
  # RedirectStandardOutput does not receive claude.exe's stream.
  $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/s','/c',"claude -p hello > `"$out`" 2> `"$err`"" `
    -WorkingDirectory $work -NoNewWindow -PassThru
  if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
    Say "TIMEOUT after ${TimeoutSeconds}s — killing."; Stop-ProcessTree -ProcessId $proc.Id; return
  }

  # AC3: a headless run shows no notice and starts no sending → no identity file is minted at the root.
  if (Test-Path $collection) {
    Say "FAIL: transcript-collection.json appeared at the project root after ``claude -p`` — the real headless"
    Say "      entrypoint was NOT treated as headless. Inspect CLAUDE_CODE_ENTRYPOINT and looksHeadless()."
  } else {
    Say "PASS: no transcript-collection.json at the project root after ``claude -p ""hello""`` (headless records nothing)."
    Say "NOTE: for a positive control, an INTERACTIVE first message in the same scaffold DOES mint the file"
    Say "      (covered deterministically by tier-1-unit/transcript-sync/notice-hook.test.ts)."
  }
}

function Do-Notice {
  Say "MANUAL walkthrough — criterion 1 'the notice appears under the first message' (no spend here):"
  Say "  1. Open a FRESH project built from the template in Claude Code (VS Code), with no earlier sessions."
  Say "  2. Send any first message."
  Say "  3. Confirm a notice starting 'SESSION RECORDING' appears UNDER your message."
  Say "  4. Open .template-docs/users/Help/Session-Recording.md — confirm it lists what is recorded and who can read it."
  Say "  5. Close the session completely; open a NEW session; send a message; confirm the notice appears again."
  Say "Record the verdict with the capture (the template's logic is already covered by tier-1-unit/transcript-sync)."
}

switch ($Phase) {
  'headless' { Do-Headless }
  'notice'   { Do-Notice }
  default {
    Say "DRY RUN (no spend)."
    Say "  -Phase headless  LIVE: scaffold a fresh project, run `claude -p \"hello\"`, assert no transcript-collection.json at root."
    Say "  -Phase notice    MANUAL: print the 'notice under the first message' walkthrough."
    Say ""
    Say "Deterministic coverage (no spend): npm run test:tier1 -- tier-1-unit/transcript-sync   (REPO_ROOT=<feature checkout>)"
    Say "Template: $TemplateRoot"
  }
}
