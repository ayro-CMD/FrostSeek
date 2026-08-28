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

local Community = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("community", Community)

local _tc = Shared and Shared._tc or function(t) return {0.5, 0.5, 0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end

Community.activeSubTab = "browser"

local FOCUS_KEYWORDS = {
    ["pvp"] = "PvP",
    ["pve"] = "PvE",
    ["raid"] = "Raid",
    ["raidng"] = "Raid",
    ["raiding"] = "Raid",
    ["mythic"] = "Mythic",
    ["mythic+"] = "Mythic+",
    ["m+"] = "Mythic+",
    ["key"] = "Mythic+",
    ["keystone"] = "Mythic+",
    ["dungeon"] = "Dungeon",
    ["dg"] = "Dungeon",
    ["rdf"] = "Dungeon",
    ["ascended"] = "Ascended",
    ["ascension"] = "Ascended",
    ["trial"] = "Trial",
    ["social"] = "Social",
    ["leveling"] = "Leveling",
    ["level"] = "Leveling",
    ["boost"] = "Boost",
    ["carry"] = "Boost",
    ["world boss"] = "World Boss",
    ["worldboss"] = "World Boss",
    ["manastorm"] = "Manastorm",
    ["pvp"] = "PvP",
    ["arena"] = "Arena",
    ["bg"] = "PvP",
    ["battleground"] = "PvP",
    ["twink"] = "Twink",
    ["classic"] = "Classic",
    ["tbc"] = "TBC",
    ["wotlk"] = "WotLK",
    ["wrath"] = "WotLK",
    ["cata"] = "Cata",
    ["mop"] = "MoP",
    ["mists"] = "MoP",
}

local function ParseFocusTags(msg)
    if not msg or msg == "" then return {} end
    local lower = string.lower(msg)
    local tags = {}
    local seen = {}
    for kw, tag in pairs(FOCUS_KEYWORDS) do
        if not seen[tag] and string.find(lower, kw, 1, true) then
            seen[tag] = true
            table.insert(tags, tag)
        end
    end
    return tags
end

local function ExtractDiscord(msg)
    if not msg then return nil end
    local d = string.match(msg, "[Dd]iscord[:%.]-%s*(https?://%S+)")
    if d then return d end
    d = string.match(msg, "[Dd]iscord[:%.]-%s*(%S+%p%S+)")
    if d then return d end
    d = string.match(msg, "(https?://discord%.gg/%S+)")
    if d then return d end
    return nil
end

local function ExtractGuildName(msg)
    if not msg then return nil end
    local g = string.match(msg, "<([^>]+)>")
    if g and string.len(g) > 2 and string.len(g) < 40 then
        return g
    end
    g = string.match(msg, "%[([^%]]+)%]")
    if g and string.len(g) > 2 and string.len(g) < 40 and
       not string.find(g, "[Hh]ero") and not string.find(g, "[Kk]eystone") then
        return g
    end
    return nil
end

local RECRUIT_KEYWORDS = {
    "recruit", "recruiting", "recruitment", "lfm guild", "guild lf", "looking for members",
    "we are", "join us", "wts guild", "guild recruiting",
    "reclutiamo", "arruoliamo", "cerchiamo membri", "unisciti", "unitevi", "gilda cerca",
    "gilda recluta", "reclutamento gilda", "stiamo cercando", "guild recluta",
    "reclutamos", "buscamos miembros", "únete", "unete", "uníos", "unios",
    "hermandad busca", "hermandad recluta", "reclutamiento",
    "recrutamos", "procuramos membros", "junte-se", "junte se", "junte-se a nós",
    "guilda recruta", "guilda procura", "recrutamento",
    "rekrutieren", "rekrutierung", "wir suchen", "suchen mitglieder", "tritt bei",
    "tretet bei", "gilde sucht", "gilde rekrutiert",
    "recrutons", "rejoignez", "rejoignez-nous", "cherchons membres", "guilde recrute",
    "guilde cherche", "recrutement de guilde",
    "rekrutujemy", "szukamy", "dolacz", "dolacz do", "gildia", "czlonkow",
    "przywitaj", "zapraszamy", "gildie", "rekrutacja",
    "rekrutujeme", "hledame", "pripoj", "pripojte se", "guilda", "clenu",
    "vitejte", "zveme", "rekrutace", "hleda",
    "rekrytiryem", "ishchem", "prisoedinyaytes", "gildiyu", "chlenov",
    "privetstvuyem", "priglashaem", "rekrutatsiya", "gilda ishchet",
    "recrutam", "cautam membri", "alturati", "alturatu", "vineti",
    "breasla cauta", "breasla recruteaza", "recrutare",
}

local LANG_HINTS = {
    it = { "reclutiamo", "arruoliamo", "cerchiamo", "unisciti", "unitevi", "gilda", "membri", "siamo", "abbiamo", "venite", "[IT]" },
    es = { "reclutamos", "buscamos", "únete", "unete", "uníos", "hermandad", "miembros", "somos", "tenemos", "venid", "[ES]" },
    pt = { "recrutamos", "procuramos", "junte", "guilda", "membros", "somos", "temos", "venham", "[PT]", "[BR]", "[PT/BR]" },
    de = { "rekrutieren", "wir", "suchen", "tritt", "tretet", "gilde", "mitglieder", "haben", "kommt", "[DE]" },
    fr = { "recrutons", "rejoignez", "cherchons", "guilde", "membres", "sommes", "avons", "venez", "[FR]" },
    en = { "recruit", "recruiting", "looking", "join", "guild", "members", "we are", "have", "come", "[EN]" },
    pl = { "rekrutujemy", "szukamy", "dolacz", "gildia", "czlonkow", "zapraszamy", "przywitaj", "gildie", "rekrutacja", "do nas", "[PL]" },
    cs = { "rekrutujeme", "hledame", "pripojte", "guilda", "clenu", "zveme", "vitejte", "rekrutace", "hleda", "k nam", "[CZ]" },
    ru = { "rekrytiryem", "ishchem", "prisoedinyaytes", "gildiyu", "chlenov", "priglashaem", "privetstvuyem", "rekrutatsiya", "gilda", "k nam", "[RU]" },
    ro = { "recrutam", "cautam", "alturati", "alturatu", "vineti", "breasla", "membri", "suntem", "avem", "alaturi","recruteaza", },
}
local LANG_LABELS = {
    it = "IT", es = "ES", pt = "PT", de = "DE", fr = "FR", en = "EN",
    pl = "PL", cs = "CZ", ru = "RU", ro = "RO",
}

local LANG_COLORS = {
    it = "|cff44ff66", 
    es = "|cffffaa33", 
    pt = "|cff44aaff", 
    de = "|cffff5555",
    fr = "|cff88ccff", 
    en = "|cff888888",
    pl = "|cffff6688", 
    cs = "|cff44aaff",
    ru = "|cffcc4444", 
    ro = "|cffaa66ff",
}

local function DetectLanguage(msg)
    if not msg then return "en" end
    local lower = string.lower(msg)
    local scores = { it = 0, es = 0, pt = 0, de = 0, fr = 0, en = 0, pl = 0, cs = 0, ru = 0, ro = 0 }
    for lang, words in pairs(LANG_HINTS) do
        for _, w in ipairs(words) do
            local escaped = string.gsub(w, "([%%%.%*%+%-%?%^%$%[%]%(%)])", "%%%1")
            local count = select(2, string.gsub(lower, escaped, ""))
            scores[lang] = scores[lang] + count
        end
    end
    local bestLang, bestScore = "en", 0
    for lang, score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            bestLang = lang
        end
    end
    return bestLang, bestScore
end

local function IsRecruitmentMessage(msg)
    if not msg then return false end
    local lower = string.lower(msg)
    for _, kw in ipairs(RECRUIT_KEYWORDS) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

local chatFrameHooked = false
local function HookChatForGuildDiscovery()
    if chatFrameHooked then return end
    chatFrameHooked = true


    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:RegisterEvent("CHAT_MSG_GUILD")
    f:RegisterEvent("CHAT_MSG_YELL")
    f:RegisterEvent("CHAT_MSG_SAY")
    f:SetScript("OnEvent", function(_, event, msg, sender)
        if not msg or not sender then return end
        if not (FrostSeekDB and FrostSeekDB.Settings) or FrostSeekDB.Settings.guildDiscoveryEnabled == false then
            return
        end
        pcall(function()
            Community:DiscoverFromChat(msg, sender, event)
        end)
    end)
end

function Community:DiscoverFromChat(msg, sender, event)
    if not IsRecruitmentMessage(msg) then return end
    local guildName = ExtractGuildName(msg)
    if not guildName then return end

    if string.lower(guildName) == "keystone" then return end
    if string.lower(guildName) == "hero" then return end

    local senderClean = sender and tostring(sender) or ""
    if string.find(senderClean, "-", 1, true) then
        senderClean = string.sub(senderClean, 1, string.find(senderClean, "-", 1, true) - 1)
    end

    local lang = DetectLanguage(msg)

    if not FrostSeekDB.Guilds then FrostSeekDB.Guilds = {} end
    if not FrostSeekDB.Guilds[guildName] then
        FrostSeekDB.Guilds[guildName] = {
            focus = "",
            discord = "",
            note = "",
            lastMessage = msg,
            lastSeen = time(),
            lastSender = senderClean,
            language = lang,
            members = {},
            source = "chat",
            seenCount = 1,
        }
    else
        local g = FrostSeekDB.Guilds[guildName]
        g.lastSeen = time()
        g.lastSender = senderClean
        g.lastMessage = msg
        g.language = lang
        g.seenCount = (g.seenCount or 0) + 1
        if senderClean and senderClean ~= "" then
            if not g.members then g.members = {} end
            g.members[senderClean] = time()
        end
    end

    local tags = ParseFocusTags(msg)
    if #tags > 0 then
        FrostSeekDB.Guilds[guildName].focus = table.concat(tags, ", ")
    end

    local disc = ExtractDiscord(msg)
    if disc then
        FrostSeekDB.Guilds[guildName].discord = disc
    end

end

function Community:GetGuildOnlineCount(guildName)
    if not guildName then return 0 end
    if not FrostSeek.Presence or not FrostSeek.Presence.onlineUsers then return 0 end
    local count = 0
    for _, u in pairs(FrostSeek.Presence.onlineUsers) do
        if u.guild and string.lower(u.guild) == string.lower(guildName) then
            count = count + 1
        end
    end
    return count
end

function Community:TrimGuildDB()
    if not FrostSeekDB.Guilds then return end
    local count = 0
    for _ in pairs(FrostSeekDB.Guilds) do count = count + 1 end
    if count <= 200 then return end
    local sorted = {}
    for name, g in pairs(FrostSeekDB.Guilds) do
        table.insert(sorted, { name = name, lastSeen = g.lastSeen or 0 })
    end
    table.sort(sorted, function(a, b) return (a.lastSeen or 0) < (b.lastSeen or 0) end
    )
    while #sorted > 200 do
        local entry = table.remove(sorted, 1)
        FrostSeekDB.Guilds[entry.name] = nil
    end
end

function Community:Initialize(parentFrame)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    if self.frame then
        self.frame:SetParent(parentFrame)
        self.frame:ClearAllPoints()
        self.frame:SetAllPoints(parentFrame)
        self.frame:Hide()
        return
    end

    local F = CreateFrame("Frame", nil, parentFrame)
    F:SetAllPoints(parentFrame)
    self.frame = F

    local pad = 10
    local curY = -10

    local title = F:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    title:SetText(_hex("accent") .. L["community_title"] .. "|r")
    curY = curY - 30

    self.subTabs = {}
    local subTabDefs = {
        { id = "browser",      name = L["community_subtab_browser"] },
        { id = "recruitment",  name = L["community_subtab_recruitment"] },
        { id = "events",       name = L["community_subtab_events"] },
    }
    local subTabW = 140
    local subTabH = 24
    for i, st in ipairs(subTabDefs) do
        local btn = CreateFrame("Button", nil, F)
        btn:SetSize(subTabW, subTabH)
        btn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + (i - 1) * (subTabW + 4), curY)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))
        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))
        btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(st.name)
        btn.text:SetTextColor(unpack(_tc("textMuted")))
        btn.id = st.id
        btn:SetScript("OnClick", function(self)
            Community.activeSubTab = self.id
            Community:RefreshSubTabs()
            Community:RefreshContent()
        end)
        self.subTabs[st.id] = btn
    end
    curY = curY - subTabH - 10

    local sep = F:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    sep:SetPoint("TOPRIGHT", F, "TOPRIGHT", -pad, curY)
    sep:SetHeight(1)
    sep:SetColorTexture(unpack(_tc("line")))
    curY = curY - 8

    self.contentY = curY
    self:BuildBrowserFrame()
    self:BuildRecruitmentFrame()
    self:BuildEventBoardFrame()

    self:RefreshSubTabs()
    self:RefreshContent()

    self.frame:Hide()

    C_Timer.After(2, HookChatForGuildDiscovery)

    C_Timer.NewTicker(120, function()
        Community:TrimGuildDB()
    end)

    C_Timer.NewTicker(5, function()
        if not Community.frame then return end
        if not Community.frame:IsVisible() then return end
        if Community.activeSubTab == "browser" then
            pcall(function() Community:RefreshBrowser() end)
        elseif Community.activeSubTab == "events" then
            pcall(function() Community:RefreshEventBoard() end)
        end
    end)
