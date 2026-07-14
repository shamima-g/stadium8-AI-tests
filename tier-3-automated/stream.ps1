<#
.SYNOPSIS
  stream.ps1 — turn the Claude command-line tool's stream-json output into timed turns.

.DESCRIPTION
  The live driver (Part 2) runs the Claude tool with stream-json output and captures the
  event lines. This module reads those lines and:
    * ConvertFrom-ClaudeStream  — normalise them into per-turn facts (tokens, the files
      each turn touched, and totals from the final result event).
    * Invoke-TimerFromStream    — drive the stopwatch (timing.ps1) from those turns:
      one turn span each, grouped under a guessed workflow-phase, under a driver phase,
      under the model, under the run. Claude's reported total time is shared across the
      turns in proportion to how much each wrote (output tokens).

  Tolerant by design — unknown event types and missing fields are skipped, not fatal, so
  a small change in the tool's output doesn't break the run. Tested against a sample
  stream; no live AI needed here.
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'timing.ps1')

function Get-JsonProp {
    param($Object, [string]$Name, $Default = $null)
    if ($Object -and ($Object.PSObject.Properties.Name -contains $Name)) { return $Object.$Name }
    return $Default
}

# Read a stream-json file into normalised per-turn facts + run totals.
function ConvertFrom-ClaudeStream {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $turns = [System.Collections.Generic.List[hashtable]]::new()
    $totalTokens = 0
    $claudeSeconds = 0.0
    $numTurns = 0

    if (-not (Test-Path $Path)) { return @{ turns = @(); totalTokens = 0; claudeSeconds = 0.0; numTurns = 0 } }

    foreach ($line in Get-Content -Path $Path -Encoding utf8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $evt = $null
        try { $evt = $line | ConvertFrom-Json } catch { continue }   # skip non-JSON lines
        $type = Get-JsonProp $evt 'type'

        if ($type -eq 'assistant') {
            $msg = Get-JsonProp $evt 'message'
            $usage = Get-JsonProp $msg 'usage'
            $inTok = [int](Get-JsonProp $usage 'input_tokens' 0)
            $outTok = [int](Get-JsonProp $usage 'output_tokens' 0)
            $touched = [System.Collections.Generic.List[string]]::new()
            foreach ($block in @(Get-JsonProp $msg 'content' @())) {
                if ((Get-JsonProp $block 'type') -ne 'tool_use') { continue }
                $input = Get-JsonProp $block 'input'
                $fp = Get-JsonProp $input 'file_path'
                if ($fp) { $touched.Add([string]$fp) }
                $cmd = Get-JsonProp $input 'command'
                if ($cmd) { $touched.Add([string]$cmd) }
            }
            $turns.Add(@{ index = $turns.Count + 1; inputTokens = $inTok; outputTokens = $outTok; touched = @($touched) })
            $totalTokens += ($inTok + $outTok)
        }
        elseif ($type -eq 'result') {
            $ms = Get-JsonProp $evt 'duration_ms'
            if ($null -ne $ms) { $claudeSeconds = [double]$ms / 1000.0 }
            $nt = Get-JsonProp $evt 'num_turns'
            if ($null -ne $nt) { $numTurns = [int]$nt }
            $ru = Get-JsonProp $evt 'usage'
            $rt = Get-JsonProp $ru 'output_tokens'
            # (result usage is a cross-check; per-turn tally above is authoritative here)
        }
    }

    if ($numTurns -eq 0) { $numTurns = $turns.Count }
    return @{ turns = @($turns); totalTokens = $totalTokens; claudeSeconds = $claudeSeconds; numTurns = $numTurns }
}

# Drive the stopwatch from parsed turns. Builds run > model > phase > wphase > turn, and
# shares Claude's total reported time across turns by output-token weight.
function Invoke-TimerFromStream {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Timer,
        [Parameter(Mandatory)][hashtable]$Parsed,
        [Parameter(Mandatory)][string]$Model,
        [string]$PhaseName = 'build'
    )
    $turns = @($Parsed.turns)
    $sumOut = (($turns | ForEach-Object { [double]$_.outputTokens }) | Measure-Object -Sum).Sum
    if ($null -eq $sumOut) { $sumOut = 0 }
    $total = [double]$Parsed.claudeSeconds

    $Timer.Start('run', 'run')     | Out-Null
    $Timer.Start($Model, 'model')  | Out-Null
    $Timer.Start($PhaseName, 'phase') | Out-Null

    $currentPhase = $null
    $prevGuess = 'spec'
    foreach ($t in $turns) {
        $guess = Get-WorkflowPhaseGuess -Touched @($t.touched) -PreviousPhase $prevGuess
        $prevGuess = $guess
        if ($guess -ne $currentPhase) {
            if ($null -ne $currentPhase) { $Timer.Stop() | Out-Null }   # close previous wphase
            $Timer.Start($guess, 'wphase') | Out-Null
            $currentPhase = $guess
        }
        $claudeSecs = if ($sumOut -gt 0) { $total * ([double]$t.outputTokens / $sumOut) } elseif ($turns.Count -gt 0) { $total / $turns.Count } else { 0.0 }
        $Timer.Start("turn-$($t.index)", 'turn') | Out-Null
        $Timer.Stop($claudeSecs) | Out-Null
    }
    if ($null -ne $currentPhase) { $Timer.Stop() | Out-Null }  # close last wphase
    $Timer.Stop() | Out-Null   # phase
    $Timer.Stop() | Out-Null   # model
    $Timer.Stop() | Out-Null   # run

    return $Timer.Summary()
}
