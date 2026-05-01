-- ============================================================
-- FrostSeek - Options Module 
-- ============================================================

local FrostSeek = _G.FrostSeek

local Options = {}

-- ==================== LOCAL VARIABLES ====================
local settingsWindow = nil
local categoryFrames = {}
local currentCategory = "general"
local previewEventFrame = nil
local keystoneUpdateTicker = nil

-- ==================== FUNZIONE PER GARANTIRE LA STRUTTURA DATI ====================
local function EnsureSettingsStructure()
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
    
    local defaults = {
        uiScale = 1.0,
        autoOpen = false,
        minimapButton = true,
        savePosition = true,
        debugMode = false
    }
    
    for k, v in pairs(defaults) do
        if FrostSeekDB.Settings[k] == nil then
            FrostSeekDB.Settings[k] = v
        end
    end
end

local function EnsureChatFilterStructure()
    FrostSeekDB.ChatFilter = FrostSeekDB.ChatFilter or {}
    if FrostSeekDB.ChatFilter.enabled == nil then FrostSeekDB.ChatFilter.enabled = true end
    if FrostSeekDB.ChatFilter.filterWorldLFG == nil then FrostSeekDB.ChatFilter.filterWorldLFG = true end
    if FrostSeekDB.ChatFilter.filterBoost == nil then FrostSeekDB.ChatFilter.filterBoost = true end
    if FrostSeekDB.ChatFilter.filterGuild == nil then FrostSeekDB.ChatFilter.filterGuild = false end
    if FrostSeekDB.ChatFilter.customKeywords == nil then FrostSeekDB.ChatFilter.customKeywords = {} end
end

local function EnsureInterruptAnnounceStructure()
    FrostSeekDB.InterruptAnnounce = FrostSeekDB.InterruptAnnounce or {}
    if FrostSeekDB.InterruptAnnounce.enabled == nil then FrostSeekDB.InterruptAnnounce.enabled = false end
    if FrostSeekDB.InterruptAnnounce.output == nil then FrostSeekDB.InterruptAnnounce.output = "Auto" end
    if FrostSeekDB.InterruptAnnounce.verbose == nil then FrostSeekDB.InterruptAnnounce.verbose = true end
    if FrostSeekDB.InterruptAnnounce.announceSelf == nil then FrostSeekDB.InterruptAnnounce.announceSelf = true end
end

-- ==================== FUNZIONE PER GARANTIRE STRUTTURA BOSS ANNOUNCE ====================
local function EnsureBossAnnounceStructure()
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.BossAnnounce then FrostSeekDB.BossAnnounce = {} end
    
    local defaults = {
        enabled = false,
        announceParty = true,
        announceRaid = false,
        announceGuild = false,
        showTimer = true,
        minBossHealth = 50,
        playSound = true,
        announceTrash = false,
        announceOnlyInInstance = true,
    }
    
    for k, v in pairs(defaults) do
        if FrostSeekDB.BossAnnounce[k] == nil then
            FrostSeekDB.BossAnnounce[k] = v
        end
    end
end

-- ==================== FUNZIONE PER GARANTIRE STRUTTURA CATEGORIE POPUP ====================
local function EnsurePopupCategoriesStructure()
    if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
    
    local defaultCategories = {
        ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true, 
        PVP = true, MANASTORM = true, KEYSTONE = true
    }
    
    if not FrostSeekDB.LFG.popupCategories then
        FrostSeekDB.LFG.popupCategories = {}
    end
    
    for catId, defaultValue in pairs(defaultCategories) do
        if FrostSeekDB.LFG.popupCategories[catId] == nil then
            FrostSeekDB.LFG.popupCategories[catId] = defaultValue
        end
    end
end

-- ==================== SETUP DATABASE SAVE ====================
local function SetupDatabaseSave()
    local saveFrame = CreateFrame("Frame")
    saveFrame:RegisterEvent("PLAYER_LOGOUT")
    saveFrame:RegisterEvent("PLAYER_QUIT")
    saveFrame:SetScript("OnEvent", function()
        if FrostSeekDB and FrostSeekDB.Settings then
            FrostSeekDB.Settings._lastSaved = time()
        end
    end)
end

-- ==================== FUNZIONE PER TROVARE KEYSTONE NELLE BORSE ====================
local function FindKeystoneInBags()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink and string.find(itemLink, "Keystone") then
                return itemLink
            end
        end
    end
    return nil
end

-- ==================== OTTIENI IL NOME DELL'OGGETTO DAL LINK ====================
local function GetItemNameFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, itemName = string.find(itemLink, "|h%[(.-)%]|h")
    return itemName or "Keystone"
end

-- ==================== DATI GIOCATORE ====================
local function GetPlayerData()
    local classInfo = "Unknown"
    local ilvl = 0
    local enchant = ""
    local roleText = ""
    
    local _, classFile = UnitClass("player")
    if classFile then
        local classMap = {
            ["WARRIOR"] = "Warrior", ["PALADIN"] = "Paladin", ["HUNTER"] = "Hunter",
            ["ROGUE"] = "Rogue", ["PRIEST"] = "Priest", ["DEATHKNIGHT"] = "Death Knight",
            ["SHAMAN"] = "Shaman", ["MAGE"] = "Mage", ["WARLOCK"] = "Warlock",
            ["DRUID"] = "Druid", ["HERO"] = "Hero",
            -- Ascension A52 & CoA
            ["NECROMANCER"] = "Necromancer", ["PYROMANCER"] = "Pyromancer",
            ["CULTIST"] = "Cultist", ["STARCALLER"] = "Starcaller",
            ["SUNCLERIC"] = "Suncleric", ["TINKER"] = "Tinker",
            ["RUNEMASTER"] = "Runemaster", ["PRIMAALIST"] = "Primaalist",
            ["REAPER"] = "Reaper", ["VENOMANCER"] = "Venomancer",
            ["CHRONOMANCER"] = "Chronomancer", ["BLOODMAGE"] = "Bloodmage",
            ["GUARDIAN"] = "Guardian", ["STORMBRINGER"] = "Stormbringer",
            ["FELSWORN"] = "Felsworn", ["BARBARIAN"] = "Barbarian",
            ["WITCH_DOCTOR"] = "Witch Doctor", ["WITCH_HUNTER"] = "Witch Hunter",
            ["KNIGHT_OF_XOROTH"] = "Knight of Xoroth", ["TEMPLAR"] = "Templar",
            ["RANGED"] = "Ranged"
        }
        classInfo = classMap[classFile] or classFile
    end
    
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
    ilvl = count > 0 and math.floor((sum / count) + 0.5) or 0
    
    if MysticEnchantUtil then
        local enchantData = MysticEnchantUtil.GetAppliedEnchantCountByQuality("player")
        if enchantData and enchantData[5] then
            for spellID, _ in pairs(enchantData[5]) do
                local spellName = GetSpellInfo(spellID)
                if spellName then
                    enchant = "[" .. spellName .. "]"
                    break
                end
            end
        end
    end
    
    roleText = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.myRole or ""
    
    return classInfo, ilvl, enchant, roleText
end

-- ==================== FUNZIONI UI ====================
local function CreateModernButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)
    
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.9)
    
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    btn.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    
    btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.hoverTex:SetAllPoints()
    btn.hoverTex:SetColorTexture(0.3, 0.5, 0.7, 0.4)
    btn.hoverTex:Hide()
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(1, 1, 1)
    
    btn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.text:SetTextColor(0.6, 0.8, 1)
        self.border:SetColorTexture(0.6, 0.8, 1, 0.8)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.text:SetTextColor(1, 1, 1)
        self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    end)
    
    return btn
