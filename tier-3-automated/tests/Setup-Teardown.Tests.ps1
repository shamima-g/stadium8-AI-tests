<#
  Pester tests for Setup.ps1 and Teardown.ps1 (Part 0 — wraps all tiers).
  Setup tests probe (never install). Teardown tests use a fake working tree.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Setup.ps1')
    . (Join-Path $PSScriptRoot '..' 'Teardown.ps1')

    # A fake Playwright cache entry. $Complete writes the INSTALLATION_COMPLETE marker Playwright
    # itself uses to decide "reuse this" vs "re-download"; without it the dir is half-extracted.
    # $WithExe also lays down the browser binary, so a `chromium-*` entry looks like a real install
    # (marker AND executable) — the two independent things Test-PlaywrightChromium requires.
    function New-PwComponent {
        param([string]$Cache, [string]$Name, [bool]$Complete, [bool]$WithExe = $true)
        $d = Join-Path $Cache $Name
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        $marker = Join-Path $d 'INSTALLATION_COMPLETE'
        if ($Complete) { Set-Content -Path $marker -Value '' -Encoding utf8 }
        elseif (Test-Path $marker) { Remove-Item $marker -Force }
        if ($WithExe -and $Name -like 'chromium-*') {
            $exe = Join-Path $d (Get-PlaywrightChromiumExeRelativePaths)[0]
            New-Item -ItemType Directory -Path (Split-Path $exe -Parent) -Force | Out-Null
            if (-not (Test-Path $exe)) { Set-Content -Path $exe -Value 'binary' -Encoding utf8 }
        }
    }

    function New-FakeWorkingTree {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-work-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'web\src\app') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\node_modules\left-pad') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\.next\cache') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'generated-docs\epics') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'web\src\app\page.tsx') -Value 'export default () => null' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\node_modules\left-pad\index.js') -Value 'module.exports=1' -Encoding utf8
        Set-Content -Path (Join-Path $root 'generated-docs\project.md') -Value '# project' -Encoding utf8
        return $root
    }
}

