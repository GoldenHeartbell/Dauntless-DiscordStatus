-- DiscordStatus (UE4SS 3.0.1 Lua mod for Dauntless 1.14.7, Dauntless Forever Modded mode) - by GoldenHeartbell
-- Licence: AGPL-3.0
--
-- ds_game.lua: reading the game. Where you are (the hunt, escalation round, Gauntlet level) and the weapon in your
-- hands. Game thread only: everything here is called from the tick hook in main.lua.

local helpers = require("ds_helpers")
local names = require("ds_names")
local try = helpers.try
local is_alive = helpers.is_alive
local text_of = helpers.text_of

local ARCHON_STATICS_PATH = "/Script/Archon.Default__ArchonGameplayStatics"
local ENGINE_STATICS_PATH = "/Script/Engine.Default__GameplayStatics"
local ESCALATION_COMPONENT_CLASS = "/Script/Archon.EscalationGameStateComponent"
local GAUNTLET_COMPONENT_CLASS = "/Script/Archon.GauntletGameStateComponent"

-- A component of the map's game state (escalation or Gauntlet), or nil on other maps
local function game_state_component(game_state, class_path)
    if not is_alive(game_state) then
        return nil
    end
    local component_class = StaticFindObject(class_path)
    if not is_alive(component_class) then
        return nil
    end
    local component = try(function() return game_state:GetComponentByClass(component_class) end)
    if is_alive(component) then
        return component
    end
    return nil
end

-- The game's own name for a player hunt (FPlayerHuntTableData.HuntName), from the hunt catalog the game keeps
local hunt_name_cache = {}
local function game_hunt_name(controller, player_hunt_id)
    if player_hunt_id == "" or player_hunt_id == "None" then
        return ""
    end
    if hunt_name_cache[player_hunt_id] then
        return hunt_name_cache[player_hunt_id]
    end
    local statics = StaticFindObject(ENGINE_STATICS_PATH)
    local game_instance = is_alive(statics) and try(function() return statics:GetGameInstance(controller) end)
    local catalog = is_alive(game_instance) and try(function() return game_instance.HuntCatalog end)
    if not is_alive(catalog) then
        return ""
    end
    local found_name = ""
    try(function()
        catalog.CachedPlayerHuntData:ForEach(function(_, element)
            local row = element:get()
            if text_of(row.PlayerHuntId) == player_hunt_id then
                found_name = text_of(row.HuntName)
                return true
            end
        end)
    end)
    if found_name ~= "" then
        hunt_name_cache[player_hunt_id] = found_name
    end
    return found_name
end

-- Where the player is: { key = "...", text = "..." }. key changes when the place changes (for the log).
-- raw collects the values that were read, for the log line.
local function read_place(controller, world, raw)
    local map_name = text_of(try(function() return world:GetFName() end))
    raw.map = map_name

    local game_state = try(function() return world.GameState end)
    local matchmaker_hunt_id = is_alive(game_state) and text_of(try(function() return game_state.MatchmakerHuntID end)) or ""
    raw.matchmaker_hunt_id = matchmaker_hunt_id

    local statics = StaticFindObject(ARCHON_STATICS_PATH)
    local player_hunt_id = ""
    if is_alive(statics) then
        player_hunt_id = text_of(try(function() return statics:GetLocalPlayerHuntId(controller) end))
    end
    raw.player_hunt_id = player_hunt_id

    local hunt_name = game_hunt_name(controller, player_hunt_id)
    raw.hunt_name = hunt_name
    local all_ids = matchmaker_hunt_id .. " " .. player_hunt_id

    if map_name:lower():find("ramsgate") then
        return { key = "city", text = "In Ramsgate" }
    end

    local escalation_code, escalation_tier = all_ids:match("Escalation_(%a+)_(%a+)")
    local escalation = game_state_component(game_state, ESCALATION_COMPONENT_CLASS)
    if escalation or escalation_code then
        local element = escalation_code and names.ESCALATION_ELEMENTS[escalation_code:lower()]
        local tier = escalation_tier and escalation_tier:lower() or ""
        local name
        local tier_info = names.ESCALATION_TIERS[tier]
        if element and tier_info then
            name = tier_info.prefix .. element .. " Escalation " .. tier_info.levels
        elseif element then
            name = element .. " Escalation"
        elseif hunt_name ~= "" then
            name = hunt_name
        else
            name = "Escalation"
        end
        local round = escalation and try(function() return escalation.CurrentRound end)
        raw.escalation_round = round
        raw.escalation_level = escalation and try(function() return escalation.CurrentChallengeLevel end)
        if type(round) == "number" and round > 0 then
            return { key = "escalation " .. name, text = name .. " - Round " .. round }
        end
        return { key = "escalation " .. name, text = name }
    end

    local gauntlet = game_state_component(game_state, GAUNTLET_COMPONENT_CLASS)
    if gauntlet or all_ids:find("Gauntlet") then
        local level = gauntlet and try(function() return gauntlet.LevelNumber end)
        raw.gauntlet_level = level
        if type(level) == "number" and level > 0 then
            return { key = "gauntlet", text = "The Gauntlet - Level " .. level }
        end
        return { key = "gauntlet", text = "The Gauntlet" }
    end

    local trial_tier = all_ids:match("Arena_MatchmakerHunt_(%a+)_")
    if trial_tier then
        local tier_text = trial_tier:sub(1, 1):upper() .. trial_tier:sub(2):lower()
        if hunt_name ~= "" then
            return { key = "trials", text = tier_text .. " Trials: " .. hunt_name }
        end
        return { key = "trials", text = tier_text .. " Trials" }
    end

    if all_ids:find("TrainingDojo") or map_name:lower():find("dojo") then
        return { key = "training", text = "Training Grounds" }
    end

    local island_letter = all_ids:match("Island(%u)%f[^%a]")
    if island_letter then
        local island = hunt_name ~= "" and hunt_name or names.HUNTING_GROUND_NAMES[island_letter]
        if island then
            return { key = "island " .. island, text = "Hunting Grounds: " .. island }
        end
    end

    if hunt_name ~= "" then
        return { key = "hunt " .. hunt_name, text = hunt_name }
    end
    if matchmaker_hunt_id ~= "" then
        return { key = "hunt " .. matchmaker_hunt_id, text = "On a hunt" }
    end
    return { key = "menu", text = "In the menus" }
