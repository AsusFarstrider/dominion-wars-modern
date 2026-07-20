[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('Status', 'Install', 'Repair', 'Uninstall')]
    [string]$Action,

    [string]$SourcePath,

    [string]$MediaPath,

    [string]$PatchPath,

    [string]$CabExtractorPath,

    [string]$Destination = (Join-Path $env:LOCALAPPDATA 'Dominion Wars'),

    [switch]$NonInteractive,

    [switch]$NoDesktopShortcut
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:ProductVersion = '0.1.0-alpha'
$script:Exe101Hash = '62EB159F40CE580308130DD223ABF12A1EF9A00C2BD93B76ABEFF1FC1044CB25'
$script:Exe104Hash = '03C20A3535D0209111FF9F3B90EBA403E059DF2BE7E784D2746ABF1535C1BE6A'
$script:PatchHash = 'BB938C4CD1CC8484D5F14978065FB96431843A5304C5078D65F0C32706F904EC'
$script:CabExtractorHash = '1181AE0DADA52EA5A5990D11F966E5986BF0A01614D2D5E5AD63B7C79E29FA29'
$script:CabHashes = [ordered]@{
    'data1.hdr' = '36342573E789423B515E9492DEC33B2DF314BE93B2473CD74D88D890B204544A'
    'data1.cab' = 'A3A08ED1D8AC74FB70FE4D498C4C3BBFFF229F23E512B80A731F78BA8D3CD185'
    'data2.cab' = '89E03CDB1169C103811E44A6A45755954C1E5A450A08610E2CEF2A784DA98A5F'
}
$script:PayloadRoot = Join-Path $PSScriptRoot 'payload'
$script:ManagedNames = @(
    'ddraw.dll',
    'DDrawCompat-ds9dw.ini',
    'DDrawCompat-LICENSE.txt',
    'Launch-DominionWars.ps1',
    'Play Dominion Wars.cmd'
)

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($full)
    if ($full -eq $root) { return $root }
    return $full.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-GameVersion {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    $exe = Join-Path $GameRoot 'ds9dw.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        throw "No ds9dw.exe was found in '$GameRoot'."
    }

    $hash = Get-Sha256 $exe
    switch ($hash) {
        $script:Exe101Hash { return [pscustomobject]@{ Version = '1.01'; Hash = $hash } }
        $script:Exe104Hash { return [pscustomobject]@{ Version = '1.04'; Hash = $hash } }
        default { return [pscustomobject]@{ Version = 'unknown'; Hash = $hash } }
    }
}

function Assert-CompleteGameTree {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    $required = @(
        'ds9dw.exe',
        'binkw32.dll',
        'rs\Bolts\ds9blt.blt',
        'rs\Bolts\ds9dat.blt',
        'rs\Bolts\ds9media.blt',
        'rs\Missions\shipcapt.mis',
        'rs\Video\IntroDS9.bik'
    )
    $missing = @($required | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $GameRoot $_) -PathType Leaf)
    })
    if ($missing.Count -gt 0) {
        throw "The game tree is incomplete. Missing: $($missing -join ', ')"
    }
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Description
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description was not found: '$Path'."
    }
    $actual = Get-Sha256 $Path
    if ($actual -ne $Expected) {
        throw "$Description has an unexpected SHA-256 hash ($actual). Expected $Expected."
    }
}

function Find-RetailMedia {
    foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
        try {
            if (-not $drive.IsReady) { continue }
            if ($drive.DriveType -ne [System.IO.DriveType]::CDRom) { continue }
            $root = $drive.RootDirectory.FullName
            if ((Test-Path -LiteralPath (Join-Path $root 'data1.hdr') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $root 'data1.cab') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $root 'data2.cab') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $root 'rs') -PathType Container)) {
                return $root
            }
        }
        catch { continue }
    }
    return $null
}

function Select-File {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Filter
    )
    if ($NonInteractive) { return $null }
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = $Filter
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

