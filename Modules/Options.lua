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

local Options = {}

local L = FrostSeek.L
local _tc = _G.FrostSeekShared and _G.FrostSeekShared._tc or function(t) return {0.5,0.5,0.5} end

local UI = _G.FrostSeekUIUtils

local settingsWindow = nil
local categoryFrames = {}
local currentCategory = "general"
local previewEventFrame = nil
local keystoneUpdateTicker = nil

local function EnsureSettingsStructure()
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end

    local defaults = {
        uiScale = 1.0,
        autoOpen = false,
        minimapButton = true,
        savePosition = true,
        debugMode = false,
        soundEnabled = true,
        soundPopup = true,
        soundListing = true,
        soundApplicant = true,
    }

    for k, v in pairs(defaults) do
        if FrostSeekDB.Settings[k] == nil then
            FrostSeekDB.Settings[k] = v
        end
    end
end

local function EnsureActivityFilterStructure()
    if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
    if not FrostSeekDB.LFG.activityFilter then
        FrostSeekDB.LFG.activityFilter = {}
    end

    local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
    if LFG and LFG.ACTIVITY_FILTER_GROUPS then
        for _, entry in ipairs(LFG.ACTIVITY_FILTER_GROUPS) do
            if not entry.isHeader and entry.id then
                if FrostSeekDB.LFG.activityFilter[entry.id] == nil then
                    FrostSeekDB.LFG.activityFilter[entry.id] = true
                end
            end
        end
    end
end

local function EnsurePopupCategoriesStructure()
    if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end

    local defaultCategories = {
        ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true,
        PVP = true, MANASTORM = true, KEYSTONE = true, MISC = false
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

local function FindKeystoneInBags()
    local GetContainerNum = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local GetContainerLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
    if not GetContainerNum or not GetContainerLink then return nil end

    for bag = 0, 4 do
        local ok, numSlots = pcall(function() return GetContainerNum(bag) end)
        if not ok then numSlots = 0 end
        for slot = 1, (numSlots or 0) do
            local itemLink
            pcall(function() itemLink = GetContainerLink(bag, slot) end)
            if itemLink and string.find(itemLink, L["cat_keystone"]) then
                return itemLink
            end
        end
    end
    return nil
end

local function GetItemNameFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, itemName = string.find(itemLink, "|h%[(.-)%]|h")
    return itemName or L["cat_keystone"]
end

local function GetPlayerData()
    local classInfo = L["opt_class_unknown"]
    local ilvl = 0
    local enchant = ""
    local roleText = ""

    local Shared = _G.FrostSeekShared
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end
    if classFile then
        local classMap = {
            ["WARRIOR"] = "Warrior", ["PALADIN"] = "Paladin", ["HUNTER"] = "Hunter",
            ["ROGUE"] = "Rogue", ["PRIEST"] = "Priest", ["DEATHKNIGHT"] = "Death Knight",
            ["SHAMAN"] = "Shaman", ["MAGE"] = "Mage", ["WARLOCK"] = "Warlock",
            ["DRUID"] = "Druid",
            ["HERO"] = "Hero",
            ["NECROMANCER"] = "Necromancer", ["PYROMANCER"] = "Pyromancer",
            ["CULTIST"] = "Cultist", ["STARCALLER"] = "Starcaller",
            ["SUNCLERIC"] = "Suncleric", ["TINKER"] = "Tinker",
            ["RUNEMASTER"] = "Runemaster", ["PRIMAALIST"] = "Primaalist",
            ["REAPER"] = "Reaper", ["VENOMANCER"] = "Venomancer",
            ["CHRONOMANCER"] = "Chronomancer", ["BLOODMAGE"] = "Bloodmage",
            ["GUARDIAN"] = "Guardian", ["STORMBRINGER"] = "Stormbringer",
            ["FELSWORN"] = "Felsworn", ["BARBARIAN"] = "Barbarian",
            ["WITCH DOCTOR"] = "Witch Doctor", ["WITCH HUNTER"] = "Witch Hunter",
            ["KNIGHT OF XOROTH"] = "Knight of Xoroth", ["TEMPLAR"] = "Templar",
            ["RANGER"] = "Ranger", ["WILDWALKER"] = "Wildwalker",
            ["SON OF ARUGAL"] = "Son of Arugal",
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

local function CreateModernButton(parent, text, width, height)
    if UI and UI.CreateModernButton then
        local btn = UI.CreateModernButton(parent, width, height, text)
        btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hoverTex:SetAllPoints()
        btn.hoverTex:SetColorTexture(1, 1, 1, 0.05)
        btn.hoverTex:Hide()
        return btn
    end
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(unpack(_tc("bgButton")))

    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    btn.border:SetColorTexture(unpack(_tc("border")))

    btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.hoverTex:SetAllPoints()
    btn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    btn.hoverTex:Hide()

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(_tc("textPrimary")))

    btn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.text:SetTextColor(unpack(_tc("textAccent")))
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)

    btn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.text:SetTextColor(unpack(_tc("textPrimary")))
        self.border:SetColorTexture(unpack(_tc("border")))
    end)

    return btn
end

local function CreateCleanEditBox(parent, width, height, isMultiLine)
    if UI and UI.CreateModernEditBox and not isMultiLine then
        return UI.CreateModernEditBox(parent, width, height)
    end
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
    bg:SetColorTexture(unpack(_tc("bgBlock")))
    bg:SetAllPoints()

    local border = editBox:CreateTexture(nil, "BORDER")
    border:SetColorTexture(unpack(_tc("borderInput")))
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)

    return editBox
end

local function CreateModernCheckbox(parent, text, x, y)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(260)
    frame:SetHeight(25)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local checkbox = CreateFrame("Button", nil, frame)
    checkbox:SetWidth(40)
    checkbox:SetHeight(20)
    checkbox:SetPoint("LEFT", frame, "LEFT", 0, 0)

    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)

    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 0, 0)
    checkbox.border:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", 0, 0)
    checkbox.border:SetColorTexture(0.0, 0.0, 0.0, 0.0)

    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetSize(1, 1)
    checkbox.check:SetPoint("TOPLEFT", checkbox, "TOPLEFT", -100, 100)
    checkbox.check:SetColorTexture(0, 0, 0, 0)
    checkbox.check:Hide()

    checkbox.knob = checkbox:CreateTexture(nil, "ARTWORK")
    checkbox.knob:SetSize(14, 14)
    checkbox.knob:SetPoint("CENTER", checkbox, "LEFT", 10, 0)
    checkbox.knob:SetColorTexture(1.0, 1.0, 1.0, 1.0)

    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetColorTexture(1, 1, 1, 0.15)
    checkbox.highlight:Hide()

    local function UpdateToggle(self)
        if self.checked then
            self.knob:ClearAllPoints()
            self.knob:SetPoint("CENTER", self, "RIGHT", -10, 0)
            self.bg:SetColorTexture(0.15, 0.75, 0.25, 1.0)
            self.knob:SetColorTexture(1.0, 1.0, 1.0, 1.0)
        else
            self.knob:ClearAllPoints()
            self.knob:SetPoint("CENTER", self, "LEFT", 10, 0)
            self.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)
            self.knob:SetColorTexture(1.0, 1.0, 1.0, 1.0)
        end
    end

    checkbox.check.SetShown = function(self, shown)
        checkbox.checked = shown and true or false
        UpdateToggle(checkbox)
    end

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetText(text)
    label:SetTextColor(unpack(_tc("textPrimary")))

    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
    end)

    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)

    checkbox:SetScript("OnClick", function(self)
        self.checked = not self.checked
        UpdateToggle(self)
    end)

    checkbox.checked = false
    UpdateToggle(checkbox)
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
    btn.bg:SetColorTexture(unpack(_tc("bgBlock")))

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(_tc("textMuted")))

    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        self.text:SetTextColor(unpack(_tc("textPrimary")))
    end)

    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpack(_tc("bgBlock")))
        self.text:SetTextColor(unpack(_tc("textMuted")))
    end)

    return btn
end

local function CreateSettingCheckbox(parent)
    local checkbox = CreateFrame("Button", nil, parent)
    checkbox:SetSize(40, 20)

    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)

    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 0, 0)
    checkbox.border:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", 0, 0)
    checkbox.border:SetColorTexture(0.0, 0.0, 0.0, 0.0)

    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetSize(1, 1)
    checkbox.check:SetPoint("TOPLEFT", checkbox, "TOPLEFT", -100, 100)
    checkbox.check:SetColorTexture(0, 0, 0, 0)
    checkbox.check:Hide()

    checkbox.knob = checkbox:CreateTexture(nil, "ARTWORK")
    checkbox.knob:SetSize(14, 14)
    checkbox.knob:SetPoint("CENTER", checkbox, "LEFT", 10, 0)
    checkbox.knob:SetColorTexture(1.0, 1.0, 1.0, 1.0)

    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetColorTexture(1, 1, 1, 0.15)
    checkbox.highlight:Hide()

    checkbox.checked = false

    local function UpdateKnob(self)
        if self.checked then
            self.knob:ClearAllPoints()
            self.knob:SetPoint("CENTER", self, "RIGHT", -10, 0)
            self.bg:SetColorTexture(0.15, 0.75, 0.25, 1.0)
            self.knob:SetColorTexture(1.0, 1.0, 1.0, 1.0)
        else
            self.knob:ClearAllPoints()
            self.knob:SetPoint("CENTER", self, "LEFT", 10, 0)
            self.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)
            self.knob:SetColorTexture(1.0, 1.0, 1.0, 1.0)
        end
    end

    checkbox.check.SetShown = function(self, shown)
        checkbox.checked = shown and true or false
        UpdateKnob(checkbox)
    end

    UpdateKnob(checkbox)

    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
    end)

    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)

    return checkbox
end

local function UpdateCustomPreview(previewText)
    if not previewText then return end

    local classInfo, ilvl, enchant, roleText = GetPlayerData()
    local customMessages = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.customMessages

    if customMessages and customMessages.enabled then
        local message = customMessages.template or "inv {role} {class} {spec} {ilvl} ilvl"

        message = string.gsub(message, "{class}", classInfo or "")
        message = string.gsub(message, "{ilvl}", tostring(ilvl or 0))
        message = string.gsub(message, "{gs}", "")
        message = string.gsub(message, "{ench}", enchant or "")
        message = string.gsub(message, "{spec}", enchant or "")
        message = string.gsub(message, "{role}", roleText or "")
        local playerLevel = UnitLevel("player") or 0
        message = string.gsub(message, "{level}", tostring(playerLevel))

        if customMessages.showKeystone then
            local keystoneLink = FindKeystoneInBags()
            local keystoneName = keystoneLink and (GetItemNameFromLink(keystoneLink) or L["cat_keystone"]) or L["opt_no_keystone_found"]
            message = string.gsub(message, "{keystone}", "[" .. keystoneName .. "]")
            customMessages.keystoneLink = keystoneLink
        else
            message = string.gsub(message, "{keystone}", "")
        end

        message = string.gsub(message, "%s+", " ")
        message = string.gsub(message, "^%s*(.-)%s*$", "%1")

        previewText:SetText(message == "" and L["opt_no_content_selected"] or message)
        previewText:SetTextColor(unpack(_tc("textAccent")))
    else
        previewText:SetText(L["options_custom_disabled"])
        previewText:SetTextColor(unpack(_tc("textMuted")))
    end
end

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

