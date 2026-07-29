<#
  Pester tests for live-driver.ps1 — the no-AI pieces (scaffold, prompt, event parsing,
  build check). The actual `claude` spawn is exercised only in a real run, not here.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'live-driver.ps1')

    function New-FakeTemplate {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-tmpl-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.claude\agents') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'node_modules\junk') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'AI-tests') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'CLAUDE.md') -Value '# template' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\src\keep.ts') -Value 'export {}' -Encoding utf8
        Set-Content -Path (Join-Path $root 'node_modules\junk\big.js') -Value 'x' -Encoding utf8
        Set-Content -Path (Join-Path $root 'AI-tests\should-not-copy.txt') -Value 'x' -Encoding utf8
        return $root
    }
    function New-FakeBenchmark {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-bench-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'frontend\docs') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'backend') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'frontend\docs\brief.md') -Value '# brief' -Encoding utf8
        Set-Content -Path (Join-Path $root 'backend\BRD.md') -Value '# brd' -Encoding utf8
        Set-Content -Path (Join-Path $root 'answers.json') -Value '{"signIn":{"choice":"your own server (BFF)"}}' -Encoding utf8
        return $root
    }
}

Describe 'Scaffold — copy template + drop docs, skip the junk' {
    It 'PASS: copies the template but excludes AI-tests/node_modules; puts docs in documentation/' {
        $tmpl = New-FakeTemplate
        $bench = New-FakeBenchmark
        $work = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-work-" + [Guid]::NewGuid().ToString('N'))
        New-Tier3Scaffold -TemplateRoot $tmpl -WorkingDir $work -BenchmarkDir $bench | Out-Null

        Test-Path (Join-Path $work 'CLAUDE.md')              | Should -BeTrue
        Test-Path (Join-Path $work 'web\src\keep.ts')        | Should -BeTrue
        Test-Path (Join-Path $work '.claude\agents')         | Should -BeTrue
        Test-Path (Join-Path $work 'node_modules')           | Should -BeFalse   # excluded
        Test-Path (Join-Path $work 'AI-tests')               | Should -BeFalse   # excluded
        Test-Path (Join-Path $work 'documentation\brief.md') | Should -BeTrue    # frontend docs dropped in
        Test-Path (Join-Path $work 'documentation\backend\BRD.md') | Should -BeTrue
        Test-Path (Join-Path $work 'TIER3-ANSWERS.json') | Should -BeTrue        # answers file dropped in for the gates
        Remove-Item $tmpl, $bench, $work -Recurse -Force
    }
}

Describe 'Prompt — real /start + /continue, answers file for the gates' {
    It 'PASS: drives /start and /continue, non-interactive, points at the answers file' {
        $prompt = Get-Tier3Prompt
        $prompt | Should -Match '/start'
        $prompt | Should -Match '/continue'
        $prompt | Should -Match 'NON-INTERACTIVE'
        $prompt | Should -Match 'TIER3-ANSWERS\.json'
        $prompt | Should -Match 'BFF'
    }
    It 'PASS: the resume prompt continues via /continue using the answers file' {
        $rp = Get-Tier3ResumePrompt
        $rp | Should -Match 'interrupted'
        $rp | Should -Match '/continue'
        $rp | Should -Match 'TIER3-ANSWERS\.json'
    }
}

