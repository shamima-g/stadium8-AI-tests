<#
.SYNOPSIS
  Setup.ps1 — make sure the machine has everything the tests need, before any tier runs.

.DESCRIPTION
  Guiding rule: setup installs anything required to run the tests in the suite. It checks
  what's already there and only installs what's missing, and records what it did.

  Every prerequisite is MANDATORY. There are no optional items: a run must not start
  unless every prerequisite it needs is present and working. When one is missing, setup
  installs it if it can, then RE-VERIFIES it actually landed; if it still isn't there —
  or can't be installed automatically — setup blocks and the run is aborted with a clear
  message. Nothing is ever "warned about and skipped".

  The check is separated from the install so it's testable and safe:
    * Get-Tier3Prerequisites  — probe the machine, report each prerequisite's status.
    * Invoke-Tier3Setup       — run the checks and (unless -CheckOnly) install what's
                                missing, re-verify it, and block on anything still absent
                                or not installable. `ok` is $true only when EVERY
                                prerequisite is present and working.

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

# The Playwright browser cache dir — honours PLAYWRIGHT_BROWSERS_PATH, else the OS default.
# Browsers live here machine-wide (not per-app), so warming it once covers every built app.
function Get-PlaywrightCacheDir {
    if ($env:PLAYWRIGHT_BROWSERS_PATH -and $env:PLAYWRIGHT_BROWSERS_PATH -ne '0') { return $env:PLAYWRIGHT_BROWSERS_PATH }
    if ($IsWindows)   { return (Join-Path $env:LOCALAPPDATA 'ms-playwright') }
    elseif ($IsMacOS) { return (Join-Path $HOME 'Library/Caches/ms-playwright') }
    else              { return (Join-Path $HOME '.cache/ms-playwright') }
}

# The candidate relative paths to the Chromium executable inside a `chromium-<rev>` build dir,
# per OS. Windows Playwright builds vary by version: newer ones extract to `chrome-win64`,
# older ones to `chrome-win` — we check both so detection doesn't break on a version bump.
function Get-PlaywrightChromiumExeRelativePaths {
    if ($IsWindows)   { return @('chrome-win64\chrome.exe', 'chrome-win\chrome.exe') }
    elseif ($IsMacOS) { return @('chrome-mac/Chromium.app/Contents/MacOS/Chromium') }
    else              { return @('chrome-linux/chrome') }
}

# The actual Chromium executable in the cache (newest `chromium-<rev>` build that has one), or
# $null. This is the ground truth: a `chromium-*` FOLDER can exist from a half-extracted or
# lock-interrupted install with no runnable binary inside — which is exactly what let a
# browserless machine pass the old "a folder is there" check and then stall the run at the
# first e2e gate. We look for the binary (across known layout names), not the folder.
function Get-PlaywrightChromiumExe {
    $dir = Get-PlaywrightCacheDir
    if (-not (Test-Path $dir)) { return $null }
    $rels = Get-PlaywrightChromiumExeRelativePaths
    foreach ($d in (Get-ChildItem -LiteralPath $dir -Directory -Filter 'chromium-*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        foreach ($rel in $rels) {
            $exe = Join-Path $d.FullName $rel
            if (Test-Path -LiteralPath $exe -PathType Leaf) { return $exe }
        }
    }
    return $null
}

# True when Chromium is really installed — the EXECUTABLE exists, not merely a folder. Used both
# to decide whether to skip the install and (post-install) to re-verify it actually landed.
function Test-PlaywrightChromium {
    return [bool](Get-PlaywrightChromiumExe)
}

# Best-effort deeper check: the browser binary actually runs (`chrome --version` exits 0).
# Returns $true/$false; never throws. An extra confidence check after install.
function Test-PlaywrightChromiumRuns {
    $exe = Get-PlaywrightChromiumExe
    if (-not $exe) { return $false }
    try {
        $out = & $exe '--version' 2>$null
        return ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($out | Out-String)))
    }
    catch { return $false }
}

# Remove a stale Playwright install lock (`__dirlock`) and orphan download leftovers (`*.zip`)
# from the machine-global cache. A killed/interrupted install leaves the lock behind, and it then
# blocks EVERY later install on the machine ("wait a few minutes … remove lock manually"). Clearing
# it before we warm is cheap and unblocks the machine immediately. Best-effort — never throws.
function Clear-PlaywrightInstallLock {
    $dir = Get-PlaywrightCacheDir
    if (-not (Test-Path $dir)) { return }
    $lock = Join-Path $dir '__dirlock'
    if (Test-Path -LiteralPath $lock) {
        try { Remove-Item -LiteralPath $lock -Recurse -Force -ErrorAction Stop } catch { }
    }
    foreach ($z in (Get-ChildItem -LiteralPath $dir -Filter '*.zip' -File -ErrorAction SilentlyContinue)) {
        try { Remove-Item -LiteralPath $z.FullName -Force -ErrorAction Stop } catch { }
    }
}

# The Playwright version to warm the cache with. It MUST match the version the template's
# generated app pins — v1.1.0 generates apps on @playwright/test ^1.59.1, whose browser build is
# chromium-1217. Warming with a mismatched version (e.g. an unpinned 'latest') downloads a
# browser the app never uses AND still leaves the app to fetch its own mid-run — defeating the
# whole point. Override with $env:TIER3_PLAYWRIGHT_VERSION when the template bumps Playwright.
function Get-Tier3PlaywrightVersion {
    if ($env:TIER3_PLAYWRIGHT_VERSION) { return $env:TIER3_PLAYWRIGHT_VERSION }
    return '1.59.1'
}

