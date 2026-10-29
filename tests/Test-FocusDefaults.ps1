[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$VerifiedGame)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 3.0
$root=Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'payload\DominionWarsFocus.psm1') -Force
$script:checks=0
function Assert([bool]$Pass,[string]$Message) {
    if (-not $Pass) { throw "FAIL: $Message" }
    $script:checks++; Write-Host "PASS: $Message"
}
$gameHash='03C20A3535D0209111FF9F3B90EBA403E059DF2BE7E784D2746ABF1535C1BE6A'
Assert ((Resolve-DominionWarsFocusMode -ExecutableHash $gameHash).Mode -eq 'Enabled') 'Normal Auto selection enables focus/capture for the known game'
foreach ($mode in @('Enabled','Experimental')) {
    Assert ((Resolve-DominionWarsFocusMode -Requested $mode -ExecutableHash $gameHash).Mode -eq 'Enabled') "$mode explicitly selects the same focus support"
}
Assert ((Resolve-DominionWarsFocusMode -Requested Baseline -ExecutableHash $gameHash).Mode -eq 'Baseline') 'Explicit stock compatibility remains available'
Assert ((Resolve-DominionWarsFocusMode -ExecutableHash 'unknown').Mode -eq 'Baseline') 'Unknown executable never receives focus-specific hooks or memory reads'
Assert ((Resolve-DominionWarsFocusMode -ExecutableHash $gameHash -Width 1024 -Height 768).Mode -eq 'Baseline') 'Smaller driver fallback retains ordinary startup compatibility'
Assert ((Resolve-DominionWarsFocusMode -ExecutableHash $gameHash -VisualPreset Sharper).Mode -eq 'Baseline') 'Unvalidated visual/focus combinations retain stock behavior'
Assert ((Resolve-DominionWarsFocusMode -ExecutableHash $gameHash -ConfigureOnly).Mode -eq 'Baseline') 'Configuration-only commands do not start a focus session'
$rejected=$false
try { $null=Resolve-DominionWarsFocusMode -Requested Enabled -ExecutableHash 'unknown' } catch { $rejected=$true }
Assert $rejected 'Explicit support refuses an unknown executable rather than silently downgrading'
Assert ((Resolve-DominionWarsFocusMode -Requested Enabled -ExecutableHash 'unknown' -DiagnoseOnly).Mode -eq 'Baseline') 'Diagnostics can report an unsupported explicit focus request without mutations'

function Releases([uint32]$Mask,[bool]$Returning=$true,[bool]$Foreground=$true,[bool]$Alt=$false,[bool]$Win=$false,[int]$Samples=2) {
    @(Get-DominionWarsFocusKeyReleases -Mask $Mask -Returning $Returning -ForegroundMatches $Foreground -AltDown $Alt -WindowsDown $Win -StableSamples $Samples)
}
Assert (((Releases 0xc0) -join ',') -eq '18,91,92') 'Only stale Alt and Windows keys produce local releases'
Assert (@(Releases 0x130).Count -eq 0) 'Shift, Control and Apps state is untouched'
Assert (@(Releases 0xc0 $false).Count -eq 0) 'No input is generated on initial focus'
Assert (@(Releases 0xc0 $true $false).Count -eq 0) 'Other foreground applications never receive input'
Assert (@(Releases 0xc0 $true $true $true).Count -eq 0) 'Physically held Alt prevents recovery'
Assert (@(Releases 0xc0 $true $true $false $true).Count -eq 0) 'Physically held Windows key prevents recovery'
Assert (@(Releases 0xc0 $true $true $false $false 1).Count -eq 0) 'A stable focus return is required'

