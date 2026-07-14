<#
.SYNOPSIS
  timing.ps1 — the Tier 3 stopwatch. Records how long the AI's work takes at every
  level, safely across pause and shutdown.

.DESCRIPTION
  Records nested spans: run > model > phase > workflow-phase (a guess) > turn.

  Two clocks:
    * Active time  — the timer's own count of moments work was actually happening.
    * Claude time  — what Claude reports it spent (passed in per turn); the number to
                     trust for "how much work". Rolled up to parents automatically.

  Honest about gaps. Active time is the SUM of intervals that were actually active —
  never "end minus start" — so paused / asleep / shut-down time can't sneak in. Time is
  excluded when either:
    * a PAUSE file exists in the live folder, or
    * the gap since the last update is larger than SleepThresholdSeconds (a sleep or a
      shutdown gap).
  Excluded time is tracked separately and never mixed into the active total.

  Crash-safe. Every span is appended to <LiveDir>/<RunId>.jsonl the moment it ends, so a
  shutdown keeps every finished span — only the one in-progress span is lost.

  The wall clock used for the active/excluded maths is injectable (the -Clock scriptblock
  returns seconds as a double), so the behaviour is fully testable without waiting in
  real time.

.NOTES
  Part 1 of the automated Tier 3 (see PLAN.md). No live AI involved.
#>

Set-StrictMode -Version Latest

# One recorded span. Kept small and JSON-friendly.
class Tier3Span {
    [string]$Name
    [string]$Level          # run | model | phase | wphase | turn
    [string]$Path           # e.g. opus/build/turn-7
    [string]$WallStart      # ISO-8601 wall-clock timestamp
    [string]$WallEnd
    [double]$ActiveStart    # value of the active clock when the span opened
    [double]$ActiveEnd
    [double]$ClaudeSeconds  # Claude's own time (turns intrinsic; parents rolled up)
    [bool]$Closed

    [double] ActiveSeconds() { return [Math]::Max(0.0, $this.ActiveEnd - $this.ActiveStart) }
}

class Tier3Timer {
    [string]$LiveDir
    [string]$RunId
    [string]$JsonlPath
    [string]$PauseFile
    [double]$SleepThresholdSeconds
    [scriptblock]$Clock         # returns current wall time in seconds (double)
    [scriptblock]$WallClock     # returns an ISO timestamp string

    hidden [double]$LastTick
    hidden [double]$ActiveAccum
    hidden [double]$ExcludedAccum
    hidden [System.Collections.Generic.List[Tier3Span]]$Stack
    hidden [System.Collections.Generic.List[Tier3Span]]$Completed

    Tier3Timer([hashtable]$opts) {
        if (-not $opts.ContainsKey('LiveDir')) { throw "Tier3Timer requires 'LiveDir'." }
        if (-not $opts.ContainsKey('RunId'))   { throw "Tier3Timer requires 'RunId'." }

        $this.LiveDir   = $opts.LiveDir
        $this.RunId     = $opts.RunId
        $this.JsonlPath = Join-Path $this.LiveDir ("{0}.jsonl" -f $this.RunId)
        $this.PauseFile = Join-Path $this.LiveDir 'PAUSE'
        $this.SleepThresholdSeconds = if ($opts.ContainsKey('SleepThresholdSeconds')) { [double]$opts.SleepThresholdSeconds } else { 120.0 }
        $this.Clock     = if ($opts.ContainsKey('Clock')) { $opts.Clock } else { { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0 } }
        $this.WallClock = if ($opts.ContainsKey('WallClock')) { $opts.WallClock } else { { (Get-Date).ToUniversalTime().ToString('o') } }

        $this.Stack     = [System.Collections.Generic.List[Tier3Span]]::new()
        $this.Completed = [System.Collections.Generic.List[Tier3Span]]::new()

        if (-not (Test-Path $this.LiveDir)) { New-Item -ItemType Directory -Path $this.LiveDir -Force | Out-Null }

        $this.LastTick     = [double](& $this.Clock)
        $this.ActiveAccum  = 0.0
        $this.ExcludedAccum = 0.0
    }

    [double] Now() { return [double](& $this.Clock) }

    # True when the clock is currently frozen by a PAUSE file.
    [bool] IsPaused() { return (Test-Path $this.PauseFile) }

    # The running active / excluded totals so far (for mid-run progress snapshots).
    [double] CurrentActiveSeconds() { return [Math]::Round($this.ActiveAccum, 4) }
    [double] CurrentExcludedSeconds() { return [Math]::Round($this.ExcludedAccum, 4) }

    # Advance the active/excluded accumulators by the time since the last update.
    # Called at every span boundary, and can be called as a heartbeat during long waits.
    [void] Update() {
        $now = $this.Now()
        $delta = $now - $this.LastTick
        $this.LastTick = $now
        if ($delta -le 0) { return }   # clock didn't move (or went backwards) — count nothing

        if ($this.IsPaused() -or ($delta -gt $this.SleepThresholdSeconds)) {
            $this.ExcludedAccum += $delta            # paused, asleep, or a shutdown gap
        }
        else {
            $this.ActiveAccum += $delta              # real, active work
        }
    }

    # Open a nested span. Returns it (mostly for tests); Stop() closes the innermost.
    [Tier3Span] Start([string]$name, [string]$level) {
        $this.Update()
        # Paths start at the model level (e.g. opus/build/turn-7), so the run span
        # doesn't prefix its children — it's the whole-run total, not a path segment.
        $parent = if ($this.Stack.Count -gt 0) { $this.Stack[$this.Stack.Count - 1] } else { $null }
        $prefix = if ($null -eq $parent -or $parent.Level -eq 'run') { '' } else { $parent.Path }
        $span = [Tier3Span]::new()
        $span.Name        = $name
        $span.Level       = $level
        $span.Path        = if ($prefix) { "$prefix/$name" } else { $name }
        $span.WallStart   = [string](& $this.WallClock)
        $span.ActiveStart = $this.ActiveAccum
        $span.ClaudeSeconds = 0.0
        $span.Closed      = $false
        $this.Stack.Add($span)
        return $span
    }