function Resolve-OfficialPatchPath {
    param([string]$RequestedPath)

    if ($RequestedPath) { return Get-NormalizedPath $RequestedPath }
    $profile = [Environment]::GetFolderPath('UserProfile')
    $candidates = @(
        (Join-Path $PSScriptRoot 'ds9dw1to4.exe'),
        (Join-Path (Get-Location).Path 'ds9dw1to4.exe'),
        (Join-Path $profile 'Downloads\ds9dw1to4.exe'),
        (Join-Path ([Environment]::GetFolderPath('Desktop')) 'ds9dw1to4.exe')
    ) | Select-Object -Unique
    foreach ($candidate in $candidates) {
        if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and
            (Get-Sha256 $candidate) -eq $script:PatchHash) {
            return Get-NormalizedPath $candidate
        }
    }
    $selected = Select-File -Title 'Select the official Dominion Wars 1.04 patch' `
        -Filter 'Dominion Wars 1.04 patch (ds9dw1to4.exe)|ds9dw1to4.exe|Programs (*.exe)|*.exe'
    if (-not $selected) { throw 'The official 1.04 patch was not selected.' }
    return Get-NormalizedPath $selected
}

function Resolve-CabExtractorPath {
    param([string]$RequestedPath)

    $resolved = if ($RequestedPath) {
        Get-NormalizedPath $RequestedPath
    }
    else {
        Get-NormalizedPath (Join-Path $script:PayloadRoot 'tools\i6comp.exe')
    }
    Assert-FileHash -Path $resolved -Expected $script:CabExtractorHash `
        -Description 'Bundled InstallShield 6 cabinet extractor (i6comp v0.20)'
    return $resolved
}

function Invoke-CabExtraction {
    param(
        [Parameter(Mandatory = $true)][string]$Extractor,
        [Parameter(Mandatory = $true)][string]$Cabinet,
        [Parameter(Mandatory = $true)][int]$Index,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )
    & $Extractor e -o $Cabinet $Index $OutputPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
        throw "Cabinet extraction failed for file index $Index."
    }
}