Describe 'Event parsing — Read-ClaudeEvent updates state and fires OnTurn' {
    It 'PASS: assistant events count turns + guess gate; result captures totals' {
        $state = @{ turns = 0; sessionId = $null; model = 'opus'; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
        $seen = New-Object System.Collections.Generic.List[string]
        $onTurn = { param($n, $g) $seen.Add("$n=$g") }

        Read-ClaudeEvent -Line '{"type":"system","session_id":"abc","model":"opus"}' -State $state -OnTurn $onTurn
        Read-ClaudeEvent -Line '{"type":"assistant","message":{"usage":{"input_tokens":10,"output_tokens":5},"content":[{"type":"tool_use","name":"Write","input":{"file_path":"web/src/app/page.tsx"}}]}}' -State $state -OnTurn $onTurn
        Read-ClaudeEvent -Line '{"type":"result","is_error":false,"duration_ms":5000,"total_cost_usd":0.12,"usage":{"input_tokens":10,"output_tokens":5}}' -State $state -OnTurn $onTurn

        $state.turns      | Should -Be 1
        $state.sessionId  | Should -Be 'abc'
        $state.sawResult  | Should -BeTrue
        $state.durationMs | Should -Be 5000
        @($seen)[0]       | Should -Be '1=green'      # a web/src .tsx write => green
    }

    It 'FAIL-guard: a non-JSON line is ignored, not fatal' {
        $state = @{ turns = 0; sessionId = $null; model = $null; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
        { Read-ClaudeEvent -Line 'not json at all' -State $state -OnTurn $null } | Should -Not -Throw
        $state.turns | Should -Be 0
    }

    It 'PASS: MANY result events SUM (duration, cost, tokens) — not last-write-wins' {
        $state = @{ turns = 0; sessionId = $null; model = 'opus'; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
        # three sub-invocations, each its own cumulative usage/duration/cost
        Read-ClaudeEvent -Line '{"type":"result","duration_ms":100000,"total_cost_usd":0.10,"usage":{"input_tokens":1000,"output_tokens":200,"cache_read_input_tokens":5000}}' -State $state -OnTurn $null
        Read-ClaudeEvent -Line '{"type":"result","duration_ms":50000,"total_cost_usd":0.05,"usage":{"input_tokens":500,"output_tokens":100,"cache_read_input_tokens":2000}}' -State $state -OnTurn $null
        Read-ClaudeEvent -Line '{"type":"result","duration_ms":20000,"total_cost_usd":0.02,"usage":{"input_tokens":300,"output_tokens":50}}' -State $state -OnTurn $null
        $state.durationMs | Should -Be 170000                 # 100000+50000+20000 (not 20000)
        [Math]::Round($state.costUsd, 2) | Should -Be 0.17    # 0.10+0.05+0.02
        $state.tokens     | Should -Be 9150                   # (1000+200+5000)+(500+100+2000)+(300+50)
    }

    It 'PASS: result token capture tolerates the modelUsage format (no usage object)' {
        $state = @{ turns = 0; sessionId = $null; model = 'opus'; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
        Read-ClaudeEvent -Line '{"type":"result","duration_api_ms":30000,"modelUsage":{"claude-opus":{"input_tokens":400,"output_tokens":100},"claude-haiku":{"input_tokens":50,"output_tokens":10}}}' -State $state -OnTurn $null
        $state.durationMs | Should -Be 30000                  # duration_api_ms fallback
        $state.tokens     | Should -Be 560                    # 400+100+50+10 across both models
    }
}

Describe 'Epic stats — commit-epic parse, per-epic time, story counts' {
    It 'PASS: Get-Tier3CommitEpic reads the epic slug from a conventional-commit scope' {
        Get-Tier3CommitEpic -Subject 'feat(auth-and-app-shell/story-3): sign-in' | Should -Be 'auth-and-app-shell'
        Get-Tier3CommitEpic -Subject 'docs(auth-and-app-shell): start epic'      | Should -Be 'auth-and-app-shell'
        Get-Tier3CommitEpic -Subject 'chore: initial template scaffold'          | Should -BeNullOrEmpty
    }

    It 'PASS: Measure-Tier3Epics = last-minus-first commit per epic, keeps story counts' {
        $epics = @(@{ slug = 'auth'; stories = 2 }, @{ slug = 'review'; stories = 1 })
        $commits = @(
            @{ ts = 1000; subject = 'docs(auth): start epic' },
            @{ ts = 1300; subject = 'feat(auth/story-1): a' },
            @{ ts = 1900; subject = 'chore(auth): epic-end' },
            @{ ts = 2000; subject = 'docs(review): start epic' },
            @{ ts = 2500; subject = 'feat(review/story-1): b' }
        )
        $m = Measure-Tier3Epics -Epics $epics -Commits $commits
        ($m | Where-Object { $_.slug -eq 'auth' }).seconds   | Should -Be 900   # 1900-1000
        ($m | Where-Object { $_.slug -eq 'review' }).seconds | Should -Be 500   # 2500-2000
        ($m | Where-Object { $_.slug -eq 'auth' }).stories   | Should -Be 2
    }

    It 'FAIL-guard: an epic with no matching commits gets 0 seconds, not an error' {
        $m = @(Measure-Tier3Epics -Epics @(@{ slug = 'ghost'; stories = 0 }) -Commits @(@{ ts = 1; subject = 'chore: x' }))
        $m.Count | Should -Be 1
        ($m | Where-Object { $_.slug -eq 'ghost' }).seconds | Should -Be 0
    }

    It 'PASS: Get-Tier3EpicDirs counts story-*.md per epic folder' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-epics-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'generated-docs/epics/alpha/stories') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'generated-docs/epics/beta/stories')  -Force | Out-Null
        Set-Content -Path (Join-Path $root 'generated-docs/epics/alpha/stories/story-1.md') -Value 'x'
        Set-Content -Path (Join-Path $root 'generated-docs/epics/alpha/stories/story-2.md') -Value 'x'
        $dirs = Get-Tier3EpicDirs -Scaffold $root
        @($dirs).Count | Should -Be 2
        ($dirs | Where-Object { $_.slug -eq 'alpha' }).stories | Should -Be 2
        ($dirs | Where-Object { $_.slug -eq 'beta' }).stories  | Should -Be 0
        Remove-Item $root -Recurse -Force
    }

    It 'FAIL-guard: a scaffold with no epics folder yields zero epics, not an error' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-noepics-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        @(Get-Tier3EpicDirs -Scaffold $root).Count | Should -Be 0
        Remove-Item $root -Recurse -Force
    }
}

