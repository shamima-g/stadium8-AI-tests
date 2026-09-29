<#
  Pester tests for stream.ps1 — parsing the Claude stream + driving the stopwatch.
  Uses a sample stream-json file (no live AI).
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'stream.ps1')
    . (Join-Path $PSScriptRoot '..' 'timing.ps1')

    function New-SampleStream {
        # A tiny but realistic run: write a spec (yaml), a failing test, code, then commit.
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-stream-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $path = Join-Path $dir 'stream.jsonl'
        $lines = @(
            '{"type":"system","subtype":"init"}',
            '{"type":"assistant","message":{"usage":{"input_tokens":100,"output_tokens":40},"content":[{"type":"tool_use","name":"Write","input":{"file_path":"documentation/transactions-api.yaml","content":"x"}}]}}',
            '{"type":"user","message":{"content":[{"type":"tool_result","content":"ok"}]}}',
            '{"type":"assistant","message":{"usage":{"input_tokens":120,"output_tokens":60},"content":[{"type":"tool_use","name":"Write","input":{"file_path":"web/src/app/tasks/page.test.tsx","content":"x"}}]}}',
            '{"type":"assistant","message":{"usage":{"input_tokens":150,"output_tokens":100},"content":[{"type":"tool_use","name":"Write","input":{"file_path":"web/src/app/tasks/page.tsx","content":"x"}}]}}',
            '{"type":"assistant","message":{"usage":{"input_tokens":80,"output_tokens":20},"content":[{"type":"tool_use","name":"Bash","input":{"command":"git commit -m \"story 1\""}}]}}',
            'this is not json and must be skipped',
            '{"type":"result","subtype":"success","duration_ms":220000,"num_turns":4,"usage":{"output_tokens":220}}'
        )
        Set-Content -Path $path -Value $lines -Encoding utf8
        return [pscustomobject]@{ Dir = $dir; Path = $path }
    }
    function New-Timer {
        param($LiveDir)
        $script:FakeNow = 0.0
        return New-Tier3Timer -LiveDir $LiveDir -RunId 'r' -Clock { $script:FakeNow } -WallClock { 'T' }
    }
}

