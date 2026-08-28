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
local LFM = FrostSeek and (FrostSeek.Modules and FrostSeek.Modules.lfm or FrostSeek.LFM)
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfm_ui", LFM)
local L = FrostSeek.L
local _tc = _G.FrostSeekShared and _G.FrostSeekShared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = _G.FrostSeekShared and _G.FrostSeekShared._hex or function(t) return "|cFF888888" end
local S = LFM._S
local LFM_ACTIVITIES = LFM.LFM_ACTIVITIES
local DIFFICULTIES = LFM.DIFFICULTIES
local CHANNELS = LFM.CHANNELS
local RAID_ROLE_REQUIREMENTS = LFM.RAID_ROLE_REQUIREMENTS
local FilterActivities = LFM._logic.FilterActivities
local ProcessTemplate = LFM._logic.ProcessTemplate
local SendLFMMessage = LFM._logic.SendLFMMessage
local SendToAllSpamChannels = LFM._logic.SendToAllSpamChannels
local StartKeystoneAutoUpdate = LFM._logic.StartKeystoneAutoUpdate
local StopKeystoneAutoUpdate = LFM._logic.StopKeystoneAutoUpdate
local UpdateKeystoneList = LFM._logic.UpdateKeystoneList
local ValidateGroupComposition = LFM._logic.ValidateGroupComposition
local userEditedMessage = false
local lastSelectedTemplate = nil
local lastSelectedActivity = nil
local activeEditBox = nil

if _G.FrostSeekOrigSetItemRef == nil then
    _G.FrostSeekOrigSetItemRef = SetItemRef
end
local _orig_SetItemRef = _G.FrostSeekOrigSetItemRef

function SetItemRef(link, text, button, chatFrame)
    if link and type(link) == "string" then
        local linkType = string.match(link, "^([^:]+)")
        if linkType == "frostseeklfm" then
            local cmd = string.match(link, "^frostseeklfm:(.+)")
            if cmd == "copy" then
                local editBox = ChatEdit_GetActiveWindow()
                if not editBox then
                    if FrostSeekCompat and FrostSeekCompat.OpenChat then
                        FrostSeekCompat.OpenChat("")
                    elseif ChatFrame_OpenChat then
                        ChatFrame_OpenChat("")
                    end
                    editBox = ChatEdit_GetActiveWindow()
                end
                if editBox and S.customMessage and S.customMessage ~= "" then
                    editBox:SetText(S.customMessage)
                end
                return
            elseif cmd == "send" then
                local message = S.customMessage or ""
                if message ~= "" then
                    for i = 1, 10 do
                        if S.spamChannels[i] then
                            SendLFMMessage(message, "CHANNEL" .. i)
                            break
                        end
                    end
                end
                return
            end
        end
    end
    if _orig_SetItemRef then
        _orig_SetItemRef(link, text, button, chatFrame)
    end
end

function LFM.UpdateMessagePreview(template, activity)
    if not LFM.messageEditBox then return end

    if template == nil and activity == nil then
        if lastSelectedTemplate then
            template = lastSelectedTemplate
            activity = lastSelectedActivity
        end
    else
        lastSelectedTemplate = template
        lastSelectedActivity = activity
    end

    if template then
        local processed = ProcessTemplate(template, activity)
        if not LFM.messageEditBox:HasFocus() then
            if userEditedMessage then
                return
            end
            S.customMessage = processed
            FrostSeekDB.LFM.customMessage = S.customMessage
            LFM.messageEditBox:SetText(processed)
            LFM.messageEditBox:SetTextColor(unpack(_tc("textPrimary")))
        end
    else
        if not LFM.messageEditBox:HasFocus() then
            if userEditedMessage then
                return
            end
            S.customMessage = ""
            FrostSeekDB.LFM.customMessage = ""
            LFM.messageEditBox:SetText("")
            LFM.messageEditBox:SetTextColor(unpack(_tc("textMuted")))
        end
    end
end

function LFM.UpdateDifficultyDropdown()
    local difficulties = DIFFICULTIES[S.currentCategory] or {"Normal"}
    if not LFM.difficultyDropdown then return end

    LFM.difficultyDropdown:SetOptions(difficulties)

    S.selectedDifficulty = difficulties[1] or "Normal"
    LFM.difficultyDropdown:SetText(S.selectedDifficulty)
    LFM.difficultyDropdown.selectedValue = S.selectedDifficulty
end

local function AcquireActivityRow(parent, pool, i)
    local btn = pool[i]
    if btn then return btn end
    btn = CreateFrame("Button", nil, parent)
    local rowW = (parent and parent:GetWidth()) or 700
    btn:SetSize(rowW, 26)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, 0)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 3, 0)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    btn._bg = bg

    local accentBar = btn:CreateTexture(nil, "BACKGROUND")
    accentBar:SetPoint("TOPLEFT", 0, 0)
    accentBar:SetSize(3, 26)
    btn._accentBar = accentBar

    local separator = btn:CreateTexture(nil, "BACKGROUND")
    separator:SetPoint("BOTTOMLEFT", 6, 0)
    separator:SetPoint("BOTTOMRIGHT", -2, 0)
    separator:SetHeight(1)
    separator:SetColorTexture(unpack(_tc("separator")))

    local dot = btn:CreateTexture(nil, "OVERLAY")
    dot:SetSize(6, 6)
    dot:SetPoint("LEFT", btn, "LEFT", 12, 0)
    btn._dot = dot

    local nameText = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    nameText:SetPoint("LEFT", dot, "RIGHT", 8, 0)
    btn._nameText = nameText

    local templateText = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    templateText:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
    btn._templateText = templateText

    btn:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(unpack(_tc("bgRowHover")))
        if self._accent then
            self._accentBar:SetColorTexture(self._accent[1], self._accent[2], self._accent[3], 1.0)
            self._dot:SetColorTexture(self._accent[1], self._accent[2], self._accent[3], 1.0)
        end
        self._nameText:SetTextColor(1, 1, 1)
        self._templateText:SetTextColor(unpack(_tc("textNorm")))
    end)

    btn:SetScript("OnLeave", function(self)
        if self._rowIndex and (self._rowIndex % 2 == 0) then
            self._bg:SetColorTexture(unpack(_tc("bgRowEven")))
        else
            self._bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        end
        if self._accent then
            self._accentBar:SetColorTexture(self._accent[1], self._accent[2], self._accent[3], 0.7)
            self._dot:SetColorTexture(self._accent[1], self._accent[2], self._accent[3], 0.9)
        end
        self._nameText:SetTextColor(unpack(_tc("textPrimary")))
        self._templateText:SetTextColor(unpack(_tc("textDim")))
    end)

    btn:SetScript("OnClick", function(self)
        userEditedMessage = false
        if self._activity then
            LFM.UpdateMessagePreview(self._activity.template, self._activity)
        end
    end)

    pool[i] = btn
    return btn
