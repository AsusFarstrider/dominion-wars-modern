# DDrawCompat focus build

Version 0.7.0-alpha selects this build automatically for the
verified NA 1.04 game, baseline visuals and supported 1280×960 initialization mode.
The normal launcher retains stock behavior for unsupported combinations;
`Play Dominion Wars - Baseline.cmd` explicitly opts out. Published 0.5/0.6 packages
select it only through `Play Dominion Wars - Experimental Alt-Tab.cmd`.

## Origin, license and exact binary

- Upstream: [narzoul/DDrawCompat](https://github.com/narzoul/DDrawCompat), tag
  `v0.7.1`, commit `2c9a07fdf9308e2b0b117886a7e363b149ee1bc7`.
- Upstream and the accompanying focus patch: BSD Zero Clause License; see
  [LICENSE.txt](LICENSE.txt). Other modernizer source remains under the repository's
  MIT license.
- Changes: [DDrawCompat-0.7.1-focus.patch](DDrawCompat-0.7.1-focus.patch).
  Apply to an exact, separate upstream checkout; `git apply --check` verifies
  applicability. No game executable or assets are included or modified.
- Installed focus binary: `DDrawCompat-Focus.dll`, 3,468,800 bytes, x86.
  SHA-256: `3AA11B1C81A21C6EF5FB85D2DC31DEEC7EB8217F637094E9ED7B9F6D6BC90490`.
  It has the same 42 export names and ordinals as the stock wrapper.

The binary is the exact revision 3b tested on the known AMD system, not a new
rebuild. The installer verifies both DLL hashes before changing managed files;
the launcher verifies the game and both wrappers again before swapping.

## Build record (developers only)

Visual Studio 2026 Build Tools; MSVC v145 14.50.35717; Windows SDK 10.0.26100.0;
solution Release/x86 (project Win32). Microsoft's WDK NuGet package
`Microsoft.Windows.WDK.x86` 10.0.26100.1 supplies `d3dumddi.h`; point the compiler
include path at its `c/Include/10.0.26100.0/um` directory. No WDK binary or driver
is shipped or installed. Package SHA-256:
`4A3F6CFF29720C632D605F9E6901C020F314E23669FEC076C4679E764CF56516`.

```text
MSBuild.exe DDrawCompat.sln /m:2 /t:Build /p:Configuration=Release /p:Platform=x86
/p:PlatformToolset=v145 /p:WindowsTargetPlatformVersion=10.0.26100.0
```

Rebuilding can produce a different hash. It must be separately verified and the
pins updated deliberately; do not substitute an unverified build in a release.

## Behavior and boundaries

The patch suppresses the NA 1.04 game's broken activation handler, retains the
last frame while unfocused, then minimizes after sustained focus loss. It restores
the saved original desktop only if necessary and reapplies the recorded game-native
mode before return. The same primary monitor and expected modes must still match;
later user changes or a replaced monitor disable further automatic switching.
Capture-host process-name exceptions attempt to preserve Windows capture overlays;
this heuristic is not universal capture support.

The native gates require an opt-in process environment, game basename/timestamp
and original window-procedure RVA. The launcher additionally requires the complete
known NA 1.04 executable hash and a valid original-display snapshot. Initialization
is currently restricted to 1280x960; Auto uses stock focus behavior for other modes. Automatic
pause does not work: pause manually before switching away.

The successful short test used identical original/game physical modes of
2560x1440@165, because stock DDrawCompat resets the physical display during
startup. It validates minimizing/returning on that system, not a genuine
different-resolution transition, other GPUs or long-session stability.

The packaged launcher temporarily swaps DLL/profile with atomic file replacement,
retains verified originals under `.dw-launcher/focus-backups`, and restores exact
bytes after the game exits. A later non-diagnostic launch recovers an interrupted
transaction. Changed/deleted files are preserved and require repair; diagnostics
are read-only. Repair/removal can recover recognized pending swaps. No global
environment variable, screenshot preference or registry display mode is saved.

## Launcher keyboard recovery (0.7)

The DLL and source patch are unchanged. The launcher additionally adapts the
remaster's guarded Alt/Windows-key recovery for the original NA 1.04 executable.
Its original key handler maps Alt to bit `0x40` and both Windows keys to `0x80`
in DWORD `0x719618`; a missing key-up can leave those flags set after switching
away. The remaster recorded stale Windows flags on two returns with physical
keys up and a subsequent owner-confirmed input recovery.

The adaptation verifies the original full executable hash, actual process path,
session and image base. It reads that DWORD with query/read-only process rights
only after a focus return, waits for two 100 ms polling samples with physical
Alt/Windows keys up, and rechecks the foreground process, target window owner,
file hash and physical keys before posting game-only key-ups. It releases only
observed stale Alt/Windows flags, not Shift/Control/Apps, and sends no input on
initial focus. No global input, memory writes or arbitrary-process scanning.
It runs for the owned game lifetime without the research helper's 32-return cap;
read/access errors disable the keyboard assistance and are logged, rather than
terminating the game. Handles close on exit. This is new launcher code with
automated fake-native coverage, not a live acceptance result for this candidate.

See [TESTING.md](../../TESTING.md) and the [new-system guide](../../docs/NEW-SYSTEM-TESTING.md).