end

local function CreateCleanEditBox(parent, width, height, isMultiLine)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(height)
    editBox:SetAutoFocus(false)
    editBox:SetTextInsets(5, 5, 2, 2)
    editBox:SetFontObject("GameFontNormal")
    
    if isMultiLine then editBox:SetMultiLine(true) end
    
    editBox:SetBackdrop(nil)
    
    for i = 1, #editBox:GetRegions() do
        local region = select(i, editBox:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            region:SetTexture(nil)
            region:Hide()
        end
    end
    
    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.15)
    bg:SetAllPoints()
    
    local border = editBox:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0.3, 0.3, 0.3, 0.2)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    
    return editBox
end

local function CreateModernCheckbox(parent, text, x, y)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(200)
    frame:SetHeight(25)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    local checkbox = CreateFrame("Button", nil, frame)
    checkbox:SetWidth(20)
    checkbox:SetHeight(20)
    checkbox:SetPoint("LEFT", frame, "LEFT", 0, 0)
    
    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetAllPoints()
    checkbox.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    
    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetWidth(14)
    checkbox.check:SetHeight(14)
    checkbox.check:SetPoint("CENTER")
    checkbox.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox.check:SetVertexColor(0.2, 0.8, 1, 1)
    checkbox.check:Hide()
    
    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetColorTexture(0.2, 0.3, 0.4, 0.5)
    checkbox.highlight:Hide()
    
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetText(text)
    label:SetTextColor(1, 1, 1)
    
    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.border:SetColorTexture(0.6, 0.8, 1, 1)
    end)
    
    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    end)
    
    checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        self.check:SetShown(self.checked)
    end)
    
    checkbox.checked = false
    frame.checkbox = checkbox
    frame.label = label
    
    return frame
end

local function CreateStyledButton(parent, text, x, y, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetWidth(width or 75)
    btn:SetHeight(height or 22)
    
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(0.8, 0.8, 0.8)
    
    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
        self.text:SetTextColor(1, 1, 1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    
    return btn
end

local function CreateSettingCheckbox(parent)
    local checkbox = CreateFrame("Button", nil, parent)
    checkbox:SetSize(24, 24)
    
    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetColorTexture(0.1, 0.1, 0.1, 1)
    
    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetAllPoints()
    checkbox.border:SetColorTexture(0.4, 0.4, 0.4, 1)
    
    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetSize(16, 16)
    checkbox.check:SetPoint("CENTER")
    checkbox.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox.check:SetVertexColor(0.2, 0.8, 1, 1)
    checkbox.check:Hide()
    
    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetColorTexture(0.3, 0.5, 0.7, 0.3)
    checkbox.highlight:Hide()
    
    checkbox.checked = false
    
    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.border:SetColorTexture(0.6, 0.8, 1, 1)
    end)
    
    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.border:SetColorTexture(0.4, 0.4, 0.4, 1)
    end)
    
    return checkbox
end

-- ==================== UPDATE PREVIEW PER CUSTOM MESSAGE ====================
local function UpdateCustomPreview(previewText)
    if not previewText then return end
    
    local classInfo, ilvl, enchant, roleText = GetPlayerData()
    local customMessages = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.customMessages
    
    if customMessages and customMessages.enabled then
        local message = customMessages.template or "hello {class} {ilvl} {ench} dps or healer {keystone}"
        
        message = string.gsub(message, "{class}", customMessages.showClass and classInfo or "")
        message = string.gsub(message, "{ilvl}", customMessages.showIlvl and tostring(ilvl) or "")
        message = string.gsub(message, "{ench}", customMessages.showEnchant and enchant or "")
        message = string.gsub(message, "{role}", customMessages.showRole and roleText or "")
        
        if customMessages.showKeystone then
            local keystoneLink = FindKeystoneInBags()
            local keystoneName = keystoneLink and (GetItemNameFromLink(keystoneLink) or "Keystone") or "No Keystone"
            message = string.gsub(message, "{keystone}", "[" .. keystoneName .. "]")
            customMessages.keystoneLink = keystoneLink
        else
            message = string.gsub(message, "{keystone}", "")
        end
        
        message = string.gsub(message, "%s+", " ")
        message = string.gsub(message, "^%s*(.-)%s*$", "%1")
        
        previewText:SetText(message == "" and "No content selected" or message)
        previewText:SetTextColor(0.6, 0.8, 1)
    else
        previewText:SetText("Custom messages disabled - Enable the checkbox above")
        previewText:SetTextColor(0.8, 0.8, 0.8)
    end
end

-- ==================== GESTIONE EVENTI PREVIEW ====================
local function StartPreviewEvents()
    if previewEventFrame then return end
    previewEventFrame = CreateFrame("Frame")
    previewEventFrame:RegisterEvent("BAG_UPDATE")
    previewEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    previewEventFrame:SetScript("OnEvent", function()
        if settingsWindow and settingsWindow:IsShown() and currentCategory == "custommessage" then
            local customFrame = categoryFrames["custommessage"]
            if customFrame and customFrame.previewText then
                UpdateCustomPreview(customFrame.previewText)
            end
        end
    end)
end

local function StopPreviewEvents()
    if previewEventFrame then
        previewEventFrame:UnregisterAllEvents()
        previewEventFrame = nil
    end
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end
end

local function StartKeystoneAutoUpdate()
    if keystoneUpdateTicker then keystoneUpdateTicker:Cancel() end
    keystoneUpdateTicker = C_Timer.NewTicker(2, function()
        if settingsWindow and settingsWindow:IsShown() and currentCategory == "custommessage" then
            local customFrame = categoryFrames["custommessage"]
            if customFrame and customFrame.previewText then
                UpdateCustomPreview(customFrame.previewText)
            end
        else
            keystoneUpdateTicker:Cancel()
            keystoneUpdateTicker = nil
        end
    end)
end