Describe 'Per-phase Claude-time distribution' {
    It 'PASS: the build phase gets the whole time; workflow-phases split by output tokens' {
        $spans = @(
            @{ path = 'opus/build'; level = 'phase'; activeSeconds = 100; claudeSeconds = 0 },
            @{ path = 'opus/build/spec'; level = 'wphase'; activeSeconds = 20; claudeSeconds = 0 },
            @{ path = 'opus/build/green'; level = 'wphase'; activeSeconds = 60; claudeSeconds = 0 },
            @{ path = 'opus/build/turn-1'; level = 'turn'; activeSeconds = 5; claudeSeconds = 0 }  # ignored
        )
        $gateTokens = @{ spec = 25; green = 75 }   # total 100 -> spec 25%, green 75%
        $phases = Get-DistributedPhaseTiming -Spans $spans -GateTokens $gateTokens -TotalClaudeSeconds 400

        $build = $phases | Where-Object { $_.path -eq 'opus/build' }
        $spec = $phases | Where-Object { $_.path -eq 'opus/build/spec' }
        $green = $phases | Where-Object { $_.path -eq 'opus/build/green' }
        $build.claudeSeconds | Should -Be 400          # whole build
        $spec.claudeSeconds  | Should -Be 100          # 25% of 400
        $green.claudeSeconds | Should -Be 300          # 75% of 400
        @($phases | Where-Object { $_.path -like '*turn-*' }).Count | Should -Be 0   # turns excluded
        Remove-Variable phases
    }

    It 'PASS: recurring gates (many red/green cycles) collapse into one row per gate' {
        $spans = @(
            @{ path = 'opus/build'; level = 'phase'; activeSeconds = 100; claudeSeconds = 0 },
            @{ path = 'opus/build/red'; level = 'wphase'; activeSeconds = 10; claudeSeconds = 0 },
            @{ path = 'opus/build/green'; level = 'wphase'; activeSeconds = 20; claudeSeconds = 0 },
            @{ path = 'opus/build/red'; level = 'wphase'; activeSeconds = 30; claudeSeconds = 0 },   # red again
            @{ path = 'opus/build/green'; level = 'wphase'; activeSeconds = 40; claudeSeconds = 0 }   # green again
        )
        $gateTokens = @{ red = 50; green = 50 }
        $phases = Get-DistributedPhaseTiming -Spans $spans -GateTokens $gateTokens -TotalClaudeSeconds 200
        @($phases | Where-Object { $_.path -eq 'opus/build/red' }).Count | Should -Be 1     # one row, not two
        ($phases | Where-Object { $_.path -eq 'opus/build/red' }).activeSeconds | Should -Be 40   # 10 + 30 summed
        ($phases | Where-Object { $_.path -eq 'opus/build/red' }).claudeSeconds | Should -Be 100  # 50% of 200, once
        Remove-Variable phases
    }

    It 'FAIL-guard: zero total tokens gives 0 to workflow-phases (no divide-by-zero)' {
        $spans = @(@{ path = 'opus/build/spec'; level = 'wphase'; activeSeconds = 10; claudeSeconds = 0 })
        $phases = Get-DistributedPhaseTiming -Spans $spans -GateTokens @{} -TotalClaudeSeconds 100
        ($phases | Where-Object { $_.path -eq 'opus/build/spec' }).claudeSeconds | Should -Be 0
    }
}