end

function LFM.UpdateActivityList()
    if not LFM.activitiesContent then return end
    if not LFM.activitiesContent.buttons then
        LFM.activitiesContent.buttons = {}
    end
    local pool = LFM.activitiesContent.buttons

    local activities = LFM_ACTIVITIES[S.currentCategory] or {}
    local filteredActivities = FilterActivities(activities)
    local n = #filteredActivities

    for i = n + 1, #pool do
        if pool[i] then pool[i]:Hide() end
    end

    local yOffset = -4

    local accentColors = {
        RAIDS = _tc("catRaid"),
        DUNGEONS = _tc("catDungeon"),
        MANASTORM = _tc("catMana"),
        WORLD_BOSS = _tc("catWorldBoss"),
        PVP = _tc("catPvP"),
        KEYSTONE = _tc("catKeystone"),
    }
    local accent = accentColors[S.currentCategory] or _tc("catAll")

    for i, activity in ipairs(filteredActivities) do
        local btn = AcquireActivityRow(LFM.activitiesContent, pool, i)
        btn._rowIndex = i
        btn._accent = accent
        btn._activity = activity
        btn:SetPoint("TOPLEFT", LFM.activitiesContent, "TOPLEFT", 2, yOffset)

        if i % 2 == 0 then
            btn._bg:SetColorTexture(unpack(_tc("bgRowEven")))
        else
            btn._bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        end

        btn._accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
        btn._dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)

        if S.currentCategory == "KEYSTONE" and activity.keystoneLink then
            btn._nameText:SetText(activity.keystoneLink)
        else
            btn._nameText:SetText(activity.name)
        end
        btn._nameText:SetTextColor(unpack(_tc("textPrimary")))

        local shortTemplate = activity.template or ""
        if #shortTemplate > 40 then
            shortTemplate = string.sub(shortTemplate, 1, 37) .. "..."
        end
        btn._templateText:SetText(shortTemplate)
        btn._templateText:SetTextColor(unpack(_tc("textDim")))

        yOffset = yOffset - 27
    end

    LFM.activitiesContent:SetHeight(math.max(math.abs(yOffset) + 10, 100))
end

local _searchDebounceToken = 0
local function ScheduleActivityListUpdate()
    _searchDebounceToken = _searchDebounceToken + 1
    local myToken = _searchDebounceToken
    C_Timer.After(0.25, function()
        if _searchDebounceToken == myToken then
            LFM.UpdateActivityList()
        end
    end)
end


function LFM.UpdateTabsAppearance()
    local allCategoryTabs = {
        { key = "RAIDS", name = L["cat_raid"] },
        { key = "DUNGEONS", name = L["cat_dungeon"] },
        { key = "MANASTORM", name = L["cat_manastorm"], profileOnly = "ascension" },
        { key = "WORLD_BOSS", name = L["cat_world_boss"] },
        { key = "PVP", name = L["cat_pvp"] },
        { key = "KEYSTONE", name = L["cat_keystone"] }
    }

    local Shared = _G.FrostSeekShared
    local currentProfile = Shared and Shared.GetServerProfile and Shared.GetServerProfile() or "wotlk"

    local categoryTabs = {}
    for _, tabInfo in ipairs(allCategoryTabs) do
        if not tabInfo.profileOnly or tabInfo.profileOnly == currentProfile then
            table.insert(categoryTabs, tabInfo)
        end
    end

    for i, tabInfo in ipairs(categoryTabs) do
        local tab = _G["LFM_Tab_" .. tabInfo.key]
        if tab then
            if tabInfo.key == S.currentCategory then
                tab.bg:SetColorTexture(unpack(_tc("bgTabActive")))
                tab.text:SetTextColor(1, 1, 1)
            else
                tab.bg:SetColorTexture(unpack(_tc("bgBlock")))
                tab.text:SetTextColor(unpack(_tc("textMuted")))
            end
        end
    end
end

function LFM:UpdateAutoUpdateInterval()
    if S.keystoneUpdateTicker and S.currentCategory == "KEYSTONE" then
        StartKeystoneAutoUpdate()
    end
end

local function ClearActiveEditBox()
    if activeEditBox then
        activeEditBox:ClearFocus()
        activeEditBox = nil
    end
end

local function CloseAllDropdowns()
    if LFM.difficultyDropdown and LFM.difficultyDropdown.menu and LFM.difficultyDropdown.menu:IsShown() then
        LFM.difficultyDropdown.menu:Hide()
    end
end

local CreateModernButton = UI and UI.CreateModernButton or CreateFrame and function(parent, width, height, text, color)
    local c = color or _tc("primary")
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 70, height or 22)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 1, -1)
    btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", 0, 0)
    btn.border:SetPoint("BOTTOMRIGHT", 0, 0)
    btn.border:SetColorTexture(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.7)
    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    btn.accent:SetHeight(1.5)
    btn.accent:SetColorTexture(c[1], c[2], c[3], 0.4)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text or "")
    btn.text:SetTextColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2)
    btn.color = c
    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 0.9)
        self.border:SetColorTexture(c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 0.9)
        self.accent:SetColorTexture(c[1], c[2], c[3], 0.8)
        self.text:SetTextColor(min(c[1] * 1.4, 1), min(c[2] * 1.4, 1), min(c[3] * 1.4, 1))
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)
        self.border:SetColorTexture(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.7)
        self.accent:SetColorTexture(c[1], c[2], c[3], 0.4)
        self.text:SetTextColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2)
    end)
    return btn
end

