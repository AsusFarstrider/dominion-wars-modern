# Dominion Wars Modernizer

Dominion Wars Modernizer is a reversible installer and launcher intended to help
owners of the North American retail release of *Star Trek: Deep Space Nine –
Dominion Wars* run the game on current Windows hardware. It reconstructs a clean
installation from the user's own disc, applies compatibility components, and
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

The current known-good result is limited to:

| Component | Validated configuration |
|---|---|
| Game media | North American retail disc |
| Game version | Official 1.04 patch applied |
| Operating system | Windows 11, build 10.0.26200 |
| GPU | AMD Radeon RX 6800 XT, driver 32.0.21043.19003 |
| Displays | Three monitors: one 2560×1440 and two 1920×1080 |
| Output profile | Temporary 1280×960 desktop mode |
| Gameplay | Single-player Federation missions 1–2 and Dominion mission 1 |

The game engine itself still requests 800×600 internally. The validated
1280×960 setting is the 4:3 desktop/output environment used while the game runs.

## What this installer does

The installer:

- detects the owner's mounted original Dominion Wars disc;
- verifies the known North American retail cabinet files;
- reconstructs the installation directly from those cabinets because the
  original InstallShield installer is unreliable on modern 64-bit Windows;
- opens the user-supplied official 1.04 patch and waits while the user completes
  its normal prompts;
- verifies that patching produced the known 1.04 executable;
- installs DDrawCompat 0.7.1 and the game-specific compatibility settings;
- creates a crash-safe launcher and a desktop shortcut named `Dominion Wars`;
- temporarily changes the primary desktop to 1280×960 while playing and restores
  the exact prior display mode afterward, including after a game failure; and
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

1. A legitimate North American Dominion Wars retail CD, inserted or mounted as a
   Windows CD/DVD drive.
2. The North American official 1.04 patch, named `ds9dw1to4.exe`. The patch is not
   distributed here. A historical mirror is listed on the
   [TrekCore Dominion Wars downloads page](https://gaming.trekcore.com/dominionwars/downloads.html).
3. A supported 64-bit Windows installation. Windows 11 is the only version
   currently validated; Windows 10 may work but is not yet confirmed.
4. Permission to write to your own `%LOCALAPPDATA%` directory and create a
   desktop shortcut. Administrator rights are not normally required by the
   modernizer itself, although Windows may show security prompts for legacy or
   unsigned components.

The installer accepts only the verified North American disc and patch hashes.
Other editions are currently rejected rather than modified speculatively.

## Installation

1. On this GitHub page, select **Code → Download ZIP**.
2. Extract the downloaded ZIP completely. Do not run the installer from inside
   the compressed archive.
3. Insert the original CD or mount an image made from your own disc.
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

The screen will temporarily switch to 1280×960. This is expected. The launcher
waits for the game process to finish and then restores the prior desktop mode in
a `finally` block. Use the launcher rather than starting `ds9dw.exe` directly;
direct startup bypasses the required display handling.

## Repair and removal

Keep the extracted modernizer download if you may need repair or removal later.

- Double-click **`Repair Dominion Wars.cmd`** to restore the packaged DDrawCompat
  DLL, configuration, and launcher files in the default installation.
- Double-click **`Remove Dominion Wars Modernizer.cmd`** to restore compatibility
  files that existed before installation, remove files added by the modernizer,
  remove its desktop shortcut, and remove its internal state directory.

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

## Known limitations

- Hardware and OS coverage is extremely limited. The validated system described
  above is one known-good configuration, not a compatibility guarantee.
- Only the North American retail edition and its official 1.04 patch are
  recognized by the current hashes.
- Single-player is the validated target. Multiplayer is untested and is not
  currently supported; the original GameSpy-era Internet service is no longer a
  release target.
- The primary desktop temporarily switches to 1280×960 whenever the packaged
  launcher is used. Windows may reposition application windows or desktop icons.
- Unsigned PowerShell scripts and the bundled legacy cabinet helper may trigger
  Microsoft Defender, SmartScreen, or third-party antivirus warnings.
- GPU driver and Windows updates can change legacy DirectDraw/Direct3D behavior.
  A previously working configuration may need to be retested after an update.
- NVIDIA, Intel, other AMD GPUs, single-monitor systems, unusual display scaling,
  and Windows 10 have not yet received equivalent validation.
- LAN or direct-IP multiplayer investigation is deferred to a separate optional
  phase.

## Troubleshooting

The default game and log directory is:

```text
%LOCALAPPDATA%\Dominion Wars
```

The primary graphics compatibility log is:

```text
%LOCALAPPDATA%\Dominion Wars\DDrawCompat-ds9dw.log
```

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

For a bug report, include the log, the exact error text, whether the desktop was
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

- `PalettizedTextures` emulates the 8-bit palettized texture format expected by
  the game.
- `singlemonitor` avoids the game's legacy behavior of choosing the last display
  device it enumerates.
- The capability patch advertises `D3DPTEXTURECAPS_POW2` so the game uses its
  working power-of-two texture path.
- `ForceD3D9On12` avoids the reproducible AMD legacy-driver access violation seen
  on the validated RX 6800 XT configuration. Whether it is necessary or optimal
  on other hardware remains to be tested.
- The launcher saves the complete primary `DEVMODE`, changes only the width and
  height to 1280×960, waits for the game, and restores the saved mode afterward.

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
- [Package manifest](MANIFEST.json)

Reports from additional hardware are more valuable than assumptions that the
known-good profile will generalize unchanged.