Describe 'Cross-segment progress (resume accumulation)' {
    It 'PASS: Merge adds tokens/turns/times, sums gate tokens, and takes memory extremes' {
        $prior = @{ segments = 1; turns = 100; tokens = 1000; claudeSeconds = 500; activeSeconds = 400; excludedSeconds = 60; gateTokens = @{ red = 50 }; memPeakUsedMB = 20000; memBaselineUsedMB = 18000; memMinAvailableMB = 5000; memTotalMB = 32000 }
        $seg = @{ turns = 50; tokens = 800; claudeSeconds = 300; activeSeconds = 200; excludedSeconds = 10; gateTokens = @{ red = 30; green = 20 }; memPeakUsedMB = 22000; memBaselineUsedMB = 17000; memMinAvailableMB = 4000; memTotalMB = 32000 }
        $c = Merge-Tier3Progress -Prior $prior -Segment $seg
        $c.segments        | Should -Be 2
        $c.turns           | Should -Be 150
        $c.tokens          | Should -Be 1800
        $c.claudeSeconds   | Should -Be 800
        $c.activeSeconds   | Should -Be 600
        $c.gateTokens.red  | Should -Be 80      # 50 + 30
        $c.gateTokens.green | Should -Be 20
        $c.memPeakUsedMB   | Should -Be 22000   # max
        $c.memBaselineUsedMB | Should -Be 17000 # min
        $c.memMinAvailableMB | Should -Be 4000  # min
    }

    It 'PASS: a first (non-resume) run merges zeros -> equals the single segment' {
        $seg = @{ turns = 10; tokens = 100; claudeSeconds = 50; activeSeconds = 40; excludedSeconds = 5; gateTokens = @{ spec = 100 }; memPeakUsedMB = 9000; memBaselineUsedMB = 8000; memMinAvailableMB = 6000; memTotalMB = 16000 }
        $c = Merge-Tier3Progress -Prior (New-Tier3ProgressZero) -Segment $seg
        $c.segments | Should -Be 1
        $c.tokens   | Should -Be 100
        $c.turns    | Should -Be 10
    }

    It 'PASS: progress round-trips through disk (including gate tokens)' {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-prog-" + [Guid]::NewGuid().ToString('N'))
        $p = Join-Path $dir 'progress.json'
        $rec = @{ segments = 2; turns = 150; tokens = 1800; claudeSeconds = 800; activeSeconds = 600; excludedSeconds = 70; gateTokens = @{ red = 80; green = 20 }; memPeakUsedMB = 22000; memBaselineUsedMB = 17000; memMinAvailableMB = 4000; memTotalMB = 32000 }
        Write-Tier3Progress -Path $p -Record $rec
        $back = Read-Tier3Progress -Path $p
        $back.tokens         | Should -Be 1800
        $back.segments       | Should -Be 2
        $back.gateTokens.red | Should -Be 80
        $back.memPeakUsedMB  | Should -Be 22000
        Remove-Item $dir -Recurse -Force
    }

    It 'FAIL-guard: a missing progress file reads as zeros' {
        $z = Read-Tier3Progress -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'no-progress-xyz.json')
        $z.segments | Should -Be 0
        $z.tokens   | Should -Be 0
    }

    It 'PASS: memory summary from combined progress computes added + 16 GB verdict' {
        $c = @{ memPeakUsedMB = 22000; memBaselineUsedMB = 17000; memMinAvailableMB = 4000; memTotalMB = 32000 }
        $m = Get-MemorySummaryFromProgress -P $c
        $m.addedMB          | Should -Be 5000               # 22000 - 17000
        $m.estimatedVmUseMB | Should -Be 9096               # 4096 + 5000
        $m.fitsBudget       | Should -BeTrue                # 9096 < 16384
    }
}

