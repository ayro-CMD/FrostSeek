--[[
==============================================================================
 FrostSeek - Advanced LFG/LFM Manager
==============================================================================
 Copyright (c) 2026 Ayro. All rights reserved.

 License: FrostSeek Proprietary License - All Rights Reserved
 Author:  Ayro

 This source code is the proprietary intellectual property of Ayro.
 Unauthorized copying, modification, redistribution, or use of any part of
 this code, in whole or in part, via any medium, is strictly prohibited
 without the express written permission of the author.

 For licensing inquiries, contact the author via the official repository:
   CurseForge Project ID: 1460315

 Watermark: FSK-WM-36DA8EFBD010-FSK-AYRO-2026-7F3C-9A21-BD54-8E1F
==============================================================================
]]



local FrostSeek = _G.FrostSeek
local Shared = _G.FrostSeekShared
local UI = _G.FrostSeekUIUtils
local L = FrostSeek and FrostSeek.L or {}
local Community = _G.FrostSeek and _G.FrostSeek.Community
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("community_events", Community)
local _tc = Shared and Shared._tc or function(t) return {0.5, 0.5, 0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end
local EVENT_TYPES = { "Dungeon", "World Boss", "Invasion", "PvP", "Social", "Other" }
local EVENT_EXPIRES = { "1 hour", "Tonight", "1 day", "7 days", "Never" }
local EVENT_TYPE_COLOR = {
    ["Dungeon"]    = "|cff44aaff",
    ["World Boss"] = "|cffff55ff",
    ["Invasion"]   = "|cffff7733",
    ["PvP"]        = "|cffff5555",
    ["Social"]     = "|cff44ff66",
    ["Other"]      = "|cffffcc00",
}
local EVENT_EXPIRE_SECONDS = {
    ["1 hour"]  = 3600,
    ["Tonight"] = 21600,
    ["1 day"]   = 86400,
    ["7 days"]  = 604800,
    ["Never"]   = 0,
}
local EVENT_CHANNEL = "FSK-EVT"
local EVENT_CHANNEL_SLOT = 13
local EVENT_PREFIX = "FSKE1"
local EVENT_QUERY_PREFIX = "FSKEQ"
local EVENT_RESPONSE_PREFIX = "FSKER"
local EVENT_SEP = "~"
local EVENT_REBROADCAST_INTERVAL = 600
local EVENT_MAX_LOCAL_EVENTS = 60

local function EventNow()
    return time()
end

local function EventPlayer()
    return UnitName("player") or L["community_default_player_name"]
end

local function EventClean(s, maxLen)
    s = tostring(s or "")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    s = string.gsub(s, EVENT_SEP, " ")
    s = string.gsub(s, "[\r\n]", " ")
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|H[^|]+|h", "")
    s = string.gsub(s, "|h", "")
    s = string.gsub(s, "%s+", " ")
    maxLen = tonumber(maxLen) or 0
    if maxLen > 0 and string.len(s) > maxLen then
        s = string.sub(s, 1, maxLen)
    end
    return s
end

local function EventShort(s, n)
    s = tostring(s or "")
    n = tonumber(n) or 0
    if n > 0 and string.len(s) > n then
        return string.sub(s, 1, math.max(1, n - 3)) .. "..."
    end
    return s
end

local function EventNameKey(name)
    name = string.lower(EventClean(name))
    name = string.gsub(name, "%-.+$", "")
    return name
end

local function EventExpireText(expires)
    expires = tonumber(expires or 0) or 0
    if expires == 0 then return L["event_never_label"] end
    local left = expires - EventNow()
    if left <= 0 then return L["event_expired_label"] end
    if left < 3600 then return tostring(math.max(1, math.floor(left / 60))) .. "m" end
    if left < 86400 then return tostring(math.floor(left / 3600)) .. "h" end
    return tostring(math.floor(left / 86400)) .. "d"
end

local function EventIsExpired(row, nowValue)
    local exp = tonumber(row and row.expires or 0) or 0
    if exp == 0 then return false end
    return exp <= (tonumber(nowValue) or EventNow())
end

local function EventSplit(s)
    local t = {}
    s = tostring(s or "")
    local start = 1
    while true do
        local pos = string.find(s, EVENT_SEP, start, true)
        if not pos then
            table.insert(t, string.sub(s, start))
            break
        end
        table.insert(t, string.sub(s, start, pos - 1))
        start = pos + 1
    end
    return t
end

local function EventDB()
    FrostSeekDB.CommunityEvents = FrostSeekDB.CommunityEvents or {}
    local db = FrostSeekDB.CommunityEvents
    db.events = db.events or {}
    db.dismissed = db.dismissed or {}
    db.filter = db.filter or "All"
    db.myOnly = db.myOnly or false
    return db
end

local function EventNormalizeType(t)
    t = EventClean(t or "Other", 18)
    for _, v in ipairs(EVENT_TYPES) do
        if t == v then return t end
    end
    return "Other"
end

local function EventStore(id, sender, created, expires, typeName, name, timeText, host, contact, description, localOnly)
    local db = EventDB()
    id = EventClean(id, 64)
    if id == "" then return nil end
    created = tonumber(created) or EventNow()
    expires = tonumber(expires) or 0
    if expires ~= 0 and expires <= EventNow() then return nil end
    local row = {
        id = id,
        sender = EventClean(sender or host or "", 40),
        created = created,
        expires = expires,
        type = EventNormalizeType(typeName),
        name = EventClean(name or L["community_default_event_name"], 64),
        timeText = EventClean(timeText or "", 40),
        host = EventClean(host or sender or "", 40),
        contact = EventClean(contact or "", 64),
        description = EventClean(description or "", 180),
        localOnly = localOnly and true or false,
    }
    local replaced = false
    for i, old in ipairs(db.events) do
        if tostring(old.id or "") == id then
            row.localOnly = old.localOnly or row.localOnly
            db.events[i] = row
            replaced = true
            break
        end
    end
    if not replaced then
        table.insert(db.events, 1, row)
    end
    table.sort(db.events, function(a, b)
        return (tonumber(a.created) or 0) > (tonumber(b.created) or 0)
    end)
    while #db.events > EVENT_MAX_LOCAL_EVENTS do
        table.remove(db.events)
    end
    return row
end

local function EventClearExpired(silent)
    local db = EventDB()
    local now = EventNow()
    local kept = {}
    local removed = 0
    for _, row in ipairs(db.events or {}) do
        local id = tostring((row and row.id) or "")
        if row and id ~= "" and EventIsExpired(row, now) then
            removed = removed + 1
            if db.dismissed then db.dismissed[id] = nil end
        elseif row then
            table.insert(kept, row)
        end
    end
    if removed > 0 then db.events = kept end
    return removed
end

function Community:GetEventRows()
    local db = EventDB()
    EventClearExpired(true)
    local rows = {}
    local filter = tostring(db.filter or "All")
    local myOnly = db.myOnly and true or false
    local now = EventNow()
    local me = EventNameKey(EventPlayer())
    for _, row in ipairs(db.events or {}) do
        local id = tostring(row.id or "")
        local expired = EventIsExpired(row, now)
        if not expired and id ~= "" and not db.dismissed[id] then
            local matchType = (filter == "All" or row.type == filter)
            local matchMine = (not myOnly) or EventNameKey(row.host) == me or EventNameKey(row.sender) == me
            if matchType and matchMine then
                table.insert(rows, row)
            end
        end
    end
    table.sort(rows, function(a, b)
        return (tonumber(a.created) or 0) > (tonumber(b.created) or 0)
    end)
    return rows
end

local _eventRetryQueue = {}
local _eventRetryScheduled = false

local function EventSendNow(payload)
    local id
    pcall(function() id = GetChannelName(EVENT_CHANNEL) end)
    if id and id ~= 0 then
        pcall(function() SendChatMessage(payload, "CHANNEL", nil, id) end)
        return true
    end
    local Compat = _G.FrostSeekCompat
    if Compat and Compat.ChannelAPI and Compat.ChannelAPI.JoinChannel then
        pcall(function() Compat.ChannelAPI.JoinChannel(EVENT_CHANNEL, nil, EVENT_CHANNEL_SLOT) end)
    else
        pcall(function() JoinChannelByName(EVENT_CHANNEL, nil, nil, EVENT_CHANNEL_SLOT) end)
    end
    return false
end

local function EventFlushRetryQueue()
    _eventRetryScheduled = false
    local stillPending = {}
    for _, entry in ipairs(_eventRetryQueue) do
        if EventSendNow(entry.payload) then
        
        else
            entry.tries = entry.tries + 1
            if entry.tries < 3 then
                stillPending[#stillPending + 1] = entry
            end
        end
    end
    _eventRetryQueue = stillPending
    if #_eventRetryQueue > 0 and not _eventRetryScheduled then
        _eventRetryScheduled = true
        C_Timer.After(2, EventFlushRetryQueue)
    end
end

local function EventSend(payload)
    payload = tostring(payload or "")
    if payload == "" then return false end
    if EventSendNow(payload) then return true end
    _eventRetryQueue[#_eventRetryQueue + 1] = { payload = payload, tries = 1 }
    if not _eventRetryScheduled then
        _eventRetryScheduled = true
        C_Timer.After(2, EventFlushRetryQueue)
    end
    return false
end

local function EventSerialize(row)
    if not row or not row.id then return nil end
    local parts = {
        EVENT_PREFIX,
        EventClean(row.id, 64),
        EventClean(row.type or "Other", 18),
        EventClean(row.name or L["community_default_event_name"], 64),
        EventClean(row.timeText or "", 40),
        EventClean(row.host or "", 40),
        EventClean(row.contact or "", 64),
        tostring(row.expires or 0),
        EventClean(row.description or "", 180),
    }
    return table.concat(parts, EVENT_SEP)
end

local function EventParseBody(body)
    if not body or body == "" then return nil end
    local parts = EventSplit(body)
    if #parts < 8 then return nil end
    return {
        id = parts[1],
        type = EventNormalizeType(parts[2]),
        name = parts[3],
        timeText = parts[4],
        host = parts[5],
        contact = parts[6],
        expires = tonumber(parts[7]) or 0,
        description = parts[8],
        created = EventNow(),
    }
end

local function EventParse(raw)
    if not raw then return nil end
    if string.sub(raw, 1, string.len(EVENT_PREFIX)) ~= EVENT_PREFIX then return nil end
    local body = string.sub(raw, string.len(EVENT_PREFIX) + 1)
    if string.sub(body, 1, 1) == EVENT_SEP then
        body = string.sub(body, 2)
    end
    return EventParseBody(body)
end

local function EventParseResponse(raw)
    if not raw then return nil end
    if string.sub(raw, 1, string.len(EVENT_RESPONSE_PREFIX)) ~= EVENT_RESPONSE_PREFIX then return nil end
    local body = string.sub(raw, string.len(EVENT_RESPONSE_PREFIX) + 1)
    if string.sub(body, 1, 1) == EVENT_SEP then
        body = string.sub(body, 2)
    end
    return EventParseBody(body)
end

local function EventSendQuery()
    EventSend(EVENT_QUERY_PREFIX .. "~" .. tostring(EventPlayer()))
end

local function EventSendResponse(row)
    if not row then return end
    local payload = EventSerialize(row)
    if not payload then return end
    EventSend(EVENT_RESPONSE_PREFIX .. payload:sub(string.len(EVENT_PREFIX) + 1))
end

local function EventBroadcastRow(row)
    if not row then return end
    local payload = EventSerialize(row)
    if payload then
        EventSend(payload)
    end
end

local eventListenerInstalled = false
local lastQueryAt = 0
local lastRebroadcastAt = 0

local function EventRebroadcastAll()
    local db = EventDB()
    EventClearExpired(true)
    if not db.events or #db.events == 0 then return end
    local me = EventNameKey(EventPlayer())
    local sent = 0
    for _, row in ipairs(db.events) do
        if row and not EventIsExpired(row, EventNow()) then
            local hostKey = EventNameKey(row.host or "")
            local senderKey = EventNameKey(row.sender or "")
            if hostKey == me or senderKey == me or row.localOnly then
                EventBroadcastRow(row)
                sent = sent + 1
                if sent >= 5 then break end
            end
        end
    end
end

local function EventRespondToQuery()
    local db = EventDB()
    EventClearExpired(true)
    if not db.events or #db.events == 0 then return end
    local sent = 0
    for _, row in ipairs(db.events) do
        if row and not EventIsExpired(row, EventNow()) then
            EventSendResponse(row)
            sent = sent + 1
            if sent >= 8 then break end
        end
    end
end

local function EventInstallListener()
    if eventListenerInstalled then return end
    eventListenerInstalled = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:SetScript("OnEvent", function(_, event, msg, sender, _, _, _, _, chanNum, chanName)
        if event ~= "CHAT_MSG_CHANNEL" then return end
        if not msg then return end
        local isEVT = false
        if chanName and tostring(chanName) ~= "" and string.lower(tostring(chanName)) == string.lower(EVENT_CHANNEL) then
            isEVT = true
        elseif chanNum and tonumber(chanNum) and GetChannelName then
            local id = GetChannelName(chanNum)
            if id and tostring(id) == tostring(chanNum) then
                local nm = select(2, GetChannelName(chanNum))
                if nm and string.lower(tostring(nm)) == string.lower(EVENT_CHANNEL) then
                    isEVT = true
                end
            end
        end
        if not isEVT then
            if string.sub(msg, 1, string.len(EVENT_PREFIX)) == EVENT_PREFIX then
                isEVT = true
            elseif string.sub(msg, 1, string.len(EVENT_QUERY_PREFIX)) == EVENT_QUERY_PREFIX then
                isEVT = true
            elseif string.sub(msg, 1, string.len(EVENT_RESPONSE_PREFIX)) == EVENT_RESPONSE_PREFIX then
                isEVT = true
            end
        end
        if not isEVT then return end
        local senderClean = tostring(sender or "")
        if string.find(senderClean, "-", 1, true) then
            senderClean = string.sub(senderClean, 1, string.find(senderClean, "-", 1, true) - 1)
        end
        if senderClean == EventPlayer() then return end

        if string.sub(msg, 1, string.len(EVENT_QUERY_PREFIX)) == EVENT_QUERY_PREFIX then
            local now = EventNow()
            if (now - lastQueryAt) < 5 then return end
            lastQueryAt = now
            C_Timer.After(math.random(1, 30) / 10, function()
                EventRespondToQuery()
            end)
            return
        end

        local row
        if string.sub(msg, 1, string.len(EVENT_RESPONSE_PREFIX)) == EVENT_RESPONSE_PREFIX then
            row = EventParseResponse(msg)
        else
            row = EventParse(msg)
        end
        if not row or not row.id or row.id == "" then return end
        EventStore(row.id, senderClean, row.created, row.expires, row.type, row.name, row.timeText, row.host, row.contact, row.description, false)
        if Community.frame and Community.frame:IsVisible() and Community.activeSubTab == "events" then
            pcall(function() Community:RefreshEventBoard() end)
        end
    end)
    local Compat = _G.FrostSeekCompat
    local function JoinEventChannel()
        if Compat and Compat.ChannelAPI and Compat.ChannelAPI.JoinChannel then
            pcall(function() Compat.ChannelAPI.JoinChannel(EVENT_CHANNEL, nil, EVENT_CHANNEL_SLOT) end)
        else
            pcall(function() JoinChannelByName(EVENT_CHANNEL, nil, nil, EVENT_CHANNEL_SLOT) end)
        end
    end
    C_Timer.After(10, JoinEventChannel)
    C_Timer.NewTicker(300, function()
        EventClearExpired(true)
    end)
    C_Timer.NewTicker(60, function()
        local now = EventNow()
        if (now - lastRebroadcastAt) >= EVENT_REBROADCAST_INTERVAL then
            lastRebroadcastAt = now
            EventRebroadcastAll()
        end
    end)
    C_Timer.After(8, function()
        lastRebroadcastAt = EventNow()
        EventSendQuery()
        C_Timer.After(2, function()
            EventRebroadcastAll()
        end)
    end)
end

function Community:PostEvent(typeName, name, timeText, host, contact, description, expiresLabel)
    if not name or EventClean(name, 64) == "" then
        print("|cffff5555FrostSeek:|r " .. L["event_board_invalid"])
        return false
    end
    local id = EventPlayer() .. "_" .. tostring(EventNow()) .. "_" .. tostring(math.random(1000, 9999))
    local expires = EVENT_EXPIRE_SECONDS[expiresLabel or "1 day"] or 86400
    if expires ~= 0 then
        expires = EventNow() + expires
    end
    local row = EventStore(id, EventPlayer(), EventNow(), expires, typeName, name, timeText, host, contact, description, false)
    if not row then
        print("|cffff5555FrostSeek:|r " .. L["event_board_invalid"])
        return false
    end
    local payload = EventSerialize(row)
    local sentOK = false
    if payload then
        sentOK = EventSend(payload)
    end
    if sentOK then
        print("|cff88ccffFrostSeek:|r " .. L["event_board_posted"])
    else
        print("|cffffaa00FrostSeek:|r " .. L["event_board_queued"])
    end
    self:RefreshEventBoard()
    return true
end

function Community:DismissEvent(id)
    if not id then return end
    local db = EventDB()
    db.dismissed[tostring(id)] = true
    print("|cff88ccffFrostSeek:|r " .. L["event_board_dismissed"])
    self:RefreshEventBoard()
end

function Community:ClearAllEvents()
    local db = EventDB()
    db.events = {}
    db.dismissed = {}
    print("|cff88ccffFrostSeek:|r " .. L["event_board_cleared"])
    self:RefreshEventBoard()
end

function Community:BuildEventBoardFrame()
    if not self.frame then return end
    local F = self.frame
    local pad = 10
    local curY = self.contentY

    local ef = CreateFrame("Frame", nil, F)
    ef:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    ef:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad, pad)
    self.eventsFrame = ef

    local header = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    header:SetPoint("TOPLEFT", ef, "TOPLEFT", 0, 0)
    header:SetText(_hex("textDim") .. L["event_board_discovered"] .. "|r")
    curY = -20

    local filterLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", ef, "TOPLEFT", 0, curY)
    filterLabel:SetText(_hex("textDim") .. L["event_board_filter"] .. ":|r")

    local filterValues = { "All", "Dungeon", "World Boss", "Invasion", "PvP", "Social", "Other" }
    local filterBtn = CreateFrame("Button", nil, ef)
    filterBtn:SetSize(90, 22)
    filterBtn:SetPoint("LEFT", filterLabel, "RIGHT", 6, 0)
    filterBtn.bg = filterBtn:CreateTexture(nil, "BACKGROUND")
    filterBtn.bg:SetAllPoints()
    filterBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    filterBtn.border = filterBtn:CreateTexture(nil, "BORDER")
    filterBtn.border:SetAllPoints()
    filterBtn.border:SetColorTexture(unpack(_tc("border")))
    filterBtn.text = filterBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    filterBtn.text:SetPoint("CENTER")
    filterBtn.text:SetText(L["filter_all"])
    filterBtn:SetScript("OnClick", function()
        local db = EventDB()
        local idx = 1
        for i, v in ipairs(filterValues) do
            if v == db.filter then idx = i break end
        end
        idx = (idx % #filterValues) + 1
        db.filter = filterValues[idx]
        filterBtn.text:SetText(db.filter)
        Community:RefreshEventBoard()
    end)
    self.eventFilterBtn = filterBtn

    local myToggle = CreateFrame("CheckButton", nil, ef, "UICheckButtonTemplate")
    myToggle:SetSize(20, 20)
    myToggle:SetPoint("LEFT", filterBtn, "RIGHT", 12, 0)
    myToggle:SetScript("OnClick", function()
        local db = EventDB()
        db.myOnly = not db.myOnly
        myToggle:SetChecked(db.myOnly)
        Community:RefreshEventBoard()
    end)
    local myLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    myLabel:SetPoint("LEFT", myToggle, "RIGHT", 2, 0)
    myLabel:SetText(_hex("textDim") .. L["event_board_my_events"] .. "|r")
    self.eventMyToggle = myToggle

    local clearBtn = CreateFrame("Button", nil, ef)
    clearBtn:SetSize(85, 22)
    clearBtn:SetPoint("TOPRIGHT", ef, "TOPRIGHT", 0, 0)
    clearBtn.bg = clearBtn:CreateTexture(nil, "BACKGROUND")
    clearBtn.bg:SetPoint("TOPLEFT", 1, -1)
    clearBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    clearBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    clearBtn.border = clearBtn:CreateTexture(nil, "BORDER")
    clearBtn.border:SetAllPoints()
    clearBtn.border:SetColorTexture(unpack(_tc("border")))
    clearBtn.hoverTex = clearBtn:CreateTexture(nil, "HIGHLIGHT")
    clearBtn.hoverTex:SetAllPoints()
    clearBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    clearBtn.accent = clearBtn:CreateTexture(nil, "OVERLAY")
    clearBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    clearBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    clearBtn.accent:SetHeight(2)
    clearBtn.accent:SetColorTexture(unpack(_tc("danger")))
    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    clearBtn.text:SetPoint("CENTER")
    clearBtn.text:SetText("|cffff7755" .. L["community_clear_all"] .. "|r")
    clearBtn:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    clearBtn:SetScript("OnLeave", function(self)
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    clearBtn:SetScript("OnClick", function()
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog(L["community_clear_events_title"], L["community_clear_events_msg"], function()
                Community:ClearAllEvents()
            end)
        else
            Community:ClearAllEvents()
        end
    end)
    self.eventClearBtn = clearBtn

    local refreshBtn = CreateFrame("Button", nil, ef)
    refreshBtn:SetSize(80, 22)
    refreshBtn:SetPoint("TOPRIGHT", ef, "TOPRIGHT", -90, 0)
    refreshBtn.bg = refreshBtn:CreateTexture(nil, "BACKGROUND")
    refreshBtn.bg:SetPoint("TOPLEFT", 1, -1)
    refreshBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    refreshBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    refreshBtn.border = refreshBtn:CreateTexture(nil, "BORDER")
    refreshBtn.border:SetAllPoints()
    refreshBtn.border:SetColorTexture(unpack(_tc("border")))
    refreshBtn.hoverTex = refreshBtn:CreateTexture(nil, "HIGHLIGHT")
    refreshBtn.hoverTex:SetAllPoints()
    refreshBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    refreshBtn.accent = refreshBtn:CreateTexture(nil, "OVERLAY")
    refreshBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    refreshBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    refreshBtn.accent:SetHeight(2)
    refreshBtn.accent:SetColorTexture(unpack(_tc("accentBar")))
    refreshBtn.text = refreshBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    refreshBtn.text:SetPoint("CENTER")
    refreshBtn.text:SetText("|cff88ccff" .. L["community_refresh"] .. "|r")
    refreshBtn:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    refreshBtn:SetScript("OnLeave", function(self)
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    refreshBtn:SetScript("OnClick", function()
        Community:RequestEventsFromPeers()
        Community:RefreshEventBoard()
        print(L["msg_events_requested"])
    end)
    self.eventRefreshBtn = refreshBtn

    curY = curY - 30

    local scrollFrame = CreateFrame("ScrollFrame", "FrostSeekEventBoardScroll", ef, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", ef, "TOPLEFT", 0, curY)
    scrollFrame:SetPoint("TOPRIGHT", ef, "TOPRIGHT", -20, curY)
    scrollFrame:SetPoint("BOTTOM", ef, "BOTTOM", 0, 240)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(740)
    scrollChild:SetHeight(400)
    scrollFrame:SetScrollChild(scrollChild)
    self.eventScrollChild = scrollChild

    local hY = -2
    local headers = {
        { text = L["event_board_type"],        x = 5,   w = 80 },
        { text = L["event_board_name"],        x = 90,  w = 180 },
        { text = L["event_board_time"],        x = 275, w = 100 },
        { text = L["event_board_host"],        x = 380, w = 110 },
        { text = L["event_board_expires"],     x = 495, w = 60 },
        { text = L["event_board_description"], x = 560, w = 180 },
    }
    for _, h in ipairs(headers) do
        local hs = scrollChild:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        hs:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", h.x, hY)
        hs:SetWidth(h.w)
        hs:SetText(_hex("textDim") .. h.text .. "|r")
    end

    self.eventRows = {}
    for i = 1, 30 do
        local row = CreateFrame("Button", nil, scrollChild)
        row:SetSize(740, 22)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -20 - (i - 1) * 22)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)

        row.typeText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.typeText:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -4)
        row.typeText:SetWidth(80)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 90, -4)
        row.nameText:SetWidth(180)

        row.timeText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.timeText:SetPoint("TOPLEFT", row, "TOPLEFT", 275, -4)
        row.timeText:SetWidth(100)

        row.hostText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.hostText:SetPoint("TOPLEFT", row, "TOPLEFT", 380, -4)
        row.hostText:SetWidth(110)

        row.expiresText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.expiresText:SetPoint("TOPLEFT", row, "TOPLEFT", 495, -4)
        row.expiresText:SetWidth(60)

        row.descText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.descText:SetPoint("TOPLEFT", row, "TOPLEFT", 560, -4)
        row.descText:SetWidth(180)

        row.dismissBtn = CreateFrame("Button", nil, row)
        row.dismissBtn:SetSize(60, 18)
        row.dismissBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
        row.dismissBtn.bg = row.dismissBtn:CreateTexture(nil, "BACKGROUND")
        row.dismissBtn.bg:SetAllPoints()
        row.dismissBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
        row.dismissBtn.border = row.dismissBtn:CreateTexture(nil, "BORDER")
        row.dismissBtn.border:SetAllPoints()
        row.dismissBtn.border:SetColorTexture(unpack(_tc("border")))
        row.dismissBtn.text = row.dismissBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.dismissBtn.text:SetPoint("CENTER")
        row.dismissBtn.text:SetText("|cffff7755" .. L["community_dismiss"] .. "|r")
        row.dismissBtn:SetScript("OnEnter", function(self)
            self.border:SetColorTexture(unpack(_tc("borderHover")))
        end)
        row.dismissBtn:SetScript("OnLeave", function(self)
            self.border:SetColorTexture(unpack(_tc("border")))
        end)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.3, 0.6, 1.0, 0.1)
            if self.eventData then
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, -4)
                GameTooltip:ClearLines()
                local color = EVENT_TYPE_COLOR[self.eventData.type or "Other"] or "|cffffcc00"
                GameTooltip:AddLine(color .. "[" .. tostring(self.eventData.type or "Other") .. "]|r " .. EventShort(self.eventData.name or L["community_default_event_name"], 48), 1, 1, 1)
                GameTooltip:AddLine(" ")
                if self.eventData.timeText and self.eventData.timeText ~= "" then
                    GameTooltip:AddLine(L["tip_when_label"] .. self.eventData.timeText, 0.9, 0.9, 0.9)
                end
                if self.eventData.host and self.eventData.host ~= "" then
                    GameTooltip:AddLine(L["tip_host_label"] .. self.eventData.host, 0.9, 0.9, 0.9)
                end
                if self.eventData.contact and self.eventData.contact ~= "" then
                    GameTooltip:AddLine(L["tip_contact_label"] .. self.eventData.contact, 0.9, 0.9, 0.9)
                end
                if self.eventData.description and self.eventData.description ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(self.eventData.description, 0.85, 0.85, 0.85, true)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["tip_right_dismiss_left_copy"], 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(self, button)
            if not self.eventData then return end
            if button == "RightButton" then
                Community:DismissEvent(self.eventData.id)
            else
                local snippet = "[" .. tostring(self.eventData.type or "Other") .. "] " .. tostring(self.eventData.name or L["community_default_event_name"])
                if self.eventData.timeText and self.eventData.timeText ~= "" then
                    snippet = snippet .. " - " .. self.eventData.timeText
                end
                if self.eventData.host and self.eventData.host ~= "" then
                    snippet = snippet .. L["community_snippet_host_label"] .. self.eventData.host
                end
                if FrostSeekCompat and FrostSeekCompat.OpenChat then
                    FrostSeekCompat.OpenChat(snippet .. " ")
                elseif ChatFrame_OpenChat then
                    ChatFrame_OpenChat(snippet .. " ")
                end
            end
        end)

        row:Hide()
        self.eventRows[i] = row
    end

    self.eventStats = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.eventStats:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 220)
    self.eventStats:SetText(_hex("textDim") .. L["community_events_count_zero"])

    local createHeader = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    createHeader:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 200)
    createHeader:SetText(_hex("accent") .. L["event_board_create"] .. "|r")

    local typeLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    typeLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 178)
    typeLabel:SetText(_hex("textDim") .. L["event_board_type"] .. ":|r")

    local typeBtn = CreateFrame("Button", nil, ef)
    typeBtn:SetSize(110, 22)
    typeBtn:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 50, 174)
    typeBtn.bg = typeBtn:CreateTexture(nil, "BACKGROUND")
    typeBtn.bg:SetAllPoints()
    typeBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    typeBtn.border = typeBtn:CreateTexture(nil, "BORDER")
    typeBtn.border:SetAllPoints()
    typeBtn.border:SetColorTexture(unpack(_tc("border")))
    typeBtn.text = typeBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    typeBtn.text:SetPoint("CENTER")
    typeBtn.selected = "Dungeon"
    typeBtn.text:SetText(typeBtn.selected)
    typeBtn:SetScript("OnClick", function()
        local idx = 1
        for i, v in ipairs(EVENT_TYPES) do
            if v == typeBtn.selected then idx = i break end
        end
        idx = (idx % #EVENT_TYPES) + 1
        typeBtn.selected = EVENT_TYPES[idx]
        typeBtn.text:SetText(typeBtn.selected)
    end)
    self.eventTypeBtn = typeBtn

    local expiresLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    expiresLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 170, 178)
    expiresLabel:SetText(_hex("textDim") .. L["event_board_expires"] .. ":|r")

    local expiresBtn = CreateFrame("Button", nil, ef)
    expiresBtn:SetSize(100, 22)
    expiresBtn:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 220, 174)
    expiresBtn.bg = expiresBtn:CreateTexture(nil, "BACKGROUND")
    expiresBtn.bg:SetAllPoints()
    expiresBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    expiresBtn.border = expiresBtn:CreateTexture(nil, "BORDER")
    expiresBtn.border:SetAllPoints()
    expiresBtn.border:SetColorTexture(unpack(_tc("border")))
    expiresBtn.text = expiresBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    expiresBtn.text:SetPoint("CENTER")
    expiresBtn.selected = "1 day"
    expiresBtn.text:SetText(expiresBtn.selected)
    expiresBtn:SetScript("OnClick", function()
        local idx = 1
        for i, v in ipairs(EVENT_EXPIRES) do
            if v == expiresBtn.selected then idx = i break end
        end
        idx = (idx % #EVENT_EXPIRES) + 1
        expiresBtn.selected = EVENT_EXPIRES[idx]
        expiresBtn.text:SetText(expiresBtn.selected)
    end)
    self.eventExpiresBtn = expiresBtn

    local nameLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    nameLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 148)
    nameLabel:SetText(_hex("textDim") .. L["event_board_name"] .. ":|r")

    if UI and UI.CreateModernEditBox then
        self.eventName = UI.CreateModernEditBox(ef, 260, 20)
    else
        self.eventName = CreateFrame("EditBox", nil, ef)
        self.eventName:SetAutoFocus(false)
        self.eventName:SetFontObject("FSKFontNormalSmall")
        self.eventName:SetSize(260, 20)
    end
    self.eventName:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 50, 144)
    self.eventName:SetText("")
    self.eventName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.eventName:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local timeLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    timeLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 320, 148)
    timeLabel:SetText(_hex("textDim") .. L["event_board_time"] .. ":|r")

    if UI and UI.CreateModernEditBox then
        self.eventTime = UI.CreateModernEditBox(ef, 200, 20)
    else
        self.eventTime = CreateFrame("EditBox", nil, ef)
        self.eventTime:SetAutoFocus(false)
        self.eventTime:SetFontObject("FSKFontNormalSmall")
        self.eventTime:SetSize(200, 20)
    end
    self.eventTime:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 365, 144)
    self.eventTime:SetText("")
    self.eventTime:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.eventTime:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local hostLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    hostLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 118)
    hostLabel:SetText(_hex("textDim") .. L["event_board_host"] .. ":|r")

    if UI and UI.CreateModernEditBox then
        self.eventHost = UI.CreateModernEditBox(ef, 180, 20)
    else
        self.eventHost = CreateFrame("EditBox", nil, ef)
        self.eventHost:SetAutoFocus(false)
        self.eventHost:SetFontObject("FSKFontNormalSmall")
        self.eventHost:SetSize(180, 20)
    end
    self.eventHost:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 50, 114)
    self.eventHost:SetText(EventPlayer())
    self.eventHost:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.eventHost:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local contactLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    contactLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 240, 118)
    contactLabel:SetText(_hex("textDim") .. L["community_contact_label"])

    if UI and UI.CreateModernEditBox then
        self.eventContact = UI.CreateModernEditBox(ef, 240, 20)
    else
        self.eventContact = CreateFrame("EditBox", nil, ef)
        self.eventContact:SetAutoFocus(false)
        self.eventContact:SetFontObject("FSKFontNormalSmall")
        self.eventContact:SetSize(240, 20)
    end
    self.eventContact:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 300, 114)
    self.eventContact:SetText("")
    self.eventContact:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.eventContact:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local descLabel = ef:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    descLabel:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 0, 88)
    descLabel:SetText(_hex("textDim") .. L["event_board_description"] .. ":|r")

    if UI and UI.CreateModernEditBox then
        self.eventDesc = UI.CreateModernEditBox(ef, 540, 32)
    else
        self.eventDesc = CreateFrame("EditBox", nil, ef)
        self.eventDesc:SetAutoFocus(false)
        self.eventDesc:SetFontObject("FSKFontNormalSmall")
        self.eventDesc:SetSize(540, 32)
        self.eventDesc:SetMultiLine(true)
    end
    self.eventDesc:SetPoint("BOTTOMLEFT", ef, "BOTTOMLEFT", 50, 52)
    self.eventDesc:SetText("")
    self.eventDesc:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local postBtn = CreateFrame("Button", nil, ef)
    postBtn:SetSize(110, 22)
    postBtn:SetPoint("BOTTOMRIGHT", ef, "BOTTOMRIGHT", 0, 24)
    postBtn.bg = postBtn:CreateTexture(nil, "BACKGROUND")
    postBtn.bg:SetPoint("TOPLEFT", 1, -1)
    postBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    postBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    postBtn.border = postBtn:CreateTexture(nil, "BORDER")
    postBtn.border:SetAllPoints()
    postBtn.border:SetColorTexture(unpack(_tc("border")))
    postBtn.accent = postBtn:CreateTexture(nil, "OVERLAY")
    postBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    postBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    postBtn.accent:SetHeight(2)
    postBtn.accent:SetColorTexture(unpack(_tc("success")))
    postBtn.hoverTex = postBtn:CreateTexture(nil, "HIGHLIGHT")
    postBtn.hoverTex:SetAllPoints()
    postBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    postBtn.text = postBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    postBtn.text:SetPoint("CENTER")
    postBtn.text:SetText("|cff44ff66" .. L["event_board_post"] .. "|r")
    postBtn:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    postBtn:SetScript("OnLeave", function(self)
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    postBtn:SetScript("OnClick", function()
        local typeName = Community.eventTypeBtn and Community.eventTypeBtn.selected or "Dungeon"
        local name = Community.eventName and Community.eventName:GetText() or ""
        local timeText = Community.eventTime and Community.eventTime:GetText() or ""
        local host = Community.eventHost and Community.eventHost:GetText() or EventPlayer()
        local contact = Community.eventContact and Community.eventContact:GetText() or ""
        local desc = Community.eventDesc and Community.eventDesc:GetText() or ""
        local expiresLabel = Community.eventExpiresBtn and Community.eventExpiresBtn.selected or "1 day"
        Community:PostEvent(typeName, name, timeText, host, contact, desc, expiresLabel)
    end)
    self.eventPostBtn = postBtn

    EventInstallListener()
end

function Community:RefreshEventBoard()
    if not self.eventRows then return end
    if not self.eventFilterBtn then return end
    EventClearExpired(true)
    local db = EventDB()
    if self.eventFilterBtn.text then
        self.eventFilterBtn.text:SetText(tostring(db.filter or "All"))
    end
    if self.eventMyToggle then
        self.eventMyToggle:SetChecked(db.myOnly and true or false)
    end
    local rows = self:GetEventRows()
    if self.eventScrollChild then
        self.eventScrollChild:SetHeight(math.max(400, #rows * 22 + 30))
    end
    for i, row in ipairs(self.eventRows) do
        local entry = rows[i]
        if entry then
            local color = EVENT_TYPE_COLOR[entry.type or "Other"] or "|cffffcc00"
            row.typeText:SetText(color .. "[" .. tostring(entry.type or "Other") .. "]|r")
            row.nameText:SetText("|cffffffff" .. EventShort(entry.name or L["community_default_event_name"], 32) .. "|r")
            row.timeText:SetText(_hex("textNorm") .. EventShort(entry.timeText or "", 22) .. "|r")
            row.hostText:SetText("|cff88ccff" .. EventShort(entry.host or "", 22) .. "|r")
            row.expiresText:SetText(_hex("textDim") .. EventExpireText(entry.expires) .. "|r")
            row.descText:SetText(_hex("textDim") .. EventShort(entry.description or "", 36) .. "|r")
            row.eventData = entry
            row.dismissBtn:SetScript("OnClick", function()
                Community:DismissEvent(entry.id)
            end)
            row:Show()
        else
            row.eventData = nil
            row:Hide()
        end
    end
    if self.eventStats then
        self.eventStats:SetText(_hex("textDim") .. tostring(#rows) .. L["community_events_count_suffix"])
    end
end

function Community:RequestEventsFromPeers()
    if not eventListenerInstalled then return end
    EventSendQuery()
end