-- ==================== CREATE CUSTOM MESSAGE TAB ====================
local function CreateCustomMessageTab(parent, scrollContent)
    local frame = CreateFrame("Frame", nil, scrollContent)
    frame:SetSize(500, 800)
    frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Custom Whisper Messages")
    title:SetTextColor(0.6, 0.8, 1)
    
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Customize the message sent when you click Accept in LFG")
    desc:SetTextColor(0.7, 0.7, 0.7)
    
    local yOffset = -50
    
    -- ENABLE CHECKBOX
    local enableFrame = CreateModernCheckbox(frame, "Enable Custom Messages", 20, yOffset)
    local enableCheck = enableFrame.checkbox
    enableCheck.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled or false
    enableCheck.check:SetShown(enableCheck.checked)
    enableCheck:SetScript("OnClick", function(self)
        self.checked = not self.checked
        self.check:SetShown(self.checked)
        FrostSeekDB.LFG.customMessages.enabled = self.checked
        UpdateCustomPreview(previewText)
    end)
    yOffset = yOffset - 40
    
    -- MESSAGE TEMPLATE
    local templateLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    templateLabel:SetPoint("TOPLEFT", 20, yOffset)
    templateLabel:SetText("Message Template:")
    templateLabel:SetTextColor(0.8, 0.8, 0.8)
    yOffset = yOffset - 25
    
    local templateBox = CreateCleanEditBox(frame, 460, 60, true)
    templateBox:SetPoint("TOPLEFT", 20, yOffset)
    templateBox:SetText(FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.template or "hello {class} {ilvl} {ench} dps or healer {keystone}")
    templateBox:SetScript("OnTextChanged", function(self)
        FrostSeekDB.LFG.customMessages.template = self:GetText()
        UpdateCustomPreview(previewText)
    end)
    yOffset = yOffset - 70
    
    -- VARIABLE BUTTONS
    local varsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    varsLabel:SetPoint("TOPLEFT", 20, yOffset)
    varsLabel:SetText("Insert Variable:")
    varsLabel:SetTextColor(0.8, 0.8, 0.8)
    yOffset = yOffset - 25
    
    local variables = { { name = "class", display = "{class}" }, { name = "ilvl", display = "{ilvl}" }, { name = "ench", display = "{ench}" }, { name = "role", display = "{role}" }, { name = "keystone", display = "{keystone}" } }
    
    for i, var in ipairs(variables) do
        local btn = CreateStyledButton(frame, var.display, 20 + ((i-1) * 80), yOffset, 75, 22)
        btn:SetScript("OnClick", function()
            local currentText = templateBox:GetText() or ""
            if currentText ~= "" and not string.find(currentText, " $") then currentText = currentText .. " " end
            local newText = currentText .. "{" .. var.name .. "}"
            templateBox:SetText(newText)
            templateBox:SetCursorPosition(string.len(newText))
            FrostSeekDB.LFG.customMessages.template = newText
            UpdateCustomPreview(previewText)
        end)
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.2, 0.3, 0.4, 0.5)
            self.text:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(var.display, 1, 1, 1)
            GameTooltip:AddLine("Click to insert", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.3)
            self.text:SetTextColor(0.8, 0.8, 0.8)
            GameTooltip:Hide()
        end)
    end
    yOffset = yOffset - 35
    
    -- COMPONENTS CHECKBOXES
    local componentsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    componentsLabel:SetPoint("TOPLEFT", 20, yOffset)
    componentsLabel:SetText("Include in message:")
    componentsLabel:SetTextColor(0.8, 0.8, 0.8)
    yOffset = yOffset - 30
    
    local checkboxes = {}
    local checkboxConfigs = {
        { id = "showClass", name = "Class", x = 30, y = yOffset },
        { id = "showIlvl", name = "Item Level", x = 150, y = yOffset },
        { id = "showEnchant", name = "Enchant", x = 270, y = yOffset },
        { id = "showRole", name = "Role", x = 30, y = yOffset - 30 },
        { id = "showKeystone", name = "Keystone (auto)", x = 150, y = yOffset - 30 }
    }

    for _, cfg in ipairs(checkboxConfigs) do
        local cFrame = CreateModernCheckbox(frame, cfg.name, cfg.x, cfg.y)
        cFrame.checkbox.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages[cfg.id] or (cfg.id ~= "showKeystone")
        cFrame.checkbox.check:SetShown(cFrame.checkbox.checked)
        cFrame.checkbox:SetScript("OnClick", function(self)
            self.checked = not self.checked
            self.check:SetShown(self.checked)
            FrostSeekDB.LFG.customMessages[cfg.id] = self.checked
            UpdateCustomPreview(previewText)
        end)
        checkboxes[cfg.id] = cFrame.checkbox
    end
    yOffset = yOffset - 80
    
    -- PREVIEW
    local previewLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", 20, yOffset)
    previewLabel:SetText("Preview:")
    previewLabel:SetTextColor(0.8, 0.8, 0.8)
    yOffset = yOffset - 25
    
    local previewFrame = CreateFrame("Frame", nil, frame)
    previewFrame:SetPoint("TOPLEFT", 20, yOffset)
    previewFrame:SetSize(460, 60)
    previewFrame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16})
    previewFrame:SetBackdropColor(0.08, 0.08, 0.1, 0.2)
    
    local previewText = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewText:SetPoint("TOPLEFT", 10, -8)
    previewText:SetPoint("RIGHT", previewFrame, "RIGHT", -10, 0)
    previewText:SetPoint("BOTTOM", previewFrame, "BOTTOM", 0, -10)
    previewText:SetJustifyH("LEFT")
    previewText:SetJustifyV("TOP")
    yOffset = yOffset - 75
    
    -- RESET BUTTON
    local resetBtn = CreateModernButton(frame, "Reset to Default", 150, 30)
    resetBtn:SetPoint("TOPLEFT", 20, yOffset)
    resetBtn:SetScript("OnClick", function()
        FrostSeekDB.LFG.customMessages.template = "hello {class} {ilvl} {ench} dps or healer {keystone}"
        templateBox:SetText(FrostSeekDB.LFG.customMessages.template)
        
        local defaults = { showClass = true, showIlvl = true, showEnchant = true, showRole = true, showKeystone = false }
        for id, val in pairs(defaults) do
            FrostSeekDB.LFG.customMessages[id] = val
            if checkboxes[id] then
                checkboxes[id].checked = val
                checkboxes[id].check:SetShown(val)
            end
        end
        UpdateCustomPreview(previewText)
    end)
    
    UpdateCustomPreview(previewText)
    
    frame.previewText = previewText
    frame.templateBox = templateBox
    frame.checkboxes = checkboxes
    
    return frame
end

