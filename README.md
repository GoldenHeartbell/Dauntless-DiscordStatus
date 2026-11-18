# DiscordStatus - Discord Rich Presence for Dauntless 1.14.7

Shows where you are and which weapon you're using on your Discord profile, instead of just "Playing Dauntless".

```
Playing Dauntless
Umbral Escalation 10-50 - Round 3
Sword, level 6
1:02:34 elapsed
```

## What it shows

- **Where you are:** Ramsgate, the Hunting Grounds island you're on, Escalations (element, tier and round), Trials,
  the Gauntlet (with your level) and the Training Grounds.
- **Your weapon:** the weapon type in your hands and its level. It updates when you switch.
- **How long you've been playing:** the timer runs from when you start the game until you close it.

It fills in the normal Dauntless entry on your profile, with the game's own artwork. There's nothing to set up in
Discord. When you close the game, the status clears by itself.

## What you need

- Dauntless 1.14.7 through the Dauntless Forever launcher, with Modded mode on (UE4SS 3.0.1)
- The Discord desktop app running on the same PC (Discord in a browser won't work)
- In Discord: Settings > Activity Privacy > "Share your detected activities with others" turned on

## Install

1. Copy the [`mod/DiscordStatus`](mod/DiscordStatus) folder into `<game folder>\Archon\Binaries\Win64\ue4ss\Mods\`.
2. Start the game. That's all: there are no keys and no settings.

To turn it off, delete the folder or remove `enabled.txt` from it.

## Good to know

- It's Lua only, no DLL. It only talks to the Discord app on your own PC, and nothing is sent anywhere else.
- It's light on the game: it reads the game once every 5 seconds.
- It shows the weapon type ("Sword"), not the weapon's own name yet.

**Problems?** Look in `ue4ss\UE4SS.log` for lines starting with `[DiscordStatus]` and post them, together with what
Discord showed.

## The code

Everything is in [`mod/DiscordStatus/Scripts`](mod/DiscordStatus/Scripts):

| File | What it does |
| --- | --- |
| `main.lua` | settings, putting the status together, and the start (the tick hooks) |
| `ds_game.lua` | reading the game: the hunt you are on, the escalation or Gauntlet round, your weapon |
| `ds_discord.lua` | the connection to the Discord app on your PC (Discord's local Rich Presence pipe) |
| `ds_names.lua` | island, escalation and weapon type names |
| `ds_helpers.lua` | small shared helpers, and which process this is |

## Licence

AGPL-3.0, see [LICENSE](LICENSE). By GoldenHeartbell.
