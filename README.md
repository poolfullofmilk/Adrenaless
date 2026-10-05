# Adrenaless

Prevents AMD Adrenalin from crashing while a game is running

## Use

1. Download the `.cmd` file from the [latest release](https://github.com/poolfullofmilk/Adrenaless/releases/latest)
2. Double click it. It saves itself to `%AppData%\Adrenaless` and adds Adrenaless to the Start menu, so the download can be deleted
3. Pick an option and accept the admin prompt when it asks
4. Restart when it asks, so AMD picks up the changes

From then on, open Adrenaless from the Start menu. Running a newer download replaces the saved copy

## Options

- **Apply settings** sets everything below and backs up your original values first
- **Restore everything** puts your original values back and removes the backup
- **Open Adrenalin** opens Adrenalin. If it's stuck and won't open, it closes Adrenalin's background parts with one admin prompt and opens it again

## What it changes

| Setting | Set to | Why |
| --- | --- | --- |
| In-game overlay | Off | Nothing from AMD draws inside your games |
| Hotkeys | Off | AMD's shortcuts never trigger the overlay or recording in a game |
| Metrics overlay | Off | No FPS or temperature overlay in your games |
| AMD's `StartDVR` task | Off | AMD's recording server no longer starts with Windows |

## What it leaves alone

- Adrenalin still starts with Windows, so GPU tuning like an undervolt keeps applying at boot
- Record & Stream, switch it inside Adrenalin itself because AMD resets its registry copy at every boot
- AMD's drivers and services, and nothing keeps running in the background

Your original values are saved in `%AppData%\Adrenaless\backup.json` until you restore them

## Removing it

Pick restore everything first, then delete the `%AppData%\Adrenaless` folder and the Adrenaless Start menu entry

Successor to [Adrenalize](https://github.com/poolfullofmilk/Adrenalize)