end

-- The display name of a weapon, from your inventory (cached per weapon: looking through the inventory is slow)
local weapon_name_cache = {}
local function weapon_display_name(instance_id)
    if instance_id == "" then
        return ""
    end
    if weapon_name_cache[instance_id] then
        return weapon_name_cache[instance_id]
    end
    local found_name = ""
    try(function()
        local items = FindAllOf("ArchonInventoryItem_Weapon")
        if not items then
            return
        end
        for _, item in ipairs(items) do
            if text_of(item.ItemInstanceID) == instance_id then
                found_name = text_of(item.DisplayName)
                break
            end
        end
    end)
    weapon_name_cache[instance_id] = found_name
    return found_name
end

-- The weapon in the player's hands: { type_number, type_name, name, level }, or nil
local function read_weapon(character, raw)
    -- GetCurrentWeapon gave nothing in Ramsgate GetWeapon and the first weapon slot are the fallbacks
    -- (GetCurrentWeapon also gave nothing on an island; the character's own Weapon field is read first)
    local ways = {
        { name = "Weapon field", get = function() return character.Weapon end },
        { name = "SubWeapons[1]", get = function() return character.SubWeapons[1] end },
        { name = "GetCurrentWeapon", get = function() return character:GetCurrentWeapon() end },
        { name = "GetWeapon", get = function() return character:GetWeapon() end },
        { name = "GetWeaponBySlot(0)", get = function() return character:GetWeaponBySlot(0) end },
    }
    local weapon = nil
    for _, way in ipairs(ways) do
        local found = try(way.get)
        if is_alive(found) then
            weapon = found
            raw.weapon_found_by = way.name
            break
        end
    end
    if not weapon then
        raw.weapon_found_by = "none"
        return nil
    end
    local type_number = try(function() return weapon.WeaponType end)
    local instance_id = text_of(try(function() return weapon.ItemInstanceID end))
    local level = try(function() return weapon.ExperienceDetails.Level end)
    if type(level) ~= "number" or level <= 0 then
        level = try(function() return weapon:GetCurrentLevel() end)
    end
    raw.weapon_item = text_of(try(function() return weapon.ItemId end))
    raw.weapon_type = type_number
    raw.weapon_level = level
    local result = {
        type_number = type_number,
        type_name = names.WEAPON_TYPE_NAMES[type_number] or "",
        name = weapon_display_name(instance_id),
        level = type(level) == "number" and level or 0,
    }
    raw.weapon_name = result.name
    return result
end

-- Your controller and your Slayer, from the object whose tick was hooked (a Slayer or a player controller).
-- Other players' Slayers tick on your PC too; they have no controller here, so they give nil.
local function controller_and_character(ticking_object)
    local controller = try(function() return ticking_object.Controller end)
    if is_alive(controller) then
        return controller, ticking_object
    end
    local character = try(function() return ticking_object.Pawn end)
    if is_alive(character) then
        return ticking_object, character
    end
    return nil, nil
end

return {
    read_place = read_place,
    read_weapon = read_weapon,
    controller_and_character = controller_and_character,
}
