-- DiscordStatus (UE4SS 3.0.1 Lua mod for Dauntless 1.14.7, Dauntless Forever Modded mode) - by GoldenHeartbell
-- Licence: AGPL-3.0
--
-- ds_names.lua: names the game does not give us directly, in English. The hunt's own name from the game's hunt table
-- is used first where there is one (that one follows the game's language), these are the fallbacks.

-- EWeaponType values (Archon_enums.lua) -> the weapon type's name
local WEAPON_TYPE_NAMES = {
    [1] = "Hammer",
    [2] = "Axe",
    [3] = "Sword",
    [4] = "Chain Blades",
    [5] = "War Pike",
    [6] = "Repeaters",
    [7] = "Aether Strikers",
}

-- Hunting Grounds islands: Adventure_Island<letter>. Names from the game's English text (weekly challenge table).
local HUNTING_GROUND_NAMES = {
    A = "Emberthorn Cove", B = "Boreal Outpost", C = "Revelation Rock", D = "Restless Sands", E = "Iron Falls",
    F = "Sunderstone", G = "Aulric's Peak", H = "Frostmarch", I = "Thunderwatch", J = "Fortune's Folly",
    K = "Brightwood", L = "Coldrunner Key", M = "The Snowblind Waste", N = "Undervald Defile", O = "Cape Fury",
    P = "Hades Reach", Q = "Razorcliff Isle", R = "Twilight Sanctuary", S = "The Paradox Breaks",
    T = "Conundrum Rocks", U = "The Blazeworks",
}

-- Escalation code names in the hunt ids, from the map each one uses (escalation_island_<element>_00)
local ESCALATION_ELEMENTS = {
    armstrong = "Blaze",
    thunderbird = "Shock",
    randall = "Umbral",
    funguy = "Terra",
    mint = "Frost",
    glitter = "Radiant",
}

-- Escalation tiers in the hunt ids (..._Escalation_Randall_Heroic), as the game's own texts name them:
-- "Umbral Escalation (1-13)", "(10-50)", and "Heroic Umbral Escalation" at level (51-90).
-- prefix goes before the element, levels after "Escalation".
local ESCALATION_TIERS = {
    easy = { prefix = "", levels = "1-13" },
    hard = { prefix = "", levels = "10-50" },
    heroic = { prefix = "Heroic ", levels = "51-90" },
}

return {
    WEAPON_TYPE_NAMES = WEAPON_TYPE_NAMES,
    HUNTING_GROUND_NAMES = HUNTING_GROUND_NAMES,
    ESCALATION_ELEMENTS = ESCALATION_ELEMENTS,
    ESCALATION_TIERS = ESCALATION_TIERS,
}