Describe 'App zip — snapshot the built app, skip the heavy junk' {
    It 'PASS: zips the source but excludes node_modules/.next; skips nothing readable' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-zip-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'web\src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\node_modules\pkg') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\.next\cache') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'CLAUDE.md') -Value '# t' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\src\page.tsx') -Value 'export {}' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\node_modules\pkg\index.js') -Value 'x' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\.next\cache\c.bin') -Value 'x' -Encoding utf8

        $zip = Join-Path $root 'app.zip'
        $res = Compress-Tier3App -SourceDir $root -DestZip $zip
        $res.ok | Should -BeTrue
        Test-Path $zip | Should -BeTrue

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $names = [System.IO.Compression.ZipFile]::OpenRead($zip).Entries.FullName
        ($names -contains 'CLAUDE.md')       | Should -BeTrue
        ($names -contains 'web/src/page.tsx') | Should -BeTrue
        ($names -join '|') | Should -Not -Match 'node_modules'
        ($names -join '|') | Should -Not -Match '\.next'
        Remove-Item $root -Recurse -Force
    }

    It 'FAIL-guard: a missing source returns ok=false, never throws' {
        $res = Compress-Tier3App -SourceDir (Join-Path ([System.IO.Path]::GetTempPath()) 'no-such-src-xyz') -DestZip (Join-Path ([System.IO.Path]::GetTempPath()) 'x.zip')
        $res.ok | Should -BeFalse
    }
}

Describe 'Conformance scoring — reuse the real artifact-lint rules' {
    It 'PASS: maps failed artifact-lint files to rule ids; clean files are not flagged' {
        $json = @'
{
  "numTotalTests": 6, "numFailedTests": 2,
  "testResults": [
    { "name": "C:/x/AI-tests/tier-1-unit/artifact-lint/shadcn-imports-only.test.ts",
      "assertionResults": [ {"status":"passed","title":"sample"}, {"status":"failed","title":"real web/src"} ] },
    { "name": "C:/x/AI-tests/tier-1-unit/artifact-lint/api-path-exactness.test.ts",
      "assertionResults": [ {"status":"passed","title":"sample"}, {"status":"passed","title":"real"} ] },
    { "name": "C:/x/AI-tests/tier-1-unit/artifact-lint/role-field-in-stories.test.ts",
      "assertionResults": [ {"status":"failed","title":"role missing"} ] }
  ]
}
'@
        $missed = ConvertFrom-VitestArtifactJson -Json $json
        $missed | Should -Contain 'shadcn-only'      # had a failing assertion
        $missed | Should -Contain 'role-per-story'   # had a failing assertion
        $missed | Should -Not -Contain 'exact-api-paths'  # all passed
        @($missed).Count | Should -Be 2
    }

    It 'PASS: a fully clean run yields no missed rules' {
        $json = '{"numTotalTests":2,"numFailedTests":0,"testResults":[{"name":"tier-1-unit/artifact-lint/shadcn-imports-only.test.ts","assertionResults":[{"status":"passed","title":"a"}]}]}'
        @(ConvertFrom-VitestArtifactJson -Json $json).Count | Should -Be 0
    }
}