-- ==================== SETTINGS STRUCTURE ====================
local SETTINGS_CATEGORIES = {
    { id = "general", name = "General", icon = "Interface\\Icons\\INV_Misc_Book_09", settings = {
        { type = "header", id = "generalHeader", name = "", desc = "Basic addon configuration" },
        { type = "checkbox", id = "autoOpen", name = "Auto-Open on Login", desc = "Automatically open FrostSeek window when you log in", default = false, getter = function() return FrostSeekDB.Settings.autoOpen end, setter = function(v) FrostSeekDB.Settings.autoOpen = v print("|cff88ccffFrostSeek:|r Auto-open " .. (v and "enabled" or "disabled")) end },
        { type = "checkbox", id = "minimapButton", name = "Show Minimap Button", desc = "Show the FrostSeek minimap button", default = true, getter = function() return FrostSeekDB.Settings.minimapButton end, setter = function(v) FrostSeekDB.Settings.minimapButton = v local mb = _G["FrostSeekMiniMapButton"]; if mb and mb.SetShown then mb:SetShown(v) end end },
        { type = "checkbox", id = "savePosition", name = "Save Window Position", desc = "Remember window positions between sessions", default = true, getter = function() return FrostSeekDB.Settings.savePosition end, setter = function(v) FrostSeekDB.Settings.savePosition = v end },
        { type = "checkbox", id = "debugMode", name = "Debug Mode", desc = "Enable debug messages in chat", default = false, getter = function() return FrostSeekDB.Settings.debugMode end, setter = function(v) FrostSeekDB.Settings.debugMode = v end },
        { type = "slider", id = "uiScale", name = "UI Scale", desc = "Adjust the scale of the FrostSeek interface (0.5 - 1.5)", min = 0.5, max = 1.5, step = 0.05, default = 1.0, getter = function() return FrostSeekDB.Settings.uiScale end, setter = function(v) FrostSeekDB.Settings.uiScale = v if FrostSeek.MainFrame then FrostSeek.MainFrame:SetScale(v) end end }
    }},
    { id = "lfg", name = "LFG System", icon = "Interface\\Icons\\Ability_DualWield", settings = {
        { type = "header", id = "lfgHeader", name = "", desc = "Configure the Looking For Group radar" },
        { type = "checkbox", id = "disableLFG", name = "Disable LFG System", desc = "Completely disable the LFG radar", default = false, getter = function() return FrostSeekDB.LFG.disableLFG end, setter = function(v) FrostSeekDB.LFG.disableLFG = v end },
        { type = "checkbox", id = "disablePopups", name = "Disable Popups", desc = "Disable LFM alert popups", default = false, getter = function() return FrostSeekDB.LFG.disablePopups end, setter = function(v) FrostSeekDB.LFG.disablePopups = v end },
        { type = "checkbox", id = "silentNotifications", name = "Silent Notifications", desc = "Disable sound for LFG notifications", default = false, getter = function() return FrostSeekDB.LFG.silentNotifications end, setter = function(v) FrostSeekDB.LFG.silentNotifications = v end },
        { type = "checkbox", id = "doNotAlertInGroup", name = "No Alerts in Group", desc = "Don't show alerts when in a group", default = true, getter = function() return FrostSeekDB.LFG.doNotAlertInGroup end, setter = function(v) FrostSeekDB.LFG.doNotAlertInGroup = v end },
        { type = "checkbox", id = "doNotAlertInCombat", name = "No Alerts in Combat", desc = "Don't show alerts when in combat", default = true, getter = function() return FrostSeekDB.LFG.doNotAlertInCombat end, setter = function(v) FrostSeekDB.LFG.doNotAlertInCombat = v end },
        { type = "slider", id = "frameDuration", name = "Popup Duration", desc = "How long popups stay visible (seconds)", min = 2, max = 10, step = 1, default = 5, getter = function() return FrostSeekDB.LFG.frameDuration end, setter = function(v) FrostSeekDB.LFG.frameDuration = v end },
        { type = "slider", id = "popupCooldown", name = "Popup Cooldown", desc = "Time between identical popups (seconds)", min = 60, max = 600, step = 10, default = 370, getter = function() return FrostSeekDB.LFG.popupCooldown end, setter = function(v) FrostSeekDB.LFG.popupCooldown = v end },
        { type = "slider", id = "maxConcurrentPopups", name = "Max Popups", desc = "Maximum number of popups shown at once", min = 1, max = 5, step = 1, default = 2, getter = function() return FrostSeekDB.LFG.maxConcurrentPopups end, setter = function(v) FrostSeekDB.LFG.maxConcurrentPopups = v end },
        { type = "checkbox", id = "enableDungeonFilter", name = "Filter by Specific Dungeons", desc = "Only show alerts for dungeons you type below (leave empty = show all)", default = false, getter = function() return FrostSeekDB.LFG.enableDungeonFilter or false end, setter = function(v) FrostSeekDB.LFG.enableDungeonFilter = v end },
        { type = "editbox", id = "dungeonFilterList", name = "Dungeon Keywords:", desc = "Comma-separated dungeon names. Examples: hoc,pos,fos,hor,icc,naxx,strat", default = "", getter = function() return FrostSeekDB.LFG.dungeonFilterList or "" end, setter = function(v) FrostSeekDB.LFG.dungeonFilterList = v end }
    }},

    { id = "bossannounce", name = "Boss Announce", icon = "Interface\\Icons\\INV_Misc_MonsterHead_01", settings = {
    { type = "header", id = "bossAnnounceHeader", name = "", desc = "Configure automatic boss fight announcements" },
    { type = "checkbox", id = "enabled", name = "Enable Boss Announcements", desc = "Automatically announce boss fights in chat", default = false, 
        getter = function() return FrostSeekDB.BossAnnounce.enabled end, 
        setter = function(v) 
            FrostSeekDB.BossAnnounce.enabled = v
            if FrostSeek.Modules and FrostSeek.Modules.bossannounce then
                if v then FrostSeek.Modules.bossannounce:Enable() else FrostSeek.Modules.bossannounce:Disable() end
            end
        end 
    },
    { type = "header", id = "channelsHeader", name = "", desc = "Select where to send boss announcements" },
    { type = "checkbox", id = "announceParty", name = "Party Chat", desc = "Announce in party chat (when in a party)", default = true,
        getter = function() return FrostSeekDB.BossAnnounce.announceParty end,
        setter = function(v) FrostSeekDB.BossAnnounce.announceParty = v end
    },
    { type = "checkbox", id = "announceRaid", name = "Raid Chat", desc = "Announce in raid chat (when in a raid)", default = false,
        getter = function() return FrostSeekDB.BossAnnounce.announceRaid end,
        setter = function(v) FrostSeekDB.BossAnnounce.announceRaid = v end
    },
    { type = "checkbox", id = "announceGuild", name = "Guild Chat", desc = "Also announce in guild chat", default = false,
        getter = function() return FrostSeekDB.BossAnnounce.announceGuild end,
        setter = function(v) FrostSeekDB.BossAnnounce.announceGuild = v end
    },
    { type = "header", id = "advancedHeader", name = "", desc = "Fine-tune announcement behavior" },
    { type = "checkbox", id = "showTimer", name = "Show Fight Duration", desc = "Display how long the boss fight lasted", default = true,
        getter = function() return FrostSeekDB.BossAnnounce.showTimer end,
        setter = function(v) FrostSeekDB.BossAnnounce.showTimer = v end
    },
    { type = "checkbox", id = "playSound", name = "Play Sound on Boss Pull", desc = "Play a sound when a boss fight starts", default = true,
        getter = function() return FrostSeekDB.BossAnnounce.playSound end,
        setter = function(v) FrostSeekDB.BossAnnounce.playSound = v end
    },
    { type = "checkbox", id = "announceOnlyInInstance", name = "Instance Only", desc = "Only announce in dungeons/raids (not in open world)", default = true,
        getter = function() return FrostSeekDB.BossAnnounce.announceOnlyInInstance end,
        setter = function(v) FrostSeekDB.BossAnnounce.announceOnlyInInstance = v end
    },
    { type = "checkbox", id = "announceTrash", name = "Announce Trash Mobs", desc = "Also announce trash mob fights (can be spammy)", default = false,
        getter = function() return FrostSeekDB.BossAnnounce.announceTrash end,
        setter = function(v) FrostSeekDB.BossAnnounce.announceTrash = v end
    },
    { type = "slider", id = "minBossHealth", name = "Health Alert Threshold", desc = "Alert when boss drops below this % health (0 = disable)", min = 0, max = 90, step = 5, default = 50,
        getter = function() return FrostSeekDB.BossAnnounce.minBossHealth end,
        setter = function(v) FrostSeekDB.BossAnnounce.minBossHealth = v end
    },
    { type = "button", id = "testAnnounce", name = "Test Announcement", desc = "Send a test announcement to test settings", 
        onClick = function()
            if FrostSeek.Modules and FrostSeek.Modules.bossannounce then
                FrostSeek.Modules.bossannounce:SendTestAnnouncement()
            else
                print("|cff88ccffBossAnnounce:|r Module not loaded")
            end
        end 
    },
    }},
    { id = "custommessage", name = "LFG Custom Wisp", icon = "Interface\\Icons\\INV_Misc_Note_01", settings = {} },
    { id = "lfm", name = "LFM System", icon = "Interface\\Icons\\Ability_Creature_Cursed_02", settings = {
        { type = "header", id = "lfmHeader", name = "", desc = "Configure the Looking For Members system" },
        { type = "slider", id = "autoUpdateInterval", name = "Auto-update Interval", desc = "Seconds between keystone list updates (0 = disable)", min = 0, max = 300, step = 10, default = 60, getter = function() return FrostSeekDB.LFM.autoUpdateInterval end, setter = function(v) FrostSeekDB.LFM.autoUpdateInterval = v if FrostSeek.Modules and FrostSeek.Modules.lfm and FrostSeek.Modules.lfm.UpdateAutoUpdateInterval then FrostSeek.Modules.lfm:UpdateAutoUpdateInterval() end end },
        { type = "header", id = "autoSpamHeader", name = "", desc = "Auto-Spam: automatically send LFM messages on a timer" },
        { type = "slider", id = "autoSpamInterval", name = "Spam Timer (seconds)", desc = "How often to auto-send the LFM message (min 5s)", min = 5, max = 300, step = 5, default = 30, getter = function() return FrostSeekDB.LFM.autoSpamInterval or 30 end, setter = function(v) FrostSeekDB.LFM.autoSpamInterval = v end },
        { type = "header", id = "autoInviteHeader", name = "", desc = "Auto-Invite: automatically invite players who whisper their iLvl" },
        { type = "checkbox", id = "autoInviteEnabled", name = "Enable Auto-Invite on Whisper", desc = "When someone whispers you and their iLvl meets the minimum, auto-invite them", default = false, getter = function() return FrostSeekDB.LFM.autoInviteEnabled or false end, setter = function(v) FrostSeekDB.LFM.autoInviteEnabled = v print("|cff88ccffFrostSeek LFM:|r Auto-Invite " .. (v and "enabled" or "disabled")) end },
        { type = "slider", id = "autoInviteMinIlvl", name = "Min iLvl for Auto-Invite", desc = "Minimum item level required to auto-invite (a player whispering a number >= this value gets invited)", min = 0, max = 500, step = 5, default = 150, getter = function() return FrostSeekDB.LFM.autoInviteMinIlvl or 150 end, setter = function(v) FrostSeekDB.LFM.autoInviteMinIlvl = v print("|cff88ccffFrostSeek LFM:|r Auto-Invite min iLvl set to " .. v) end },
        { type = "button", id = "resetSpamChannels", name = "Reset Spam Channels", desc = "Clear all selected spam channels", onClick = function() if FrostSeekDB.LFM.spamChannels then wipe(FrostSeekDB.LFM.spamChannels) end print("|cff88ccffFrostSeek LFM:|r Spam channels reset") end }
    }},
    { id = "qol", name = "QoL", icon = "Interface\\Icons\\INV_Misc_Coin_01", settings = {
        { type = "header", id = "qolHeader", name = "", desc = "QOL features" },
        { type = "checkbox", id = "autoSellGreys", name = "Auto-Sell Grey Items", desc = "Automatically sell grey items when visiting a vendor", default = false, getter = function() return FrostSeekDB.QOL.autoSellGreys end, setter = function(v) FrostSeekDB.QOL.autoSellGreys = v end },
        { type = "checkbox", id = "autoRepair", name = "Auto-Repair Equipment", desc = "Automatically repair equipment when visiting a vendor", default = false, getter = function() return FrostSeekDB.QOL.autoRepair end, setter = function(v) FrostSeekDB.QOL.autoRepair = v end },
        { type = "checkbox", id = "useGuildRepair", name = "Use Guild Bank for Repair", desc = "Use guild bank funds for repairs when available", default = false, getter = function() return FrostSeekDB.QOL.useGuildRepair end, setter = function(v) FrostSeekDB.QOL.useGuildRepair = v end }
    }},
    { id = "popupcategories", name = "Popup Categories", icon = "Interface\\Icons\\INV_Misc_Note_02", settings = {
        { type = "header", id = "popupCategoriesHeader", name = "", desc = "Select which categories trigger popup notifications" },
        { type = "category", id = "popupCategories", name = "Enable popups for:", categories = {
            { id = "ALL", name = "All Categories", desc = "Show popups for all categories (overrides individual selections)" },
            { id = "DUNGEON", name = "Dungeons", desc = "Normal and heroic dungeons" },
            { id = "RAID", name = "Raids", desc = "All raid instances" },
            { id = "WORLD_BOSS", name = "World Bosses", desc = "Azuregos, Kazzak, Emeriss, Soggoth, etc." },
            { id = "PVP", name = "PvP", desc = "Arena and battlegrounds" },
            { id = "MANASTORM", name = "Manastorm", desc = "Manastorm activities" },
            { id = "KEYSTONE", name = "Keystone", desc = "Mythic+ keystone runs" },
        }, getter = function(catId) if FrostSeekDB.LFG.popupCategories.ALL and catId ~= "ALL" then return true end return FrostSeekDB.LFG.popupCategories[catId] or false end,
        setter = function(catId, value)
            if catId == "ALL" then
                FrostSeekDB.LFG.popupCategories.ALL = value
                if value then for id, _ in pairs(FrostSeekDB.LFG.popupCategories) do if id ~= "ALL" then FrostSeekDB.LFG.popupCategories[id] = false end end end
            else
                FrostSeekDB.LFG.popupCategories[catId] = value
                if value then FrostSeekDB.LFG.popupCategories.ALL = false end
                local anyActive = false
                for id, val in pairs(FrostSeekDB.LFG.popupCategories) do if id ~= "ALL" and val then anyActive = true; break end end
                if not anyActive then FrostSeekDB.LFG.popupCategories.ALL = true end
            end
        end },
        { type = "button", id = "popupInfo", name = "How Popup Categories Work", desc = "Click for information", onClick = function() print("|cff88ccff========== POPUP CATEGORIES INFO ==========|r") print("Read logic: ALL overrides individuals. If none selected, ALL is forced ON.") print("|cff88ccff==========================================|r") end }
    }},
            { id = "chatfilter", name = "Chat Filter", icon = "Interface\\Icons\\INV_Misc_Note_03", settings = {
        { type = "header", id = "chatFilterHeader", name = "", desc = "Filter unwanted messages from chat channels" },
        { type = "checkbox", id = "cfEnabled", name = "Enable Chat Filter", desc = "Filter unwanted messages from chat (does not affect FrostSeek LFG popups)", default = true, getter = function() return FrostSeekDB.ChatFilter and FrostSeekDB.ChatFilter.enabled end, setter = function(v) if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end FrostSeekDB.ChatFilter.enabled = v end },
        { type = "header", id = "filterTypesHeader", name = "", desc = "Toggle specific filter types" },
        { type = "checkbox", id = "cfWorldLFG", name = "Filter World LFG", desc = "Hide LFG/LFM messages from World channel", default = true, getter = function() return FrostSeekDB.ChatFilter and FrostSeekDB.ChatFilter.filterWorldLFG end, setter = function(v) if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end FrostSeekDB.ChatFilter.filterWorldLFG = v end },
        { type = "checkbox", id = "cfBoost", name = "Filter Boost/WTS/WTB", desc = "Hide boost selling, WTS, WTB, GDKP messages", default = true, getter = function() return FrostSeekDB.ChatFilter and FrostSeekDB.ChatFilter.filterBoost end, setter = function(v) if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end FrostSeekDB.ChatFilter.filterBoost = v end },
        { type = "checkbox", id = "cfGuild", name = "Filter Guild Recruitment", desc = "Hide guild and community recruitment messages", default = false, getter = function() return FrostSeekDB.ChatFilter and FrostSeekDB.ChatFilter.filterGuild end, setter = function(v) if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end FrostSeekDB.ChatFilter.filterGuild = v end },
        { type = "header", id = "lfgChannelsHeader", name = "", desc = "Select additional channels to filter LFG messages from" },
        { type = "category", id = "cfLFGChannels", name = "Filter LFG on channels:", categories = {
            { id = "1", name = "Channel 1", desc = "Filter LFG on channel 1" },
            { id = "2", name = "Channel 2", desc = "Filter LFG on channel 2" },
            { id = "3", name = "Channel 3", desc = "Filter LFG on channel 3" },
            { id = "4", name = "Channel 4 (LookingForGroup)", desc = "Filter LFG on channel 4" },
            { id = "5", name = "Channel 5", desc = "Filter LFG on channel 5" },
            { id = "6", name = "Channel 6", desc = "Filter LFG on channel 6" },
            { id = "7", name = "Channel 7", desc = "Filter LFG on channel 7" },
            { id = "8", name = "Channel 8", desc = "Filter LFG on channel 8" },
            { id = "9", name = "Channel 9", desc = "Filter LFG on channel 9" },
            { id = "10", name = "Channel 10", desc = "Filter LFG on channel 10" },
        }, getter = function(channelId)
            local id = tonumber(channelId)
            return FrostSeekDB.ChatFilter and FrostSeekDB.ChatFilter.filterLFGChannels and FrostSeekDB.ChatFilter.filterLFGChannels[id] or false
        end, setter = function(channelId, value)
            if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end
            if not FrostSeekDB.ChatFilter.filterLFGChannels then FrostSeekDB.ChatFilter.filterLFGChannels = {} end
            FrostSeekDB.ChatFilter.filterLFGChannels[tonumber(channelId)] = value
        end },
        { type = "header", id = "customKeywordsHeader", name = "", desc = "Add your own custom filter keywords" },
        { type = "editbox", id = "cfCustomKeywords", name = "Custom Keywords:", desc = "Comma-separated keywords to filter from chat", default = "", getter = function()
            if not FrostSeekDB.ChatFilter then return "" end
            local kw = FrostSeekDB.ChatFilter.customKeywords or {}
            return table.concat(kw, ",")
        end, setter = function(v)
            if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end
            local keywords = {}
            for w in string.gmatch(v or "", "[^,]+") do
                w = w:match("^%s*(.-)%s*$")
                if w ~= "" then table.insert(keywords, w) end
            end
            FrostSeekDB.ChatFilter.customKeywords = keywords
        end },
        { type = "button", id = "cfClearKeywords", name = "Clear Custom Keywords", desc = "Remove all custom filter keywords", onClick = function() if not FrostSeekDB.ChatFilter then FrostSeekDB.ChatFilter = {} end FrostSeekDB.ChatFilter.customKeywords = {} end }
    }},
        { id = "interruptannounce", name = "Interrupt Announce", icon = "Interface\\Icons\\Spell_Frost_IceShock", settings = {
        { type = "header", id = "interruptHeader", name = "", desc = "Announce spell interrupts in chat" },
        { type = "checkbox", id = "iaEnabled", name = "Enable Interrupt Announce", desc = "Announce when you interrupt a spell", default = false, getter = function() return FrostSeekDB.InterruptAnnounce and FrostSeekDB.InterruptAnnounce.enabled end, setter = function(v) if not FrostSeekDB.InterruptAnnounce then FrostSeekDB.InterruptAnnounce = {} end FrostSeekDB.InterruptAnnounce.enabled = v end },
        { type = "header", id = "outputHeader", name = "", desc = "Choose where to send interrupt messages" },
        { type = "category", id = "iaOutput", name = "Output channel:", categories = {
            { id = "Auto", name = "Auto", desc = "Party in party, Raid in raid, nothing solo" },
            { id = "Say", name = "Say", desc = "Always announce in Say chat" },
            { id = "Party", name = "Party", desc = "Always announce in Party chat" },
            { id = "Raid", name = "Raid", desc = "Always announce in Raid chat" },
            { id = "Self", name = "Self Only", desc = "Do not send message (disabled)" },
        }, getter = function(catId)
            return FrostSeekDB.InterruptAnnounce and FrostSeekDB.InterruptAnnounce.output == catId
        end, setter = function(catId, value)
            if not FrostSeekDB.InterruptAnnounce then FrostSeekDB.InterruptAnnounce = {} end
            if value then
                FrostSeekDB.InterruptAnnounce.output = catId
                for _, cat in ipairs({
                    { id = "Auto" }, { id = "Say" }, { id = "Party" }, { id = "Raid" }, { id = "Self" }
                }) do
                    if cat.id ~= catId then end
                end
            end
        end },
        { type = "checkbox", id = "iaVerbose", name = "Verbose Messages", desc = "Use '=> Interrupted:' prefix instead of plain 'Interrupted:'", default = true, getter = function() return FrostSeekDB.InterruptAnnounce and FrostSeekDB.InterruptAnnounce.verbose end, setter = function(v) if not FrostSeekDB.InterruptAnnounce then FrostSeekDB.InterruptAnnounce = {} end FrostSeekDB.InterruptAnnounce.verbose = v end },
    }},
    { id = "advanced", name = "Advanced", icon = "Interface\\Icons\\INV_Misc_EngGizmos_01", settings = {
        { type = "header", id = "advancedHeader", name = "", desc = "Advanced configuration options" },
        { type = "button", id = "resetPosition", name = "Reset Window Position", desc = "Reset main window to default position", onClick = function() FrostSeekDB.Settings.windowPosition = nil; if FrostSeek.MainFrame then FrostSeek.MainFrame:ClearAllPoints(); FrostSeek.MainFrame:SetPoint("CENTER") end print("|cff88ccffFrostSeek:|r Window positions reset") end },
        { type = "button", id = "clearAllData", name = "Clear All Data", desc = "Clear all saved data", warning = "This cannot be undone!", onClick = function() StaticPopup_Show("FROSTSEEK_CONFIRM_CLEAR_DATA") end }
    }}
}