Describe 'Playwright browser detection + lock clearing (hardened)' {
    BeforeEach {
        $script:cache = Join-Path ([System.IO.Path]::GetTempPath()) ("pw-cache-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:cache -Force | Out-Null
        $script:prevPath = $env:PLAYWRIGHT_BROWSERS_PATH
        $env:PLAYWRIGHT_BROWSERS_PATH = $script:cache
    }
    AfterEach {
        $env:PLAYWRIGHT_BROWSERS_PATH = $script:prevPath
        Remove-Item $script:cache -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'FAIL-guard: a chromium-* FOLDER with no executable is NOT detected as present' {
        # The exact state that let a browserless machine pass the old check and stall at epic 1.
        New-Item -ItemType Directory -Path (Join-Path $script:cache 'chromium-1217') -Force | Out-Null
        Test-PlaywrightChromium      | Should -BeFalse
        Get-PlaywrightChromiumExe    | Should -BeNullOrEmpty
    }

    It 'PASS: a chromium-* build WITH the executable is detected (across layout names)' {
        foreach ($rel in (Get-PlaywrightChromiumExeRelativePaths)) {
            $c = Join-Path $script:cache ("chromium-1217-" + [Guid]::NewGuid().ToString('N').Substring(0,6))
            $exe = Join-Path $c $rel
            New-Item -ItemType Directory -Path (Split-Path $exe -Parent) -Force | Out-Null
            Set-Content -Path $exe -Value 'binary' -Encoding utf8
            (Get-PlaywrightChromiumExe) | Should -Not -BeNullOrEmpty
            Remove-Item $c -Recurse -Force
        }
    }

    It 'PASS: the newer chrome-win64 layout is detected (regression for the chrome-win bug)' -Skip:(-not $IsWindows) {
        $exe = Join-Path (Join-Path $script:cache 'chromium-1217') 'chrome-win64\chrome.exe'
        New-Item -ItemType Directory -Path (Split-Path $exe -Parent) -Force | Out-Null
        Set-Content -Path $exe -Value 'binary' -Encoding utf8
        (Get-PlaywrightChromiumExe) | Should -Match 'chrome-win64'
    }

    It 'PASS: exe + completion marker + headless shell together read as ready to use' {
        # The full-stack check: the two conditions (component set complete, executable real) met.
        $prevComp = $env:TIER3_BROWSER_COMPONENTS
        try {
            $env:TIER3_BROWSER_COMPONENTS = 'chromium-1217,chromium_headless_shell-1217'
            New-PwComponent $script:cache 'chromium-1217' $true
            New-PwComponent $script:cache 'chromium_headless_shell-1217' $true
            Test-PlaywrightChromium | Should -BeTrue
        }
        finally { $env:TIER3_BROWSER_COMPONENTS = $prevComp }
    }

    It 'FAIL-guard: the completion marker alone is not enough without the executable' {
        # Marker present but no binary — Playwright would reuse the dir and the launch would fail.
        $prevComp = $env:TIER3_BROWSER_COMPONENTS
        try {
            $env:TIER3_BROWSER_COMPONENTS = 'chromium-1217'
            New-PwComponent $script:cache 'chromium-1217' $true $false
            @(Get-MissingPlaywrightComponents).Count | Should -Be 0     # marker says complete...
            Test-PlaywrightChromium | Should -BeFalse                   # ...but no exe → not ready
        }
        finally { $env:TIER3_BROWSER_COMPONENTS = $prevComp }
    }

    It 'PASS: Clear-PlaywrightInstallLock removes a stale __dirlock and orphan zips' {
        New-Item -ItemType Directory -Path (Join-Path $script:cache '__dirlock') -Force | Out-Null
        Set-Content -Path (Join-Path $script:cache 'chromium.zip') -Value 'x' -Encoding utf8
        Set-Content -Path (Join-Path $script:cache 'chromium-headless-shell.zip') -Value 'x' -Encoding utf8
        Clear-PlaywrightInstallLock
        Test-Path (Join-Path $script:cache '__dirlock')            | Should -BeFalse
        @(Get-ChildItem -LiteralPath $script:cache -Filter '*.zip').Count | Should -Be 0
    }

    It 'PASS: Clear-PlaywrightInstallLock is a safe no-op when there is nothing to clear' {
        { Clear-PlaywrightInstallLock } | Should -Not -Throw
    }
}

Describe 'Setup — probing (never installs)' {
    It 'PASS: reports Node and PowerShell as present in this environment' {
        $prereqs = Get-Tier3Prerequisites -IncludeTier3 $true
        ($prereqs | Where-Object { $_.name -like 'Node*' }).present  | Should -BeTrue
        ($prereqs | Where-Object { $_.name -like 'PowerShell*' }).present | Should -BeTrue
    }

    It 'PASS: -IncludeTier3:$false drops the Claude-tool prerequisite' {
        $with    = Get-Tier3Prerequisites -IncludeTier3 $true
        $without = Get-Tier3Prerequisites -IncludeTier3 $false
        @($with    | Where-Object { $_.name -like 'Claude*' }).Count | Should -Be 1
        @($without | Where-Object { $_.name -like 'Claude*' }).Count | Should -Be 0
    }

    It 'PASS: -IncludeTier3 adds the Playwright browser prerequisite, dropped without it' {
        $with    = Get-Tier3Prerequisites -IncludeTier3 $true
        $without = Get-Tier3Prerequisites -IncludeTier3 $false
        @($with    | Where-Object { $_.name -like 'Playwright*' }).Count | Should -Be 1
        @($without | Where-Object { $_.name -like 'Playwright*' }).Count | Should -Be 0
    }

    It 'PASS: the Playwright browser prerequisite is mandatory (installable, not optional)' {
        $pw = Get-Tier3Prerequisites -IncludeTier3 $true | Where-Object { $_.name -like 'Playwright*' }
        $pw.installable | Should -BeTrue
        ($pw.ContainsKey('optional') -and $pw.optional) | Should -BeFalse   # must be present to run
    }

    It 'PASS: the browser check demands the pinned build, both halves, each marked complete' {
        # The gate must LAUNCH from the cache, never fetch: a different build, a missing headless
        # shell, or a half-extracted dir all mean a mid-run download, so all three read as absent.
        $cache = Join-Path ([System.IO.Path]::GetTempPath()) ("pw-cache-" + [Guid]::NewGuid().ToString('N'))
        $oldPath = $env:PLAYWRIGHT_BROWSERS_PATH
        $oldComp = $env:TIER3_BROWSER_COMPONENTS
        try {
            $env:PLAYWRIGHT_BROWSERS_PATH = $cache
            $env:TIER3_BROWSER_COMPONENTS = 'chromium-1217,chromium_headless_shell-1217'
            New-PwComponent $cache 'chromium-9999' $true
            Test-PlaywrightChromium | Should -BeFalse                       # wrong build only

            New-PwComponent $cache 'chromium-1217' $true
            Get-MissingPlaywrightComponents | Should -Be @('chromium_headless_shell-1217')
            Test-PlaywrightChromium | Should -BeFalse                       # headless shell absent

            New-PwComponent $cache 'chromium_headless_shell-1217' $false    # no completion marker
            Test-PlaywrightChromium | Should -BeFalse                       # half-extracted → refetch

            New-PwComponent $cache 'chromium_headless_shell-1217' $true
            @(Get-MissingPlaywrightComponents).Count | Should -Be 0
            Test-PlaywrightChromium | Should -BeTrue                        # complete → will be used
        }
        finally {
            $env:PLAYWRIGHT_BROWSERS_PATH = $oldPath
            $env:TIER3_BROWSER_COMPONENTS = $oldComp
            Remove-Item $cache -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'FAIL-guard: an empty browser cache reads as absent' {
        $cache = Join-Path ([System.IO.Path]::GetTempPath()) ("pw-cache-" + [Guid]::NewGuid().ToString('N'))
        $oldPath = $env:PLAYWRIGHT_BROWSERS_PATH
        $oldComp = $env:TIER3_BROWSER_COMPONENTS
        try {
            $env:TIER3_BROWSER_COMPONENTS = 'chromium-1217,chromium_headless_shell-1217'
            $env:PLAYWRIGHT_BROWSERS_PATH = $cache          # does not exist at all
            Test-PlaywrightChromium | Should -BeFalse
            New-Item -ItemType Directory -Path $cache -Force | Out-Null
            Test-PlaywrightChromium | Should -BeFalse       # exists but holds no browser
        }
        finally {
            $env:PLAYWRIGHT_BROWSERS_PATH = $oldPath
            $env:TIER3_BROWSER_COMPONENTS = $oldComp
            Remove-Item $cache -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'PASS: the resolved Playwright version satisfies the range the generated app declares' {
        # `^1.59.1` allows 1.60/1.61/1.62..., each shipping a DIFFERENT Chromium build. Warming the
        # floor when npm resolves higher is precisely how the gate ends up fetching mid-run.
        $range = Get-Tier3PlaywrightRange
        $range | Should -Match '^\^?\d+\.\d+\.\d+$'
        $floor = [version]($range -replace '^[^0-9]*', '')
        $got   = [version](Get-Tier3PlaywrightVersion)
        $got   | Should -BeGreaterOrEqual $floor                    # never below the declared floor
        $got.Major | Should -Be $floor.Major                        # and inside the caret range
    }

    It 'PASS: the required component list covers the browser AND its headless shell' {
        $comp = Get-Tier3BrowserComponents
        @($comp | Where-Object { $_ -like 'chromium-*' }).Count               | Should -BeGreaterThan 0
        @($comp | Where-Object { $_ -like 'chromium_headless_shell-*' }).Count | Should -BeGreaterThan 0
    }

    It 'PASS: no prerequisite is optional — every item is must-have' {
        $prereqs = Get-Tier3Prerequisites -IncludeTier3 $true
        @($prereqs | Where-Object { $_.ContainsKey('optional') -and $_.optional }).Count | Should -Be 0
    }

    It 'FAIL-guard: a prerequisite that fails to install blocks the run (ok=$false)' {
        # A stubbed install that throws — Invoke-Tier3Setup must record it as blocking, not skip it.
        function Get-Tier3Prerequisites { param([bool]$IncludeTier3 = $true)
            ,@(@{ name = 'FakeTool'; present = $false; installable = $true; hint = 'x'; install = { throw 'boom' }; verify = { $false } }) }
        try {
            $r = Invoke-Tier3Setup -IncludeTier3 $true
            $r.ok                | Should -BeFalse
            $r.blocking          | Should -Contain 'FakeTool'
            ($r.log -join "`n")  | Should -Match '\[error\] FakeTool'
        }
        finally { Remove-Item Function:\Get-Tier3Prerequisites -ErrorAction SilentlyContinue }
    }

    It 'FAIL-guard: a prerequisite that installs but still is not detected blocks the run' {
        # Install succeeds (no throw) but re-verify says it's still absent — must block, never proceed.
        function Get-Tier3Prerequisites { param([bool]$IncludeTier3 = $true)
            ,@(@{ name = 'FakeTool'; present = $false; installable = $true; hint = 'x'; install = { }; verify = { $false } }) }
        try {
            $r = Invoke-Tier3Setup -IncludeTier3 $true
            $r.ok                | Should -BeFalse
            $r.blocking          | Should -Contain 'FakeTool'
            ($r.log -join "`n")  | Should -Match 'still not detected'
        }
        finally { Remove-Item Function:\Get-Tier3Prerequisites -ErrorAction SilentlyContinue }
    }

    It 'PASS: a prerequisite that installs and re-verifies is not blocking' {
        function Get-Tier3Prerequisites { param([bool]$IncludeTier3 = $true)
            ,@(@{ name = 'FakeTool'; present = $false; installable = $true; hint = 'x'; install = { }; verify = { $true } }) }
        try {
            $r = Invoke-Tier3Setup -IncludeTier3 $true
            $r.ok                | Should -BeTrue
            @($r.blocking).Count | Should -Be 0
            ($r.log -join "`n")  | Should -Match 'installed and verified'
        }
        finally { Remove-Item Function:\Get-Tier3Prerequisites -ErrorAction SilentlyContinue }
    }

    It 'PASS: -CheckOnly reports without installing and never throws' {
        $r = Invoke-Tier3Setup -IncludeTier3 $false -CheckOnly
        $r.prerequisites.Count | Should -BeGreaterThan 0
        $r.ContainsKey('ok')   | Should -BeTrue
    }

    It 'PASS: writes a setup log when asked' {
        $logDir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-setuplog-" + [Guid]::NewGuid().ToString('N'))
        $logPath = Join-Path $logDir 'setup.log'
        Invoke-Tier3Setup -IncludeTier3 $false -CheckOnly -LogPath $logPath | Out-Null
        Test-Path $logPath | Should -BeTrue
        (Get-Content $logPath -Raw) | Should -Match '\[ok\]'
        Remove-Item $logDir -Recurse -Force
    }
}

Describe 'Teardown — keep what matters, remove the junk' {
    It 'PASS: removes node_modules and build caches, keeps source + generated-docs' {
        $root = New-FakeWorkingTree
        $res = Invoke-Tier3Teardown -WorkingDir $root
        $res.ok | Should -BeTrue
        Test-Path (Join-Path $root 'web\node_modules') | Should -BeFalse
        Test-Path (Join-Path $root 'web\.next')        | Should -BeFalse
        Test-Path (Join-Path $root 'web\src\app\page.tsx')     | Should -BeTrue
        Test-Path (Join-Path $root 'generated-docs\project.md') | Should -BeTrue
        Remove-Item $root -Recurse -Force
    }

    It 'PASS: -KeepDeps leaves node_modules in place' {
        $root = New-FakeWorkingTree
        Invoke-Tier3Teardown -WorkingDir $root -KeepDeps | Out-Null
        Test-Path (Join-Path $root 'web\node_modules') | Should -BeTrue   # kept
        Test-Path (Join-Path $root 'web\.next')        | Should -BeFalse  # still removed
        Remove-Item $root -Recurse -Force
    }

    It 'PASS: -Full removes the whole working folder' {
        $root = New-FakeWorkingTree
        Invoke-Tier3Teardown -WorkingDir $root -Full | Out-Null
        Test-Path $root | Should -BeFalse
    }

    It 'FAIL-guard: a missing working folder is a no-op, not an error' {
        $res = Invoke-Tier3Teardown -WorkingDir (Join-Path ([System.IO.Path]::GetTempPath()) 'does-not-exist-xyz')
        $res.ok | Should -BeTrue
        $res.note | Should -Match 'nothing to do'
    }

    It 'PASS: compacts the app git repo (history preserved, repo still valid)' {
        $root = New-FakeWorkingTree
        & git -C $root init --quiet 2>$null
        & git -C $root -c user.email=t@t -c user.name=t add -A 2>$null
        & git -C $root -c user.email=t@t -c user.name=t commit -m 'first' --quiet 2>$null
        $res = Invoke-Tier3Teardown -WorkingDir $root
        $res.ok           | Should -BeTrue
        $res.gitCompacted | Should -BeTrue
        Test-Path (Join-Path $root '.git') | Should -BeTrue                    # history kept
        (& git -C $root rev-parse --verify HEAD 2>$null) | Should -Not -BeNullOrEmpty  # repo still valid
        Remove-Item $root -Recurse -Force
    }

    It 'PASS: no .git present → gitCompacted stays false, no error' {
        $root = New-FakeWorkingTree
        $res = Invoke-Tier3Teardown -WorkingDir $root
        $res.ok           | Should -BeTrue
        $res.gitCompacted | Should -BeFalse
        Remove-Item $root -Recurse -Force
    }
}
