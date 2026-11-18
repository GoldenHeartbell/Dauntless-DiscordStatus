# Dauntless DiscordStatus

Shows what you are doing in **Dauntless 1.14.7** on your Discord profile, instead of only "Playing Dauntless".

By GoldenHeartbell. Version 0.1.0 (test). Licence: AGPL-3.0 (see LICENSE).

## What Discord shows

```
Playing Dauntless
Hunting Grounds: Emberthorn Cove        <- where you are
Ember Fists (Aether Strikers, level 7)  <- the weapon in your hands and its level
1:02:34 elapsed                         <- how long the game has been running
```

Where you are can be:

| Place | Shown as |
| --- | --- |
| Ramsgate | In Ramsgate |
| Hunting Grounds | Hunting Grounds: *island name* |
| Escalation | *Umbral Escalation 1-13*, *Umbral Escalation 10-50* or *Heroic Umbral Escalation 51-90*, plus the round you are on |
| Trials | Elite Trials (or Hard Trials) |
| The Gauntlet | The Gauntlet - Level *n* |
| Training Grounds | Training Grounds |

Names come from the game itself where it has them (so they follow the game's language), otherwise from the English
game text.

The two lines go into the normal "Playing Dauntless" entry Discord already shows for the game, with the game's own
artwork: the mod uses Discord's own Dauntless application, so there is nothing to set up in Discord.

## What you need

- Dauntless 1.14.7 through the Dauntless Forever launcher, with **Modded mode** on (UE4SS 3.0.1).
- The Discord desktop app, running on the same PC. (Discord in a browser can't be reached by games.)
- In Discord: Settings > Activity Privacy > **Share your detected activities with others** on.

## Install

1. Copy the `DiscordStatus` folder into `<game folder>\Archon\Binaries\Win64\ue4ss\Mods\`.
2. Start the game. That's all: there are no keys and no settings.

To turn it off, delete the folder (or remove `enabled.txt` from it).

## How it works (for the curious)

Everything is Lua, in the `Scripts` folder, no DLL: `main.lua` (settings and the start), `ds_game.lua` (reading the
game), `ds_discord.lua` (the Discord connection), `ds_names.lua` (island, escalation and weapon names) and
`ds_helpers.lua`. Every 5 seconds (from a hook on your Slayer's tick, so it runs on the
game's own thread) the script reads the game (the hunt you are on, the escalation or Gauntlet round, your weapon)
and, when something changed, tells the Discord app on your PC over
Discord's local "Rich Presence" pipe. The script only writes to that pipe, so the game never waits for Discord. Nothing
is sent anywhere else. When you close the game, Discord clears the status by itself.

The hunt servers that run on your PC load the same mods; the script recognises them and does nothing there.

## Problems?

- Look in `ue4ss\UE4SS.log` for lines starting with `[DiscordStatus]` (hooks, places, what it sent to Discord).
  Post them together with what Discord showed.
