# CLAUDE.md

Personal rules live in `~/.claude/CLAUDE.md`. This file only covers Adrenaless.

## What This Is

One PowerShell script, `Adrenaless.ps1`, and `Adrenaless.cmd` to double click it. It turns off Record And Stream, the in-game overlay, hotkeys and the metrics overlay, disables AMD's `StartDVR` logon task that starts the recording server, and restores everything from a backup on request. Nothing stays running.

`StartCN` is deliberately left alone. It starts Adrenalin at logon, and Adrenalin is what applies GPU tuning such as an undervolt; 1.0 disabled it and the tuning silently stopped applying after a restart. Third-party tools cannot replace that on recent Radeons, voltage control goes through AMD's own driver interface.

It replaces Adrenalize, a tray app that restarted AMD after every game launch and kept breaking it by killing the host of a hook still loaded in the running game.

## Rules

- Only change what Adrenalin exposes as a setting, or AMD's own scheduled tasks. Never patch, rename or block driver files.
- Write registry values with the type that is already there, Adrenalin ignores the wrong type.
- Back up only on the first run, so a rerun never replaces the originals with values that are already off.
- Stay one script. No installer, no background task, no config file.

## Known

- `amdihk64.dll` is placed by Adrenalin's host service, `AMDRSServ`, into every process that uses AMD's D3D driver, including ones that were already running. With Adrenalin not running nothing is hooked; measured after a restart with `StartCN` off, then again after opening Adrenalin by hand.
- The hook itself is stock AMD behaviour. What actually broke AMD on this machine was restarting it underneath a running game, and Record And Stream injecting its capture hook next to Medal's.
- Adrenalize 3 kept its backup in `%AppData%\Adrenalize`, the script moves it over on first start so Restore still works.

## Releases

The version is `$Version` in the script, one digit after the dot. Release assets are `Adrenaless_v<version>.cmd` and `Adrenaless_v<version>.ps1`, following the versioned naming rule. The launcher runs the `.ps1` with its own base name, so the pair keeps working after a rename.

## Checks

Windows PowerShell 5.1. `-Status` needs no admin and is the smoke test.