# Native API double: no actual windows, input, process memory or display changes.
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
public static class DominionWarsFocusInputNative
{
    public static uint ForegroundPid=123, WindowPid=123, Mask=0xc0;
    public static bool AltDown, WinDown, FailRead;
    public static int CloseCalls;
    public static readonly List<string> Messages=new List<string>();
    public static IntPtr OpenProcess(uint a,bool b,int c) { throw new Exception("Real process open must not occur in the fake fixture"); }
    public static bool ReadProcessMemory(IntPtr h,IntPtr a,byte[] b,UIntPtr s,out UIntPtr n) {
        Array.Copy(BitConverter.GetBytes(Mask),b,4); n=new UIntPtr(4); return !FailRead;
    }
    public static bool CloseHandle(IntPtr h) { CloseCalls++; return true; }
    public static IntPtr GetForegroundWindow() { return new IntPtr(1); }
    public static uint GetWindowThreadProcessId(IntPtr h,out uint pid) { pid=h.ToInt64()==1 ? ForegroundPid : WindowPid; return 1; }
    public static short GetAsyncKeyState(int k) { return (short)(((k==0x12||k==0xa4||k==0xa5)?AltDown:WinDown) ? -32768 : 0); }
    public static bool PostMessage(IntPtr h,uint m,IntPtr k,IntPtr f) { Messages.Add(m+":"+k.ToInt64()+":"+f.ToInt64()); return true; }
}
'@
$gamePath=Join-Path $VerifiedGame 'ds9dw.exe'
if ((Get-FileHash -LiteralPath $gamePath).Hash -ne $gameHash) { throw 'Fixture requires an original verified NA 1.04 game; it will not be launched.' }
$fakeProcess=[pscustomobject]@{ Id=123; HasExited=$false; MainWindowHandle=[IntPtr]2 }
$fakeProcess | Add-Member -MemberType ScriptMethod -Name Refresh -Value { }
function Session {
    [pscustomobject]@{ Process=$fakeProcess; GamePath=$gamePath; Handle=[IntPtr]7;
        SeenForeground=$false; LostFocus=$false; StableSamples=0; Disabled=$false }
}
function Tick($Session) {
    $messages=@(Update-DominionWarsFocusInputSession $Session)
    if ($Session.Disabled -and $messages.Count) { throw ($messages -join '; ') }
}
$session=Session
Tick $session
Assert ([DominionWarsFocusInputNative]::Messages.Count -eq 0) 'Actual polling implementation sends nothing at initial focus'
[DominionWarsFocusInputNative]::ForegroundPid=999; Tick $session
[DominionWarsFocusInputNative]::ForegroundPid=123; Tick $session
Assert ([DominionWarsFocusInputNative]::Messages.Count -eq 0) 'First foreground sample is not enough'
Tick $session
Assert (([DominionWarsFocusInputNative]::Messages -join ',') -eq '261:18:-1070071807,257:91:-1051000831,257:92:-1050935295') 'Polling queues exact game-only keyup messages with correct scan/release flags'
Tick $session
Assert ([DominionWarsFocusInputNative]::Messages.Count -eq 3) 'Completed return does not repeatedly inject keyups'
for ($cycle=0; $cycle -lt 40; $cycle++) {
    [DominionWarsFocusInputNative]::ForegroundPid=999; Tick $session
    [DominionWarsFocusInputNative]::ForegroundPid=123; Tick $session; Tick $session
}
Assert ([DominionWarsFocusInputNative]::Messages.Count -eq 123) 'Long sessions do not silently lose recovery after the research 32-return cap'
[DominionWarsFocusInputNative]::ForegroundPid=999; Tick $session
[DominionWarsFocusInputNative]::ForegroundPid=123
[DominionWarsFocusInputNative]::WinDown=$true; Tick $session; Tick $session
Assert ([DominionWarsFocusInputNative]::Messages.Count -eq 123) 'Polling preserves physically held Windows keys'
[DominionWarsFocusInputNative]::WinDown=$false
[DominionWarsFocusInputNative]::Mask=0
Tick $session; Tick $session
Assert ([DominionWarsFocusInputNative]::Messages.Count -eq 123) 'Clean game state needs no release messages'
[DominionWarsFocusInputNative]::ForegroundPid=999; Tick $session
[DominionWarsFocusInputNative]::ForegroundPid=123
[DominionWarsFocusInputNative]::FailRead=$true
Tick $session; $message=Update-DominionWarsFocusInputSession $session
Assert ($session.Disabled -and $message -match 'disabled' -and [DominionWarsFocusInputNative]::Messages.Count -eq 123) 'Read failures disable only keyboard assistance without sending input'
Stop-DominionWarsFocusInputSession $session; Stop-DominionWarsFocusInputSession $session
Assert ($session.Handle -eq [IntPtr]::Zero -and [DominionWarsFocusInputNative]::CloseCalls -eq 1) 'Read-only handle cleanup is idempotent'
$session=Session; $session.SeenForeground=$true; $session.LostFocus=$true; $session.StableSamples=1
[DominionWarsFocusInputNative]::FailRead=$false; [DominionWarsFocusInputNative]::Mask=0xc0
[DominionWarsFocusInputNative]::WindowPid=999
$null=Update-DominionWarsFocusInputSession $session
Assert ($session.Disabled -and [DominionWarsFocusInputNative]::Messages.Count -eq 123) 'Window ownership changes prevent input and disable assistance'
Stop-DominionWarsFocusInputSession $session
$rejected=$false
try { $null=Start-DominionWarsFocusInputSession -Process ([Diagnostics.Process]::GetCurrentProcess()) -GamePath $gamePath } catch { $rejected=$true }
Assert $rejected 'Production startup refuses to attach to an unrelated process'
$scriptText=Get-Content -LiteralPath (Join-Path $root 'payload\Launch-DominionWars.ps1') -Raw
Assert ($scriptText -match "\`$FocusMode = 'Auto'") 'PowerShell entry point defaults to automatic focus support'
$baselineText=Get-Content -LiteralPath (Join-Path $root 'payload\Play Dominion Wars - Baseline.cmd') -Raw
Assert ($baselineText -match '-FocusMode Baseline') 'Stock-compatibility command explicitly opts out'
Write-Host "PASS: $script:checks default focus and keyboard recovery checks; no game, input or display changes."
