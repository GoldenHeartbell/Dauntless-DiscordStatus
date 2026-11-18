-- DiscordStatus (UE4SS 3.0.1 Lua mod for Dauntless 1.14.7, Dauntless Forever Modded mode) - by GoldenHeartbell
-- Licence: AGPL-3.0
--
-- ds_discord.lua: the connection to the Discord app on this PC, over Discord's local pipe (\\.\pipe\discord-ipc-0,
-- the "Rich Presence" connection games use). Each message is [opcode, 4 bytes][length, 4 bytes][JSON].
-- It only ever WRITES to the pipe, so the game never waits for Discord. When Discord is closed or restarts, the next
-- write fails and it connects again later. Call setup() once, then show_on_discord() with each status.

local helpers = require("ds_helpers")
local log = helpers.log
local try = helpers.try

-- ===================================================================================================================
-- JSON (Discord's messages are JSON; only what this mod sends: objects, strings, numbers, booleans)
-- ===================================================================================================================

local encode_json

-- One JSON string with quotes and escapes
local function encode_json_string(text)
    local escaped = text:gsub('[%c"\\]', function(character)
        if character == '"' then return '\\"' end
        if character == "\\" then return "\\\\" end
        if character == "\n" then return "\\n" end
        if character == "\r" then return "\\r" end
        if character == "\t" then return "\\t" end
        return string.format("\\u%04x", character:byte())
    end)
    return '"' .. escaped .. '"'
end

-- Any value this mod uses, as JSON text. Object keys are sorted so the same status always gives the same text.
encode_json = function(value)
    local kind = type(value)
    if kind == "string" then
        return encode_json_string(value)
    end
    if kind == "number" then
        if value == math.floor(value) then
            return string.format("%d", value)
        end
        return tostring(value)
    end
    if kind == "boolean" then
        return value and "true" or "false"
    end
    if kind == "table" then
        local keys = {}
        for key in pairs(value) do
            table.insert(keys, key)
        end
        table.sort(keys)
        local parts = {}
        for _, key in ipairs(keys) do
            table.insert(parts, encode_json_string(key) .. ":" .. encode_json(value[key]))
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

-- ===================================================================================================================
-- The connection (write only)
-- ===================================================================================================================

-- Set by setup()
local application_id = ""
local status_process_id = 0
local seconds_between_retries = 20

-- The same status is sent again every 30 seconds: Discord drops a status that arrives before it has detected the
-- game. 30 s stays well inside Discord's
local SECONDS_BETWEEN_REFRESHES = 30

local discord_pipe = nil
local next_connect_attempt = 0
local last_sent_activity = nil
local next_refresh_at = 0
local message_counter = 0

-- Remembers which Discord application to use, which process id to send, and how long to wait before reconnecting
local function setup(new_application_id, new_status_process_id, new_seconds_between_retries)
    application_id = new_application_id
    status_process_id = new_status_process_id
    seconds_between_retries = new_seconds_between_retries
end

-- Sends one message. Returns false when Discord is gone.
local function send_to_discord(opcode, message)
    if not discord_pipe then
        return false
    end
    local json = encode_json(message)
    local frame = string.pack("<i4i4", opcode, #json) .. json
    local ok = try(function()
        local written = discord_pipe:write(frame)
        return written ~= nil and discord_pipe:flush() ~= nil
    end)
    if ok then
        return true
    end
    log("Discord closed the connection; trying again in " .. seconds_between_retries .. " seconds")
    try(function() discord_pipe:close() end)
    discord_pipe = nil
    last_sent_activity = nil
    next_connect_attempt = os.time() + seconds_between_retries
    return false
end

-- Opens Discord's pipe (discord-ipc-0, or -1 ... -9 when several Discord apps run) and says hello
local function connect_to_discord()
    if discord_pipe or os.time() < next_connect_attempt then
        return
    end
    next_connect_attempt = os.time() + seconds_between_retries
    for pipe_number = 0, 9 do
        local pipe = io.open("\\\\.\\pipe\\discord-ipc-" .. pipe_number, "r+b")
        if pipe then
            pipe:setvbuf("no")
            discord_pipe = pipe
            if send_to_discord(0, { v = 1, client_id = application_id }) then
                log("connected to Discord (pipe discord-ipc-" .. pipe_number .. ")")
            end
            return
        end
    end
end

-- Puts this status on the Discord profile: when it changed, and again every 30 seconds
local function show_on_discord(activity)
    connect_to_discord()
    if not discord_pipe then
        return
    end
    local activity_json = encode_json(activity)
    local is_refresh = activity_json == last_sent_activity
    if is_refresh and os.time() < next_refresh_at then
        return
    end
    message_counter = message_counter + 1
    local arguments = { activity = activity, pid = status_process_id }
    local message = { cmd = "SET_ACTIVITY", args = arguments, nonce = tostring(message_counter) }
    if send_to_discord(1, message) then
        last_sent_activity = activity_json
        next_refresh_at = os.time() + SECONDS_BETWEEN_REFRESHES
        if is_refresh then
            return
        end
        log("sent to Discord: " .. tostring(activity.details) .. " | " .. tostring(activity.state or "(no weapon)"))
    end
end

return {
    setup = setup,
    show_on_discord = show_on_discord,
}
