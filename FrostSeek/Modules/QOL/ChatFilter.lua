-- ============================================================
-- AruiQOL - Chat Filter Module
-- ============================================================

local AruiQOL = _G.AruiQOL
local ChatFilter = {}

local FILTER_LOG_LIMIT = 20
local DEDUPLICATE_INTERVAL = 0.5
local MAX_SPAM_MESSAGES_PER_PLAYER = 5
local SPAM_WINDOW = 30

local filterLog = {}
local spamTracker = {}
local lastDedupeKey = nil
local lastDedupeTime = 0

-- ==================== FUNZIONI HELPER ====================
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

local function MatchesCustomKeywords(msg, keywords)
    if not keywords or #keywords == 0 then return false, nil end

    local lowerMsg = string.lower(msg)
    for _, word in ipairs(keywords) do
        if word ~= "" and string.find(lowerMsg, string.lower(word), 1, true) then
            return true, word
        end
    end
    return false, nil
end

local function MatchesChannelLFG(msg, channelName, channelIndex, db)
    if not db.filterWorldLFG and not db.filterLFGChannels then return false, nil end

    local isTargetChannel = false

    -- Check world channel by name
    if db.filterWorldLFG and channelName then
        if string.find(string.lower(channelName), "world", 1, true) or
           string.find(string.lower(channelName), "lookingforgroup", 1, true) then
            isTargetChannel = true
        end
    end

    -- Check specific channel numbers
    if not isTargetChannel and db.filterLFGChannels and channelIndex then
        if db.filterLFGChannels[tostring(channelIndex)] then
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

local function MatchesBoostFilter(msg, enabled)
    if not enabled then return false, nil end

    local lowerMsg = string.lower(msg)
    local boostWords = {
        "wts", "wtb", "selling", "boost", "boosting", "carry",
        "gdkp", "pilot", "piloted", "cheap", "price", "service",
        "buy", "sell", "currency", "wowt", "kingboost"
    }

    for _, word in ipairs(boostWords) do
        if string.find(lowerMsg, word, 1, true) then
            return true, "Boost/Trade"
        end
    end
    return false, nil
end

local function MatchesGuildFilter(msg, enabled)
    if not enabled then return false, nil end

    local lowerMsg = string.lower(msg)
    local guildWords = {
        "guild", "community", "recruit", "recruiting", "roster",
        "lf members", "lf guild", "new guild", "apply",
        "core group", "core team", "static group", "raid team",
        "looking for members", "looking for a guild", "guild is looking",
        "active members", "friendly guild", "pve guild", "pvp guild",
        "recruitment", "enlist", "join us"
    }

    for _, word in ipairs(guildWords) do
        if string.find(lowerMsg, word, 1, true) then
            return true, "Guild Recruit"
        end
    end
    return false, nil
end

-- ==================== EVENT FILTER ====================
local function ChatFilter_OnEvent(self, event, msg, player, language, channelName, ...)
    local db = ChatFilter.db
    if not db or not db.enabled then return false end
    if not msg or not player then return false end

    -- Remove realm names
    player = string.gsub(player, "%-[^|]+", "")
    if player == UnitName("player") then return false end

    local matched, trigger

    -- Spam burst check
    if IsSpamBurst(player) then
        AddLog(player, msg, "Spam Burst")
        return true
    end

    -- Custom keywords
    matched, trigger = MatchesCustomKeywords(msg, db.customKeywords)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    -- Channel LFG
    local channelIndex = select(4, ...)
    matched, trigger = MatchesChannelLFG(msg, channelName, channelIndex, db)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    -- Boost filter
    matched, trigger = MatchesBoostFilter(msg, db.filterBoost)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    -- Guild filter
    matched, trigger = MatchesGuildFilter(msg, db.filterGuild)
    if matched then
        AddLog(player, msg, trigger)
        return true
    end

    return false
end

-- ==================== CLEANUP SPAM TRACKER ====================
C_Timer.NewTicker(60, function()
    local now = GetTime()
    for name, entry in pairs(spamTracker) do
        if (now - entry.startTime) > SPAM_WINDOW * 2 then
            spamTracker[name] = nil
        end
    end
end)

-- ==================== REGISTRA FILTRI ====================
local function RegisterFilters()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatFilter_OnEvent)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_TRADESKILLS", ChatFilter_OnEvent)
end

