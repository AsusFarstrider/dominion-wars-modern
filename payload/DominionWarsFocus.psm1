Set-StrictMode -Version 3.0

$script:BaselineHash = 'F75F0AC48D2782F225C483DC2F1142303A513E8DD8A60793891ADE89F64755EA'
$script:FocusHash = '3AA11B1C81A21C6EF5FB85D2DC31DEEC7EB8217F637094E9ED7B9F6D6BC90490'
$script:GameHash = '03C20A3535D0209111FF9F3B90EBA403E059DF2BE7E784D2746ABF1535C1BE6A'

function Resolve-DominionWarsFocusMode {
    param(
        [ValidateSet('Auto','Enabled','Baseline','Experimental')][string]$Requested = 'Auto',
        [string]$ExecutableHash,
        [string]$VisualPreset = 'Baseline',
        [int]$Width = 1280,
        [int]$Height = 960,
        [switch]$ConfigureOnly,
        [switch]$DiagnoseOnly
    )
    $reason = $null
    if ($Requested -eq 'Baseline') { $reason = 'Stock compatibility explicitly selected.' }
    elseif ($ConfigureOnly) { $reason = 'Configuration-only operation; no per-run focus changes.' }
    elseif ($ExecutableHash -ne $script:GameHash) { $reason = 'Focus support requires the verified North American 1.04 executable.' }
    elseif ($VisualPreset -ne 'Baseline') { $reason = 'Visual presets retain stock focus behavior; combined use is not validated.' }
    elseif ($Width -ne 1280 -or $Height -ne 960) { $reason = 'Focus support requires a driver-tested 1280x960 initialization mode.' }
    if ($reason -and -not $DiagnoseOnly -and $Requested -in @('Enabled','Experimental')) { throw $reason }
    [pscustomobject]@{ Mode = if ($reason) { 'Baseline' } else { 'Enabled' }; Reason = $reason }
}

function Get-DominionWarsFocusKeyReleases {
    param([uint32]$Mask, [bool]$Returning, [bool]$ForegroundMatches,
        [bool]$AltDown, [bool]$WindowsDown, [int]$StableSamples)
    # Never release keys on initial focus, into another app, or while physically held.
    if (-not $Returning -or -not $ForegroundMatches -or $AltDown -or $WindowsDown -or $StableSamples -lt 2) { return }
    if ($Mask -band 0x40) { 0x12 }
    if ($Mask -band 0x80) { 0x5b; 0x5c }
}

