-- DiscordStatus (UE4SS 3.0.1 Lua mod for Dauntless 1.14.7, Dauntless Forever Modded mode) - by GoldenHeartbell
-- Licence: AGPL-3.0
--
-- ds_helpers.lua: small helpers the other files share (logging, safe calls, text), and which process this is.

-- Writes one line to UE4SS.log
local function log(text)
    print("[DiscordStatus] " .. text .. "\n")
end

-- Runs a function and returns its result, or nil when it fails (a missing object or property must never stop the mod)
local function try(action)
    local ok, result = pcall(action)
    if ok then
        return result
    end
    return nil
end

-- True when the object exists and is still alive in the game
local function is_alive(object)
    return object ~= nil and try(function() return object:IsValid() end) == true
end

-- Text from an FString, FName or FText, or "" when there is none
local function text_of(value)
    if value == nil then
        return ""
    end
    if type(value) == "string" then
        return value
    end
    local text = try(function() return value:ToString() end)
    return type(text) == "string" and text or ""
end

-- Keeps text within Discord's limit of 128 characters per line
local function shorten(text)
    if #text <= 128 then
        return text
    end
    return text:sub(1, 125) .. "..."
end

-- "client" for the game you play, something else for a server
-- The hunt servers on this PC run the same game with the same mods.
local function process_role()
    local local_app_data = (os.getenv("LOCALAPPDATA") or "") .. "\\"
    local server_home = local_app_data:match("\\(srvhome%d*)\\")
    if server_home then
        return server_home
    end
    if os.getenv("GAMESERVER_BINARY_PATH") then
        return "server162"
    end
    return "client"
end

-- The process id sent with the status. Discord refuses a status without one ("nonzero pid required"). The game's own
-- process id ties the status to the "Playing Dauntless" Discord detected.
-- It still goes away when the game closes: Discord clears a status when its connection closes.
local FALLBACK_PROCESS_ID = 4
local function game_process_id()
    local log_path = (os.getenv("LOCALAPPDATA") or "") .. "\\d1147_dxgi.log"
    local file = io.open(log_path, "rb")
    if not file then
        return FALLBACK_PROCESS_ID
    end
    local size = file:seek("end") or 0
    local start = size > 8192 and size - 8192 or 0
    file:seek("set", start)
    local tail = file:read("a") or ""
    file:close()
    local newest = nil
    for process_id in tail:gmatch("pid (%d+):") do
        newest = tonumber(process_id)
    end
    return newest or FALLBACK_PROCESS_ID
end

return {
    log = log,
    try = try,
    is_alive = is_alive,
    text_of = text_of,
    shorten = shorten,
    process_role = process_role,
    game_process_id = game_process_id,
}
