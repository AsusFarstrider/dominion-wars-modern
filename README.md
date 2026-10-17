# Dominion Wars Modernizer

Dominion Wars Modernizer is a reversible installer and launcher intended to help
owners of the North American retail release of *Star Trek: Deep Space Nine –
Dominion Wars* run the game on current Windows hardware. It reconstructs a clean
installation from the user's own CD or a mounted image of that CD, applies compatibility components, and
launches the game in the display environment required by its legacy input and
rendering code.

> [!WARNING]
> **This is an early alpha release.** It has been validated on only one primary
> system and a small number of campaign missions. It may fail on other GPUs,
> driver versions, Windows builds, monitor layouts, or regional game editions.
> The game is not claimed to be fully fixed, and universal Windows 10/11
> compatibility has not been established. Back up saves and keep your original
> media available.

## Validated configuration

The **0.5.0-alpha prerelease** adds a separately selected experimental Alt+Tab
launcher. The normal shortcut keeps stock DDrawCompat and the baseline behavior.
New-system testers should follow the [clean-install testing guide](docs/NEW-SYSTEM-TESTING.md).

The **0.6.0-alpha prerelease** is an installer-only reliability
update. It adds stage/activity reporting, persistent installation logs and an
isolated cabinet extractor. The first physical-CD test completed successfully
after Esc released a console-selection pause near the shortcut stage. The next
candidate adds a temporary console QuickEdit safeguard. The user-reported
click/focus test passed on the Windows 10 machine, with uninterrupted log updates
and exact console-mode restoration. The download instructions below refer to 0.6.0-alpha.

The current known-good result is limited to:

| Component | Validated configuration |
|---|---|
| Game media | North American retail disc |
| Game version | Official 1.04 patch applied |
| Operating system | Windows 11, build 10.0.26200 |
| GPU | AMD Radeon RX 6800 XT, driver 32.0.21043.19003 |
| Displays | Three monitors: one 2560×1440 and two 1920×1080 |
| Launcher profile | Temporary 1280×960 initialization mode |
| Gameplay | Single-player: three sequential missions completed; fourth played until defeat |

The game engine itself still requests 800×600 internally. The validated
1280×960 setting is the launcher's initialization environment, not an upgraded
native game resolution. DDrawCompat can return the physical display to the normal
desktop resolution during startup; this was confirmed on the known system while
investigating Alt+Tab. Do not assume the physical display stays at 1280×960.

A short startup/exit regression with the updated launcher also passed on Windows
11 build 26300 and AMD driver 32.0.21045.5002. That is not equivalent to the
longer gameplay validation above; see [TESTING.md](TESTING.md) for the distinction.
The 0.4.0-alpha candidate has also had a short baseline gameplay test on that
newer build/driver, but Alt+Tab failed. Controlled launcher-termination and
orphaned-desktop recovery checks passed on this system; fallback-mode gameplay
and broader NVIDIA/Intel coverage still need testing.
The 0.4.0-alpha candidate adds optional per-run visual/resource-saving presets;
these also have automated checks only, not verified image-quality or performance gains.

A second-system **0.5.0-alpha smoke test** reached the first mission briefly on
Windows 10 Home build 19045, an Intel i5-3570K and NVIDIA GeForce GTX 670
(driver 30.0.14.7514). The physical-CD installation stalled after media detection
and only continued after the user pressed Ctrl+C. This is evidence of gameplay
startup on that configuration, not a clean installer pass or long-session
stability validation. The installer stall is being addressed in development;
Ctrl+C is not a recommended workaround.

## What this installer does

The installer:

- detects the owner's original Dominion Wars CD or a disc image mounted as a
  Windows CD/DVD drive;
- verifies the known North American retail cabinet files;
- reconstructs the installation directly from those cabinets because the
  original InstallShield installer is unreliable on modern 64-bit Windows;
- opens the user-supplied official 1.04 patch and waits while the user completes
  its normal prompts;
- verifies that patching produced the known 1.04 executable;
- installs DDrawCompat 0.7.1 and the game-specific compatibility settings;
- creates a launcher and a desktop shortcut named `Dominion Wars`;
- tests display modes, temporarily changes the primary desktop to 1280×960
  (or a supported narrower fallback) for startup, and attempts to restore
  the prior display mode afterward, including after a game failure;