    # Close the innermost span, roll its Claude time up to the parent, and persist it.
    [Tier3Span] Stop([double]$claudeSeconds) {
        $this.Update()
        if ($this.Stack.Count -eq 0) { throw "Tier3Timer.Stop() called with no open span." }
        $span = $this.Stack[$this.Stack.Count - 1]
        $this.Stack.RemoveAt($this.Stack.Count - 1)

        $span.ActiveEnd     = $this.ActiveAccum
        $span.WallEnd       = [string](& $this.WallClock)
        $span.ClaudeSeconds += $claudeSeconds
        $span.Closed        = $true

        # Roll this span's Claude time up to its (now-innermost) parent, once.
        if ($this.Stack.Count -gt 0) {
            $this.Stack[$this.Stack.Count - 1].ClaudeSeconds += $span.ClaudeSeconds
        }

        $this.WriteSpan($span)
        $this.Completed.Add($span)
        return $span
    }

    [Tier3Span] Stop() { return $this.Stop(0.0) }

    # Append one span as a JSON line — the crash-safe record.
    hidden [void] WriteSpan([Tier3Span]$span) {
        $row = [ordered]@{
            runId         = $this.RunId
            name          = $span.Name
            level         = $span.Level
            path          = $span.Path
            wallStart     = $span.WallStart
            wallEnd       = $span.WallEnd
            activeSeconds = [Math]::Round($span.ActiveSeconds(), 4)
            claudeSeconds = [Math]::Round($span.ClaudeSeconds, 4)
        }
        $line = ($row | ConvertTo-Json -Compress -Depth 5)
        # Append atomically-ish; a single line write is what keeps a shutdown safe.
        Add-Content -Path $this.JsonlPath -Value $line -Encoding utf8
    }

    # Totals + a per-phase table, for the end-of-run report.
    [hashtable] Summary() {
        $phases = @(
            $this.Completed |
                Where-Object { $_.Level -eq 'phase' } |
                ForEach-Object {
                    [ordered]@{
                        path          = $_.Path
                        activeSeconds = [Math]::Round($_.ActiveSeconds(), 4)
                        claudeSeconds = [Math]::Round($_.ClaudeSeconds, 4)
                    }
                }
        )
        $runClaude = (($this.Completed | Where-Object { $_.Level -eq 'run' } | ForEach-Object { $_.ClaudeSeconds }) | Measure-Object -Sum).Sum
        if ($null -eq $runClaude) { $runClaude = 0.0 }
        # All completed spans (path/level/active/claude) — lets a caller build a richer
        # per-phase view (e.g. distribute Claude time across workflow-phase spans).
        $allSpans = @(
            $this.Completed | ForEach-Object {
                [ordered]@{ path = $_.Path; level = $_.Level; activeSeconds = [Math]::Round($_.ActiveSeconds(), 4); claudeSeconds = [Math]::Round($_.ClaudeSeconds, 4) }
            }
        )
        return @{
            runId           = $this.RunId
            activeSeconds   = [Math]::Round($this.ActiveAccum, 4)
            excludedSeconds = [Math]::Round($this.ExcludedAccum, 4)
            claudeSeconds   = [Math]::Round([double]$runClaude, 4)
            phases          = $phases
            spans           = $allSpans
            openSpans       = $this.Stack.Count
        }
    }
}

# Factory so callers don't touch the class syntax directly.
function New-Tier3Timer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiveDir,
        [Parameter(Mandatory)][string]$RunId,
        [double]$SleepThresholdSeconds = 120.0,
        [scriptblock]$Clock,
        [scriptblock]$WallClock
    )
    $opts = @{ LiveDir = $LiveDir; RunId = $RunId; SleepThresholdSeconds = $SleepThresholdSeconds }
    if ($PSBoundParameters.ContainsKey('Clock'))     { $opts.Clock = $Clock }
    if ($PSBoundParameters.ContainsKey('WallClock')) { $opts.WallClock = $WallClock }
    return [Tier3Timer]::new($opts)
}

# Guess the workflow phase of a turn from what it touched. Approximate by design — the
# per-turn and per-phase *times* are exact; only this label is a guess. Adapted to this
# stack (Next.js / Vitest / Playwright): specs are YAML under documentation/ or
# generated-docs/specs; failing tests are *.test.* / *.spec.*; code is web/src; a commit
# is a save. No signal ⇒ keep the previous phase.
function Get-WorkflowPhaseGuess {
    [CmdletBinding()]
    param(
        [string[]]$Touched = @(),   # file paths written/edited, plus tokens like 'git commit'
        [string]$PreviousPhase = 'spec'
    )
    $t = @($Touched | ForEach-Object { "$_".Replace('\', '/').ToLowerInvariant() })

    if ($t | Where-Object { $_ -match 'git commit' }) { return 'save' }
    if ($t | Where-Object { $_ -match '\.(test|spec)\.[jt]sx?$' }) { return 'red' }
    if ($t | Where-Object { $_ -match '(^|/)(documentation|generated-docs/specs)/.*\.ya?ml$' }) { return 'spec' }
    if ($t | Where-Object { $_ -match '(^|/)web/src/' }) { return 'green' }
    return $PreviousPhase
}
