--[[
==============================================================================
 FrostSeek - First-Install Setup Wizard (v2.2.5)
==============================================================================
 A 4-page setup wizard that fires on first install (when setupCompleted == false):
   Page 1: Language picker
   Page 2: Welcome message (localized) explaining how the addon works
   Page 3: Role + popups + FrostNet profile + sounds + theme
   Page 4: Thank-you message from Ayro + Finish button (reload UI)
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

local wizardState = {
    language = "auto",
    role = "No Role",
    enablePopups = false,
    enableSounds = true,
    enableChatFilter = false,
    theme = "Shadow",
    discord = "",
}


local function L_(key, default)
    return L[key] or default or key
end

local function CreateModernButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 120, height or 28)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(unpack(_tc("bgButton")))
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    btn.border:SetColorTexture(unpack(_tc("border")))
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(_tc("textPrimary")))
    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(unpack(_tc("bgTabActive")))
        self.text:SetTextColor(unpack(_tc("textAccent")))
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpack(_tc("bgButton")))
        self.text:SetTextColor(unpack(_tc("textPrimary")))
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    return btn
end

--noah
local function ClearPageContent(content)
    if not content then return end
    local children = { content:GetChildren() }
    for _, child in ipairs(children) do
        if child and child.Hide then child:Hide() end
    end
    local regions = { content:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.Hide then region:Hide() end
    end
end

local function RenderPage1(content)
    ClearPageContent(content)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText(L["setup_page_1_title"])
    title:SetTextColor(unpack(_tc("textAccent")))

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -15)
    desc:SetText(L["setup_page_1_desc"])
    desc:SetTextColor(unpack(_tc("textMuted")))

    local langLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langLabel:SetPoint("TOP", desc, "BOTTOM", 0, -40)
    langLabel:SetText(L["settings_language"] .. ":")
    langLabel:SetTextColor(unpack(_tc("textPrimary")))

    local langBtn = CreateModernButton(content, "auto", 200, 32)
    langBtn:SetPoint("TOP", langLabel, "BOTTOM", 0, -10)

    local function GetLangDisplay(v)
        if v == "auto" then return L["settings_language_auto"] end
        return v
    end

    local function UpdateLangBtn()
        langBtn.text:SetText(GetLangDisplay(wizardState.language))
    end
    UpdateLangBtn()

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
        UpdateLangBtn()
        ShowPage(currentPage)
    end)
end

local function RenderPage2(content)
    ClearPageContent(content)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText(L["setup_page_2_title"])
    title:SetTextColor(unpack(_tc("textAccent")))

    local body = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    body:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 20)
    body:SetText(L_("setup_page_2_body", ""))
    body:SetTextColor(unpack(_tc("textPrimary")))
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
end

local function RenderPage3(content)
    ClearPageContent(content)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText(L["setup_page_3_title"])
    title:SetTextColor(unpack(_tc("textAccent")))

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText(L["setup_page_3_desc"])
    desc:SetTextColor(unpack(_tc("textMuted")))


    local popupsBtn = CreateModernButton(content, L["setup_enable_popups"], 320, 36)
    popupsBtn:SetPoint("TOPLEFT", 60, -100)
    local function UpdatePopupsBtn()
        if wizardState.enablePopups then
            popupsBtn.text:SetText(L["setup_enable_popups"] .. ": |cff44ff44" .. L["on"] .. "|r")
        else
            popupsBtn.text:SetText(L["setup_enable_popups"] .. ": |cffff5555" .. L["off"] .. "|r")
        end
    end
    UpdatePopupsBtn()
    popupsBtn:SetScript("OnClick", function()
        wizardState.enablePopups = not wizardState.enablePopups
        UpdatePopupsBtn()
    end)

    local soundsBtn = CreateModernButton(content, L["setup_enable_sounds"], 320, 36)
    soundsBtn:SetPoint("TOPLEFT", 60, -150)
    local function UpdateSoundsBtn()
        if wizardState.enableSounds then
            soundsBtn.text:SetText(L["setup_enable_sounds"] .. ": |cff44ff44" .. L["on"] .. "|r")
        else
            soundsBtn.text:SetText(L["setup_enable_sounds"] .. ": |cffff5555" .. L["off"] .. "|r")
        end
    end
    UpdateSoundsBtn()
    soundsBtn:SetScript("OnClick", function()
        wizardState.enableSounds = not wizardState.enableSounds
        UpdateSoundsBtn()
    end)

    local chatFilterBtn = CreateModernButton(content, L["setup_enable_chat_filter"], 320, 36)
    chatFilterBtn:SetPoint("TOPLEFT", 60, -200)
    local function UpdateChatFilterBtn()
        if wizardState.enableChatFilter then
            chatFilterBtn.text:SetText(L["setup_enable_chat_filter"] .. ": |cff44ff44" .. L["on"] .. "|r")
        else
            chatFilterBtn.text:SetText(L["setup_enable_chat_filter"] .. ": |cffff5555" .. L["off"] .. "|r")
        end
    end
    UpdateChatFilterBtn()
    chatFilterBtn:SetScript("OnClick", function()
        wizardState.enableChatFilter = not wizardState.enableChatFilter
        UpdateChatFilterBtn()
    end)
