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
local Setup = {}

local L = FrostSeek and FrostSeek.L or {}
local _tc = _G.FrostSeekShared and _G.FrostSeekShared._tc or function(t) return {0.5, 0.5, 0.5} end

local wizardFrame = nil
local currentPage = 1
local TOTAL_PAGES = 4
local ShowPage

local pageFrames = {}
local pageRefreshers = {}
local pagesBuilt = false
local showScheduled = false

local wizardState = {
    language = "auto",
    role = "No Role",
    enablePopups = false,
    enableChatFilter = false,
    theme = "Shadow",
    discord = "",
}


local function L_(key, default)
    return L[key] or default or key
end

local function SetVisible(widget, visible)
    if not widget then return end
    if visible then
        if widget.Show then widget:Show() end
    else
        if widget.Hide then widget:Hide() end
    end
end

local function SetSolidColor(texture, r, g, b, a)
    if not texture then return end
    if texture.SetColorTexture then
        texture:SetColorTexture(r, g, b, a)
    else
        texture:SetTexture(r, g, b, a or 1)
    end
end

local function CreateModernButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 120, height or 28)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    SetSolidColor(btn.bg, unpack(_tc("bgButton")))
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    SetSolidColor(btn.border, unpack(_tc("border")))
    btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(_tc("textPrimary")))
    btn._baseWidth = width or 120
    btn.FitText = function(self)
        local ok, w = pcall(function() return self.text:GetStringWidth() end)
        if ok and type(w) == "number" and w > 0 then
            local desired = math.ceil(w) + 24
            if desired > self._baseWidth then
                self:SetWidth(desired)
            else
                self:SetWidth(self._baseWidth)
            end
        end
    end
    btn:FitText()
    btn:SetScript("OnEnter", function(self)
        SetSolidColor(self.bg, unpack(_tc("bgTabActive")))
        self.text:SetTextColor(unpack(_tc("textAccent")))
        SetSolidColor(self.border, unpack(_tc("borderHover")))
    end)
    btn:SetScript("OnLeave", function(self)
        SetSolidColor(self.bg, unpack(_tc("bgButton")))
        self.text:SetTextColor(unpack(_tc("textPrimary")))
        SetSolidColor(self.border, unpack(_tc("border")))
    end)
    return btn
end