function Invoke-OfficialPatch {
    param(
        [Parameter(Mandatory = $true)][string]$Patch,
        [Parameter(Mandatory = $true)][string]$GameRoot
    )

    Assert-FileHash -Path $Patch -Expected $script:PatchHash -Description 'Official 1.04 patch'
    Write-Host ''
    Write-Host 'The official Dominion Wars 1.04 updater will open now.' -ForegroundColor Cyan
    Write-Host 'Complete its prompts. The modernizer will verify the result afterward.'
    $process = Start-Process -FilePath $Patch -ArgumentList @(('"' + $GameRoot + '"')) `
        -WorkingDirectory $GameRoot -PassThru
    $process.WaitForExit()
    $process.Refresh()
    if ($process.ExitCode -ne 0) {
        throw "The official patch exited with code $($process.ExitCode)."
    }
    $game = Get-GameVersion $GameRoot
    if ($game.Version -ne '1.04') {
        throw "The patch did not produce the verified 1.04 executable (found $($game.Hash))."
    }
}

function New-GameTreeFromMedia {
    param(
        [Parameter(Mandatory = $true)][string]$MediaRoot,
        [Parameter(Mandatory = $true)][string]$Patch,
        [Parameter(Mandatory = $true)][string]$Extractor,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (Test-Path -LiteralPath $Target) {
        throw "Destination already exists: '$Target'."
    }
    foreach ($entry in $script:CabHashes.GetEnumerator()) {
        Assert-FileHash -Path (Join-Path $MediaRoot $entry.Key) -Expected $entry.Value `
            -Description "Retail disc $($entry.Key)"
    }
    if (-not (Test-Path -LiteralPath $Extractor -PathType Leaf)) {
        throw "InstallShield 6 cabinet extractor was not found: '$Extractor'."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $MediaRoot 'rs') -PathType Container)) {
        throw "The retail disc data directory was not found under '$MediaRoot'."
    }

    $parent = Split-Path -Parent $Target
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $stage = Join-Path $parent ('.dw-media-stage-' + [guid]::NewGuid().ToString('N'))
    $extract = Join-Path $stage '.cab-extract'
    try {
        New-Item -ItemType Directory -Path $stage,$extract | Out-Null
        Copy-Item -LiteralPath (Join-Path $MediaRoot 'rs') -Destination $stage -Recurse -Force
        if (Test-Path -LiteralPath (Join-Path $MediaRoot 'readme.txt')) {
            Copy-Item -LiteralPath (Join-Path $MediaRoot 'readme.txt') -Destination $stage
        }

        $cabinet = Join-Path $MediaRoot 'data1.cab'
        $cabFiles = @(
            @{ Index = 39; Name = 'ds9dw.exe' },
            @{ Index = 40; Name = 'binkw32.dll' },
            @{ Index = 41; Name = 'gizmolog.ico' },
            @{ Index = 42; Name = 'GameSpy.ico' },
            @{ Index = 47; Name = 'shipcapt.mis' }
        )
        foreach ($item in $cabFiles) {
            Invoke-CabExtraction -Extractor $Extractor -Cabinet $cabinet `
                -Index $item.Index -OutputPath (Join-Path $extract $item.Name)
        }
        foreach ($name in @('ds9dw.exe', 'binkw32.dll', 'gizmolog.ico', 'GameSpy.ico')) {
            Move-Item -LiteralPath (Join-Path $extract $name) -Destination (Join-Path $stage $name)
        }
        New-Item -ItemType Directory -Path (Join-Path $stage 'rs\Missions') -Force | Out-Null
        Move-Item -LiteralPath (Join-Path $extract 'shipcapt.mis') `
            -Destination (Join-Path $stage 'rs\Missions\shipcapt.mis')
        Remove-Item -LiteralPath $extract -Recurse -Force

        Assert-CompleteGameTree $stage
        $retail = Get-GameVersion $stage
        if ($retail.Version -ne '1.01') {
            throw "Media reconstruction did not produce the verified 1.01 executable ($($retail.Hash))."
        }
        Invoke-OfficialPatch -Patch $Patch -GameRoot $stage
        Assert-CompleteGameTree $stage
        Move-Item -LiteralPath $stage -Destination $Target
    }
    finally {
        if (Test-Path -LiteralPath $stage) {
            Remove-Item -LiteralPath $stage -Recurse -Force
        }
    }
}

function Get-StatePaths {
    param([Parameter(Mandatory = $true)][string]$GameRoot)
    $stateRoot = Join-Path $GameRoot '.dw-modernizer'
    return [pscustomobject]@{
        Root = $stateRoot
        Backups = Join-Path $stateRoot 'backups'
        Manifest = Join-Path $stateRoot 'state.json'
    }
}

function Read-State {
    param([Parameter(Mandatory = $true)][string]$GameRoot)
    $paths = Get-StatePaths $GameRoot
    if (-not (Test-Path -LiteralPath $paths.Manifest -PathType Leaf)) { return $null }
    return Get-Content -LiteralPath $paths.Manifest -Raw | ConvertFrom-Json
}

function Write-State {
    param(
        [Parameter(Mandatory = $true)][string]$GameRoot,
        [Parameter(Mandatory = $true)]$State
    )
    $paths = Get-StatePaths $GameRoot
    New-Item -ItemType Directory -Path $paths.Root -Force | Out-Null
    $temporary = "$($paths.Manifest).new"
    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $paths.Manifest -Force
}

