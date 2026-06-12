-- FrostSeek Presence Module

local FrostSeek = _G.FrostSeek

local Presence = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("presence", Presence)

local function _tc(token)
    local T = _G.FrostSeekTheme or (FrostSeek and FrostSeek.Theme)
    if T and T.Get then return T.Get(token) end
    return {0.5, 0.5, 0.5}
end

local function _hex(token)
    local c = _tc(token)
    if not c or #c < 3 then return "|cFF888888" end
    return string.format("|cFF%02X%02X%02X", math.min(255, math.floor(c[1] * 255 + 0.5)), math.min(255, math.floor(c[2] * 255 + 0.5)), math.min(255, math.floor(c[3] * 255 + 0.5)))
end

local PING_INTERVAL = 55     
local PRUNE_AFTER = 180       
local REFRESH_INTERVAL = 10    

Presence.onlineUsers = {}
Presence.panel = nil
Presence.panelVisible = false


local CLASS_COLORS = {
    WARRIOR  = {0.78, 0.61, 0.43},
    PALADIN  = {0.96, 0.55, 0.73},
    HUNTER   = {0.67, 0.83, 0.45},
    ROGUE    = {1.00, 0.96, 0.41},
    PRIEST   = {1.00, 1.00, 1.00},
    SHAMAN   = {0.00, 0.44, 0.87},
    MAGE     = {0.41, 0.80, 0.94},
    WARLOCK  = {0.58, 0.51, 0.79},
    DRUID    = {1.00, 0.49, 0.04},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
}

local function GetClassColor(classFile)
    if not classFile then return {0.7, 0.7, 0.7} end
    return CLASS_COLORS[string.upper(classFile)] or {0.7, 0.7, 0.7}
end

local function GetClassHex(classFile)
    local c = GetClassColor(classFile)
    return string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

function Presence:SendPing()
    local Network = FrostSeek and FrostSeek.Network
    if not Network or not Network.SendPresence then return end

    local profile = FrostSeekDB and FrostSeekDB.Profile or {}
    Network:SendPresence(
        FrostSeek.VERSION or "1.7.0",
        profile.role or "",
        profile.spec or ""
    )
end

function Presence:HandlePresence(user)
    if not user or not user.name or user.name == "" then return end
    local pn = UnitName("player") or ""
    if user.name == pn then return end

    self.onlineUsers[user.name] = user

    if self.panelVisible and self.panel and self.panel:IsShown() then
        self:RefreshPanel()
    end

    if FrostSeek.DashboardRefresh then
        FrostSeek.DashboardRefresh()
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
    self:PruneUsers()
    local c = 1 
    for _ in pairs(self.onlineUsers) do
        c = c + 1
    end
    return c
end

