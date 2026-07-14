<#
  Pester tests for Setup.ps1 and Teardown.ps1 (Part 0 — wraps all tiers).
  Setup tests probe (never install). Teardown tests use a fake working tree.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Setup.ps1')
    . (Join-Path $PSScriptRoot '..' 'Teardown.ps1')

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
}
