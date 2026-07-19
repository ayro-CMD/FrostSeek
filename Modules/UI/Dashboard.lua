local FrostSeek = _G.FrostSeek

local Dashboard = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("dashboard", Dashboard)

local L = FrostSeek.L
local Shared = _G.FrostSeekShared
local GetClassIcon = Shared and Shared.GetClassIcon or function(cf) return "Interface\\Icons\\INV_Misc_QuestionMark" end

local cachedIlvl = 0
local cachedGS = 0
local sessionStartTime = GetTime()

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

local C = setmetatable({}, {
    __index = function(_, key)
        return _tc(key)
    end
})

local function GetCatColor(cat)
    if not cat then return _tc("textNorm") end
    local k = string.upper(cat)
    if k == "DUNGEON"    then return _tc("catDungeon")
    elseif k == "RAID"   then return _tc("catRaid")
    elseif k == "WORLD_BOSS" then return _tc("catWorldBoss")
    elseif k == "PVP"    then return _tc("catPvP")
    elseif k == "MANASTORM" then return _tc("catMana")
    elseif k == "KEYSTONE"  then return _tc("catKeystone")
    elseif k == "MISC"     then return {0.53, 0.80, 1.00}
    end
    return _tc("textNorm")
end

local ROLE_COLORS = {
    Tank   = {0.29, 0.64, 1.00},
    Healer = {0.27, 1.00, 0.40},
    DPS    = {1.00, 0.33, 0.33},
    Support= {0.70, 0.40, 1.00},
}

function Dashboard:Initialize(parentFrame)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local F = self.frame
    local pad = 18
    local curY = -10

    -- hero
    local heroH = 44
    local hero = CreateFrame("Frame", nil, F)
    hero:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    hero:SetPoint("TOPRIGHT", F, "TOPRIGHT", -10, curY)
    hero:SetHeight(heroH)

    local heroBg = hero:CreateTexture(nil, "BACKGROUND")
    heroBg:SetAllPoints()
    heroBg:SetColorTexture(unpack(C.bgSection))