function Copy-GameTreeTransactional {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )
    if (Test-Path -LiteralPath $Target) {
        throw "Destination already exists: '$Target'. Use that directory as SourcePath for an in-place install."
    }

    $parent = Split-Path -Parent $Target
    if (-not $parent) { throw "Destination must have a parent directory." }
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $stage = Join-Path $parent ('.dw-stage-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $stage | Out-Null
        Copy-Item -Path (Join-Path $Source '*') -Destination $stage -Recurse -Force
        Assert-CompleteGameTree $stage
        Move-Item -LiteralPath $stage -Destination $Target
    }
    finally {
        if (Test-Path -LiteralPath $stage) {
            Remove-Item -LiteralPath $stage -Recurse -Force
        }
    }
}

function Install-ManagedFiles {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    $paths = Get-StatePaths $GameRoot
    New-Item -ItemType Directory -Path $paths.Backups -Force | Out-Null
    $oldState = Read-State $GameRoot
    $records = @()

    foreach ($name in $script:ManagedNames) {
        $source = Join-Path $script:PayloadRoot $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Modernizer payload is incomplete: '$name' is missing."
        }
        $target = Join-Path $GameRoot $name
        $backupName = $null

        $oldRecord = $null
        if ($oldState) {
            $oldRecord = @($oldState.ManagedFiles | Where-Object { $_.Name -eq $name }) | Select-Object -First 1
        }

        if ($oldRecord) {
            if ($oldRecord.BackupName) {
                $backupName = [string]$oldRecord.BackupName
            }
        }
        elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            $backupName = $name + '.original'
            $backupPath = Join-Path $paths.Backups $backupName
            if (-not (Test-Path -LiteralPath $backupPath)) {
                Copy-Item -LiteralPath $target -Destination $backupPath
            }
        }

        Copy-Item -LiteralPath $source -Destination $target -Force
        $records += [pscustomobject]@{
            Name = $name
            InstalledHash = Get-Sha256 $target
            BackupName = $backupName
        }
    }

    return $records
}

function Install-DesktopShortcut {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop 'Dominion Wars.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $GameRoot 'Play Dominion Wars.cmd'
    $shortcut.WorkingDirectory = $GameRoot
    $icon = Join-Path $GameRoot 'ds9dw.exe'
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Description = 'Launch Dominion Wars with modern Windows compatibility fixes'
    $shortcut.Save()
    return $shortcutPath
}

function Show-Status {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) {
        [pscustomobject]@{ Destination = $GameRoot; GameVersion = 'not installed'; Modernizer = 'not installed' }
        return
    }

    try { $game = Get-GameVersion $GameRoot } catch { $game = [pscustomobject]@{ Version = 'not detected'; Hash = $null } }
    $state = Read-State $GameRoot
    $managedStatus = if ($state) { 'installed ' + $state.ModernizerVersion } else { 'not installed' }
    [pscustomobject]@{
        Destination = $GameRoot
        GameVersion = $game.Version
        ExecutableHash = $game.Hash
        Modernizer = $managedStatus
    }
}

$destinationPath = Get-NormalizedPath $Destination