local function CreateCustomMessageTab(parent, scrollContent)
    local frame = CreateFrame("Frame", nil, scrollContent)
    frame:SetSize(500, 700)
    frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText(L["options_custom_whisper"])
    title:SetTextColor(unpack(_tc("textAccent")))

    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetPoint("LEFT", frame, "LEFT", 20, 0)
    desc:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    desc:SetText(L["options_custom_whisper_desc"])
    desc:SetTextColor(unpack(_tc("textMuted")))
    desc:SetJustifyH("LEFT")

    local yOffset = -50

    local previewText
    local templateBox

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

    local templateLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    templateLabel:SetPoint("TOPLEFT", 20, yOffset)
    templateLabel:SetText(L["options_msg_template"])
    templateLabel:SetTextColor(unpack(_tc("textMuted")))

    local varsHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    varsHint:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    varsHint:SetPoint("TOP", frame, "TOP", 0, yOffset + 4)
    varsHint:SetText("")
    varsHint:Hide()
    yOffset = yOffset - 25

    templateBox = CreateCleanEditBox(frame, 460, 50, true)
    templateBox:SetPoint("TOPLEFT", 20, yOffset)
    templateBox:SetText(FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.template or "inv {role} {class} {spec} {ilvl} ilvl")
    templateBox._fskLastClickTime = 0
    pcall(function()
        templateBox:SetScript("OnMouseUp", function(self, button)
            if button ~= "LeftButton" then return end
            local now = GetTime()
            if now - (self._fskLastClickTime or 0) < 0.5 then
                self:HighlightText()
                self._fskLastClickTime = 0
            else
                self._fskLastClickTime = now
            end
        end)
    end)
    templateBox:SetScript("OnTextChanged", function(self)
        FrostSeekDB.LFG.customMessages.template = self:GetText()
        UpdateCustomPreview(previewText)
    end)
    yOffset = yOffset - 30

    local variables = {
        { name = "class",    display = "{class}",    desc = L["opt_var_class_desc"] },
        { name = "ilvl",    display = "{ilvl}",     desc = L["opt_var_ilvl_desc"] },
        { name = "spec",    display = "{spec}",     desc = L["opt_var_spec_desc"] },
        { name = "role",    display = "{role}",     desc = L["opt_var_role_desc"] },
        { name = "level",   display = "{level}",    desc = L["opt_var_level_desc"] },
        { name = "keystone",display = "{keystone}", desc = L["opt_var_keystone_desc"] },
    }

    local btnWidth, btnHeight, btnGap, perRow = 100, 22, 8, 4
    for i, var in ipairs(variables) do
        local rowIdx = math.floor((i - 1) / perRow)
        local colIdx = (i - 1) % perRow
        local x = 20 + colIdx * (btnWidth + btnGap)
        local y = yOffset - rowIdx * (btnHeight + 6)
        local btn = CreateStyledButton(frame, var.display, x, y, btnWidth, btnHeight)
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
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            self.text:SetTextColor(unpack(_tc("textPrimary")))
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(var.display, 1, 1, 1)
            GameTooltip:AddLine(var.desc or L["tip_click_to_insert_template"], 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            self.text:SetTextColor(unpack(_tc("textMuted")))
            GameTooltip:Hide()
        end)
    end
    yOffset = yOffset - (2 * (btnHeight + 6)) - 5

    local keystoneFrame = CreateModernCheckbox(frame, "Auto-detect keystone from bags", 20, yOffset)
    local keystoneCheck = keystoneFrame.checkbox
    keystoneCheck.checked = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.showKeystone or false
    keystoneCheck.check:SetShown(keystoneCheck.checked)
    keystoneCheck:SetScript("OnClick", function(self)
        self.checked = not self.checked
        self.check:SetShown(self.checked)
        FrostSeekDB.LFG.customMessages.showKeystone = self.checked
        UpdateCustomPreview(previewText)
    end)
    yOffset = yOffset - 35

    local previewLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", 20, yOffset)
    previewLabel:SetText(L["options_preview"])
    previewLabel:SetTextColor(unpack(_tc("textMuted")))
    yOffset = yOffset - 25

    local previewFrame = CreateFrame("Frame", nil, frame)
    previewFrame:SetPoint("TOPLEFT", 20, yOffset)
    previewFrame:SetSize(460, 60)
    previewFrame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16})
    previewFrame:SetBackdropColor(unpack(_tc("bgInput")))

    previewText = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewText:SetPoint("TOPLEFT", 10, -8)
    previewText:SetPoint("RIGHT", previewFrame, "RIGHT", -10, 0)
    previewText:SetPoint("BOTTOM", previewFrame, "BOTTOM", 0, -10)
    previewText:SetJustifyH("LEFT")
    previewText:SetJustifyV("TOP")
    yOffset = yOffset - 75

    local resetBtn = CreateModernButton(frame, "Reset to Default", 150, 30)
    resetBtn:SetPoint("TOPLEFT", 20, yOffset)
    resetBtn:SetScript("OnClick", function()
        FrostSeekDB.LFG.customMessages.template = "inv {role} {class} {spec} {ilvl} ilvl"
        templateBox:SetText(FrostSeekDB.LFG.customMessages.template)

        FrostSeekDB.LFG.customMessages.showKeystone = false
        keystoneCheck.checked = false
        keystoneCheck.check:SetShown(false)

        UpdateCustomPreview(previewText)
    end)

    UpdateCustomPreview(previewText)

    frame.previewText = previewText
    frame.templateBox = templateBox

    return frame
end

local function CreateCustomKeywordsTab(parent, scrollContent)
    local frame = CreateFrame("Frame", nil, scrollContent)
    frame:SetSize(530, 800)
    frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText(L["options_custom_keywords"])
    title:SetTextColor(unpack(_tc("textAccent")))

    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText(L["options_keywords_desc"])
    desc:SetTextColor(unpack(_tc("textMuted")))
    desc:SetJustifyH("CENTER")

    if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
    if not FrostSeekDB.LFG.customKeywords then
        FrostSeekDB.LFG.customKeywords = {
            DUNGEON = "", RAID = "", WORLD_BOSS = "",
            PVP = "", MANASTORM = "", KEYSTONE = ""
        }
    end

    if FrostSeekDB.LFG.customKeywords.CUSTOM ~= nil then
        FrostSeekDB.LFG.customKeywords.CUSTOM = nil
    end

    local categories = {
        { id = "DUNGEON", name = L["cat_dungeon"], color = _tc("catDungeon"), desc = L["opt_kw_dungeon_desc"] },
        { id = "RAID", name = L["cat_raid"], color = _tc("catRaid"), desc = L["opt_kw_raid_desc"] },
        { id = "WORLD_BOSS", name = L["cat_world_boss"], color = _tc("catWorldBoss"), desc = L["opt_kw_world_boss_desc"] },
        { id = "PVP", name = "PvP", color = _tc("catPvP"), desc = L["opt_kw_pvp_desc"] },
        { id = "MANASTORM", name = L["cat_manastorm"], color = _tc("catMana"), desc = L["opt_kw_manastorm_desc"] },
        { id = "KEYSTONE", name = L["cat_keystone"], color = _tc("catKeystone"), desc = L["opt_kw_keystone_desc"] },
        { id = "MISC", name = L["cat_misc"], color = _tc("catMisc"), desc = L["opt_kw_misc_desc"] },
    }

    local yOffset = -80

    local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
    local function GetDefaultKeywordsForCategory(catId)
        local catLower = string.upper(catId)
        local headerHints = {
            DUNGEON = { "DUNGEONS" },
            RAID = { "RAIDS" },
            WORLD_BOSS = { "WORLD BOSSES" },
            PVP = { "PVP" },
            MANASTORM = { "MANASTORM" },
            KEYSTONE = { "KEYSTONE" },
            MISC = { "MISC" },
        }
        local wantedHeaders = headerHints[catLower] or {}
        local result = {}
        if not LFG or not LFG.ACTIVITY_FILTER_GROUPS then return result end
        local inMatch = false
        for _, entry in ipairs(LFG.ACTIVITY_FILTER_GROUPS) do
            if entry.isHeader then
                inMatch = false
                for _, h in ipairs(wantedHeaders) do
                    if string.find(string.upper(entry.header), h, 1, true) then
                        inMatch = true
                        break
                    end
                end
            elseif inMatch and entry.keywords then
                for _, kw in ipairs(entry.keywords) do
                    table.insert(result, kw)
                end
            end
        end
        return result
    end

    for _, cat in ipairs(categories) do

        local defaultKeywords = GetDefaultKeywordsForCategory(cat.id)
        local defaultsLine = ""
        if #defaultKeywords > 0 then
            local shown = {}
            for i = 1, math.min(#defaultKeywords, 8) do
                table.insert(shown, defaultKeywords[i])
            end
            defaultsLine = table.concat(shown, ", ")
            if #defaultKeywords > 8 then
                defaultsLine = defaultsLine .. ", ..."
            end
        else
            defaultsLine = "(none)"
        end
        local catFrameHeight = 90

        local catFrame = CreateFrame("Frame", nil, frame)
        catFrame:SetSize(510, catFrameHeight)
        catFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)

        local accentBar = catFrame:CreateTexture(nil, "BACKGROUND")
        accentBar:SetPoint("TOPLEFT", 0, 0)
        accentBar:SetSize(3, catFrameHeight)
        accentBar:SetColorTexture(cat.color[1], cat.color[2], cat.color[3], 0.8)

        local catBg = catFrame:CreateTexture(nil, "BACKGROUND")
        catBg:SetPoint("TOPLEFT", 3, 0)
        catBg:SetPoint("BOTTOMRIGHT", 0, 0)
        catBg:SetColorTexture(unpack(_tc("bgSection")))

        local catLabel = catFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        catLabel:SetPoint("TOPLEFT", 14, -8)
        catLabel:SetText(cat.name)
        catLabel:SetTextColor(cat.color[1], cat.color[2], cat.color[3])

        local catDesc = catFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        catDesc:SetPoint("TOPLEFT", 14, -25)
        catDesc:SetPoint("RIGHT", catFrame, "RIGHT", -10, 0)
        catDesc:SetText(cat.desc)
        catDesc:SetTextColor(unpack(_tc("textDim")))
        catDesc:SetJustifyH("LEFT")

        local defaultsLabel = catFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        defaultsLabel:SetPoint("TOPLEFT", 14, -42)
        defaultsLabel:SetPoint("RIGHT", catFrame, "RIGHT", -10, 0)
        defaultsLabel:SetText(L["lbl_default_prefix"] .. defaultsLine)
        defaultsLabel:SetTextColor(unpack(_tc("textDim")))
        defaultsLabel:SetJustifyH("LEFT")
        defaultsLabel:SetWordWrap(true)
        defaultsLabel:SetHeight(16)

        local editBox = CreateCleanEditBox(catFrame, 480, 26)
        editBox:SetPoint("TOPLEFT", 14, -62)
        editBox:SetPoint("RIGHT", catFrame, "RIGHT", -10, 0)
        editBox:SetText(FrostSeekDB.LFG.customKeywords[cat.id] or "")
        editBox._fskLastClickTime = 0
        pcall(function()
            editBox:SetScript("OnMouseUp", function(self, button)
                if button ~= "LeftButton" then return end
                local now = GetTime()
                if now - (self._fskLastClickTime or 0) < 0.5 then
                    self:HighlightText()
                    self._fskLastClickTime = 0
                else
                    self._fskLastClickTime = now
                end
            end)
        end)

        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)

        editBox:SetScript("OnTextChanged", function(self)
            FrostSeekDB.LFG.customKeywords[cat.id] = self:GetText() or ""
        end)

        catFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetText(cat.name .. L["tip_default_keywords_suffix"], 1, 1, 1)
            if #defaultKeywords > 0 then
                local line = ""
                local count = 0
                for _, kw in ipairs(defaultKeywords) do
                    if count == 6 then
                        GameTooltip:AddLine(line, 0.8, 0.8, 0.8, false)
                        line = kw
                        count = 1
                    else
                        if line == "" then line = kw else line = line .. ", " .. kw end
                        count = count + 1
                    end
                end
                if line ~= "" then
                    GameTooltip:AddLine(line, 0.8, 0.8, 0.8, false)
                end
            else
                GameTooltip:AddLine(L["tip_no_default_keywords"], 0.6, 0.6, 0.6, false)
            end
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["tip_custom_kw_match"], 0.6, 0.8, 1, true)
            GameTooltip:Show()
        end)
        catFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        yOffset = yOffset - (catFrameHeight + 10)
    end

    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    infoText:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    infoText:SetHeight(60)
    infoText:SetText(L["txt_custom_kw_tip"])
    infoText:SetTextColor(unpack(_tc("textDim")))
    infoText:SetJustifyH("LEFT")
    infoText:SetWordWrap(true)

    yOffset = yOffset - 70

    local resetBtn = CreateModernButton(frame, "Reset All Custom Keywords", 230, 32)
    resetBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, yOffset)
    resetBtn:SetScript("OnClick", function()
        for _, cat in ipairs(categories) do
            FrostSeekDB.LFG.customKeywords[cat.id] = ""
        end
        print(L["msg_all_kw_reset"])
    end)

    return frame
