# DiscordStatus - Discord Rich Presence for Dauntless 1.14.7

Shows where you are and which weapon you're using on your Discord profile, instead of just "Playing Dauntless".

By GoldenHeartbell. Version 0.1.0. Licence: AGPL-3.0 (see [LICENSE](LICENSE)).

## What Discord shows

```
Playing Dauntless
Hunting Grounds: Emberthorn Cove        <- where you are
Sword, level 6                          <- the weapon in your hands and its level
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

Your weapon updates when you switch. It shows the weapon type ("Sword"), not the weapon's own name yet.

The lines go into the normal "Playing Dauntless" entry Discord already shows for the game, with the game's own
artwork: the mod uses Discord's own Dauntless application, so there is nothing to set up in Discord. When you close
the game, the status clears by itself.

## What you need

- Dauntless 1.14.7 through the Dauntless Forever launcher, with **Modded mode** on (UE4SS 3.0.1).
- The Discord desktop app, running on the same PC. (Discord in a browser can't be reached by games.)
- In Discord: Settings > Activity Privacy > **Share your detected activities with others** on.

## Install

1. Download `DiscordStatus-<version>.zip` from [Releases](https://github.com/GoldenHeartbell/Dauntless-DiscordStatus/releases)
   and unzip it.
2. Copy the `DiscordStatus` folder into `<game folder>\Archon\Binaries\Win64\ue4ss\Mods\`.
3. Start the game. That's all: there are no keys and no settings.

To turn it off, delete the folder (or remove `enabled.txt` from it).

## Problems?

Look in `ue4ss\UE4SS.log` for lines starting with `[DiscordStatus]` (hooks, places, what it sent to Discord). Post
them together with what Discord showed.

## How it works (for the curious)

Everything is Lua, no DLL, in the [`Scripts`](Scripts) folder:

| File | What it does |
| --- | --- |
| `main.lua` | settings, putting the status together, and the start (the tick hooks) |
| `ds_game.lua` | reading the game: the hunt you are on, the escalation or Gauntlet round, your weapon |
| `ds_discord.lua` | the connection to the Discord app on your PC (Discord's local Rich Presence pipe) |
| `ds_names.lua` | island, escalation and weapon type names |
| `ds_helpers.lua` | small shared helpers, and which process this is |

Every 5 seconds (from a hook on your Slayer's tick, so it runs on the game's own thread) the script reads the game:
the hunt you are on, the escalation or Gauntlet round, and your weapon. When something changed, it tells the Discord
app on your PC over Discord's local "Rich Presence" pipe. The script only writes to that pipe, so the game never
waits for Discord. Nothing is sent anywhere else.

The hunt servers that run on your PC load the same mods; the script recognises them and does nothing there.