local function BuildPage1(content)
    local cw = content:GetWidth()
    if not cw or cw < 300 then cw = 610 end

    local title = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetTextColor(unpack(_tc("textAccent")))

    local desc = content:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -15)
    desc:SetTextColor(unpack(_tc("textMuted")))

    local langLabel = content:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    langLabel:SetPoint("TOP", desc, "BOTTOM", 0, -40)
    langLabel:SetTextColor(unpack(_tc("textPrimary")))

    local langBtn = CreateModernButton(content, "auto", 200, 32)
    langBtn:SetPoint("TOP", langLabel, "BOTTOM", 0, -10)

    local function GetLangDisplay(v)
        if v == "auto" then return L["settings_language_auto"] end
        return v
    end

    local function UpdateLangBtn()
        langBtn.text:SetText(GetLangDisplay(wizardState.language))
        langBtn:FitText()
    end

    local themeLabel = content:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    themeLabel:SetPoint("TOP", langBtn, "BOTTOM", 0, -28)
    themeLabel:SetTextColor(unpack(_tc("textPrimary")))

    local themeBtn = CreateModernButton(content, wizardState.theme or "Shadow", 200, 32)
    themeBtn:SetPoint("TOP", themeLabel, "BOTTOM", 0, -10)

    local function UpdateThemeBtn()
        themeBtn.text:SetText(wizardState.theme or "Shadow")
        themeBtn:FitText()
    end

    local note = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    note:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    note:SetWidth(cw - 80)
    note:SetTextColor(unpack(_tc("textDim")))
    note:SetJustifyH("CENTER")
    note:SetWordWrap(true)

    langBtn:SetScript("OnClick", function()
        local codes = { "auto" }
        if FrostSeek and FrostSeek.GetAvailableLocales then
            for _, c in ipairs(FrostSeek.GetAvailableLocales()) do
                table.insert(codes, c)
            end
        else
            codes = { "auto", "enUS", "itIT", "frFR", "deDE", "esES", "ptBR" }
        end
        local idx = 1
        for i, c in ipairs(codes) do
            if c == wizardState.language then idx = i; break end
        end
        wizardState.language = codes[(idx % #codes) + 1] or "auto"
        if not FrostSeekDB then FrostSeekDB = {} end
        if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
        FrostSeekDB.Settings.language = wizardState.language
        ShowPage(currentPage)
    end)

    themeBtn:SetScript("OnClick", function()
        local themes = { "Frost", "Blood", "Emerald", "Void", "Classic", "Neon",
                         "Shadow", "Horde", "Alliance", "Plague", "Druid",
                         "Warlock", "Northrend", "Dragon", "Titan" }
        if FrostSeekTheme and FrostSeekTheme.GetThemes then
            local ok, list = pcall(function() return FrostSeekTheme.GetThemes() end)
            if ok and type(list) == "table" and #list > 0 then themes = list end
        end
        local idx = 1
        for i, t in ipairs(themes) do
            if t == wizardState.theme then idx = i break end
        end
        wizardState.theme = themes[(idx % #themes) + 1] or "Shadow"
        if FrostSeekTheme and FrostSeekTheme.Set then
            pcall(function()
                FrostSeekTheme.Set(wizardState.theme)
                if FrostSeekTheme.Apply then FrostSeekTheme.Apply() end
            end)
        end
        UpdateThemeBtn()
    end)

    local function RefreshTexts()
        title:SetText(L["setup_page_1_title"])
        desc:SetText(L["setup_page_1_desc"])
        langLabel:SetText(L["settings_language"] .. ":")
        themeLabel:SetText((L["options_theme"] or "Theme") .. ":")
        note:SetText(L_("setup_page_1_note", ""))
        UpdateLangBtn()
        UpdateThemeBtn()
    end

    RefreshTexts()
    return RefreshTexts
end

local function BuildPage2(content)
    local title = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetTextColor(unpack(_tc("textAccent")))

    local body = content:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    body:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 20)
    body:SetTextColor(unpack(_tc("textPrimary")))
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)

    local function RefreshTexts()
        title:SetText(L["setup_page_2_title"])
        body:SetText(L_("setup_page_2_body", ""))
    end

    RefreshTexts()
    return RefreshTexts
end

local function BuildPage3(content)
    local cw = content:GetWidth()
    if not cw or cw < 300 then cw = 610 end

    local title = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetTextColor(unpack(_tc("textAccent")))

    local desc = content:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetWidth(cw - 40)
    desc:SetTextColor(unpack(_tc("textMuted")))

    local popupsBtn = CreateModernButton(content, L["setup_enable_popups"], 320, 36)
    popupsBtn:SetPoint("TOPLEFT", 40, -86)
    local function UpdatePopupsBtn()
        if wizardState.enablePopups then
            popupsBtn.text:SetText(L["setup_enable_popups"] .. ": |cff44ff44" .. L["on"] .. "|r")
        else
            popupsBtn.text:SetText(L["setup_enable_popups"] .. ": |cffff5555" .. L["off"] .. "|r")
        end
        popupsBtn:FitText()
    end

    local popupsDesc = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    popupsDesc:SetPoint("TOPLEFT", popupsBtn, "BOTTOMLEFT", 6, -8)
    popupsDesc:SetWidth(cw - 100)
    popupsDesc:SetTextColor(unpack(_tc("textDim")))
    popupsDesc:SetJustifyH("LEFT")
    popupsDesc:SetWordWrap(true)

    local chatFilterBtn = CreateModernButton(content, L["setup_enable_chat_filter"], 320, 36)
    chatFilterBtn:SetPoint("TOPLEFT", popupsDesc, "BOTTOMLEFT", -6, -16)
    local function UpdateChatFilterBtn()
        if wizardState.enableChatFilter then
            chatFilterBtn.text:SetText(L["setup_enable_chat_filter"] .. ": |cff44ff44" .. L["on"] .. "|r")
        else
            chatFilterBtn.text:SetText(L["setup_enable_chat_filter"] .. ": |cffff5555" .. L["off"] .. "|r")
        end
        chatFilterBtn:FitText()
    end

    local chatFilterDesc = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    chatFilterDesc:SetPoint("TOPLEFT", chatFilterBtn, "BOTTOMLEFT", 6, -8)
    chatFilterDesc:SetWidth(cw - 100)
    chatFilterDesc:SetTextColor(unpack(_tc("textDim")))
    chatFilterDesc:SetJustifyH("LEFT")
    chatFilterDesc:SetWordWrap(true)

    popupsBtn:SetScript("OnClick", function()
        wizardState.enablePopups = not wizardState.enablePopups
        UpdatePopupsBtn()
    end)

    chatFilterBtn:SetScript("OnClick", function()
        wizardState.enableChatFilter = not wizardState.enableChatFilter
        UpdateChatFilterBtn()
    end)

    local function RefreshTexts()
        title:SetText(L["setup_page_3_title"])
        desc:SetText(L["setup_page_3_desc"])
        popupsDesc:SetText(L_("setup_page_3_popups_desc", ""))
        chatFilterDesc:SetText(L_("setup_page_3_chatfilter_desc", ""))
        UpdatePopupsBtn()
        UpdateChatFilterBtn()
    end

    RefreshTexts()
    return RefreshTexts
end

local function BuildPage4(content)
    local cw = content:GetWidth()
    if not cw or cw < 300 then cw = 610 end

    local title = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -30)
    title:SetTextColor(unpack(_tc("textAccent")))

    local body = content:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -80)
    body:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 60)
    body:SetTextColor(unpack(_tc("textPrimary")))
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)

    local hint = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    hint:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    hint:SetTextColor(unpack(_tc("textDim")))

    local extra = content:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    extra:SetPoint("BOTTOM", hint, "TOP", 0, 10)
    extra:SetWidth(cw - 80)
    extra:SetTextColor(unpack(_tc("textMuted")))
    extra:SetJustifyH("CENTER")
    extra:SetWordWrap(true)

    local function RefreshTexts()
        title:SetText(L["setup_page_4_title"])
        body:SetText(L_("setup_page_4_body", ""))
        hint:SetText(L["setup_finish_hint"])
        extra:SetText(L_("setup_page_4_extra", ""))
    end

    RefreshTexts()
    return RefreshTexts