function Presence:GetOnlineUsers()
    self:PruneUsers()
    local rows = {}
    local _, classFile = UnitClass("player")
    local profile = FrostSeekDB and FrostSeekDB.Profile or {}
    table.insert(rows, {
        name = UnitName("player") or "",
        version = FrostSeek.VERSION or "1.7.0",
        level = tostring(UnitLevel("player") or 60),
        classFile = classFile or "",
        role = profile.role or "",
        spec = profile.spec or "",
        zone = GetRealZoneText() or "",
        guild = GetGuildInfo("player") or "",
        seen = time(),
        isSelf = true,
        isFriend = false,
    })

    for _, u in pairs(self.onlineUsers) do
        u.isFriend = IsFriend and IsFriend(u.name) or false
        u.isSelf = false
        table.insert(rows, u)
    end

    table.sort(rows, function(a, b)
        if a.isSelf and not b.isSelf then return true end
        if b.isSelf and not a.isSelf then return false end
        if a.isFriend and not b.isFriend then return true end
        if b.isFriend and not a.isFriend then return false end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return rows
end

function Presence:GetStats()
    local rows = self:GetOnlineUsers()
    local stats = {
        total = #rows,
        friends = 0,
        tanks = 0,
        healers = 0,
        dps = 0,
    }

    for _, u in ipairs(rows) do
        if u.isFriend then stats.friends = stats.friends + 1 end
        if u.role == "Tank" then stats.tanks = stats.tanks + 1
        elseif u.role == "Healer" then stats.healers = stats.healers + 1
        elseif u.role == "DPS" then stats.dps = stats.dps + 1
        end
    end

    return stats
end

function Presence:GetRoleDistribution()
    local stats = self:GetStats()
    local total = stats.tanks + stats.healers + stats.dps
    if total == 0 then
        return { tank = 0, healer = 0, dps = 0 }
    end
    return {
        tank = stats.tanks / total,
        healer = stats.healers / total,
        dps = stats.dps / total,
    }
end

function Presence:PrintOnlineUsers()
    self:PruneUsers()
    local rows = self:GetOnlineUsers()
    print("|cff88ccffFrostNet Online:|r " .. tostring(#rows) .. " users online")
    for _, u in ipairs(rows) do
        local guild = u.guild and u.guild ~= "" and (" <" .. u.guild .. ">") or ""
        local role = u.role and u.role ~= "" and (" - " .. u.role) or ""
        local zone = u.zone and u.zone ~= "" and (" - " .. u.zone) or ""
        local lvl = u.level and u.level ~= "" and (" lvl " .. u.level) or ""
        print("  " .. tostring(u.name or "?") .. guild .. lvl .. role .. zone)
    end
end

local MAX_ROWS = 12

function Presence:BuildPanel(parent)
    if self.panel then return self.panel end

    local f = CreateFrame("Frame", "FrostSeekPresencePanel", parent or UIParent)
    self.panel = f
    f:SetWidth(440)
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
    f.statusDot = headerFrame:CreateTexture(nil, "ARTWORK")
    f.statusDot:SetSize(8, 8)
    f.statusDot:SetPoint("RIGHT", headerFrame, "RIGHT", -36, 2)
    f.statusDot:SetColorTexture(unpack(_tc("success")))
    f.statusText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.statusText:SetPoint("RIGHT", f.statusDot, "LEFT", -4, 0)
    f.statusText:SetText("Online")

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
    local barW = 160
    local barH = 10
    local barGap = 16
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

    local colY = statsY - statsH - 6
    local header = CreateFrame("Frame", nil, f)
    header:SetWidth(416)
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

    local hLabels = {{"Status", 6}, {"Player", 22}, {"Lvl", 125}, {"Role", 155}, {"Zone", 200}, {"Guild", 300}, {"Seen", 390}}
    for _, lbl in ipairs(hLabels) do
        local t = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", header, "LEFT", lbl[2], 0)
        t:SetText(_hex("textDim") .. lbl[1] .. "|r")
    end

    self.rows = {}
    local rowStartY = colY - 24
    for i = 1, MAX_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(416)
        r:SetHeight(24)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 10, rowStartY - ((i - 1) * 26))

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(0, 0, 0, 0)

        r.statusDot = r:CreateTexture(nil, "ARTWORK")
        r.statusDot:SetSize(6, 6)
        r.statusDot:SetPoint("LEFT", r, "LEFT", 8, 0)
        r.statusDot:SetColorTexture(unpack(_tc("success")))

        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.name:SetPoint("LEFT", r, "LEFT", 22, 0)
        r.name:SetWidth(101)
        r.name:SetJustifyH("LEFT")

        r.level = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.level:SetPoint("LEFT", r, "LEFT", 125, 0)
        r.level:SetWidth(28)

        r.role = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.role:SetPoint("LEFT", r, "LEFT", 155, 0)
        r.role:SetWidth(42)

        r.zone = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.zone:SetPoint("LEFT", r, "LEFT", 200, 0)
        r.zone:SetWidth(98)
        r.zone:SetJustifyH("LEFT")

        r.guild = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.guild:SetPoint("LEFT", r, "LEFT", 300, 0)
        r.guild:SetWidth(88)
        r.guild:SetJustifyH("LEFT")

        r.seen = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.seen:SetPoint("LEFT", r, "LEFT", 390, 0)
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
                GameTooltip:SetText("FrostNet User", 0.53, 0.8, 1)
                GameTooltip:AddLine(tostring(self.userData.name or "?"), classColor[1], classColor[2], classColor[3])
                if self.userData.guild and self.userData.guild ~= "" then
                    GameTooltip:AddLine("Guild: " .. self.userData.guild, 0.9, 0.82, 0.55)
                end
                if self.userData.zone and self.userData.zone ~= "" then
                    GameTooltip:AddLine("Zone: " .. self.userData.zone, 0.9, 0.9, 0.9)
                end
                if self.userData.level and self.userData.level ~= "" then
                    GameTooltip:AddLine("Level: " .. tostring(self.userData.level), 0.9, 0.9, 0.9)
                end
                if self.userData.role and self.userData.role ~= "" then
                    local rc = self.userData.role == "Tank" and {0.29, 0.64, 1.0} or
                               self.userData.role == "Healer" and {0.27, 1.0, 0.40} or
                               self.userData.role == "DPS" and {1.0, 0.33, 0.33} or {1, 1, 1}
                    GameTooltip:AddLine("Role: " .. self.userData.role, rc[1], rc[2], rc[3])
                end
                if self.userData.spec and self.userData.spec ~= "" then
                    GameTooltip:AddLine("Spec: " .. self.userData.spec, 1, 1, 1)
                end
                if self.userData.classFile and self.userData.classFile ~= "" then
                    GameTooltip:AddLine("Class: " .. self.userData.classFile, classColor[1], classColor[2], classColor[3])
                end
                if self.userData.version and self.userData.version ~= "" then
                    GameTooltip:AddLine("Version: " .. self.userData.version, 0.6, 0.6, 0.6)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Right-click to Whisper", 0.4, 1, 0.4)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
            GameTooltip:Hide()
        end)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.userData and self.userData.name then
                local pn = UnitName("player") or ""
                if self.userData.name ~= pn then
                    ChatFrame_OpenChat("/w " .. self.userData.name .. " ")
                end
            end
        end)

        self.rows[i] = r
        r:Hide()
    end

    local footerY = 8

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernButton then
        f.refreshBtn = FrostSeek.UI.CreateModernButton(f, 120, 24, "Refresh Ping")
    else
        f.refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.refreshBtn:SetSize(120, 24)
        f.refreshBtn:SetText("Refresh Ping")
    end
    f.refreshBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, footerY)
    f.refreshBtn:SetScript("OnClick", function()
        Presence:SendPing()
        Presence:RefreshPanel()
        print("|cff88ccffFrostNet:|r Ping sent!")
    end)

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernButton then
        f.whoBtn = FrostSeek.UI.CreateModernButton(f, 100, 24, "Who List")
    else
        f.whoBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.whoBtn:SetSize(100, 24)
        f.whoBtn:SetText("Who List")
    end
    f.whoBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, footerY)
    f.whoBtn:SetScript("OnClick", function()
        Presence:PrintOnlineUsers()
    end)

    f.autoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.autoLabel:SetPoint("BOTTOM", f, "BOTTOM", 0, footerY + 4)
    f.autoLabel:SetText(_hex("textDim") .. "Auto-refresh: " .. tostring(REFRESH_INTERVAL) .. "s|r")

    f:Hide()
    return f
