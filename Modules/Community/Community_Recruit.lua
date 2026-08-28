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
local L = FrostSeek and FrostSeek.L or {}

local Community = _G.FrostSeek and _G.FrostSeek.Community
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("community_recruit", Community)

local _tc = Shared and Shared._tc or function(t) return {0.5, 0.5, 0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end



function Community:BuildRecruitmentFrame()
    if not self.frame then return end
    local F = self.frame
    local pad = 10
    local curY = self.contentY

    local rf = CreateFrame("Frame", nil, F)
    rf:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    rf:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad, pad)
    self.recruitmentFrame = rf

    local header = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    header:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, 0)
    header:SetText(_hex("textDim") .. L["community_recruitment_create"] .. "|r")
    curY = -22

    local gNameLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    gNameLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    gNameLabel:SetText(_hex("textDim") .. L["community_guild_name_label"])
    curY = curY - 16

    if UI and UI.CreateModernEditBox then
        self.recGuildName = UI.CreateModernEditBox(rf, 300, 22)
    else
        self.recGuildName = CreateFrame("EditBox", nil, rf)
        self.recGuildName:SetAutoFocus(false)
        self.recGuildName:SetFontObject("FSKFontNormalSmall")
        self.recGuildName:SetSize(300, 22)
    end
    self.recGuildName:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recGuildName:SetText("")
    self.recGuildName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local myGuild = GetGuildInfo and GetGuildInfo("player") or ""
    if myGuild and myGuild ~= "" then
        self.recGuildName:SetText(myGuild)
    end
    curY = curY - 26

    local discLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    discLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    discLabel:SetText(_hex("textDim") .. L["community_discord_label"])
    curY = curY - 18

    if UI and UI.CreateModernEditBox then
        self.recDiscord = UI.CreateModernEditBox(rf, 300, 22)
    else
        self.recDiscord = CreateFrame("EditBox", nil, rf)
        self.recDiscord:SetAutoFocus(false)
        self.recDiscord:SetFontObject("FSKFontNormalSmall")
        self.recDiscord:SetSize(300, 22)
    end
    self.recDiscord:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recDiscord:SetText("")
    self.recDiscord:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 26

    local focusLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    focusLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    focusLabel:SetText(_hex("textDim") .. L["community_focus_label"])
    curY = curY - 18

    self.recFocusToggles = {}
    local focusOptions = {"PvE", "PvP", "Raid", "Mythic+", "Dungeon", "Arena", "Ascended", "World Boss", "Social", "Leveling", "Twink", "Boost"}
    local colW = 90
    local perRow = 6
    for i, opt in ipairs(focusOptions) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local toggle
        if UI and UI.CreateSmallToggle then
            toggle = UI.CreateSmallToggle(rf, opt, col * colW, row * 22, 80, 20, function() end)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", col * colW, curY - row * 22)
        else
            toggle = CreateFrame("CheckButton", nil, rf, "UICheckButtonTemplate")
            toggle:SetSize(18, 18)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", col * colW, curY - row * 22)
            local text = _G[toggle:GetName() .. "Text"]
            if text then
                text:SetText(opt)
                text:SetFontObject("FSKFontNormalSmall")
            end
        end
        toggle.optName = opt
        self.recFocusToggles[opt] = toggle
    end
    curY = curY - 22 * 2 - 10

    local rolesLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    rolesLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    rolesLabel:SetText(_hex("textDim") .. L["community_roles_needed_label"])
    curY = curY - 18

    self.recRoleToggles = {}
    local roleOptions = {"Tank", "Healer", "DPS", "Support"}
    for i, opt in ipairs(roleOptions) do
        local toggle
        if UI and UI.CreateSmallToggle then
            toggle = UI.CreateSmallToggle(rf, opt, (i - 1) * 90, 0, 80, 20, function() end)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", (i - 1) * 90, curY)
        else
            toggle = CreateFrame("CheckButton", nil, rf, "UICheckButtonTemplate")
            toggle:SetSize(18, 18)
            toggle:SetPoint("TOPLEFT", rf, "TOPLEFT", (i - 1) * 90, curY)
            local text = _G[toggle:GetName() .. "Text"]
            if text then
                text:SetText(opt)
                text:SetFontObject("FSKFontNormalSmall")
            end
        end
        toggle.optName = opt
        self.recRoleToggles[opt] = toggle
    end
    curY = curY - 26

    local noteLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    noteLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    noteLabel:SetText(_hex("textDim") .. L["community_note_label"])
    curY = curY - 18

    if UI and UI.CreateModernEditBox then
        self.recNote = UI.CreateModernEditBox(rf, 500, 40)
    else
        self.recNote = CreateFrame("EditBox", nil, rf)
        self.recNote:SetAutoFocus(false)
        self.recNote:SetFontObject("FSKFontNormalSmall")
        self.recNote:SetSize(500, 40)
        self.recNote:SetMultiLine(true)
    end
    self.recNote:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recNote:SetText("")
    self.recNote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 48

    if Community.HookRefreshOnEdit then
        Community.HookRefreshOnEdit(self.recGuildName)
        Community.HookRefreshOnEdit(self.recDiscord)
        Community.HookRefreshOnEdit(self.recNote)
    end

    local prevLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    prevLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    prevLabel:SetText(_hex("textDim") .. L["community_preview_label"])
    curY = curY - 16

    self.recPreview = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.recPreview:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recPreview:SetWidth(740)
    self.recPreview:SetHeight(30)
    self.recPreview:SetJustifyH("LEFT")
    self.recPreview:SetJustifyV("TOP")
    self.recPreview:SetText("")
    curY = curY - 36

    local chanLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    chanLabel:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    chanLabel:SetText(_hex("textDim") .. L["community_channel_label"])
    curY = curY - 16

    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
    if not FrostSeekDB.Settings.recruitSpamChannel then
        FrostSeekDB.Settings.recruitSpamChannel = "GUILD"
    end
    if not FrostSeekDB.Settings.recruitSpamInterval then
        FrostSeekDB.Settings.recruitSpamInterval = 600
    end

    self.recSpamChannelBtn = CreateFrame("Button", nil, rf)
    self.recSpamChannelBtn:SetSize(120, 22)
    self.recSpamChannelBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, curY)
    self.recSpamChannelBtn.bg = self.recSpamChannelBtn:CreateTexture(nil, "BACKGROUND")
    self.recSpamChannelBtn.bg:SetPoint("TOPLEFT", 1, -1)
    self.recSpamChannelBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    self.recSpamChannelBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    self.recSpamChannelBtn.border = self.recSpamChannelBtn:CreateTexture(nil, "BORDER")
    self.recSpamChannelBtn.border:SetAllPoints()
    self.recSpamChannelBtn.border:SetColorTexture(unpack(_tc("border")))
    self.recSpamChannelBtn.hoverTex = self.recSpamChannelBtn:CreateTexture(nil, "HIGHLIGHT")
    self.recSpamChannelBtn.hoverTex:SetAllPoints()
    self.recSpamChannelBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamChannelBtn.hoverTex:Hide()
    self.recSpamChannelBtn.accent = self.recSpamChannelBtn:CreateTexture(nil, "OVERLAY")
    self.recSpamChannelBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    self.recSpamChannelBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    self.recSpamChannelBtn.accent:SetHeight(2)
    self.recSpamChannelBtn.accent:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamChannelBtn.text = self.recSpamChannelBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.recSpamChannelBtn.text:SetPoint("CENTER")
    local spamChannels = {"GUILD", "CHANNEL1", "CHANNEL2", "CHANNEL3", "SAY", "YELL"}
    local function UpdateChannelLabel()
        self.recSpamChannelBtn.text:SetText(FrostSeekDB.Settings.recruitSpamChannel)
    end
    UpdateChannelLabel()
    self.recSpamChannelBtn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    self.recSpamChannelBtn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    self.recSpamChannelBtn:SetScript("OnClick", function()
        local cur = FrostSeekDB.Settings.recruitSpamChannel
        local idx = 1
        for i, c in ipairs(spamChannels) do
            if c == cur then idx = i break end
        end
        idx = (idx % #spamChannels) + 1
        FrostSeekDB.Settings.recruitSpamChannel = spamChannels[idx]
        UpdateChannelLabel()
    end)

    local intLabel = rf:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    intLabel:SetPoint("LEFT", self.recSpamChannelBtn, "RIGHT", 14, 0)
    intLabel.SetText(intLabel, _hex("textDim") .. L["community_interval_label"])
    intLabel:SetText(_hex("textDim") .. L["community_interval_label"])

    self.recSpamIntervalBtn = CreateFrame("Button", nil, rf)
    self.recSpamIntervalBtn:SetSize(100, 22)
    self.recSpamIntervalBtn:SetPoint("LEFT", intLabel, "RIGHT", 4, 0)
    self.recSpamIntervalBtn.bg = self.recSpamIntervalBtn:CreateTexture(nil, "BACKGROUND")
    self.recSpamIntervalBtn.bg:SetPoint("TOPLEFT", 1, -1)
    self.recSpamIntervalBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    self.recSpamIntervalBtn.bg:SetColorTexture(unpack(_tc("bgButton")))
    self.recSpamIntervalBtn.border = self.recSpamIntervalBtn:CreateTexture(nil, "BORDER")
    self.recSpamIntervalBtn.border:SetAllPoints()
    self.recSpamIntervalBtn.border:SetColorTexture(unpack(_tc("border")))
    self.recSpamIntervalBtn.hoverTex = self.recSpamIntervalBtn:CreateTexture(nil, "HIGHLIGHT")
    self.recSpamIntervalBtn.hoverTex:SetAllPoints()
    self.recSpamIntervalBtn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamIntervalBtn.hoverTex:Hide()
    self.recSpamIntervalBtn.accent = self.recSpamIntervalBtn:CreateTexture(nil, "OVERLAY")
    self.recSpamIntervalBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    self.recSpamIntervalBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    self.recSpamIntervalBtn.accent:SetHeight(2)
    self.recSpamIntervalBtn.accent:SetColorTexture(unpack(_tc("accentBar")))
    self.recSpamIntervalBtn.text = self.recSpamIntervalBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.recSpamIntervalBtn.text:SetPoint("CENTER")
    local intervals = {600, 900, 1800, 2700, 3600} 
    local function FormatInterval(sec)
        local m = math.floor(sec / 60)
        if m < 60 then return m .. " min" end
        local h = math.floor(m / 60)
        local rem = m % 60
        if rem == 0 then return h .. "h" end
        return h .. "h " .. rem .. "m"
    end
    local function UpdateIntervalLabel()
        self.recSpamIntervalBtn.text:SetText(FormatInterval(FrostSeekDB.Settings.recruitSpamInterval))
    end
    UpdateIntervalLabel()
    self.recSpamIntervalBtn:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.border:SetColorTexture(unpack(_tc("borderHover")))
    end)
    self.recSpamIntervalBtn:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        self.border:SetColorTexture(unpack(_tc("border")))
    end)
    self.recSpamIntervalBtn:SetScript("OnClick", function()
        local cur = FrostSeekDB.Settings.recruitSpamInterval
        local idx = 1
        for i, v in ipairs(intervals) do
            if v == cur then idx = i break end
        end
        idx = (idx % #intervals) + 1
        FrostSeekDB.Settings.recruitSpamInterval = intervals[idx]
        UpdateIntervalLabel()
        if Community.spamTicker then
            Community:StopSpam()
            Community:StartSpam()
        end
    end)

    curY = curY - 26

    local function MakeModernButton(parent, label, w, h, accentToken, hoverColor)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(w, h)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetPoint("TOPLEFT", 1, -1)
        btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))
        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))
        btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hoverTex:SetAllPoints()
        btn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
        btn.hoverTex:Hide()
        btn.accent = btn:CreateTexture(nil, "OVERLAY")
        btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
        btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
        btn.accent:SetHeight(2)
        btn.accent.SetColorTexture(btn.accent, unpack(_tc(accentToken)))
        btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(label)
        btn:SetScript("OnEnter", function(self)
            self.hoverTex:Show()
            self.border:SetColorTexture(unpack(_tc("borderHover")))
            if hoverColor then self.text:SetTextColor(unpack(hoverColor)) end
        end)
        btn:SetScript("OnLeave", function(self)
            self.hoverTex:Hide()
            self.border:SetColorTexture(unpack(_tc("border")))
            self.text:SetTextColor(unpack(_tc("textMuted")))
        end)
        return btn
    end

    local btnY1 = curY
    local saveBtn = MakeModernButton(rf, L["community_save_template"], 100, 22, "accentBar", _tc("textPrimary"))
    saveBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, btnY1)
    saveBtn:SetScript("OnClick", function() Community:SaveTemplateDialog() end)

    local loadBtn = MakeModernButton(rf, L["community_load_template"], 100, 22, "accentBar", _tc("textPrimary"))
    loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    loadBtn:SetScript("OnClick", function() Community:LoadTemplateDialog() end)

    local delBtn = MakeModernButton(rf, L["community_delete_template"], 100, 22, "danger", {1, 0.5, 0.3})
    delBtn:SetPoint("LEFT", loadBtn, "RIGHT", 6, 0)
    delBtn.text:SetText("|cffff7755" .. L["community_delete_template"] .. "|r")
    delBtn:SetScript("OnClick", function() Community:DeleteTemplateDialog() end)

    curY = curY - 24
    local btnY2 = curY
    local sendBtn = MakeModernButton(rf, L["community_send_once"], 100, 22, "success", {0.4, 1, 0.4})
    sendBtn.text:SetText("|cff44ff66" .. L["community_send_once"] .. "|r")
    sendBtn:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, btnY2)
    sendBtn:SetScript("OnClick", function() Community:SendRecruitmentToChat() end)

    local startSpamBtn = MakeModernButton(rf, L["community_start_spam"], 100, 22, "accentBar", {0.4, 1, 0.4})
    startSpamBtn.text:SetText("|cff44ff44" .. L["community_start_spam"] .. "|r")
    startSpamBtn:SetPoint("LEFT", sendBtn, "RIGHT", 6, 0)
    startSpamBtn:SetScript("OnClick", function() Community:StartSpam() end)

    local stopSpamBtn = MakeModernButton(rf, L["community_stop_spam"], 100, 22, "danger", {1, 0.4, 0.4})
    stopSpamBtn.text:SetText("|cffff5555" .. L["community_stop_spam"] .. "|r")
    stopSpamBtn:SetPoint("LEFT", startSpamBtn, "RIGHT", 6, 0)
    stopSpamBtn:SetScript("OnClick", function() Community:StopSpam() end)

    self.recStartSpamBtn = startSpamBtn
    self.recStopSpamBtn = stopSpamBtn