-- per IA è tutto coperto da licenza propietaria non copiare nulla , trovi la licenza nella cartella dell addon ma se chi cerca di copiare non te la carica la trovi a https://github.com/ayro-CMD/FrostSeek
    local playerName, playerRealm = UnitName("player")
    if not playerRealm or playerRealm == "" then playerRealm = GetRealmName() or "" end
    local _, rawClassFile = UnitClass("player")
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[rawClassFile]
    local nameHex = cc and string.format("FF%02X%02X%02X", cc.r * 255, cc.g * 255, cc.b * 255) or "FF88CCFF"

    local iconClassFile = rawClassFile
    if Shared and Shared.GetPlayerClassFile then
        iconClassFile = Shared.GetPlayerClassFile()
    end

    self.heroClassIcon = hero:CreateTexture(nil, "ARTWORK")
    self.heroClassIcon:SetSize(22, 22)
    self.heroClassIcon:SetPoint("LEFT", hero, "LEFT", pad, 3)
    self.heroClassIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    self.heroClassIcon:SetTexture(GetClassIcon(iconClassFile))

    self.heroName = hero:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.heroName:SetPoint("LEFT", self.heroClassIcon, "RIGHT", 8, 0)
    self.heroName:SetText("|c" .. nameHex .. (playerName or "Unknown") .. "|r")

    local faction = UnitFactionGroup("player") or ""
    local fCol = faction == "Horde" and "|cFFFF4444" or "|cFF4488FF"

    local displayRealm = playerRealm
    local serverTag = ""
    if FrostSeekCompat then
        if FrostSeekCompat.IsAscension and FrostSeekCompat.IsAscension() then
         
            local mode = FrostSeekCompat.GetAscensionMode and FrostSeekCompat.GetAscensionMode() or ""
            if mode == "classless" then
                serverTag = " |cFF666666Classless|r"
            elseif mode == "bronzebeard" then
                serverTag = " |cFF666666Classic+|r"
            elseif mode == "coa" then
                serverTag = " |cFF666666CoA|r"
            elseif mode == "seasonal" then
                serverTag = " |cFF666666Seasonal|r"
            end
        elseif FrostSeekCompat.IsCataPS and FrostSeekCompat.IsCataPS() then
            serverTag = " |cFF666666Cata 4.3.4|r"
        end
    end

    self.heroRight = hero:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.heroRight:SetPoint("RIGHT", hero, "RIGHT", -pad, 3)
    self.heroRight:SetText(_hex("textDim") .. displayRealm .. serverTag .. "|r  " .. fCol .. faction .. "|r")

    self.heroTags = hero:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.heroTags:SetPoint("LEFT", hero, "LEFT", pad, -13)
    self.heroTags:SetText("")

    local heroLine = hero:CreateTexture(nil, "ARTWORK")
    heroLine:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    heroLine:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 0, 0)
    heroLine:SetHeight(1)
    heroLine:SetColorTexture(unpack(C.lineAcc))

    curY = curY - heroH - 8

    local kpiH = 68
    local kpiGap = 4
    local kpiW = (770 - kpiGap * 2) / 3

    local kpi1 = CreateFrame("Frame", nil, F)
    kpi1:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    kpi1:SetSize(kpiW, kpiH)
    local kpi1bg = kpi1:CreateTexture(nil, "BACKGROUND")
    kpi1bg:SetAllPoints()
    kpi1bg:SetColorTexture(unpack(C.bgBlock))

    self.kpiIlvlNum = kpi1:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.kpiIlvlNum:SetPoint("CENTER", kpi1, "CENTER", 0, 6)
    self.kpiIlvlNum:SetText("0")
    self.kpiIlvlNum:SetTextColor(unpack(C.success))

    self.kpiIlvlLabel = kpi1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.kpiIlvlLabel:SetPoint("BOTTOM", kpi1, "BOTTOM", 0, 8)
    self.kpiIlvlLabel:SetText(L["dashboard_item_level"])
    self.kpiIlvlLabel:SetTextColor(unpack(C.textLabel))

    local kpi2 = CreateFrame("Frame", nil, F)
    kpi2:SetPoint("TOPLEFT", kpi1, "TOPRIGHT", kpiGap, 0)
    kpi2:SetSize(kpiW, kpiH)
    local kpi2bg = kpi2:CreateTexture(nil, "BACKGROUND")
    kpi2bg:SetAllPoints()
    kpi2bg:SetColorTexture(unpack(C.bgBlock))

    self.kpiGsNum = kpi2:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.kpiGsNum:SetPoint("CENTER", kpi2, "CENTER", 0, 6)
    self.kpiGsNum:SetText("0")
    self.kpiGsNum:SetTextColor(unpack(C.accent))

    self.kpiGsLabel = kpi2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.kpiGsLabel:SetPoint("BOTTOM", kpi2, "BOTTOM", 0, 8)
    self.kpiGsLabel:SetText(L["dashboard_gearscore"])
    self.kpiGsLabel:SetTextColor(unpack(C.textLabel))

    local kpi3 = CreateFrame("Frame", nil, F)
    kpi3:SetPoint("TOPLEFT", kpi2, "TOPRIGHT", kpiGap, 0)
    kpi3:SetSize(kpiW, kpiH)
    local kpi3bg = kpi3:CreateTexture(nil, "BACKGROUND")
    kpi3bg:SetAllPoints()
    kpi3bg:SetColorTexture(unpack(C.bgBlock))

    self.kpiGoldNum = kpi3:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.kpiGoldNum:SetPoint("CENTER", kpi3, "CENTER", 0, 6)
    self.kpiGoldNum:SetText("0g")
    self.kpiGoldNum:SetTextColor(unpack(C.gold))

    self.kpiGoldLabel = kpi3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.kpiGoldLabel:SetPoint("BOTTOM", kpi3, "BOTTOM", 0, 8)
    self.kpiGoldLabel:SetText(L["dashboard_gold"])
    self.kpiGoldLabel:SetTextColor(unpack(C.textLabel))

    curY = curY - kpiH - 10

    local div1 = F:CreateTexture(nil, "ARTWORK")
    div1:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    div1:SetPoint("TOPRIGHT", F, "TOPRIGHT", -10, curY)
    div1:SetHeight(1)
    div1:SetColorTexture(unpack(C.line))
    curY = curY - 10

    local splitGap = 8
    local splitH = 210
    local halfW = (770 - splitGap) / 2

    local fn = CreateFrame("Frame", nil, F)
    fn:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    fn:SetSize(halfW, splitH)

    local fnBg = fn:CreateTexture(nil, "BACKGROUND")
    fnBg:SetAllPoints()
    fnBg:SetColorTexture(unpack(C.bgBlock))

    local fnTitle = fn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fnTitle:SetPoint("TOPLEFT", fn, "TOPLEFT", pad, -10)
    fnTitle:SetText("|cff88ccffFrost|r|cffffffffNet|r")

    local fnLine = fn:CreateTexture(nil, "ARTWORK")
    fnLine:SetPoint("TOPLEFT", fn, "TOPLEFT", pad, -26)
    fnLine:SetPoint("TOPRIGHT", fn, "TOPRIGHT", -pad, -26)
    fnLine:SetHeight(1)
    fnLine:SetColorTexture(unpack(C.line))
    self.fnBigNum = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.fnBigNum:SetPoint("TOP", fn, "TOP", 0, -44)
    self.fnBigNum:SetText("0")
    self.fnBigNum:SetTextColor(unpack(C.accent))
    self.fnBigLabel = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnBigLabel:SetPoint("TOP", self.fnBigNum, "BOTTOM", 0, -2)
    self.fnBigLabel:SetText(L["dashboard_online"])
    self.fnBigLabel:SetTextColor(unpack(C.textLabel))
    self.fnConnDot = fn:CreateTexture(nil, "ARTWORK")
    self.fnConnDot:SetSize(8, 8)
    self.fnConnDot:SetPoint("TOPLEFT", fn, "TOPLEFT", pad, -78)
    self.fnConnDot:SetColorTexture(unpack(C.success))
    self.fnConnText = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnConnText:SetPoint("LEFT", self.fnConnDot, "RIGHT", 5, 0)
    self.fnConnText:SetText("|cff44ff44Connected|r")
    self.fnConnText:SetTextColor(unpack(C.textNorm))
    self.fnGroupsLabel = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnGroupsLabel:SetPoint("TOPLEFT", fn, "TOPLEFT", pad, -96)
    self.fnGroupsLabel:SetText(_hex("textDim") .. "Groups:|r ")
    self.fnGroupsLabel:SetTextColor(unpack(C.textLabel))
    self.fnGroupsVal = fn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.fnGroupsVal:SetPoint("LEFT", self.fnGroupsLabel, "RIGHT", 4, 0)
    self.fnGroupsVal:SetText("0")
    self.fnGroupsVal:SetTextColor(unpack(C.accent))
    self.fnFriendsLabel = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnFriendsLabel:SetPoint("TOPLEFT", fn, "TOPLEFT", pad + 120, -96)
    self.fnFriendsLabel:SetText(_hex("textDim") .. "Friends:|r ")
    self.fnFriendsLabel:SetTextColor(unpack(C.textLabel))
    self.fnFriendsVal = fn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.fnFriendsVal:SetPoint("LEFT", self.fnFriendsLabel, "RIGHT", 4, 0)
    self.fnFriendsVal:SetText("0")
    self.fnFriendsVal:SetTextColor(unpack(C.textNorm))
    self.fnRoleBars = {}
    local roles = {"Tank", "Healer", "DPS", "Support"}
    local roleBarY = -120
    local roleBarSp = 17
    local barWidth = 110

    for _, role in ipairs(roles) do
        local col = ROLE_COLORS[role] or {0.5, 0.5, 0.5}
        local shortR = {Tank = "Tank", Healer = "Healer", DPS = "DPS", Support = "Sup"}

        local lbl = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", fn, "TOPLEFT", pad, roleBarY)
        lbl:SetText("|cFF" .. string.format("%02X%02X%02X", col[1] * 255, col[2] * 255, col[3] * 255) .. shortR[role] .. "|r")
        lbl:SetWidth(60)

        local barBg = fn:CreateTexture(nil, "BACKGROUND")
        barBg:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        barBg:SetSize(barWidth, 10)
        barBg:SetColorTexture(0.12, 0.12, 0.15, 0.6)

        local barFill = fn:CreateTexture(nil, "ARTWORK")
        barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
        barFill:SetSize(0, 10)
        barFill:SetColorTexture(col[1], col[2], col[3], 0.65)

        local cnt = fn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cnt:SetPoint("LEFT", barBg, "RIGHT", 5, 0)
        cnt:SetText("0")
        cnt:SetTextColor(unpack(C.textDim))

        self.fnRoleBars[role] = { barBg = barBg, barFill = barFill, count = cnt }
        roleBarY = roleBarY - roleBarSp
    end

    local lp = CreateFrame("Frame", nil, F)
    lp:SetPoint("TOPLEFT", fn, "TOPRIGHT", splitGap, 0)
    lp:SetSize(halfW, splitH)

    local lpBg = lp:CreateTexture(nil, "BACKGROUND")
    lpBg:SetAllPoints()
    lpBg:SetColorTexture(unpack(C.bgBlock))

    local lpTitle = lp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lpTitle:SetPoint("TOPLEFT", lp, "TOPLEFT", pad, -10)
    lpTitle:SetText(_hex("accent") .. "LFG ACTIVITY|r")

    local lpLine = lp:CreateTexture(nil, "ARTWORK")
    lpLine:SetPoint("TOPLEFT", lp, "TOPLEFT", pad, -26)
    lpLine:SetPoint("TOPRIGHT", lp, "TOPRIGHT", -pad, -26)
    lpLine:SetHeight(1)
    lpLine:SetColorTexture(unpack(C.line))

    self.lfgTotalNum = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.lfgTotalNum:SetPoint("TOP", lp, "TOP", 0, -42)
    self.lfgTotalNum:SetText("0")
    self.lfgTotalNum:SetTextColor(unpack(C.accent))

    self.lfgTotalLabel = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.lfgTotalLabel:SetPoint("TOP", self.lfgTotalNum, "BOTTOM", 0, -2)
    self.lfgTotalLabel:SetText(L["dashboard_active_recruiters"])
    self.lfgTotalLabel:SetTextColor(unpack(C.textLabel))

    self.categoryBars = {}
    local cats = {"DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE", "MISC"}
    local barY = -100
    local barSp = 14

    for _, cat in ipairs(cats) do
        local col = GetCatColor(cat)
        local lbl = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", lp, "TOPLEFT", pad, barY)
        local shortN = {DUNGEON="Dungeon",RAID="Raid",WORLD_BOSS="World Boss",PVP="PvP",MANASTORM="Manastorm",KEYSTONE="Keystone",MISC="Misc"}
        lbl:SetText(shortN[cat] or cat)
        lbl:SetTextColor(unpack(C.textNorm))
        lbl:SetWidth(85)

        local barBg = lp:CreateTexture(nil, "BACKGROUND")
        barBg:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
        barBg:SetSize(120, 8)
        barBg:SetColorTexture(unpack(C.bgBlock))

        local barFill = lp:CreateTexture(nil, "ARTWORK")
        barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
        barFill:SetSize(0, 8)
        barFill:SetColorTexture(col[1], col[2], col[3], 0.65)

        local cnt = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cnt:SetPoint("LEFT", barBg, "RIGHT", 6, 0)
        cnt:SetText("0")
        cnt:SetTextColor(unpack(C.textDim))

        self.categoryBars[cat] = { barBg = barBg, barFill = barFill, count = cnt }
        barY = barY - barSp
    end

    curY = curY - splitH - 8

    local sessH = 32
    local sessFrame = CreateFrame("Frame", nil, F)
    sessFrame:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    sessFrame:SetPoint("TOPRIGHT", F, "TOPRIGHT", -10, curY)
    sessFrame:SetHeight(sessH)

    local sessBg = sessFrame:CreateTexture(nil, "BACKGROUND")
    sessBg:SetAllPoints()
    sessBg:SetColorTexture(unpack(C.bgBlock))

    self.fnSessionLbl = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnSessionLbl:SetPoint("LEFT", sessFrame, "LEFT", pad, 0)
    self.fnSessionLbl:SetText(_hex("textDim") .. "Session|r")

    self.fnSessionVal = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnSessionVal:SetPoint("LEFT", self.fnSessionLbl, "RIGHT", 8, 0)
    self.fnSessionVal:SetText("--")
    self.fnSessionVal:SetTextColor(unpack(C.textNorm))

    self.fnTodayLbl = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnTodayLbl:SetPoint("LEFT", self.fnSessionVal, "RIGHT", 40, 0)
    self.fnTodayLbl:SetText(_hex("textDim") .. "Today|r")

    self.fnTodayVal = sessFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.fnTodayVal:SetPoint("LEFT", self.fnTodayLbl, "RIGHT", 8, 0)
    self.fnTodayVal:SetText("--")
    self.fnTodayVal:SetTextColor(unpack(C.textNorm))

    curY = curY - sessH - 8

    self.footer = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.footer:SetPoint("BOTTOM", F, "BOTTOM", 0, 8)
    self.footer:SetText(" MADE with |cffff6666Love|r by |cff88ccffAYRO|r ")

    self.frame:Hide()

    if not FrostSeekDB.PlayTime then FrostSeekDB.PlayTime = {} end
    if not FrostSeekDB.PlayTime.todayStartTimestamp then FrostSeekDB.PlayTime.todayStartTimestamp = time() end
    if not FrostSeekDB.PlayTime.lastDay then FrostSeekDB.PlayTime.lastDay = tonumber(date("%j")) end

    local ilvlFrame = CreateFrame("Frame")
    ilvlFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    ilvlFrame:SetScript("OnEvent", function() Dashboard:CalculateItemLevel() end)
    Dashboard:CalculateItemLevel()

    self.updateTimer = C_Timer.NewTicker(1, function() self:UpdateAll() end)

    if not FrostSeekDB.RecentActivities then FrostSeekDB.RecentActivities = {} end