end

function Community:RefreshSubTabs()
    if not self.subTabs then return end
    for id, btn in pairs(self.subTabs) do
        if id == self.activeSubTab then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.border:SetColorTexture(unpack(_tc("borderFocus")))
            btn.text:SetTextColor(unpack(_tc("textPrimary")))
        else
            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
            btn.border:SetColorTexture(unpack(_tc("border")))
            btn.text:SetTextColor(unpack(_tc("textMuted")))
        end
    end
end

function Community:RefreshContent()
    if not self.frame then return end
    if self.activeSubTab == "browser" then
        if self.browserFrame then self.browserFrame:Show() end
        if self.recruitmentFrame then self.recruitmentFrame:Hide() end
        if self.eventsFrame then self.eventsFrame:Hide() end
        self:RefreshBrowser()
    elseif self.activeSubTab == "recruitment" then
        if self.recruitmentFrame then self.recruitmentFrame:Show() end
        if self.browserFrame then self.browserFrame:Hide() end
        if self.eventsFrame then self.eventsFrame:Hide() end
        self:RefreshRecruitmentPreview()
    elseif self.activeSubTab == "events" then
        if self.eventsFrame then self.eventsFrame:Show() end
        if self.browserFrame then self.browserFrame:Hide() end
        if self.recruitmentFrame then self.recruitmentFrame:Hide() end
        self:RefreshEventBoard()
        self:RequestEventsFromPeers()
    end