# Install Chromium into the cache, using the pinned version above. Hardened against the failure
# that silently truncated release runs at epic 1:
#   * clears a stale __dirlock + orphan zips first (Clear-PlaywrightInstallLock), so a previous
#     killed install can't block this one;
#   * serialises via a machine-wide mutex so our warm never races another warm on the global cache;
#   * requires BOTH a zero exit AND the executable to actually exist afterwards — "the install
#     command ran" is not enough. Throws on any of these so the caller blocks the run rather than
#     starting it on a machine whose browser will fail at the first e2e gate.
function Install-PlaywrightChromium {
    $ver = Get-Tier3PlaywrightVersion
    $cmd = "npx --yes @playwright/test@$ver install chromium"

    $mutex = $null; $owned = $false
    try { $mutex = New-Object System.Threading.Mutex($false, 'Global\Tier3PlaywrightInstall') }
    catch { $mutex = $null }   # e.g. Global\ not permitted here — proceed without the cross-session guard
    try {
        if ($mutex) {
            try { $owned = $mutex.WaitOne([TimeSpan]::FromMinutes(15)) }
            catch [System.Threading.AbandonedMutexException] { $owned = $true }   # prior holder died; we own it now
        }

        Clear-PlaywrightInstallLock                       # drop any stale lock/zip before we start
        if ($IsWindows) { & cmd.exe /c "$cmd" 2>&1 | Out-Null }
        else            { & npx --yes "@playwright/test@$ver" install chromium 2>&1 | Out-Null }
        $exit = $LASTEXITCODE
        Clear-PlaywrightInstallLock                       # and don't leave a lock behind for the next run

        if ($exit -ne 0) { throw "``$cmd`` exited $exit" }
        if (-not (Test-PlaywrightChromium)) {
            throw "``$cmd`` reported success but no Chromium executable is present under $(Get-PlaywrightCacheDir)"
        }
        if (-not (Test-PlaywrightChromiumRuns)) {
            Write-Verbose 'Playwright Chromium installed but `--version` did not confirm a launch; proceeding on executable presence.'
        }
    }
    finally {
        if ($mutex) {
            if ($owned) { try { $mutex.ReleaseMutex() } catch { } }
            $mutex.Dispose()
        }
    }
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
    $items.Add(@{ name = 'Pester 5'; present = [bool]$pester; version = ($(if ($pester) { $pester.Version.ToString() } else { $null })); requiredFor = 'the Tier 1 & Tier 3 PowerShell tests'; installable = $true; hint = 'Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.0'; install = { Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0 }; verify = { [bool](Get-Module -ListAvailable Pester | Where-Object { $_.Version -ge [version]'5.0' } | Select-Object -First 1) } })

    $gitV = Get-CommandVersion -Exe 'git'
    $items.Add(@{ name = 'Git'; present = [bool]$gitV; version = $gitV; requiredFor = 'Tier 2 and the build history'; installable = $false; hint = 'Install Git from git-scm.com.' })

    if ($IncludeTier3) {
        $claudeV = Get-CommandVersion -Exe 'claude'
        $items.Add(@{ name = 'Claude command-line tool (signed in)'; present = [bool]$claudeV; version = $claudeV; requiredFor = 'Tier 3 live runs'; installable = $false; hint = 'Install the Claude command-line tool and sign in (we never store logins).' })

        # The app's epic-end Playwright (e2e) gate needs a browser installed. If it's missing the
        # workflow discovers it mid-run and downloads it under time pressure — which can end a
        # headless session before the download finishes and stall the whole run at the first epic.
        # It's a MUST-HAVE: setup installs it here and re-verifies the cache; if it still isn't
        # present the run is blocked rather than started and left to stall.
        $chromium = Test-PlaywrightChromium
        $items.Add(@{ name = 'Playwright browser (Chromium)'; present = $chromium; version = ($(if ($chromium) { 'cached' } else { $null })); requiredFor = 'the epic-end Playwright (e2e) gate in Tier 3 live runs'; installable = $true; hint = 'npx --yes playwright install chromium'; install = { Install-PlaywrightChromium }; verify = { Test-PlaywrightChromium } })
    }

    return $items
}

# Run the checks and install what's missing + installable (unless -CheckOnly), then
# RE-VERIFY each install actually landed. Writes a short log when -LogPath is given.
# Every prerequisite is mandatory: anything still missing, failed to install, or failed
# to verify is added to `blocking`, so `ok` is $true only when the machine is fully ready
# and the caller must refuse to run the tests otherwise.
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
            # Missing but installable: download it, then confirm it's really there. A failed
            # install OR a failed re-verify blocks the run — never install-and-hope.
            & $add "[install] $($p.name) — not found; installing…"
            try {
                & $p.install
                $verified = if ($p.ContainsKey('verify')) { [bool](& $p.verify) } else { $true }
                if ($verified) {
                    & $add "[install] $($p.name) — installed and verified"
                }
                else {
                    & $add "[error] $($p.name) — install ran but it's still not detected; cannot run tests without it"
                    $blocking.Add($p.name)
                }
            }
            catch {
                & $add "[error] $($p.name) — install failed: $($_.Exception.Message); cannot run tests without it"
                $blocking.Add($p.name)
            }
        }
        elseif ($p.installable -and $CheckOnly) {
            # Dry run: report it as not-ready (would install) and count it as blocking so the
            # check honestly says the machine isn't ready to run tests yet.
            & $add "[missing] $($p.name) — not installed (would install: $($p.hint))"
            $blocking.Add($p.name)
        }
        else {
            # Missing and not auto-installable: the user must provide it. Always blocking.
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
