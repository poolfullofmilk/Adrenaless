# CLAUDE.md

Personal rules live in `~/.claude/CLAUDE.md`. This file only covers Adrenaless.

## What This Is

One PowerShell script, `Adrenaless.ps1`, and `Adrenaless.cmd` to double click it. It turns off the Adrenalin features that make AMD's driver hook into games, disables AMD's own logon tasks, and restores everything from a backup on request. Nothing stays running.

It replaces Adrenalize, a tray app that restarted AMD after every game launch and kept breaking it by killing the host of a hook still loaded in the running game.

## Rules

- Only change what Adrenalin exposes as a setting, or AMD's own scheduled tasks. Never patch, rename or block driver files.
- Write registry values with the type that is already there, Adrenalin ignores the wrong type.
- Back up only on the first run, so a rerun never replaces the originals with values that are already off.
- Stay one script. No installer, no background task, no config file.

## Known

- AMD's D3D11, D3D12 and Vulkan drivers load `amdihk64.dll` into every process that uses the GPU, not only games. A plain window that never touches the GPU does not get it.
- Unverified: whether that stops once Adrenalin's host no longer starts at logon. If it does not, AMD's Driver Only install is the answer.
- Adrenalize 3 kept its backup in `%AppData%\Adrenalize`, the script moves it over on first start so Restore still works.

## Releases

The version is `$Version` in the script, one digit after the dot. Release assets are `Adrenaless_v<version>.cmd` and `Adrenaless_v<version>.ps1`, following the versioned naming rule. The launcher runs the `.ps1` with its own base name, so the pair keeps working after a rename.

## Checks

Windows PowerShell 5.1. `-Status` needs no admin and is the smoke test.