Describe 'ConvertFrom-ClaudeStream — normalise the events' {
    It 'PASS: counts turns, tallies tokens, reads the result total, skips junk' {
        $s = New-SampleStream
        $p = ConvertFrom-ClaudeStream -Path $s.Path
        @($p.turns).Count | Should -Be 4                 # 4 assistant turns (system/user/junk skipped)
        $p.claudeSeconds  | Should -Be 220               # 220000 ms
        $p.numTurns       | Should -Be 4
        $p.totalTokens    | Should -Be 670               # (100+40)+(120+60)+(150+100)+(80+20)
        Remove-Item $s.Dir -Recurse -Force
    }

    It 'PASS: B1 — captures per-turn tool names, AskUserQuestion asks, and assistant text' {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-stream-b1-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $path = Join-Path $dir 'stream.jsonl'
        Set-Content -Path $path -Encoding utf8 -Value @(
            '{"type":"assistant","message":{"usage":{"input_tokens":1,"output_tokens":1},"content":[{"type":"text","text":"Here is the plan. Approve?"},{"type":"tool_use","name":"AskUserQuestion","input":{"questions":[{"question":"Approve the plan?"}]}}]}}',
            '{"type":"assistant","message":{"usage":{"input_tokens":1,"output_tokens":1},"content":[{"type":"tool_use","name":"Bash","input":{"command":"git commit -m x"}}]}}',
            '{"type":"result","subtype":"success","duration_ms":1000,"num_turns":2}'
        )
        $p = ConvertFrom-ClaudeStream -Path $path
        @($p.asks).Count    | Should -Be 1
        @($p.asks)[0].turn  | Should -Be 1
        @($p.texts)[0].text | Should -Be 'Here is the plan. Approve?'
        (@($p.turns)[0].tools | ForEach-Object { $_.name }) | Should -Be 'AskUserQuestion'
        (@($p.turns)[1].tools | ForEach-Object { $_.name }) | Should -Be 'Bash'
        Remove-Item $dir -Recurse -Force
    }

    It 'PASS: B1 — a stream with no AUQ/text yields empty asks/texts (back-compat)' {
        $s = New-SampleStream
        $p = ConvertFrom-ClaudeStream -Path $s.Path
        @($p.asks).Count  | Should -Be 0
        @($p.texts).Count | Should -Be 0
        (@($p.turns)[3].tools | ForEach-Object { $_.name }) | Should -Be 'Bash'   # the git-commit turn
        Remove-Item $s.Dir -Recurse -Force
    }

    It 'PASS: captures the files/commands each turn touched' {
        $s = New-SampleStream
        $p = ConvertFrom-ClaudeStream -Path $s.Path
        @($p.turns)[0].touched | Should -Contain 'documentation/transactions-api.yaml'
        @($p.turns)[3].touched | Should -Contain 'git commit -m "story 1"'
        Remove-Item $s.Dir -Recurse -Force
    }

    It 'FAIL-guard: a missing stream file returns empty, not an error' {
        $p = ConvertFrom-ClaudeStream -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'no-such-stream.jsonl')
        @($p.turns).Count | Should -Be 0
    }

    It 'PASS: MANY result events SUM their duration + turns (not last-write-wins)' {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-stream-multi-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $path = Join-Path $dir 'stream.jsonl'
        Set-Content -Path $path -Encoding utf8 -Value @(
            '{"type":"assistant","message":{"usage":{"input_tokens":10,"output_tokens":5},"content":[]}}',
            '{"type":"result","subtype":"success","duration_ms":100000,"num_turns":2,"usage":{"output_tokens":50}}',
            '{"type":"result","subtype":"success","duration_ms":120000,"num_turns":3,"usage":{"output_tokens":60}}'
        )
        $p = ConvertFrom-ClaudeStream -Path $path
        $p.claudeSeconds | Should -Be 220        # 100000+120000 ms, summed (not just 120000)
        $p.numTurns      | Should -Be 5          # 2+3, summed
        Remove-Item $dir -Recurse -Force
    }
}

Describe 'Invoke-TimerFromStream — drive the stopwatch' {
    It 'PASS: builds turn spans grouped by guessed workflow-phase, and shares Claude time' {
        $s = New-SampleStream
        $t = New-Timer -LiveDir $s.Dir
        $p = ConvertFrom-ClaudeStream -Path $s.Path
        $summary = Invoke-TimerFromStream -Timer $t -Parsed $p -Model 'opus' -PhaseName 'build'

        # Claude total (220s) is shared across turns -> the run rolls up to ~220
        [Math]::Round($summary.claudeSeconds) | Should -Be 220
        # the four guessed phases appear as spans in the jsonl (spec, red, green, save)
        $jsonl = Join-Path $s.Dir 'r.jsonl'
        $levels = Get-Content $jsonl | ForEach-Object { ($_ | ConvertFrom-Json).path }
        @($levels | Where-Object { $_ -eq 'opus/build/spec' }).Count  | Should -BeGreaterThan 0
        @($levels | Where-Object { $_ -eq 'opus/build/red' }).Count   | Should -BeGreaterThan 0
        @($levels | Where-Object { $_ -eq 'opus/build/green' }).Count | Should -BeGreaterThan 0
        @($levels | Where-Object { $_ -eq 'opus/build/save' }).Count  | Should -BeGreaterThan 0
        Remove-Item $s.Dir -Recurse -Force
    }

    It 'PASS: the phase (build) rolls up all the Claude time' {
        $s = New-SampleStream
        $t = New-Timer -LiveDir $s.Dir
        $p = ConvertFrom-ClaudeStream -Path $s.Path
        $summary = Invoke-TimerFromStream -Timer $t -Parsed $p -Model 'opus' -PhaseName 'build'
        $buildPhase = $summary.phases | Where-Object { $_.path -eq 'opus/build' }
        [Math]::Round($buildPhase.claudeSeconds) | Should -Be 220
        Remove-Item $s.Dir -Recurse -Force
    }
}
