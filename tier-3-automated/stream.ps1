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
    # B1 — the tool/AUQ/text timeline a post-run scorer re-parses for the silence check + judge.
    $asks = [System.Collections.Generic.List[hashtable]]::new()
    $texts = [System.Collections.Generic.List[hashtable]]::new()

    if (-not (Test-Path $Path)) { return @{ turns = @(); totalTokens = 0; claudeSeconds = 0.0; numTurns = 0; asks = @(); texts = @() } }

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
            $tools = [System.Collections.Generic.List[hashtable]]::new()
            $turnIndex = $turns.Count + 1
            foreach ($block in @(Get-JsonProp $msg 'content' @())) {
                $btype = Get-JsonProp $block 'type'
                if ($btype -eq 'text') {
                    $txt = Get-JsonProp $block 'text'
                    if ($txt) { $texts.Add(@{ turn = $turnIndex; text = [string]$txt }) }
                    continue
                }
                if ($btype -ne 'tool_use') { continue }
                $name = [string](Get-JsonProp $block 'name')
                $input = Get-JsonProp $block 'input'
                $tools.Add(@{ name = $name; input = $input })
                if ($name -eq 'AskUserQuestion') { $asks.Add(@{ turn = $turnIndex; input = $input }) }
                $fp = Get-JsonProp $input 'file_path'
                if ($fp) { $touched.Add([string]$fp) }
                $cmd = Get-JsonProp $input 'command'
                if ($cmd) { $touched.Add([string]$cmd) }
            }
            $turns.Add(@{ index = $turnIndex; inputTokens = $inTok; outputTokens = $outTok; touched = @($touched); tools = @($tools) })
            $totalTokens += ($inTok + $outTok)
        }
        elseif ($type -eq 'result') {
            # A run emits MANY result events (one per Claude sub-invocation), each with its
            # own duration/turns — SUM them for the run total; overwriting would keep only
            # the last sub-call. (Tokens stay the per-turn tally above, authoritative here;
            # result usage is only a cross-check.)
            $ms = Get-JsonProp $evt 'duration_ms'
            if ($null -eq $ms) { $ms = Get-JsonProp $evt 'duration_api_ms' }   # tolerate the api-only field
            if ($null -ne $ms) { $claudeSeconds += [double]$ms / 1000.0 }
            $nt = Get-JsonProp $evt 'num_turns'
            if ($null -ne $nt) { $numTurns += [int]$nt }
        }
    }

    if ($numTurns -eq 0) { $numTurns = $turns.Count }
    return @{ turns = @($turns); totalTokens = $totalTokens; claudeSeconds = $claudeSeconds; numTurns = $numTurns; asks = @($asks); texts = @($texts) }
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