end

function Community:Show()
    if self.frame then self.frame:Show() end
end

function Community:Hide()
    if self.frame then self.frame:Hide() end
end

FrostSeek.Community = Community
if _G.FrostSeek then
    _G.FrostSeek.Community = Community
end

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

local function EventSend(payload)
    payload = tostring(payload or "")
    if payload == "" then return false end
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
        print("|cffffaa00FrostSeek:|r " .. (L["event_board_queued"] or L["event_board_queued"]))
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

function Community:BuildBrowserFrame()
    if not self.frame then return end
    local F = self.frame
    local pad = 10
    local curY = self.contentY

    local bf = CreateFrame("Frame", nil, F)
    bf:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    bf:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad, pad)
    self.browserFrame = bf

    local header = bf:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    header:SetPoint("TOPLEFT", bf, "TOPLEFT", 0, 0)
    header:SetText(_hex("textDim") .. L["community_guilds_discovered"] .. "|r")
    curY = -20

    local searchLabel = bf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", bf, "TOPLEFT", 0, curY)
    searchLabel:SetText(_hex("textDim") .. L["community_search_label"])

    if UI and UI.CreateModernEditBox then
        self.browserSearch = UI.CreateModernEditBox(bf, 160, 18)
    else
        self.browserSearch = CreateFrame("EditBox", nil, bf)
        self.browserSearch:SetAutoFocus(false)
        self.browserSearch:SetFontObject("FSKFontNormalSmall")
        self.browserSearch:SetSize(160, 18)
    end
    self.browserSearch:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    self.browserSearch:SetText("")
    self.browserSearch:SetScript("OnTextChanged", function()
        self:RefreshBrowser()
    end)
    self.browserSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local langLabel = bf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    langLabel:SetPoint("LEFT", self.browserSearch, "RIGHT", 20, 0)
    langLabel:SetText(_hex("textDim") .. L["community_lang_label"])

    self.browserLangFilter = "all"
    local langBtn = CreateFrame("Button", nil, bf)
    langBtn:SetSize(60, 22)
    langBtn:SetPoint("LEFT", langLabel, "RIGHT", 4, 0)
    langBtn.bg = langBtn:CreateTexture(nil, "BACKGROUND")
    langBtn.bg:SetAllPoints()
    langBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    langBtn.border = langBtn:CreateTexture(nil, "BORDER")
    langBtn.border:SetAllPoints()
    langBtn.border:SetColorTexture(unpack(_tc("border")))
    langBtn.text = langBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    langBtn.text:SetPoint("CENTER")
    langBtn.text:SetText(L["filter_all"])
    langBtn:SetScript("OnClick", function()
        local order = {"all", "it", "es", "pt", "de", "fr", "en", "pl", "cs", "ru", "ro"}
        local idx = 1
        for i, l in ipairs(order) do
            if l == self.browserLangFilter then idx = i break end
        end
        idx = (idx % #order) + 1
        self.browserLangFilter = order[idx]
        local labels = { all = L["filter_all"], it = "IT", es = "ES", pt = "PT", de = "DE", fr = "FR", en = "EN", pl = "PL", cs = "CZ", ru = "RU", ro = "RO" }
        langBtn.text:SetText(labels[self.browserLangFilter])
        self:RefreshBrowser()
    end)
    self.browserLangBtn = langBtn

    local sortLabel = bf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    sortLabel:SetPoint("LEFT", langBtn, "RIGHT", 16, 0)
    sortLabel:SetText(_hex("textDim") .. L["community_sort_label"])

    self.browserSort = "recent" 
    local sortBtn = CreateFrame("Button", nil, bf)
    sortBtn:SetSize(90, 22)
    sortBtn:SetPoint("LEFT", sortLabel, "RIGHT", 4, 0)
    sortBtn.bg = sortBtn:CreateTexture(nil, "BACKGROUND")
    sortBtn.bg:SetAllPoints()
    sortBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    sortBtn.border = sortBtn:CreateTexture(nil, "BORDER")
    sortBtn.border:SetAllPoints()
    sortBtn.border:SetColorTexture(unpack(_tc("border")))
    sortBtn.text = sortBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    sortBtn.text:SetPoint("CENTER")
    sortBtn.text:SetText(L["event_board_recent"] or L["event_board_recent"])
    sortBtn:SetScript("OnClick", function()
        if self.browserSort == "recent" then self.browserSort = "name"
        elseif self.browserSort == "name" then self.browserSort = "sender"
        else self.browserSort = "recent" end
        local labels = { recent = L["community_recent_label"], name = L["community_name_label"], sender = L["community_sender_label"] }
        sortBtn.text:SetText(labels[self.browserSort])
        self:RefreshBrowser()
    end)
    self.browserSortBtn = sortBtn

    local clearBtn = CreateFrame("Button", nil, bf)
    clearBtn:SetSize(85, 22)
    clearBtn:SetPoint("TOPRIGHT", bf, "TOPRIGHT", 0, 0)
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
    clearBtn.hoverTex:Hide()
    clearBtn.accent = clearBtn:CreateTexture(nil, "OVERLAY")
    clearBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    clearBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    clearBtn.accent:SetHeight(2)
    clearBtn.accent:SetColorTexture(unpack(_tc("danger")))
    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    clearBtn.text:SetPoint("CENTER")
    clearBtn.text:SetText("|cffff7755" .. L["community_clear_all"] .. "|r")
    clearBtn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    clearBtn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    clearBtn:SetScript("OnClick", function()
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog(L["community_clear_guilds_title"], L["community_clear_guilds_msg"], function()
                FrostSeekDB.Guilds = {}
                self:RefreshBrowser()
                print(L["msg_guild_db_cleared"])
            end)
        end
    end)
    self.browserClearBtn = clearBtn

    curY = curY - 30

    local scrollFrame = CreateFrame("ScrollFrame", "FrostSeekCommunityBrowserScroll", bf, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", bf, "TOPLEFT", 0, curY)
    scrollFrame:SetPoint("TOPRIGHT", bf, "TOPRIGHT", -20, curY)
    scrollFrame:SetPoint("BOTTOM", bf, "BOTTOM", 0, 30)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(740)
    scrollChild:SetHeight(400)
    scrollFrame:SetScrollChild(scrollChild)
    self.browserScrollChild = scrollChild

    local hY = -2
    local headers = {
        { text = L["label_guild"],     x = 5,   w = 145 },
        { text = L["lbl_lang"],      x = 155, w = 50 },
        { text = L["lbl_focus"],     x = 210, w = 160 },
        { text = L["lbl_discord"],   x = 375, w = 165 },
        { text = L["lbl_sender"],    x = 545, w = 110 },
        { text = L["lbl_seen"],      x = 660, w = 75 },
    }
    for _, h in ipairs(headers) do
        local hs = scrollChild:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        hs:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", h.x, hY)
        hs:SetWidth(h.w)
        hs:SetText(_hex("textDim") .. h.text .. "|r")
    end

    self.browserRows = {}
    for i = 1, 30 do
        local row = CreateFrame("Button", nil, scrollChild)
        row:SetSize(740, 22)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -20 - (i - 1) * 22)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)

        row.name = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -4)
        row.name:SetWidth(145)

        row.lang = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.lang:SetPoint("TOPLEFT", row, "TOPLEFT", 155, -4)
        row.lang:SetWidth(50)

        row.focus = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.focus:SetPoint("TOPLEFT", row, "TOPLEFT", 210, -4)
        row.focus:SetWidth(160)

        row.discord = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.discord:SetPoint("TOPLEFT", row, "TOPLEFT", 375, -4)
        row.discord:SetWidth(165)

        row.sender = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", 545, -4)
        row.sender:SetWidth(110)

        row.seen = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        row.seen:SetPoint("TOPLEFT", row, "TOPLEFT", 660, -4)
        row.seen:SetWidth(75)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.3, 0.6, 1.0, 0.1)
            if self.guildData and self.guildData.lastMessage then
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, -4)
                GameTooltip:ClearLines()
                local nameStr = self.guildName or ""
                GameTooltip:AddLine(_hex("accent") .. nameStr .. "|r", 1, 1, 1)
                GameTooltip:AddLine(" ")
                local msg = self.guildData.lastMessage
                if msg and msg ~= "" then
                    local maxLen = 120
                    local displayMsg = #msg > maxLen and string.sub(msg, 1, maxLen - 3) .. "..." or msg
                    GameTooltip:AddLine("|cffffffff" .. displayMsg .. "|r", 0.9, 0.9, 0.9, true)
                else
                    GameTooltip:AddLine(L["tip_no_message_captured"], 0.6, 0.6, 0.6)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["tip_left_details_right_whisp"], 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)

        row:Hide()
        self.browserRows[i] = row
    end

    self.browserStats = bf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.browserStats:SetPoint("BOTTOMLEFT", bf, "BOTTOMLEFT", 0, 4)
    self.browserStats:SetText(_hex("textDim") .. L["community_guilds_count_zero"])