-- ==================== SETTING CONTROL CREATION ====================
local function CreateSettingControl(parent, setting, yOffset)
    if setting.id == "debugMode" and not FrostSeekDB.Settings.debugMode then return nil, 0 end
    
    local controlFrame = CreateFrame("Frame", nil, parent)
    controlFrame:SetSize(500, 50)
    controlFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    
    local nameLabel = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
    nameLabel:SetText(setting.name or "")
    nameLabel:SetTextColor(1, 1, 1)
    
    controlFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name or "", 1, 1, 1)
        GameTooltip:AddLine(setting.desc or "", 0.8, 0.8, 0.8, true)
        if setting.warning then GameTooltip:AddLine(" "); GameTooltip:AddLine("Warning: " .. setting.warning, 1, 0.2, 0.2, true) end
        GameTooltip:Show()
    end)
    controlFrame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    
    if setting.type == "checkbox" then
        local checkbox = CreateSettingCheckbox(controlFrame)
        checkbox:SetPoint("RIGHT", controlFrame, "RIGHT", -10, 0)
        nameLabel:SetPoint("RIGHT", checkbox, "LEFT", -5, 0)
        nameLabel:SetJustifyH("LEFT")
        
        local function Update() local v = setting.getter and setting.getter() or FrostSeekDB.Settings[setting.id] or setting.default or false; checkbox.checked = v; checkbox.check:SetShown(v) end
        Update()
        
        checkbox:SetScript("OnClick", function(self)
            self.checked = not self.checked
            self.check:SetShown(self.checked)
            if setting.setter then setting.setter(self.checked) else FrostSeekDB.Settings[setting.id] = self.checked end
        end)
        checkbox.UpdateFromDB = Update
        return controlFrame, -40, checkbox

    elseif setting.type == "slider" then
        local isInteger = (setting.step or 1) >= 1
        local valueText = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valueText:SetPoint("RIGHT", controlFrame, "RIGHT", -40, 0)
        valueText:SetTextColor(0.6, 0.8, 1)
        
        local slider = CreateFrame("Slider", nil, controlFrame)
        slider:SetPoint("RIGHT", controlFrame, "RIGHT", -80, 0)
        slider:SetSize(150, 15)
        slider:SetMinMaxValues(setting.min or 0, setting.max or 100)
        slider:SetValueStep(setting.step or 1)
        slider:SetOrientation("HORIZONTAL")
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        
        local bg = slider:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        local function Update()
            local v = setting.getter and setting.getter() or FrostSeekDB.Settings[setting.id] or setting.default or 1
            valueText:SetText(isInteger and tostring(math.floor(v)) or string.format("%.2f", v))
            slider:SetValue(v)
        end
        Update()
        
        slider:SetScript("OnValueChanged", function(self, value)
            local step = setting.step or 1
            local rv = math.floor(value / step + 0.5) * step
            self:SetValue(rv)
            valueText:SetText(isInteger and tostring(math.floor(rv)) or string.format("%.2f", rv))
            if setting.setter then setting.setter(rv) else FrostSeekDB.Settings[setting.id] = rv end
        end)
        slider.UpdateFromDB = Update
        return controlFrame, -50, slider

    elseif setting.type == "category" then
        local categoriesFrame = CreateFrame("Frame", nil, parent)
        categoriesFrame:SetSize(540, 200)
        categoriesFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset - 20)
        
        local title = categoriesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", categoriesFrame, "TOPLEFT", 0, 0)
        title:SetText(setting.name or "")
        title:SetTextColor(1, 1, 1)
        
        local catYOffset = -30
        local checkboxes = {}
        
        for i, category in ipairs(setting.categories or {}) do
            local catFrame = CreateFrame("Frame", nil, categoriesFrame)
            catFrame:SetSize(540, 30)
            catFrame:SetPoint("TOPLEFT", categoriesFrame, "TOPLEFT", 20, catYOffset)
            
            local checkbox = CreateSettingCheckbox(catFrame)
            checkbox:SetPoint("LEFT", catFrame, "LEFT", 0, 0)
            
            local label = catFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
            label:SetText(category.name or "")
            label:SetTextColor(0.8, 0.8, 0.8)
            
            local function Update() checkbox.checked = setting.getter(category.id); checkbox.check:SetShown(checkbox.checked) end
            Update()
            
            checkbox:SetScript("OnClick", function(self)
                self.checked = not self.checked
                self.check:SetShown(self.checked)
                setting.setter(category.id, self.checked)
                
                -- Logica di aggiornamento grafico per le checkbox delle categorie
                for _, cb in ipairs(checkboxes) do
                    cb.UpdateFromDB()
                end
            end)
            
            checkbox.categoryId = category.id
            checkbox.UpdateFromDB = Update
            table.insert(checkboxes, checkbox)
            
            catFrame:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(category.name or "", 1, 1, 1); GameTooltip:AddLine(category.desc or "", 0.8, 0.8, 0.8, true); GameTooltip:Show() end)
            catFrame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
            
            catYOffset = catYOffset - 32
        end
        return categoriesFrame, catYOffset - 20, checkboxes
    
    elseif setting.type == "button" then
        local button = CreateModernButton(controlFrame, setting.name or "", 180, 25)
        button:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
        button:SetScript("OnClick", function() if setting.onClick then setting.onClick() end end)
        return controlFrame, -45, button
    
        elseif setting.type == "editbox" then
        local editBox = CreateCleanEditBox(parent, 350, 25)
        editBox:SetPoint("RIGHT", controlFrame, "RIGHT", -10, 0)
        nameLabel:SetPoint("RIGHT", editBox, "LEFT", -5, 0)
        nameLabel:SetJustifyH("LEFT")

        local function Update()
            local v = setting.getter and setting.getter() or ""
            editBox:SetText(v or "")
        end
        Update()

        editBox:SetScript("OnTextChanged", function(self)
            if setting.setter then setting.setter(self:GetText()) end
        end)
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        editBox.UpdateFromDB = Update
        return controlFrame, -45, editBox

    elseif setting.type == "header" then
        local headerFrame = CreateFrame("Frame", nil, parent)
        headerFrame:SetSize(540, 40)
        headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
        
        local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
        headerText:SetText(setting.name or "")
        headerText:SetTextColor(0.6, 0.8, 1)
        
        if setting.desc and setting.desc ~= "" then
            local headerDesc = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            headerDesc:SetPoint("TOPLEFT", headerText, "BOTTOMLEFT", 0, -5)
            headerDesc:SetText(setting.desc)
            headerDesc:SetTextColor(0.7, 0.7, 0.7)
        end
        return headerFrame, -60
    end
    return controlFrame, -40