end

local pageBuilders = {
    [1] = BuildPage1,
    [2] = BuildPage2,
    [3] = BuildPage3,
    [4] = BuildPage4,
}

local function EnsurePages()
    if pagesBuilt then return end
    if not (wizardFrame and wizardFrame.content) then return end
    pagesBuilt = true
    for i = 1, TOTAL_PAGES do
        local container = CreateFrame("Frame", nil, wizardFrame.content)
        container:SetAllPoints()
        container:Hide()
        pageFrames[i] = container
        local builder = pageBuilders[i]
        if builder then
            local ok, refresher = pcall(builder, container)
            if ok and type(refresher) == "function" then
                pageRefreshers[i] = refresher
            end
        end
    end
end


local function UpdateNavButtons()
    if not wizardFrame then return end
    SetVisible(wizardFrame.backBtn, currentPage > 1)
    SetVisible(wizardFrame.nextBtn, currentPage < TOTAL_PAGES)
    SetVisible(wizardFrame.finishBtn, currentPage == TOTAL_PAGES)
    wizardFrame.pageText:SetText(string.format("%d / %d", currentPage, TOTAL_PAGES))
    if wizardFrame.titleBar then
        wizardFrame.titleBar:SetText("|cff88ccff" .. (L["setup_title"]) .. "|r")
    end
    if wizardFrame.backBtn and wizardFrame.backBtn.text then
        wizardFrame.backBtn.text:SetText(L["setup_back"])
        wizardFrame.backBtn:FitText()
    end
    if wizardFrame.nextBtn and wizardFrame.nextBtn.text then
        wizardFrame.nextBtn.text:SetText(L["setup_next"])
        wizardFrame.nextBtn:FitText()
    end
    if wizardFrame.finishBtn and wizardFrame.finishBtn.text then
        wizardFrame.finishBtn.text:SetText(L["setup_finish"])
        wizardFrame.finishBtn:FitText()
    end
    if wizardFrame.skipBtn and wizardFrame.skipBtn.text then
        wizardFrame.skipBtn.text:SetText(L["setup_skip"])
        wizardFrame.skipBtn:FitText()
    end
