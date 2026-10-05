# CLAUDE.md

Personal rules live in `~/.claude/CLAUDE.md`. This file only covers Adrenaless.

## What This Is

One file, `Adrenaless.cmd`. It turns the in-game overlay on and hotkeys and the metrics overlay off, disables AMD's `StartDVR` logon task that starts the recording server, restores everything from a backup on request, and opens Adrenalin. Nothing stays running.

The file is a batch and PowerShell hybrid. `<# :` is a harmless line to cmd and opens a block comment for PowerShell, so cmd runs the short header, which hands the whole file to PowerShell as a script block and exits before reaching the rest. The header puts the file's own path in `AdrenalessPath`, because a script block has no `$PSCommandPath`. The file must keep CRLF line endings and stay ASCII.

The menu runs unelevated and only elevates for a single step: it relaunches the file hidden with `-Apply`, `-Restore` or `-Clear` through `Invoke-Elevated`. Viewing the status or opening Adrenalin never raises a prompt.

`StartCN` is deliberately left alone. It starts Adrenalin at logon, and Adrenalin is what applies GPU tuning such as an undervolt; 1.0 disabled it and the tuning silently stopped applying after a restart. Third-party tools cannot replace that on recent Radeons, voltage control goes through AMD's own driver interface.

It replaces Adrenalize, a tray app that restarted AMD after every game launch and kept breaking it by killing the host of a hook still loaded in the running game.

## Opening Adrenalin

Menu option 3, or `-Open`, exists because Adrenalin gets stuck in a way only Task Manager used to fix. Its window process, `RadeonSoftware`, dies on its own, sometimes minutes after boot, while its background parts (`AMDRSServ`, `amdow`, `CPUMetricsServer`) stay alive and run elevated. A new launch then sees Adrenalin as already running, hands the request to those parts and exits in about a tenth of a second without writing a log, and when the background parts are hours old nothing ever shows up. Fresh background parts pass the request on fine, which is why the problem looks random.

`-Open` runs as the user and launches Adrenalin normally. If no window appears within twelve seconds it relaunches itself elevated with `-Clear`, which closes every Adrenalin part but never AMD's driver services, then launches Adrenalin again as the user. The launch must stay unelevated: Adrenalin quits during its splash when it inherits administrator rights.

## In Game Overlay

The overlay is set on, not off. Adrenalin 26.10 opened while a game runs does not draw its normal window, it shows itself through the overlay. With the overlay off it crashed every time: `screen is not defined` in `MainDesktopWindow.qml`, exit code 13, then AMD's own `cncmd watch` restarted it hidden in the tray, which looks like nothing happened. With `FullscreenExperiencePrompt` under `HKCU\Software\AMD\CN` set to 0 it stopped crashing but still showed no window. With the overlay on and AMD restarted it opened mid-game in Overwatch and again after the game closed. Versions 1.0 to 1.2 turned the overlay off and caused the exact crash they were meant to fix.

Hotkeys stay off, so the overlay never appears in a game unless Adrenalin is opened.

The crash only shows in Adrenalin's debug output, read through `OutputDebugString` with DebugView or a `DBWIN_BUFFER` listener. Its `RSX_Common` log in `%LocalAppData%\AMD\CN` says nothing, and no Windows crash report is written.

Record And Stream is not managed. AMD rewrites `DvrEnabled` under `HKCU\Software\AMD\DVR` to 1 at every boot from its own store, whatever the switch inside Adrenalin says, so writing it changed nothing. Versions 1.0 to 1.2 wrote it anyway.

## Rules

- Only change what Adrenalin exposes as a setting, or AMD's own scheduled tasks. Never patch, rename or block driver files.
- Write registry values with the type that is already there, Adrenalin ignores the wrong type.
- Back up only on the first run, so a rerun never replaces the originals with values that are already changed.
- Stay one file. No installer, no background task, no config file.
- The README is written in normal sentence case, and no sentence ends with punctuation.

## Known

- `amdihk64.dll` is placed by Adrenalin's host service, `AMDRSServ`, into every process that uses AMD's D3D driver, including ones that were already running. With Adrenalin not running nothing is hooked; measured after a restart with `StartCN` off, then again after opening Adrenalin by hand.
- The hook itself is stock AMD behaviour. What actually broke AMD on this machine was restarting it underneath a running game, and the overlay being off when Adrenalin was opened in game.
- Adrenalize 3 kept its backup in `%AppData%\Adrenalize`, the script moves it over on first start so Restore still works.

## Releases

The version is `$Version` in the file, one digit after the dot. A release has one asset, `Adrenaless_v<version>.cmd`, and only the latest release is kept. The file finds itself through `%~f0`, so any name works.

## Checks

Windows PowerShell 5.1. `Adrenaless.cmd -Status` needs no admin and is the smoke test.
