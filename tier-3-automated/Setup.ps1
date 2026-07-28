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
# -Pattern narrows the search to one build (callers pass the build the app actually resolves);
# the default keeps the build-agnostic behaviour.
function Get-PlaywrightChromiumExe {
    param([string]$Pattern = 'chromium-*')
    $dir = Get-PlaywrightCacheDir
    if (-not (Test-Path $dir)) { return $null }
    $rels = Get-PlaywrightChromiumExeRelativePaths
    foreach ($d in (Get-ChildItem -LiteralPath $dir -Directory -Filter $Pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        foreach ($rel in $rels) {
            $exe = Join-Path $d.FullName $rel
            if (Test-Path -LiteralPath $exe -PathType Leaf) { return $exe }
        }
    }
    return $null
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

# The semver RANGE the template's generated app declares for @playwright/test (v1.1.0 generates
# apps on ^1.59.1). A FALLBACK only: when the app ships a lockfile the lock decides, because that's
# what `npm install` honours (see Get-Tier3PlaywrightVersionFromLock). The range is what we resolve
# against when there is no lockfile. Override with $env:TIER3_PLAYWRIGHT_RANGE if the template
# changes what it declares.
function Get-Tier3PlaywrightRange {
    if ($env:TIER3_PLAYWRIGHT_RANGE) { return $env:TIER3_PLAYWRIGHT_RANGE }
    return '^1.59.1'
}

# The template whose lockfile decides the version. Set once by Invoke-Tier3Setup so the probes
# below stay argument-less; switching it drops the memoised version/component answers, since a
# different template can pin a different browser.
$script:Tier3PlaywrightVersion = $null
$script:Tier3TemplateRoot      = $null
function Set-Tier3TemplateRoot {
    param([string]$Path)
    $script:Tier3TemplateRoot      = $Path
    $script:Tier3PlaywrightVersion = $null
    $script:Tier3BrowserComponents = $null
}

# The EXACT @playwright/test version the app's `npm install` will land, read from the lockfile the
# app ships — the ground truth, and it OUTRANKS the range. npm honours package-lock.json over the
# caret in package.json, so a template declaring `^1.59.1` while locking 1.59.1 installs 1.59.1,
# NOT the newest match. That distinction is the whole point of this function: each minor ships a
# DIFFERENT Chromium build (1.59.1 → chromium-1217, 1.62.0 → chromium-1234), so resolving the range
# to its newest warmed chromium-1234 while the app launched 1217, and the epic-end gate stalled
# downloading its own browser mid-run — the exact stall this prerequisite exists to prevent.
# Returns $null when there's no readable lockfile, leaving the range to decide as before.
function Get-Tier3PlaywrightVersionFromLock {
    param([string]$TemplateRoot)
    if (-not $TemplateRoot) { return $null }
    # The generated app lives in web/; a flat template keeps its lockfile at the root.
    foreach ($lock in @([System.IO.Path]::Combine($TemplateRoot, 'web', 'package-lock.json'),
                        [System.IO.Path]::Combine($TemplateRoot, 'package-lock.json'))) {
        if (-not (Test-Path -LiteralPath $lock -PathType Leaf)) { continue }
        try {
            # -AsHashtable is REQUIRED, not a convenience: a real npm v2/v3 lockfile carries a ""
            # key for the root package, and ConvertFrom-Json without it fails outright on an empty
            # property name ("only supported using the -AsHashTable switch") — which would send
            # every genuine lockfile down the catch below and quietly restore the very bug this
            # function exists to fix. PowerShell 7 is a hard prerequisite, so the switch is always
            # available. Dictionaries also keep this StrictMode-safe: ContainsKey, not property probes.
            $json = Get-Content -LiteralPath $lock -Raw | ConvertFrom-Json -AsHashtable
            if (-not ($json -is [System.Collections.IDictionary])) { continue }
            # Lockfile v2/v3 record resolved versions under `packages`, v1 under `dependencies`.
            foreach ($probe in @(@{ section = 'packages';     key = 'node_modules/@playwright/test' },
                                 @{ section = 'dependencies'; key = '@playwright/test' })) {
                if (-not $json.ContainsKey($probe.section)) { continue }
                $section = $json[$probe.section]
                if (-not ($section -is [System.Collections.IDictionary]) -or -not $section.ContainsKey($probe.key)) { continue }
                $entry = $section[$probe.key]
                if ($entry -is [System.Collections.IDictionary] -and $entry.ContainsKey('version') -and $entry['version']) {
                    return [string]$entry['version']
                }
            }
        }
        catch { }   # unreadable or not-JSON lockfile — fall through to the range
    }
    return $null
}

# The concrete version to warm, in order of authority:
#   1. $env:TIER3_PLAYWRIGHT_VERSION      — an explicit pin (offline/CI friendly), trusted outright.
#   2. the app's lockfile                 — what `npm install` will really land: the ground truth.
#   3. the range's newest published match — for a template that ships no lockfile.
#   4. the range's floor                  — when npm can't be reached at all.
# An explicitly-passed -TemplateRoot always answers for itself, never from another template's memo.
function Get-Tier3PlaywrightVersion {
    param([string]$TemplateRoot)
    if ($env:TIER3_PLAYWRIGHT_VERSION) { return $env:TIER3_PLAYWRIGHT_VERSION }
    if ($TemplateRoot) {
        $pinned = Get-Tier3PlaywrightVersionFromLock -TemplateRoot $TemplateRoot
        if ($pinned) { $script:Tier3PlaywrightVersion = $pinned; return $pinned }
    }
    if ($script:Tier3PlaywrightVersion) { return $script:Tier3PlaywrightVersion }
    $locked = Get-Tier3PlaywrightVersionFromLock -TemplateRoot $script:Tier3TemplateRoot
    if ($locked) { $script:Tier3PlaywrightVersion = $locked; return $locked }
    $range = Get-Tier3PlaywrightRange
    $floor = ($range -replace '^[^0-9]*', '')
    try {
        # `npm view <range> version` prints one line per matching version ("@playwright/test@1.62.0
        # '1.62.0'") when several match, or a bare version when only one does. Take the last.
        $out = & npm view "@playwright/test@$range" version 2>$null
        $picked = @($out | Where-Object { $_ -match '(\d+\.\d+\.\d+)' } |
                    ForEach-Object { [regex]::Matches($_, '(\d+\.\d+\.\d+)')[-1].Value }) |
                    Select-Object -Last 1
        if ($picked) { $script:Tier3PlaywrightVersion = $picked; return $picked }
    }
    catch { }
    return $floor
}

# The browser components the e2e gate actually needs on disk, asked of Playwright itself rather
# than hard-coded: `install chromium --dry-run` prints an "Install location:" line per component
# (the browser, its headless shell, ffmpeg, and winldd on Windows), so the list always matches the
# version resolved above. A missing component of ANY kind is a mid-run download, so all count —
# the headless shell especially, since that's what a headless `playwright test` actually launches.
# $env:TIER3_BROWSER_COMPONENTS (comma-separated dir names) overrides the probe; 'any' accepts any
# single Chromium build, the loose pre-pin behaviour. Falls back to browser + headless shell for
# any build when the dry-run can't run (offline), so we degrade to the old looseness, never to a
# hard block.
$script:Tier3BrowserComponents = $null
function Get-Tier3BrowserComponents {
    if ($env:TIER3_BROWSER_COMPONENTS) {
        return @($env:TIER3_BROWSER_COMPONENTS -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    if ($script:Tier3BrowserComponents) { return $script:Tier3BrowserComponents }
    $ver = Get-Tier3PlaywrightVersion
    try {
        $cmd = "npx --yes @playwright/test@$ver install chromium --dry-run"
        if ($IsWindows) { $out = & cmd.exe /c "$cmd 2>&1" }
        else            { $out = & npx --yes "@playwright/test@$ver" install chromium --dry-run 2>&1 }
        $dirs = @($out | Select-String -Pattern 'Install location:\s*(\S.*)$' |
                  ForEach-Object { Split-Path -Leaf ($_.Matches[0].Groups[1].Value.Trim()) } |
                  Sort-Object -Unique)
        if ($dirs.Count) { $script:Tier3BrowserComponents = $dirs; return $dirs }
    }
    catch { }
    return @('chromium-*', 'chromium_headless_shell-*')   # last resort: any build, both halves
}

# The `chromium-<rev>` component of the resolved set — the build whose executable must be there.
function Get-Tier3ChromiumComponent {
    $c = @(Get-Tier3BrowserComponents) | Where-Object { $_ -like 'chromium-*' } | Select-Object -First 1
    if ($c) { return $c }
    return 'chromium-*'
}

# True when a cached component is one Playwright will REUSE rather than re-download. Playwright
# writes an INSTALLATION_COMPLETE marker into a browser directory once its download finishes and
# treats a directory without that marker as incomplete — so the marker, not the directory, is the
# real "will be used, not fetched" signal (a half-extracted leftover re-downloads).
function Test-PlaywrightComponent {
    param([Parameter(Mandatory)][string]$Pattern)
    $dir = Get-PlaywrightCacheDir
    if (-not (Test-Path $dir)) { return $false }
    return @(Get-ChildItem -LiteralPath $dir -Directory -Filter $Pattern -ErrorAction SilentlyContinue |
             Where-Object { Test-Path (Join-Path $_.FullName 'INSTALLATION_COMPLETE') }).Count -gt 0
}

# The components the gate needs that AREN'T ready to be reused. Empty means the gate will launch
# straight from the cache: nothing to fetch, nothing to stall on.
function Get-MissingPlaywrightComponents {
    # @() everywhere: a single-component list would otherwise arrive as a bare string, and under
    # Set-StrictMode -Version Latest indexing/.Count on a string is an error, not a one-element list.
    $wanted = @(Get-Tier3BrowserComponents)
    if ($wanted.Count -eq 1 -and $wanted[0] -eq 'any') { $wanted = @('chromium-*') }
    return @($wanted | Where-Object { -not (Test-PlaywrightComponent -Pattern $_) })
}

# True when the e2e gate can launch straight from the cache. Two independent conditions, both
# required: every component of the version the app resolves is present and marked complete (so
# nothing is fetched mid-run), AND the browser build really holds a runnable executable rather
# than a half-extracted shell of one (so it isn't a folder that only looks installed).
function Test-PlaywrightChromium {
    if (@(Get-MissingPlaywrightComponents).Count -ne 0) { return $false }
    return [bool](Get-PlaywrightChromiumExe -Pattern (Get-Tier3ChromiumComponent))
}

# Install Chromium — the browser, its headless shell, ffmpeg, winldd — into the cache, for the
# RESOLVED version above. Always an exact version, never the range: `cmd.exe /c` strips a bare `^`,
# so a range spec would silently degrade to the range's floor here (which is why resolution happens
# via `npm view` from PowerShell, where `^` survives quoting).
# `--with-deps` also pulls the OS-level libraries the browser needs, on every platform including
# Windows. That step can exit non-zero on its own (it wants elevation to touch system packages),
# which would block a run over deps the machine may well already have — so we retry the plain
# install: a browser without the extra OS deps still satisfies the gate, no browser does not.
# Hardened against the failure that silently truncated release runs at epic 1:
#   * clears a stale __dirlock + orphan zips first (Clear-PlaywrightInstallLock), so a previous
#     killed install can't block this one;
#   * serialises via a machine-wide mutex so our warm never races another warm on the global cache;
#   * requires a zero exit AND every component present AND the executable to actually exist
#     afterwards — "the install command ran" is not enough. Throws on any of these so the caller
#     blocks the run rather than starting it on a machine whose browser fails at the first gate.
function Install-PlaywrightChromium {
    $ver = Get-Tier3PlaywrightVersion

    $mutex = $null; $owned = $false
    try { $mutex = New-Object System.Threading.Mutex($false, 'Global\Tier3PlaywrightInstall') }
    catch { $mutex = $null }   # e.g. Global\ not permitted here — proceed without the cross-session guard
    try {
        if ($mutex) {
            try { $owned = $mutex.WaitOne([TimeSpan]::FromMinutes(15)) }
            catch [System.Threading.AbandonedMutexException] { $owned = $true }   # prior holder died; we own it now
        }

        # Ask for the OS deps first, then retry without them if that step is refused.
        $err = $null
        foreach ($argList in @(@('install', '--with-deps', 'chromium'), @('install', 'chromium'))) {
            $cmd = "npx --yes @playwright/test@$ver $($argList -join ' ')"
            Clear-PlaywrightInstallLock                   # drop any stale lock/zip before we start
            if ($IsWindows) { & cmd.exe /c "$cmd" 2>&1 | Out-Null }
            else            { & npx --yes "@playwright/test@$ver" @argList 2>&1 | Out-Null }
            $exit = $LASTEXITCODE
            Clear-PlaywrightInstallLock                   # don't leave a lock behind for the next run
            if ($exit -eq 0) { $err = $null; break }
            $err = "``$cmd`` exited $exit"
        }

        if ($err) { throw $err }
        $missing = @(Get-MissingPlaywrightComponents)
        if ($missing.Count) {
            throw "the install reported success but these components are still missing under $(Get-PlaywrightCacheDir): $($missing -join ', ')"
        }
        if (-not (Get-PlaywrightChromiumExe -Pattern (Get-Tier3ChromiumComponent))) {
            throw "the install reported success but no Chromium executable is present in $(Get-Tier3ChromiumComponent) under $(Get-PlaywrightCacheDir)"
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
# -TemplateRoot is the template this run builds against: it decides WHICH Playwright browser must
# be cached, read from that app's lockfile. Omit it and the range decides, as before.
function Get-Tier3Prerequisites {
    [CmdletBinding()]
    param([bool]$IncludeTier3 = $true, [string]$TemplateRoot)

    if ($TemplateRoot) { Set-Tier3TemplateRoot -Path $TemplateRoot }

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
        # present the run is blocked rather than started and left to stall. "Present" means EVERY
        # component of the version the app resolves is cached and marked complete AND the browser
        # holds a real executable, so the gate launches from the cache instead of fetching.
        $pwMissing = @(Get-MissingPlaywrightComponents)
        $chromium  = Test-PlaywrightChromium
        # Name the @playwright/test version the build resolved to, not just the cached dirs: when a
        # warm targets the wrong version this line is what shows it at a glance in setup.log.
        $pwVer     = if ($chromium) { "for @playwright/test $(Get-Tier3PlaywrightVersion) — cached: $((Get-Tier3BrowserComponents) -join ', ')" } else { $null }
        $items.Add(@{ name = 'Playwright browser (Chromium)'; present = $chromium; version = $pwVer; requiredFor = 'the epic-end Playwright (e2e) gate in Tier 3 live runs'; installable = $true; hint = "npx --yes @playwright/test@$(Get-Tier3PlaywrightVersion) install --with-deps chromium  (missing: $($pwMissing -join ', '))"; install = { Install-PlaywrightChromium }; verify = { Test-PlaywrightChromium } })
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
        [string]$LogPath,
        [string]$TemplateRoot
    )
    $log = [System.Collections.Generic.List[string]]::new()
    $add = { param($m) $log.Add($m); Write-Verbose $m }

    # Aim the Playwright check at the template we're about to build, so the browser we warm is the
    # one THAT app's lockfile pins. Without it we'd warm whatever the range resolves to newest.
    if ($TemplateRoot) { Set-Tier3TemplateRoot -Path $TemplateRoot }

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