end

local function RenderPage4(content)
    ClearPageContent(content)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -30)
    title:SetText(L["setup_page_4_title"])
    title:SetTextColor(unpack(_tc("textAccent")))

    local body = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 30, -80)
    body:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 60)
    body:SetText(L_("setup_page_4_body", ""))
    body:SetTextColor(unpack(_tc("textPrimary")))
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)

    local hint = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    hint:SetText(L["setup_finish_hint"])
    hint:SetTextColor(unpack(_tc("textDim")))
end

local pageRenderers = {
    [1] = RenderPage1,
    [2] = RenderPage2,
    [3] = RenderPage3,
    [4] = RenderPage4,
}


local function UpdateNavButtons()
    if not wizardFrame then return end
    wizardFrame.backBtn:SetShown(currentPage > 1)
    wizardFrame.nextBtn:SetShown(currentPage < TOTAL_PAGES)
    wizardFrame.finishBtn:SetShown(currentPage == TOTAL_PAGES)
    wizardFrame.pageText:SetText(string.format("%d / %d", currentPage, TOTAL_PAGES))
    if wizardFrame.titleBar then
        wizardFrame.titleBar:SetText("|cff88ccff" .. (L["setup_title"]) .. "|r")
    end
    if wizardFrame.backBtn and wizardFrame.backBtn.text then
        wizardFrame.backBtn.text:SetText(L["setup_back"])
    end
    if wizardFrame.nextBtn and wizardFrame.nextBtn.text then
        wizardFrame.nextBtn.text:SetText(L["setup_next"])
    end
    if wizardFrame.finishBtn and wizardFrame.finishBtn.text then
        wizardFrame.finishBtn.text:SetText(L["setup_finish"])
    end
    if wizardFrame.skipBtn and wizardFrame.skipBtn.text then
        wizardFrame.skipBtn.text:SetText(L["setup_skip"])
    end
end

function ShowPage(pageNum)
    if pageNum < 1 or pageNum > TOTAL_PAGES then return end
    currentPage = pageNum
    if pageRenderers[currentPage] and wizardFrame and wizardFrame.content then
        pageRenderers[currentPage](wizardFrame.content)
    end
    UpdateNavButtons()
end

function Setup.Show()
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

    local titleBar = wizardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleBar:SetPoint("TOP", wizardFrame, "TOP", 0, -18)
    titleBar:SetText("|cff88ccff" .. (L["setup_title"]) .. "|r")
    wizardFrame.titleBar = titleBar

    wizardFrame.pageText = wizardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
        if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
        FrostSeekDB.LFG.disablePopups = not wizardState.enablePopups
        FrostSeekDB.Settings.soundEnabled = wizardState.enableSounds
        FrostSeekDB.LFG.chatFilterEnabled = wizardState.enableChatFilter

        print(L["msg_setup_complete"])
        if ReloadUI then
            ReloadUI()
        elseif C_UI and C_UI.Reload then
            C_UI.Reload()
        end
    end)

    wizardFrame.skipBtn = CreateModernButton(wizardFrame, L["setup_skip"], 110, 26)
    wizardFrame.skipBtn:SetPoint("BOTTOMLEFT", wizardFrame, "BOTTOMLEFT", 150, 15)
    wizardFrame.skipBtn.text:SetTextColor(unpack(_tc("textDim")))
    wizardFrame.skipBtn:SetScript("OnClick", function()
        if not FrostSeekDB then FrostSeekDB = {} end
        if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
        FrostSeekDB.Settings.setupCompleted = true
        wizardFrame:Hide()
        print(L["msg_setup_skipped"])
    end)

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
    if Setup.ShouldShow() then
        C_Timer.After(4, function()
            Setup.Show()
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
