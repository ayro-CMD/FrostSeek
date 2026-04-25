local FrostSeek = _G.FrostSeek

local Dashboard = {}

local cachedIlvl = 0
local sessionStartTime = GetTime()

function Dashboard:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    
    -- ==================================================
    -- HEADER INFORMAZIONI
    -- ==================================================
    local infoFrame = CreateFrame("Frame", nil, self.frame)
    infoFrame:SetSize(760, 60)
    infoFrame:SetPoint("TOP", self.frame, "TOP", 0, -10)
    
    local realmName = GetRealmName() or "Unknown"
    local faction = UnitFactionGroup("player") or "Unknown"
    local factionColor = faction == "Horde" and "FFCC0000" or "FF00AAFF"
    
    local serverText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    serverText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 20, -15)
    serverText:SetText(string.format("|cFF88CCFF%s|r |c%s%s|r", realmName, factionColor, faction))
    
    local versionText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOPRIGHT", infoFrame, "TOPRIGHT", -20, -15)
    versionText:SetText("|cFF88CCFF|r")
    
    local sep = self.frame:CreateTexture(nil, "BACKGROUND")
    sep:SetPoint("TOP", infoFrame, "BOTTOM", 0, -5)
    sep:SetSize(720, 1)
    sep:SetColorTexture(0.3, 0.3, 0.35, 0.5)
    
    -- ==================================================
    -- PANNELLO PRINCIPALE 
    -- ==================================================
    local mainFrame = CreateFrame("Frame", nil, self.frame)
    mainFrame:SetSize(760, 380)
    mainFrame:SetPoint("TOP", infoFrame, "BOTTOM", 0, -20)
    
    -- COLONNA 1: Server Info
    self.col1 = CreateFrame("Frame", nil, mainFrame)
    self.col1:SetSize(240, 380)
    self.col1:SetPoint("LEFT", mainFrame, "LEFT", 10, 0)
    
    local col1Bg = self.col1:CreateTexture(nil, "BACKGROUND")
    col1Bg:SetAllPoints()
    col1Bg:SetColorTexture(0.05, 0.05, 0.08, 0.5)
    
    local col1Title = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    col1Title:SetPoint("TOP", self.col1, "TOP", 0, -10)
    col1Title:SetText("SERVER INFO")
    col1Title:SetTextColor(0.6, 0.8, 1)
    
    local serverTimeLabel = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    serverTimeLabel:SetPoint("TOPLEFT", self.col1, "TOPLEFT", 20, -45)
    serverTimeLabel:SetText("Server time:")
    serverTimeLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.serverTime = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.serverTime:SetPoint("LEFT", serverTimeLabel, "RIGHT", 10, 0)
    self.serverTime:SetText("00:00:00")
    self.serverTime:SetTextColor(0.6, 0.8, 1)
    
    local localTimeLabel = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    localTimeLabel:SetPoint("TOPLEFT", self.col1, "TOPLEFT", 20, -70)
    localTimeLabel:SetText("Local time:")
    localTimeLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.localTime = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.localTime:SetPoint("LEFT", localTimeLabel, "RIGHT", 10, 0)
    self.localTime:SetText("00:00:00")
    self.localTime:SetTextColor(1, 1, 1)
    
    local friendsLabel = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    friendsLabel:SetPoint("TOPLEFT", self.col1, "TOPLEFT", 20, -100)
    friendsLabel:SetText("Friends online:")
    friendsLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.friendsValue = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.friendsValue:SetPoint("LEFT", friendsLabel, "RIGHT", 10, 0)
    self.friendsValue:SetText("0")
    self.friendsValue:SetTextColor(0, 1, 0)
    
    local lfgActivityLabel = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lfgActivityLabel:SetPoint("TOPLEFT", self.col1, "TOPLEFT", 20, -130)
    lfgActivityLabel:SetText("LFG Activity:")
    lfgActivityLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.lfgActivity = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.lfgActivity:SetPoint("LEFT", lfgActivityLabel, "RIGHT", 10, 0)
    self.lfgActivity:SetText("0")
    self.lfgActivity:SetTextColor(1, 1, 1)
    
    local guildOnlineLabel = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    guildOnlineLabel:SetPoint("TOPLEFT", self.col1, "TOPLEFT", 20, -155)
    guildOnlineLabel:SetText("Guild online:")
    guildOnlineLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.guildOnline = self.col1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.guildOnline:SetPoint("LEFT", guildOnlineLabel, "RIGHT", 10, 0)
    self.guildOnline:SetText("0/0")
    self.guildOnline:SetTextColor(1, 1, 1)
    
    -- COLONNA 2: RECENT
    self.col2 = CreateFrame("Frame", nil, mainFrame)
    self.col2:SetSize(240, 380)
    self.col2:SetPoint("LEFT", self.col1, "RIGHT", 10, 0)
    
    local col2Bg = self.col2:CreateTexture(nil, "BACKGROUND")
    col2Bg:SetAllPoints()
    col2Bg:SetColorTexture(0.05, 0.05, 0.08, 0.5)
    
    local col2Title = self.col2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    col2Title:SetPoint("TOP", self.col2, "TOP", 0, -10)
    col2Title:SetText("RECENT ACTIVITY")
    col2Title:SetTextColor(0.6, 0.8, 1)
    
    self.recentActivities = {}
    local recentYOffset = -40
    for i = 1, 8 do
        local activityLine = self.col2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        activityLine:SetPoint("TOPLEFT", self.col2, "TOPLEFT", 15, recentYOffset)
        activityLine:SetText("")
        activityLine:SetTextColor(0.8, 0.8, 0.8)
        self.recentActivities[i] = activityLine
        recentYOffset = recentYOffset - 20
    end
    
    -- COLONNA 3: Your Stats
    self.col3 = CreateFrame("Frame", nil, mainFrame)
    self.col3:SetSize(240, 380)
    self.col3:SetPoint("LEFT", self.col2, "RIGHT", 10, 0)
    
    local col3Bg = self.col3:CreateTexture(nil, "BACKGROUND")
    col3Bg:SetAllPoints()
    col3Bg:SetColorTexture(0.05, 0.05, 0.08, 0.5)
    
    local col3Title = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    col3Title:SetPoint("TOP", self.col3, "TOP", 0, -10)
    col3Title:SetText("YOUR STATS")
    col3Title:SetTextColor(0.6, 0.8, 1)
    
    self.playerName = UnitName("player")
    self.playerClass = UnitClass("player")
    
    local playerLabel = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", self.col3, "TOPLEFT", 20, -40)
    playerLabel:SetText(string.format("%s - %s", self.playerName, self.playerClass))
    playerLabel:SetTextColor(1, 1, 1)
    
    local ilvlLabel = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ilvlLabel:SetPoint("TOPLEFT", self.col3, "TOPLEFT", 20, -70)
    ilvlLabel:SetText("Item Level:")
    ilvlLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.ilvlValue = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.ilvlValue:SetPoint("LEFT", ilvlLabel, "RIGHT", 10, 0)
    self.ilvlValue:SetText("0")
    self.ilvlValue:SetTextColor(0, 1, 0)
    
    local goldLabel = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    goldLabel:SetPoint("TOPLEFT", self.col3, "TOPLEFT", 20, -95)
    goldLabel:SetText("Gold:")
    goldLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.goldValue = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldValue:SetPoint("LEFT", goldLabel, "RIGHT", 10, 0)
    self.goldValue:SetText("0g")
    self.goldValue:SetTextColor(1, 1, 0)
    
    local sessionLabel = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sessionLabel:SetPoint("TOPLEFT", self.col3, "TOPLEFT", 20, -130)
    sessionLabel:SetText("This session:")
    sessionLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.sessionValue = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.sessionValue:SetPoint("LEFT", sessionLabel, "RIGHT", 10, 0)
    self.sessionValue:SetText("00:00:00")
    self.sessionValue:SetTextColor(0.6, 0.8, 1)
    
    local todayLabel = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    todayLabel:SetPoint("TOPLEFT", self.col3, "TOPLEFT", 20, -155)
    todayLabel:SetText("Today:")
    todayLabel:SetTextColor(0.8, 0.8, 0.8)
    
    self.todayValue = self.col3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.todayValue:SetPoint("LEFT", todayLabel, "RIGHT", 10, 0)
    self.todayValue:SetText("00:00:00")
    self.todayValue:SetTextColor(1, 1, 1)
    
    -- ===== FOOTER =====
    self.footer = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.footer:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 10)
    self.footer:SetText("|cFFFFFF00FrostSeek | Made with Love by Ayro|r")
    self.footer:SetTextColor(0.8, 0.8, 0.8)
    
    self.frame:Hide()
    
    if not FrostSeekDB.PlayTime then
        FrostSeekDB.PlayTime = {}
    end
    
    if not FrostSeekDB.PlayTime.todayStartTimestamp then
        FrostSeekDB.PlayTime.todayStartTimestamp = time()
    end
    
    if not FrostSeekDB.PlayTime.lastDay then
        FrostSeekDB.PlayTime.lastDay = tonumber(date("%j"))
    end
    
    -- Listener per l'iLvl
    local ilvlFrame = CreateFrame("Frame")
    ilvlFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    ilvlFrame:SetScript("OnEvent", function()
        Dashboard:CalculateItemLevel()
    end)
    Dashboard:CalculateItemLevel()
    
    -- Timer
    self.updateTimer = C_Timer.NewTicker(1, function()
        self:UpdateAll()
    end)
    
    if not FrostSeekDB.RecentActivities then
        FrostSeekDB.RecentActivities = {}
    end
