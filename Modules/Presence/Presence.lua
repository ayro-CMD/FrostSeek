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

local Presence = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("presence", Presence)

local L = FrostSeek.L
local Shared = _G.FrostSeekShared
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end

local PING_INTERVAL = 55     
local PRUNE_AFTER = 165
local REFRESH_INTERVAL = 10

Presence.onlineUsers = {}
Presence.panel = nil
Presence.panelVisible = false
Presence.versionWarned = {}
Presence.roleFilter = Presence.roleFilter or { Tank = false, Healer = false, DPS = false, Support = false }
Presence.searchFilter = Presence.searchFilter or (FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.presenceSearch or "")
Presence.newerVersionNotified = false

function Presence:CompareVersions(vA, vB)
    local function parse(v)
        local parts = {}
        for n in string.gmatch(tostring(v), "%d+") do
            table.insert(parts, tonumber(n) or 0)
        end
        return parts
    end
    local a, b = parse(vA), parse(vB)
    local maxLen = math.max(#a, #b)
    for i = 1, maxLen do
        local na = a[i] or 0
        local nb = b[i] or 0
        if na > nb then return 1 end
        if na < nb then return -1 end
    end
    return 0
end

local GetClassColor = Shared and Shared.GetClassColor or function(cf) return {0.7,0.7,0.7} end
local GetClassHex = Shared and Shared.GetClassHex or function(cf) return "|cFF888888" end
local GetClassIcon = Shared and Shared.GetClassIcon or function(cf) return "Interface\\Icons\\INV_Misc_QuestionMark" end

function Presence:SendPing()
    local Network = FrostSeek and FrostSeek.Network
    if not Network or not Network.SendPresence then return end

    local profile = FrostSeekDB and FrostSeekDB.Profile or {}
    local lfgRole = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.myRole or ""
    local role = profile.role or lfgRole or ""
    if role == "" then role = L["none"] end
    if profile.role ~= role then profile.role = role end

    Network:SendPresence(
        FrostSeek.VERSION or "",
        role,
        profile.spec or ""
    )
end

function Presence:HandlePong(name, seen)
    if not name or name == "" then return end
    local pn = UnitName("player") or ""
    if name == pn then return end
    local u = self.onlineUsers[name]
    if u then
        u.seen = seen or time()
    end
end

function Presence:HandleHeartbeat(name, seen)
    if not name or name == "" then return end
    local pn = UnitName("player") or ""
    if name == pn then return end
    local u = self.onlineUsers[name]
    if u then
        u.seen = seen or time()
        u.lastHeartbeat = time()
    end
end

function Presence:HandlePresence(user)
    if not user or not user.name or user.name == "" then return end
    local pn = UnitName("player") or ""
    if user.name == pn then return end

    local wasOnline = self.onlineUsers[user.name] ~= nil
    self.onlineUsers[user.name] = user

    if not wasOnline and FrostSeekDB and FrostSeekDB.Favorites and FrostSeekDB.Favorites[user.name] then
        local role = user.role or ""
        local level = user.level or ""
        local msg = string.format(L["presence_favorite_online_msg"], tostring(user.name), tostring(level), tostring(role))
        print(msg)
        if Shared and Shared.PlaySound then
            Shared.PlaySound("popup")
        end
        Presence:ShowFavoriteToast(user.name, role, level)
    end
    
    local myVersion = FrostSeek.VERSION or ""
    if user.version and user.version ~= "" and user.version ~= myVersion then
        user.outdated = true
    else
        user.outdated = false
    end

    if self.panelVisible and self.panel and self.panel:IsShown() then
        self:RefreshPanel()
    end

    if FrostSeek.Dashboard and FrostSeek.Dashboard.UpdateAll then
        FrostSeek.Dashboard:UpdateAll()
    end
end

function Presence.IsFavorite(name)
    if not name then return false end
    return FrostSeekDB and FrostSeekDB.Favorites and FrostSeekDB.Favorites[name] == true
end

function Presence.ToggleFavorite(name)
    if not name or name == "" then return end
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Favorites then FrostSeekDB.Favorites = {} end
    if FrostSeekDB.Favorites[name] then
        FrostSeekDB.Favorites[name] = nil
        print(L["msg_removed_favorite"] .. name .. L["msg_from_favorites_suffix"])
    else
        FrostSeekDB.Favorites[name] = true
        print(L["msg_added_favorite"] .. name .. L["msg_to_favorites_suffix"])
    end
    if Presence.panelVisible and Presence.panel and Presence.panel:IsShown() then
        Presence:RefreshPanel()
    end
end

function Presence:PruneUsers()
    local cutoff = time() - PRUNE_AFTER
    for name, u in pairs(self.onlineUsers) do
        if not u.seen or u.seen < cutoff then
            self.onlineUsers[name] = nil
        end
    end
end

function Presence:GetOnlineCount()
    local c = 1 
    for _ in pairs(self.onlineUsers) do
        c = c + 1
    end
    return c
end

function Presence:GetOnlineUsers()
    self:PruneUsers()
    local rows = {}
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end
    local profile = FrostSeekDB and FrostSeekDB.Profile or {}
    table.insert(rows, {
        name = UnitName("player") or "",
        version = FrostSeek.VERSION or "",
        level = tostring(UnitLevel("player") or 60),
        classFile = classFile or "",
        role = profile.role or L["none"],
        spec = profile.spec or "",
        zone = GetRealZoneText() or "",
        guild = GetGuildInfo("player") or "",
        status = profile.status or L["status_free"],
        seen = time(),
        isSelf = true,
        isFriend = false,
    })

    for _, u in pairs(self.onlineUsers) do
        u.isFriend = FrostSeekCompat and FrostSeekCompat.IsFriendCached and FrostSeekCompat.IsFriendCached(u.name) or false
        u.isSelf = false
        table.insert(rows, u)
    end

    local myGuild = (GetGuildInfo and GetGuildInfo("player")) or ""
    local searchQ = (self.searchFilter or ""):lower()
    local anyRoleFilter = false
    for _, v in pairs(self.roleFilter or {}) do
        if v then anyRoleFilter = true; break end
    end
    local filtered = {}
    for _, u in ipairs(rows) do
        if u.isSelf then
            local roleMatch = true
            if anyRoleFilter then
                local r = u.role
                if r == "SUPPORT" then r = "Support" end
                roleMatch = self.roleFilter and self.roleFilter[r] == true
            end
            if roleMatch then
                table.insert(filtered, u)
            end
        else
            local nameLower = tostring(u.name or ""):lower()
            if searchQ ~= "" and not string.find(nameLower, searchQ, 1, true) then

            elseif self.guildOnly and myGuild ~= "" and (u.guild or "") ~= myGuild then

            elseif anyRoleFilter then
                local r = u.role
                if r == "SUPPORT" then r = "Support" end
                if self.roleFilter and self.roleFilter[r] == true then
                    table.insert(filtered, u)
                end
            else
                table.insert(filtered, u)
            end
        end
    end

    local sortMode = self.sortMode or "name"
    table.sort(filtered, function(a, b)
        if a.isSelf and not b.isSelf then return true end
        if b.isSelf and not a.isSelf then return false end
        if a.isFriend and not b.isFriend then return true end
        if b.isFriend and not a.isFriend then return false end
        if sortMode == "guild" then
            local ga = tostring(a.guild or "")
            local gb = tostring(b.guild or "")
            if ga ~= gb then return ga < gb end
            return tostring(a.name or "") < tostring(b.name or "")
        elseif sortMode == "zone" then
            local za = tostring(a.zone or "")
            local zb = tostring(b.zone or "")
            if za ~= zb then return za < zb end
            return tostring(a.name or "") < tostring(b.name or "")
        elseif sortMode == "seen" then
            return (a.seen or 0) > (b.seen or 0)
        end

        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return filtered
end

function Presence:GetStats()
    local rows = self:GetOnlineUsers()
    local stats = {
        total = #rows,
        friends = 0,
        tanks = 0,
        healers = 0,
        dps = 0,
        supports = 0,
    }

    for _, u in ipairs(rows) do
        if u.isFriend then stats.friends = stats.friends + 1 end
        if u.role == "Tank" then stats.tanks = stats.tanks + 1
        elseif u.role == "Healer" then stats.healers = stats.healers + 1
        elseif u.role == "DPS" then stats.dps = stats.dps + 1
        elseif u.role == "Support" or u.role == "SUPPORT" then stats.supports = stats.supports + 1
        end
    end

    return stats
end

function Presence:GetRoleDistribution()
    local stats = self:GetStats()
    local total = stats.tanks + stats.healers + stats.dps + stats.supports
    if total == 0 then
        return { tank = 0, healer = 0, dps = 0, support = 0 }
    end
    return {
        tank = stats.tanks / total,
        healer = stats.healers / total,
        dps = stats.dps / total,
        support = stats.supports / total,
    }
end

function Presence:PrintOnlineUsers()
    self:PruneUsers()
    local rows = self:GetOnlineUsers()
    print("|cff88ccffFrostNet Online:|r " .. tostring(#rows) .. L["presence_users_online_suffix"])
    for _, u in ipairs(rows) do
        local guild = u.guild and u.guild ~= "" and (" <" .. u.guild .. ">") or ""
        local role = u.role and u.role ~= "" and (" - " .. u.role) or ""
        local zone = u.zone and u.zone ~= "" and (" - " .. u.zone) or ""
        local lvl = u.level and u.level ~= "" and (L["presence_lvl_label"] .. u.level) or ""
        print("  " .. tostring(u.name or "?") .. guild .. lvl .. role .. zone)
    end
end

local VISIBLE_ROWS = 11
local ROW_HEIGHT = 26

function Presence:BuildPanel(parent)
    if self.panel then return self.panel end

    local f = CreateFrame("Frame", "FrostSeekPresencePanel", parent or UIParent)
    self.panel = f
    f:SetWidth(520)
    f:SetHeight(520)
    f:SetPoint("TOPRIGHT", parent or UIParent, "TOPRIGHT", -5, -50)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel((parent and parent:GetFrameLevel() or 100) + 50)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(unpack(_tc("bgMain")))

    f.border = f:CreateTexture(nil, "BORDER")
    f.border:SetAllPoints()
    f.border:SetColorTexture(unpack(_tc("border")))

    f.inner = f:CreateTexture(nil, "ARTWORK")
    f.inner:SetPoint("TOPLEFT", 2, -2)
    f.inner:SetPoint("BOTTOMRIGHT", -2, 2)
    f.inner:SetColorTexture(unpack(_tc("bgSection")))

    local headerH = 46
    local headerFrame = CreateFrame("Frame", nil, f)
    headerFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    headerFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    headerFrame:SetHeight(headerH)
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(_tc("bgBlock")[1], _tc("bgBlock")[2], _tc("bgBlock")[3], 0.8)
    headerFrame.title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerFrame.title:SetPoint("LEFT", headerFrame, "LEFT", 14, 2)
    headerFrame.title:SetText("|cff88ccffFrost|r|cffffffffNet|r")
    f.onlineBadge = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.onlineBadge:SetPoint("LEFT", headerFrame.title, "RIGHT", 10, 0)

    local statusBtn = CreateFrame("Button", nil, headerFrame)
    statusBtn:SetSize(120, 20)
    statusBtn:SetPoint("RIGHT", headerFrame, "RIGHT", -40, 2)
    statusBtn:RegisterForClicks("LeftButtonUp")

    f.statusDot = statusBtn:CreateTexture(nil, "ARTWORK")
    f.statusDot:SetSize(8, 8)
    f.statusDot:SetPoint("RIGHT", statusBtn, "RIGHT", -4, 0)
    f.statusDot:SetColorTexture(unpack(_tc("success")))

    f.statusText = statusBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.statusText:SetPoint("RIGHT", f.statusDot, "LEFT", -4, 0)
    f.statusText:SetText(L["status_free"])

    
    local STATUS_OPTIONS = {
        { id = L["status_free"],   label = L["status_free"],   color = {0.2, 0.9, 0.4},  hex = "|cff44ff44" },
        { id = L["status_busy"],   label = L["status_busy"],   color = {1.0, 0.75, 0.2},  hex = "|cffffcc00" },
        { id = L["status_afk"],    label = L["status_afk"],    color = {0.95, 0.3, 0.3},  hex = "|cffff5555" },
        { id = L["status_bored"],  label = L["status_bored"],  color = {0.7, 0.3, 0.9},  hex = "|cffb34dff" },
    }

    f.STATUS_OPTIONS = STATUS_OPTIONS
    f.statusMenuOpen = false

    local statusDrop = CreateFrame("Frame", "FrostSeekStatusDrop", UIParent)
    statusDrop:SetSize(100, #STATUS_OPTIONS * 24 + 4)
    statusDrop:SetFrameStrata("DIALOG")
    statusDrop:SetToplevel(true)
    statusDrop:EnableMouse(true)
    statusDrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    statusDrop:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    statusDrop:Hide()
    f.statusDrop = statusDrop

    for idx, opt in ipairs(STATUS_OPTIONS) do
        local btn = CreateFrame("Button", nil, statusDrop)
        btn:SetSize(94, 22)
        btn:SetPoint("TOPLEFT", statusDrop, "TOPLEFT", 3, -2 - ((idx - 1) * 24))

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(opt.color[1], opt.color[2], opt.color[3], 0.12)

        btn.dot = btn:CreateTexture(nil, "ARTWORK")
        btn.dot:SetSize(8, 8)
        btn.dot:SetPoint("LEFT", btn, "LEFT", 8, 0)
        btn.dot:SetColorTexture(opt.color[1], opt.color[2], opt.color[3], 1)

        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("LEFT", btn.dot, "RIGHT", 6, 0)
        btn.label:SetText(opt.hex .. opt.label .. "|r")

        btn.check = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.check:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        btn.check:SetText("")

        btn:SetScript("OnClick", function()
            if not FrostSeekDB then FrostSeekDB = {} end
            if not FrostSeekDB.Profile then FrostSeekDB.Profile = {} end
            FrostSeekDB.Profile.status = opt.id
            Presence:SendPing()
            Presence:RefreshPanel()
            statusDrop:Hide()
            f.statusMenuOpen = false
        end)
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(opt.color[1], opt.color[2], opt.color[3], 0.35)
        end)
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(opt.color[1], opt.color[2], opt.color[3], 0.12)
        end)
    end

    
    statusDrop:SetScript("OnHide", function()
        f.statusMenuOpen = false
    end)

    statusBtn:SetScript("OnClick", function()
        if f.statusMenuOpen then
            statusDrop:Hide()
            f.statusMenuOpen = false
            return
        end
        
        statusDrop:ClearAllPoints()
        statusDrop:SetPoint("TOPRIGHT", statusBtn, "BOTTOMRIGHT", 0, -4)
        statusDrop:Show()
        f.statusMenuOpen = true

        
        local curStatus = FrostSeekDB and FrostSeekDB.Profile and FrostSeekDB.Profile.status or L["status_free"]
        for idx2, opt2 in ipairs(STATUS_OPTIONS) do
            local child = select(idx2, statusDrop:GetChildren())
            if child and child.check then
                if opt2.id == curStatus then
                    child.check:SetText("|cff88ccff>>|r")
                else
                    child.check:SetText("")
                end
            end
        end
    end)

    statusBtn:SetScript("OnEnter", function(self)
        f.statusText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    end)
    statusBtn:SetScript("OnLeave", function(self)
        f.statusText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    end)

    local headerLine = headerFrame:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", 0, 0)
    headerLine:SetHeight(2)

    local accentC = _tc("accent")
    headerLine:SetColorTexture(accentC[1], accentC[2], accentC[3], 0.6)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide(); Presence.panelVisible = false end)

    local statsY = -headerH - 6
    local statsH = 56
    local statsFrame = CreateFrame("Frame", nil, f)
    statsFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, statsY)
    statsFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, statsY)
    statsFrame:SetHeight(statsH)

    local statsBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    statsBg:SetAllPoints()
    statsBg:SetColorTexture(unpack(_tc("bgBlock")))
    f.statsLeft = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.statsLeft:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 10, -6)
    f.statsLeft:SetWidth(200)
    f.statsLeft:SetHeight(statsH - 8)
    f.statsLeft:SetJustifyH("LEFT")
    f.statsLeft:SetJustifyV("TOP")

    local barAreaX = 220
    local barW = 130
    local barH = 6
    local barGap = 11
    local tankLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tankLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", barAreaX, -6)
    tankLabel:SetText("|cff4aa3ffT|r")
    tankLabel:SetWidth(14)

    f.tankBarBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    f.tankBarBg:SetPoint("LEFT", tankLabel, "RIGHT", 4, 0)
    f.tankBarBg:SetSize(barW, barH)
    f.tankBarBg:SetColorTexture(0.15, 0.15, 0.18, 0.6)

    f.tankBarFill = statsFrame:CreateTexture(nil, "ARTWORK")
    f.tankBarFill:SetPoint("LEFT", f.tankBarBg, "LEFT", 0, 0)
    f.tankBarFill:SetSize(0, barH)
    f.tankBarFill:SetColorTexture(0.29, 0.64, 1.0, 0.7)

    f.tankCount = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.tankCount:SetPoint("LEFT", f.tankBarBg, "RIGHT", 4, 0)
    f.tankCount:SetText("0")
    f.tankCount:SetTextColor(unpack(_tc("textDim")))

    local healerLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healerLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", barAreaX, -6 - barGap)
    healerLabel:SetText("|cff44ff66H|r")
    healerLabel:SetWidth(14)

    f.healerBarBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    f.healerBarBg:SetPoint("LEFT", healerLabel, "RIGHT", 4, 0)
    f.healerBarBg:SetSize(barW, barH)
    f.healerBarBg:SetColorTexture(0.15, 0.15, 0.18, 0.6)

    f.healerBarFill = statsFrame:CreateTexture(nil, "ARTWORK")
    f.healerBarFill:SetPoint("LEFT", f.healerBarBg, "LEFT", 0, 0)
    f.healerBarFill:SetSize(0, barH)
    f.healerBarFill:SetColorTexture(0.27, 1.0, 0.40, 0.7)

    f.healerCount = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.healerCount:SetPoint("LEFT", f.healerBarBg, "RIGHT", 4, 0)
    f.healerCount:SetText("0")
    f.healerCount:SetTextColor(unpack(_tc("textDim")))

    local dpsLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpsLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", barAreaX, -6 - barGap * 2)
    dpsLabel:SetText("|cffff5555D|r")
    dpsLabel:SetWidth(14)

    f.dpsBarBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    f.dpsBarBg:SetPoint("LEFT", dpsLabel, "RIGHT", 4, 0)
    f.dpsBarBg:SetSize(barW, barH)
    f.dpsBarBg:SetColorTexture(0.15, 0.15, 0.18, 0.6)

    f.dpsBarFill = statsFrame:CreateTexture(nil, "ARTWORK")
    f.dpsBarFill:SetPoint("LEFT", f.dpsBarBg, "LEFT", 0, 0)
    f.dpsBarFill:SetSize(0, barH)
    f.dpsBarFill:SetColorTexture(1.0, 0.33, 0.33, 0.7)

    f.dpsCount = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.dpsCount:SetPoint("LEFT", f.dpsBarBg, "RIGHT", 4, 0)
    f.dpsCount:SetText("0")
    f.dpsCount:SetTextColor(unpack(_tc("textDim")))

    local supportLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    supportLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", barAreaX, -6 - barGap * 3)
    supportLabel:SetText("|cffb366ffS|r")
    supportLabel:SetWidth(14)

    f.supportBarBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    f.supportBarBg:SetPoint("LEFT", supportLabel, "RIGHT", 4, 0)
    f.supportBarBg:SetSize(barW, barH)
    f.supportBarBg:SetColorTexture(0.15, 0.15, 0.18, 0.6)

    f.supportBarFill = statsFrame:CreateTexture(nil, "ARTWORK")
    f.supportBarFill:SetPoint("LEFT", f.supportBarBg, "LEFT", 0, 0)
    f.supportBarFill:SetSize(0, barH)
    f.supportBarFill:SetColorTexture(0.70, 0.40, 1.00, 0.7)

    f.supportCount = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.supportCount:SetPoint("LEFT", f.supportBarBg, "RIGHT", 4, 0)
    f.supportCount:SetText("0")
    f.supportCount:SetTextColor(unpack(_tc("textDim")))

    local colY = statsY - statsH - 6
    local toolbarH = 52
    local toolbarY = colY
    colY = colY - toolbarH

    local header = CreateFrame("Frame", nil, f)
    header:SetWidth(496)
    header:SetHeight(22)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, colY)
    local headerBgTex = header:CreateTexture(nil, "BACKGROUND")
    headerBgTex:SetAllPoints()
    headerBgTex:SetColorTexture(_tc("bgBlock")[1], _tc("bgBlock")[2], _tc("bgBlock")[3], 0.6)

    local headerAccent = header:CreateTexture(nil, "ARTWORK")
    headerAccent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    headerAccent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerAccent:SetHeight(1)
    headerAccent:SetColorTexture(accentC[1], accentC[2], accentC[3], 0.3)

    local hLabels = {{L["presence_col_status"], 6}, {L["presence_col_player"], 36}, {L["presence_col_lvl"], 130}, {L["presence_col_role"], 165}, {L["presence_col_zone"], 215}, {L["presence_col_guild"], 320}, {L["presence_col_seen"], 435}}
    for _, lbl in ipairs(hLabels) do
        local t = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", header, "LEFT", lbl[2], 0)
        t:SetText(_hex("textDim") .. lbl[1] .. "|r")
    end

    local toolbar = CreateFrame("Frame", nil, f)
    toolbar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, toolbarY)
    toolbar:SetSize(496, 52)

    local searchLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 0, -8)
    searchLabel:SetText(_hex("textDim") .. (L["search"] or L["search"]) .. ":|r")
    f.searchEdit = CreateFrame("EditBox", nil, toolbar)
    f.searchEdit:SetAutoFocus(false)
    f.searchEdit:SetFontObject("GameFontNormalSmall")
    f.searchEdit:SetSize(200, 20)
    f.searchEdit:SetPoint("LEFT", searchLabel, "RIGHT", 6, 0)
    f.searchEdit:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    f.searchEdit:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    f.searchEdit:SetBackdropBorderColor(0.3, 0.4, 0.5, 1.0)
    f.searchEdit:SetTextInsets(6, 6, 2, 2)
    f.searchEdit:SetText(Presence.searchFilter or "")
    f.searchEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    f.searchEdit:SetScript("OnTextChanged", function(self)
        Presence.searchFilter = (self:GetText() or ""):lower()
        if FrostSeekDB and FrostSeekDB.Settings then
            FrostSeekDB.Settings.presenceSearch = Presence.searchFilter
        end
        Presence:RefreshPanel()
    end)

    local ROLE_CYCLE = {
        { id = "all",     label = "All",      color = {0.7, 0.7, 0.7} },
        { id = "Tank",    label = "Tank",     color = {0.29, 0.64, 1.0} },
        { id = "Healer",  label = "Healer",   color = {0.27, 1.0, 0.40} },
        { id = "DPS",     label = "DPS",      color = {1.0, 0.33, 0.33} },
        { id = "Support", label = "Support", color = {0.70, 0.40, 1.00} },
    }
    Presence.roleCycleIndex = Presence.roleCycleIndex or 1
    for k in pairs(Presence.roleFilter or {}) do
        Presence.roleFilter[k] = false
    end

    local roleBtn = CreateFrame("Button", nil, toolbar)
    roleBtn:SetSize(110, 20)
    roleBtn:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 0, -32)
    roleBtn.bg = roleBtn:CreateTexture(nil, "BACKGROUND")
    roleBtn.bg:SetAllPoints()
    roleBtn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
    roleBtn.border = roleBtn:CreateTexture(nil, "BORDER")
    roleBtn.border:SetAllPoints()
    roleBtn.border:SetColorTexture(0.3, 0.4, 0.5, 1.0)
    roleBtn.text = roleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleBtn.text:SetPoint("CENTER")

    local function UpdateRoleBtnVisual()
        local r = ROLE_CYCLE[Presence.roleCycleIndex] or ROLE_CYCLE[1]
        roleBtn.text:SetText("|cff888888Role:|r |cffffffff" .. r.label .. "|r")
    end
    UpdateRoleBtnVisual()
    roleBtn:SetScript("OnClick", function()
        Presence.roleCycleIndex = (Presence.roleCycleIndex % #ROLE_CYCLE) + 1
        local r = ROLE_CYCLE[Presence.roleCycleIndex]
        for _, opt in ipairs(ROLE_CYCLE) do
            if Presence.roleFilter[opt.id] ~= nil then
                Presence.roleFilter[opt.id] = (opt.id == r.id) and r.id ~= "all"
            end
        end
        UpdateRoleBtnVisual()
        Presence:RefreshPanel()
    end)
    f.roleBtn = roleBtn

    local function applyRoleCycleState()
        local r = ROLE_CYCLE[Presence.roleCycleIndex] or ROLE_CYCLE[1]
        for _, opt in ipairs(ROLE_CYCLE) do
            if Presence.roleFilter[opt.id] ~= nil then
                Presence.roleFilter[opt.id] = (opt.id == r.id) and r.id ~= "all"
            end
        end
    end
    applyRoleCycleState()

    local sortLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortLabel:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 120, -35)
    sortLabel:SetText(_hex("textDim") .. (L["presence_sort"] or L["presence_sort"]) .. ":|r")
    local sortBtn = CreateFrame("Button", nil, toolbar)
    sortBtn:SetSize(80, 20)
    sortBtn:SetPoint("LEFT", sortLabel, "RIGHT", 4, 0)
    sortBtn.bg = sortBtn:CreateTexture(nil, "BACKGROUND")
    sortBtn.bg:SetAllPoints()
    sortBtn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
    sortBtn.border = sortBtn:CreateTexture(nil, "BORDER")
    sortBtn.border:SetAllPoints()
    sortBtn.border:SetColorTexture(0.3, 0.4, 0.5, 1.0)
    sortBtn.text = sortBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortBtn.text:SetPoint("CENTER")
    f.sortBtn = sortBtn
    Presence.sortMode = Presence.sortMode or "name"
    local SORT_OPTIONS = { "name", "guild", "zone", "seen" }
    sortBtn.text:SetText(L["presence_sort_" .. Presence.sortMode] or Presence.sortMode)
    sortBtn:SetScript("OnClick", function()
        local idx = 1
        for i, v in ipairs(SORT_OPTIONS) do
            if v == Presence.sortMode then idx = i; break end
        end
        Presence.sortMode = SORT_OPTIONS[(idx % #SORT_OPTIONS) + 1]
        sortBtn.text:SetText(L["presence_sort_" .. Presence.sortMode] or Presence.sortMode)
        Presence:RefreshPanel()
    end)

    local guildToggle = CreateFrame("Button", nil, toolbar)
    guildToggle:SetSize(120, 20)
    guildToggle:SetPoint("LEFT", sortBtn, "RIGHT", 12, 0)
    guildToggle.bg = guildToggle:CreateTexture(nil, "BACKGROUND")
    guildToggle.bg:SetAllPoints()
    guildToggle.bg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
    guildToggle.border = guildToggle:CreateTexture(nil, "BORDER")
    guildToggle.border:SetAllPoints()
    guildToggle.border:SetColorTexture(0.3, 0.4, 0.5, 1.0)
    guildToggle.text = guildToggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    guildToggle.text:SetPoint("CENTER")
    f.guildToggle = guildToggle
    Presence.guildOnly = Presence.guildOnly or false
    local function UpdateGuildToggleText()
        if Presence.guildOnly then
            guildToggle.text:SetText("|cff44ff44" .. (L["presence_guild_only"] or L["presence_guild_only_on"]) .. "|r")
        else
            guildToggle.text:SetText("|cff888888" .. (L["presence_guild_only"] or L["presence_guild_only"]) .. ": OFF|r")
        end
    end
    UpdateGuildToggleText()
    guildToggle:SetScript("OnClick", function()
        Presence.guildOnly = not Presence.guildOnly
        UpdateGuildToggleText()
        Presence:RefreshPanel()
    end)

    
    local footerY = 8
    local listH = VISIBLE_ROWS * ROW_HEIGHT + 2
    local listFrame = CreateFrame("Frame", nil, f)
    listFrame:SetHeight(listH)
    listFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, colY - 24)
    listFrame:SetWidth(496)

    local scrollFrame = CreateFrame("ScrollFrame", "FrostSeekPresenceScroll", listFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -18, 2)
    self.presenceScrollFrame = scrollFrame

    local scrollBarWidth = 16
    local rowWidth = 478 - scrollBarWidth

    self.rows = {}
    for i = 1, VISIBLE_ROWS do
        local r = CreateFrame("Button", nil, listFrame)
        r:SetWidth(rowWidth)
        r:SetHeight(ROW_HEIGHT)
        r:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(0, 0, 0, 0)

        r.statusDot = r:CreateTexture(nil, "ARTWORK")
        r.statusDot:SetSize(6, 6)
        r.statusDot:SetPoint("LEFT", r, "LEFT", 8, 0)
        r.statusDot:SetColorTexture(unpack(_tc("success")))

        r.classIconBorder = r:CreateTexture(nil, "BACKGROUND")
        r.classIconBorder:SetSize(22, 22)
        r.classIconBorder:SetPoint("CENTER", r, "LEFT", 28, 0)
        r.classIconBorder:SetColorTexture(0, 0, 0, 0)
        r.classIconBorder:Hide()

        r.classIcon = r:CreateTexture(nil, "ARTWORK")
        r.classIcon:SetSize(20, 20)
        r.classIcon:SetPoint("CENTER", r, "LEFT", 28, 0)
        r.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.classIcon:Hide()

        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.name:SetPoint("LEFT", r, "LEFT", 44, 0)
        r.name:SetWidth(95)
        r.name:SetJustifyH("LEFT")

        r.level = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.level:SetPoint("LEFT", r, "LEFT", 145, 0)
        r.level:SetWidth(30)

        r.role = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.role:SetPoint("LEFT", r, "LEFT", 180, 0)
        r.role:SetWidth(48)

        r.zone = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.zone:SetPoint("LEFT", r, "LEFT", 230, 0)
        r.zone:SetWidth(95)
        r.zone:SetJustifyH("LEFT")

        r.guild = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.guild:SetPoint("LEFT", r, "LEFT", 330, 0)
        r.guild:SetWidth(100)
        r.guild:SetJustifyH("LEFT")

        r.seen = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.seen:SetPoint("LEFT", r, "LEFT", 435, 0)
        r.seen:SetWidth(38)

        r.highlight = r:CreateTexture(nil, "HIGHLIGHT")
        r.highlight:SetAllPoints()
        r.highlight:SetColorTexture(unpack(_tc("bgRowHover")))
        r.highlight:SetAlpha(0.4)

        r:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(_tc("bgRowHover")[1], _tc("bgRowHover")[2], _tc("bgRowHover")[3], 0.25)
            if self.userData then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local classColor = GetClassColor(self.userData.classFile)
                GameTooltip:SetText(L["presence_user_tooltip"] or "FrostNet User", 0.53, 0.8, 1)
                GameTooltip:AddLine(tostring(self.userData.name or "?"), classColor[1], classColor[2], classColor[3])
                if self.userData.guild and self.userData.guild ~= "" then
                    GameTooltip:AddLine(L["tip_guild_label"] .. self.userData.guild, 0.9, 0.82, 0.55)
                end
                if self.userData.zone and self.userData.zone ~= "" then
                    GameTooltip:AddLine(L["tip_zone_label"] .. self.userData.zone, 0.9, 0.9, 0.9)
                end
                if self.userData.level and self.userData.level ~= "" then
                    GameTooltip:AddLine(L["level"] .. ": " .. tostring(self.userData.level), 0.9, 0.9, 0.9)
                end
                if self.userData.role and self.userData.role ~= "" then
                    local rc = self.userData.role == "Tank" and {0.29, 0.64, 1.0} or
                               self.userData.role == "Healer" and {0.27, 1.0, 0.40} or
                               self.userData.role == "DPS" and {1.0, 0.33, 0.33} or
                               (self.userData.role == "Support" or self.userData.role == "SUPPORT") and {0.70, 0.40, 1.00} or
                               {1, 1, 1}
                    GameTooltip:AddLine(L["lfg_role"] .. ": " .. self.userData.role, rc[1], rc[2], rc[3])
                end
                if self.userData.spec and self.userData.spec ~= "" then
                    GameTooltip:AddLine(L["tip_spec_label"] .. self.userData.spec, 1, 1, 1)
                end
                if self.userData.classFile and self.userData.classFile ~= "" then
                    GameTooltip:AddLine(L["class"] .. ": " .. self.userData.classFile, classColor[1], classColor[2], classColor[3])
                end
                if self.userData.version and self.userData.version ~= "" then
                    if self.userData.outdated then
                        GameTooltip:AddLine(L["tip_version_label"] .. self.userData.version .. L["presence_outdated_label"], 1, 0.5, 0.2)
                        GameTooltip:AddLine(" ", 0, 0, 0)
                        GameTooltip:AddLine(L["tip_update_frostnet"], 1, 0.8, 0.2)
                    else
                        GameTooltip:AddLine(L["tip_version_label"] .. self.userData.version, 0.6, 0.6, 0.6)
                    end
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["tip_left_click_whisper"], 0.4, 1, 0.4)
                GameTooltip:AddLine(L["tip_right_click_menu"], 0.4, 1, 0.4)
                GameTooltip:AddLine(L["tip_shift_click_favorite"], 0.7, 0.4, 1.0)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r:SetScript("OnClick", function(self, button)
            if not self.userData or not self.userData.name then return end
            local pn = UnitName("player") or ""
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    Presence.ToggleFavorite(self.userData.name)
                    return
                end
                if self.userData.name ~= pn then
                    if FrostSeekCompat and FrostSeekCompat.OpenChat then
                        FrostSeekCompat.OpenChat("/w " .. self.userData.name .. " ")
                    elseif ChatFrame_OpenChat then
                        ChatFrame_OpenChat("/w " .. self.userData.name .. " ")
                    end
                end
            elseif button == "RightButton" then
                if self.userData.name ~= pn then
                    Presence:ShowRowContextMenu(self.userData)
                end
            end
        end)

        self.rows[i] = r
        r:Hide()
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function()
            Presence:RefreshPanel()
        end)
    end)

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernButton then
        f.refreshBtn = FrostSeek.UI.CreateModernButton(f, 120, 24, L["presence_refresh_ping"])
    else
        f.refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.refreshBtn:SetSize(120, 24)
        f.refreshBtn:SetText(L["presence_refresh_ping"])
    end
    f.refreshBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, footerY)
    f.refreshBtn:SetScript("OnClick", function()
        Presence:SendPing()
        Presence:RefreshPanel()
        print(L["presence_ping_sent"])
    end)

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernButton then
        f.whoBtn = FrostSeek.UI.CreateModernButton(f, 100, 24, L["presence_who_list"])
    else
        f.whoBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.whoBtn:SetSize(100, 24)
        f.whoBtn:SetText(L["presence_who_list"])
    end
    f.whoBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, footerY)
    f.whoBtn:SetScript("OnClick", function()
        Presence:PrintOnlineUsers()
    end)

    f.autoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.autoLabel:SetPoint("BOTTOM", f, "BOTTOM", 0, footerY + 4)

    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
    if FrostSeekDB.Settings.presenceRefreshInterval == nil then
        FrostSeekDB.Settings.presenceRefreshInterval = REFRESH_INTERVAL
    end
    Presence.refreshIntervals = { 10, 30, 60, 0 }

    local autoBtn = CreateFrame("Button", nil, f)
    autoBtn:SetSize(120, 18)
    autoBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, footerY + 2)
    autoBtn:SetFrameLevel(f:GetFrameLevel() + 5)
    autoBtn.text = f.autoLabel
    local function UpdateAutoBtnLabel()
        local v = FrostSeekDB.Settings.presenceRefreshInterval
        local txt
        if v == 0 then
            txt = L["presence_auto_refresh_off"]
        else
            txt = _hex("textDim") .. L["presence_auto_refresh_label"] .. tostring(v) .. "s|r"
        end
        f.autoLabel:SetText(txt)
    end
    UpdateAutoBtnLabel()
    autoBtn:SetScript("OnEnter", function(self)
        f.autoLabel:SetText(L["txt_click_to_cycle"])
    end)
    autoBtn:SetScript("OnLeave", function(self)
        UpdateAutoBtnLabel()
    end)
    autoBtn:SetScript("OnClick", function()
        local cur = FrostSeekDB.Settings.presenceRefreshInterval
        local idx = 1
        for i, v in ipairs(Presence.refreshIntervals) do
            if v == cur then idx = i break end
        end
        idx = (idx % #Presence.refreshIntervals) + 1
        FrostSeekDB.Settings.presenceRefreshInterval = Presence.refreshIntervals[idx]
        UpdateAutoBtnLabel()
        Presence:ApplyRefreshInterval()
    end)
    f.autoBtn = autoBtn
    f.UpdateAutoBtnLabel = UpdateAutoBtnLabel
    Presence:ApplyRefreshInterval()

    f.versionLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.versionLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, footerY + 28)
    f.versionLabel:SetText(_hex("accent") .. "FrostSeek v" .. tostring(FrostSeek.VERSION or "?") .. "|r")

    f:Hide()
    return f