end

local function GetSettingsCategories()
    return {
    { id = "general", name = L["options_general"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\generale.tga", settings = {
        { type = "header", id = "generalHeader", name = "", desc = L["options_basic_config"] },
        { type = "checkbox", id = "frostnetEnabled", name = L["options_enable_frostnet"], desc = L["options_enable_frostnet_desc"], default = true, getter = function() return FrostSeekDB.Settings.frostnetEnabled ~= false end, setter = function(v) FrostSeekDB.Settings.frostnetEnabled = v; local net = _G.FrostSeek and _G.FrostSeek.Network; if net then if v then net:JoinChannel() else net:LeaveChannel() end end; print("|cff88ccffFrostNet:|r " .. (v and "|cff44ff44" .. L["enabled"] .. "|r" or "|cffff5555" .. L["disabled"] .. "|r")) end },
        { type = "checkbox", id = "autoOpen", name = L["options_auto_open"], desc = L["options_auto_open_desc"], default = false, getter = function() return FrostSeekDB.Settings.autoOpen end, setter = function(v) FrostSeekDB.Settings.autoOpen = v print(string.format(L["msg_auto_open_status"], v and L["enabled"] or L["disabled"])) end },
        { type = "checkbox", id = "minimapButton", name = L["minimap_show"], desc = L["options_minimap_button_desc"], default = true, getter = function() return FrostSeekDB.Settings.minimapButton end, setter = function(v) FrostSeekDB.Settings.minimapButton = v local mb = _G["FrostSeekMiniMapButton"]; if mb and mb.SetShown then mb:SetShown(v) end end },
        { type = "checkbox", id = "savePosition", name = L["options_save_position"], desc = L["options_save_position_desc"], default = true, getter = function() return FrostSeekDB.Settings.savePosition end, setter = function(v) FrostSeekDB.Settings.savePosition = v end },
        { type = "checkbox", id = "debugMode", name = L["options_debug_mode"], desc = L["options_debug_mode_desc"], default = false, getter = function() return FrostSeekDB.Settings.debugMode end, setter = function(v) FrostSeekDB.Settings.debugMode = v end },
        { type = "dropdown", id = "language", name = L["settings_language"], desc = L["settings_language_desc"], default = "auto",
          options = function()
              local codes = {}
              if FrostSeek and FrostSeek.GetAvailableLocales then
                  codes = FrostSeek.GetAvailableLocales()
              else
                  codes = { "enUS" }
              end
              local result = { "auto" }
              for _, c in ipairs(codes) do table.insert(result, c) end
              return result
          end,
          getter = function() return FrostSeekDB.Settings.language or "auto" end,
          setter = function(v)
              FrostSeekDB.Settings.language = v
              print("|cff88ccffFrostSeek:|r " .. L["settings_language_set"]:format(tostring(v)))
              local msg = L["settings_language_changed"]:format(tostring(v))
              if FrostSeek and FrostSeek.PromptReloadUI then
                  FrostSeek.PromptReloadUI(msg)
              end
          end },
        { type = "dropdown", id = "logLevel", name = L["settings_log_level"], desc = L["settings_log_level_desc"], default = "WARN",
          options = function() return { "DEBUG", "INFO", "WARN", "ERROR" } end,
          getter = function() return FrostSeekDB.Settings.logLevel or "WARN" end,
          setter = function(v)
              FrostSeekDB.Settings.logLevel = v
              if FrostSeek and FrostSeek.Logger then
                  FrostSeek.Logger.Level = v
              end
              print(L["msg_log_level_set"] .. tostring(v))
          end },
        { type = "slider", id = "uiScale", name = L["options_ui_scale"], desc = L["options_ui_scale_desc"], min = 0.5, max = 1.5, step = 0.05, default = 1.0, getter = function() return FrostSeekDB.Settings.uiScale end, setter = function(v) FrostSeekDB.Settings.uiScale = v if FrostSeek.MainFrame then FrostSeek.MainFrame:SetScale(v) end end },
        { type = "dropdown", id = "serverProfile", name = L["options_server_profile"], desc = L["options_server_profile_desc"], default = "auto",
          options = function() return { "auto", "classic", "tbc", "wotlk", "cata", "mop", "ascension", "epoch" } end,
          getter = function() return FrostSeekDB.Settings.serverProfile or "auto" end,
          setter = function(v)
              FrostSeekDB.Settings.serverProfile = v
              FrostSeekDB.Settings.serverProfileManual = (v ~= "auto")
              if FrostSeek and FrostSeek.PromptReloadUI then
                  local msg = string.format(L["msg_server_profile_changed"], tostring(v))
                  FrostSeek.PromptReloadUI(msg)
              end
          end },
    }},
    { id = "lfg", name = L["options_lfg"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\exp.tga", settings = {
        { type = "header", id = "lfgHeader", name = "", desc = L["lfg_title"] },
        { type = "checkbox", id = "disableLFG", name = L["options_disable_lfg"], desc = L["options_disable_lfg_desc"], default = false, getter = function() return FrostSeekDB.LFG.disableLFG end, setter = function(v) FrostSeekDB.LFG.disableLFG = v; local lfg = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg; if lfg and lfg.UpdateToggleVisual then lfg.UpdateToggleVisual(not v) end; if _G.FrostSeek and _G.FrostSeek.UpdateMinimapDisabledOverlay then _G.FrostSeek.UpdateMinimapDisabledOverlay() end end },
        { type = "checkbox", id = "silentNotifications", name = L["lfg_silent_notifications"], desc = L["options_silent_notifications_desc"], default = false, getter = function() return FrostSeekDB.LFG.silentNotifications end, setter = function(v) FrostSeekDB.LFG.silentNotifications = v end },
        { type = "checkbox", id = "doNotAlertInGroup", name = L["lfg_no_alerts_group"], desc = L["options_no_alerts_group_desc"], default = false, getter = function() return FrostSeekDB.LFG.doNotAlertInGroup end, setter = function(v) FrostSeekDB.LFG.doNotAlertInGroup = v end },
        { type = "checkbox", id = "doNotAlertInCombat", name = L["lfg_no_alerts_combat"], desc = L["options_no_alerts_combat_desc"], default = false, getter = function() return FrostSeekDB.LFG.doNotAlertInCombat end, setter = function(v) FrostSeekDB.LFG.doNotAlertInCombat = v end },
        { type = "slider", id = "frameDuration", name = L["lfg_popup_duration"], desc = L["options_popup_duration_desc"], min = 2, max = 10, step = 1, default = 5, getter = function() return FrostSeekDB.LFG.frameDuration end, setter = function(v) FrostSeekDB.LFG.frameDuration = v end },
        { type = "slider", id = "popupCooldown", name = L["lfg_popup_cooldown"], desc = L["options_popup_cooldown_desc"], min = 60, max = 600, step = 10, default = 370, getter = function() return FrostSeekDB.LFG.popupCooldown end, setter = function(v) FrostSeekDB.LFG.popupCooldown = v end },
        { type = "slider", id = "maxConcurrentPopups", name = L["lfg_max_popups"], desc = L["options_max_popups_desc"], min = 1, max = 5, step = 1, default = 2, getter = function() return FrostSeekDB.LFG.maxConcurrentPopups end, setter = function(v) FrostSeekDB.LFG.maxConcurrentPopups = v end },
        { type = "header", id = "keystoneFilterHeader", name = "", desc = L["options_keystone_filter"] },
        { type = "slider", id = "keystoneMinLevel", name = L["options_keystone_min_level"], desc = L["options_keystone_min_level_desc"], min = 0, max = 30, step = 1, default = 0, getter = function() return FrostSeekDB.LFG.keystoneMinLevel or 0 end, setter = function(v) FrostSeekDB.LFG.keystoneMinLevel = tonumber(v) or 0; local lfg = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg; if lfg and lfg.keystoneMinBox then lfg.keystoneMinBox:SetText(tostring(FrostSeekDB.LFG.keystoneMinLevel)) end; if lfg and lfg.UpdateRecruitersList then lfg.UpdateRecruitersList() end end },
        { type = "header", id = "chatFilterHeader", name = "", desc = L["options_chat_filter"] },
        { type = "checkbox", id = "chatFilterEnabled", name = L["options_chat_filter_enabled"], desc = L["options_chat_filter_enabled_desc"], default = false, getter = function() return FrostSeekDB.LFG.chatFilterEnabled end, setter = function(v) FrostSeekDB.LFG.chatFilterEnabled = v end },
        { type = "editbox", id = "chatFilterKeywords", name = L["options_chat_filter_keywords"], desc = L["options_chat_filter_keywords_desc"], getter = function() return FrostSeekDB.LFG.chatFilterKeywords or "" end, setter = function(v) FrostSeekDB.LFG.chatFilterKeywords = tostring(v or "") end },
    }},
    { id = "activityfilter", name = L["options_activity_filter"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\filtri.tga", settings = {
        { type = "header", id = "activityFilterHeader", desc = L["options_activity_filter_desc"] },
        { type = "activityfilter", id = "activityFilterCheckboxes" }
    }},
    { id = "custommessage", name = L["options_custom_whisper"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\lfgwisp.tga", settings = {} },
    { id = "customkeywords", name = L["options_custom_tags"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\tag.tga", settings = {} },
    { id = "lfm", name = L["options_lfm"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\lfm.tga", settings = {
        { type = "header", id = "lfmHeader", name = "", desc = L["options_lfm_header_desc"] },
        { type = "slider", id = "autoUpdateInterval", name = L["options_auto_update_interval"], desc = L["options_auto_update_interval_desc"], min = 0, max = 300, step = 10, default = 60, getter = function() return FrostSeekDB.LFM.autoUpdateInterval end, setter = function(v) FrostSeekDB.LFM.autoUpdateInterval = v if FrostSeek.Modules and FrostSeek.Modules.lfm and FrostSeek.Modules.lfm.UpdateAutoUpdateInterval then FrostSeek.Modules.lfm:UpdateAutoUpdateInterval() end end },
        { type = "header", id = "autoSpamHeader", name = "", desc = L["options_auto_spam_header_desc"] },
        { type = "slider", id = "autoSpamInterval", name = L["options_spam_timer"], desc = L["options_spam_timer_desc"], min = 5, max = 300, step = 5, default = 30, getter = function() return FrostSeekDB.LFM.autoSpamInterval or 30 end, setter = function(v) FrostSeekDB.LFM.autoSpamInterval = v end },
        { type = "dropdown", id = "autoStopMemberCount", name = L["options_lfm_auto_stop"], desc = L["options_lfm_auto_stop_desc"], default = 0,
          options = function() return { 0, 5, 10, 15, 20, 25, 40 } end,
          getter = function() return FrostSeekDB.LFM.autoStopMemberCount or 0 end,
          setter = function(v)
              FrostSeekDB.LFM.autoStopMemberCount = tonumber(v) or 0
              print(L["msg_auto_stop_threshold_set"] .. tostring(v))
          end },
        { type = "header", id = "autoInviteHeader", name = "", desc = L["options_auto_invite_header_desc"] },
        { type = "checkbox", id = "autoInviteEnabled", name = L["options_enable_auto_invite"], desc = L["options_enable_auto_invite_desc"], default = false, getter = function() return FrostSeekDB.LFM.autoInviteEnabled or false end, setter = function(v) FrostSeekDB.LFM.autoInviteEnabled = v print(string.format(L["msg_auto_invite_status"], v and L["enabled"] or L["disabled"])) end },
        { type = "slider", id = "autoInviteMinIlvl", name = L["options_auto_invite_min_ilvl"], desc = L["opt_auto_invite_min_ilvl_long_desc"], min = 0, max = 500, step = 5, default = 0,
          getter = function()
              local v = FrostSeekDB.LFM.autoInviteMinIlvl
              if v == nil or v == 0 then
                  local function PlayerIlvl()
                      local sum, count = 0, 0
                      for i = 1, 17 do
                          if i ~= 4 then
                              local link = GetInventoryItemLink("player", i)
                              if link then
                                  local _, _, _, ilvl = GetItemInfo(link)
                                  if ilvl then sum = sum + ilvl; count = count + 1 end
                              end
                          end
                      end
                      return count > 0 and math.floor((sum / count) + 0.5) or 0
                  end
                  local pi = PlayerIlvl()
                  if pi > 0 then return math.max(0, pi - 5) end
                  local function GetExp()
                      local ok, lvl = pcall(function() return GetAccountExpansionLevel and GetAccountExpansionLevel() end)
                      if not ok or type(lvl) ~= "number" then return 0 end
                      return lvl
                  end
                  local exp = GetExp()
                  local expFloor = { [0]=60, [1]=70, [2]=80, [3]=85, [4]=90, [5]=100, [6]=110, [7]=120, [8]=130 }
                  return expFloor[exp] or 100
              end
              return v
          end,
          setter = function(v)
              FrostSeekDB.LFM.autoInviteMinIlvl = v
              print(L["msg_min_ilvl_set"] .. tostring(v) .. (v == 0 and " (auto: player ilvl - 5)" or ""))
          end },
        { type = "button", id = "resetSpamChannels", name = L["options_reset_spam_channels"], desc = L["opt_reset_spam_channels_desc"], onClick = function() if FrostSeekDB.LFM.spamChannels then wipe(FrostSeekDB.LFM.spamChannels) end print(L["msg_spam_channels_reset"]) end }
    }},
    { id = "popupcategories", name = L["options_popup_categories"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\popupcategorie.tga", settings = {
        { type = "header", id = "popupCategoriesHeader", name = "", desc = L["opt_popup_categories_desc"] },
        { type = "checkbox", id = "enablePopups", name = L["opt_enable_popups"], desc = L["opt_enable_popups_desc"], default = false,
          getter = function() return not FrostSeekDB.LFG.disablePopups end,
          setter = function(v) FrostSeekDB.LFG.disablePopups = not v; if _G.FrostSeek and _G.FrostSeek.UpdateMinimapDisabledOverlay then _G.FrostSeek.UpdateMinimapDisabledOverlay() end end },
        { type = "checkbox", id = "popupShowLFG", name = L["options_popup_show_lfg"], desc = L["options_popup_show_lfg_desc"], default = true,
          getter = function() return FrostSeekDB.LFG.popupShowLFG ~= false end,
          setter = function(v)
              FrostSeekDB.LFG.popupShowLFG = v and true or false
              if (not (FrostSeekDB.LFG.popupShowLFG ~= false)) and (not (FrostSeekDB.LFG.popupShowLFM ~= false)) then
                  FrostSeekDB.LFG.popupShowLFM = true
              end
          end },
        { type = "checkbox", id = "popupShowLFM", name = L["options_popup_show_lfm"], desc = L["options_popup_show_lfm_desc"], default = true,
          getter = function() return FrostSeekDB.LFG.popupShowLFM ~= false end,
          setter = function(v)
              FrostSeekDB.LFG.popupShowLFM = v and true or false
              if (not (FrostSeekDB.LFG.popupShowLFG ~= false)) and (not (FrostSeekDB.LFG.popupShowLFM ~= false)) then
                  FrostSeekDB.LFG.popupShowLFG = true
              end
          end },
        { type = "category", id = "popupCategories", name = L["opt_enable_popups_for"], categories = {
            { id = "ALL", name = L["cat_all"], desc = L["opt_enable_popups_for_desc"] },
            { id = "DUNGEON", name = L["cat_dungeon"], desc = L["opt_popups_dungeons_desc"] },
            { id = "RAID", name = L["cat_raid"], desc = L["opt_popups_raids_desc"] },
            { id = "WORLD_BOSS", name = L["cat_world_boss"], desc = L["opt_popups_world_bosses_desc"] },
            { id = "PVP", name = "PvP", desc = L["opt_popups_pvp_desc"] },
            { id = "MANASTORM", name = L["cat_manastorm"], desc = L["opt_popups_manastorm_desc"] },
            { id = "KEYSTONE", name = L["cat_keystone"], desc = L["opt_popups_keystone_desc"] },
        }, getter = function(catId)
            if catId == "ALL" then
                if FrostSeekDB.LFG.popupCategories.ALL ~= nil then return FrostSeekDB.LFG.popupCategories.ALL end
                local anyIndiv = false
                for id, val in pairs(FrostSeekDB.LFG.popupCategories) do
                    if id ~= "ALL" and val then anyIndiv = true; break end
                end
                return not anyIndiv
            end
            if FrostSeekDB.LFG.popupCategories.ALL then return true end
            return FrostSeekDB.LFG.popupCategories[catId] or false
        end,
        setter = function(catId, value)
            if catId == "ALL" then
                FrostSeekDB.LFG.popupCategories.ALL = value
                if value then
                    for id, _ in pairs(FrostSeekDB.LFG.popupCategories) do
                        if id ~= "ALL" then FrostSeekDB.LFG.popupCategories[id] = false end
                    end
                else
                    for id, _ in pairs(FrostSeekDB.LFG.popupCategories) do
                        if id ~= "ALL" then FrostSeekDB.LFG.popupCategories[id] = false end
                    end
                end
            else
                if FrostSeekDB.LFG.popupCategories.ALL then
                    for id, _ in pairs(FrostSeekDB.LFG.popupCategories) do
                        if id ~= "ALL" then FrostSeekDB.LFG.popupCategories[id] = false end
                    end
                    FrostSeekDB.LFG.popupCategories.ALL = false
                end
                FrostSeekDB.LFG.popupCategories[catId] = value
                if not value then
                    local anyActive = false
                    for id, val in pairs(FrostSeekDB.LFG.popupCategories) do
                        if id ~= "ALL" and val then anyActive = true; break end
                    end
                    if not anyActive then FrostSeekDB.LFG.popupCategories.ALL = true end
                end
            end
        end },
        { type = "button", id = "popupInfo", name = L["options_how_popups_work"], desc = L["opt_how_popups_work_desc"], onClick = function()
            if StaticPopupDialogs and StaticPopupDialogs["FROSTSEEK_POPUP_INFO"] then
                StaticPopup_Show("FROSTSEEK_POPUP_INFO")
            end
        end, onEnter = function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["options_how_popups_work"], 1, 1, 1)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["tip_popups_all_selected"], 0.8, 0.9, 1, true)
            GameTooltip:AddLine(L["tip_popups_all_fire"], 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["tip_popups_single_selected"], 0.8, 0.9, 1, true)
            GameTooltip:AddLine(L["tip_popups_single_explain"], 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["tip_popups_none_selected"], 0.8, 0.9, 1, true)
            GameTooltip:AddLine(L["tip_popups_none_explain"], 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        end },
        { type = "header", id = "popupAnchorHeader", name = "", desc = L["options_popup_anchor_desc"] },
        { type = "button", id = "popupAnchorUnlock", name = L["options_popup_anchor_unlock"], desc = L["options_popup_anchor_desc"], onClick = function()
            local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
            if LFG and LFG.SetPopupUnlockMode then
                LFG.SetPopupUnlockMode(true)
            else
                print(L["msg_lfg_module_not_loaded"])
            end
        end },
        { type = "button", id = "popupAnchorReset", name = L["options_popup_anchor_reset"], desc = L["options_popup_anchor_desc"], onClick = function()
            local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
            if LFG and LFG.ResetPopupAnchor then
                LFG.ResetPopupAnchor()
            end
        end }
    }},
    { id = "sounds", name = L["options_sound"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\generale.tga", settings = {
        { type = "header", id = "soundsHeader", name = "", desc = L["opt_sound_notifications_desc"] },
        { type = "checkbox", id = "soundEnabled", name = L["options_enable_sounds"], desc = L["opt_enable_sounds_desc"], default = true, isMaster = true, getter = function() return FrostSeekDB.Settings.soundEnabled ~= false end, setter = function(v) FrostSeekDB.Settings.soundEnabled = v end },
        { type = "checkbox", id = "soundPopup", name = L["sound_popup"], desc = L["opt_sound_popup_desc"], default = true,
          master = { getter = function() return FrostSeekDB.Settings.soundEnabled ~= false end },
          getter = function() return FrostSeekDB.Settings.soundPopup ~= false end, setter = function(v) FrostSeekDB.Settings.soundPopup = v end },
        { type = "checkbox", id = "soundListing", name = L["opt_new_listing_sound"], desc = L["opt_new_listing_sound_desc"], default = true,
          master = { getter = function() return FrostSeekDB.Settings.soundEnabled ~= false end },
          getter = function() return FrostSeekDB.Settings.soundListing ~= false end, setter = function(v) FrostSeekDB.Settings.soundListing = v end },
        { type = "checkbox", id = "soundApplicant", name = L["sound_applicant"], desc = L["opt_sound_applicant_desc"], default = true,
          master = { getter = function() return FrostSeekDB.Settings.soundEnabled ~= false end },
          getter = function() return FrostSeekDB.Settings.soundApplicant ~= false end, setter = function(v) FrostSeekDB.Settings.soundApplicant = v end },
    }},
    { id = "advanced", name = L["options_advanced"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\avanzato.tga", settings = {
        { type = "header", id = "advancedHeader", name = "", desc = L["opt_advanced_desc"] },
        { type = "button", id = "resetPosition", name = L["options_reset_position"], desc = L["opt_reset_position_desc"], onClick = function() FrostSeekDB.Settings.windowPosition = nil; if FrostSeek.MainFrame then FrostSeek.MainFrame:ClearAllPoints(); FrostSeek.MainFrame:SetPoint("CENTER") end print(L["msg_window_positions_reset"]) end },
        { type = "button", id = "resetSessionStats", name = L["opt_reset_session_stats"], desc = L["opt_reset_session_stats_desc"], onClick = function()
            FrostSeekDB.SessionStats = {
                listingsCreated = 0,
                applicantsReceived = 0,
                applicantsAccepted = 0,
                applicantsDeclined = 0,
                applicationsSent = 0,
                applicationsAccepted = 0,
                peakOnline = 0,
                sessionStart = time(),
            }
            print(L["msg_session_stats_reset"])
        end },
        { type = "button", id = "clearFavorites", name = L["opt_clear_favorites"], desc = L["opt_clear_favorites_desc"], onClick = function()
            local Shared = _G.FrostSeekShared
            if Shared and Shared.ConfirmDialog then
                Shared.ConfirmDialog(L["confirm_clear_favorites_title"], L["confirm_clear_favorites_msg"], function()
                    FrostSeekDB.Favorites = {}
                    print(L["msg_favorites_cleared"])
                end)
            else
                FrostSeekDB.Favorites = {}
                print(L["msg_favorites_cleared"])
            end
        end },
        { type = "button", id = "listFavorites", name = L["opt_list_favorites"], desc = L["opt_list_favorites_desc"], onClick = function()
            local count = 0
            if FrostSeekDB.Favorites then
                for name, _ in pairs(FrostSeekDB.Favorites) do
                    count = count + 1
                end
            end
            if count == 0 then
                print(L["msg_no_favorites_set"])
            else
                print(L["msg_favorites_header"])
                for name, _ in pairs(FrostSeekDB.Favorites) do
                    local online = _G.FrostSeek and _G.FrostSeek.Presence and _G.FrostSeek.Presence.onlineUsers and _G.FrostSeek.Presence.onlineUsers[name] ~= nil
                    local status = online and " |cff44ff44online|r" or " |cff888888offline|r"
                    print("  |cffb366ff*|r " .. name .. status)
                end
            end
        end },
        { type = "button", id = "clearAllData", name = L["clear_all_data"], desc = L["opt_clear_all_data_desc"], warning = L["msg_warning_cannot_undo"], onClick = function()
            local Shared = _G.FrostSeekShared
            if Shared and Shared.ConfirmDialog then
                Shared.ConfirmDialog(L["clear_all_data"], L["msg_clear_all_data_warning"], function()
                    FrostSeekDB = {
                        Settings = { uiScale = 1.0, windowPosition = nil, minimapButton = true, debugMode = false, savePosition = true, autoOpen = false, soundEnabled = true, soundPopup = true, soundListing = true, soundApplicant = true },
                        LFG = { myRole = "", silentNotifications = false, frameDuration = 5, disablePopups = true, disableLFG = false, maxMessageLength = 90, popupCooldown = 370, maxConcurrentPopups = 2, doNotAlertInGroup = true, doNotAlertInCombat = true, popupCategories = { ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true, PVP = true, MANASTORM = true, KEYSTONE = true, MISC = false }, popupShowLFG = true, popupShowLFM = true, customFilterWords = "", showActiveRecruitersWindow = false, customMessages = { enabled = false, template = "inv {role} {class} {spec} {ilvl} ilvl", showClass = true, showIlvl = true, showEnchant = true, showSpec = true, showRole = true, showLevel = true, showKeystone = false, keystoneLink = "" } },
                        LFM = { lastMessages = {}, favoriteTemplates = {}, channelPresets = {}, autoUpdateInterval = 60, autoInviteMinIlvl = 0 },
                    }
                    ReloadUI()
                end)
            end
        end }
    }},
    { id = "theme", name = L["options_theme"], icon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\sistema.tga", settings = {
        { type = "themeselector", id = "themeSelector", name = L["options_select_theme_label"], desc = L["opt_select_theme_desc"] },
    }}
}
end

local function CreateSettingControl(parent, setting, yOffset)
    if setting.id == "debugMode" and not FrostSeekDB.Settings.debugMode then return nil, 0 end

    if setting.type == "frostnetrole" then
        local roleFrame = CreateFrame("Frame", nil, parent)
        roleFrame:SetSize(540, 60)
        roleFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset - 10)

        local roleLabel = roleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        roleLabel:SetPoint("TOPLEFT", roleFrame, "TOPLEFT", 0, 0)
        roleLabel:SetText(setting.name or L["lfg_role"])
        roleLabel:SetTextColor(unpack(_tc("textPrimary")))

        local EnsureProfile = function()
            if not FrostSeekDB then FrostSeekDB = {} end
            if not FrostSeekDB.Profile then FrostSeekDB.Profile = { role = "", spec = "", discord = false, note = "", autoFill = true, autoIlvl = 0 } end
            return FrostSeekDB.Profile
        end

        local roles = { "Tank", "Healer", "DPS" }
        local roleColors = { Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555" }
        local roleButtons = {}

        for i, role in ipairs(roles) do
            local btn = CreateFrame("Button", nil, roleFrame)
            btn:SetSize(90, 26)
            btn:SetPoint("TOPLEFT", roleFrame, "TOPLEFT", (i - 1) * 100, -22)

            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
            btn.bg:SetColorTexture(unpack(_tc("bgButton")))

            btn.border = btn:CreateTexture(nil, "BORDER")
            btn.border:SetAllPoints()
            btn.border:SetColorTexture(unpack(_tc("border")))

            btn.accent = btn:CreateTexture(nil, "OVERLAY")
            btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
            btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
            btn.accent:SetHeight(2)
            btn.accent:SetColorTexture(unpack(_tc("accentBar")))

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("CENTER")
            btn.text:SetText(roleColors[role] .. role .. "|r")
            btn.text:SetTextColor(unpack(_tc("textMuted")))

            btn.roleName = role

            local function UpdateRoleVisuals()
                local p = EnsureProfile()
                for r, b in pairs(roleButtons) do
                    if r == p.role then
                        b.bg:SetColorTexture(unpack(_tc("bgTabActive")))
                        b.border:SetColorTexture(unpack(_tc("borderFocus")))
                        b.accent:SetColorTexture(unpack(_tc("accentFocus")))
                        b.text:SetTextColor(unpack(_tc("textPrimary")))
                    else
                        b.bg:SetColorTexture(unpack(_tc("bgButton")))
                        b.border:SetColorTexture(unpack(_tc("border")))
                        b.accent:SetColorTexture(unpack(_tc("accentBar")))
                        b.text:SetTextColor(unpack(_tc("textMuted")))
                    end
                end
            end

            btn:SetScript("OnClick", function(self)
                local p = EnsureProfile()
                p.role = self.roleName
                UpdateRoleVisuals()
                local Profile = _G.FrostSeek and _G.FrostSeek.Profile
                if Profile then
                    if Profile.UpdateRoleButtons then Profile:UpdateRoleButtons() end
                    if Profile.UpdateAutoInfo then Profile:UpdateAutoInfo() end
                end
                print(L["msg_role_set_to"] .. roleColors[self.roleName] .. self.roleName .. "|r")
            end)

            btn:SetScript("OnEnter", function(self)
                self.border:SetColorTexture(unpack(_tc("borderHover")))
                self.text:SetTextColor(unpack(_tc("textAccent")))
            end)

            btn:SetScript("OnLeave", function(self)
                local p = EnsureProfile()
                if self.roleName == p.role then
                    self.border:SetColorTexture(unpack(_tc("borderFocus")))
                    self.text:SetTextColor(unpack(_tc("textPrimary")))
                else
                    self.border:SetColorTexture(unpack(_tc("border")))
                    self.text:SetTextColor(unpack(_tc("textMuted")))
                end
            end)

            roleButtons[role] = btn
        end

        local p = EnsureProfile()
        for r, b in pairs(roleButtons) do
            if r == p.role then
                b.bg:SetColorTexture(unpack(_tc("bgTabActive")))
                b.border:SetColorTexture(unpack(_tc("borderFocus")))
                b.accent:SetColorTexture(unpack(_tc("accentFocus")))
                b.text:SetTextColor(unpack(_tc("textPrimary")))
            end
        end

        return roleFrame, -70
    end

    local controlFrame = CreateFrame("Frame", nil, parent)
    controlFrame:SetSize(500, 50)
    controlFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

    local nameLabel = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", controlFrame, "LEFT", 0, 0)
    nameLabel:SetText(setting.name or "")
    nameLabel:SetTextColor(unpack(_tc("textPrimary")))
    if setting.type == "category" then
        nameLabel:Hide()
    end

    controlFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(setting.name or "", 1, 1, 1)
        GameTooltip:AddLine(setting.desc or "", 0.8, 0.8, 0.8, true)
        if setting.warning then GameTooltip:AddLine(" "); GameTooltip:AddLine(L["tip_warning_prefix"] .. setting.warning, 1, 0.2, 0.2, true) end
        GameTooltip:Show()
    end)
    controlFrame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    if setting.type == "checkbox" then
        local checkbox = CreateSettingCheckbox(controlFrame)
        checkbox:SetPoint("RIGHT", controlFrame, "RIGHT", -10, 0)
        nameLabel:SetPoint("RIGHT", checkbox, "LEFT", -5, 0)
        nameLabel:SetJustifyH("LEFT")

        local function ApplyEnabledState()
            local masterOK = true
            if setting.master then
                local m = setting.master.getter and setting.master.getter()
                masterOK = m ~= false
            end
            pcall(function()
                if masterOK then
                    if checkbox.Enable then checkbox:Enable() end
                else
                    if checkbox.Disable then checkbox:Disable() end
                end
            end)
            checkbox:SetAlpha(masterOK and 1.0 or 0.4)
            if nameLabel then nameLabel:SetAlpha(masterOK and 1.0 or 0.5) end
        end

        local function Update()
            local v = setting.getter and setting.getter() or FrostSeekDB.Settings[setting.id] or setting.default or false
            checkbox.checked = v
            checkbox.check:SetShown(v)
            if checkbox.bg then
                if v then
                    checkbox.bg:SetColorTexture(0.15, 0.75, 0.25, 1.0)
                else
                    checkbox.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)
                end
            end
            if checkbox.knob then
                if v then
                    checkbox.knob:ClearAllPoints()
                    checkbox.knob:SetPoint("CENTER", checkbox, "RIGHT", -10, 0)
                else
                    checkbox.knob:ClearAllPoints()
                    checkbox.knob:SetPoint("CENTER", checkbox, "LEFT", 10, 0)
                end
            end
        end
        Update()
        ApplyEnabledState()

        checkbox:SetScript("OnClick", function(self)
            if setting.master then
                local m = setting.master.getter and setting.master.getter()
                if m == false then
                    self.check:SetShown(self.checked)
                    return
                end
            end
            self.checked = not self.checked
            if setting.setter then setting.setter(self.checked) else FrostSeekDB.Settings[setting.id] = self.checked end
            self.check:SetShown(self.checked)
            if self.bg then
                if self.checked then
                    self.bg:SetColorTexture(0.15, 0.75, 0.25, 1.0)
                else
                    self.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)
                end
            end
            if self.knob then
                if self.checked then
                    self.knob:ClearAllPoints()
                    self.knob:SetPoint("CENTER", self, "RIGHT", -10, 0)
                else
                    self.knob:ClearAllPoints()
                    self.knob:SetPoint("CENTER", self, "LEFT", 10, 0)
                end
            end
            if setting.isMaster and settingsWindow and settingsWindow.controls then
                C_Timer.After(0, function()
                    for _, ctrl in ipairs(settingsWindow.controls) do
                        if ctrl and ctrl.UpdateFromDB then ctrl:UpdateFromDB() end
                    end
                    for _, ctrl in ipairs(settingsWindow.controls) do
                        if ctrl and ctrl.GetParent and ctrl.ApplyEnabledState then ctrl:ApplyEnabledState() end
                    end
                end)
            end
        end)
        checkbox.UpdateFromDB = function()
            Update()
            ApplyEnabledState()
        end
        checkbox.ApplyEnabledState = ApplyEnabledState
        return controlFrame, -40, checkbox

    elseif setting.type == "slider" then
        local isInteger = (setting.step or 1) >= 1
        local valueText = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valueText:SetPoint("RIGHT", controlFrame, "RIGHT", -40, 0)
        valueText:SetTextColor(unpack(_tc("textAccent")))

        local slider = CreateFrame("Slider", nil, controlFrame)
        slider:SetPoint("RIGHT", controlFrame, "RIGHT", -80, 0)
        slider:SetSize(150, 15)
        slider:SetMinMaxValues(setting.min or 0, setting.max or 100)
        slider:SetValueStep(setting.step or 1)
        slider:SetOrientation("HORIZONTAL")
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

        local bg = slider:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(unpack(_tc("bgButton")))

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

    elseif setting.type == "dropdown" then
        local selectedValue = setting.getter and setting.getter() or setting.default or ""
        local rawOptions = setting.options
        if type(rawOptions) == "function" then
            local ok, result = pcall(rawOptions)
            if ok then rawOptions = result end
        end
        rawOptions = rawOptions or {}

        local options = {}
        for _, opt in ipairs(rawOptions) do
            if type(opt) == "table" then
                table.insert(options, { value = opt.value, text = opt.text or tostring(opt.value), key = tostring(opt.value) })
            else
                table.insert(options, { value = opt, text = tostring(opt), key = tostring(opt) })
            end
        end

        local btn = CreateFrame("Button", nil, controlFrame)
        btn:SetSize(160, 24)
        btn:SetPoint("RIGHT", controlFrame, "RIGHT", -10, 0)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetTextColor(unpack(_tc("textPrimary")))


        local function GetDisplayText(val)
            local key = tostring(val)
            for _, opt in ipairs(options) do
                if opt.key == key then return opt.text end
            end
            return tostring(val)
        end
        btn.text:SetText(GetDisplayText(selectedValue))


        btn.arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        btn.arrow:SetTextColor(0.5, 0.5, 0.5, 0.8)
        btn.arrow:SetText("|cff88ccffv|r")

        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgTabActive")))
        end)
        btn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgButton")))
        end)

        btn:SetScript("OnClick", function(self)

            local curVal = setting.getter and setting.getter() or setting.default or ""
            local curKey = tostring(curVal)
            local nextOpt = nil
            for i, opt in ipairs(options) do
                if opt.key == curKey then
                    nextOpt = options[(i % #options) + 1]
                    break
                end
            end
            if not nextOpt and #options > 0 then
                nextOpt = options[1]
            end
            if nextOpt then
                self.text:SetText(nextOpt.text)
                if setting.setter then setting.setter(nextOpt.value) else FrostSeekDB.Settings[setting.id] = nextOpt.value end
            end
        end)

        return controlFrame, -40, btn

    elseif setting.type == "category" then
        local categoriesFrame = CreateFrame("Frame", nil, parent)
        categoriesFrame:SetSize(540, 200)
        categoriesFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset - 20)

        local title = categoriesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", categoriesFrame, "TOPLEFT", 0, 0)
        title:SetText(setting.name or "")
        title:SetTextColor(unpack(_tc("textPrimary")))

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
            label:SetTextColor(unpack(_tc("textMuted")))

            local function Update()
                checkbox.checked = setting.getter(category.id)
                checkbox.check:SetShown(checkbox.checked)
                if checkbox.bg then
                    if checkbox.checked then
                        checkbox.bg:SetColorTexture(0.15, 0.75, 0.25, 1.0)
                    else
                        checkbox.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)
                    end
                end
                if checkbox.knob then
                    if checkbox.checked then
                        checkbox.knob:ClearAllPoints()
                        checkbox.knob:SetPoint("CENTER", checkbox, "RIGHT", -10, 0)
                    else
                        checkbox.knob:ClearAllPoints()
                        checkbox.knob:SetPoint("CENTER", checkbox, "LEFT", 10, 0)
                    end
                end
            end
            Update()

            checkbox:SetScript("OnClick", function(self)
                self.checked = not self.checked
                self.check:SetShown(self.checked)
                setting.setter(category.id, self.checked)
                if self.bg then
                    if self.checked then
                        self.bg:SetColorTexture(0.15, 0.75, 0.25, 1.0)
                    else
                        self.bg:SetColorTexture(0.75, 0.2, 0.2, 1.0)
                    end
                end
                if self.knob then
                    if self.checked then
                        self.knob:ClearAllPoints()
                        self.knob:SetPoint("CENTER", self, "RIGHT", -10, 0)
                    else
                        self.knob:ClearAllPoints()
                        self.knob:SetPoint("CENTER", self, "LEFT", 10, 0)
                    end
                end

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
        local button = CreateModernButton(controlFrame, setting.name or "", 240, 25)
        button:SetPoint("RIGHT", controlFrame, "RIGHT", 0, 0)
        button:SetScript("OnClick", function() if setting.onClick then setting.onClick(button) end end)
        if setting.onEnter then
            button:SetScript("OnEnter", function() setting.onEnter(button) end)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        return controlFrame, -45, button

    elseif setting.type == "themeselector" then
        controlFrame:Hide()
        nameLabel:SetText("")

        local themeFrame = CreateFrame("Frame", nil, parent)
        themeFrame:SetSize(540, 80)
        themeFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset - 20)

        local themeTitle = themeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        themeTitle:SetPoint("TOPLEFT", themeFrame, "TOPLEFT", 0, 0)
        themeTitle:SetText(L["options_select_theme_label"])
        themeTitle:SetTextColor(unpack(_tc("textPrimary")))

        local themeDropdown
        if UI and UI.CreateModernDropdown then
            themeDropdown = UI.CreateModernDropdown(themeFrame, 200, 24)
        else
            themeDropdown = CreateFrame("Frame", nil, themeFrame)
            themeDropdown:SetSize(200, 24)
        end
        themeDropdown:SetPoint("TOPLEFT", themeTitle, "BOTTOMLEFT", 0, -8)

        local themeDesc = themeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        themeDesc:SetPoint("TOPLEFT", themeDropdown, "BOTTOMLEFT", 0, -6)
        themeDesc:SetPoint("RIGHT", themeFrame, "RIGHT", 0, 0)
        themeDesc:SetText(L["options_theme_reload_desc"])
        themeDesc:SetTextColor(unpack(_tc("textDim")))
        themeDesc:SetJustifyH("LEFT")

        local themeAPI = _G.FrostSeekTheme or (FrostSeek and FrostSeek.Theme)
        if themeAPI and themeAPI.GetThemes then
            local themes = themeAPI.GetThemes()
            if themeDropdown.SetOptions then
                themeDropdown:SetOptions(themes)
            end

            local currentName = themeAPI.GetName and themeAPI.GetName() or "Frost"
            if themeDropdown.SetText then
                themeDropdown:SetText(currentName)
            end
            themeDropdown.selectedValue = currentName

            themeDropdown.onChange = function(val)
                if val == currentName then return end
                FrostSeekDB.Settings._pendingTheme = val
                StaticPopup_Show("FROSTSEEK_THEME_RELOAD", val)
            end
        end

        return themeFrame, -100

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

    elseif setting.type == "activityfilter" then
        local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
        if not LFG or not LFG.ACTIVITY_FILTER_GROUPS then
            return controlFrame, -40
        end

        local groups = LFG.ACTIVITY_FILTER_GROUPS
        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(540, 10)
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

        local yOff = 0
        local allCheckboxes = {}

        local headerColors = {
            ["CLASSIC DUNGEONS"] = { 0.2, 0.75, 0.2 },
            ["CLASSIC RAIDS"]    = { 0.85, 0.45, 0.15 },
            ["TBC DUNGEONS"]     = { 0.3, 0.65, 0.85 },
            ["TBC RAIDS"]        = { 0.85, 0.55, 0.1 },
            ["WOTLK DUNGEONS"]   = { 0.55, 0.35, 0.85 },
            ["WOTLK RAIDS"]      = { 0.7, 0.2, 0.8 },
            ["CATA DUNGEONS"]    = { 0.85, 0.55, 0.15 },
            ["CATA RAIDS"]       = { 0.85, 0.4, 0.1 },
            ["MoP DUNGEONS"]     = { 0.3, 0.85, 0.55 },
            ["MoP RAIDS"]        = { 0.2, 0.7, 0.4 },
            ["MoP WORLD BOSSES"] = { 0.85, 0.3, 0.2 },
            ["EPOCH DUNGEONS"]   = { 0.9, 0.5, 0.85 },
            ["CUSTOM DUNGEONS"]  = { 0.9, 0.7, 0.1 },
            ["CUSTOM RAIDS"]     = { 0.95, 0.6, 0.15 },
            ["WORLD BOSSES"]     = { 0.85, 0.2, 0.2 },
            ["PVP"]              = { 0.85, 0.2, 0.2 },
            ["MANASTORM"]        = { 0.6, 0.3, 0.85 },
            ["KEYSTONE"]         = { 0.9, 0.4, 0.65 },
            ["MISC"]             = { 0.53, 0.80, 1.0 },
        }

        local currentHeaderName = nil
        local currentHeaderCheckboxes = {}
        local headerSections = {}

        local function GetPlayerExpansionLevel()
            local Shared = _G.FrostSeekShared
            if Shared and Shared.GetServerProfileExpansionLevel then
                return Shared.GetServerProfileExpansionLevel()
            end
            local ok, lvl = pcall(function() return GetAccountExpansionLevel and GetAccountExpansionLevel() end)
            if not ok or type(lvl) ~= "number" then return 4 end
            if lvl < 0 then lvl = 0 end
            if lvl > 4 then lvl = 4 end
            return lvl
        end
        local playerExpLevel = GetPlayerExpansionLevel()

        local Shared = _G.FrostSeekShared
        local function IsHeaderVisibleForServer(headerName)
            if Shared and Shared.IsExpansionVisibleForServer then
                return Shared.IsExpansionVisibleForServer(headerName)
            end
            return true
        end

        for _, entry in ipairs(groups) do
            if entry.isHeader then
                local skipDueToLevel = type(entry.level) == "number" and entry.level > playerExpLevel
                local skipDueToServer = not IsHeaderVisibleForServer(entry.header)
                if skipDueToLevel or skipDueToServer then
                    currentHeaderName = nil
                    currentHeaderCheckboxes = {}
                else

                if currentHeaderName and #currentHeaderCheckboxes > 0 then
                    headerSections[currentHeaderName] = currentHeaderCheckboxes
                end
                currentHeaderName = entry.header
                currentHeaderCheckboxes = {}

                local hFrame = CreateFrame("Frame", nil, container)
                hFrame:SetSize(530, 28)
                hFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, yOff)

                local hAccent = hFrame:CreateTexture(nil, "BACKGROUND")
                hAccent:SetPoint("LEFT", 0, 0)
                hAccent:SetSize(3, 22)
                local hc = headerColors[entry.header] or { 0.4, 0.6, 0.8 }
                hAccent:SetColorTexture(hc[1], hc[2], hc[3], 0.9)

                local hBg = hFrame:CreateTexture(nil, "BACKGROUND")
                hBg:SetPoint("TOPLEFT", 3, 0)
                hBg:SetPoint("BOTTOMRIGHT", 0, 0)
                hBg:SetColorTexture(hc[1] * 0.15, hc[2] * 0.15, hc[3] * 0.15, 0.6)

                local hText = hFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                hText:SetPoint("LEFT", 12, 0)
                hText:SetText(entry.header)
                hText:SetTextColor(hc[1] * 1.3, hc[2] * 1.3, hc[3] * 1.3)

                local toggleBtn = CreateFrame("Button", nil, hFrame)
                toggleBtn:SetSize(80, 20)
                toggleBtn:SetPoint("RIGHT", hFrame, "RIGHT", -6, 0)
                toggleBtn.bg = toggleBtn:CreateTexture(nil, "BACKGROUND")
                toggleBtn.bg:SetAllPoints()
                toggleBtn.bg:SetColorTexture(hc[1] * 0.15, hc[2] * 0.15, hc[3] * 0.15, 0.6)
                toggleBtn.border = toggleBtn:CreateTexture(nil, "BORDER")
                toggleBtn.border:SetAllPoints()
                toggleBtn.border:SetColorTexture(hc[1] * 0.4, hc[2] * 0.4, hc[3] * 0.4, 0.8)
                toggleBtn.text = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                toggleBtn.text:SetPoint("CENTER")
                toggleBtn._headerName = entry.header
                toggleBtn._checkboxes = currentHeaderCheckboxes
                hFrame._toggleBtn = toggleBtn

                yOff = yOff - 30
                end
            else
                if not currentHeaderName then
                else
                local activityExp = entry.exp
                local skipEntry = false
                if activityExp ~= nil then
                    local profile = Shared and Shared.GetServerProfile and Shared.GetServerProfile() or "wotlk"
                    if activityExp == 97 then
                        skipEntry = (profile ~= "ascension")
                    elseif activityExp == 98 then
                        skipEntry = (profile ~= "epoch")
                    elseif activityExp == 99 then
                        skipEntry = (profile ~= "ascension" and profile ~= "epoch")
                    elseif activityExp > playerExpLevel then
                        skipEntry = true
                    end
                end
                if skipEntry then
                else
                local row = CreateFrame("Frame", nil, container)
                row:SetSize(530, 24)
                row:SetPoint("TOPLEFT", container, "TOPLEFT", 15, yOff)

                local cb = CreateFrame("Button", nil, row)
                cb:SetSize(18, 18)
                cb:SetPoint("LEFT", row, "LEFT", 0, 0)

                cb.bg = cb:CreateTexture(nil, "BACKGROUND")
                cb.bg:SetAllPoints()
                cb.bg:SetColorTexture(unpack(_tc("bgCheckbox")))

                cb.border = cb:CreateTexture(nil, "BORDER")
                cb.border:SetAllPoints()
                cb.border:SetColorTexture(unpack(_tc("border")))

                cb.check = cb:CreateTexture(nil, "OVERLAY")
                cb.check:SetSize(12, 12)
                cb.check:SetPoint("CENTER")
                cb.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                cb.check:SetVertexColor(unpack(_tc("primary")))

                local isChecked = FrostSeekDB.LFG.activityFilter[entry.id] ~= false
                cb.checked = isChecked
                cb.check:SetShown(isChecked)

                local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
                label:SetText(entry.name)
                label:SetTextColor(unpack(isChecked and _tc("textPrimary") or _tc("textDim")))

                cb:SetScript("OnClick", function(self)
                    self.checked = not self.checked
                    self.check:SetShown(self.checked)
                    FrostSeekDB.LFG.activityFilter[entry.id] = self.checked
                    label:SetTextColor(unpack(self.checked and _tc("textPrimary") or _tc("textDim")))

                    if LFG.UpdateFilterIconState then LFG.UpdateFilterIconState() end
                end)

                cb:SetScript("OnEnter", function(self)
                    self.border:SetColorTexture(unpack(_tc("borderHover")))
                end)
                cb:SetScript("OnLeave", function(self)
                    self.border:SetColorTexture(unpack(_tc("border")))
                end)

                row:SetScript("OnEnter", function(self)
                    cb.border:SetColorTexture(unpack(_tc("borderHover")))
                end)
                row:SetScript("OnLeave", function(self)
                    cb.border:SetColorTexture(unpack(_tc("border")))
                end)

                table.insert(allCheckboxes, { cb = cb, label = label, id = entry.id })
                table.insert(currentHeaderCheckboxes, { cb = cb, label = label, id = entry.id })

                yOff = yOff - 24
                end
                end
            end
        end

        if currentHeaderName and #currentHeaderCheckboxes > 0 then
            headerSections[currentHeaderName] = currentHeaderCheckboxes
        end

        local function updateToggleBtnText(toggleBtn, checkboxes)
            if not toggleBtn or not toggleBtn.text then return end
            if not checkboxes or #checkboxes == 0 then
                toggleBtn.text:SetText("")
                return
            end
            local allOn = true
            local allOff = true
            for _, info in ipairs(checkboxes) do
                if info.cb.checked then allOff = false else allOn = false end
            end
            if allOn then
                toggleBtn.text:SetText("|cffff5555" .. L["deselect"] .. "|r")
            elseif allOff then
                toggleBtn.text:SetText("|cff44ff44" .. L["select"] .. "|r")
            else
                toggleBtn.text:SetText("|cff88ccff" .. L["toggle_all"] .. "|r")
            end
        end

        for _, child in ipairs({ container:GetChildren() }) do
            if child._toggleBtn and child._toggleBtn._checkboxes then
                local hb = child._toggleBtn
                local cbList = hb._checkboxes
                updateToggleBtnText(hb, cbList)
                hb:SetScript("OnClick", function()
                    local allOn = true
                    for _, info in ipairs(cbList) do
                        if not info.cb.checked then allOn = false; break end
                    end
                    local target = not allOn
                    for _, info in ipairs(cbList) do
                        info.cb.checked = target
                        info.cb.check:SetShown(target)
                        FrostSeekDB.LFG.activityFilter[info.id] = target
                        info.label:SetTextColor(unpack(target and _tc("textPrimary") or _tc("textDim")))
                    end
                    updateToggleBtnText(hb, cbList)
                    if LFG.UpdateFilterIconState then LFG.UpdateFilterIconState() end
                end)
            end
        end

        local btnRow = CreateFrame("Frame", nil, container)
        btnRow:SetSize(530, 28)
        btnRow:SetPoint("TOPLEFT", container, "TOPLEFT", 5, yOff - 5)

        local selectAllBtn = CreateModernButton(btnRow, L["select_all"], 90, 22)
        selectAllBtn:SetPoint("LEFT", btnRow, "LEFT", 0, 0)
        selectAllBtn:SetScript("OnClick", function()
            for _, info in ipairs(allCheckboxes) do
                info.cb.checked = true
                info.cb.check:SetShown(true)
                FrostSeekDB.LFG.activityFilter[info.id] = true
                info.label:SetTextColor(unpack(_tc("textPrimary")))
            end
            if LFG.UpdateFilterIconState then LFG.UpdateFilterIconState() end
        end)

        local deselectAllBtn = CreateModernButton(btnRow, L["deselect_all"], 100, 22)
        deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 8, 0)
        deselectAllBtn:SetScript("OnClick", function()
            local Shared = _G.FrostSeekShared
            if Shared and Shared.ConfirmDialog then
                Shared.ConfirmDialog(L["confirm_reset_lfg_filters_title"], L["confirm_reset_lfg_filters_msg"], function()
                    for _, info in ipairs(allCheckboxes) do
                        info.cb.checked = false
                        info.cb.check:SetShown(false)
                        FrostSeekDB.LFG.activityFilter[info.id] = false
                        info.label:SetTextColor(unpack(_tc("textDim")))
                    end
                    if LFG.UpdateFilterIconState then LFG.UpdateFilterIconState() end
                end)
            end
        end)

        yOff = yOff - 35

        container:SetHeight(math.abs(yOff) + 20)

        return container, yOff - 10, allCheckboxes

    elseif setting.type == "header" then
        local headerFrame = CreateFrame("Frame", nil, parent)
        headerFrame:SetSize(540, 60)
        headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

        local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
        headerText:SetText(setting.name or "")
        headerText:SetTextColor(unpack(_tc("textAccent")))

        if setting.desc and setting.desc ~= "" then
            local headerDesc = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            headerDesc:SetPoint("TOPLEFT", headerText, "BOTTOMLEFT", 0, -5)
            headerDesc:SetPoint("RIGHT", headerFrame, "RIGHT", 0, 0)
            headerDesc:SetText(setting.desc)
            headerDesc:SetTextColor(unpack(_tc("textMuted")))
            headerDesc:SetJustifyH("LEFT")
            headerDesc:SetWordWrap(true)
            headerDesc:SetHeight(40)
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