Describe 'Lower-tier group parsing (Tier 1 / Tier 2)' {
    It 'PASS: groups assertions by tier and counts pass/fail/skip' {
        $json = @'
{
  "testResults": [
    { "name": "C:/x/AI-tests/tier-1-unit/scripts/a.test.ts", "startTime": 1000, "endTime": 3000,
      "assertionResults": [ {"status":"passed"}, {"status":"passed"}, {"status":"failed"} ] },
    { "name": "C:/x/AI-tests/tier-2-recorded-run/recorded-run.test.ts", "startTime": 3000, "endTime": 3500,
      "assertionResults": [ {"status":"passed"}, {"status":"pending"} ] }
  ]
}
'@
        $groups = ConvertFrom-VitestGroupsJson -Json $json
        $t1 = $groups | Where-Object { $_.name -match 'Tier 1' }
        $t2 = $groups | Where-Object { $_.name -match 'Tier 2' }
        $t1.tests   | Should -Be 3
        $t1.passed  | Should -Be 2
        $t1.failed  | Should -Be 1
        $t1.durationSeconds | Should -Be 2      # (3000-1000)/1000
        $t2.skipped | Should -Be 1              # the 'pending' one
    }
    It 'FAIL-guard: a tier with no tests is omitted' {
        $json = '{"testResults":[{"name":"tier-1-unit/x.test.ts","startTime":0,"endTime":0,"assertionResults":[{"status":"passed"}]}]}'
        $groups = ConvertFrom-VitestGroupsJson -Json $json
        @($groups | Where-Object { $_.name -match 'Tier 2' }).Count | Should -Be 0
    }
}

Describe 'Build check — recorded, never gating' {
    It 'PASS: a working dir with no web/ app is reported as not-built (not an error)' {
        $work = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-nobuild-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        $r = Test-Tier3Build -WorkingDir $work
        $r.ok | Should -BeFalse
        $r.detail | Should -Match 'no web'
        Remove-Item $work -Recurse -Force
    }
}