end

function Presence:RefreshPanel()
    if not self.panel then return end
    local rows = self:GetOnlineUsers()
    local stats = self:GetStats()
    local f = self.panel

    if f.onlineBadge then
        f.onlineBadge:SetText(_hex("accent") .. tostring(stats.total) .. "|r " .. _hex("textDim") .. L["presence_online_label"])
    end

    if f.statsLeft then
        local lines = {}
        table.insert(lines, _hex("textDim") .. L["presence_friends_label"] .. (stats.friends > 0 and "|cff44ff44" or "|cffffffff") .. tostring(stats.friends) .. "|r")
        table.insert(lines, _hex("textDim") .. L["presence_with_role_label"] .. tostring(stats.tanks + stats.healers + stats.dps + stats.supports) .. "|" .. tostring(stats.total))
        f.statsLeft:SetText(table.concat(lines, "\n"))
    end

    local maxRole = math.max(stats.tanks, stats.healers, stats.dps, stats.supports, 1)
    local barW = 130

    if f.tankBarFill then
        f.tankBarFill:SetWidth(stats.tanks > 0 and math.max(4, (stats.tanks / maxRole) * barW) or 0)
        f.tankCount:SetText(tostring(stats.tanks))
        f.tankCount:SetTextColor(unpack(stats.tanks > 0 and _tc("textNorm") or _tc("textDim")))
    end
    if f.healerBarFill then
        f.healerBarFill:SetWidth(stats.healers > 0 and math.max(4, (stats.healers / maxRole) * barW) or 0)
        f.healerCount:SetText(tostring(stats.healers))
        f.healerCount:SetTextColor(unpack(stats.healers > 0 and _tc("textNorm") or _tc("textDim")))
    end
    if f.dpsBarFill then
        f.dpsBarFill:SetWidth(stats.dps > 0 and math.max(4, (stats.dps / maxRole) * barW) or 0)
        f.dpsCount:SetText(tostring(stats.dps))
        f.dpsCount:SetTextColor(unpack(stats.dps > 0 and _tc("textNorm") or _tc("textDim")))
    end
    if f.supportBarFill then
        f.supportBarFill:SetWidth(stats.supports > 0 and math.max(4, (stats.supports / maxRole) * barW) or 0)
        f.supportCount:SetText(tostring(stats.supports))
        f.supportCount:SetTextColor(unpack(stats.supports > 0 and _tc("textNorm") or _tc("textDim")))
    end

    
    if f.statusDot and f.statusText then
        local Network = FrostSeek.Network
        local myStatus = FrostSeekDB and FrostSeekDB.Profile and FrostSeekDB.Profile.status or L["status_free"]
        local statusOpts = f.STATUS_OPTIONS or {}
        local statusInfo = nil
        for _, opt in ipairs(statusOpts) do
            if opt.id == myStatus then statusInfo = opt break end
        end
        if not statusInfo then statusInfo = { id = L["status_free"], color = {0.2, 0.9, 0.4}, hex = "|cff44ff44" } end

        if Network and Network.isConnected then
            f.statusDot:SetColorTexture(statusInfo.color[1], statusInfo.color[2], statusInfo.color[3], 1.0)
            f.statusText:SetText(statusInfo.hex .. myStatus .. "|r")
        else
            f.statusDot:SetColorTexture(unpack(_tc("danger")))
            f.statusText:SetText(L["txt_offline_colored"])
        end
    end


    local scrollOffset = 0
    if self.presenceScrollFrame then
        scrollOffset = FauxScrollFrame_GetOffset(self.presenceScrollFrame)
    end
    local totalUsers = #rows

    if self.presenceScrollFrame then
        FauxScrollFrame_Update(self.presenceScrollFrame, totalUsers, VISIBLE_ROWS, ROW_HEIGHT)
    end

    for i, row in ipairs(self.rows) do
        local u = rows[i + scrollOffset]
        if u then
            row:Show()
            row.userData = u

            local nameColor
            if u.isSelf then
                nameColor = GetClassHex(u.classFile)
            elseif u.isFriend then
                nameColor = "|cff44ff44"
            else
                nameColor = GetClassHex(u.classFile)
            end
            local favPrefix = ""
            if FrostSeekDB and FrostSeekDB.Favorites and FrostSeekDB.Favorites[u.name] then
                favPrefix = "|cffb366ff*|r "
            end
            if u.outdated then
                row.name:SetText(favPrefix .. "|cffffcc00!|r " .. nameColor .. tostring(u.name or "?") .. "|r")
            else
                row.name:SetText(favPrefix .. nameColor .. tostring(u.name or "?") .. "|r")
            end

            if row.classIcon then
                local cf = u.classFile
                if cf and cf ~= "" then
                    row.classIcon:SetTexture(GetClassIcon(cf))
                    row.classIcon:Show()
                    if row.classIconBorder then
                        local cColor = GetClassColor(cf)
                        if cColor then
                            row.classIconBorder:SetColorTexture(cColor[1], cColor[2], cColor[3], 0.35)
                            row.classIconBorder:Show()
                        else
                            row.classIconBorder:Hide()
                        end
                    end
                else
                    row.classIcon:Hide()
                    if row.classIconBorder then row.classIconBorder:Hide() end
                end
            end

            row.level:SetText(_hex("textDim") .. tostring(u.level or "") .. "|r")

            local roleColor = "|cff888888"
            local displayRole = (u.role and u.role ~= "") and u.role or L["none"]
            if u.role == "Tank" then roleColor = "|cff4aa3ff"
            elseif u.role == "Healer" then roleColor = "|cff44ff66"
            elseif u.role == "DPS" then roleColor = "|cffff5555"
            elseif u.role == "Support" or u.role == "SUPPORT" then roleColor = "|cffb366ff"
            elseif u.role == L["none"] or u.role == "" or not u.role then roleColor = "|cff888888"
            end
            row.role:SetText(roleColor .. displayRole .. "|r")

            local zoneStr = tostring(u.zone or "")
            if string.len(zoneStr) > 18 then zoneStr = string.sub(zoneStr, 1, 17) .. ".." end
            row.zone:SetText(_hex("textDim") .. zoneStr .. "|r")

            local guildStr = tostring(u.guild or "")
            if string.len(guildStr) > 14 then guildStr = string.sub(guildStr, 1, 13) .. ".." end
            row.guild:SetText(_hex("textDim") .. guildStr .. "|r")

            local age = time() - (u.seen or time())
            local userStatus = u.status or L["status_free"]

            local statusColor = {0.2, 0.9, 0.4}
            local statusOpts = f.STATUS_OPTIONS or {}
            for _, opt in ipairs(statusOpts) do
                if opt.id == userStatus then statusColor = opt.color break end
            end

            if userStatus == "Online" then statusColor = {0.2, 0.9, 0.4} end

            if u.isSelf then
                row.seen:SetText(L["txt_now_colored"])
                row.statusDot:SetColorTexture(statusColor[1], statusColor[2], statusColor[3], 1.0)
            elseif age < 60 then
                row.seen:SetText("|cff44ff44" .. tostring(age) .. "s|r")
                row.statusDot:SetColorTexture(statusColor[1], statusColor[2], statusColor[3], 1.0)
            elseif age < 300 then
                row.seen:SetText("|cffffcc00" .. tostring(math.floor(age / 60)) .. "m|r")
                row.statusDot:SetColorTexture(statusColor[1], statusColor[2], statusColor[3], 0.7)
            else
                row.seen:SetText("|cffff5555" .. tostring(math.floor(age / 60)) .. "m|r")
                row.statusDot:SetColorTexture(0.5, 0.5, 0.5, 0.5)
            end
        else
            row:Hide()
            row.userData = nil
            if row.classIcon then row.classIcon:Hide() end
            if row.classIconBorder then row.classIconBorder:Hide() end
        end
    end