- starts a separate recovery helper before changing the display, to attempt
  restoration if the launcher dies while the game is running; and
- supports compatibility-file repair and removal.

Installation is staged in a temporary directory. A failed or cancelled media
reconstruction is not committed as the destination installation.

## What this project does not include

This repository ships:

- no Dominion Wars game assets;
- no official 1.04 game patch;
- no modified Dominion Wars executable; and
- no no-CD, copy-protection, or DRM bypass.

Users must provide legitimate original media and the official 1.04 patch. The
original disc remains required wherever the unmodified game requires it.

## Prerequisites

Before starting, have:

1. A legitimate North American Dominion Wars retail CD **or an image made from
   your own original CD**, mounted as a Windows CD/DVD drive. You do not need to
   use a physical drive when a suitable mounted image is available.
2. The North American official 1.04 patch, named `ds9dw1to4.exe`. The patch is not
   distributed here. A historical mirror is listed on the
   [TrekCore Dominion Wars downloads page](https://gaming.trekcore.com/dominionwars/downloads.html).
3. A 64-bit Intel/AMD Windows installation. Windows 11 is the only version
   currently validated; Windows 10 may work but is not yet confirmed.
   Windows on ARM has not been validated.
4. Permission to write to your own `%LOCALAPPDATA%` directory and create a
   desktop shortcut. Administrator rights are not normally required by the
   modernizer itself, although Windows may show security prompts for legacy or
   unsigned components.

The installer accepts only the verified North American disc and patch hashes.
Other editions are currently rejected rather than modified speculatively.

### Using a disc image

An image such as **ISO or BIN/CUE** can be used when your mounting tool exposes
the original disc contents as a virtual CD/DVD drive. Image-format support comes
from that tool, not this installer; a BIN image may need its accompanying CUE file.
The modernizer does not create or mount images and cannot install directly from
an unmounted `.iso`, `.bin` or `.cue` file.

After mounting, check File Explorer for the new CD/DVD drive and its disc files
(including `data1.cab` and `data2.cab`), then run the modernizer. **Any drive letter
is fine.** Keep the CD inserted or the image mounted during play wherever the
unmodified game requires its disc. No disc image is included in the download.

## Installation

1. Open the [0.6.0-alpha prerelease](https://github.com/AsusFarstrider/dominion-wars-modern/releases/tag/v0.6.0-alpha)
   and download its attached **`dominion-wars-modernizer-0.6.0-alpha.zip`** asset.
   Use that tested package rather than the automatically generated **Source code**
   ZIP or **Code → Download ZIP**.
2. Extract the downloaded ZIP completely. Do not run the installer from inside
   the compressed archive.
3. Insert the original CD **or mount an image of your own disc as a CD/DVD drive**.
   Confirm the drive is visible in File Explorer before continuing; do not select
   the raw image file as the installation source.
4. Put `ds9dw1to4.exe` either in the extracted modernizer folder or in your
   Downloads folder. If it is elsewhere, the installer will ask you to select it.
5. Double-click **`Install Dominion Wars.cmd`**.
6. If Windows warns about an unsigned script or legacy helper, inspect the file
   and publisher information before choosing whether to continue. Do not disable
   antivirus protection globally.
7. The official 1.04 updater will open. Complete its prompts normally. The
   modernizer will verify its output before finishing.
8. Wait for `Installation completed successfully` and close the command window.

The default installation directory is:

```text
%LOCALAPPDATA%\Dominion Wars
```

A `Dominion Wars` shortcut is created on the current user's desktop.
An existing shortcut with that name is backed up before replacement. Subsequent
repair/removal protects shortcuts you have edited.

Advanced users may inspect all supported parameters with:

```powershell
Get-Help .\DominionWarsModernizer.ps1 -Detailed
```

An existing, verified 1.04 installation can be modernized in place with an
explicit PowerShell command:

```powershell
.\DominionWarsModernizer.ps1 Install -SourcePath 'C:\Games\Dominion Wars' -Destination 'C:\Games\Dominion Wars'
```

## How to play

Start the game from the desktop shortcut named **Dominion Wars**. If the shortcut
is unavailable, run:

```text
%LOCALAPPDATA%\Dominion Wars\Play Dominion Wars.cmd
```

At startup, the screen will temporarily switch to 1280×960 if your display driver accepts
that mode. Otherwise the launcher tries 1024×768, 800×600, then 640×480. If none
works, it also considers real driver modes at least 800×600 with a width below
1600 pixels, including narrow widescreen modes. DDrawCompat preserves the game's
aspect ratio. All fallback sizes remain experimental, not additional validated
gameplay configurations. The launcher uses a driver-supported refresh rate, waits for the
game to finish, and attempts to restore the prior desktop mode in a `finally`
block. Use the launcher rather than starting `ds9dw.exe` directly; direct startup
bypasses this handling. DDrawCompat may return the physical display to your normal
desktop resolution before gameplay; the startup mode need not persist throughout
the session. Only one launcher can run at a time in a Windows session.

If a high-refresh display behaves poorly, **`Play Dominion Wars - 60 Hz.cmd`**
prefers a supported rate nearest 60 Hz for that run. It does not guarantee exact
60 Hz, and the normal shortcut continues to prefer the original desktop rate.

### Optional experimental Alt+Tab mode

After the normal launcher works, open the installed game folder (by default,
paste `%LOCALAPPDATA%\Dominion Wars` into File Explorer's address bar) and run
**`Play Dominion Wars - Experimental Alt-Tab.cmd`**. The desktop shortcut remains
the normal baseline; this alternative is selected separately for each run.

This uses a hash-verified, game-specific DDrawCompat build intended to minimize on
focus loss and restore the game through Alt+Tab or its taskbar icon. It passed a
short packaged regression on the known AMD system; Intel/NVIDIA and longer sessions still need
testing. **Pause manually before switching away: automatic pause does not work.**
Screenshot overlays use a heuristic exception and are not universally validated.

The alternative currently requires a driver-tested 1280×960 initialization mode,
the verified North American 1.04 executable, and baseline visual settings. It does
not combine with visual presets. It records the actual physical game mode; when
that already matches the original desktop, no resolution change is necessary.
Actual different-resolution return remains unvalidated.

It temporarily swaps the DLL/profile and restores exact original bytes after
exit. Verified backups remain in `.dw-launcher\focus-backups`. A non-diagnostic
launch recovers an interrupted swap before starting; later file changes/deletions
are preserved and block launch until repaired. Close the game, back up intentional
customizations and use **`Repair Dominion Wars.cmd`** from the extracted package.
If repair also refuses a changed/missing backup, retain the evidence and report
the error; do not delete backups to bypass the check. Use the normal launcher to
opt out on subsequent runs. Neither mode changes global screenshot preferences.

### One launcher, different graphics paths

Use the same normal shortcut on AMD, NVIDIA, or Intel systems. This is the intended
compatibility target, not a claim that all three vendors have been validated.
The default profile still uses the D3D9On12 path validated on the RX 6800 XT.
That path requires a DirectX 12-capable GPU. The normal launcher's `Auto` selection
keeps your saved profile unless it forces D3D9On12 and the default adapter cannot
create a DX12 device. In that case it saves the system-default D3D9 selection,
keeping the essential texture fixes, and records its choice in the launch log.
The probe does not guarantee rendering success or correctly cover every hybrid
GPU selection. A capability failure is not inferred from the GPU brand.

If startup still fails on another computer,
open the installed game folder and double-click
**`Play Dominion Wars - Native Graphics.cmd`**. This keeps the essential game
fixes but lets Windows use its system-default Direct3D 9 driver. On some Intel
systems that default may itself be D3D9On12; this is not a forced-native override.

The selection is saved in the game-specific compatibility profile. Subsequent
launches from the normal desktop shortcut keep it. To return to the original
profile, run **`Play Dominion Wars - D3D9On12 Graphics.cmd`** or repair. Do not
switch backends while the game is running. The alternative path is experimental:
native-driver exit crashes occurred on our validated AMD system.
The launcher does not automatically retry after a crash or switch backends based
on frame rate. Advanced users can pass `-GraphicsBackend Profile` to retain the
saved profile without the automatic capability adjustment.

### Optional visual and resource-saving presets

The normal desktop shortcut keeps your baseline visual profile. To experiment,
open the installed game folder and run one of these instead:

| Launcher | Experimental change |
|---|---|
| `Play Dominion Wars - Sharper.cmd` | Bicubic scaling of the finished image; compare text and edge sharpness |
| `Play Dominion Wars - Enhanced 3D.cmd` | 2× internal 3D render scaling; potentially cleaner ship edges/detail |
| `Play Dominion Wars - Resource-saving.cmd` | Attempts a 60 FPS cap to reduce unnecessary work; not an FPS boost |
| `Play Dominion Wars - Baseline.cmd` | Uses your original visual profile, just like the normal shortcut |

Each experimental preset applies for **one run only**. The launcher backs up your
game-specific INI, changes only display filtering, render scaling, anti-aliasing,
and frame limiting, then restores the original file when the game exits. All
three presets disable MSAA and reset the other preset controls to their baseline
values during that run, so enhancements are not accidentally combined.
The graphics-backend selection remains separate and can still be saved.

The presets do not increase the temporary desktop width, remove the required
texture fixes, change CPU affinity, or alter system-wide GPU settings. At the
game's 800×600 internal size, 2× scaling targets 1600×1200 rendering before
presentation; it is not a new native game/UI resolution or new texture detail.
Resource-saving requires the game's page-flipping path to work and may add
latency. Presets may cause visual glitches or perform worse on some systems.
They are not recommended defaults until actual gameplay comparison is complete.

If a preset launch is interrupted, the next normal launch attempts to recover
the original profile before starting. If the profile was edited afterward, the
launcher keeps those changes and preserves the original backup rather than
overwriting them; preset values may remain in that edited file. Repair restores
the packaged baseline if needed. Existing DDrawCompat overlays can override
preset values; check the graphics log's final configuration.
See [graphics experiments](docs/GRAPHICS.md) for settings and the comparison plan.

## Repair and removal

Keep the extracted modernizer download if you may need repair or removal later.

- Double-click **`Repair Dominion Wars.cmd`** to restore the packaged DDrawCompat
  DLL, configuration, and launcher files in the default installation. It also
  recreates a missing or unchanged modernizer shortcut, but keeps an edited one.
- Double-click **`Remove Dominion Wars Modernizer.cmd`** to restore compatibility
  files that existed before installation, remove files added by the modernizer,
  remove its unmodified desktop shortcut or restore the shortcut it replaced,
  and remove its internal state directory. An edited shortcut is kept; any
  original shortcut is recovered beside it under a different name.

Removal deliberately leaves the reconstructed game installation, saves, and
user-modified files in place. It is not a complete game uninstaller.

For a non-default destination, use PowerShell and provide the same directory:

```powershell
.\DominionWarsModernizer.ps1 Repair -Destination 'C:\Games\Dominion Wars'
.\DominionWarsModernizer.ps1 Uninstall -Destination 'C:\Games\Dominion Wars'
```

Repair requires the verified, unmodified 1.04 `ds9dw.exe`. Removal preserves a
managed file if it has been modified since installation and no original backup
is available, rather than deleting an unknown user change.
Repair resets the graphics selection to the packaged D3D9On12 profile; the next
normal launch can select system-default graphics again if DX12 is unavailable. Removal
can leave a backend-modified INI under the same preservation rule. Launcher
diagnostics and graphics logs are retained; you may delete those after reviewing
them. No game files or saves are removed.

## Known limitations

- Hardware and OS coverage is extremely limited. The validated system described
  above is one known-good configuration, not a compatibility guarantee.
- Only the North American retail edition and its official 1.04 patch are
  recognized by the current hashes.
- Single-player is the validated target. Multiplayer is untested and is not
  currently supported; the original GameSpy-era Internet service is no longer a
  release target.
- The normal baseline launcher still has the reproduced Alt+Tab
  `DDERR_NOEXCLUSIVEMODE` failure. The optional focus mode below passed a short
  test on one system, not general hardware or long-session validation.
- Reloading a newly written AutoSave also crashed during a baseline test on the
  known AMD system. Subsequent fresh-start, repeated-load, new-slot save/reload,
  and AutoSave-overwrite controls passed, but the original fault remains
  unresolved. Save/load is not yet validated as reliable. Brief successful
  mission launches do not establish campaign stability. Keep backups of saves.
- The primary desktop temporarily switches to a narrower mode whenever the
  packaged launcher is used unless the selected mode already matches. Windows may reposition application windows or
  desktop icons. If no candidate mode passes the driver's test, the launcher
  reports an error without changing the desktop.
- The separate recovery helper waits until both the launcher and game have
  stopped. It restores only if the saved monitor is still primary and its
  identity and temporary mode/position still match. It avoids overwriting later
  user display changes. Recovery is not guaranteed if the helper is also killed,
  Windows shuts down, or power is lost; it does not restart after reboot.
  **`Recover Dominion Wars Desktop.cmd`** offers a manual attempt after closing
  the game/launcher. **Windows Settings → System → Display** remains the fallback.
- Normal shutdown uses the same monitor/mode safeguards: it leaves an already-
  restored desktop alone and preserves later display changes rather than
  unconditionally reapplying the mode saved at launch.
- D3D9On12 is not supported by every GPU. Its capability probe checks the default
  adapter, not every possible hybrid-GPU selection. Laptops, remote sessions,
  virtual displays, and HDR/display-mode changes need separate testing.
- Unsigned PowerShell scripts and the bundled legacy cabinet helper may trigger
  Microsoft Defender, SmartScreen, or third-party antivirus warnings.
- GPU driver and Windows updates can change legacy DirectDraw/Direct3D behavior.
  A previously working configuration may need to be retested after an update.
- Other GPUs, Intel integrated graphics, unusual display scaling, and Windows 10
  have not received equivalent longer-session validation. The brief GTX 670 /
  Windows 10 result above does not establish broad vendor or OS support.
- LAN or direct-IP multiplayer investigation is deferred to a separate optional
  phase.

## Troubleshooting

### Installation activity and logs (0.6.0-alpha)

The installer prints the current stage and, during hashing/copying,
the current file, bytes processed, percentage where measurable, and elapsed time.
Long operations report approximately every five seconds. Extraction reports
observed output/diagnostic bytes rather than an invented percentage. After sixty
seconds without measured byte changes it warns about the lack of progress;
this does not prove a freeze, and slow optical-disc reads are not automatically
terminated. The official patch stage explicitly waits for its interactive prompts.

Installation, repair and removal logs are stored outside the game directory:

```text
%LOCALAPPDATA%\Dominion Wars Modernizer\InstallLogs
```

To open this folder, press **Win+R**, paste that path and press Enter. Each run
gets a timestamped log. Extraction also produces separate `.stdout.log` and
`.stderr.log` files; the main log identifies the relevant files. These survive
failed-install staging cleanup and modernizer removal. No logs are uploaded.
They are not automatically rotated; you may delete old logs after reviewing them.
Include the latest run's log and its referenced extractor logs in an installer
bug report. They may contain local paths; review them before sharing.

Do not press Ctrl+C to make installation advance: it requests cancellation.
During verification/copying, cancellation waits for an outstanding Windows file
read/write to return before cleaning up. During extraction it stops only the
helper launched for that operation. For the interactive official updater, close
its window and wait; the modernizer will not delete staging while that updater
is still running. Closing the console forcibly or powering off bypasses normal
cleanup. A console selection can pause visible updates; press **Esc** to leave
selection mode. The current candidate attempts to disable mouse-selection
QuickEdit temporarily in the install/repair/removal console and restores the
original mode afterward, unless another actor changed it. It does not change
Windows-wide console preferences or Ctrl+C handling. Non-console hosts are left
alone, and a refused safeguard is reported rather than failing installation.
This addresses classic console mouse selection, not every terminal host or
explicit keyboard Mark mode. Background file work/extraction also stays isolated
from console output. Without an effective guard, selection can still pause
visible messages and the next stage until selection ends.
The safeguard uses the documented [Windows console-mode API](https://learn.microsoft.com/en-us/windows/console/setconsolemode).

The double-click installer requires an explicit completion marker before showing
success, not just a zero process exit code. If compatibility setup fails after
the verified game directory was committed, that directory may remain; retain
the logs and report the error rather than assuming the install was rolled back.

The published 0.5.0-alpha package does **not** have these installer logs or
progress changes. If reporting that version's silent wait, include a screenshot,
elapsed time, and whether you used a physical CD or mounted image.

### Game and launcher logs

The default game and log directory is:

```text
%LOCALAPPDATA%\Dominion Wars
```

The primary graphics compatibility log is:

```text
%LOCALAPPDATA%\Dominion Wars\DDrawCompat-ds9dw.log
```

The launcher also writes:

```text
%LOCALAPPDATA%\Dominion Wars\.dw-launcher\launcher.log
%LOCALAPPDATA%\Dominion Wars\.dw-launcher\diagnostics.json
```

The JSON report records Windows, GPUs/drivers, monitor layout, the executable
and wrapper hashes, profile, additional DDrawCompat configuration file paths,
existing Windows compatibility flags, requested/selected backend handling, and
display-mode test results. It is refreshed on each launch;
the text log records process exit and restoration results. Text logs rotate at
approximately 1 MB, keeping one previous file. Nothing is uploaded automatically.
Review reports before sharing: they may contain local paths or hardware IDs.

Double-click **`Diagnose Dominion Wars.cmd`** in the installed game folder to
generate a report without launching the game, editing the compatibility profile,
or changing the desktop. It only queries/tests capabilities and writes local
diagnostics. Missing hardware inventory is recorded rather than blocking launch.
If other DDrawCompat configuration files are detected, inspect its graphics log's
final configuration: an existing overlay file can override the selected profile.

For conflicting game-local settings, **`Reset Dominion Wars Compatibility.cmd`**
backs up the game-specific profile, `DDrawCompat.ini`, and the game overlay,
then installs the clean packaged recipe and removes those local overrides.
It does not launch the game or change the desktop. It does not change global
DDrawCompat settings or Windows compatibility flags. Use
**`Undo Dominion Wars Compatibility Reset.cmd`** to restore the original files.
Undo refuses to overwrite settings edited after reset (including backend
changes); originals remain in `.dw-launcher\profile-backups`. Only one pending
reset is allowed, so undo it before resetting again.

Display recovery records are kept separately from the game under:

```text
%LOCALAPPDATA%\Dominion Wars Modernizer\DisplayRecovery\session-<Windows session ID>.json
```

If the helper encounters an error, its adjacent `.json.log` contains the error.
These records are retained on modernizer removal and are not uploaded.

Per-run preset backups and any conflict records are kept under
`.dw-launcher\visual-presets` in the game folder. A pending recovery record is
`.dw-launcher\visual-preset.json`. These files are retained on removal. Keep the
backups if you want to recover a customized profile; Diagnose reports pending
preset recovery without changing it.

Modernizer state and original compatibility-file backups are kept under:

```text
%LOCALAPPDATA%\Dominion Wars\.dw-modernizer
```

Do not delete that state directory before running removal if you want replaced
files restored.

If installation fails:

1. Confirm the disc is visible as a CD/DVD drive in File Explorer.
2. Confirm the patch is the North American `ds9dw1to4.exe` release.
3. Extract the entire modernizer ZIP before running the command file.
4. Copy the complete error text shown in the command window.

If the game stops launching after previously working, run
`Repair Dominion Wars.cmd`, then try the desktop shortcut again. Repair restores
only the modernizer-managed compatibility files; it does not repair arbitrary
game assets or saves.

For a bug report, include both launcher files and the DDrawCompat log, the exact
error text, the selected graphics path, whether the desktop was
restored, and the system details requested below. Do not upload copyrighted game
files, disc images, the official patch, or save files containing personal data.

## Testing requested

Broader testing is needed. Please report:

- Windows edition, version, and OS build;
- GPU model and exact driver version;
- monitor count, resolution, arrangement, and which display is primary;
- disc region/edition and printed release details;
- the SHA-256 of `ds9dw.exe`, if available;
- whether installation, videos, menu input, mission loading, gameplay, saving,
  loading, and Quit worked; and
- exactly where a failure occurred, including what was visible immediately
  beforehand.

The verified North American 1.04 executable SHA-256 is:

```text
03C20A3535D0209111FF9F3B90EBA403E059DF2BE7E784D2746ABF1535C1BE6A
```

## Technical overview

The known-good graphics profile uses DDrawCompat 0.7.1 beside `ds9dw.exe`:

```ini
PalettizedTextures = on
CompatFixes = singlemonitor
CapsPatches = D3DDEVICEDESC.dpcTriCaps.dwTextureCaps|=0x2
ForceD3D9On12 = on
```

The 0.3 candidate also explicitly pins DDrawCompat's existing defaults:
`EnableDDrawCompat = on`, `FullscreenMode = borderless`, and
`DisplayAspectRatio = app`. This makes the recipe less dependent on settings
left by another game; a higher-priority overlay can still override it.

- `PalettizedTextures` emulates the 8-bit palettized texture format expected by
  the game.
- `singlemonitor` avoids the game's legacy behavior of choosing the last display
  device it enumerates.
- The capability patch advertises `D3DPTEXTURECAPS_POW2` so the game uses its
  working power-of-two texture path.
- `ForceD3D9On12` avoids the reproducible AMD legacy-driver access violation seen
  on the validated RX 6800 XT configuration. Whether it is necessary or optimal
  on other hardware remains to be tested.
- The launcher saves the primary display's complete `DEVMODE`, enumerates actual
  driver modes, prefers 1280×960, and tests candidates using `CDS_TEST` before
  selecting a supported size/refresh rate. It applies the temporary mode without
  updating registry defaults, waits for the game, and restores the saved mode.
  An independent helper saves a per-user/session recovery record before the
  switch and guards orphaned-session restoration with process and monitor checks.
  Fallback ordering, error handling, and exit-code propagation have automated
  coverage; that is not equivalent to gameplay validation on those modes.

### Root cause

Dominion Wars takes a broken non-power-of-two texture path on modern hardware.
That path leaves texture dimensions uninitialized, leading to enormous invalid
allocation requests and a later null-pointer access in the game. Re-advertising
the period-correct power-of-two limitation sends the game through its working
texture path instead.

See [Technical compatibility findings](docs/COMPATIBILITY.md) for the evidence
and experiment history.

## Legal and third-party credits

- **Dominion Wars and its assets:** not included. This project is not affiliated
  with or endorsed by the game's publishers, developers, or rights holders.
- **Official 1.04 patch:** required but not included. The installer verifies the
  user-supplied North American patch before executing it.
- **DDrawCompat 0.7.1:** created by Narzoul and distributed under its permissive
  license. The required text is included as
  [`payload/DDrawCompat-LICENSE.txt`](payload/DDrawCompat-LICENSE.txt). Source:
  [narzoul/DDrawCompat](https://github.com/narzoul/DDrawCompat).
- **Optional DDrawCompat focus build:** the separately pinned revision 3b includes
  game-specific source changes under BSD Zero Clause. The complete patch, build
  record, hash and license accompany the package in
  [`third_party/DDrawCompat-focus`](third_party/DDrawCompat-focus/README.md).
- **i6comp v0.20:** created by fOSSiL and updated by Morlac. Its source headers
  authorize use when proper credit is given. The bundled binary is hash-locked;
  attribution and the authorization text are in
  [`payload/tools/I6COMP-LICENSE.txt`](payload/tools/I6COMP-LICENSE.txt).
- **Historical Dominion Wars wrapper:** Jiri Dvorak's earlier wrapper and
  MIT-licensed source were used as research provenance. Its source identified the
  broken non-power-of-two path and the POW2 capability workaround. No wrapper
  binary or game code from that project is shipped here.
- **Modernizer source:** released under the [MIT License](LICENSE.txt).

## Development status

This repository is an early compatibility project, not a finished commercial
installer. The current milestone is a reversible, original-media single-player
installation path for one verified regional edition.

- [Validation record](TESTING.md)
- [Technical compatibility findings](docs/COMPATIBILITY.md)
- [Broader-hardware testing plan](docs/PORTABILITY.md)
- [Clean-install and Intel/NVIDIA testing guide](docs/NEW-SYSTEM-TESTING.md)
- [Optional graphics and resource-saving experiments](docs/GRAPHICS.md)
- [Package manifest](MANIFEST.json)

Reports from additional hardware are more valuable than assumptions that the
known-good profile will generalize unchanged.