function Initialize-DominionWarsFocusInput {
    if ('DominionWarsFocusInputNative' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DominionWarsFocusInputNative
{
    [DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern bool ReadProcessMemory(IntPtr handle, IntPtr address, byte[] bytes, UIntPtr size, out UIntPtr read);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool PostMessage(IntPtr window, uint message, IntPtr key, IntPtr flags);
}
'@
}

function Start-DominionWarsFocusInputSession {
    param([Parameter(Mandatory=$true)][Diagnostics.Process]$Process,
        [Parameter(Mandatory=$true)][string]$GamePath)
    Initialize-DominionWarsFocusInput
    $Process.Refresh()
    $fullPath = [IO.Path]::GetFullPath($GamePath)
    if ($Process.HasExited -or $Process.SessionId -ne [Diagnostics.Process]::GetCurrentProcess().SessionId -or
        -not [string]::Equals($Process.MainModule.FileName,$fullPath,[StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($fullPath) -ine 'ds9dw.exe' -or
        $Process.MainModule.BaseAddress.ToInt64() -ne 0x400000 -or
        (Get-FocusFileHash $fullPath) -ne $script:GameHash) { throw 'Focus input recovery refused an unrecognized game process.' }
    # Query/read rights only. No memory writes, global keyboard hooks or SendInput.
    $handle = [DominionWarsFocusInputNative]::OpenProcess(0x1010,$false,$Process.Id)
    if ($handle -eq [IntPtr]::Zero) { throw 'Read-only game input access unavailable; keyboard recovery disabled.' }
    [pscustomobject]@{ Process=$Process; GamePath=$fullPath; Handle=$handle;
        SeenForeground=$false; LostFocus=$false; StableSamples=0; Disabled=$false }
}

function Update-DominionWarsFocusInputSession {
    param([Parameter(Mandatory=$true)]$Session)
    if ($Session.Disabled -or $Session.Process.HasExited) { return }
    try {
        [uint32]$foregroundPid=0
        $foreground=[DominionWarsFocusInputNative]::GetForegroundWindow()
        $null=[DominionWarsFocusInputNative]::GetWindowThreadProcessId($foreground,[ref]$foregroundPid)
        if ($foregroundPid -ne $Session.Process.Id) {
            if ($Session.SeenForeground) { $Session.LostFocus=$true }
            $Session.StableSamples=0
            return
        }
        $Session.SeenForeground=$true
        if (-not $Session.LostFocus) { return }
        $altDown=([DominionWarsFocusInputNative]::GetAsyncKeyState(0x12) -band 0x8000) -or
            ([DominionWarsFocusInputNative]::GetAsyncKeyState(0xa4) -band 0x8000) -or
            ([DominionWarsFocusInputNative]::GetAsyncKeyState(0xa5) -band 0x8000)
        $windowsDown=([DominionWarsFocusInputNative]::GetAsyncKeyState(0x5b) -band 0x8000) -or
            ([DominionWarsFocusInputNative]::GetAsyncKeyState(0x5c) -band 0x8000)
        if ($altDown -or $windowsDown) { $Session.StableSamples=0; return }
        $Session.StableSamples++
        if ($Session.StableSamples -lt 2) { return }
        $bytes=New-Object byte[] 4; $read=[UIntPtr]::Zero; $size=New-Object UIntPtr ([uint32]4)
        if (-not [DominionWarsFocusInputNative]::ReadProcessMemory($Session.Handle,[IntPtr]0x719618,$bytes,$size,[ref]$read) -or
            $read.ToUInt64() -ne 4) { throw 'Could not read the game modifier state.' }
        $mask=[BitConverter]::ToUInt32($bytes,0)
        $keys=@(Get-DominionWarsFocusKeyReleases -Mask $mask -Returning $true -ForegroundMatches $true `
            -AltDown $altDown -WindowsDown $windowsDown -StableSamples $Session.StableSamples)
        if ($keys.Count) {
            $Session.Process.Refresh()
            $window=$Session.Process.MainWindowHandle
            [uint32]$windowPid=0
            $null=[DominionWarsFocusInputNative]::GetWindowThreadProcessId($window,[ref]$windowPid)
            if ($window -eq [IntPtr]::Zero -or $windowPid -ne $Session.Process.Id -or
                (Get-FocusFileHash $Session.GamePath) -ne $script:GameHash) { throw 'Focus input window or executable identity changed.' }
            foreach ($key in $keys) {
                # Recheck focus and physical keys immediately before each local message.
                [uint32]$checkPid=0
                $null=[DominionWarsFocusInputNative]::GetWindowThreadProcessId([DominionWarsFocusInputNative]::GetForegroundWindow(),[ref]$checkPid)
                $altDown=([DominionWarsFocusInputNative]::GetAsyncKeyState(0x12) -band 0x8000) -or
                    ([DominionWarsFocusInputNative]::GetAsyncKeyState(0xa4) -band 0x8000) -or
                    ([DominionWarsFocusInputNative]::GetAsyncKeyState(0xa5) -band 0x8000)
                $windowsDown=([DominionWarsFocusInputNative]::GetAsyncKeyState(0x5b) -band 0x8000) -or
                    ([DominionWarsFocusInputNative]::GetAsyncKeyState(0x5c) -band 0x8000)
                if ($checkPid -ne $Session.Process.Id -or $altDown -or $windowsDown) { $Session.StableSamples=0; return }
                $null=[DominionWarsFocusInputNative]::GetWindowThreadProcessId($window,[ref]$windowPid)
                if ($Session.Process.HasExited -or $windowPid -ne $Session.Process.Id) { throw 'Game window ownership changed before key release.' }
                $message=0x101; $flags=if ($key -eq 0x5b) { -1051000831 } else { -1050935295 }
                if ($key -eq 0x12) { $message=0x105; $flags=-1070071807 }
                if (-not [DominionWarsFocusInputNative]::PostMessage($window,$message,[IntPtr]$key,[IntPtr]$flags)) { throw 'Game-only key-release message was refused.' }
            }
            'Focus return: repaired stale game modifier mask 0x{0:X} with game-only key releases.' -f ($mask -band 0xc0)
        }
        $Session.LostFocus=$false; $Session.StableSamples=0
    }
    catch {
        $Session.Disabled=$true
        "Focus keyboard recovery disabled for this run: $($_.Exception.Message)"
    }
}

function Stop-DominionWarsFocusInputSession {
    param($Session)
    if ($Session -and $Session.Handle -ne [IntPtr]::Zero) {
        $null=[DominionWarsFocusInputNative]::CloseHandle($Session.Handle)
        $Session.Handle=[IntPtr]::Zero
        $Session.Disabled=$true
    }
}

function Get-FocusFileHash {
    param([string]$Path)
    $stream=[IO.File]::OpenRead($Path)
    $algorithm=[Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','') }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}

function Write-FocusRecord {
    param([string]$Path,$State)
    $State.UpdatedUtc=[DateTime]::UtcNow.ToString('o')
    $temporary=$Path+'.new'
    $existing=Get-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
    if ($existing -and ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Redirected focus record temporary file rejected.' }
    [IO.File]::WriteAllText($temporary,($State | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Get-DominionWarsFocusEnvironmentNames {
    @('DW_EXPERIMENTAL_FOCUS_GUARD','DW_EXPERIMENTAL_FOCUS_DESKTOP','DW_FOCUS_DEVICE','DW_FOCUS_DEVICE_IDENTITY','DW_FOCUS_ORIGINAL_MODE')
}

function ConvertTo-DominionWarsFocusSnapshot {
    param([Parameter(Mandatory=$true)]$Mode)
    $size = [Runtime.InteropServices.Marshal]::SizeOf($Mode)
    if ($size -ne 220 -or $Mode.dmSize -ne 220 -or $Mode.dmDriverExtra -ne 0) {
        throw 'Experimental Alt+Tab requires a complete 220-byte DEVMODEW without private driver data. Use the normal launcher instead.'
    }
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal($size)
    try {
        $bytes = New-Object byte[] $size
        [Runtime.InteropServices.Marshal]::Copy($bytes, 0, $pointer, $size)
        [Runtime.InteropServices.Marshal]::StructureToPtr($Mode, $pointer, $false)
        [Runtime.InteropServices.Marshal]::Copy($pointer, $bytes, 0, $size)
        return [BitConverter]::ToString($bytes).Replace('-', '')
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer) }
}

function Assert-FocusPath {
    param([string]$GameRoot, [string]$BackupId)
    if ($BackupId -notmatch '^[a-f0-9]{32}$') { throw 'Invalid experimental Alt+Tab recovery identifier.' }
    $path = $GameRoot
    foreach ($part in @('.dw-launcher','focus-backups',$BackupId)) {
        $path = Join-Path $path $part
        if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Experimental Alt+Tab recovery refuses redirected backup directories.'
        }
    }
    return $path
}

function Copy-FocusFileAtomic {
    param([string]$Source, [string]$Target, [string]$BackupRoot)
    $temporary = Join-Path $BackupRoot ([guid]::NewGuid().ToString('N') + '.swap')
    try {
        Copy-Item -LiteralPath $Source -Destination $temporary
        # All files stay on the game volume. Replace is atomic and refuses a
        # missing destination, preserving deliberate deletions during recovery.
        [IO.File]::Replace($temporary, $Target, [NullString]::Value)
    }
    finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
}

function Restore-DominionWarsFocusSession {
    param([Parameter(Mandatory=$true)][string]$GameRoot, [switch]$AllowConflicts)
    $recordPath = Join-Path $GameRoot '.dw-launcher\focus-session.json'
    if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) { return $null }
    if ((Get-Item -LiteralPath $recordPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected focus recovery record rejected.' }
    $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    if ($record.SchemaVersion -ne 1 -or $record.Phase -notin @('Prepared','Applied')) { throw 'Unrecognized experimental Alt+Tab recovery record.' }
    $backupRoot = Assert-FocusPath -GameRoot $GameRoot -BackupId $record.BackupId
    $specs = @(
        @{ Name='ddraw.dll'; Backup='original-ddraw.dll'; Original=$record.OriginalWrapperHash; Applied=$record.AppliedWrapperHash },
        @{ Name='DDrawCompat-ds9dw.ini'; Backup='original.ini'; Original=$record.OriginalProfileHash; Applied=$record.AppliedProfileHash }
    )
    if ($record.OriginalWrapperHash -ne $script:BaselineHash -or $record.AppliedWrapperHash -ne $script:FocusHash) { throw 'Unexpected focus recovery wrapper identities.' }
    # Validate every backup before restoring either file.
    foreach ($spec in $specs) {
        $backup = Join-Path $backupRoot $spec.Backup
        if ($spec.Original -notmatch '^[A-Fa-f0-9]{64}$' -or $spec.Applied -notmatch '^[A-Fa-f0-9]{64}$' -or
            -not (Test-Path -LiteralPath $backup -PathType Leaf) -or
            ((Get-Item -LiteralPath $backup -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -or
            (Get-FocusFileHash $backup) -ne $spec.Original) { throw 'Experimental Alt+Tab backup is missing or changed; refusing recovery.' }
    }
    $conflicts = @()
    foreach ($spec in $specs) {
        $target = Join-Path $GameRoot $spec.Name
        $current = if (Test-Path -LiteralPath $target -PathType Leaf) { Get-FocusFileHash $target } else { $null }
        if ($current -eq $spec.Applied -and $current -ne $spec.Original) {
            if ((Get-Item -LiteralPath $target -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected focus target rejected.' }
            Copy-FocusFileAtomic -Source (Join-Path $backupRoot $spec.Backup) -Target $target -BackupRoot $backupRoot
        }
        elseif ($current -ne $spec.Original) { $conflicts += $spec.Name }
    }
    if ($conflicts.Count) {
        Copy-Item -LiteralPath $recordPath -Destination (Join-Path $backupRoot 'conflict.json') -Force
        if (-not $AllowConflicts) { throw "Experimental Alt+Tab recovery preserved changed/deleted files: $($conflicts -join ', '). Run repair before launching; backups are at $backupRoot" }
    }
    Remove-Item -LiteralPath $recordPath
    return [pscustomobject]@{ BackupPath=$backupRoot; PreservedChanges=($conflicts.Count -gt 0); Conflicts=$conflicts }
}

function Start-DominionWarsFocusSession {
    param([Parameter(Mandatory=$true)][string]$GameRoot)
    $recordPath = Join-Path $GameRoot '.dw-launcher\focus-session.json'
    if (Test-Path -LiteralPath $recordPath) { throw 'Recover the unfinished experimental Alt+Tab session first.' }
    $wrapper = Join-Path $GameRoot 'ddraw.dll'
    $focus = Join-Path $GameRoot 'DDrawCompat-Focus.dll'
    $profile = Join-Path $GameRoot 'DDrawCompat-ds9dw.ini'
    if ((Get-FocusFileHash (Join-Path $GameRoot 'ds9dw.exe')) -ne $script:GameHash) { throw 'Experimental Alt+Tab supports only the verified North American 1.04 executable.' }
    if ((Get-FocusFileHash $wrapper) -ne $script:BaselineHash -or (Get-FocusFileHash $focus) -ne $script:FocusHash) { throw 'Unexpected experimental or baseline wrapper. Run repair first.' }
    foreach ($file in @($wrapper,$focus,$profile)) {
        if ((Get-Item -LiteralPath $file -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Experimental Alt+Tab refuses redirected compatibility files.' }
        $handle = [IO.File]::Open($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $handle.Dispose()
    }
    $id = [guid]::NewGuid().ToString('N')
    $backupRoot = Assert-FocusPath -GameRoot $GameRoot -BackupId $id
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Copy-Item -LiteralPath $wrapper -Destination (Join-Path $backupRoot 'original-ddraw.dll')
    Copy-Item -LiteralPath $profile -Destination (Join-Path $backupRoot 'original.ini')
    $text = [IO.File]::ReadAllText($profile)
    $pattern = '(?im)^[\t ]*AltTabFix[\t ]*=.*$'
    if ([regex]::IsMatch($text,$pattern)) { $text = [regex]::Replace($text,$pattern,'AltTabFix = noactivateapp(0)') }
    else { $text = $text.TrimEnd() + "`r`nAltTabFix = noactivateapp(0)`r`n" }
    $appliedProfile = Join-Path $backupRoot 'applied.ini'
    [IO.File]::WriteAllText($appliedProfile,$text,(New-Object Text.UTF8Encoding($false)))
    $record = [pscustomobject]@{
        SchemaVersion=1; Phase='Prepared'; BackupId=$id; UpdatedUtc=''
        OriginalWrapperHash=Get-FocusFileHash $wrapper; AppliedWrapperHash=$script:FocusHash
        OriginalProfileHash=Get-FocusFileHash $profile; AppliedProfileHash=Get-FocusFileHash $appliedProfile
    }
    Write-FocusRecord -Path $recordPath -State $record
    try {
        Copy-FocusFileAtomic -Source $focus -Target $wrapper -BackupRoot $backupRoot
        Copy-FocusFileAtomic -Source $appliedProfile -Target $profile -BackupRoot $backupRoot
        $record.Phase='Applied'; Write-FocusRecord -Path $recordPath -State $record
    }
    catch { $null=Restore-DominionWarsFocusSession -GameRoot $GameRoot; throw }
    return $record
}

Export-ModuleMember -Function Resolve-DominionWarsFocusMode, Get-DominionWarsFocusKeyReleases, Initialize-DominionWarsFocusInput, Start-DominionWarsFocusInputSession, Update-DominionWarsFocusInputSession, Stop-DominionWarsFocusInputSession, Get-DominionWarsFocusEnvironmentNames, ConvertTo-DominionWarsFocusSnapshot, Start-DominionWarsFocusSession, Restore-DominionWarsFocusSession
