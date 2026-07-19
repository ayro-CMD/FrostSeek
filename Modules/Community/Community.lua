--[[
==============================================================================
 FrostSeek - Advanced LFG/LFM Manager with FrostNet
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
    -- English
    "recruit", "recruiting", "recruitment", "lfm guild", "guild lf", "looking for members",
    "we are", "join us", "wts guild", "guild recruiting",
    -- Italian
    "reclutiamo", "arruoliamo", "cerchiamo membri", "unisciti", "unitevi", "gilda cerca",
    "gilda recluta", "reclutamento gilda", "stiamo cercando", "guild recluta",
    -- Spanish
    "reclutamos", "buscamos miembros", "únete", "unete", "uníos", "unios",
    "hermandad busca", "hermandad recluta", "reclutamiento",
    -- Portuguese
    "recrutamos", "procuramos membros", "junte-se", "junte se", "junte-se a nós",
    "guilda recruta", "guilda procura", "recrutamento",
    -- German
    "rekrutieren", "rekrutierung", "wir suchen", "suchen mitglieder", "tritt bei",
    "tretet bei", "gilde sucht", "gilde rekrutiert",
    -- French
    "recrutons", "rejoignez", "rejoignez-nous", "cherchons membres", "guilde recrute",
    "guilde cherche", "recrutement de guilde",
    -- Polish
    "rekrutujemy", "szukamy", "dolacz", "dolacz do", "gildia", "czlonkow",
    "przywitaj", "zapraszamy", "gildie", "rekrutacja",
    -- Czech
    "rekrutujeme", "hledame", "pripoj", "pripojte se", "guilda", "clenu",
    "vitejte", "zveme", "rekrutace", "hleda",
    -- Russian
    "rekrytiryem", "ishchem", "prisoedinyaytes", "gildiyu", "chlenov",
    "privetstvuyem", "priglashaem", "rekrutatsiya", "gilda ishchet",
}

local LANG_HINTS = {
    it = { "reclutiamo", "arruoliamo", "cerchiamo", "unisciti", "unitevi", "gilda", "membri", "siamo", "abbiamo", "venite" },
    es = { "reclutamos", "buscamos", "únete", "unete", "uníos", "hermandad", "miembros", "somos", "tenemos", "venid" },
    pt = { "recrutamos", "procuramos", "junte", "guilda", "membros", "somos", "temos", "venham" },
    de = { "rekrutieren", "wir", "suchen", "tritt", "tretet", "gilde", "mitglieder", "haben", "kommt" },
    fr = { "recrutons", "rejoignez", "cherchons", "guilde", "membres", "sommes", "avons", "venez" },
    en = { "recruit", "recruiting", "looking", "join", "guild", "members", "we are", "have", "come" },
    pl = { "rekrutujemy", "szukamy", "dolacz", "gildia", "czlonkow", "zapraszamy", "przywitaj", "gildie", "rekrutacja", "do nas" },
    cs = { "rekrutujeme", "hledame", "pripojte", "guilda", "clenu", "zveme", "vitejte", "rekrutace", "hleda", "k nam" },
    ru = { "rekrytiryem", "ishchem", "prisoedinyaytes", "gildiyu", "chlenov", "priglashaem", "privetstvuyem", "rekrutatsiya", "gilda", "k nam" },
}

local LANG_LABELS = {
    it = "IT", es = "ES", pt = "PT", de = "DE", fr = "FR", en = "EN",
    pl = "PL", cs = "CZ", ru = "RU",
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
}

local function DetectLanguage(msg)
    if not msg then return "en" end
    local lower = string.lower(msg)
    local scores = { it = 0, es = 0, pt = 0, de = 0, fr = 0, en = 0, pl = 0, cs = 0, ru = 0 }
    for lang, words in pairs(LANG_HINTS) do
        for _, w in ipairs(words) do
            local count = select(2, string.gsub(lower, w, ""))
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

    local orig = ChatFrame_OnEvent
    if not orig then return end

    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_CHANNEL")
    f:RegisterEvent("CHAT_MSG_GUILD")
    f:RegisterEvent("CHAT_MSG_YELL")
    f:RegisterEvent("CHAT_MSG_SAY")
    f:SetScript("OnEvent", function(_, event, msg, sender)
        if not msg or not sender then return end
        if not FrostSeekDB.Settings or FrostSeekDB.Settings.guildDiscoveryEnabled == false then
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

    local title = F:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    title:SetText(_hex("accent") .. "Community|r")
    curY = curY - 30

    self.subTabs = {}
    local subTabDefs = {
        { id = "browser",      name = "Guild Browser" },
        { id = "recruitment",  name = "Recruitment Creator" },
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
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
        if Community.activeSubTab ~= "browser" then return end
        pcall(function() Community:RefreshBrowser() end)
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
        self:RefreshBrowser()
    elseif self.activeSubTab == "recruitment" then
        if self.recruitmentFrame then self.recruitmentFrame:Show() end
        if self.browserFrame then self.browserFrame:Hide() end
        self:RefreshRecruitmentPreview()
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

    local header = bf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", bf, "TOPLEFT", 0, 0)
    header:SetText(_hex("textDim") .. "Discovered guilds from chat messages|r")
    curY = -20

    local searchLabel = bf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", bf, "TOPLEFT", 0, curY)
    searchLabel:SetText(_hex("textDim") .. "Search:|r")

    if UI and UI.CreateModernEditBox then
        self.browserSearch = UI.CreateModernEditBox(bf, 160, 18)
    else
        self.browserSearch = CreateFrame("EditBox", nil, bf)
        self.browserSearch:SetAutoFocus(false)
        self.browserSearch:SetFontObject("GameFontNormalSmall")
        self.browserSearch:SetSize(160, 18)
    end
    self.browserSearch:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    self.browserSearch:SetText("")
    self.browserSearch:SetScript("OnTextChanged", function()
        self:RefreshBrowser()
    end)
    self.browserSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local langLabel = bf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langLabel:SetPoint("LEFT", self.browserSearch, "RIGHT", 20, 0)
    langLabel:SetText(_hex("textDim") .. "Lang:|r")

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
    langBtn.text = langBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langBtn.text:SetPoint("CENTER")
    langBtn.text:SetText("All")
    langBtn:SetScript("OnClick", function()
        local order = {"all", "it", "es", "pt", "de", "fr", "en", "pl", "cs", "ru"}
        local idx = 1
        for i, l in ipairs(order) do
            if l == self.browserLangFilter then idx = i break end
        end
        idx = (idx % #order) + 1
        self.browserLangFilter = order[idx]
        local labels = { all = "All", it = "IT", es = "ES", pt = "PT", de = "DE", fr = "FR", en = "EN", pl = "PL", cs = "CZ", ru = "RU" }
        langBtn.text:SetText(labels[self.browserLangFilter])
        self:RefreshBrowser()
    end)
    self.browserLangBtn = langBtn

    local sortLabel = bf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortLabel:SetPoint("LEFT", langBtn, "RIGHT", 16, 0)
    sortLabel:SetText(_hex("textDim") .. "Sort:|r")

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
    sortBtn.text = sortBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortBtn.text:SetPoint("CENTER")
    sortBtn.text:SetText("Recent")
    sortBtn:SetScript("OnClick", function()
        if self.browserSort == "recent" then self.browserSort = "name"
        elseif self.browserSort == "name" then self.browserSort = "sender"
        else self.browserSort = "recent" end
        local labels = { recent = "Recent", name = "Name", sender = "Sender" }
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
    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearBtn.text:SetPoint("CENTER")
    clearBtn.text:SetText("|cffff7755Clear All|r")
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
            Shared.ConfirmDialog("Clear Guild Database", "Remove all discovered guilds?", function()
                FrostSeekDB.Guilds = {}
                self:RefreshBrowser()
                print("|cff88ccffFrostSeek:|r Guild database cleared")
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
        { text = "Guild",     x = 5,   w = 145 },
        { text = "Lang",      x = 155, w = 50 },
        { text = "Focus",     x = 210, w = 160 },
        { text = "Discord",   x = 375, w = 165 },
        { text = "Sender",    x = 545, w = 110 },
        { text = "Seen",      x = 660, w = 75 },
    }
    for _, h in ipairs(headers) do
        local hs = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -4)
        row.name:SetWidth(145)

        row.lang = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.lang:SetPoint("TOPLEFT", row, "TOPLEFT", 155, -4)
        row.lang:SetWidth(50)

        row.focus = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.focus:SetPoint("TOPLEFT", row, "TOPLEFT", 210, -4)
        row.focus:SetWidth(160)

        row.discord = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.discord:SetPoint("TOPLEFT", row, "TOPLEFT", 375, -4)
        row.discord:SetWidth(165)

        row.sender = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", 545, -4)
        row.sender:SetWidth(110)

        row.seen = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
                    GameTooltip:AddLine("|cff888888No message captured|r", 0.6, 0.6, 0.6)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff888888Left-click: details  |  Right-click: whisper|r", 0.5, 0.5, 0.5)
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

    self.browserStats = bf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.browserStats:SetPoint("BOTTOMLEFT", bf, "BOTTOMLEFT", 0, 4)
    self.browserStats:SetText(_hex("textDim") .. "0 guilds discovered|r")
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
                if delta < 60 then ago = delta .. "s ago"
                elseif delta < 3600 then ago = math.floor(delta / 60) .. "m ago"
                elseif delta < 86400 then ago = math.floor(delta / 3600) .. "h ago"
                else ago = math.floor(delta / 86400) .. "d ago"
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
                        print("|cff88ccffFrostSeek:|r Whispering " .. sender .. " (last recruiter of " .. tostring(self.guildName) .. ")")
                    else
                        print("|cffff5555FrostSeek:|r No sender known for this guild")
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
        self.browserStats:SetText(_hex("textDim") .. tostring(#list) .. " guilds discovered|r")
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
        GameTooltip:AddLine("Language: " .. langColor .. "[" .. langLabel .. "]|r", 0.9, 0.9, 0.9)
    end
    if data.focus and data.focus ~= "" then
        GameTooltip:AddLine("Focus: " .. data.focus, 0.8, 0.9, 1)
    end
    if data.discord and data.discord ~= "" then
        GameTooltip:AddLine("Discord: |cff4aa3ff" .. data.discord .. "|r", 0.9, 0.9, 0.9)
    end
    if data.lastSender and data.lastSender ~= "" then
        GameTooltip:AddLine("Last recruiter: |cff88ccff" .. data.lastSender .. "|r", 0.9, 0.9, 0.9)
    end
    local online = self:GetGuildOnlineCount(name)
    GameTooltip:AddLine("Online now: " .. tostring(online), 0.4, 1, 0.4)
    GameTooltip:AddLine("Seen " .. tostring(data.seenCount or 1) .. " time(s)", 0.6, 0.6, 0.6)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click to whisper last recruiter", 0.4, 1, 0.4)
    GameTooltip:AddLine("Shift-click to remove from DB", 0.7, 0.4, 0.4)
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

    local header = rf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, 0)
    header:SetText(_hex("textDim") .. "Create your guild recruitment message|r")
    curY = -22

    local gNameLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gNameLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    gNameLabel:SetText(_hex("textDim") .. "Guild Name:|r")
    curY = curY - 16

    if UI and UI.CreateModernEditBox then
        self.recGuildName = UI.CreateModernEditBox(rf, 300, 22)
    else
        self.recGuildName = CreateFrame("EditBox", nil, rf)
        self.recGuildName:SetAutoFocus(false)
        self.recGuildName:SetFontObject("GameFontNormalSmall")
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

    local discLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    discLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    discLabel:SetText(_hex("textDim") .. "Discord:|r")
    curY = curY - 18

    if UI and UI.CreateModernEditBox then
        self.recDiscord = UI.CreateModernEditBox(rf, 300, 22)
    else
        self.recDiscord = CreateFrame("EditBox", nil, rf)
        self.recDiscord:SetAutoFocus(false)
        self.recDiscord:SetFontObject("GameFontNormalSmall")
        self.recDiscord:SetSize(300, 22)
    end
    self.recDiscord:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recDiscord:SetText("")
    self.recDiscord:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 26

    local focusLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    focusLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    focusLabel:SetText(_hex("textDim") .. "Focus:|r")
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
                text:SetFontObject("GameFontNormalSmall")
            end
        end
        toggle.optName = opt
        self.recFocusToggles[opt] = toggle
    end
    curY = curY - 22 * 2 - 10

    local rolesLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rolesLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    rolesLabel:SetText(_hex("textDim") .. "Roles Needed:|r")
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
                text:SetFontObject("GameFontNormalSmall")
            end
        end
        toggle.optName = opt
        self.recRoleToggles[opt] = toggle
    end
    curY = curY - 26

    local noteLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    noteLabel:SetText(_hex("textDim") .. "Note:|r")
    curY = curY - 18

    if UI and UI.CreateModernEditBox then
        self.recNote = UI.CreateModernEditBox(rf, 500, 40)
    else
        self.recNote = CreateFrame("EditBox", nil, rf)
        self.recNote:SetAutoFocus(false)
        self.recNote:SetFontObject("GameFontNormalSmall")
        self.recNote:SetSize(500, 40)
        self.recNote:SetMultiLine(true)
    end
    self.recNote:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recNote:SetText("")
    self.recNote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 48

    local prevLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    prevLabel:SetText(_hex("textDim") .. "Preview:|r")
    curY = curY - 16

    self.recPreview = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.recPreview:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recPreview:SetWidth(740)
    self.recPreview:SetHeight(30)
    self.recPreview:SetJustifyH("LEFT")
    self.recPreview:SetJustifyV("TOP")
    self.recPreview:SetText("")
    curY = curY - 36

    local chanLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chanLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    chanLabel:SetText(_hex("textDim") .. "Channel:|r")
    curY = curY - 16

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
    self.recSpamChannelBtn.text = self.recSpamChannelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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

    local intLabel = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    intLabel:SetPoint("LEFT", self.recSpamChannelBtn, "RIGHT", 14, 0)
    intLabel.SetText(intLabel, _hex("textDim") .. "Interval:|r")
    intLabel:SetText(_hex("textDim") .. "Interval:|r")

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
    self.recSpamIntervalBtn.text = self.recSpamIntervalBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
    local saveBtn = MakeModernButton(rf, "Save Template", 100, 22, "accentBar", _tc("textPrimary"))
    saveBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, btnY1)
    saveBtn:SetScript("OnClick", function() Community:SaveTemplateDialog() end)

    local loadBtn = MakeModernButton(rf, "Load Template", 100, 22, "accentBar", _tc("textPrimary"))
    loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    loadBtn:SetScript("OnClick", function() Community:LoadTemplateDialog() end)

    local delBtn = MakeModernButton(rf, "Delete Template", 100, 22, "danger", {1, 0.5, 0.3})
    delBtn:SetPoint("LEFT", loadBtn, "RIGHT", 6, 0)
    delBtn.text:SetText("|cffff7755Delete Template|r")
    delBtn:SetScript("OnClick", function() Community:DeleteTemplateDialog() end)

    curY = curY - 24
    local btnY2 = curY
    local sendBtn = MakeModernButton(rf, "Send Once", 100, 22, "success", {0.4, 1, 0.4})
    sendBtn.text:SetText("|cff44ff66Send Once|r")
    sendBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, btnY2)
    sendBtn:SetScript("OnClick", function() Community:SendRecruitmentToChat() end)

    local startSpamBtn = MakeModernButton(rf, "Start Spam", 100, 22, "accentBar", {0.4, 1, 0.4})
    startSpamBtn.text:SetText("|cff44ff44Start Spam|r")
    startSpamBtn:SetPoint("LEFT", sendBtn, "RIGHT", 6, 0)
    startSpamBtn:SetScript("OnClick", function() Community:StartSpam() end)

    local stopSpamBtn = MakeModernButton(rf, "Stop Spam", 100, 22, "danger", {1, 0.4, 0.4})
    stopSpamBtn.text:SetText("|cffff5555Stop Spam|r")
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
    print("|cff88ccffFrostSeek:|r Recruitment spam started (every " .. self:FormatIntervalLabel(interval) .. ")")
    self.spamTicker = C_Timer.NewTicker(interval, function()
        Community:SendRecruitmentToChat()
    end)
end

function Community:StopSpam()
    if self.spamTicker then
        self.spamTicker:Cancel()
        self.spamTicker = nil
        print("|cff88ccffFrostSeek:|r Recruitment spam stopped")
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
        table.insert(parts, "Looking for " .. table.concat(focusParts, "/") .. " players")
    else
        table.insert(parts, "Looking for new members")
    end
    if #roleParts > 0 then
        table.insert(parts, "Need: " .. table.concat(roleParts, "/"))
    end
    if discord and discord ~= "" then
        table.insert(parts, "Discord: " .. discord)
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
        print("|cffff5555FrostSeek:|r Cannot save template without a guild name")
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
    print("|cff88ccffFrostSeek:|r Template saved as '" .. name .. "'")
end

function Community:LoadTemplateDialog()
    if not FrostSeekDB.GuildTemplates then return end
    local count = 0
    for _ in pairs(FrostSeekDB.GuildTemplates) do count = count + 1 end
    if count == 0 then
        print("|cffffaa00FrostSeek:|r No saved templates")
        return
    end
    print("|cff88ccffFrostSeek Templates:|r")
    for name, config in pairs(FrostSeekDB.GuildTemplates) do
        print("  |cff88ccff-|r " .. name .. " |cff888888[" .. (config.guild or "?") .. "]|r")
    end
    print("|cff888888Use /fsloadtemplate <name> to load|r")
end

function Community:DeleteTemplateDialog()
    if not FrostSeekDB.GuildTemplates then return end
    local count = 0
    for _ in pairs(FrostSeekDB.GuildTemplates) do count = count + 1 end
    if count == 0 then
        print("|cffffaa00FrostSeek:|r No templates to delete")
        return
    end
    print("|cff88ccffFrostSeek Templates (deletable via /fsdeltemplate <name>):|r")
    for name, _ in pairs(FrostSeekDB.GuildTemplates) do
        print("  |cffff5555-|r " .. name)
    end
end

function Community:LoadTemplateByName(name)
    if not name or not FrostSeekDB.GuildTemplates then return false end
    local config = FrostSeekDB.GuildTemplates[name]
    if not config then return false end
    self:ApplyRecruitmentConfig(config)
    print("|cff88ccffFrostSeek:|r Loaded template '" .. name .. "'")
    return true
end

function Community:DeleteTemplateByName(name)
    if not name or not FrostSeekDB.GuildTemplates then return false end
    if not FrostSeekDB.GuildTemplates[name] then return false end
    FrostSeekDB.GuildTemplates[name] = nil
    print("|cff88ccffFrostSeek:|r Deleted template '" .. name .. "'")
    return true
end

function Community:SendRecruitmentToChat()
    local msg = self:BuildRecruitmentMessage()
    if not msg or msg == "" then
        print("|cffff5555FrostSeek:|r Empty recruitment message")
        return
    end
    local channel = FrostSeekDB.Settings.recruitSpamChannel or "GUILD"
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
                    print("|cff88ccffFrostSeek:|r Recruitment message sent to " .. tostring(chName) .. " (channel " .. channelNum .. ")")
                    return
                end
            end
        end
        ok = pcall(function() SendChatMessage(msg, "GUILD") end)
        if ok then
            print("|cff88ccffFrostSeek:|r Recruitment message sent to GUILD (channel " .. channel .. " not available)")
            return
        end
    else
        ok = pcall(function() SendChatMessage(msg, channel) end)
        if ok then
            print("|cff88ccffFrostSeek:|r Recruitment message sent to " .. channel)
            return
        end
    end
    pcall(function() SendChatMessage(msg, "SAY") end)
    print("|cffffaa00FrostSeek:|r Recruitment message sent to SAY (configured channel failed)")
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

print("|cff88ccffFrostSeek Community:|r Module loaded")