end

-- Funzione iLvl
function Dashboard:CalculateItemLevel()
    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel then
                    sum = sum + itemLevel
                    count = count + 1
                end
            end
        end
    end
    cachedIlvl = count > 0 and math.floor((sum / count) + 0.5) or 0
end

function Dashboard:Show()
    self:UpdateAll()
    self.frame:Show()
end

function Dashboard:Hide()
    self.frame:Hide()
end

function Dashboard:UpdateAll()
    self:UpdateServerInfo()
    self:UpdatePlayerStats()
    self:UpdateRecentActivities()
end

function Dashboard:UpdateServerInfo()
    
    self.serverTime:SetText(date("!%H:%M:%S"))
    
    -- Local time
    self.localTime:SetText(date("%H:%M:%S"))
    
    -- Friends online
    local onlineFriends = 0
    for i = 1, GetNumFriends() do
        local _, _, _, _, connected = GetFriendInfo(i)
        if connected then
            onlineFriends = onlineFriends + 1
        end
    end
    
    self.friendsValue:SetText(onlineFriends)
    
    if onlineFriends > 0 then
        self.friendsValue:SetTextColor(0, 1, 0)
    else
        self.friendsValue:SetTextColor(1, 0.5, 0.5)
    end
    
    
    local lfgCount = 0
    if FrostSeek.Modules.lfg and FrostSeek.Modules.lfg.GetActiveRecruiterCount then
        lfgCount = FrostSeek.Modules.lfg:GetActiveRecruiterCount() or 0
    end
    self.lfgActivity:SetText(lfgCount)
    if lfgCount > 0 then
        self.lfgActivity:SetTextColor(0, 1, 0)
    else
        self.lfgActivity:SetTextColor(1, 1, 1)
    end
    
    -- Guild online
    local guildName = GetGuildInfo("player")
    if guildName then
        local online = 0
        local total = GetNumGuildMembers() or 0
        if total > 0 then
            for i = 1, total do
                local _, _, _, _, _, _, _, _, onlinex = GetGuildRosterInfo(i)
                if onlinex then
                    online = online + 1
                end
            end
        end
        self.guildOnline:SetText(string.format("%d/%d", online, total))
        if online > 0 then
            self.guildOnline:SetTextColor(0, 1, 0)
        else
            self.guildOnline:SetTextColor(1, 1, 1)
        end
    else
        self.guildOnline:SetText("No guild")
        self.guildOnline:SetTextColor(0.7, 0.7, 0.7)
    end