end

local function RefreshAllControls()
    if not settingsWindow or not settingsWindow.controls then return end
    for _, control in ipairs(settingsWindow.controls) do
        if control and control.UpdateFromDB then control.UpdateFromDB() end
    end
end

-- ==================== OPTIONS WINDOW ====================
function CreateOptionsWindow()
    EnsureSettingsStructure()
    EnsureBossAnnounceStructure()
    EnsurePopupCategoriesStructure()
    SetupDatabaseSave()
    
    if settingsWindow then
        RefreshAllControls()
        settingsWindow:Show()
        return
    end
    
        local backdropTemplate = FrostSeekCompat.GetBackdropTemplateStr()
    settingsWindow = CreateFrame("Frame", "FrostSeekOptionsWindow", UIParent, backdropTemplate ~= "" and backdropTemplate or nil)
    settingsWindow:SetSize(800, 700)
    settingsWindow:SetPoint("CENTER")
    settingsWindow:SetFrameStrata("DIALOG")
    settingsWindow:EnableMouse(true)
    settingsWindow:SetMovable(true)
    settingsWindow:RegisterForDrag("LeftButton")
    settingsWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsWindow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    settingsWindow:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    settingsWindow:SetBackdropColor(0.1, 0.1, 0.15, 0.95)
    settingsWindow:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, settingsWindow)
    titleBar:SetPoint("TOPLEFT", settingsWindow, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", settingsWindow, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(35)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() settingsWindow:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() settingsWindow:StopMovingOrSizing() end)
    
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER")
    title:SetText("|cff88ccffFrostSeek Settings|r")
    
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() settingsWindow:Hide(); StopPreviewEvents() end)
    
    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, settingsWindow)
    sidebar:SetSize(180, 550)
    sidebar:SetPoint("TOPLEFT", settingsWindow, "TOPLEFT", 15, -50)
    
    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(0.15, 0.15, 0.2, 0.8)
    
    local catYOffset = -40
    for _, category in ipairs(SETTINGS_CATEGORIES) do
        local btn = CreateModernButton(sidebar, category.name, 160, 32)
        btn:SetPoint("TOP", sidebar, "TOP", 0, catYOffset)
        if category.icon then
            local icon = btn:CreateTexture(nil, "OVERLAY")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
            icon:SetTexture(category.icon)
        end
        btn:SetScript("OnClick", function() 
            SwitchSettingsCategory(category.id)
            RefreshAllControls()
            if category.id == "custommessage" and FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showKeystone then
                StartKeystoneAutoUpdate()
            else
                if keystoneUpdateTicker then keystoneUpdateTicker:Cancel(); keystoneUpdateTicker = nil end
            end
        end)
        catYOffset = catYOffset - 38
    end
    
    -- Content
    local contentFrame = CreateFrame("Frame", nil, settingsWindow)
    contentFrame:SetSize(550, 550)
    contentFrame:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 20, 0)
    
    local contentBg = contentFrame:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.1, 0.1, 0.15, 0.8)
    
        local scrollFrame = CreateFrame("ScrollFrame", "FrostSeekSettingsScroll", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -25, 10)
    
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(500, 900)
    scrollFrame:SetScrollChild(scrollContent)
    
    settingsWindow.scrollContent = scrollContent
    settingsWindow.scrollFrame = scrollFrame
    settingsWindow.controls = {}
    
    for _, category in ipairs(SETTINGS_CATEGORIES) do
        local frame
        if category.id == "custommessage" then
            frame = CreateCustomMessageTab(category, scrollContent)
        else
            frame = CreateFrame("Frame", nil, scrollContent)
            frame:SetSize(500, 900)
            frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
            
            local frameTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            frameTitle:SetPoint("TOP", frame, "TOP", 0, -15)
            frameTitle:SetText(category.name)
            frameTitle:SetTextColor(0.6, 0.8, 1)
            
            local yOffset = -50
            for _, setting in ipairs(category.settings) do
                local control, height, controlObj = CreateSettingControl(frame, setting, yOffset)
                yOffset = yOffset + (height or -45)
                if controlObj then table.insert(settingsWindow.controls, controlObj) end
            end
        end
        frame:Hide()
        categoryFrames[category.id] = frame
    end
    
    -- Footer
    local footer = CreateFrame("Frame", nil, settingsWindow)
    footer:SetPoint("BOTTOMLEFT", settingsWindow, "BOTTOMLEFT", 15, 10)
    footer:SetPoint("BOTTOMRIGHT", settingsWindow, "BOTTOMRIGHT", -15, 10)
    footer:SetHeight(35)
    
    local footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetPoint("LEFT", footer, "LEFT", 0, 0)
    footerText:SetText("|cff888888FrostSeek |r")
    
    local closeButton = CreateModernButton(footer, "Close", 80, 28)
    closeButton:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() settingsWindow:Hide(); StopPreviewEvents() end)
    
    StartPreviewEvents()
