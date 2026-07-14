<#
.SYNOPSIS
  Setup.ps1 — make sure the machine has everything the tests need, before any tier runs.

.DESCRIPTION
  Guiding rule: setup installs anything required to run the tests in the suite. It checks
  what's already there and only installs what's missing, and records what it did.

  The check is separated from the install so it's testable and safe:
    * Get-Tier3Prerequisites  — probe the machine, report each prerequisite's status.
    * Invoke-Tier3Setup       — run the checks and (unless -CheckOnly) install what's
                                missing and installable; stop with a plain message when an
                                essential tool can't be installed automatically.

  If you're only running the cheap tiers, pass -IncludeTier3:$false to skip the
  Tier-3-only prerequisites (the Claude tool, Playwright browsers). No live AI here.
#>

Set-StrictMode -Version Latest

# Return the first line of `<exe> <args>`, or $null when the command is absent/errors.
function Get-CommandVersion {
    param([string]$Exe, [string[]]$VersionArgs = @('--version'))
    if (-not (Get-Command $Exe -ErrorAction SilentlyContinue)) { return $null }
    try {
        $out = & $Exe @VersionArgs 2>$null
        if ($null -eq $out) { return '' }
        return (($out | Select-Object -First 1) | Out-String).Trim()
    }
    catch { return $null }
}

# Probe every prerequisite and report its status. Pure — never installs anything.
function Get-Tier3Prerequisites {
    [CmdletBinding()]
    param([bool]$IncludeTier3 = $true)

    $items = [System.Collections.Generic.List[hashtable]]::new()

    $nodeV = Get-CommandVersion -Exe 'node'
    $items.Add(@{ name = 'Node.js (v20+) & npm'; present = [bool]$nodeV; version = $nodeV; requiredFor = 'Tiers 1 & 2, building the app'; installable = $false; hint = 'Install Node.js v20 or newer from nodejs.org (or your package manager).' })

    $pwshV = Get-CommandVersion -Exe 'pwsh'
    $items.Add(@{ name = 'PowerShell 7'; present = [bool]$pwshV; version = $pwshV; requiredFor = 'the runner and the PowerShell hook tests'; installable = $false; hint = 'Install PowerShell 7 from aka.ms/powershell.' })

    $pester = Get-Module -ListAvailable Pester | Where-Object { $_.Version -ge [version]'5.0' } | Select-Object -First 1
    $items.Add(@{ name = 'Pester 5'; present = [bool]$pester; version = ($(if ($pester) { $pester.Version.ToString() } else { $null })); requiredFor = 'the Tier 1 & Tier 3 PowerShell tests'; installable = $true; hint = 'Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.0'; install = { Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0 } })

    $gitV = Get-CommandVersion -Exe 'git'
    $items.Add(@{ name = 'Git'; present = [bool]$gitV; version = $gitV; requiredFor = 'Tier 2 and the build history'; installable = $false; hint = 'Install Git from git-scm.com.' })

    if ($IncludeTier3) {
        $claudeV = Get-CommandVersion -Exe 'claude'
        $items.Add(@{ name = 'Claude command-line tool (signed in)'; present = [bool]$claudeV; version = $claudeV; requiredFor = 'Tier 3 live runs'; installable = $false; hint = 'Install the Claude command-line tool and sign in (we never store logins).' })
    }

    return $items
}

# Run the checks and install what's missing + installable (unless -CheckOnly). Writes a
# short log when -LogPath is given. Stops with a clear message when an essential,
# non-installable prerequisite is missing.
function Invoke-Tier3Setup {
    [CmdletBinding()]
    param(
        [bool]$IncludeTier3 = $true,
        [switch]$CheckOnly,
        [string]$LogPath
    )
    $log = [System.Collections.Generic.List[string]]::new()
    $add = { param($m) $log.Add($m); Write-Verbose $m }

    $prereqs = Get-Tier3Prerequisites -IncludeTier3 $IncludeTier3
    $blocking = [System.Collections.Generic.List[string]]::new()

    foreach ($p in $prereqs) {
        if ($p.present) {
            & $add "[ok] $($p.name) — $($p.version)"
            continue
        }
        if ($p.installable -and -not $CheckOnly) {
            & $add "[install] $($p.name) — installing…"
            try { & $p.install; & $add "[install] $($p.name) — done" }
            catch { & $add "[warn] $($p.name) — install failed: $($_.Exception.Message)"; $blocking.Add($p.name) }
        }
        elseif ($p.installable -and $CheckOnly) {
            & $add "[missing] $($p.name) — would install ($($p.hint))"
        }
        else {
            & $add "[action needed] $($p.name) — $($p.hint)"
            $blocking.Add($p.name)
        }
    }

    if ($LogPath) {
        $dir = Split-Path -Parent $LogPath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -Path $LogPath -Value ($log -join "`n") -Encoding utf8
    }

    return @{ prerequisites = $prereqs; blocking = @($blocking); log = @($log); ok = (@($blocking).Count -eq 0) }
}