end

function ShowPage(pageNum)
    if pageNum < 1 or pageNum > TOTAL_PAGES then return end
    currentPage = pageNum
    for i = 1, TOTAL_PAGES do
        SetVisible(pageFrames[i], i == currentPage)
    end
    if pageRefreshers[currentPage] then
        pcall(pageRefreshers[currentPage])
    end
    UpdateNavButtons()
end

function Setup.Show()
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.theme then
        wizardState.theme = FrostSeekDB.Settings.theme
    end
    if wizardFrame then wizardFrame:Show() ShowPage(1) return end

    local backdropTemplate = ""
    if _G.FrostSeekCompat and _G.FrostSeekCompat.GetBackdropTemplateStr then
        backdropTemplate = _G.FrostSeekCompat.GetBackdropTemplateStr()
    end

    wizardFrame = CreateFrame("Frame", "FrostSeekSetupFrame", UIParent,
        backdropTemplate ~= "" and backdropTemplate or nil)
    wizardFrame:SetSize(640, 520)
    wizardFrame:SetPoint("CENTER")
    wizardFrame:SetFrameStrata("DIALOG")
    wizardFrame:EnableMouse(true)
    wizardFrame:SetMovable(true)
    wizardFrame:RegisterForDrag("LeftButton")
    wizardFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    wizardFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    wizardFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    wizardFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.97)
    wizardFrame:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)

    local titleBar = wizardFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    titleBar:SetPoint("TOP", wizardFrame, "TOP", 0, -18)

    if FSK_FontSystem and FSK_FontSystem.SafeText then
        FSK_FontSystem.SafeText(titleBar, "FSKFontNormalLarge",
            "|cff88ccff" .. (L["setup_title"]) .. "|r")
    else
        pcall(titleBar.SetText, titleBar, "|cff88ccff" .. (L["setup_title"]) .. "|r")
    end
    wizardFrame.titleBar = titleBar

    local setupLogo = wizardFrame:CreateTexture(nil, "OVERLAY")
    pcall(function()
        setupLogo:SetTexture("Interface\\AddOns\\FrostSeek\\Media\\texture\\logo.tga")
        setupLogo:SetSize(32, 32)
        setupLogo:SetPoint("TOPLEFT", wizardFrame, "TOPLEFT", 14, -12)
    end)
    wizardFrame.logo = setupLogo

    wizardFrame.pageText = wizardFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    wizardFrame.pageText:SetPoint("TOPRIGHT", wizardFrame, "TOPRIGHT", -20, -18)
    wizardFrame.pageText:SetTextColor(unpack(_tc("textDim")))

    wizardFrame.content = CreateFrame("Frame", nil, wizardFrame)
    wizardFrame.content:SetPoint("TOPLEFT", wizardFrame, "TOPLEFT", 15, -45)
    wizardFrame.content:SetPoint("BOTTOMRIGHT", wizardFrame, "BOTTOMRIGHT", -15, 50)

    wizardFrame.backBtn = CreateModernButton(wizardFrame, L["setup_back"], 100, 30)
    wizardFrame.backBtn:SetPoint("BOTTOMLEFT", wizardFrame, "BOTTOMLEFT", 30, 15)
    wizardFrame.backBtn:SetScript("OnClick", function() ShowPage(currentPage - 1) end)

    wizardFrame.nextBtn = CreateModernButton(wizardFrame, L["setup_next"], 100, 30)
    wizardFrame.nextBtn:SetPoint("BOTTOMRIGHT", wizardFrame, "BOTTOMRIGHT", -30, 15)
    wizardFrame.nextBtn:SetScript("OnClick", function() ShowPage(currentPage + 1) end)

    wizardFrame.finishBtn = CreateModernButton(wizardFrame, L["setup_finish"], 120, 32)
    wizardFrame.finishBtn:SetPoint("BOTTOMRIGHT", wizardFrame, "BOTTOMRIGHT", -30, 15)
    wizardFrame.finishBtn.text:SetTextColor(0.4, 1, 0.4)
    wizardFrame.finishBtn:SetScript("OnClick", function()
        if not FrostSeekDB then FrostSeekDB = {} end
        if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
        FrostSeekDB.Settings.setupCompleted = true
        FrostSeekDB.Settings.language = wizardState.language
        if wizardState.theme then
            FrostSeekDB.Settings.theme = wizardState.theme
        end
        if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
        FrostSeekDB.LFG.disablePopups = not wizardState.enablePopups
        FrostSeekDB.LFG.chatFilterEnabled = wizardState.enableChatFilter

        print(L["msg_setup_complete"])
        if ReloadUI then
            ReloadUI()
        elseif C_UI and C_UI.Reload then
            C_UI.Reload()
        end
    end)

    wizardFrame.skipBtn = CreateModernButton(wizardFrame, L["setup_skip"], 130, 26)
    wizardFrame.skipBtn:SetPoint("BOTTOMLEFT", wizardFrame.backBtn, "BOTTOMRIGHT", 10, 0)
    wizardFrame.skipBtn.text:SetTextColor(unpack(_tc("textDim")))
    wizardFrame.skipBtn:SetScript("OnClick", function()
        if not FrostSeekDB then FrostSeekDB = {} end
        if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
        FrostSeekDB.Settings.setupCompleted = true
        wizardFrame:Hide()
        print(L["msg_setup_skipped"])
    end)

    EnsurePages()

    wizardFrame:Show()
    ShowPage(1)

    if _G.UISpecialFrames then
        tinsert(_G.UISpecialFrames, "FrostSeekSetupFrame")
    end
end

function Setup.ShouldShow()
    if not FrostSeekDB or not FrostSeekDB.Settings then return false end
    return FrostSeekDB.Settings.setupCompleted ~= true
end

function Setup.MaybeShow()
    if showScheduled then return end
    if wizardFrame and wizardFrame.IsShown and wizardFrame:IsShown() then return end
    if Setup.ShouldShow() then
        showScheduled = true
        C_Timer.After(4, function()
            showScheduled = false
            local msgh = _G.debugstack or debug.traceback
            local ok, err = xpcall(Setup.Show, msgh)
            if not ok then
                local handler = _G.geterrorhandler or function(e) print(e) end
                handler(err)
            end
        end)
    end
end

SLASH_FSSETUP1 = "/fsetup"
SLASH_FSSETUP2 = "/fssetup"
SlashCmdList["FSSETUP"] = function()
    Setup.Show()
end

_G.FrostSeekSetup = Setup

local setupEventFrame = CreateFrame("Frame")
setupEventFrame:RegisterEvent("PLAYER_LOGIN")
setupEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(3, function()
            Setup.MaybeShow()
        end)
    end
end)

return Setup
