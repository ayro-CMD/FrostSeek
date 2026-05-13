local FrostSeek = _G.FrostSeek

local Dashboard = {}

local cachedIlvl = 0
local cachedGS = 0
local sessionStartTime = GetTime()

-- ==================== COLORS ====================
local C = {
    primary   = {0.2, 0.6, 0.9},
    accent    = {0.53, 0.8, 1.0},
    success   = {0.2, 0.9, 0.4},
    warning   = {1.0, 0.75, 0.2},
    danger    = {0.95, 0.3, 0.3},
    gold      = {1.0, 0.85, 0.0},
    textBig   = {1.0, 1.0, 1.0},
    textNorm  = {0.85, 0.85, 0.88},
    textDim   = {0.45, 0.48, 0.55},
    textLabel = {0.38, 0.42, 0.5},
    bgSection = {0.06, 0.07, 0.10, 0.6},
    bgBlock   = {0.08, 0.09, 0.13, 0.5},
    line      = {0.18, 0.22, 0.30, 0.5},
    lineAcc   = {0.2, 0.5, 0.8, 0.35},
    dungeon   = {0.2, 0.75, 0.2},
    raid      = {0.85, 0.45, 0.15},
    worldboss = {0.85, 0.2, 0.2},
    pvp       = {0.85, 0.2, 0.2},
    manastorm = {0.6, 0.3, 0.85},
    keystone  = {0.9, 0.4, 0.65},
}

local function GetCatColor(cat)
    if not cat then return C.textNorm end
    local k = string.upper(cat)
    if k == "DUNGEON"    then return C.dungeon
    elseif k == "RAID"   then return C.raid
    elseif k == "WORLD_BOSS" then return C.worldboss
    elseif k == "PVP"    then return C.pvp
    elseif k == "MANASTORM" then return C.manastorm
    elseif k == "KEYSTONE"  then return C.keystone end
    return C.textNorm
end