function CreateOptionsWindow()
    EnsureSettingsStructure()
    EnsurePopupCategoriesStructure()
    EnsureActivityFilterStructure()
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
    title:SetText(L["txt_frostseek_settings_title"])

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() settingsWindow:Hide(); StopPreviewEvents() end)

    local sidebar = CreateFrame("Frame", nil, settingsWindow)
    sidebar:SetSize(180, 550)
    sidebar:SetPoint("TOPLEFT", settingsWindow, "TOPLEFT", 15, -50)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(unpack(_tc("bgSection")))

    local catYOffset = -40
    for _, category in ipairs(GetSettingsCategories()) do
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

    local contentFrame = CreateFrame("Frame", nil, settingsWindow)
    contentFrame:SetSize(550, 550)
    contentFrame:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 20, 0)

    local contentBg = contentFrame:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(unpack(_tc("bgBlock")))

    local scrollFrame = CreateFrame("ScrollFrame", "FrostSeekSettingsScroll", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -25, 10)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(500, 540)
    scrollFrame:SetScrollChild(scrollContent)

    settingsWindow.scrollContent = scrollContent
    settingsWindow.scrollFrame = scrollFrame
    settingsWindow.controls = {}

    for _, category in ipairs(GetSettingsCategories()) do
        local frame
        if category.id == "custommessage" then
            frame = CreateCustomMessageTab(category, scrollContent)
        elseif category.id == "customkeywords" then
            frame = CreateCustomKeywordsTab(category, scrollContent)
        else
            frame = CreateFrame("Frame", nil, scrollContent)
            frame:SetSize(500, 540)
            frame:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)

            local frameTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            frameTitle:SetPoint("TOP", frame, "TOP", 0, -15)
            frameTitle:SetText(category.name)
            frameTitle:SetTextColor(unpack(_tc("textAccent")))

            local yOffset = -50
            for _, setting in ipairs(category.settings) do
                local control, height, controlObj = CreateSettingControl(frame, setting, yOffset)
                yOffset = yOffset + (height or -45)
                if controlObj then table.insert(settingsWindow.controls, controlObj) end
            end
            local contentH = math.abs(yOffset) + 30
            contentH = math.max(540, math.min(contentH, 2000))
            frame:SetHeight(contentH)
        end
        frame:Hide()
        categoryFrames[category.id] = frame
    end

    local function RecomputeScrollHeight()
        local maxH = 540
        for _, f in pairs(categoryFrames) do
            if f and f:GetHeight() > maxH then
                maxH = f:GetHeight()
            end
        end
        scrollContent:SetHeight(maxH)
    end
    RecomputeScrollHeight()
    settingsWindow.RecomputeScrollHeight = RecomputeScrollHeight

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
    if settingsWindow and settingsWindow.scrollContent and categoryFrames[categoryId] then
        local h = categoryFrames[categoryId]:GetHeight()
        if h and h > 540 then
            settingsWindow.scrollContent:SetHeight(h)
        else
            settingsWindow.scrollContent:SetHeight(540)
        end
    end