end

Presence._ctxMenu = nil
Presence._activeToasts = Presence._activeToasts or {}

function Presence:ShowFavoriteToast(name, role, level)
    if not name or name == "" then return end
    if not FrostSeekDB or not FrostSeekDB.LFG or FrostSeekDB.LFG.silentNotifications == true then return end

    local toast = CreateFrame("Frame", nil, UIParent)
    toast:SetFrameStrata("TOOLTIP")
    toast:SetToplevel(true)
    toast:EnableMouse(true)
    toast:SetSize(280, 56)

    local toastW = 280
    local toastH = 56

    local idx = #Presence._activeToasts
    toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20 - (idx * (toastH + 6)))

    toast.bg = toast:CreateTexture(nil, "BACKGROUND")
    toast.bg:SetAllPoints()
    toast.bg:SetColorTexture(0.08, 0.08, 0.12, 0.97)

    toast.border = toast:CreateTexture(nil, "BORDER")
    toast.border:SetAllPoints()
    toast.border:SetColorTexture(0.7, 0.4, 1.0, 0.8)

    toast.accent = toast:CreateTexture(nil, "ARTWORK")
    toast.accent:SetSize(4, toastH - 6)
    toast.accent:SetPoint("LEFT", toast, "LEFT", 3, 0)
    toast.accent:SetColorTexture(0.7, 0.4, 1.0, 1.0)

    toast.icon = toast:CreateTexture(nil, "ARTWORK")
    toast.icon:SetSize(28, 28)
    toast.icon:SetPoint("LEFT", toast, "LEFT", 12, 0)
    toast.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 8, -2)
    toast.title:SetText("|cffb366ff" .. (L["presence_favorite_online_title"] or "Favorite Online") .. "|r")

    toast.body = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.body:SetPoint("BOTTOMLEFT", toast.icon, "BOTTOMRIGHT", 8, 2)
    local bodyParts = {}
    table.insert(bodyParts, "|cffffffff" .. tostring(name) .. "|r")
    if level and level ~= "" then
        table.insert(bodyParts, "|cff888888" .. (L["level"] or "Lvl") .. " " .. tostring(level) .. "|r")
    end
    if role and role ~= "" then
        local roleColor = "|cff888888"
        if role == "Tank" then roleColor = "|cff4aa3ff"
        elseif role == "Healer" then roleColor = "|cff44ff66"
        elseif role == "DPS" then roleColor = "|cffff5555"
        elseif role == "Support" or role == "SUPPORT" then roleColor = "|cffb366ff"
        end
        table.insert(bodyParts, roleColor .. tostring(role) .. "|r")
    end
    toast.body:SetText(table.concat(bodyParts, "  "))

    toast:SetAlpha(0)
    toast:Show()
    local elapsed = 0
    local phase = "in"
    toast:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if phase == "in" then
            local a = math.min(1, elapsed / 0.25)
            self:SetAlpha(a)
            if a >= 1 then phase = "hold"; elapsed = 0 end
        elseif phase == "hold" then
            if elapsed >= 4.0 then phase = "out"; elapsed = 0 end
        elseif phase == "out" then
            local a = math.max(0, 1 - (elapsed / 0.4))
            self:SetAlpha(a)
            if a <= 0 then
                self:Hide()
                self:SetScript("OnUpdate", nil)
                for i, t in ipairs(Presence._activeToasts) do
                    if t == self then
                        table.remove(Presence._activeToasts, i)
                        break
                    end
                end
                Presence:RelayoutToasts()
                self:GetParent():SetScript("OnUpdate", nil)
            end
        end
    end)

    toast:SetScript("OnMouseDown", function(self)
        if FrostSeekCompat and FrostSeekCompat.OpenChat then
            FrostSeekCompat.OpenChat("/w " .. tostring(name) .. " ")
        elseif ChatFrame_OpenChat then
            ChatFrame_OpenChat("/w " .. tostring(name) .. " ")
        end
        self:SetScript("OnUpdate", nil)
        self:Hide()
        for i, t in ipairs(Presence._activeToasts) do
            if t == self then
                table.remove(Presence._activeToasts, i)
                break
            end
        end
        Presence:RelayoutToasts()
    end)

    table.insert(Presence._activeToasts, toast)
    Presence:RelayoutToasts()
