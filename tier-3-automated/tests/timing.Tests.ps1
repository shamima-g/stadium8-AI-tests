<#
  Pester tests for timing.ps1 — the Tier 3 stopwatch.

  Every behaviour is proven with a good case AND a broken/edge case, using an
  injected fake clock so nothing waits in real time. Each test works in its own
  temp folder and cleans up after itself.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'timing.ps1')

    # A per-test temp live folder + a controllable clock.
    function New-Fixture {
        param([double]$SleepThresholdSeconds = 120.0)
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-timing-" + [Guid]::NewGuid().ToString('N'))
        $script:FakeNow = 0.0
        $timer = New-Tier3Timer -LiveDir $dir -RunId 'run1' `
            -SleepThresholdSeconds $SleepThresholdSeconds `
            -Clock { $script:FakeNow } -WallClock { 'T' }
        return [pscustomobject]@{ Dir = $dir; Timer = $timer }
    }
    function Advance { param([double]$To) $script:FakeNow = $To }
}

Describe 'Active time — counts only moments work was happening' {
    It 'PASS: adds up active intervals across nested spans' {
        $f = New-Fixture
        $t = $f.Timer
        $t.Start('run', 'run')   | Out-Null   # now 0
        Advance 5
        $t.Start('opus', 'model')| Out-Null   # +5 active
        Advance 12
        $t.Stop() | Out-Null                  # model closes (+7 active)
        $t.Stop() | Out-Null                  # run closes (+0)
        $s = $t.Summary()
        $s.activeSeconds   | Should -Be 12
        $s.excludedSeconds | Should -Be 0
        Remove-Item $f.Dir -Recurse -Force
    }

    It 'FAIL-guard: a backwards clock adds nothing (never negative)' {
        $f = New-Fixture
        $t = $f.Timer
        $t.Start('run', 'run') | Out-Null
        Advance 10
        $t.Start('opus', 'model') | Out-Null  # +10 active
        Advance 3                              # clock went backwards
        $t.Update()
        $t.Stop() | Out-Null
        $t.Stop() | Out-Null
        $t.Summary().activeSeconds | Should -Be 10
        Remove-Item $f.Dir -Recurse -Force
    }
}

Describe 'Pause — a PAUSE file freezes the clock' {
    It 'PASS: time while PAUSE exists is excluded, not counted as active' {
        $f = New-Fixture
        $t = $f.Timer
        $t.Start('run', 'run') | Out-Null
        Advance 5
        $t.Start('opus', 'model') | Out-Null           # active = 5
        New-Item -ItemType File -Path (Join-Path $f.Dir 'PAUSE') -Force | Out-Null
        Advance 20
        $t.Update()                                    # +15 excluded (paused)
        Remove-Item (Join-Path $f.Dir 'PAUSE') -Force
        Advance 25
        $t.Update()                                    # +5 active
        $t.Stop() | Out-Null
        $t.Stop() | Out-Null
        $s = $t.Summary()
        $s.activeSeconds   | Should -Be 10
        $s.excludedSeconds | Should -Be 15
        Remove-Item $f.Dir -Recurse -Force
    }
}

Describe 'Sleep / shutdown gap — a big jump is excluded' {
    It 'PASS: a gap larger than the sleep threshold is excluded' {
        $f = New-Fixture -SleepThresholdSeconds 120
        $t = $f.Timer
        $t.Start('run', 'run') | Out-Null
        Advance 10
        $t.Start('opus', 'model') | Out-Null   # active = 10
        Advance 210                            # 200s jump > 120 threshold => asleep
        $t.Update()                            # +200 excluded
        Advance 215
        $t.Update()                            # +5 active
        $t.Stop() | Out-Null
        $t.Stop() | Out-Null
        $s = $t.Summary()
        $s.activeSeconds   | Should -Be 15
        $s.excludedSeconds | Should -Be 200
        Remove-Item $f.Dir -Recurse -Force
    }

    It 'FAIL-guard: a gap just under the threshold still counts as active' {
        $f = New-Fixture -SleepThresholdSeconds 120
        $t = $f.Timer
        $t.Start('run', 'run') | Out-Null
        Advance 100                            # 100s < 120 => active work, not a gap
        $t.Update()
        $t.Stop() | Out-Null
        $s = $t.Summary()
        $s.activeSeconds   | Should -Be 100
        $s.excludedSeconds | Should -Be 0
        Remove-Item $f.Dir -Recurse -Force
    }
}