end

function ShowOptionsWindow()
    EnsureSettingsStructure()
    EnsurePopupCategoriesStructure()
    EnsureActivityFilterStructure()
    CreateOptionsWindow()
    if settingsWindow then
        settingsWindow:Show()
        SwitchSettingsCategory("general")
        RefreshAllControls()
    end
end

_G.ShowOptionsWindow = ShowOptionsWindow
_G.SwitchSettingsCategory = SwitchSettingsCategory

function Options:Initialize(parentFrame)
    EnsureSettingsStructure()
    EnsurePopupCategoriesStructure()

    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", self.frame, "TOP", 0, -20)
    self.title:SetText(L["options_system_settings"])

    self.desc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -10)
    self.desc:SetText(L["options_desc"])
    self.desc:SetTextColor(unpack(_tc("textMuted")))

    local buttonsFrame = CreateFrame("Frame", nil, self.frame)
    buttonsFrame:SetSize(760, 280)
    buttonsFrame:SetPoint("CENTER", self.frame, "CENTER", 0, -60)

    self.openBtn = CreateModernButton(buttonsFrame, "Open Settings Window", 220, 45)
    self.openBtn:SetPoint("TOP", buttonsFrame, "TOP", 0, 0)
    self.openBtn:SetScript("OnClick", ShowOptionsWindow)

    local function CreateLinkButton(parentFrame, text, link, color, yOffset, iconPath)
        local btn = CreateModernButton(parentFrame, text, 180, 35)
        btn:SetPoint("TOP", parentFrame, "TOP", 0, yOffset)

        if iconPath then
            local icon = btn:CreateTexture(nil, "OVERLAY")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
            icon:SetTexture(iconPath)
            btn.text:ClearAllPoints()
            btn.text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        end

        local function TryCopyToClipboard(str)
            if _G.Clipboard and type(_G.Clipboard) == "function" then
                local ok = pcall(_G.Clipboard, str)
                if ok then return true end
            end
            return false
        end

        btn:SetScript("OnClick", function()
            if TryCopyToClipboard(link) then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(L["msg_link_copied_to_clipboard"], tostring(text), tostring(link)))
            else
                local editBox = ChatEdit_ChooseBoxForSend()
                if not editBox:IsVisible() then ChatEdit_ActivateChat(editBox) end
                editBox:SetText(link)
                editBox:HighlightText()
                editBox:SetFocus()
                DEFAULT_CHAT_FRAME:AddMessage(L["msg_link_inserted_in_chat"])
            end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, color.r, color.g, color.b)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["tip_link_label"], 0.7, 0.7, 0.7, false)
            GameTooltip:AddLine(link, 1, 1, 1, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(L["tip_click_to_copy"], 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
            if self.hoverTex then self.hoverTex:Show() end
            self.text:SetTextColor(color.r, color.g, color.b)
            if self.border then self.border:SetColorTexture(color.r, color.g, color.b, 1) end
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.hoverTex then self.hoverTex:Hide() end
            self.text:SetTextColor(unpack(_tc("textPrimary")))
            if self.border then self.border:SetColorTexture(unpack(_tc("border"))) end
        end)
        return btn
    end

    CreateLinkButton(buttonsFrame, "Donate", "https://paypal.me/1AYRO", {r=0.000, g=0.439, b=0.729}, -50, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\paypal.tga")
    CreateLinkButton(buttonsFrame, "CurseForge", "https://www.curseforge.com/wow/addons/frostseek", {r=0.937, g=0.502, b=0.196}, -90, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\forge.tga")
    CreateLinkButton(buttonsFrame, "GitHub", "https://github.com/ayro-CMD/FrostSeek", {r=0.533, g=0.533, b=0.533}, -130, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\Kjrt.tga")
    CreateLinkButton(buttonsFrame, "BugReport", "https://discord.gg/uvtvKXzbXW", {r=0.863, g=0.078, b=0.235}, -170, "Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\bug.tga")

    self.statusFrame = CreateFrame("Frame", nil, self.frame)
    self.statusFrame:SetSize(550, 80)
    self.statusFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 30)

    local statusBg = self.statusFrame:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    statusBg:SetColorTexture(unpack(_tc("bgCheckbox")))

    local statusTitle = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusTitle:SetPoint("TOP", self.statusFrame, "TOP", 0, -10)
    statusTitle:SetText(L["options_current_status"])
    statusTitle:SetTextColor(unpack(_tc("textPrimary")))

    self.statusText = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.statusText:SetPoint("TOP", statusTitle, "BOTTOM", 0, -10)
    self.statusText:SetText(L["options_lfg_status_active"])
    self.statusText:SetTextColor(unpack(_tc("textPrimary")))

    self.frame:Hide()
end

function Options:Show()
    if self.frame then
        if self.statusText then
            local lfgStatus = L["options_lfg_status_active_colored"]
            if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then lfgStatus = L["options_lfg_status_disabled_colored"] end
            self.statusText:SetText(string.format(L["options_lfg_status_label"], lfgStatus, L["options_icon_credit"]))
        end
        self.frame:Show()
    end
end

function Options:Hide()
    if self.frame then self.frame:Hide() end
end

StaticPopupDialogs["FROSTSEEK_THEME_RELOAD"] = {
    text = L["popup_theme_reload_text"],
    button1 = L["popup_btn_apply_now"],
    button2 = L["popup_btn_apply_reload"],
    button3 = L["cancel"],
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
        local pending = FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings._pendingTheme
        if pending then
            local themeAPI = _G.FrostSeekTheme or (_G.FrostSeek and _G.FrostSeek.Theme)
            if themeAPI and themeAPI.Set then
                themeAPI.Set(pending)
            end
            if themeAPI and themeAPI.Apply then
                pcall(themeAPI.Apply)
            end
            FrostSeekDB.Settings._pendingTheme = nil
            print(string.format(L["msg_theme_applied_live"], tostring(pending)))
        end
    end,
    OnCancel = function()
        local pending = FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings._pendingTheme
        if pending then
            local themeAPI = _G.FrostSeekTheme or (_G.FrostSeek and _G.FrostSeek.Theme)
            if themeAPI and themeAPI.Set then
                themeAPI.Set(pending)
            end
            FrostSeekDB.Settings._pendingTheme = nil
            print(string.format(L["msg_theme_applied_reloading"], tostring(pending)))

            StaticPopup_Hide("FROSTSEEK_THEME_RELOAD")
            local editBox = ChatFrame1EditBox
            if not editBox or not editBox:IsShown() then
                if FrostSeekCompat and FrostSeekCompat.OpenChat then
                    FrostSeekCompat.OpenChat("")
                elseif ChatFrame_OpenChat then
                    ChatFrame_OpenChat("")
                end
                editBox = ChatFrame1EditBox
            end
            if editBox then
                editBox:SetText("/reload")
                ChatEdit_SendText(editBox, 0)
            else
                print(L["msg_type_reload_manual"])
            end
        end
    end,
    OnHide = function()
        if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings._pendingTheme then
            local pending = FrostSeekDB.Settings._pendingTheme
            FrostSeekDB.Settings._pendingTheme = nil
            RefreshAllControls()
            print(L["msg_theme_change_cancelled"])
        end
    end,
}

StaticPopupDialogs["FROSTSEEK_POPUP_INFO"] = {
    text = "|cff88ccff" .. L["options_how_popups_work"] .. "|r\n\n"
        .. "|cffffd966" .. L["tip_popups_all_selected"] .. "|r " .. L["tip_popups_all_fire"] .. "\n\n"
        .. "|cffffd966" .. L["tip_popups_single_selected"] .. "|r " .. L["tip_popups_single_explain"] .. "\n\n"
        .. "|cffffd966" .. L["tip_popups_none_selected"] .. "|r " .. L["tip_popups_none_explain"] .. "\n\n"
        .. "|cff888888" .. L["tip_hover_categories"] .. "|r",
    button1 = L["popup_btn_close"],
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function Options:ApplyTheme()
    if settingsWindow and settingsWindow:IsShown() then
    end
end

local function ThemeStaticPopup(popupFrame)
    if not popupFrame then return end
    local Shared = _G.FrostSeekShared
    local _tc = Shared and Shared._tc or function() return {0.5, 0.5, 0.5} end
    pcall(function()
        local bgC = _tc("bgMain")
        local borderC = _tc("accent")
        if popupFrame.SetBackdrop then
            popupFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                tile = false, tileSize = 0, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            popupFrame:SetBackdropColor(bgC[1], bgC[2], bgC[3], 0.95)
            popupFrame:SetBackdropBorderColor(borderC[1], borderC[2], borderC[3], 0.9)
        end
    end)
    pcall(function()
        local accentC = _tc("accent")
        local textC = _tc("textPrimary")
        for i = 1, 3 do
            local btn = _G[popupFrame:GetName() .. "Button" .. i]
            if btn and btn:IsShown() then
                if btn.SetBackdrop then
                    btn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        tile = false, tileSize = 0, edgeSize = 1,
                        insets = { left = 0, right = 0, top = 0, bottom = 0 }
                    })
                    btn:SetBackdropColor(accentC[1] * 0.25, accentC[2] * 0.25, accentC[3] * 0.25, 0.9)
                    btn:SetBackdropBorderColor(accentC[1] * 0.5, accentC[2] * 0.5, accentC[3] * 0.5, 0.8)
                end
                local btnText = _G[btn:GetName() .. "Text"]
                if btnText then
                    btnText:SetTextColor(min(accentC[1] * 1.3, 1), min(accentC[2] * 1.3, 1), min(accentC[3] * 1.3, 1))
                end
                btn:SetScript("OnEnter", function(self)
                    if self.SetBackdropColor then
                        self:SetBackdropColor(accentC[1] * 0.5, accentC[2] * 0.5, accentC[3] * 0.5, 0.95)
                    end
                end)
                btn:SetScript("OnLeave", function(self)
                    if self.SetBackdropColor then
                        self:SetBackdropColor(accentC[1] * 0.25, accentC[2] * 0.25, accentC[3] * 0.25, 0.9)
                    end
                end)
            end
        end
    end)
end

if StaticPopup_Show then
    hooksecurefunc("StaticPopup_Show", function(which, ...)
        if which and type(which) == "string" and string.find(which, "^FROSTSEEK_") then
            local maxDialogs = STATICPOPUP_NUMDIALOGS or 4
            for i = 1, maxDialogs do
                local popup = _G["StaticPopup" .. i]
                if popup and popup:IsShown() and popup.which == which then
                    ThemeStaticPopup(popup)
                    break
                end
            end
        end
    end)
end

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("options", Options)
end