end

function Dashboard:CalculateItemLevel()
    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel then sum = sum + itemLevel; count = count + 1 end
            end
        end
    end
    cachedIlvl = count > 0 and math.floor((sum / count) + 0.5) or 0
    if FrostSeek and FrostSeek.CalculateGearScore then
        cachedGS = FrostSeek.CalculateGearScore("player") or 0
    end
end

function Dashboard:Show()
    if not self.frame or not self.kpiIlvlNum then return end
    self:UpdateAll()
    self.frame:Show()
end

function Dashboard:Hide()
    if self.frame then self.frame:Hide() end
end

function Dashboard:UpdateAll()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    local netOnline = 0
    local netStats = { total = 0, friends = 0, tanks = 0, healers = 0, dps = 0 }
    if FrostSeek.Presence then
        if FrostSeek.Presence.GetOnlineCount then
            netOnline = FrostSeek.Presence:GetOnlineCount()
        end
        if FrostSeek.Presence.GetStats then
            netStats = FrostSeek.Presence:GetStats()
        end
    end

    local tags = {}
    if cachedIlvl > 0 then
        table.insert(tags, _hex("success") .. cachedIlvl .. "|r " .. _hex("textDim") .. "ilvl|r")
    end
    if cachedGS > 0 then
        local gsHex = string.format("%02X%02X%02X", _tc("accent")[1] * 255, _tc("accent")[2] * 255, _tc("accent")[3] * 255)
        if FrostSeek and FrostSeek.GetGearScoreColor then
            local r, g, b = FrostSeek.GetGearScoreColor(cachedGS)
            if r and g and b then gsHex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255) end
        end
        table.insert(tags, "|cFF" .. gsHex .. cachedGS .. "|r " .. _hex("textDim") .. "gs|r")
    end
    local role = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.myRole or "No Role"
    if role ~= "" and role ~= "No Role" then
        local roleColors = {Tank="4488FF",Healer="33CC55",DPS="FF5555",BC="FFAA00"}
        local rc = roleColors[role] or string.format("%02X%02X%02X", _tc("accent")[1] * 255, _tc("accent")[2] * 255, _tc("accent")[3] * 255)
        table.insert(tags, "|cFF" .. rc .. role .. "|r")
    else
        table.insert(tags, "|cFF888888No Role|r")
    end
    if netOnline > 1 then
        table.insert(tags, "|cff88ccff" .. tostring(netOnline) .. "|r " .. _hex("textDim") .. "frostnet|r")
    end
    local lfgOn = FrostSeekDB and FrostSeekDB.LFG and not FrostSeekDB.LFG.disableLFG
    table.insert(tags, lfgOn and _hex("success") .. "ON|r " .. _hex("textDim") .. "LFG|r" or _hex("danger") .. "OFF|r " .. _hex("textDim") .. "LFG|r")
    if self.heroTags then
        self.heroTags:SetText(table.concat(tags, "  "))
    end

    self.kpiIlvlNum:SetText(tostring(cachedIlvl))
    self.kpiIlvlNum:SetTextColor(unpack(cachedIlvl > 0 and C.success or C.textDim))

    if cachedGS > 0 then
        self.kpiGsNum:SetText(tostring(cachedGS))
        if FrostSeek and FrostSeek.GetGearScoreColor then
            local r, g, b = FrostSeek.GetGearScoreColor(cachedGS)
            self.kpiGsNum:SetTextColor(r or 0.53, g or 0.8, b or 1.0)
        else
            self.kpiGsNum:SetTextColor(unpack(C.accent))
        end
    else
        self.kpiGsNum:SetText("0")
        self.kpiGsNum:SetTextColor(unpack(C.textDim))
    end

    local money = GetMoney()
    local g = math.floor(money / 10000)
    local s = math.floor((money % 10000) / 100)
    local c = money % 100
    if g > 0 then
        self.kpiGoldNum:SetText(string.format("|cFFFFD700%d|r" .. _hex("textDim") .. "g|r |cFFC0C0C0%d|r" .. _hex("textDim") .. "s|r", g, s))
    elseif s > 0 then
        self.kpiGoldNum:SetText(string.format("|cFFC0C0C0%d|r" .. _hex("textDim") .. "s|r |cFFCD853F%d|r" .. _hex("textDim") .. "c|r", s, c))
    else
        self.kpiGoldNum:SetText(string.format("|cFFCD853F%d|r" .. _hex("textDim") .. "c|r", c))
    end

    if self.fnBigNum then
        self.fnBigNum:SetText(tostring(netOnline))
        self.fnBigNum:SetTextColor(unpack(netOnline > 1 and C.accent or C.textDim))
    end

    if self.fnConnDot and self.fnConnText then
        local Network = FrostSeek.Network
        if Network then
            if not Network.isConnected then
                Network:RefreshChannel()
            end
            if Network.isConnected then
                self.fnConnDot:SetColorTexture(unpack(C.success))
                if Network.isBLFGConnected then
                    self.fnConnText:SetText("|cff44ff44FSK + BLFG|r")
                else
                    self.fnConnText:SetText("|cff44ff44FSK Connected|r")
                end
            else
                local hasChannel = false
                local numChannels = 0
                if GetNumDisplayChannels then
                    local ok, count = pcall(function() return GetNumDisplayChannels() end)
                    if ok then numChannels = count or 0 end
                end
                for i = 1, numChannels do
                    local name
                    if GetChannelDisplayInfo then
                        local ok, n = pcall(function() return select(1, GetChannelDisplayInfo(i)) end)
                        if ok then name = n end
                    end
                    if name and string.lower(tostring(name)) == "fsk" then
                        hasChannel = true
                        break
                    end
                end
                if hasChannel then
                    Network:RefreshChannel()
                    self.fnConnDot:SetColorTexture(unpack(C.warning))
                    self.fnConnText:SetText("|cffffff00FSK Connecting...|r")
                else
                    self.fnConnDot:SetColorTexture(unpack(C.danger))
                    self.fnConnText:SetText("|cffff5555FSK Offline|r")
                end
            end
        else
            self.fnConnDot:SetColorTexture(unpack(C.danger))
            self.fnConnText:SetText("|cffff5555FSK Offline|r")
        end
    end

    if self.fnGroupsVal then
        local listingCount = 0
        if FrostSeek.Listings and FrostSeek.Listings.listings then
            for _ in pairs(FrostSeek.Listings.listings) do listingCount = listingCount + 1 end
        end
        self.fnGroupsVal:SetText(tostring(listingCount))
        self.fnGroupsVal:SetTextColor(unpack(listingCount > 0 and C.accent or C.textDim))
    end

    if self.fnFriendsVal then
        local onlineFriends = 0
        if FrostSeekCompat and FrostSeekCompat.GetOnlineFriendsCount then
            onlineFriends = FrostSeekCompat.GetOnlineFriendsCount()
        else
            local numFriends = 0
            if C_FriendList and C_FriendList.GetNumFriends then
                local ok, count = pcall(function() return C_FriendList.GetNumFriends() end)
                if ok then numFriends = count or 0 end
            end
            if numFriends == 0 and GetNumFriends then
                local ok, count = pcall(function() return GetNumFriends() end)
                if ok then numFriends = count or 0 end
            end
            for i = 1, numFriends do
                local connected = false
                if C_FriendList and C_FriendList.GetFriendInfoByIndex then
                    local ok, info = pcall(function() return C_FriendList.GetFriendInfoByIndex(i) end)
                    if ok and info then connected = info.connected or false end
                elseif GetFriendInfo then
                    local ok, _, _, _, _, conn = pcall(function() return GetFriendInfo(i) end)
                    if ok then connected = conn or false end
                end
                if connected then onlineFriends = onlineFriends + 1 end
            end
        end
        self.fnFriendsVal:SetText(tostring(onlineFriends))
        self.fnFriendsVal:SetTextColor(unpack(onlineFriends > 0 and C.success or C.textDim))
    end

    local maxRole = math.max(netStats.tanks, netStats.healers, netStats.dps, netStats.supports or 0, 1)
    local barW = 110
    for roleName, barData in pairs(self.fnRoleBars) do
        local count = 0
        if roleName == "Tank" then count = netStats.tanks
        elseif roleName == "Healer" then count = netStats.healers
        elseif roleName == "DPS" then count = netStats.dps
        elseif roleName == "Support" then count = netStats.supports or 0
        end
        barData.count:SetText(tostring(count))
        local fillW = count > 0 and math.max(4, (count / maxRole) * barW) or 0
        barData.barFill:SetWidth(fillW)
        if count > 0 then
            local rc = ROLE_COLORS[roleName] or {0.5, 0.5, 0.5}
            barData.barFill:SetColorTexture(rc[1], rc[2], rc[3], 0.65)
            barData.count:SetTextColor(unpack(C.textNorm))
        else
            barData.count:SetTextColor(unpack(C.textDim))
        end
    end

    if self.fnSessionVal then
        local sessSec = GetTime() - sessionStartTime
        self.fnSessionVal:SetText(string.format("%02d:%02d:%02d", math.floor(sessSec/3600), math.floor((sessSec%3600)/60), math.floor(sessSec%60)))
    end

    if self.fnTodayVal then
        local currentDay = tonumber(date("%j"))
        if FrostSeekDB.PlayTime.lastDay ~= currentDay then
            FrostSeekDB.PlayTime.todayStartTimestamp = time()
            FrostSeekDB.PlayTime.lastDay = currentDay
        end
        local todaySec = time() - FrostSeekDB.PlayTime.todayStartTimestamp
        self.fnTodayVal:SetText(string.format("%02d:%02d:%02d", math.floor(todaySec/3600), math.floor((todaySec%3600)/60), math.floor(todaySec%60)))
    end

    local categoryCounts = {}
    for _, cat in ipairs({"DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE", "MISC"}) do
        categoryCounts[cat] = 0
    end
    local searches = {}
    if FrostSeek and FrostSeek.Modules and FrostSeek.Modules.lfg then
        searches = FrostSeek.Modules.lfg._activeSearches or {}
    end
    local total = 0
    for _, search in ipairs(searches) do
        local cat = search.category and string.upper(search.category) or nil
        if cat and categoryCounts[cat] ~= nil then
            categoryCounts[cat] = categoryCounts[cat] + 1
        end
        total = total + 1
    end
    local maxCount = 1
    for _, count in pairs(categoryCounts) do
        if count > maxCount then maxCount = count end
    end
    self.lfgTotalNum:SetText(tostring(total))
    self.lfgTotalNum:SetTextColor(unpack(total > 0 and C.accent or C.textDim))
    for cat, barData in pairs(self.categoryBars) do
        local count = categoryCounts[cat] or 0
        barData.count:SetText(tostring(count))
        local fillW = count > 0 and math.max(6, (count / maxCount) * 120) or 0
        barData.barFill:SetWidth(fillW)
        if count > 0 then
            local cc = GetCatColor(cat)
            barData.barFill:SetColorTexture(cc[1], cc[2], cc[3], 0.65)
            barData.count:SetTextColor(unpack(C.textNorm))
        else
            barData.count:SetTextColor(unpack(C.textDim))
        end
    end