-- ==================== INIT ====================
function Dashboard:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local F = self.frame
    local pad = 18
    local curY = -10

    -- ==================================================
    -- HERO BAR
    -- ==================================================
    local heroH = 44
    local hero = CreateFrame("Frame", nil, F)
    hero:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    hero:SetPoint("TOPRIGHT", F, "TOPRIGHT", -10, curY)
    hero:SetHeight(heroH)

    local heroBg = hero:CreateTexture(nil, "BACKGROUND")
    heroBg:SetAllPoints()
    heroBg:SetColorTexture(unpack(C.bgSection))

    -- Player name
    local playerName, playerRealm = UnitName("player")
    if not playerRealm or playerRealm == "" then playerRealm = GetRealmName() or "" end
    local _, classFile = UnitClass("player")
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    local nameHex = cc and string.format("FF%02X%02X%02X", cc.r * 255, cc.g * 255, cc.b * 255) or "FF88CCFF"

    self.heroName = hero:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.heroName:SetPoint("LEFT", hero, "LEFT", pad, 3)
    self.heroName:SetText("|c" .. nameHex .. (playerName or "Unknown") .. "|r")

    -- Realm + Faction
    local faction = UnitFactionGroup("player") or ""
    local fCol = faction == "Horde" and "|cFFFF4444" or "|cFF4488FF"
    local ascLbl = ""
    if FrostSeekCompat and FrostSeekCompat.IsAscension and FrostSeekCompat.IsAscension() then
        ascLbl = "  |cFF666666|  |cFFAA88FF" .. (FrostSeekCompat.GetServerTypeLabel and FrostSeekCompat.GetServerTypeLabel() or "Ascension") .. "|r"
    end
    self.heroRight = hero:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.heroRight:SetPoint("RIGHT", hero, "RIGHT", -pad, 3)
    self.heroRight:SetText("|cFF555555" .. playerRealm .. "|r  " .. fCol .. faction .. "|r" .. ascLbl)

    -- Tags
    self.heroTags = hero:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.heroTags:SetPoint("LEFT", hero, "LEFT", pad, -13)
    self.heroTags:SetText("")

    -- Bottom accent
    local heroLine = hero:CreateTexture(nil, "ARTWORK")
    heroLine:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    heroLine:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 0, 0)
    heroLine:SetHeight(1)
    heroLine:SetColorTexture(unpack(C.lineAcc))

    curY = curY - heroH - 8

    -- ==================================================
    -- KPI STRIP — 3 big numbers
    -- ==================================================
    local kpiH = 68
    local kpiGap = 4
    local kpiW = (770 - kpiGap * 2) / 3

    -- Item Level
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
    self.kpiIlvlLabel:SetText("ITEM LEVEL")
    self.kpiIlvlLabel:SetTextColor(unpack(C.textLabel))

    -- GearScore
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
    self.kpiGsLabel:SetText("GEARSCORE")
    self.kpiGsLabel:SetTextColor(unpack(C.textLabel))

    -- Gold
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
    self.kpiGoldLabel:SetText("GOLD")
    self.kpiGoldLabel:SetTextColor(unpack(C.textLabel))

    curY = curY - kpiH - 10

    -- Divider
    local div1 = F:CreateTexture(nil, "ARTWORK")
    div1:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    div1:SetPoint("TOPRIGHT", F, "TOPRIGHT", -10, curY)
    div1:SetHeight(1)
    div1:SetColorTexture(unpack(C.line))
    curY = curY - 10

    -- ==================================================
    -- SPLIT: Server (left) + LFG Activity (right)
    -- ==================================================
    local splitGap = 8
    local splitH = 235
    local halfW = (770 - splitGap) / 2

    -- LEFT: Server
    local sv = CreateFrame("Frame", nil, F)
    sv:SetPoint("TOPLEFT", F, "TOPLEFT", 10, curY)
    sv:SetSize(halfW, splitH)

    local svBg = sv:CreateTexture(nil, "BACKGROUND")
    svBg:SetAllPoints()
    svBg:SetColorTexture(unpack(C.bgBlock))

    local svTitle = sv:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    svTitle:SetPoint("TOPLEFT", sv, "TOPLEFT", pad, -10)
    svTitle:SetText("|cFF88CCFFSERVER|r")

    local svLine = sv:CreateTexture(nil, "ARTWORK")
    svLine:SetPoint("TOPLEFT", sv, "TOPLEFT", pad, -26)
    svLine:SetPoint("TOPRIGHT", sv, "TOPRIGHT", -pad, -26)
    svLine:SetHeight(1)
    svLine:SetColorTexture(unpack(C.line))

    local ry = -40
    local rh = 28

    -- Helper to make a label-left / value-right row
    local function MakeRow(parent, label, y)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", pad, y)
        lbl:SetText(label)
        lbl:SetTextColor(unpack(C.textLabel))
        local val = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -pad, y)
        val:SetText("--")
        val:SetTextColor(unpack(C.textNorm))
        return lbl, val
    end

    _, self.svTimeVal   = MakeRow(sv, "Server Time",    ry); ry = ry - rh
    _, self.svLocalVal  = MakeRow(sv, "Local Time",     ry); ry = ry - rh

    -- Friends
    _, self.svFriendsVal = MakeRow(sv, "Friends Online", ry); ry = ry - rh

    -- Guild
    _, self.svGuildVal = MakeRow(sv, "Guild Online", ry); ry = ry - rh

    _, self.svSessionVal = MakeRow(sv, "Session", ry); ry = ry - rh
    _, self.svTodayVal   = MakeRow(sv, "Today",   ry)

    -- RIGHT: LFG Activity
    local lp = CreateFrame("Frame", nil, F)
    lp:SetPoint("TOPLEFT", sv, "TOPRIGHT", splitGap, 0)
    lp:SetSize(halfW, splitH)

    local lpBg = lp:CreateTexture(nil, "BACKGROUND")
    lpBg:SetAllPoints()
    lpBg:SetColorTexture(unpack(C.bgBlock))

    local lpTitle = lp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lpTitle:SetPoint("TOPLEFT", lp, "TOPLEFT", pad, -10)
    lpTitle:SetText("|cFF88CCFFLFG ACTIVITY|r")

    local lpLine = lp:CreateTexture(nil, "ARTWORK")
    lpLine:SetPoint("TOPLEFT", lp, "TOPLEFT", pad, -26)
    lpLine:SetPoint("TOPRIGHT", lp, "TOPRIGHT", -pad, -26)
    lpLine:SetHeight(1)
    lpLine:SetColorTexture(unpack(C.line))

    -- Big total number
    self.lfgTotalNum = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.lfgTotalNum:SetPoint("TOP", lp, "TOP", 0, -42)
    self.lfgTotalNum:SetText("0")
    self.lfgTotalNum:SetTextColor(unpack(C.accent))

    self.lfgTotalLabel = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.lfgTotalLabel:SetPoint("TOP", self.lfgTotalNum, "BOTTOM", 0, -2)
    self.lfgTotalLabel:SetText("ACTIVE RECRUITERS")
    self.lfgTotalLabel:SetTextColor(unpack(C.textLabel))

    -- Category bars
    self.categoryBars = {}
    local cats = {"DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE"}
    local barY = -100
    local barSp = 20

    for _, cat in ipairs(cats) do
        local col = GetCatColor(cat)

        local lbl = lp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", lp, "TOPLEFT", pad, barY)
        local shortN = {DUNGEON="Dungeon",RAID="Raid",WORLD_BOSS="World Boss",PVP="PvP",MANASTORM="Manastorm",KEYSTONE="Keystone"}
        lbl:SetText(shortN[cat] or cat)
        lbl:SetTextColor(unpack(C.textNorm))
        lbl:SetWidth(85)

        local barBg = lp:CreateTexture(nil, "BACKGROUND")
        barBg:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
        barBg:SetSize(120, 8)
        barBg:SetColorTexture(0.1, 0.1, 0.12, 0.8)

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

    -- ==================================================
    -- FOOTER
    -- ==================================================
    self.footer = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.footer:SetPoint("BOTTOM", F, "BOTTOM", 0, 8)
    self.footer:SetText("Made with Love by|cFF88CCFF AYRO|r ")

    self.frame:Hide()

    -- ==================================================
    -- DATA
    -- ==================================================
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