end

function Dashboard:UpdatePlayerStats()
    
    self.ilvlValue:SetText(cachedIlvl)
    
    -- Gold
    local gold = GetMoney()
    local goldg = math.floor(gold / 10000)
    local golds = math.floor((gold % 10000) / 100)
    local goldc = gold % 100
    
    if goldg > 0 then
        self.goldValue:SetText(string.format("%dg %ds %dc", goldg, golds, goldc))
    elseif golds > 0 then
        self.goldValue:SetText(string.format("%ds %dc", golds, goldc))
    else
        self.goldValue:SetText(string.format("%dc", goldc))
    end
    
    -- Session time
    local sessionDuration = GetTime() - sessionStartTime
    local hours = math.floor(sessionDuration / 3600)
    local minutes = math.floor((sessionDuration % 3600) / 60)
    local seconds = math.floor(sessionDuration % 60)
    self.sessionValue:SetText(string.format("%02d:%02d:%02d", hours, minutes, seconds))
    
    -- Play Time Today
    local currentDay = tonumber(date("%j"))
    
    if FrostSeekDB.PlayTime.lastDay ~= currentDay then
        FrostSeekDB.PlayTime.todayStartTimestamp = time()
        FrostSeekDB.PlayTime.lastDay = currentDay
    end

    
    local todaySeconds = time() - FrostSeekDB.PlayTime.todayStartTimestamp
    local todayHours = math.floor(todaySeconds / 3600)
    local todayMinutes = math.floor((todaySeconds % 3600) / 60)
    local todaySecondsRemain = math.floor(todaySeconds % 60)
    
    self.todayValue:SetText(string.format("%02d:%02d:%02d", todayHours, todayMinutes, todaySecondsRemain))