local CreateModernEditBox = UI and UI.CreateModernEditBox or function(parent, width, height)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width or 120, height or 20)
    eb:SetAutoFocus(false)
    eb:SetFontObject("FSKFontNormalSmall")
    eb:SetTextInsets(6, 6, 0, 0)
    eb.bg = eb:CreateTexture(nil, "BACKGROUND")
    eb.bg:SetPoint("TOPLEFT", 1, -1)
    eb.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    eb.bg:SetColorTexture(unpack(_tc("bgInput")))
    eb.border = eb:CreateTexture(nil, "BORDER")
    eb.border:SetPoint("TOPLEFT", 0, 0)
    eb.border:SetPoint("BOTTOMRIGHT", 0, 0)
    eb.border:SetColorTexture(unpack(_tc("borderInput")))
    eb.accent = eb:CreateTexture(nil, "OVERLAY")
    eb.accent:SetPoint("BOTTOMLEFT", 2, 0)
    eb.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    eb.accent:SetHeight(1.5)
    eb.accent:SetColorTexture(unpack(_tc("accentBar")))
    eb:SetScript("OnEditFocusGained", function(self)
        if activeEditBox and activeEditBox ~= self then
            activeEditBox:ClearFocus()
        end
        activeEditBox = self
        self.bg:SetColorTexture(unpack(_tc("bgInputFocus")))
        self.border:SetColorTexture(unpack(_tc("borderFocus")))
        self.accent:SetColorTexture(unpack(_tc("accentFocus")))
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        if activeEditBox == self then
            activeEditBox = nil
        end
        self.bg:SetColorTexture(unpack(_tc("bgInput")))
        self.border:SetColorTexture(unpack(_tc("borderInput")))
        self.accent:SetColorTexture(unpack(_tc("accentBar")))
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return eb
end

local CreateModernDropdown = UI and UI.CreateModernDropdown or function(parent, width, height)
    local dd = CreateFrame("Frame", nil, parent)
    dd:SetSize(width or 120, height or 22)
    dd.bg = dd:CreateTexture(nil, "BACKGROUND")
    dd.bg:SetPoint("TOPLEFT", 0, 0)
    dd.bg:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.bg:SetColorTexture(0, 0, 0, 1)
    dd.border = dd:CreateTexture(nil, "BORDER")
    dd.border:SetPoint("TOPLEFT", 0, 0)
    dd.border:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.border:SetColorTexture(unpack(_tc("borderMenu")))
    dd.accent = dd:CreateTexture(nil, "OVERLAY")
    dd.accent:SetPoint("BOTTOMLEFT", 2, 0)
    dd.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    dd.accent:SetHeight(1.5)
    dd.accent:SetColorTexture(unpack(_tc("accentBar")))
    dd.button = CreateFrame("Button", nil, dd)
    dd.button:SetAllPoints(dd)
    dd.text = dd:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    dd.text:SetPoint("LEFT", 6, 0)
    dd.text:SetTextColor(unpack(_tc("textPrimary")))
    dd.text:SetText("")
    dd.arrowText = dd:CreateFontString(nil, "OVERLAY")
    dd.arrowText:SetPoint("RIGHT", -6, 0)
    dd.arrowText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    dd.arrowText:SetText("v")
    dd.arrowText:SetTextColor(unpack(_tc("textNorm")))
    dd.menu = CreateFrame("Frame", nil, UIParent)
    dd.menu:SetFrameStrata("DIALOG")
    dd.menu:SetToplevel(true)
    dd.menu:EnableMouse(true)
    dd.menu:SetSize(width or 120, 10)
    dd.menu:Hide()
    dd.menuBg = dd.menu:CreateTexture(nil, "BACKGROUND")
    dd.menuBg:SetPoint("TOPLEFT", 0, 0)
    dd.menuBg:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.menuBg:SetColorTexture(unpack(_tc("bgMenuBg")))
    dd.menuBorder = dd.menu:CreateTexture(nil, "BORDER")
    dd.menuBorder:SetPoint("TOPLEFT", 0, 0)
    dd.menuBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.menuBorder:SetColorTexture(unpack(_tc("borderMenu")))
    dd.menu.buttons = {}
    dd.menu.maxShown = 20
    dd.options = {}
    dd.onChange = nil
    dd.menu:SetScript("OnHide", function()
        dd.border:SetColorTexture(unpack(_tc("borderMenu")))
        dd.accent:SetColorTexture(unpack(_tc("accentBar")))
    end)
    local function CloseMenu()
        dd.menu:Hide()
    end
    dd.closeHandler = CreateFrame("Frame", nil, UIParent)
    pcall(function() dd.closeHandler:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
    dd.closeHandler:SetScript("OnEvent", function(self, event)
        if dd.menu:IsShown() then
            if not MouseIsOver(dd.menu) and not MouseIsOver(dd) then
                CloseMenu()
            end
        end
    end)
    local function ToggleMenu()
        if dd.menu:IsShown() then
            CloseMenu()
        else
            dd.menu:ClearAllPoints()
            dd.menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
            dd.menu:Show()
            dd.border:SetColorTexture(unpack(_tc("borderFocus")))
            dd.accent:SetColorTexture(unpack(_tc("accentFocus")))
        end
    end
    dd.button:SetScript("OnClick", ToggleMenu)
    dd.button:SetScript("OnEnter", function()
        if not dd.menu:IsShown() then
            dd.border:SetColorTexture(unpack(_tc("borderHover")))
            dd.accent:SetColorTexture(unpack(_tc("accentFocus")))
        end
    end)
    dd.button:SetScript("OnLeave", function()
        if not dd.menu:IsShown() then
            dd.border:SetColorTexture(unpack(_tc("borderMenu")))
            dd.accent:SetColorTexture(unpack(_tc("accentBar")))
        end
    end)
    function dd:SetOptions(options)
        self.options = options or {}
        for _, b in ipairs(self.menu.buttons) do
            b:Hide()
            b:SetParent(nil)
        end
        wipe(self.menu.buttons)
        local count = #self.options
        local maxH = min(count, self.menu.maxShown)
        self.menu:SetHeight(maxH * 22 + 4)
        for i, opt in ipairs(self.options) do
            local b = CreateFrame("Button", nil, self.menu)
            b:SetSize(self:GetWidth() - 2, 22)
            b:SetPoint("TOPLEFT", 1, -2 - (i-1) * 22)
            b.optBg = b:CreateTexture(nil, "BACKGROUND")
            b.optBg:SetAllPoints()
            b.optBg:SetColorTexture(0, 0, 0, 0)
            b.optAccent = b:CreateTexture(nil, "OVERLAY")
            b.optAccent:SetPoint("TOPLEFT", 0, 0)
            b.optAccent:SetSize(2, 22)
            b.optAccent:SetColorTexture(unpack(_tc("accentBar")))
            b.optAccent:SetAlpha(0)
            b.optText = b:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
            b.optText:SetPoint("LEFT", 8, 0)
            b.optText:SetText(opt)
            b.optText:SetTextColor(unpack(_tc("textNorm")))
            b:Show()
            b:SetScript("OnEnter", function(self)
                self.optBg:SetColorTexture(unpack(_tc("bgRowHover")))
                self.optAccent:SetAlpha(1)
                self.optAccent:SetColorTexture(unpack(_tc("accentFocus")))
                self.optText:SetTextColor(unpack(_tc("textPrimary")))
            end)
            b:SetScript("OnLeave", function(self)
                self.optBg:SetColorTexture(0, 0, 0, 0)
                self.optAccent:SetAlpha(0)
                self.optText:SetTextColor(unpack(_tc("textNorm")))
            end)
            b:SetScript("OnClick", function()
                dd:SetText(opt)
                dd.selectedValue = opt
                CloseMenu()
                if dd.onChange then dd.onChange(opt) end
            end)
            self.menu.buttons[i] = b
        end
    end
    function dd:SetText(txt)
        self.text:SetText(txt)
    end
    function dd:GetText()
        return self.text:GetText()
    end
    return dd
end

local CreateSmallToggle = UI and UI.CreateSmallToggle or function(parent, text, x, y, width, height, onClick)
    local sc = _tc("success")
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 36, height or 20)
    btn:SetPoint("LEFT", parent, "LEFT", x, y)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 1, -1)
    btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bg:SetColorTexture(unpack(_tc("bgBlock")))
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", 0, 0)
    btn.border:SetPoint("BOTTOMRIGHT", 0, 0)
    local _bi = _tc("borderInput")
    btn.border:SetColorTexture(_bi[1], _bi[2], _bi[3], 0.7)
    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    btn.accent:SetHeight(1.5)
    local _ab = _tc("accentBar")
    btn.accent:SetColorTexture(_ab[1], _ab[2], _ab[3], 0.3)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(_tc("textMuted")))
    btn.active = false
    btn:SetScript("OnClick", function(self)
        self.active = not self.active
        if self.active then
            self.bg:SetColorTexture(sc[1] * 0.4, sc[2] * 0.4, sc[3] * 0.4, 0.85)
            self.border:SetColorTexture(sc[1] * 0.7, sc[2] * 0.7, sc[3] * 0.7, 0.9)
            self.accent:SetColorTexture(sc[1], sc[2], sc[3], 0.7)
            self.text:SetTextColor(min(sc[1] * 1.4, 1), min(sc[2] * 1.4, 1), min(sc[3] * 1.4, 1))
        else
            self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            local bi2 = _tc("borderInput")
            self.border:SetColorTexture(bi2[1], bi2[2], bi2[3], 0.7)
            local ab2 = _tc("accentBar")
            self.accent:SetColorTexture(ab2[1], ab2[2], ab2[3], 0.3)
            self.text:SetTextColor(unpack(_tc("textMuted")))
        end
        if onClick then onClick(self.active) end
    end)
    btn:SetScript("OnEnter", function(self)
        if self.active then
            self.bg:SetColorTexture(sc[1] * 0.5, sc[2] * 0.5, sc[3] * 0.5, 0.9)
            self.border:SetColorTexture(sc[1] * 0.8, sc[2] * 0.8, sc[3] * 0.8, 1.0)
            self.accent:SetColorTexture(min(sc[1] * 1.1, 1), min(sc[2] * 1.1, 1), min(sc[3] * 1.1, 1), 0.9)
        else
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            self.border:SetColorTexture(unpack(_tc("borderHover")))
            local ab3 = _tc("accentBar")
            self.accent:SetColorTexture(ab3[1], ab3[2], ab3[3], 0.5)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.active then
            self.bg:SetColorTexture(sc[1] * 0.4, sc[2] * 0.4, sc[3] * 0.4, 0.85)
            self.border:SetColorTexture(sc[1] * 0.7, sc[2] * 0.7, sc[3] * 0.7, 0.9)
            self.accent:SetColorTexture(sc[1], sc[2], sc[3], 0.7)
            self.text:SetTextColor(min(sc[1] * 1.4, 1), min(sc[2] * 1.4, 1), min(sc[3] * 1.4, 1))
        else
            self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            local bi3 = _tc("borderInput")
            self.border:SetColorTexture(bi3[1], bi3[2], bi3[3], 0.7)
            local ab4 = _tc("accentBar")
            self.accent:SetColorTexture(ab4[1], ab4[2], ab4[3], 0.3)
            self.text:SetTextColor(unpack(_tc("textMuted")))
        end
    end)
    btn:SetScript("OnMouseDown", function()
        ClearActiveEditBox()
        CloseAllDropdowns()
    end)
    return btn