end


function Community:StartSpam()
    if self.spamTicker then
        self.spamTicker:Cancel()
        self.spamTicker = nil
    end
    local interval = FrostSeekDB.Settings.recruitSpamInterval or 600
    self:SendRecruitmentToChat()
    print(L["msg_recruit_spam_started"] .. self:FormatIntervalLabel(interval) .. ")")
    self.spamTicker = C_Timer.NewTicker(interval, function()
        Community:SendRecruitmentToChat()
    end)
end

function Community:StopSpam()
    if self.spamTicker then
        self.spamTicker:Cancel()
        self.spamTicker = nil
        print(L["msg_recruit_spam_stopped"])
    end
end

function Community:FormatIntervalLabel(sec)
    local m = math.floor(sec / 60)
    if m < 60 then return m .. " min" end
    local h = math.floor(m / 60)
    local rem = m % 60
    if rem == 0 then return h .. "h" end
    return h .. "h " .. rem .. "m"
end

function Community:RefreshRecruitmentPreview()
    if not self.recPreview then return end
    local msg = self:BuildRecruitmentMessage()
    self.recPreview:SetText(msg)
end

function Community:BuildRecruitmentMessage()
    local guild = self.recGuildName and self.recGuildName:GetText() or ""
    local discord = self.recDiscord and self.recDiscord:GetText() or ""

    local focusParts = {}
    if self.recFocusToggles then
        for opt, toggle in pairs(self.recFocusToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then
                table.insert(focusParts, opt)
            end
        end
    end

    local roleParts = {}
    if self.recRoleToggles then
        for opt, toggle in pairs(self.recRoleToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then
                table.insert(roleParts, opt)
            end
        end
    end

    local note = self.recNote and self.recNote:GetText() or ""

    local parts = {}
    table.insert(parts, "[" .. guild .. "]")
    if #focusParts > 0 then
        table.insert(parts, L["community_looking_for_prefix"] .. table.concat(focusParts, "/") .. L["community_players_suffix"])
    else
        table.insert(parts, L["community_looking_for_members"])
    end
    if #roleParts > 0 then
        table.insert(parts, L["community_need_prefix"] .. table.concat(roleParts, "/"))
    end
    if discord and discord ~= "" then
        table.insert(parts, L["community_discord_prefix"] .. discord)
    end
    if note and note ~= "" then
        table.insert(parts, note)
    end
    table.insert(parts, "- FrostSeek")

    return table.concat(parts, " - ")
end

function Community:GetCurrentRecruitmentConfig()
    local config = {
        guild = self.recGuildName and self.recGuildName:GetText() or "",
        discord = self.recDiscord and self.recDiscord:GetText() or "",
        focus = {},
        roles = {},
        note = self.recNote and self.recNote:GetText() or "",
    }
    if self.recFocusToggles then
        for opt, toggle in pairs(self.recFocusToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then table.insert(config.focus, opt) end
        end
    end
    if self.recRoleToggles then
        for opt, toggle in pairs(self.recRoleToggles) do
            local checked = toggle.active or (toggle.GetChecked and toggle:GetChecked())
            if checked then table.insert(config.roles, opt) end
        end
    end
    return config
end

function Community:ApplyRecruitmentConfig(config)
    if not config then return end
    if self.recGuildName then self.recGuildName:SetText(config.guild or "") end
    if self.recDiscord then self.recDiscord:SetText(config.discord or "") end
    if self.recNote then self.recNote:SetText(config.note or "") end
    if self.recFocusToggles and config.focus then
        for opt, toggle in pairs(self.recFocusToggles) do
            local found = false
            for _, f in ipairs(config.focus) do
                if f == opt then found = true break end
            end
            if toggle.SetChecked then toggle:SetChecked(found) end
            if toggle.active ~= nil then toggle.active = found end
        end
    end
    if self.recRoleToggles and config.roles then
        for opt, toggle in pairs(self.recRoleToggles) do
            local found = false
            for _, r in ipairs(config.roles) do
                if r == opt then found = true break end
            end
            if toggle.SetChecked then toggle:SetChecked(found) end
            if toggle.active ~= nil then toggle.active = found end
        end
    end
    self:RefreshRecruitmentPreview()
end

function Community:SaveTemplateDialog()
    local config = self:GetCurrentRecruitmentConfig()
    if config.guild == "" then
        print(L["msg_cannot_save_no_guild"])
        return
    end
    local name = config.guild
    local baseName = name
    local suffix = 1
    while FrostSeekDB.GuildTemplates and FrostSeekDB.GuildTemplates[name] do
        name = baseName .. " (" .. tostring(suffix) .. ")"
        suffix = suffix + 1
    end
    if not FrostSeekDB.GuildTemplates then FrostSeekDB.GuildTemplates = {} end
    FrostSeekDB.GuildTemplates[name] = config
    print(L["msg_template_saved_as"] .. " '" .. name .. "'")
end

function Community:LoadTemplateDialog()
    if not FrostSeekDB.GuildTemplates then return end
    local count = 0
    for _ in pairs(FrostSeekDB.GuildTemplates) do count = count + 1 end
    if count == 0 then
        print(L["msg_no_saved_templates"])
        return
    end
    print(L["msg_templates_header"])
    for name, config in pairs(FrostSeekDB.GuildTemplates) do
        print("  |cff88ccff-|r " .. name .. " |cff888888[" .. (config.guild or "?") .. "]|r")
    end
    print(L["msg_use_fsloadtemplate"])
end

function Community:DeleteTemplateDialog()
    if not FrostSeekDB.GuildTemplates then return end
    local count = 0
    for _ in pairs(FrostSeekDB.GuildTemplates) do count = count + 1 end
    if count == 0 then
        print(L["msg_no_templates_to_delete"])
        return
    end
    print(L["msg_templates_deletable_hdr"])
    for name, _ in pairs(FrostSeekDB.GuildTemplates) do
        print("  |cffff5555-|r " .. name)
    end
end

function Community:LoadTemplateByName(name)
    if not name or not FrostSeekDB.GuildTemplates then return false end
    local config = FrostSeekDB.GuildTemplates[name]
    if not config then return false end
    self:ApplyRecruitmentConfig(config)
    print(L["msg_loaded_template"] .. " '" .. name .. "'")
    return true
end

function Community:DeleteTemplateByName(name)
    if not name or not FrostSeekDB.GuildTemplates then return false end
    if not FrostSeekDB.GuildTemplates[name] then return false end
    FrostSeekDB.GuildTemplates[name] = nil
    print(L["msg_deleted_template"] .. " '" .. name .. "'")
    return true
end

function Community:SendRecruitmentToChat()
    local msg = self:BuildRecruitmentMessage()
    if not msg or msg == "" then
        print(L["msg_empty_recruitment_msg"])
        return
    end
    local channel = (FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.recruitSpamChannel) or "GUILD"
    
    if string.match(channel, "CHANNEL%d+") then
        local channelNum = tonumber(string.match(channel, "CHANNEL(%d+)"))
        if channelNum then
            local realId
            local chName
            pcall(function()
                local id, name = GetChannelName(channelNum)
                if type(id) == "number" and id > 0 then
                    realId = id
                    chName = name
                end
            end)
            if realId then
                pcall(function() SendChatMessage(msg, "CHANNEL", nil, realId) end)
                print(L["msg_recruit_sent_to"] .. tostring(chName) .. L["community_channel_prefix"] .. channelNum .. ")")
                return
            end
            print("|cffff5555FrostSeek:|r " .. (L["community_not_available_suffix"] or "channel ") .. tostring(channel) .. ")")
            return
        end
    end
    local ok = pcall(function() SendChatMessage(msg, channel) end)
    if ok then
        print(L["community_recruit_sent_to_prefix"] .. channel)
    else
        print("|cffff5555FrostSeek:|r " .. (L["msg_recruit_sent_to_say"] or "send failed"))
    end
end

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("community", Community)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("community")
end