end

function Dashboard:UpdateRecentActivities()
    
    local activities = {}
    local searches = {}
    if FrostSeek and FrostSeek.Modules and FrostSeek.Modules.lfg then
    searches = FrostSeek.Modules.lfg._activeSearches or {}
    end
    
    for i, search in ipairs(searches) do
        if #activities < 8 then
            local timeAgo = math.floor(GetTime() - (search.lastUpdate or 0))
            local timeStr = timeAgo < 60 and string.format("%ds", timeAgo) or string.format("%dm", math.floor(timeAgo/60))
            table.insert(activities, string.format("|cFF88CCFF[%s]|r %s (%s)", search.category or "?", search.player or "?", timeStr))
        end
    end
    
    if FrostSeekDB.LFM and FrostSeekDB.LFM.lastMessages then
        for i, msg in ipairs(FrostSeekDB.LFM.lastMessages) do
            if #activities < 8 then
                local timeStr = msg.timestamp and date("%H:%M", msg.timestamp) or "recent"
                table.insert(activities, string.format("|cFF00FF00[LFM]|r %s (%s)", msg.channel or "?", timeStr))
            end
        end
    end
    
    if #activities == 0 then
        for i = 1, 8 do
            if self.recentActivities[i] then
                self.recentActivities[i]:SetText("")
            end
        end
        if self.recentActivities[1] then
            self.recentActivities[1]:SetText("No recent activity")
            self.recentActivities[1]:SetTextColor(0.5, 0.5, 0.5)
        end
        return
    end
    
    for i = 1, 8 do
        if self.recentActivities[i] then
            if activities[i] then
                self.recentActivities[i]:SetText(activities[i])
                self.recentActivities[i]:SetTextColor(0.9, 0.9, 0.9)
            else
                self.recentActivities[i]:SetText("")
            end
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