end

function Community:RefreshBrowser()
    if not self.browserRows then return end

    local search = self.browserSearch and self.browserSearch:GetText() or ""
    local lowerSearch = string.lower(search)
    local langFilter = self.browserLangFilter or "all"

    local list = {}
    if FrostSeekDB.Guilds then
        for name, g in pairs(FrostSeekDB.Guilds) do
            local matchesSearch = (search == "" or
               string.find(string.lower(name), lowerSearch, 1, true) or
               (g.focus and string.find(string.lower(g.focus), lowerSearch, 1, true)) or
               (g.discord and string.find(string.lower(g.discord), lowerSearch, 1, true)) or
               (g.lastSender and string.find(string.lower(g.lastSender), lowerSearch, 1, true)))
            local matchesLang = (langFilter == "all" or g.language == langFilter)
            if matchesSearch and matchesLang then
                table.insert(list, { name = name, data = g })
            end
        end
    end

    if self.browserSort == "name" then
        table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    elseif self.browserSort == "sender" then
        table.sort(list, function(a, b)
            return (a.data.lastSender or ""):lower() < (b.data.lastSender or ""):lower()
        end)
    else
        table.sort(list, function(a, b) return (a.data.lastSeen or 0) > (b.data.lastSeen or 0) end)
    end

    for i, row in ipairs(self.browserRows) do
        local entry = list[i]
        if entry then
            row.name:SetText(_hex("accent") .. entry.name .. "|r")

            local lang = entry.data.language or "en"
            local langLabel = LANG_LABELS[lang] or "EN"
            local langColor = LANG_COLORS[lang] or "|cff888888"
            row.lang:SetText(langColor .. "[" .. langLabel .. "]|r")

            row.focus:SetText(entry.data.focus or "")
            if entry.data.discord and entry.data.discord ~= "" then
                row.discord:SetText("|cff4aa3ff" .. entry.data.discord .. "|r")
            else
                row.discord:SetText(_hex("textDim") .. "-" .. "|r")
            end

            if entry.data.lastSender and entry.data.lastSender ~= "" then
                row.sender:SetText("|cff88ccff" .. entry.data.lastSender .. "|r")
            else
                row.sender:SetText(_hex("textDim") .. "-" .. "|r")
            end

            local ago = ""
            if entry.data.lastSeen then
                local delta = time() - entry.data.lastSeen
                if delta < 60 then ago = delta .. L["community_time_seconds_ago"]
                elseif delta < 3600 then ago = math.floor(delta / 60) .. L["community_time_minutes_ago"]
                elseif delta < 86400 then ago = math.floor(delta / 3600) .. L["community_time_hours_ago"]
                else ago = math.floor(delta / 86400) .. L["community_time_days_ago"]
                end
            end
            row.seen:SetText(_hex("textDim") .. ago .. "|r")

            row.guildName = entry.name
            row.guildData = entry.data
            row:SetScript("OnClick", function(self, button)
                if button == "RightButton" then
                    local sender = self.guildData and self.guildData.lastSender
                    if sender and sender ~= "" then
                        if FrostSeekCompat and FrostSeekCompat.OpenChat then
                            FrostSeekCompat.OpenChat("/w " .. sender .. " ")
                        elseif ChatFrame_OpenChat then
                            ChatFrame_OpenChat("/w " .. sender .. " ")
                        end
                        print(L["msg_whispering"] .. sender .. L["community_last_recruiter_of_prefix"] .. tostring(self.guildName) .. ")")
                    else
                        print(L["msg_no_sender_known"])
                    end
                else
                    Community:ShowGuildDetail(self.guildName, self.guildData)
                end
            end)
            row:Show()
        else
            row:Hide()
        end
    end

    if self.browserStats then
        self.browserStats:SetText(_hex("textDim") .. tostring(#list) .. L["community_guilds_count_suffix"])
    end
end

function Community:ShowGuildDetail(name, data)
    if not name or not data then return end
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(_hex("accent") .. name .. "|r", 1, 1, 1)
    GameTooltip:AddLine(" ")
    if data.language then
        local langLabel = LANG_LABELS[data.language] or "EN"
        local langColor = LANG_COLORS[data.language] or "|cff888888"
        GameTooltip:AddLine(L["tip_language_label"] .. langColor .. "[" .. langLabel .. "]|r", 0.9, 0.9, 0.9)
    end
    if data.focus and data.focus ~= "" then
        GameTooltip:AddLine(L["tip_focus_label"] .. data.focus, 0.8, 0.9, 1)
    end
    if data.discord and data.discord ~= "" then
        GameTooltip:AddLine(L["tip_discord_label"] .. data.discord .. "|r", 0.9, 0.9, 0.9)
    end
    if data.lastSender and data.lastSender ~= "" then
        GameTooltip:AddLine(L["tip_last_recruiter"] .. data.lastSender .. "|r", 0.9, 0.9, 0.9)
    end
    local online = self:GetGuildOnlineCount(name)
    GameTooltip:AddLine(L["tip_online_now"] .. tostring(online), 0.4, 1, 0.4)
    GameTooltip:AddLine(L["tip_seen_label"] .. tostring(data.seenCount or 1) .. L["community_times_suffix"], 0.6, 0.6, 0.6)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["tip_right_click_whisper_rec"], 0.4, 1, 0.4)
    GameTooltip:AddLine(L["tip_shift_click_remove_db"], 0.7, 0.4, 0.4)
    GameTooltip:Show()
end

function Community:BuildRecruitmentFrame()
    if not self.frame then return end
    local F = self.frame
    local pad = 10
    local curY = self.contentY

    local rf = CreateFrame("Frame", nil, F)
    rf:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    rf:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad, pad)
    self.recruitmentFrame = rf

    local header = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    header:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, 0)
    header:SetText(_hex("textDim") .. L["community_recruitment_create"] .. "|r")
    curY = -22

    local gNameLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    gNameLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    gNameLabel:SetText(_hex("textDim") .. L["community_guild_name_label"])
    curY = curY - 16

    if UI and UI.CreateModernEditBox then
        self.recGuildName = UI.CreateModernEditBox(rf, 300, 22)
    else
        self.recGuildName = CreateFrame("EditBox", nil, rf)
        self.recGuildName:SetAutoFocus(false)
        self.recGuildName:SetFontObject("FSKFontNormalSmall")
        self.recGuildName:SetSize(300, 22)
    end
    self.recGuildName:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recGuildName:SetText("")
    self.recGuildName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local myGuild = GetGuildInfo and GetGuildInfo("player") or ""
    if myGuild and myGuild ~= "" then
        self.recGuildName:SetText(myGuild)
    end
    curY = curY - 26

    local discLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    discLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    discLabel:SetText(_hex("textDim") .. L["community_discord_label"])
    curY = curY - 18

    if UI and UI.CreateModernEditBox then
        self.recDiscord = UI.CreateModernEditBox(rf, 300, 22)
    else
        self.recDiscord = CreateFrame("EditBox", nil, rf)
        self.recDiscord:SetAutoFocus(false)
        self.recDiscord:SetFontObject("FSKFontNormalSmall")
        self.recDiscord:SetSize(300, 22)
    end
    self.recDiscord:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recDiscord:SetText("")
    self.recDiscord:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 26

    local focusLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    focusLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    focusLabel:SetText(_hex("textDim") .. L["community_focus_label"])
    curY = curY - 18

    self.recFocusToggles = {}
    local focusOptions = {"PvE", "PvP", "Raid", "Mythic+", "Dungeon", "Arena", "Ascended", "World Boss", "Social", "Leveling", "Twink", "Boost"}
    local colW = 90
    local perRow = 6
    for i, opt in ipairs(focusOptions) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local toggle
        if UI and UI.CreateSmallToggle then
            toggle = UI.CreateSmallToggle(rf, opt, col * colW, row * 22, 80, 20, function() end)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", col * colW, curY - row * 22)
        else
            toggle = CreateFrame("CheckButton", nil, rf, "UICheckButtonTemplate")
            toggle:SetSize(18, 18)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", col * colW, curY - row * 22)
            local text = _G[toggle:GetName() .. "Text"]
            if text then
                text:SetText(opt)
                text:SetFontObject("FSKFontNormalSmall")
            end
        end
        toggle.optName = opt
        self.recFocusToggles[opt] = toggle
    end
    curY = curY - 22 * 2 - 10

    local rolesLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    rolesLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    rolesLabel:SetText(_hex("textDim") .. L["community_roles_needed_label"])
    curY = curY - 18

    self.recRoleToggles = {}
    local roleOptions = {"Tank", "Healer", "DPS", "Support"}
    for i, opt in ipairs(roleOptions) do
        local toggle
        if UI and UI.CreateSmallToggle then
            toggle = UI.CreateSmallToggle(rf, opt, (i - 1) * 90, 0, 80, 20, function() end)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", (i - 1) * 90, curY)
        else
            toggle = CreateFrame("CheckButton", nil, rf, "UICheckButtonTemplate")
            toggle:SetSize(18, 18)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", (i - 1) * 90, curY)
            local text = _G[toggle:GetName() .. "Text"]
            if text then
                text:SetText(opt)
                text:SetFontObject("FSKFontNormalSmall")
            end
        end
        toggle.optName = opt
        self.recRoleToggles[opt] = toggle
    end
    curY = curY - 26

    local noteLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    noteLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    noteLabel:SetText(_hex("textDim") .. L["community_note_label"])
    curY = curY - 18

    if UI and UI.CreateModernEditBox then
        self.recNote = UI.CreateModernEditBox(rf, 500, 40)
    else
        self.recNote = CreateFrame("EditBox", nil, rf)
        self.recNote:SetAutoFocus(false)
        self.recNote:SetFontObject("FSKFontNormalSmall")
        self.recNote:SetSize(500, 40)
        self.recNote:SetMultiLine(true)
    end
    self.recNote:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recNote:SetText("")
    self.recNote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 48

    local prevLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    prevLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    prevLabel:SetText(_hex("textDim") .. L["community_preview_label"])
    curY = curY - 16

    self.recPreview = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.recPreview:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recPreview:SetWidth(740)
    self.recPreview:SetHeight(30)
    self.recPreview:SetJustifyH("LEFT")
    self.recPreview:SetJustifyV("TOP")
    self.recPreview:SetText("")
    curY = curY - 36

    local chanLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    chanLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    chanLabel:SetText(_hex("textDim") .. L["community_channel_label"])
    curY = curY - 16

    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
    if not FrostSeekDB.Settings.recruitSpamChannel then
        FrostSeekDB.Settings.recruitSpamChannel = "GUILD"
    end
    if not FrostSeekDB.Settings.recruitSpamInterval then
        FrostSeekDB.Settings.recruitSpamInterval = 600
    end

    self.recSpamChannelBtn = CreateFrame("Button", nil, rf)
    self.recSpamChannelBtn:SetSize(120, 22)
    self.recSpamChannelBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recSpamChannelBtn.bg = self.recSpamChannelBtn:CreateTexture(nil, "BACKGROUND")
    self.recSpamChannelBtn.bg:SetPoint("TOPLEFT", 1, -1)
    self.recSpamChannelBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    self.recSpamChannelBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    self.recSpamChannelBtn.border = self.recSpamChannelBtn:CreateTexture(nil, "BORDER")
    self.recSpamChannelBtn.border:SetAllPoints()
    self.recSpamChannelBtn.border:SetColorTexture(unpack(_tc("border")))
    self.recSpamChannelBtn.hoverTex = self.recSpamChannelBtn:CreateTexture(nil, "HIGHLIGHT")
    self.recSpamChannelBtn.hoverTex:SetAllPoints()
    self.recSpamChannelBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamChannelBtn.hoverTex:Hide()
    self.recSpamChannelBtn.accent = self.recSpamChannelBtn:CreateTexture(nil, "OVERLAY")
    self.recSpamChannelBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    self.recSpamChannelBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    self.recSpamChannelBtn.accent:SetHeight(2)
    self.recSpamChannelBtn.accent:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamChannelBtn.text = self.recSpamChannelBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.recSpamChannelBtn.text:SetPoint("CENTER")
    local spamChannels = {"GUILD", "CHANNEL1", "CHANNEL2", "CHANNEL3", "SAY", "YELL"}
    local function UpdateChannelLabel()
        self.recSpamChannelBtn.text:SetText(FrostSeekDB.Settings.recruitSpamChannel)
    end
    UpdateChannelLabel()
    self.recSpamChannelBtn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    self.recSpamChannelBtn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    self.recSpamChannelBtn:SetScript("OnClick", function()
        local cur = FrostSeekDB.Settings.recruitSpamChannel
        local idx = 1
        for i, c in ipairs(spamChannels) do
            if c == cur then idx = i break end
        end
        idx = (idx % #spamChannels) + 1
        FrostSeekDB.Settings.recruitSpamChannel = spamChannels[idx]
        UpdateChannelLabel()
    end)

    local intLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    intLabel:SetPoint("LEFT", self.recSpamChannelBtn, "RIGHT", 14, 0)
    intLabel.SetText(intLabel, _hex("textDim") .. L["community_interval_label"])
    intLabel:SetText(_hex("textDim") .. L["community_interval_label"])

    self.recSpamIntervalBtn = CreateFrame("Button", nil, rf)
    self.recSpamIntervalBtn:SetSize(100, 22)
    self.recSpamIntervalBtn:SetPoint("LEFT", intLabel, "RIGHT", 4, 0)
    self.recSpamIntervalBtn.bg = self.recSpamIntervalBtn:CreateTexture(nil, "BACKGROUND")
    self.recSpamIntervalBtn.bg:SetPoint("TOPLEFT", 1, -1)
    self.recSpamIntervalBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    self.recSpamIntervalBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    self.recSpamIntervalBtn.border = self.recSpamIntervalBtn:CreateTexture(nil, "BORDER")
    self.recSpamIntervalBtn.border:SetAllPoints()
    self.recSpamIntervalBtn.border:SetColorTexture(unpack(_tc("border")))
    self.recSpamIntervalBtn.hoverTex = self.recSpamIntervalBtn:CreateTexture(nil, "HIGHLIGHT")
    self.recSpamIntervalBtn.hoverTex:SetAllPoints()
    self.recSpamIntervalBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamIntervalBtn.hoverTex:Hide()
    self.recSpamIntervalBtn.accent = self.recSpamIntervalBtn:CreateTexture(nil, "OVERLAY")
    self.recSpamIntervalBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    self.recSpamIntervalBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    self.recSpamIntervalBtn.accent:SetHeight(2)
    self.recSpamIntervalBtn.accent:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamIntervalBtn.text = self.recSpamIntervalBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.recSpamIntervalBtn.text:SetPoint("CENTER")
    local intervals = {600, 900, 1800, 2700, 3600} 
    local function FormatInterval(sec)
        local m = math.floor(sec / 60)
        if m < 60 then return m .. " min" end
        local h = math.floor(m / 60)
        local rem = m % 60
        if rem == 0 then return h .. "h" end
        return h .. "h " .. rem .. "m"
    end
    local function UpdateIntervalLabel()
        self.recSpamIntervalBtn.text:SetText(FormatInterval(FrostSeekDB.Settings.recruitSpamInterval))
    end
    UpdateIntervalLabel()
    self.recSpamIntervalBtn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    self.recSpamIntervalBtn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    self.recSpamIntervalBtn:SetScript("OnClick", function()
        local cur = FrostSeekDB.Settings.recruitSpamInterval
        local idx = 1
        for i, v in ipairs(intervals) do
            if v == cur then idx = i break end
        end
        idx = (idx % #intervals) + 1
        FrostSeekDB.Settings.recruitSpamInterval = intervals[idx]
        UpdateIntervalLabel()
        if Community.spamTicker then
            Community:StopSpam()
            Community:StartSpam()
        end
    end)

    curY = curY - 26

    local function MakeModernButton(parent, label, w, h, accentToken, hoverColor)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(w, h)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetPoint("TOPLEFT", 1, -1)
        btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))
        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))
        btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hoverTex:SetAllPoints()
        btn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
        btn.hoverTex:Hide()
        btn.accent = btn:CreateTexture(nil, "OVERLAY")
        btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
        btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
        btn.accent:SetHeight(2)
        btn.accent.SetColorTexture(btn.accent, unpack(_tc(accentToken)))
        btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(label)
        btn:SetScript("OnEnter", function(self)
            self.hoverTex:Show()
            self.border:SetColorTexture(unpack(_tc("borderHover")))
            if hoverColor then self.text:SetTextColor(unpack(hoverColor)) end
        end)
        btn:SetScript("OnLeave", function(self)
            self.hoverTex:Hide()
            self.border:SetColorTexture(unpack(_tc("border")))
            self.text:SetTextColor(unpack(_tc("textMuted")))
        end)
        return btn
    end

    local btnY1 = curY
    local saveBtn = MakeModernButton(rf, L["community_save_template"], 100, 22, "accentBar", _tc("textPrimary"))
    saveBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, btnY1)
    saveBtn:SetScript("OnClick", function() Community:SaveTemplateDialog() end)

    local loadBtn = MakeModernButton(rf, L["community_load_template"], 100, 22, "accentBar", _tc("textPrimary"))
    loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    loadBtn:SetScript("OnClick", function() Community:LoadTemplateDialog() end)

    local delBtn = MakeModernButton(rf, L["community_delete_template"], 100, 22, "danger", {1, 0.5, 0.3})
    delBtn:SetPoint("LEFT", loadBtn, "RIGHT", 6, 0)
    delBtn.text:SetText("|cffff7755" .. L["community_delete_template"] .. "|r")
    delBtn:SetScript("OnClick", function() Community:DeleteTemplateDialog() end)

    curY = curY - 24
    local btnY2 = curY
    local sendBtn = MakeModernButton(rf, L["community_send_once"], 100, 22, "success", {0.4, 1, 0.4})
    sendBtn.text:SetText("|cff44ff66" .. L["community_send_once"] .. "|r")
    sendBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, btnY2)
    sendBtn:SetScript("OnClick", function() Community:SendRecruitmentToChat() end)

    local startSpamBtn = MakeModernButton(rf, L["community_start_spam"], 100, 22, "accentBar", {0.4, 1, 0.4})
    startSpamBtn.text:SetText("|cff44ff44" .. L["community_start_spam"] .. "|r")
    startSpamBtn:SetPoint("LEFT", sendBtn, "RIGHT", 6, 0)
    startSpamBtn:SetScript("OnClick", function() Community:StartSpam() end)

    local stopSpamBtn = MakeModernButton(rf, L["community_stop_spam"], 100, 22, "danger", {1, 0.4, 0.4})
    stopSpamBtn.text:SetText("|cffff5555" .. L["community_stop_spam"] .. "|r")
    stopSpamBtn:SetPoint("LEFT", startSpamBtn, "RIGHT", 6, 0)
    stopSpamBtn:SetScript("OnClick", function() Community:StopSpam() end)

    self.recStartSpamBtn = startSpamBtn
    self.recStopSpamBtn = stopSpamBtn
