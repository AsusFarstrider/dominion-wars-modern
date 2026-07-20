# Technical compatibility findings

Validation date: 2026-07-19

This document records the evidence behind the current Dominion Wars Modernizer
profile. The result is validated on one Windows 11 and AMD Radeon configuration;
it should not be read as proof of general Windows 10/11 compatibility.

## Validated result

The North American retail build was reconstructed from the original CD cabinets,
updated from 1.01 to the official 1.04 release, and run on Windows 11 build
10.0.26200 with an AMD Radeon RX 6800 XT driver 32.0.21043.19003 and a
three-monitor desktop.

Observed working behavior included all introduction videos, menu mouse input,
the first two Federation missions, the beginning of the first Dominion mission,
and a clean Quit. Windows recorded no application fault on the final packaged
launcher test, DDrawCompat detached successfully, and the original 2560×1440
desktop mode was restored.

## Known-good profile

DDrawCompat v0.7.1 is installed as `ddraw.dll` beside `ds9dw.exe` with:

```ini
PalettizedTextures = on
CompatFixes = singlemonitor
CapsPatches = D3DDEVICEDESC.dpcTriCaps.dwTextureCaps|=0x2
ForceD3D9On12 = on
```

The launcher temporarily changes the primary desktop to 1280×960, starts the
game, waits for it to exit, and restores the captured display mode in a `finally`
block. Runtime tracing shows the engine still requests 800×600×16 internally.

## Native failure

The unwrapped 1.04 executable changed display mode, displayed a black screen, and
then raised an access violation:

- exception: `0xC0000005`;
- fault: `ds9dw.exe+0x8A08` (`0x00408A08`);
- invalid operation: write to address `0x00000054`; and
- immediate cause: a failed internal creation routine returned null and the game
  wrote to offset `+0x54` without checking it.

DDrawCompat's release log showed managed texture creation failing with
`E_INVALIDARG`. A debug build exposed malformed texture dimensions of roughly
13.8 million by 13.9 million pixels.

## Texture root cause

The recovered source for Jiri Dvorak's historical Dominion Wars wrapper documents
that the game's non-power-of-two texture path does not initialize texture
dimensions correctly. The wrapper reintroduced `D3DPTEXTURECAPS_POW2`, causing
the game to select its working texture path.

DDrawCompat reproduces that capability advertisement with:

```ini
CapsPatches = D3DDEVICEDESC.dpcTriCaps.dwTextureCaps|=0x2
```

After adding it, the managed `P8` and `R5G6B5` allocations that previously failed
succeeded and the game remained running. `PalettizedTextures = on` provides the
8-bit palettized format expected by the game. `CompatFixes = singlemonitor`
prevents the legacy display enumerator from selecting a secondary monitor.

## Mouse and display behavior

The historical wrapper author documented a mouse failure when the real primary
desktop width is at least 1600 pixels. DDrawCompat's virtual display-resolution
setting did not correct this independent input bug. Temporarily setting the real
primary desktop to a 4:3 mode does.

The initial 640×480 Windows compatibility flag proved the diagnosis and allowed
successful gameplay. The final launcher instead uses 1280×960, preserving the
intended 4:3 output while remaining below the mouse bug's width threshold.

## AMD exit failure and D3D9On12

At 1280×960 without D3D9On12, gameplay worked but some state transitions and
exits reproducibly faulted in AMD's legacy 32-bit Direct3D module,
`AMDXN32.DLL+0xBECCFE`. With `ForceD3D9On12 = on`, the first Dominion mission ran
normally and Quit produced a successful DDrawCompat detach with no Windows crash
event. This setting is validated for the tested RX 6800 XT; its behavior on other
vendors and drivers still needs evidence.

## Experiment summary

| Experiment | Result |
|---|---|
| Native 1.04 | Black screen, then access violation at `ds9dw.exe+0x8A08` |
| DDrawCompat defaults | Same crash; managed `R5G6B5` creation failed |
| Palettized emulation only | Selected `P8`, but malformed allocation still failed |
| Single-monitor enumeration only | Startup crash remained |
| Virtual 1280×720 | Startup crash remained; mouse issue was not fixed |
| POW2 capability patch | Startup, videos, and menu succeeded |
| Windows 640×480 compatibility flag | Mouse worked; Federation mission 1 completed |
| Temporary 1280×960 desktop | Mouse worked; Federation missions 1–2 completed |
| 1280×960 without D3D9On12 | Gameplay worked; AMD legacy-driver exit faults occurred |
| Add D3D9On12 | Dominion mission 1 ran; Quit detached cleanly with no crash event |

## Scope

Multiplayer is not a release gate. GameSpy-era Internet service is outside the
current target, and LAN/direct-IP work is deferred. The current target is a
reversible original-media installation and stable single-player launch on modern
Windows systems.

## Research provenance

- [DDrawCompat](https://github.com/narzoul/DDrawCompat)
- [DDrawCompat configuration reference](https://github.com/narzoul/DDrawCompat/wiki/Configuration)
- [TrekCore Dominion Wars downloads](https://gaming.trekcore.com/dominionwars/downloads.html)
- [DxWnd Dominion Wars investigation](https://sourceforge.net/p/dxwnd/discussion/general/thread/364ab0f613/)

The historical Jiri Dvorak wrapper source was used as research provenance for the
POW2 workaround. Its binary and source are not distributed by this repository.
