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

local LANG_PATTERNS = {}
for _lang, _words in pairs(LANG_HINTS) do
    local _escaped = {}
    for _i, _w in ipairs(_words) do
        _escaped[#_escaped + 1] = string.gsub(_w, "([%%%.%*%+%-%?%^%$%[%]%(%)])", "%%%1")
    end
    LANG_PATTERNS[_lang] = table.concat(_escaped, "|")
end

local function DetectLanguage(msg)
    if not msg then return "en", 0 end
    local lower = string.lower(msg)
    local bestLang, bestScore = "en", 0
    for lang, pattern in pairs(LANG_PATTERNS) do
        local count = select(2, string.gsub(lower, pattern, ""))
        if count > bestScore then
            bestScore = count
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
    sortBtn.text:SetText(L["event_board_recent"])
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

local function HookRefreshOnEdit(box)
    if not box then return end
    if box._fsRecHooked then return end
    box._fsRecHooked = true
    local orig = box:GetScript("OnTextChanged")
    box:SetScript("OnTextChanged", function(self, ...)
        if orig then orig(self, ...) end
        if Community.recruitmentFrame and Community.recruitmentFrame:IsShown() then
            Community:RefreshRecruitmentPreview()
        end
    end)
end
Community.HookRefreshOnEdit = HookRefreshOnEdit

C_Timer.After(3, function()
    HookRefreshOnEdit(Community.recGuildName)
    HookRefreshOnEdit(Community.recDiscord)
    HookRefreshOnEdit(Community.recNote)
end)

