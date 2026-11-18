-- DiscordStatus (UE4SS 3.0.1 Lua mod for Dauntless 1.14.7, Dauntless Forever Modded mode) - by GoldenHeartbell
-- Licence: AGPL-3.0
--
-- Shows more than "Playing Dauntless" on your Discord profile:
--   line 1: where you are   "In Ramsgate", "Hunting Grounds: Emberthorn Cove", "Heroic Umbral Escalation 51-90 - Round 3",
--                           "Elite Trials", "The Gauntlet - Level 12", "Training Grounds"
--   line 2: your weapon     "Ember Fists (Aether Strikers, level 7)"
--   and how long the game has been running.
--
-- The files, in this Scripts folder:
--   main.lua        settings, putting the status together, and the start (the tick hooks)
--   ds_game.lua     reading the game: the hunt you are on, the escalation or Gauntlet round, your weapon
--   ds_discord.lua  the connection to the Discord app on this PC
--   ds_names.lua    island, escalation and weapon type names
--   ds_helpers.lua  small shared helpers, and which process this is
--
-- ===================================================================================================================
-- Settings
-- ===================================================================================================================

-- Discord's own application for Dauntless: the one behind the "Playing Dauntless" Discord already shows when it
-- detects the game. Using it, together with the game's process id
local DISCORD_APPLICATION_ID = "451468933057347603"

local SECONDS_BETWEEN_GAME_CHECKS = 5
local SECONDS_BETWEEN_DISCORD_RETRIES = 20

-- ===================================================================================================================
-- The other files (the "ds_" names keep them apart from files of other mods and from Mods\shared)
-- ===================================================================================================================

local helpers = require("ds_helpers")
local game = require("ds_game")
local discord = require("ds_discord")
local log = helpers.log
local shorten = helpers.shorten

-- ===================================================================================================================
-- Putting it together
-- ===================================================================================================================

local current_place_key = nil
-- The "elapsed" timer counts from the game start
local game_started_at = os.time()

-- The status Discord shows, made from what the game says (no pictures: Discord shows the game's own artwork)
local function build_activity(place, weapon)
    local activity = {
        details = shorten(place.text),
        timestamps = { start = game_started_at },
    }
    if weapon and weapon.type_name ~= "" then
        local level_text = weapon.level > 0 and (", level " .. weapon.level) or ""
        if weapon.name ~= "" and weapon.name ~= weapon.type_name then
            activity.state = shorten(weapon.name .. " (" .. weapon.type_name .. level_text .. ")")
        else
            activity.state = shorten(weapon.type_name .. level_text)
        end
    end
    return activity
end

-- Reads the game and updates Discord when something changed (game thread, from the tick hook).
-- Returns false when this object was not yours, so the next tick tries again.
local function check_game(ticking_object, hook_name)
    local controller, character = game.controller_and_character(ticking_object)
    if not controller then
        return false
    end
    local world = helpers.try(function() return character:GetWorld() end)
    if not helpers.is_alive(world) then
        return false
    end
    local raw = { hook = hook_name }
    local place = game.read_place(controller, world, raw)
    local weapon = game.read_weapon(character, raw)
    if place.key ~= current_place_key then
        current_place_key = place.key
        log("place: " .. place.text .. " (map " .. tostring(raw.map) .. ", hunt " .. tostring(raw.matchmaker_hunt_id) .. ", weapon by " .. tostring(raw.weapon_found_by) .. ")")
    end
    discord.show_on_discord(build_activity(place, weapon))
    return true
end

-- ===================================================================================================================
-- Start
-- ===================================================================================================================

local role = helpers.process_role()
if role ~= "client" then
    log("not the game you play (" .. role .. "): nothing to do here")
elseif not DISCORD_APPLICATION_ID:match("^%d+$") then
    log("no Discord application id yet: paste it into DISCORD_APPLICATION_ID at the top of Scripts\\main.lua")
else
    discord.setup(DISCORD_APPLICATION_ID, helpers.game_process_id(), SECONDS_BETWEEN_DISCORD_RETRIES)

    -- The ticks that drive the checks: your Slayer (Ramsgate and hunts), and the hunt player controller as a backup.
    -- Each is hooked as soon as its Blueprint class has loaded.
    local TICK_HOOKS = {
        { name = "Slayer", class = "/Game/Blueprints/BP_PlayerCharacter.BP_PlayerCharacter_C", hooked = false },
        { name = "controller", class = "/Game/Character/Player/blueprints/player_controller_bp.player_controller_bp_C", hooked = false },
    }
    local next_check_at = 0
    local last_problem = nil
    local ticks_since_clock_look = 0
    local TICKS_BETWEEN_CLOCK_LOOKS = 30
    local SECONDS_AFTER_NOT_YOURS = 1

    local function on_tick(hook_name)
        return function(self)
            ticks_since_clock_look = ticks_since_clock_look + 1
            if ticks_since_clock_look < TICKS_BETWEEN_CLOCK_LOOKS then
                return
            end
            ticks_since_clock_look = 0
            local now = os.time()
            if now < next_check_at then
                return
            end
            local ok, result = pcall(function() return check_game(self:get(), hook_name) end)
            if ok and result then
                next_check_at = now + SECONDS_BETWEEN_GAME_CHECKS
            elseif ok then
                -- not your Slayer (another player's): try again soon, on one of the next ticks
                next_check_at = now + SECONDS_AFTER_NOT_YOURS
            else
                next_check_at = now + SECONDS_BETWEEN_GAME_CHECKS
                -- log a problem once, not every check
                if tostring(result) ~= last_problem then
                    log("check failed: " .. tostring(result))
                end
            end
            last_problem = (not ok) and tostring(result) or nil
        end
    end

    -- Hooks each tick whose class has loaded. Returns true when all are hooked.
    -- (Only StaticFindObject and RegisterHook here: this runs on LoopAsync's thread, where game objects are not read.)
    local function register_tick_hooks()
        local all_hooked = true
        for _, hook in ipairs(TICK_HOOKS) do
            if not hook.hooked and os.time() < (hook.next_try or 0) then
                all_hooked = false
            elseif not hook.hooked then
                local class_object = StaticFindObject(hook.class)
                if class_object and class_object:IsValid() then
                    -- RegisterHook inside a Lua function, (A failure here only says
                    -- "function: 0x...": UE4SS 3.0.1 gives no message.)
                    local tick_callback = on_tick(hook.name)
                    local ok, problem = pcall(function()
                        RegisterHook(hook.class .. ":ReceiveTick", tick_callback)
                    end)
                    
                    hook.attempts = (hook.attempts or 0) + 1
                    if ok then
                        hook.hooked = true
                        log("hook on the " .. hook.name .. " tick: ok (attempt " .. hook.attempts .. ")")
                    else
                        all_hooked = false
                        hook.next_try = os.time() + 2
                        if hook.attempts == 1 then
                            log("hook on the " .. hook.name .. " tick: not yet (" .. tostring(problem) .. "), trying again")
                        end
                    end
                else
                    all_hooked = false
                end
            end
        end
        return all_hooked
    end

    log("started (UE4SS 3.0.1); waiting for your Slayer to load, then checking the game every " .. SECONDS_BETWEEN_GAME_CHECKS .. " seconds")
    LoopAsync(3000, function()
        local ok, done = pcall(register_tick_hooks)
        return ok and done
    end)
end
