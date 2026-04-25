-- ============================================================
-- FrostSeek - Chat Filter Module
-- ============================================================

local FrostSeek = _G.FrostSeek
local ChatFilter = {}
local FILTER_LOG_LIMIT = 20
local DEDUPLICATE_INTERVAL = 0.5
local MAX_SPAM_MESSAGES_PER_PLAYER = 5
local SPAM_WINDOW = 30
local filterLog = {}
local spamTracker = {}
local lastDedupeKey = nil
local lastDedupeTime = 0

local function InitDB()
    FrostSeekDB.ChatFilter = FrostSeekDB.ChatFilter or {}
    FrostSeekDB.ChatFilter.enabled = FrostSeekDB.ChatFilter.enabled ~= false
    FrostSeekDB.ChatFilter.filterWorldLFG = FrostSeekDB.ChatFilter.filterWorldLFG ~= false
    FrostSeekDB.ChatFilter.filterBoost = FrostSeekDB.ChatFilter.filterBoost ~= false
    FrostSeekDB.ChatFilter.filterGuild = FrostSeekDB.ChatFilter.filterGuild or false
    FrostSeekDB.ChatFilter.customKeywords = FrostSeekDB.ChatFilter.customKeywords or {}
    FrostSeekDB.ChatFilter.filterLFGChannels = FrostSeekDB.ChatFilter.filterLFGChannels or {}
end

local function RegisterChatFilterModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterChatFilterModule)
        return
    end
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("chatfilter", ChatFilter)
    end
end

local function AddLog(player, msg, trigger)
    local key = player .. "|" .. (trigger or "") .. "|" .. (msg or "")
    if lastDedupeKey == key and (GetTime() - lastDedupeTime) < DEDUPLICATE_INTERVAL then
        return
    end
    lastDedupeKey = key
    lastDedupeTime = GetTime()

    local entry = string.format("|cff88ccff[Filtered]|r |cffff8800[%s]|r |cffd3d3d3%s: %s|r",
        trigger or "unknown", player or "?", msg or "")
    table.insert(filterLog, 1, entry)
    if #filterLog > FILTER_LOG_LIMIT then
        table.remove(filterLog)
    end
end

local function IsSpamBurst(sender)
    if not spamTracker[sender] then
        spamTracker[sender] = { count = 0, startTime = GetTime() }
    end

    local entry = spamTracker[sender]
    local now = GetTime()

    if (now - entry.startTime) > SPAM_WINDOW then
        entry.count = 1
        entry.startTime = now
        return false
    end

    entry.count = entry.count + 1
    return entry.count > MAX_SPAM_MESSAGES_PER_PLAYER
end

local function MatchesCustomKeywords(msg)
    local db = FrostSeekDB.ChatFilter
    if not db or not db.customKeywords then return false, nil end

    local lowerMsg = string.lower(msg)
    for _, word in ipairs(db.customKeywords) do
        if word ~= "" and string.find(lowerMsg, string.lower(word), 1, true) then
            return true, word
        end
    end
    return false, nil
end

local function MatchesChannelLFG(event, msg, channelName, ...)
    local db = FrostSeekDB.ChatFilter
    if not db then return false, nil end
    if event ~= "CHAT_MSG_CHANNEL" then return false, nil end
    if not db.filterWorldLFG and not db.filterLFGChannels then return false, nil end

    local isTargetChannel = false

    -- Check world channel by name
    if db.filterWorldLFG and channelName then
        if string.find(string.lower(channelName), "world", 1, true) then
            isTargetChannel = true
        end
    end

    -- Check specific channel numbers
    if not isTargetChannel and db.filterLFGChannels then
        local channelIndex = select(4, ...)
        if channelIndex and db.filterLFGChannels[channelIndex] then
            isTargetChannel = true
        end
    end

    if not isTargetChannel then return false, nil end

    local lowerMsg = string.lower(msg)

    if string.find(lowerMsg, "lfg", 1, true)
    or string.find(lowerMsg, "lfm", 1, true)
    or string.match(lowerMsg, "lf%d+m") then
        return true, "Channel LFG"
    end

    if string.find(lowerMsg, "lf", 1, true) then
        local roles = { "dps", "tank", "heal", "healer", "heals" }
        for _, role in ipairs(roles) do
            if string.find(lowerMsg, role, 1, true) then
                return true, "Channel LF Role"
            end
        end
    end

    return false, nil
end

local function MatchesBoostFilter(msg)
    local db = FrostSeekDB.ChatFilter
    if not db or not db.filterBoost then return false, nil end

    local lowerMsg = string.lower(msg)
    local boostWords = {
        "wts", "wtb", "selling", "boost", "boosting", "carry",
        "gdkp", "pilot", "piloted", "cheap", "price", "service"
    }

    for _, word in ipairs(boostWords) do
        if string.find(lowerMsg, word, 1, true) then
            return true, "Boost/Trade"
        end
    end
    return false, nil
end

-- ==================== FILTRO GUILD RECRUIT ====================
local function MatchesGuildFilter(msg)
    local db = FrostSeekDB.ChatFilter
    if not db or not db.filterGuild then return false, nil end

    local lowerMsg = string.lower(msg)
    local guildWords = {
        "guild", "community", "recruit", "recruiting", "roster",
        "lf members", "lf guild", "new guild", "apply",
        "core group", "core team", "static group", "raid team",
        "looking for members", "looking for a guild", "guild is looking",
        "active members", "friendly guild", "pve guild", "pvp guild"
    }

    for _, word in ipairs(guildWords) do
        if string.find(lowerMsg, word, 1, true) then
            return true, "Guild Recruit"
        end
    end
    return false, nil
end

local function ChatFilter_OnEvent(self, event, msg, player, language, channelName, ...)
    if not FrostSeekDB.ChatFilter then
        FrostSeekDB.ChatFilter = {
            enabled = true,
            filterWorldLFG = true,
            filterBoost = true,
            filterGuild = false,
            customKeywords = {},
            filterLFGChannels = {}
        }
    end

    local db = FrostSeekDB.ChatFilter
    if not db.enabled then return false end
    if not msg or not player then return false end

    player = string.gsub(player, "%-[^|]+", "")
    if player == UnitName("player") then return false end

    local matched, trigger

    if IsSpamBurst(player) then
        AddLog(player, msg, "Spam Burst")
        return true
    end

    matched, trigger = MatchesCustomKeywords(msg)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    matched, trigger = MatchesChannelLFG(event, msg, channelName, ...)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    matched, trigger = MatchesBoostFilter(msg)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    matched, trigger = MatchesGuildFilter(msg)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    return false
end

C_Timer.NewTicker(60, function()
    local now = GetTime()
    for name, entry in pairs(spamTracker) do
        if (now - entry.startTime) > SPAM_WINDOW * 2 then
            spamTracker[name] = nil
        end
    end
end)

local function RegisterFilters()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter_OnEvent)
end

InitDB()
RegisterFilters()
RegisterChatFilterModule()