end

function Presence:RefreshPanel()
    if not self.panel then return end
    local rows = self:GetOnlineUsers()
    local stats = self:GetStats()
    local f = self.panel

    if f.onlineBadge then
        f.onlineBadge:SetText(_hex("accent") .. tostring(stats.total) .. "|r " .. _hex("textDim") .. "online|r")
    end

    if f.statsLeft then
        local lines = {}
        table.insert(lines, _hex("textDim") .. "Friends:|r " .. (stats.friends > 0 and "|cff44ff44" or "|cffffffff") .. tostring(stats.friends) .. "|r")
        table.insert(lines, _hex("textDim") .. "With Role:|r " .. tostring(stats.tanks + stats.healers + stats.dps) .. "|" .. tostring(stats.total))
        f.statsLeft:SetText(table.concat(lines, "\n"))
    end

    local maxRole = math.max(stats.tanks, stats.healers, stats.dps, 1)
    local barW = 160

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

    if f.statusDot then
        local Network = FrostSeek.Network
        if Network and Network.isConnected then
            f.statusDot:SetColorTexture(unpack(_tc("success")))
            if f.statusText then f.statusText:SetText("|cff44ff44Online|r") end
        else
            f.statusDot:SetColorTexture(unpack(_tc("danger")))
            if f.statusText then f.statusText:SetText("|cffff5555Offline|r") end
        end
    end

    for i, row in ipairs(self.rows) do
        local u = rows[i]
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
            row.name:SetText(nameColor .. tostring(u.name or "?") .. "|r")

            row.level:SetText(_hex("textDim") .. tostring(u.level or "") .. "|r")

            local roleColor = "|cffffffff"
            if u.role == "Tank" then roleColor = "|cff4aa3ff"
            elseif u.role == "Healer" then roleColor = "|cff44ff66"
            elseif u.role == "DPS" then roleColor = "|cffff5555"
            end
            row.role:SetText(roleColor .. tostring(u.role or "") .. "|r")

            local zoneStr = tostring(u.zone or "")
            if string.len(zoneStr) > 18 then zoneStr = string.sub(zoneStr, 1, 17) .. ".." end
            row.zone:SetText(_hex("textDim") .. zoneStr .. "|r")

            local guildStr = tostring(u.guild or "")
            if string.len(guildStr) > 14 then guildStr = string.sub(guildStr, 1, 13) .. ".." end
            row.guild:SetText(_hex("textDim") .. guildStr .. "|r")

            local age = time() - (u.seen or time())
            if u.isSelf then
                row.seen:SetText("|cff44ff44now|r")
                row.statusDot:SetColorTexture(0.2, 0.9, 0.4, 1.0)
            elseif age < 60 then
                row.seen:SetText("|cff44ff44" .. tostring(age) .. "s|r")
                row.statusDot:SetColorTexture(0.2, 0.9, 0.4, 1.0)
            elseif age < 300 then
                row.seen:SetText("|cffffcc00" .. tostring(math.floor(age / 60)) .. "m|r")
                row.statusDot:SetColorTexture(1.0, 0.75, 0.2, 0.9)
            else
                row.seen:SetText("|cffff5555" .. tostring(math.floor(age / 60)) .. "m|r")
                row.statusDot:SetColorTexture(0.95, 0.3, 0.3, 0.7)
            end
        else
            row:Hide()
            row.userData = nil
        end
    end
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
        Presence:SendPing()
    end
end)

C_Timer.NewTicker(REFRESH_INTERVAL, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    Presence:PruneUsers()
    if Presence.panelVisible and Presence.panel and Presence.panel:IsShown() then
        Presence:RefreshPanel()
    end
end)


FrostSeek.Presence = Presence

local function RegisterPresenceModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterPresenceModule)
        return
    end
    if not _G.FrostSeek._v or not _G.FrostSeek._v.c(_tk) then return end
    if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
        _G.FrostSeekTheme.RegisterModule("presence")
    end
end

RegisterPresenceModule()

local FROSTSEEK_SIG = "FSK-" .. string.char(70,82,79,83,84) .. "-" .. "0x4FSK7"
