# Development validation

Test date: 2026-07-19

Environment: Windows 11 build 10.0.26200, AMD Radeon RX 6800 XT, three displays,
original North American retail media mounted as a CD-ROM drive.

## Updater lifecycle

A disposable verified 1.04 fixture passed:

1. in-place installation;
2. backup of a pre-existing compatibility configuration;
3. deliberate corruption of the installed configuration;
4. repair back to the packaged SHA-256;
5. modernizer removal;
6. restoration of the pre-existing file;
7. removal of files that did not exist before installation;
8. preservation of the game executable and data.

## Original-media reconstruction

The development updater reconstructed a new game tree directly from mounted
original media using the hash-verified bundled i6comp v0.20 extractor. It launched
the user-supplied official 1.04 patch, waited for its normal UI to complete, and
verified the patched executable as:

`03C20A3535D0209111FF9F3B90EBA403E059DF2BE7E784D2746ABF1535C1BE6A`

Every game file in the result was then compared by relative path, size, and
SHA-256 with the independently preserved clean 1.04 baseline:

- expected files: 31
- reconstructed game files: 31
- differences: 0
- result: PASS

Repair and modernizer removal also passed against this full reconstruction, and
the underlying game tree remained installed.

## Packaged launcher

The first packaged-launch test exposed that `$PSScriptRoot` was unavailable while
PowerShell evaluated a parameter default. Path resolution was moved into the
launcher body and the installed test copy was repaired. The repeated test then:

- resolved `ds9dw.exe` relative to the installed launcher;
- started the game through the packaged DDrawCompat profile;
- created the expected `P8`, `R5G6B5`, and `D16` resources;
- returned exit code 0; and
- ended with `DDrawCompat detached successfully`.

The user confirmed that the packaged build reached the main menu and exited via
Quit. Windows recorded no `ds9dw.exe` application fault, and the primary desktop
was restored to its original 2560x1440 mode.

The command wrappers preserve the underlying PowerShell exit code so a displayed
error cannot be mistaken for a successful automated run.

## Path independence

With no media path supplied, mounted-media discovery selected a valid Dominion
Wars CD-ROM source. An explicit path can override automatic selection. A text
scan found no development workspace path embedded in the package. The default
destination is resolved at runtime from the current user's `LOCALAPPDATA` folder.

## Bundled extractor validation

The bundled i6comp v0.20 executable is checked before use against SHA-256
`1181AE0DADA52EA5A5990D11F966E5986BF0A01614D2D5E5AD63B7C79E29FA29`.
The package includes the source-header authorization and credits for fOSSiL and
Morlac. A modified or substituted extractor is rejected before execution.