switch ($Action) {
    'Status' {
        Show-Status $destinationPath
    }

    'Install' {
        if (-not $SourcePath -and -not $MediaPath) {
            $MediaPath = Find-RetailMedia
            if ($MediaPath) {
                Write-Host "Detected Dominion Wars retail media at '$MediaPath'." -ForegroundColor Cyan
            }
        }
        if ([bool]$SourcePath -eq [bool]$MediaPath) {
            throw 'Install requires one source: a verified -SourcePath or mounted original -MediaPath. No retail media was auto-detected.'
        }

        if ($MediaPath) {
            $media = Get-NormalizedPath $MediaPath
            $patch = Resolve-OfficialPatchPath $PatchPath
            $extractor = Resolve-CabExtractorPath $CabExtractorPath
            if ($PSCmdlet.ShouldProcess($destinationPath, "Reconstruct and patch Dominion Wars from '$media'")) {
                New-GameTreeFromMedia -MediaRoot $media -Patch $patch `
                    -Extractor $extractor -Target $destinationPath
            }
        }
        else {
            $source = Get-NormalizedPath $SourcePath
            Assert-CompleteGameTree $source
            $sourceGame = Get-GameVersion $source
            if ($sourceGame.Version -eq '1.01') {
                throw 'A 1.01 installed tree is not yet accepted directly; use -MediaPath or update it to 1.04 first.'
            }
            if ($sourceGame.Version -ne '1.04') {
                throw "Unrecognized ds9dw.exe (SHA-256 $($sourceGame.Hash)). Refusing to overwrite it."
            }

            if ($source -ne $destinationPath) {
                if ($PSCmdlet.ShouldProcess($destinationPath, "Copy verified Dominion Wars 1.04 from '$source'")) {
                    Copy-GameTreeTransactional -Source $source -Target $destinationPath
                }
            }
        }

        if ($WhatIfPreference) { return }

        Assert-CompleteGameTree $destinationPath
        if ($PSCmdlet.ShouldProcess($destinationPath, 'Install Dominion Wars modern compatibility files')) {
            $records = Install-ManagedFiles $destinationPath
            $shortcutPath = $null
            if (-not $NoDesktopShortcut) { $shortcutPath = Install-DesktopShortcut $destinationPath }
            $state = [ordered]@{
                SchemaVersion = 1
                ModernizerVersion = $script:ProductVersion
                InstalledUtc = [DateTime]::UtcNow.ToString('o')
                GameVersion = '1.04'
                GameExecutableHash = $script:Exe104Hash
                Destination = $destinationPath
                DesktopShortcut = $shortcutPath
                ManagedFiles = $records
            }
            Write-State -GameRoot $destinationPath -State $state
        }
        Show-Status $destinationPath
    }

    'Repair' {
        Assert-CompleteGameTree $destinationPath
        $game = Get-GameVersion $destinationPath
        if ($game.Version -ne '1.04') {
            throw "Repair requires the verified 1.04 executable; found $($game.Version) ($($game.Hash))."
        }
        if (-not (Read-State $destinationPath)) { throw 'The modernizer is not installed in this directory.' }
        if ($PSCmdlet.ShouldProcess($destinationPath, 'Repair Dominion Wars modern compatibility files')) {
            $records = Install-ManagedFiles $destinationPath
            $state = Read-State $destinationPath
            $state.ManagedFiles = $records
            $state.ModernizerVersion = $script:ProductVersion
            $state | Add-Member -NotePropertyName RepairedUtc `
                -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
            Write-State -GameRoot $destinationPath -State $state
        }
        Show-Status $destinationPath
    }

    'Uninstall' {
        $state = Read-State $destinationPath
        if (-not $state) { throw 'The modernizer is not installed in this directory.' }
        $paths = Get-StatePaths $destinationPath
        if ($PSCmdlet.ShouldProcess($destinationPath, 'Remove the modernizer and restore replaced files')) {
            foreach ($record in $state.ManagedFiles) {
                $target = Join-Path $destinationPath ([string]$record.Name)
                $backup = if ($record.BackupName) { Join-Path $paths.Backups ([string]$record.BackupName) } else { $null }
                if ($backup -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
                    Copy-Item -LiteralPath $backup -Destination $target -Force
                }
                elseif (Test-Path -LiteralPath $target -PathType Leaf) {
                    $currentHash = Get-Sha256 $target
                    if ($currentHash -eq [string]$record.InstalledHash) {
                        Remove-Item -LiteralPath $target -Force
                    }
                    else {
                        Write-Warning "Keeping modified managed file: $target"
                    }
                }
            }
            if ($state.DesktopShortcut -and (Test-Path -LiteralPath ([string]$state.DesktopShortcut))) {
                Remove-Item -LiteralPath ([string]$state.DesktopShortcut) -Force
            }
            Remove-Item -LiteralPath $paths.Root -Recurse -Force
        }
        Show-Status $destinationPath
    }
}