Describe 'Browser pre-warm — aimed at the template THIS run builds' {
    # The regression this guards: the driver's pre-warm resolved the Playwright version from the
    # DECLARED RANGE whenever setup hadn't already aimed it — which is exactly the set of paths the
    # pre-warm exists to cover (-SkipSetup, a resumed run, the driver loaded on its own). It then
    # warmed the range's newest Chromium (^1.59.1 -> 1.62.0 -> chromium-1234), reported a complete
    # cache, and the app installed its LOCKED 1.59.1 -> chromium-1217: a browser download mid-epic,
    # under time pressure, in a headless session that can end before it finishes.
    #
    # Every test here is offline: the cache is faked and complete (so the pre-warm takes its
    # "nothing to fetch" branch and never installs), and TIER3_BROWSER_COMPONENTS stands in for the
    # `--dry-run` component probe. What's asserted is the VERSION the pre-warm resolved, read back
    # from the log it writes.
    BeforeAll {
        # Setup.ps1 supplies Set-Tier3TemplateRoot / the resolver the pre-warm delegates to; loading
        # it here is what puts the driver on its real (delegating) path rather than the fallback.
        . (Join-Path $PSScriptRoot '..' 'Setup.ps1')

        # A function's source with comment lines dropped — so an assertion about what a function RUNS
        # isn't satisfied (or broken) by prose explaining why it doesn't run it.
        function Get-FunctionCode {
            param([string]$Name)
            return (((Get-Command $Name).Definition -split "`n" | Where-Object { $_ -notmatch '^\s*#' }) -join "`n")
        }
    }

    BeforeEach {
        $script:cache = Join-Path ([System.IO.Path]::GetTempPath()) ("pw-cache-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:cache -Force | Out-Null
        # A complete chromium-1217: the INSTALLATION_COMPLETE marker Playwright reuses on, plus a
        # real executable — the two things Test-PlaywrightChromium demands before it says "ready".
        $exe = Join-Path (Join-Path $script:cache 'chromium-1217') (Get-PlaywrightChromiumExeRelativePaths)[0]
        New-Item -ItemType Directory -Path (Split-Path $exe -Parent) -Force | Out-Null
        Set-Content -Path $exe -Value 'binary' -Encoding utf8
        Set-Content -Path (Join-Path (Join-Path $script:cache 'chromium-1217') 'INSTALLATION_COMPLETE') -Value '' -Encoding utf8

        $script:prevCache = $env:PLAYWRIGHT_BROWSERS_PATH
        $script:prevComp  = $env:TIER3_BROWSER_COMPONENTS
        $script:prevVer   = $env:TIER3_PLAYWRIGHT_VERSION
        $env:PLAYWRIGHT_BROWSERS_PATH = $script:cache
        $env:TIER3_BROWSER_COMPONENTS = 'chromium-1217'
        $env:TIER3_PLAYWRIGHT_VERSION = $null
        Set-Tier3TemplateRoot -Path $null      # start unaimed, like a -SkipSetup run

        $script:logDir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-pwlog-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:logDir -Force | Out-Null
        $script:logPath = Join-Path $script:logDir 'playwright-install.log'

        # A template whose app LOCKS 1.60.2 — inside the declared ^1.59.1 range but not its newest,
        # so resolving the range instead of the lock gives a visibly different answer.
        $script:tmpl = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-tmpl-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $script:tmpl 'web') -Force | Out-Null
        $lock = @{ lockfileVersion = 3; packages = @{ '' = @{ name = 'web' }; 'node_modules/@playwright/test' = @{ version = '1.60.2' } } }
        Set-Content -Path (Join-Path (Join-Path $script:tmpl 'web') 'package-lock.json') -Value ($lock | ConvertTo-Json -Depth 8) -Encoding utf8
    }
    AfterEach {
        Set-Tier3TemplateRoot -Path $null      # don't leak a root into the next test
        $env:PLAYWRIGHT_BROWSERS_PATH = $script:prevCache
        $env:TIER3_BROWSER_COMPONENTS = $script:prevComp
        $env:TIER3_PLAYWRIGHT_VERSION = $script:prevVer
        Remove-Item $script:cache  -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $script:logDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $script:tmpl   -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'PASS: -TemplateRoot pins the pre-warm to the version that template LOCKS' {
        Install-Tier3Browser -LogPath $script:logPath -TemplateRoot $script:tmpl | Out-Null
        (Get-Content $script:logPath -Raw) | Should -Match 'resolved @playwright/test 1\.60\.2'
        Get-Tier3PlaywrightVersion | Should -Be '1.60.2'      # and it stays aimed for the run
    }

    It 'FAIL-guard: the run''s template overrides a version memoised for a DIFFERENT one' {
        # A dev run following a release one (or vice versa) must not inherit the previous pin —
        # that would warm the other channel's browser and stall this run's gate.
        $other = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-tmpl-" + [Guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path (Join-Path $other 'web') -Force | Out-Null
            $lock = @{ lockfileVersion = 3; packages = @{ '' = @{ name = 'web' }; 'node_modules/@playwright/test' = @{ version = '1.59.1' } } }
            Set-Content -Path (Join-Path (Join-Path $other 'web') 'package-lock.json') -Value ($lock | ConvertTo-Json -Depth 8) -Encoding utf8
            Set-Tier3TemplateRoot -Path $other
            Get-Tier3PlaywrightVersion | Should -Be '1.59.1'          # the stale pin is live...

            Install-Tier3Browser -LogPath $script:logPath -TemplateRoot $script:tmpl | Out-Null
            (Get-Content $script:logPath -Raw) | Should -Match 'resolved @playwright/test 1\.60\.2'
            Get-Tier3PlaywrightVersion | Should -Be '1.60.2'          # ...and this run re-aimed it
        }
        finally { Remove-Item $other -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'PASS: the pre-warm still runs (and logs) when no template root is given' {
        # Backwards-compatible: an explicit env pin keeps the old argument-less behaviour working.
        $env:TIER3_PLAYWRIGHT_VERSION = '1.60.2'
        { Install-Tier3Browser -LogPath $script:logPath | Out-Null } | Should -Not -Throw
        (Get-Content $script:logPath -Raw) | Should -Match 'resolved @playwright/test 1\.60\.2'
    }

    It 'FAIL-guard: the pre-warm never asks for OS-level deps (the silent sudo hang)' {
        # `--with-deps` needs root: in this non-interactive install a Linux/macOS runner stops on a
        # sudo password prompt nothing can answer, so setup HANGS rather than fails — and there is no
        # timeout around it. The template dropped the same flag for the same reason (stadium-8
        # d643097); neither install path here may reintroduce it.
        Get-FunctionCode 'Install-Tier3Browser'       | Should -Not -Match 'with-deps'
        Get-FunctionCode 'Install-PlaywrightChromium' | Should -Not -Match 'with-deps'
        Get-FunctionCode 'Install-PlaywrightChromium' | Should -Match 'install chromium'
    }
}