-- ==================== CALCULATE ITEM LEVEL ====================
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
    self:UpdateAll()
    self.frame:Show()
end

function Dashboard:Hide()
    self.frame:Hide()
end

-- ==================== UPDATE ALL ====================
function Dashboard:UpdateAll()
    -- Hero tags
    local tags = {}
    if cachedIlvl > 0 then
        table.insert(tags, "|cFF33CC55" .. cachedIlvl .. "|r |cFF444444ilvl|r")
    end
    if cachedGS > 0 then
        local gsHex = "88CCFF"
        if FrostSeek and FrostSeek.GetGearScoreColor then
            local r, g, b = FrostSeek.GetGearScoreColor(cachedGS)
            if r and g and b then gsHex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255) end
        end
        table.insert(tags, "|cFF" .. gsHex .. cachedGS .. "|r |cFF444444gs|r")
    end
    local role = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.myRole or ""
    if role ~= "" then
        local roleColors = {Tank="4488FF",Healer="33CC55",DPS="FF5555",BC="FFAA00"}
        local rc = roleColors[role] or "88CCFF"
        table.insert(tags, "|cFF" .. rc .. role .. "|r")
    end
    local lfgOn = FrostSeekDB and FrostSeekDB.LFG and not FrostSeekDB.LFG.disableLFG
    table.insert(tags, lfgOn and "|cFF33CC55ON|r |cFF444444LFG|r" or "|cFFFF4444OFF|r |cFF444444LFG|r")
    self.heroTags:SetText(table.concat(tags, "  "))

    -- KPI
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
        self.kpiGoldNum:SetText(string.format("|cFFFFD700%d|r|cFF555555g|r |cFFC0C0C0%d|r|cFF555555s|r", g, s))
    elseif s > 0 then
        self.kpiGoldNum:SetText(string.format("|cFFC0C0C0%d|r|cFF555555s|r |cFFCD853F%d|r|cFF555555c|r", s, c))
    else
        self.kpiGoldNum:SetText(string.format("|cFFCD853F%d|r|cFF555555c|r", c))
    end

    -- Server
    self.svTimeVal:SetText(date("!%H:%M:%S"))
    self.svLocalVal:SetText(date("%H:%M:%S"))

    local onlineFriends = 0
    for i = 1, GetNumFriends() do
        local _, _, _, _, connected = GetFriendInfo(i)
        if connected then onlineFriends = onlineFriends + 1 end
    end
    self.svFriendsVal:SetText(tostring(onlineFriends))
    self.svFriendsVal:SetTextColor(unpack(onlineFriends > 0 and C.success or C.textDim))

    local guildName = GetGuildInfo("player")
    if guildName then
        local on, tot = 0, GetNumGuildMembers() or 0
        if tot > 0 then
            for i = 1, tot do
                local _, _, _, _, _, _, _, _, isOn = GetGuildRosterInfo(i)
                if isOn then on = on + 1 end
            end
        end
        self.svGuildVal:SetText(string.format("%d / %d", on, tot))
        self.svGuildVal:SetTextColor(unpack(on > 0 and C.success or C.textNorm))
    else
        self.svGuildVal:SetText("No guild")
        self.svGuildVal:SetTextColor(unpack(C.textDim))
    end

    local sessSec = GetTime() - sessionStartTime
    self.svSessionVal:SetText(string.format("%02d:%02d:%02d", math.floor(sessSec/3600), math.floor((sessSec%3600)/60), math.floor(sessSec%60)))

    local currentDay = tonumber(date("%j"))
    if FrostSeekDB.PlayTime.lastDay ~= currentDay then
        FrostSeekDB.PlayTime.todayStartTimestamp = time()
        FrostSeekDB.PlayTime.lastDay = currentDay
    end
    local todaySec = time() - FrostSeekDB.PlayTime.todayStartTimestamp
    self.svTodayVal:SetText(string.format("%02d:%02d:%02d", math.floor(todaySec/3600), math.floor((todaySec%3600)/60), math.floor(todaySec%60)))

    -- LFG
    local categoryCounts = {}
    for _, cat in ipairs({"DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE"}) do
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

-- ==================== MODULE REGISTRATION ====================
local function RegisterDashboardModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterDashboardModule)
        return
    end
    sessionStartTime = GetTime()
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("dashboard", Dashboard)
    end
end

RegisterDashboardModule()