end


function Community:StartSpam()
    if self.spamTicker then
        self.spamTicker:Cancel()
        self.spamTicker = nil
    end
    local interval = FrostSeekDB.Settings.recruitSpamInterval or 600
    self:SendRecruitmentToChat()
    print(L["msg_recruit_spam_started"] .. self:FormatIntervalLabel(interval) .. ")")
    self.spamTicker = C_Timer.NewTicker(interval, function()
        Community:SendRecruitmentToChat()
    end)
end

function Community:StopSpam()
    if self.spamTicker then
        self.spamTicker:Cancel()
        self.spamTicker = nil
        print(L["msg_recruit_spam_stopped"])
    end
end

function Community:FormatIntervalLabel(sec)
    local m = math.floor(sec / 60)
    if m < 60 then return m .. " min" end
    local h = math.floor(m / 60)
    local rem = m % 60
    if rem == 0 then return h .. "h" end
    return h .. "h " .. rem .. "m"
end

function Community:RefreshRecruitmentPreview()
    if not self.recPreview then return end
    local msg = self:BuildRecruitmentMessage()
    self.recPreview:SetText(msg)
end

function Community:BuildRecruitmentMessage()
    local guild = self.recGuildName and self.recGuildName:GetText() or ""
    local discord = self.recDiscord and self.recDiscord:GetText() or ""

    local focusParts = {}
    if self.recFocusToggles then
        for opt, toggle in pairs(self.recFocusToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then
                table.insert(focusParts, opt)
            end
        end
    end

    local roleParts = {}
    if self.recRoleToggles then
        for opt, toggle in pairs(self.recRoleToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then
                table.insert(roleParts, opt)
            end
        end
    end

    local note = self.recNote and self.recNote:GetText() or ""

    local parts = {}
    table.insert(parts, "[" .. guild .. "]")
    if #focusParts > 0 then
        table.insert(parts, L["community_looking_for_prefix"] .. table.concat(focusParts, "/") .. L["community_players_suffix"])
    else
        table.insert(parts, L["community_looking_for_members"])
    end
    if #roleParts > 0 then
        table.insert(parts, L["community_need_prefix"] .. table.concat(roleParts, "/"))
    end
    if discord and discord ~= "" then
        table.insert(parts, L["community_discord_prefix"] .. discord)
    end
    if note and note ~= "" then
        table.insert(parts, note)
    end
    table.insert(parts, "- FrostSeek")

    return table.concat(parts, " - ")
end

function Community:GetCurrentRecruitmentConfig()
    local config = {
        guild = self.recGuildName and self.recGuildName:GetText() or "",
        discord = self.recDiscord and self.recDiscord:GetText() or "",
        focus = {},
        roles = {},
        note = self.recNote and self.recNote:GetText() or "",
    }
    if self.recFocusToggles then
        for opt, toggle in pairs(self.recFocusToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then table.insert(config.focus, opt) end
        end
    end
    if self.recRoleToggles then
        for opt, toggle in pairs(self.recRoleToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then table.insert(config.roles, opt) end
        end
    end
    return config
end

function Community:ApplyRecruitmentConfig(config)
    if not config then return end
    if self.recGuildName then self.recGuildName:SetText(config.guild or "") end
    if self.recDiscord then self.recDiscord:SetText(config.discord or "") end
    if self.recNote then self.recNote:SetText(config.note or "") end
    if self.recFocusToggles and config.focus then
        for opt, toggle in pairs(self.recFocusToggles) do
            local found = false
            for _, f in ipairs(config.focus) do
                if f == opt then found = true break end
            end
            if toggle.SetChecked then toggle:SetChecked(found) end
            if toggle.active ~= nil then toggle.active = found end
        end
    end
    if self.recRoleToggles and config.roles then
        for opt, toggle in pairs(self.recRoleToggles) do
            local found = false
            for _, r in ipairs(config.roles) do
                if r == opt then found = true break end
            end
            if toggle.SetChecked then toggle:SetChecked(found) end
            if toggle.active ~= nil then toggle.active = found end
        end
    end
    self:RefreshRecruitmentPreview()
end

function Community:SaveTemplateDialog()
    local config = self:GetCurrentRecruitmentConfig()
    if config.guild == "" then
        print(L["msg_cannot_save_no_guild"])
        return
    end
    local name = config.guild
    local baseName = name
    local suffix = 1
    while FrostSeekDB.GuildTemplates and FrostSeekDB.GuildTemplates[name] do
        name = baseName .. " (" .. tostring(suffix) .. ")"
        suffix = suffix + 1
    end
    if not FrostSeekDB.GuildTemplates then FrostSeekDB.GuildTemplates = {} end
    FrostSeekDB.GuildTemplates[name] = config
    print(L["msg_template_saved_as"] .. " '" .. name .. "'")
end

function Community:LoadTemplateDialog()
    if not FrostSeekDB.GuildTemplates then return end
    local count = 0
    for _ in pairs(FrostSeekDB.GuildTemplates) do count = count + 1 end
    if count == 0 then
        print(L["msg_no_saved_templates"])
        return
    end
    print(L["msg_templates_header"])
    for name, config in pairs(FrostSeekDB.GuildTemplates) do
        print("  |cff88ccff-|r " .. name .. " |cff888888[" .. (config.guild or "?") .. "]|r")
    end
    print(L["msg_use_fsloadtemplate"])
end

function Community:DeleteTemplateDialog()
    if not FrostSeekDB.GuildTemplates then return end
    local count = 0
    for _ in pairs(FrostSeekDB.GuildTemplates) do count = count + 1 end
    if count == 0 then
        print(L["msg_no_templates_to_delete"])
        return
    end
    print(L["msg_templates_deletable_hdr"])
    for name, _ in pairs(FrostSeekDB.GuildTemplates) do
        print("  |cffff5555-|r " .. name)
    end
end

function Community:LoadTemplateByName(name)
    if not name or not FrostSeekDB.GuildTemplates then return false end
    local config = FrostSeekDB.GuildTemplates[name]
    if not config then return false end
    self:ApplyRecruitmentConfig(config)
    print(L["msg_loaded_template"] .. " '" .. name .. "'")
    return true
end

function Community:DeleteTemplateByName(name)
    if not name or not FrostSeekDB.GuildTemplates then return false end
    if not FrostSeekDB.GuildTemplates[name] then return false end
    FrostSeekDB.GuildTemplates[name] = nil
    print(L["msg_deleted_template"] .. " '" .. name .. "'")
    return true
end

function Community:SendRecruitmentToChat()
    local msg = self:BuildRecruitmentMessage()
    if not msg or msg == "" then
        print(L["msg_empty_recruitment_msg"])
        return
    end
    local channel = (FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.recruitSpamChannel) or "GUILD"
    local ok = false
    if string.match(channel, "CHANNEL%d+") then
        local channelNum = tonumber(string.match(channel, "CHANNEL(%d+)"))
        if channelNum then
            local realId
            local chName
            pcall(function()
                local id, name = GetChannelName(channelNum)
                if type(id) == "number" and id > 0 then
                    realId = id
                    chName = name
                end
            end)
            if realId then
                ok = pcall(function() SendChatMessage(msg, "CHANNEL", nil, realId) end)
                if ok then
                    print(L["msg_recruit_sent_to"] .. tostring(chName) .. L["community_channel_prefix"] .. channelNum .. ")")
                    return
                end
            end
        end
        ok = pcall(function() SendChatMessage(msg, "GUILD") end)
        if ok then
            print(L["msg_recruit_sent_to_guild"] .. channel .. L["community_not_available_suffix"])
            return
        end
    else
        ok = pcall(function() SendChatMessage(msg, channel) end)
        if ok then
            print(L["community_recruit_sent_to_prefix"] .. channel)
            return
        end
    end
    pcall(function() SendChatMessage(msg, "SAY") end)
    print(L["msg_recruit_sent_to_say"])
end

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("community", Community)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("community")
end

local function HookRefreshOnEdit(box)
    if not box then return end
    local orig = box:GetScript("OnTextChanged")
    box:SetScript("OnTextChanged", function(self, ...)
        if orig then orig(self, ...) end
        if Community.recruitmentFrame and Community.recruitmentFrame:IsShown() then
            Community:RefreshRecruitmentPreview()
        end
    end)
end

C_Timer.After(3, function()
    HookRefreshOnEdit(Community.recGuildName)
    HookRefreshOnEdit(Community.recDiscord)
    HookRefreshOnEdit(Community.recNote)
end)

print(L["msg_community_module_loaded"])