-- ==================== OPZIONI UI ====================
function ChatFilter:CreateOptionsUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(530, 700)
    
    local yOffset = 10
    
    -- Toggle principale
    local enabledCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -yOffset)
    enabledCheck.Text:SetText("Enable Chat Filter")
    enabledCheck:SetChecked(self.db.enabled)
    enabledCheck:SetScript("OnClick", function(btn) self.db.enabled = btn:GetChecked() end)
    yOffset = yOffset + 35
    
    -- Separator
    local separator1 = frame:CreateTexture(nil, "BACKGROUND")
    separator1:SetSize(490, 2)
    separator1:SetPoint("TOP", frame, "TOP", 0, -yOffset - 5)
    separator1:SetColorTexture(0.3, 0.5, 0.8, 0.5)
    yOffset = yOffset + 15
    
    -- Filter options title
    local filterTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -yOffset)
    filterTitle:SetText("Filter Categories:")
    filterTitle:SetTextColor(1, 0.8, 0)
    yOffset = yOffset + 25
    
    -- World LFG filter
    local worldLFGCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
    worldLFGCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -yOffset)
    worldLFGCheck.Text:SetText("Filter World/LFG Channel advertisements")
    worldLFGCheck:SetChecked(self.db.filterWorldLFG)
    worldLFGCheck:SetScript("OnClick", function(btn) self.db.filterWorldLFG = btn:GetChecked() end)
    yOffset = yOffset + 25
    
    -- Boost filter
    local boostCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
    boostCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -yOffset)
    boostCheck.Text:SetText("Filter Boost/Trade messages")
    boostCheck:SetChecked(self.db.filterBoost)
    boostCheck:SetScript("OnClick", function(btn) self.db.filterBoost = btn:GetChecked() end)
    yOffset = yOffset + 25
    
    -- Guild filter
    local guildCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
    guildCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -yOffset)
    guildCheck.Text:SetText("Filter Guild Recruitment messages")
    guildCheck:SetChecked(self.db.filterGuild)
    guildCheck:SetScript("OnClick", function(btn) self.db.filterGuild = btn:GetChecked() end)
    yOffset = yOffset + 35
    
    -- Custom keywords title
    local customTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -yOffset)
    customTitle:SetText("Custom Keywords:")
    customTitle:SetTextColor(1, 0.8, 0)
    yOffset = yOffset + 25
    
    -- Keywords input
    local keywordInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    keywordInput:SetSize(300, 25)
    keywordInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -yOffset)
    keywordInput:SetAutoFocus(false)
    keywordInput:SetText("Enter keyword...")
    keywordInput:SetScript("OnEnterPressed", function(self)
        local keyword = self:GetText()
        if keyword and keyword ~= "" and keyword ~= "Enter keyword..." then
            if not self.db.customKeywords then self.db.customKeywords = {} end
            table.insert(self.db.customKeywords, keyword)
            self:SetText("")
            ChatFilter:RefreshKeywordList(keywordList)
        end
    end)
    
    local addBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    addBtn:SetSize(60, 25)
    addBtn:SetPoint("LEFT", keywordInput, "RIGHT", 10, 0)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        local keyword = keywordInput:GetText()
        if keyword and keyword ~= "" and keyword ~= "Enter keyword..." then
            if not self.db.customKeywords then self.db.customKeywords = {} end
            table.insert(self.db.customKeywords, keyword)
            keywordInput:SetText("")
            ChatFilter:RefreshKeywordList(keywordList)
        end
    end)
    yOffset = yOffset + 35
    
    -- Keywords list frame
    local keywordScroll = CreateFrame("ScrollFrame", nil, frame)
    keywordScroll:SetSize(450, 120)
    keywordScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -yOffset)
    
    local keywordList = CreateFrame("Frame", nil, keywordScroll)
    keywordList:SetSize(440, 100)
    keywordScroll:SetScrollChild(keywordList)
    
    yOffset = yOffset + 130
    
    -- Spam protection title
    local spamTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spamTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -yOffset)
    spamTitle:SetText("Spam Protection:")
    spamTitle:SetTextColor(1, 0.8, 0)
    yOffset = yOffset + 25
    
    local spamText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spamText:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -yOffset)
    spamText:SetText("Blocks players sending more than " .. MAX_SPAM_MESSAGES_PER_PLAYER .. " messages in " .. SPAM_WINDOW .. " seconds")
    spamText:SetTextColor(0.7, 0.7, 0.7)
    
    return frame
end

function ChatFilter:RefreshKeywordList(keywordList)
    -- Clear existing
    for _, child in ipairs({keywordList:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local yPos = 5
    for i, keyword in ipairs(self.db.customKeywords or {}) do
        local btn = CreateFrame("Button", nil, keywordList)
        btn:SetSize(430, 25)
        btn:SetPoint("TOPLEFT", keywordList, "TOPLEFT", 5, -yPos)
        
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.15, 0.15, 0.2, 1)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("LEFT", btn, "LEFT", 10, 0)
        btn.text:SetText(keyword)
        
        btn.deleteBtn = CreateFrame("Button", nil, btn)
        btn.deleteBtn:SetSize(20, 20)
        btn.deleteBtn:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
        btn.deleteBtn:SetText("X")
        btn.deleteBtn:SetScript("OnClick", function()
            table.remove(self.db.customKeywords, i)
            ChatFilter:RefreshKeywordList(keywordList)
        end)
        
        yPos = yPos + 28
    end
    
    keywordList:SetSize(440, math.max(100, yPos + 10))
end

-- ==================== INIZIALIZZAZIONE ====================
function ChatFilter:Initialize()
    -- Default settings
    if self.db.enabled == nil then self.db.enabled = true end
    if self.db.filterWorldLFG == nil then self.db.filterWorldLFG = true end
    if self.db.filterBoost == nil then self.db.filterBoost = true end
    if self.db.filterGuild == nil then self.db.filterGuild = false end
    if self.db.customKeywords == nil then self.db.customKeywords = {} end
    if self.db.filterLFGChannels == nil then self.db.filterLFGChannels = {} end
    
    RegisterFilters()
    
    if AruiQOLDB.Settings.debugMode then
        print("|cff88ccff[ChatFilter]|r Initialized")
    end
end

-- ==================== REGISTRAZIONE MODULO ====================
local function RegisterChatFilterModule()
    if not _G.AruiQOL then
        C_Timer.After(0.5, RegisterChatFilterModule)
        return
    end
    _G.AruiQOL:RegisterModule("ChatFilter", ChatFilter)
end

RegisterChatFilterModule()
