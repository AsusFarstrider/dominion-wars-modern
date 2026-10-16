# 0.5.0-alpha candidate

Early alpha for original-media owners. Tested on one Windows 11 / AMD RX 6800 XT /
three-monitor configuration. Intel, NVIDIA, other drivers and monitor layouts
remain unvalidated. This is not a universal Windows compatibility fix.

## Changes

- Separately selected **Play Dominion Wars - Experimental Alt-Tab.cmd** launcher.
  It uses the exact hash-pinned focus wrapper tested on the AMD system. The normal
  desktop shortcut retains stock DDrawCompat and the baseline behavior.
- Per-run DLL/profile swap with verified backups, atomic replacement, normal-exit
  restoration and next-launch recovery after interruption. Later changes/deletions
  are preserved rather than silently overwritten. Repair/removal recognize pending
  swaps, and both bundled DLLs are hash-checked before installation.
- Source patch, upstream license and build provenance for the optional wrapper.
- A new-system testing guide and a manifest-verified release builder. Candidate
  runtime files match the successfully tested package; final changes are documentation.

## Tested and still uncertain

The fresh extracted package's normal launcher passed the user's mission/save-load/
normal-quit check. The optional launcher received an overall pass; logs confirm
two minimize/return cycles, exit code 0, desktop cleanup, exact restoration of the
stock DLL/profile and removal of its recovery record. Automated launcher, focus
transaction, repair/removal, profile/recovery, visual-preset and shortcut checks passed.

Both original and game-native physical modes were 2560x1440@165, so real changes
between different physical resolutions remain untested. The launcher's 1280x960
mode is for initialization; stock DDrawCompat can restore the physical desktop
during startup. Individual screenshot shortcuts were not separately itemized in
the packaged pass. Longer focus-mode sessions, other GPUs and fresh CD installs
on other systems are the next tests. See [TESTING.md](TESTING.md).

## Using the candidate

Extract the complete release ZIP, supply a legitimate North American retail CD
**or a mounted image of your own CD**, plus the official North American 1.04 patch,
then run **Install Dominion
Wars.cmd**. Game assets, the official patch, modified game executables and DRM
bypasses are not included. No Git or development tools are needed.

The image must appear as a Windows CD/DVD drive. ISO or BIN/CUE can be used with
a suitable mounting tool; the modernizer does not mount images or read raw image
files. Any drive letter is accepted. Download the attached
`dominion-wars-modernizer-0.5.0-alpha.zip`, not GitHub's automatically generated
source archives.

Start with the normal desktop shortcut. After it works, try the separately named
experimental launcher in the installed game folder. **Pause manually before
switching away; automatic pause does not work.** The optional mode requires the
verified NA 1.04 executable and a driver-tested 1280x960 initialization mode, and
does not combine with visual presets. The normal baseline still has its known
Alt+Tab restore failure.

For the Intel/NVIDIA machine, follow [new-system testing](docs/NEW-SYSTEM-TESTING.md)
and preserve logs before another run overwrites them. No equivalently validated
Intel/NVIDIA configuration is claimed yet. Close the game before repair/removal;
back up intentional configuration edits before repair resets packaged files.