end

function Presence:RelayoutToasts()
    local toastH = 56
    local gap = 6
    for i, t in ipairs(Presence._activeToasts) do
        t:ClearAllPoints()
        t:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20 - ((i - 1) * (toastH + gap)))
    end
end

function Presence:ShowRowContextMenu(userData)
    if not userData or not userData.name then return end
    if Presence._ctxMenu then
        Presence._ctxMenu:Hide()
        Presence._ctxMenu = nil
    end
    local menu = CreateFrame("Frame", "FrostSeekPresenceCtxMenu", UIParent)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetToplevel(true)
    menu:EnableMouse(true)
    local isFav = FrostSeekDB and FrostSeekDB.Favorites and FrostSeekDB.Favorites[userData.name] ~= nil
    local options = {
        { label = L["popup_whisper"] or L["popup_whisper"], action = function()
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat("/w " .. userData.name .. " ")
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat("/w " .. userData.name .. " ")
            end
        end },
        { label = L["popup_invite"] or L["popup_invite"], action = function()
            pcall(function() InviteUnit(userData.name) end)
        end },
        { label = L["presence_add_friend"] or L["presence_add_friend"], action = function()
            pcall(function() AddOrRemoveFriend(userData.name) end)
        end },
        { label = isFav and (L["presence_remove_favorite"] or "Remove Favorite") or (L["presence_add_favorite"] or "Add Favorite"),
          action = function()
            Presence.ToggleFavorite(userData.name)
        end },
        { label = L["presence_join_voice"] or L["presence_join_voice"], action = function()
            local VB = FrostSeek and FrostSeek.VoiceBridge
            if VB then VB:JoinVoice(userData.name) end
        end },
    }
    local itemH = 22
    menu:SetSize(170, #options * itemH + 8)
    menu:SetPoint("CENTER")
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    menu:SetBackdropColor(0.08, 0.08, 0.12, 0.97)
    for i, opt in ipairs(options) do
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(160, itemH)
        btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -4 - ((i - 1) * itemH))
        btn:RegisterForClicks("LeftButtonUp")
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        btn.text:SetText(opt.label)
        btn.text:SetTextColor(0.9, 0.9, 0.9)
        btn:SetScript("OnClick", function()
            menu:Hide()
            Presence._ctxMenu = nil
            opt.action()
        end)
        btn:SetScript("OnEnter", function(self)
            self.text:SetTextColor(0.5, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self.text:SetTextColor(0.9, 0.9, 0.9)
        end)
    end

    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetFrameStrata("DIALOG")
    closer:SetAllPoints(UIParent)
    closer:RegisterForClicks("AnyUp")
    closer:SetScript("OnClick", function()
        menu:Hide()
        closer:Hide()
        Presence._ctxMenu = nil
    end)
    menu.closer = closer
    Presence._ctxMenu = menu
    menu:Show()
end

function Presence:TogglePanel(parentFrame)
    if not self.panel then
        self:BuildPanel(parentFrame or FrostSeek and FrostSeek.MainFrame)
    end
    if self.panel:IsShown() then
        self.panel:Hide()
        self.panelVisible = false
    else
        self.panel:Show()
        self.panelVisible = true
        self:RefreshPanel()
    end
end

function Presence:ShowPanel(parentFrame)
    if not self.panel then
        self:BuildPanel(parentFrame or FrostSeek and FrostSeek.MainFrame)
    end
    self.panel:Show()
    self.panelVisible = true
    self:RefreshPanel()
end

function Presence:HidePanel()
    if self.panel then
        self.panel:Hide()
        self.panelVisible = false
    end
end

C_Timer.NewTicker(PING_INTERVAL, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.frostnetEnabled ~= false then
        if Shared and Shared._cachedPlayerClass then
            Shared._cachedPlayerClass = nil
        end
        if Presence.onlineUsers then
            local pn = UnitName("player") or ""
            if Presence.onlineUsers[pn] then
                local cf
                if Shared and Shared.GetPlayerClassFile then
                    cf = Shared.GetPlayerClassFile()
                else
                    _, cf = UnitClass("player")
                end
                Presence.onlineUsers[pn].classFile = cf or ""
            end
        end
        Presence:SendPing()
    end
end)

C_Timer.NewTicker(5, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    Presence:PruneUsers()
end)

Presence._refreshTicker = nil
function Presence:ApplyRefreshInterval()
    local v = (FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.presenceRefreshInterval) or REFRESH_INTERVAL
    if Presence._refreshTicker then
        Presence._refreshTicker:Cancel()
        Presence._refreshTicker = nil
    end
    if v == 0 then return end
    Presence._refreshTicker = C_Timer.NewTicker(v, function()
        if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
        if Presence.panelVisible and Presence.panel and Presence.panel:IsShown() then
            Presence:RefreshPanel()
        end
    end)
end

FrostSeek.Presence = Presence

if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("presence")
end