end

function LFM:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    local CW = math.max(700, (parentFrame:GetWidth() or 800) - 20)
    local IW = CW - 20
    local AW = IW - 40

    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(CW, 520)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.mainContainer:EnableMouse(true)
    self.mainContainer:SetScript("OnMouseDown", function()
        ClearActiveEditBox()
        CloseAllDropdowns()
    end)

    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    self.title:SetPoint("TOP", self.mainContainer, "TOP", 0, -8)
    self.title:SetText("|cff88ccff" .. L["lfm_title"] .. "|r")
    self.title:SetTextColor(0.8, 0.9, 1)

    self.desc = self.mainContainer:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -3)
    self.desc:SetText(L["lfm_desc"])
    self.desc:SetTextColor(unpack(_tc("textMuted")))

    self.rolesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.rolesFrame:SetSize(IW, 26)
    self.rolesFrame:SetPoint("TOP", self.desc, "BOTTOM", 0, -6)

    local rolesLabel = self.rolesFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    rolesLabel:SetPoint("LEFT", self.rolesFrame, "LEFT", 10, 0)
    rolesLabel:SetText(L["lfm_need"] .. ":")
    rolesLabel:SetTextColor(unpack(_tc("textMuted")))

    self.roleCheckboxes = {}
    local roleTypes = {"Tank", "Healer", "DPS", "Support"}
    local ROLE_COLORS = Shared and Shared.ROLE_COLORS or { Tank = {0.3, 0.5, 0.85}, Healer = {0.2, 0.8, 0.3}, DPS = {0.85, 0.3, 0.2}, Support = {0.7, 0.4, 1.0}, BC = {1, 0.8, 0.1} }
    local roleLabels = {Tank = "Tank", Healer = "Healer", DPS = "DPS", Support = "Support", BC = "Keystone"}
    local xOffset = 20
    for i, role in ipairs(roleTypes) do
        local checkbox = CreateFrame("CheckButton", "FrostSeekLFM_Role_" .. role, self.rolesFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("LEFT", rolesLabel, "RIGHT", xOffset, 0)
        checkbox:SetSize(18, 18)
        local text = _G[checkbox:GetName() .. "Text"]
        if text then
            text:SetText(roleLabels[role])
            text:SetFontObject("FSKFontNormalSmall")
            local rc = ROLE_COLORS[role] or {0.7, 0.7, 0.7}
            text:SetTextColor(rc[1], rc[2], rc[3])
        end
        checkbox:SetScript("OnClick", function(self)
            S.selectedRoles[role] = self:GetChecked()
            LFM.UpdateMessagePreview()
        end)
        self.roleCheckboxes[role] = checkbox

        local countBtn = CreateFrame("Button", nil, self.rolesFrame)
        countBtn:SetSize(28, 20)
        if text then
            countBtn:SetPoint("LEFT", text, "RIGHT", 4, 0)
        else
            countBtn:SetPoint("LEFT", checkbox, "RIGHT", 40, 0)
        end
        countBtn.bg = countBtn:CreateTexture(nil, "BACKGROUND")
        countBtn.bg:SetAllPoints()
        countBtn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
        countBtn.border = countBtn:CreateTexture(nil, "BORDER")
        countBtn.border:SetAllPoints()
        countBtn.border:SetColorTexture(0.3, 0.4, 0.5, 1.0)
        countBtn.text = countBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        countBtn.text:SetPoint("CENTER")
        local function UpdateCountText()
            countBtn.text:SetText("|cff44ff44" .. tostring(S.needCount[role] or 0) .. "|r")
        end
        UpdateCountText()

        countBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        countBtn:SetScript("OnClick", function(self, button)
            local cur = S.needCount[role] or 0
            local next
            if button == "RightButton" then
                next = math.max(0, cur - 1)
            else
                next = math.min(10, cur + 1)
            end
            S.needCount[role] = next
            UpdateCountText()
            LFM.UpdateMessagePreview()
        end)
        countBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["tip_required_role"] .. role, 1, 1, 1)
            GameTooltip:AddLine(L["tip_left_click_increase"], 0.8, 0.9, 1, true)
            GameTooltip:AddLine(L["tip_right_click_decrease"], 0.8, 0.9, 1, true)
            GameTooltip:AddLine(L["tip_range_0_10"], 0.6, 0.6, 0.6, true)
            GameTooltip:Show()
        end)
        countBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        self.roleCheckboxes[role .. "Count"] = countBtn
        xOffset = xOffset + 100
    end

    local difficultyLabel = self.rolesFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    difficultyLabel:SetPoint("LEFT", self.roleCheckboxes["Support"], "RIGHT", 70, 0)
    difficultyLabel:SetText(L["lfm_difficulty"] .. ":")
    difficultyLabel:SetTextColor(unpack(_tc("textMuted")))

    self.difficultyDropdown = CreateModernDropdown(self.rolesFrame, 100, 22)
    self.difficultyDropdown:SetPoint("LEFT", difficultyLabel, "RIGHT", 5, 0)
    self.difficultyDropdown:SetText(S.selectedDifficulty)
    self.difficultyDropdown.onChange = function(val)
        S.selectedDifficulty = val
        LFM.UpdateMessagePreview()
    end

    self.searchFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.searchFrame:SetSize(IW, 26)
    self.searchFrame:SetPoint("TOP", self.rolesFrame, "BOTTOM", 0, -4)

    local searchLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    searchLabel:SetPoint("LEFT", self.searchFrame, "LEFT", 10, 0)
    searchLabel:SetText(L["search"] .. ":")
    searchLabel:SetTextColor(unpack(_tc("textMuted")))

    self.searchBox = CreateModernEditBox(self.searchFrame, 160, 18)
    self.searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    self.searchBox:SetText("")
    self.searchBox:SetScript("OnTextChanged", function(self)
        S.searchText = self:GetText()
        ScheduleActivityListUpdate()
    end)

    self.clearSearchBtn = CreateModernButton(self.searchFrame, 45, 18, L["clear"], _tc("border"))
    self.clearSearchBtn:SetPoint("LEFT", self.searchBox, "RIGHT", 5, 0)
    self.clearSearchBtn:SetScript("OnClick", function()
        self.searchBox:SetText("")
        S.searchText = ""
        LFM.UpdateActivityList()
    end)

    local bcBtn = CreateFrame("CheckButton", "FrostSeekLFM_Role_BC", self.searchFrame, "UICheckButtonTemplate")
    bcBtn:SetSize(18, 18)
    bcBtn:SetPoint("RIGHT", self.searchFrame, "RIGHT", -160, 0)
    local bcText = _G[bcBtn:GetName() .. "Text"]
    if bcText then
        bcText:SetText(L["txt_bonus_coin"])
        bcText:SetFontObject("FSKFontNormalSmall")
        bcText:SetTextColor(1, 0.8, 0.1)
    end
    bcBtn:SetScript("OnClick", function(self)
        S.selectedRoles.BC = self:GetChecked()
        LFM.UpdateMessagePreview()
    end)
    bcBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(L["txt_bonus_coin_colored"], 1, 1, 1)
        GameTooltip:AddLine(L["tip_bonus_coin_enable"], 0.8, 0.9, 1, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine(L["tip_what_is_bonus_coin"], 0.8, 0.9, 1, true)
        GameTooltip:AddLine(L["tip_bonus_coin_explain"], 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(L["tip_bonus_coin_announce"], 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    bcBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.roleCheckboxes["BC"] = bcBtn
    self.bcBtn = bcBtn

    local function UpdateBCVisibility()
        if S.currentCategory == "KEYSTONE" then
            bcBtn:Show()
            if bcText then bcText:Show() end
        else
            bcBtn:Hide()
            if bcText then bcText:Hide() end
            S.selectedRoles.BC = false
            bcBtn:SetChecked(false)
        end
    end
    self.UpdateBCVisibility = UpdateBCVisibility

    self.categoriesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.categoriesFrame:SetSize(IW, 26)
    self.categoriesFrame:SetPoint("TOP", self.searchFrame, "BOTTOM", 0, -4)

    local allCategoryTabsInit = {
        { key = "RAIDS", name = L["cat_raid"] },
        { key = "DUNGEONS", name = L["cat_dungeon"] },
        { key = "MANASTORM", name = L["cat_manastorm"], profileOnly = "ascension" },
        { key = "WORLD_BOSS", name = L["cat_world_boss"] },
        { key = "PVP", name = L["cat_pvp"] },
        { key = "KEYSTONE", name = L["cat_keystone"] }
    }

    local SharedInit = _G.FrostSeekShared
    local initProfile = SharedInit and SharedInit.GetServerProfile and SharedInit.GetServerProfile() or "wotlk"

    local categoryTabs = {}
    for _, tabInfo in ipairs(allCategoryTabsInit) do
        if not tabInfo.profileOnly or tabInfo.profileOnly == initProfile then
            table.insert(categoryTabs, tabInfo)
        end
    end

    for i, tabInfo in ipairs(categoryTabs) do
        local tab = CreateFrame("Button", nil, self.categoriesFrame)
        tab:SetSize(70, 22)
        tab:SetPoint("LEFT", 10 + ((i-1) * 75), 0)

        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(unpack(_tc("bgBlock")))

        tab.text = tab:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabInfo.name)
        tab.text:SetTextColor(unpack(_tc("textPrimary")))

        tab:SetScript("OnClick", function()
            CloseAllDropdowns()
            ClearActiveEditBox()
            S.currentCategory = tabInfo.key
            if S.currentCategory == "KEYSTONE" then
                UpdateKeystoneList()
                StartKeystoneAutoUpdate()
                if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Show() end
            else
                StopKeystoneAutoUpdate()
                if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Hide() end
            end
            if self.UpdateBCVisibility then self.UpdateBCVisibility() end
            LFM.UpdateDifficultyDropdown()
            LFM.UpdateActivityList()
            LFM.UpdateTabsAppearance()
        end)

        tab:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        end)

        tab:SetScript("OnLeave", function(self)
            if tabInfo.key == S.currentCategory then
                self.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            else
                self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            end
        end)

        _G["LFM_Tab_" .. tabInfo.key] = tab
    end

    self.activitiesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.activitiesFrame:SetSize(IW, 200)
    self.activitiesFrame:SetPoint("TOP", self.categoriesFrame, "BOTTOM", 0, -6)

    local activitiesBg = self.activitiesFrame:CreateTexture(nil, "BACKGROUND")
    activitiesBg:SetAllPoints()
    activitiesBg:SetColorTexture(unpack(_tc("bgRowOdd")))
    self.activitiesScrollFrame = CreateFrame("ScrollFrame", "FrostSeekActivitiesScroll", self.activitiesFrame, "UIPanelScrollFrameTemplate")

    self.activitiesScrollFrame:SetPoint("TOPLEFT", 5, -5)
    self.activitiesScrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

    self.activitiesContent = CreateFrame("Frame", nil, self.activitiesScrollFrame)
    self.activitiesContent:SetSize(AW, 200)
    self.activitiesScrollFrame:SetScrollChild(self.activitiesContent)

    self.messageFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.messageFrame:SetSize(IW, 32)
    self.messageFrame:SetPoint("TOP", self.activitiesFrame, "BOTTOM", 0, -6)

    local messageLabel = self.messageFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    messageLabel:SetPoint("TOPLEFT", self.messageFrame, "TOPLEFT", 10, -2)
    messageLabel:SetText(L["lfm_message"] .. ":")
    messageLabel:SetTextColor(0.6, 0.8, 1)

    self.messageEditBox = CreateModernEditBox(self.messageFrame, 500, 20)
    self.messageEditBox:SetPoint("LEFT", messageLabel, "RIGHT", 5, 0)
    self.messageEditBox:SetPoint("RIGHT", self.messageFrame, "RIGHT", -10, 0)
    self.messageEditBox:SetText(S.customMessage)
    self.messageEditBox:SetMaxLetters(255)
    self.messageEditBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        S.customMessage = text
        FrostSeekDB.LFM.customMessage = S.customMessage
        if LFM.messageEditBox:HasFocus() then
            userEditedMessage = true
        end
    end)

    self.spamFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.spamFrame:SetSize(IW, 52)
    self.spamFrame:SetPoint("TOP", self.messageFrame, "BOTTOM", 0, -4)

    local spamLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    spamLabel:SetPoint("LEFT", self.spamFrame, "LEFT", 10, 12)
    spamLabel:SetText(L["lfm_spam"] .. ":")
    spamLabel:SetTextColor(0.6, 0.8, 1)

    local timerLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    timerLabel:SetPoint("LEFT", spamLabel, "RIGHT", 8, 0)
    timerLabel:SetText(L["lfm_every"])
    timerLabel:SetTextColor(unpack(_tc("textMuted")))

    self.spamTimerBox = CreateModernEditBox(self.spamFrame, 40, 18)
    self.spamTimerBox:SetPoint("LEFT", timerLabel, "RIGHT", 5, 0)
    self.spamTimerBox:SetText(tostring((FrostSeekDB and FrostSeekDB.LFM and FrostSeekDB.LFM.autoSpamInterval) or 30))
    self.spamTimerBox:SetMaxLetters(4)
    self.spamTimerBox:SetNumeric(true)

    local secLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    secLabel:SetPoint("LEFT", self.spamTimerBox, "RIGHT", 5, 0)
    secLabel:SetText("s")
    secLabel:SetTextColor(unpack(_tc("textMuted")))

    self.spamBtn = CreateModernButton(self.spamFrame, 76, 20, L["lfm_start_spam"], _tc("success"))
    self.spamBtn:SetPoint("LEFT", secLabel, "RIGHT", 10, 0)
    self.spamBtn:SetScript("OnClick", function()
        if S.autoSpamActive then
            LFM:StopAutoSpam()
        else
            LFM:StartAutoSpam()
        end
    end)

    self.spamStatusText = self.spamFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.spamStatusText:SetPoint("LEFT", self.spamBtn, "RIGHT", 10, 0)
    self.spamStatusText:SetText("")
    self.spamStatusText:Hide()

    local chLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    chLabel:SetPoint("LEFT", self.spamFrame, "LEFT", 10, -12)
    chLabel:SetText(L["lfm_channel"] .. ":")
    chLabel:SetTextColor(unpack(_tc("textMuted")))

    local ADDON_CHANNEL_BLACKLIST = {
        ["FSK"]          = true,
        [" FSK"]         = true,
        ["FrostSeek"]    = true,
        ["FrostNet"]     = true,
        ["BLFG"]         = true,
        ["BBLC25C"]      = true,
        ["HGE"]          = true,
        ["FSK-EVT"]      = true,
    }

    local function IsAddonChannel(channelName)
        if not channelName or channelName == "" then return false end
        local trimmed = string.match(channelName, "^%s*(.-)%s*$") or channelName
        if trimmed == "" then return false end
        local key = string.upper(trimmed)
        if ADDON_CHANNEL_BLACKLIST[key] then return true end
        local keyWithSpace = " " .. key
        if ADDON_CHANNEL_BLACKLIST[keyWithSpace] then return true end
        return false
    end

    local function GetChannelSlotName(slotIndex)
        local ok, id, name = pcall(function() return GetChannelName(slotIndex) end)
        if ok and type(id) == "number" and id > 0 and name and tostring(name) ~= "" then
            local chName = tostring(name)
            if IsAddonChannel(chName) then return nil end
            return chName
        end
        return nil
    end

    self.spamChannelButtons = {}
    self.spamChannelLabels = {}
    for i = 1, 10 do
        local chSlotName = GetChannelSlotName(i)
        local btnLabel = chSlotName and string.sub(chSlotName, 1, 5) or tostring(i)
        local btn = CreateSmallToggle(self.spamFrame, btnLabel,
            80 + (i-1) * 40, -12, 34, 20,
            function(active)
                S.spamChannels[i] = active
                if not FrostSeekDB.LFM.spamChannels then FrostSeekDB.LFM.spamChannels = {} end
                FrostSeekDB.LFM.spamChannels[i] = active
            end
        )

        if chSlotName then
            btn:SetScript("OnEnter", function(selfBtn)
                GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
                GameTooltip:AddLine(L["tip_channel_n"] .. i .. ": " .. chSlotName, 1, 1, 1)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(selfBtn)
                GameTooltip:Hide()
            end)
        end
        if FrostSeekDB.LFM.spamChannels and FrostSeekDB.LFM.spamChannels[i] then
            btn.active = true
            S.spamChannels[i] = true
            if chSlotName then
                btn.bg:SetColorTexture(unpack(_tc("success")))
                btn.text:SetTextColor(0.4, 1, 0.4)
            else
                btn.bg:SetColorTexture(unpack(_tc("textDim")))
                btn.text:SetTextColor(0.5, 0.5, 0.5)
            end
        elseif not chSlotName then
            btn.text:SetTextColor(0.4, 0.4, 0.4)
        end
        self.spamChannelButtons[i] = btn
    end

    self.refreshChannelTimer = C_Timer.NewTicker(5, function()
        for i = 1, 10 do
            local btn = self.spamChannelButtons[i]
            if btn then
                local chSlotName = GetChannelSlotName(i)
                local newLabel = chSlotName and string.sub(chSlotName, 1, 5) or tostring(i)
                if btn.text then
                    btn.text:SetText(newLabel)
                end
                if chSlotName then
                    btn:SetScript("OnEnter", function(selfBtn)
                        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
                        GameTooltip:AddLine(L["tip_channel_n"] .. i .. ": " .. chSlotName, 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function(selfBtn)
                        GameTooltip:Hide()
                    end)
                    if S.spamChannels[i] then
                        btn.bg:SetColorTexture(unpack(_tc("success")))
                        btn.text:SetTextColor(0.4, 1, 0.4)
                    else
                        btn.text:SetTextColor(1, 1, 1)
                    end
                else
                    btn:SetScript("OnEnter", function(selfBtn)
                        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
                        GameTooltip:AddLine(L["tip_channel_n"] .. i .. L["tip_channel_empty"], 0.6, 0.6, 0.6)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function(selfBtn)
                        GameTooltip:Hide()
                    end)
                    btn.text:SetTextColor(0.4, 0.4, 0.4)
                end
            end
        end
    end)

    self.autoInviteFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.autoInviteFrame:SetSize(IW, 28)
    self.autoInviteFrame:SetPoint("TOP", self.spamFrame, "BOTTOM", 0, -4)

    local aiLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    aiLabel:SetPoint("LEFT", self.autoInviteFrame, "LEFT", 10, 0)
    aiLabel:SetText(L["lfm_auto_invite"] .. ":")
    aiLabel:SetTextColor(0.6, 0.8, 1)

    self.autoInviteToggle = CreateSmallToggle(self.autoInviteFrame, "ON/OFF", 90, 0, 50, 20,
        function(active)
            S.autoInviteEnabled = active
            FrostSeekDB.LFM.autoInviteEnabled = active
            if active then
                print(L["msg_auto_invite_enabled_ilvl"] .. S.autoInviteMinIlvl .. L["msg_min_lvl_inline"] .. S.autoInviteMinLevel .. ")")
            else
                print(L["msg_auto_invite_disabled"])
            end
        end
    )

    if FrostSeekDB.LFM.autoInviteEnabled then
        self.autoInviteToggle.active = true
        S.autoInviteEnabled = true
        self.autoInviteToggle.bg:SetColorTexture(unpack(_tc("success")))
        self.autoInviteToggle.text:SetTextColor(0.4, 1, 0.4)
    end

    local minIlvlLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    minIlvlLabel:SetPoint("LEFT", self.autoInviteToggle, "RIGHT", 10, 0)
    minIlvlLabel:SetText(L["lfm_min_ilvl"] .. ":")
    minIlvlLabel:SetTextColor(unpack(_tc("textMuted")))

    self.minIlvlBox = CreateModernEditBox(self.autoInviteFrame, 50, 18)
    self.minIlvlBox:SetPoint("LEFT", minIlvlLabel, "RIGHT", 5, 0)
    self.minIlvlBox:SetMaxLetters(4)
    self.minIlvlBox:SetNumeric(true)
    self.minIlvlBox._fskLastClickTime = 0
    pcall(function()
        self.minIlvlBox:SetScript("OnMouseUp", function(self, button)
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
    local stored = FrostSeekDB.LFM.autoInviteMinIlvl
    local displayVal
    if stored == nil or stored == 0 then
        local pi = PlayerIlvl()
        displayVal = pi > 0 and math.max(0, pi - 5) or 150
        S.autoInviteMinIlvl = displayVal
        FrostSeekDB.LFM.autoInviteMinIlvl = displayVal
    else
        displayVal = stored
        S.autoInviteMinIlvl = stored
    end
    local _suppressTextHandler = true
    self.minIlvlBox:SetText(tostring(displayVal))
    _suppressTextHandler = false

    local plusLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    plusLabel:SetPoint("LEFT", self.minIlvlBox, "RIGHT", 3, 0)
    plusLabel:SetText("+")
    plusLabel:SetTextColor(0.4, 1, 0.4)

    self.minIlvlBox:SetScript("OnTextChanged", function(self)
        if _suppressTextHandler then return end
        local val = tonumber(self:GetText()) or 0
        S.autoInviteMinIlvl = val
        FrostSeekDB.LFM.autoInviteMinIlvl = val
    end)

    local minLevelLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    minLevelLabel:SetPoint("LEFT", plusLabel, "RIGHT", 15, 0)
    minLevelLabel:SetText(L["lfm_min_level"] .. ":")
    minLevelLabel:SetTextColor(unpack(_tc("textMuted")))

    self.minLevelBox = CreateModernEditBox(self.autoInviteFrame, 40, 18)
    self.minLevelBox:SetPoint("LEFT", minLevelLabel, "RIGHT", 5, 0)
    self.minLevelBox:SetText(tostring(FrostSeekDB.LFM.autoInviteMinLevel or 60))
    self.minLevelBox:SetMaxLetters(3)
    self.minLevelBox:SetNumeric(true)
    self.minLevelBox._fskLastClickTime = 0
    pcall(function()
        self.minLevelBox:SetScript("OnMouseUp", function(self, button)
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
    S.autoInviteMinLevel = FrostSeekDB.LFM.autoInviteMinLevel or 60

    self.minLevelBox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText()) or 0
        S.autoInviteMinLevel = val
        FrostSeekDB.LFM.autoInviteMinLevel = val
    end)

    local aiDesc = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    aiDesc:SetPoint("LEFT", self.minLevelBox, "RIGHT", 8, 0)
    aiDesc:SetText(L["txt_invites_on_whisper"])
    aiDesc:SetTextColor(unpack(_tc("textDim")))

    local autoStopFrame = CreateFrame("Frame", nil, self.mainContainer)
    autoStopFrame:SetSize(IW, 28)
    autoStopFrame:SetPoint("TOP", self.autoInviteFrame, "BOTTOM", 0, -4)
    self.autoStopFrame = autoStopFrame

    local asLabel = autoStopFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    asLabel:SetPoint("LEFT", autoStopFrame, "LEFT", 10, 0)
    asLabel:SetText(_hex("accent") .. L["options_lfm_auto_stop"] .. "|r")
    asLabel:SetTextColor(unpack(_tc("textPrimary")))

    local asStopValues = { 0, 5, 10, 15, 20, 25, 40 }
    local asStopBtn = CreateFrame("Button", nil, autoStopFrame)
    asStopBtn:SetSize(80, 20)
    asStopBtn:SetPoint("LEFT", asLabel, "RIGHT", 8, 0)
    asStopBtn.bg = asStopBtn:CreateTexture(nil, "BACKGROUND")
    asStopBtn.bg:SetAllPoints()
    asStopBtn.bg:SetColorTexture(0.1, 0.1, 0.15, 0.95)
    asStopBtn.border = asStopBtn:CreateTexture(nil, "BORDER")
    asStopBtn.border:SetAllPoints()
    asStopBtn.border:SetColorTexture(0.3, 0.4, 0.5, 1.0)
    asStopBtn.text = asStopBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    asStopBtn.text:SetPoint("CENTER")
    self.autoStopBtn = asStopBtn

    local function UpdateAutoStopBtnText()
        local v = FrostSeekDB.LFM.autoStopMemberCount or 0
        if v == 0 then
            asStopBtn.text:SetText("|cff888888" .. L["disabled"] .. "|r")
        else
            asStopBtn.text:SetText("|cff44ff44" .. tostring(v) .. "|r")
        end
    end
    UpdateAutoStopBtnText()

    asStopBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    asStopBtn:SetScript("OnClick", function(self, button)
        local cur = FrostSeekDB.LFM.autoStopMemberCount or 0
        local idx = 1
        for i, v in ipairs(asStopValues) do
            if v == cur then idx = i; break end
        end
        local nextVal
        if button == "RightButton" then
            nextVal = asStopValues[idx == 1 and #asStopValues or idx - 1]
        else
            nextVal = asStopValues[(idx % #asStopValues) + 1]
        end
        FrostSeekDB.LFM.autoStopMemberCount = nextVal
        UpdateAutoStopBtnText()
        if nextVal == 0 then
            print(L["msg_auto_stop_disabled"])
        else
            print(L["msg_auto_stop_at"] .. nextVal .. L["msg_members_count"])
        end
    end)
    asStopBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["options_lfm_auto_stop"], 1, 1, 1)
        GameTooltip:AddLine(L["tip_left_click_increase"], 0.8, 0.9, 1, true)
        GameTooltip:AddLine(L["tip_right_click_decrease"], 0.8, 0.9, 1, true)
        GameTooltip:Show()
    end)
    asStopBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local asDesc = autoStopFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    asDesc:SetPoint("LEFT", asStopBtn, "RIGHT", 8, 0)
    asDesc:SetText(_hex("textDim") .. L["options_lfm_auto_stop_desc"] .. "|r")

    self.controlsFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.controlsFrame:SetSize(IW, 32)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 8)

    self.sendAllBtn = CreateModernButton(self.controlsFrame, 76, 22, L["lfm_send_all"], _tc("warning"))
    self.sendAllBtn:SetPoint("RIGHT", -5, 20)
    self.sendAllBtn:SetScript("OnClick", function(btn)
        local message = LFM.messageEditBox:GetText()
        if message and message ~= "" then
            local warning = ValidateGroupComposition()
            if warning then
                print(L["msg_lfm_warning_prefix"] .. warning)
            end
            local sent = SendToAllSpamChannels(message)
            if sent > 0 then
                print(L["msg_lfm_sent_to"] .. sent .. L["msg_channel_count_suffix"])
                if Shared and Shared.PlaySound then
                    Shared.PlaySound("listing")
                end
            else
                print(L["msg_no_spam_channels"])
            end
        else
            print(L["msg_no_message_to_send"])
        end
    end)
    self.sendAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["lfm_send_all_tooltip"], 1, 1, 1)
        GameTooltip:AddLine(L["tip_sends_to_all_ch"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    self.sendAllBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    LFM.UpdateDifficultyDropdown()
    LFM.UpdateTabsAppearance()
    LFM.UpdateActivityList()
    if self.UpdateBCVisibility then self.UpdateBCVisibility() end

    self.frame:Hide()
end

function LFM:Show()
    if not self.frame then return end
    if S.currentCategory == "KEYSTONE" then
        UpdateKeystoneList()
        StartKeystoneAutoUpdate()
        if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Show() end
    else
        StopKeystoneAutoUpdate()
        if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Hide() end
    end
    if self.UpdateBCVisibility then self.UpdateBCVisibility() end
    self.frame:Show()
end

function LFM:Hide()
    if self.frame then self.frame:Hide() end
    StopKeystoneAutoUpdate()
end

function LFM:RefreshData()
    LFM.UpdateActivityList()
    LFM.UpdateMessagePreview()
end

local bagUpdateHandler = CreateFrame("Frame")
bagUpdateHandler:RegisterEvent("BAG_UPDATE_DELAYED")
bagUpdateHandler:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" and S.currentCategory == "KEYSTONE" then
        C_Timer.After(0.5, function()
            UpdateKeystoneList()
        end)
    end
end)