end

function SwitchSettingsCategory(categoryId)
    currentCategory = categoryId
    for id, frame in pairs(categoryFrames) do
        if frame then frame:SetShown(id == categoryId) end
    end
    if settingsWindow and settingsWindow.scrollFrame then
        settingsWindow.scrollFrame:SetVerticalScroll(0)
    end
end

function ShowOptionsWindow()
    CreateOptionsWindow()
    if settingsWindow then
        settingsWindow:Show()
        SwitchSettingsCategory("general")
        RefreshAllControls()
    end
end

-- ==================== MODULE FUNCTIONS ====================
function Options:Initialize(parentFrame)
    EnsureSettingsStructure()
    EnsurePopupCategoriesStructure()
    
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    
    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", self.frame, "TOP", 0, -20)
    self.title:SetText("|cff88ccffSystem Settings|r")
    
    self.desc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -10)
    self.desc:SetText("Configure all FrostSeek settings")
    self.desc:SetTextColor(0.8, 0.8, 0.8)
    
    local buttonsFrame = CreateFrame("Frame", nil, self.frame)
    buttonsFrame:SetSize(760, 280)
    buttonsFrame:SetPoint("CENTER", self.frame, "CENTER", 0, -60)
    
    self.openBtn = CreateModernButton(buttonsFrame, "Open Settings Window", 220, 45)
    self.openBtn:SetPoint("TOP", buttonsFrame, "TOP", 0, 0)
    self.openBtn:SetScript("OnClick", ShowOptionsWindow)
    
        -- Funzione link con icona
    local function CreateLinkButton(parentFrame, text, link, color, yOffset, iconPath)
        local btn = CreateModernButton(parentFrame, text, 180, 35)
        btn:SetPoint("TOP", parentFrame, "TOP", 0, yOffset)

        -- Icona
        if iconPath then
            local icon = btn:CreateTexture(nil, "OVERLAY")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
            icon:SetTexture(iconPath)
            btn.text:ClearAllPoints()
            btn.text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        end

        btn:SetScript("OnClick", function()
            local editBox = ChatEdit_ChooseBoxForSend()
            if not editBox:IsVisible() then ChatEdit_ActivateChat(editBox) end
            editBox:SetText(link)
            editBox:HighlightText()
            editBox:SetFocus()
            DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffFrostSeek:|r Link inserted in chat box! (Ctrl+C to copy)")
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, color.r, color.g, color.b)
            GameTooltip:AddLine("Click to copy link", 1, 1, 1, true)
            GameTooltip:Show()
            self.hoverTex:Show()
            self.text:SetTextColor(color.r, color.g, color.b)
            self.border:SetColorTexture(color.r, color.g, color.b, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self.hoverTex:Hide()
            self.text:SetTextColor(1, 1, 1)
            self.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
        end)
        return btn
    end

    CreateLinkButton(buttonsFrame, "Discord", "https://discord.gg/T5rtyW9yX4", {r=0.345, g=0.396, b=0.949}, -50, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\discord.tga")
    CreateLinkButton(buttonsFrame, "CurseForge", "https://www.curseforge.com/wow/addons/frostseek", {r=0.937, g=0.502, b=0.196}, -90, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\forge.tga")
    CreateLinkButton(buttonsFrame, "GitHub", "https://github.com/ayro-CMD/FrostSeek", {r=0.533, g=0.533, b=0.533}, -130, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\Kjrt.tga")
    CreateLinkButton(buttonsFrame, "BugReport", "https://discord.gg/uvtvKXzbXW", {r=0.863, g=0.078, b=0.235}, -170, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\bug.tga")
    
    self.statusFrame = CreateFrame("Frame", nil, self.frame)
    self.statusFrame:SetSize(550, 80)
    self.statusFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 30)
    
    local statusBg = self.statusFrame:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    statusBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    
    local statusTitle = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusTitle:SetPoint("TOP", self.statusFrame, "TOP", 0, -10)
    statusTitle:SetText("Current Status")
    statusTitle:SetTextColor(1, 1, 1)
    
    self.statusText = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.statusText:SetPoint("TOP", statusTitle, "BOTTOM", 0, -10)
    self.statusText:SetText("LFG: |cFF00FF00Active|r  |  by AYRO")
    self.statusText:SetTextColor(0.9, 0.9, 0.9)
    
    self.frame:Hide()
end

function Options:Show()
    if self.frame then
        if self.statusText then
            local lfgStatus = "|cFF00FF00Active|r"
            if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then lfgStatus = "|cFFFF0000Disabled|r" end
            self.statusText:SetText("LFG: " .. lfgStatus .. "  |  by AYRO")
        end
        self.frame:Show()
    end
end

function Options:Hide()
    if self.frame then self.frame:Hide() end
end

StaticPopupDialogs["FROSTSEEK_CONFIRM_CLEAR_DATA"] = {
    text = "Are you sure you want to clear ALL FrostSeek data?\n\nThis action cannot be undone!",
    button1 = "Yes, Clear All",
    button2 = "Cancel",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
        FrostSeekDB = {
            Settings = { uiScale = 1.0, windowPosition = nil, minimapButton = true, debugMode = false, savePosition = true, autoOpen = false },
            LFG = { myRole = "", silentNotifications = false, frameDuration = 5, disablePopups = false, disableLFG = false, maxMessageLength = 90, popupCooldown = 370, maxConcurrentPopups = 2, doNotAlertInGroup = true, doNotAlertInCombat = true, popupCategories = { ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true, PVP = true, MANASTORM = true, KEYSTONE = true }, customFilterWords = "", showActiveRecruitersWindow = false, customMessages = { enabled = false, template = "hello {class} {ilvl} {ench} dps or healer {keystone}", showClass = true, showIlvl = true, showEnchant = true, showRole = true, showKeystone = false, keystoneLink = "" } },
            LFM = { lastMessages = {}, favoriteTemplates = {}, channelPresets = {}, autoUpdateInterval = 60 },
            QOL = { autoSellGreys = false, autoRepair = false, useGuildRepair = false },
            FriendsNotify = { enabled = true, position = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 10, y = -10 } },
            MPlusScores = {},
        }
        ReloadUI()
    end
}

-- ==================== MODULE REGISTRATION ====================
if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("options", Options)
end