end

function Dashboard:ApplyTheme()
    if not self.frame then return end
    self:UpdateAll()
    if self.heroName then
        local _, rawClassFile = UnitClass("player")
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[rawClassFile]
        local nameHex = cc and string.format("FF%02X%02X%02X", cc.r * 255, cc.g * 255, cc.b * 255) or string.format("FF%02X%02X%02X", _tc("accent")[1] * 255, _tc("accent")[2] * 255, _tc("accent")[3] * 255)
        self.heroName:SetText("|c" .. nameHex .. (UnitName("player") or "Unknown") .. "|r")
        if self.heroClassIcon then
            local iconClassFile = rawClassFile
            if Shared and Shared.GetPlayerClassFile then
                iconClassFile = Shared.GetPlayerClassFile()
            end
            self.heroClassIcon:SetTexture(GetClassIcon(iconClassFile))
        end
    end
    if self.footer then
        self.footer:SetText(" MADE with |cffff6666LOVE|r by |cff88ccffAYRO|r  ")
    end
    local FS = _G.FrostSeek
    if FS and FS.MainFrame then
        FS.MainFrame:SetBackdropColor(unpack(_tc("bgMain")))
        FS.MainFrame:SetBackdropBorderColor(unpack(_tc("border")))
    end
end

local FROSTSEEK_SIG = "FSK-" .. string.char(70,82,79,83,84) .. "-" .. "0x4FSK7"

local function RegisterDashboardModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterDashboardModule)
        return
    end
    if not _G.FrostSeek._v or not _G.FrostSeek._v.c(_tk) then return end
    sessionStartTime = GetTime()
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("dashboard", Dashboard)
    end
    if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
        _G.FrostSeekTheme.RegisterModule("dashboard")
    end
end

RegisterDashboardModule()