Describe 'Nested span paths — start at the model level' {
    It 'PASS: path reads model/phase/turn (no run prefix)' {
        $f = New-Fixture
        $t = $f.Timer
        $t.Start('run', 'run')     | Out-Null
        $t.Start('opus', 'model')  | Out-Null
        $t.Start('build', 'phase') | Out-Null
        $turn = $t.Start('turn-7', 'turn')
        $turn.Path | Should -Be 'opus/build/turn-7'
        $t.Stop() | Out-Null; $t.Stop() | Out-Null; $t.Stop() | Out-Null; $t.Stop() | Out-Null
        Remove-Item $f.Dir -Recurse -Force
    }
}

Describe 'Claude time — rolls up to the parents' {
    It 'PASS: turn times sum into their phase, model, and run' {
        $f = New-Fixture
        $t = $f.Timer
        $t.Start('run', 'run')     | Out-Null
        $t.Start('opus', 'model')  | Out-Null
        $t.Start('build', 'phase') | Out-Null
        $t.Start('turn-1', 'turn') | Out-Null
        $t.Stop(3.0) | Out-Null                # turn 1: 3s Claude
        $t.Start('turn-2', 'turn') | Out-Null
        $t.Stop(2.0) | Out-Null                # turn 2: 2s Claude
        $phase = $t.Stop()                     # phase closes: 5s
        $phase.ClaudeSeconds | Should -Be 5
        $t.Stop() | Out-Null                   # model: 5s
        $run = $t.Stop()                       # run: 5s
        $run.ClaudeSeconds | Should -Be 5
        $s = $t.Summary()
        $s.claudeSeconds | Should -Be 5
        ($s.phases | Where-Object { $_.path -eq 'opus/build' }).claudeSeconds | Should -Be 5
        Remove-Item $f.Dir -Recurse -Force
    }
}

Describe 'Crash-safe — each finished span is written the moment it ends' {
    It 'PASS: a stopped span is on disk; an open span is not yet written' {
        $f = New-Fixture
        $t = $f.Timer
        $jsonl = Join-Path $f.Dir 'run1.jsonl'
        $t.Start('run', 'run')    | Out-Null
        $t.Start('opus', 'model') | Out-Null   # still open
        Test-Path $jsonl | Should -BeFalse      # nothing finished yet
        $t.Start('build', 'phase') | Out-Null
        $t.Start('turn-1', 'turn') | Out-Null
        $t.Stop(1.5) | Out-Null                 # turn-1 finished -> one line
        @(Get-Content $jsonl).Count | Should -Be 1
        $row = Get-Content $jsonl | ConvertFrom-Json
        $row.path          | Should -Be 'opus/build/turn-1'
        $row.claudeSeconds | Should -Be 1.5
        $row.level         | Should -Be 'turn'
        # the still-open model/phase/run spans are NOT written yet
        @(Get-Content $jsonl | Where-Object { $_ -match '"level":"run"' }).Count | Should -Be 0
        $t.Stop() | Out-Null; $t.Stop() | Out-Null; $t.Stop() | Out-Null
        @(Get-Content $jsonl).Count | Should -Be 4    # turn, phase, model, run
        Remove-Item $f.Dir -Recurse -Force
    }
}

Describe 'Workflow-phase guess — from what the turn touched' {
    It 'PASS: a YAML spec under documentation/ => spec' {
        Get-WorkflowPhaseGuess -Touched @('documentation/transactions-api.yaml') -PreviousPhase 'green' | Should -Be 'spec'
    }
    It 'PASS: a generated-docs/specs YAML => spec' {
        Get-WorkflowPhaseGuess -Touched @('generated-docs/specs/api-spec.yaml') | Should -Be 'spec'
    }
    It 'PASS: a test file => red (failing test)' {
        Get-WorkflowPhaseGuess -Touched @('web/src/app/tasks/page.test.tsx') | Should -Be 'red'
    }
    It 'PASS: app code under web/src => green' {
        Get-WorkflowPhaseGuess -Touched @('web/src/app/tasks/page.tsx') | Should -Be 'green'
    }
    It 'PASS: a git commit => save' {
        Get-WorkflowPhaseGuess -Touched @('git commit -m "story 1"') | Should -Be 'save'
    }
    It 'PASS: no signal keeps the previous phase' {
        Get-WorkflowPhaseGuess -Touched @('README.md') -PreviousPhase 'green' | Should -Be 'green'
    }
    It 'FAIL-guard: a test file wins over plain web/src code (red beats green)' {
        Get-WorkflowPhaseGuess -Touched @('web/src/app/page.tsx', 'web/src/app/page.test.tsx') | Should -Be 'red'
    }
}
