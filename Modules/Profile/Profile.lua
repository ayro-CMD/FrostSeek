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

local Profile = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("profile", Profile)

local Shared = _G.FrostSeekShared
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end
local L = FrostSeek and FrostSeek.L or setmetatable({}, {__index = function(_, k) return k end})

local function EnsureProfileDB()
    if not FrostSeekDB then
        FrostSeekDB = {}
    end
    if not FrostSeekDB.Profile then
        FrostSeekDB.Profile = {
            role = "",
            spec = "",
            discord = false,
            note = "",
            autoFill = true,
            autoIlvl = 0,
            status = "Online",
        }
    end

    local p = FrostSeekDB.Profile
    if p.role == nil or p.role == "" then p.role = "No Role" end
    if p.spec == nil then p.spec = "" end
    if p.discord == nil then p.discord = false end
    if p.note == nil then p.note = "" end
    if p.autoFill == nil then p.autoFill = true end
    if p.autoIlvl == nil then p.autoIlvl = 0 end
    if p.autoGs ~= nil then p.autoGs = nil end
    if p.status == nil or p.status == "" then p.status = "Online" end
    return p
end

local function EnsureProfileFields()
    return EnsureProfileDB()
end

EnsureProfileDB()

function Profile:AutoFill()
    local p = EnsureProfileDB()
    if not p then return 0 end

    local ilvl = 0
    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel and itemLevel > 0 then
                    sum = sum + itemLevel
                    count = count + 1
                end
            end
        end
    end
    ilvl = count > 0 and math.floor((sum / count) + 0.5) or 0

    p.autoIlvl = ilvl

    return ilvl
end

function Profile:GetProfile()
    local p = EnsureProfileDB()
    if p.autoFill then
        self:AutoFill()
    end
    return p
end

function Profile:GetProfileForApp()
    local p = self:GetProfile()
    local Shared = _G.FrostSeekShared
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end

    return {
        name = UnitName("player") or "",
        class = classFile or "",
        classFile = classFile or "",
        level = tostring(UnitLevel("player") or 60),
        role = p.role or "DPS",
        itemLevel = tostring(p.autoIlvl or 0),
        roleType = p.spec or "",
        discord = p.discord and "Yes" or "No",
        status = p.status or "Online",
        note = p.note or "",
        applied = time(),
    }
end

function Profile:Save()
    self:AutoFill()
end

function Profile:Initialize(parentFrame)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    if self.frame then
        self.frame:SetParent(parentFrame)
        self.frame:ClearAllPoints()
        self.frame:SetAllPoints(parentFrame)
        self.frame:Hide()
        return
    end

    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local F = self.frame
    local pad = 18
    local curY = -15

    local title = F:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    title:SetText("|cff88ccff" .. L["profile_your_profile"] .. "|r")
    curY = curY - 30

    local autoInfo = F:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    autoInfo:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    autoInfo:SetWidth(740)
    autoInfo:SetJustifyH("LEFT")
    self.autoInfo = autoInfo
    curY = curY - 50

    local div = F:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    div:SetPoint("TOPRIGHT", F, "TOPRIGHT", -pad, curY)
    div:SetHeight(1)
    div:SetColorTexture(unpack(_tc("line")))
    curY = curY - 15

    local roleLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    roleLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    roleLabel:SetText(_hex("accent") .. L["profile_role"] .. "|r")
    curY = curY - 22

    local roleButtons = {}
    local roles = { "No Role", "Tank", "Healer", "DPS", "Support" }
    local roleColors = { ["No Role"] = "|cff888888", Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555", Support = "|cffb366ff" }

    for i, role in ipairs(roles) do
        local btn = CreateFrame("Button", nil, F)
        btn:SetSize(82, 28)
        btn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + (i - 1) * 86, curY)

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
        btn.accent:SetColorTexture(unpack(_tc("accentBar")))

        btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(roleColors[role] .. role .. "|r")
        btn.text:SetTextColor(unpack(_tc("textPrimary")))

        btn.roleName = role

        btn:SetScript("OnEnter", function(self)
            self.hoverTex:Show()
            self.text:SetTextColor(unpack(_tc("textAccent")))
            self.border:SetColorTexture(unpack(_tc("borderHover")))
        end)

        btn:SetScript("OnLeave", function(self)
            self.hoverTex:Hide()
            local p2 = EnsureProfileDB()
            if self.roleName == p2.role then
                self.text:SetTextColor(unpack(_tc("textPrimary")))
                self.border:SetColorTexture(unpack(_tc("borderFocus")))
            else
                self.text:SetTextColor(unpack(_tc("textMuted")))
                self.border:SetColorTexture(unpack(_tc("border")))
            end
        end)

        btn:SetScript("OnClick", function(self)
            local p = EnsureProfileDB()
            p.role = self.roleName
            if FrostSeekDB and FrostSeekDB.LFG then
                FrostSeekDB.LFG.myRole = self.roleName
            end
            Profile:UpdateRoleButtons()
            Profile:UpdateAutoInfo()
            if FrostSeek and FrostSeek.LFG and FrostSeek.LFG.roleDropdown then
                FrostSeek.LFG.roleDropdown:SetText(self.roleName)
                FrostSeek.LFG.roleDropdown.selectedValue = self.roleName
            end
        end)

        roleButtons[role] = btn
    end
    self.roleButtons = roleButtons
    curY = curY - 40

    local specLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    specLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    specLabel:SetText(_hex("accent") .. L["profile_spec_secondary"] .. "|r")
    curY = curY - 22

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernEditBox then
        self.specEdit = FrostSeek.UI.CreateModernEditBox(F, 300, 24)
    else
        self.specEdit = CreateFrame("EditBox", nil, F)
        self.specEdit:SetAutoFocus(false)
        self.specEdit:SetFontObject("FSKFontNormalSmall")
        self.specEdit:SetWidth(300)
        self.specEdit:SetHeight(24)
    end
    self.specEdit:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    do
        local p = EnsureProfileDB()
        self.specEdit:SetText(p.spec or "")
    end
    self.specEdit:SetScript("OnTextChanged", function(self)
        local p = EnsureProfileDB()
        p.spec = self:GetText() or ""
    end)
    self.specEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 40

    local discLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    discLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    discLabel:SetText(_hex("accent") .. L["profile_discord_ready"] .. "|r")
    curY = curY - 22

    local discToggle = CreateFrame("Button", nil, F)
    discToggle:SetSize(110, 28)
    discToggle:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)

    discToggle.bg = discToggle:CreateTexture(nil, "BACKGROUND")
    discToggle.bg:SetPoint("TOPLEFT", 1, -1)
    discToggle.bg:SetPoint("BOTTOMRIGHT", -1, 1)

    discToggle.border = discToggle:CreateTexture(nil, "BORDER")
    discToggle.border:SetAllPoints()
    discToggle.border:SetColorTexture(unpack(_tc("border")))

    discToggle.hoverTex = discToggle:CreateTexture(nil, "HIGHLIGHT")
    discToggle.hoverTex:SetAllPoints()
    discToggle.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    discToggle.hoverTex:Hide()

    discToggle.accent = discToggle:CreateTexture(nil, "OVERLAY")
    discToggle.accent:SetPoint("BOTTOMLEFT", 2, 0)
    discToggle.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    discToggle.accent:SetHeight(2)

    discToggle.text = discToggle:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    discToggle.text:SetPoint("CENTER")

    discToggle:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        local p2 = EnsureProfileDB()
        local c = _tc("borderHover")
        self.border:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    end)

    discToggle:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        local p2 = EnsureProfileDB()
        if p2.discord then
            self.border:SetColorTexture(0.3, 0.7, 0.4, 0.9)
        else
            self.border:SetColorTexture(unpack(_tc("border")))
        end
    end)

    discToggle:SetScript("OnClick", function(self)
        local p = EnsureProfileDB()
        p.discord = not p.discord
        Profile:UpdateDiscordToggle()
        Profile:UpdateAutoInfo()
        Profile:UpdateRoleButtons()
        print(L["profile_discord_print_prefix"] .. (p.discord and L["profile_discord_ready_status"] or L["profile_discord_not_available_status"]))
    end)
    self.discToggle = discToggle
    curY = curY - 45

    local wispLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    wispLabel:SetPoint("LEFT", discLabel, "RIGHT", 175, 0)
    wispLabel:SetText(_hex("accent") .. L["options_whisper_on_apply"] .. "|r")

    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
    if FrostSeekDB.Settings.applyWhisper == nil then FrostSeekDB.Settings.applyWhisper = false end

    local wispToggle = CreateFrame("Button", nil, F)
    wispToggle:SetSize(160, 28)
    wispToggle:SetPoint("TOPLEFT", wispLabel, "BOTTOMLEFT", 0, -6)

    wispToggle.bg = wispToggle:CreateTexture(nil, "BACKGROUND")
    wispToggle.bg:SetPoint("TOPLEFT", 1, -1)
    wispToggle.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    wispToggle.bg:SetColorTexture(unpack(_tc("bgButton")))

    wispToggle.border = wispToggle:CreateTexture(nil, "BORDER")
    wispToggle.border:SetAllPoints()
    wispToggle.border:SetColorTexture(unpack(_tc("border")))

    wispToggle.hoverTex = wispToggle:CreateTexture(nil, "HIGHLIGHT")
    wispToggle.hoverTex:SetAllPoints()
    wispToggle.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    wispToggle.hoverTex:Hide()

    wispToggle.accent = wispToggle:CreateTexture(nil, "OVERLAY")
    wispToggle.accent:SetPoint("BOTTOMLEFT", 2, 0)
    wispToggle.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    wispToggle.accent:SetHeight(2)
    wispToggle.accent:SetColorTexture(unpack(_tc("accentBar")))

    wispToggle.text = wispToggle:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    wispToggle.text:SetPoint("CENTER")

    local function UpdateWispToggleVisual()
        local on = FrostSeekDB.Settings.applyWhisper == true
        wispToggle.text:SetText(on and L["profile_whisper_on"] or L["profile_whisper_off"])
        if on then
            wispToggle.border:SetColorTexture(0.3, 0.7, 0.4, 0.9)
            wispToggle.bg:SetColorTexture(unpack(_tc("bgTabActive")))
        else
            wispToggle.border:SetColorTexture(unpack(_tc("border")))
            wispToggle.bg:SetColorTexture(unpack(_tc("bgButton")))
        end
    end
    UpdateWispToggleVisual()

    wispToggle:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        self.border:SetColorTexture(unpack(_tc("borderHover")))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["options_whisper_on_apply"], 0.8, 0.9, 1)
        GameTooltip:AddLine(L["tip_apply_whisper_explain"], 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(L["tip_apply_whisper_useful"], 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    wispToggle:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        UpdateWispToggleVisual()
        GameTooltip:Hide()
    end)
    wispToggle:SetScript("OnClick", function(self)
        FrostSeekDB.Settings.applyWhisper = not (FrostSeekDB.Settings.applyWhisper == true)
        UpdateWispToggleVisual()
        print(L["msg_apply_whisper_prefix"] .. (FrostSeekDB.Settings.applyWhisper and L["profile_enabled"] or L["profile_disabled"]))
    end)
    self.wispToggle = wispToggle
    self.UpdateWispToggleVisual = UpdateWispToggleVisual

    local noteLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    noteLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    noteLabel:SetText(_hex("accent") .. L["profile_application_notes"] .. "|r")
    curY = curY - 22

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernEditBox then
        self.noteEdit = FrostSeek.UI.CreateModernEditBox(F, 500, 50)
    else
        self.noteEdit = CreateFrame("EditBox", nil, F)
        self.noteEdit:SetAutoFocus(false)
        self.noteEdit:SetFontObject("FSKFontNormalSmall")
        self.noteEdit:SetWidth(500)
        self.noteEdit:SetHeight(50)
        self.noteEdit:SetMultiLine(true)
    end
    self.noteEdit:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    do
        local p = EnsureProfileDB()
        self.noteEdit:SetText(p.note or "")
    end
    self.noteEdit:SetScript("OnTextChanged", function(self)
        local p = EnsureProfileDB()
        p.note = self:GetText() or ""
    end)
    self.noteEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 55

    local VB = FrostSeek and FrostSeek.VoiceBridge

    local voiceUrlLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    voiceUrlLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    voiceUrlLabel:SetText(_hex("accent") .. L["profile_voice_url_inline"] .. "|r")
    self.voiceUrlLabel = voiceUrlLabel
    curY = curY - 18

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernEditBox then
        self.voiceUrlEdit = FrostSeek.UI.CreateModernEditBox(F, 360, 24)
    else
        self.voiceUrlEdit = CreateFrame("EditBox", nil, F)
        self.voiceUrlEdit:SetAutoFocus(false)
        self.voiceUrlEdit:SetFontObject("FSKFontNormalSmall")
        self.voiceUrlEdit:SetWidth(360)
        self.voiceUrlEdit:SetHeight(24)
    end
    self.voiceUrlEdit:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    if VB then
        local pn = UnitName("player") or ""
        local existing = VB:Get(pn)
        if existing then self.voiceUrlEdit:SetText(existing) end
    end
    self.voiceUrlEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernButton then
        self.voiceSaveBtn = FrostSeek.UI.CreateModernButton(F, 110, 24, L["save"], _tc("accent"))
    else
        self.voiceSaveBtn = CreateFrame("Button", nil, F, "UIPanelButtonTemplate")
        self.voiceSaveBtn:SetSize(110, 24)
        self.voiceSaveBtn:SetText("|cff44ff44" .. L["save"] .. "|r")
    end
    self.voiceSaveBtn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + 370, curY)
    self.voiceSaveBtn:SetScript("OnClick", function()
        if not VB then
            print(L["msg_voicebridge_not_loaded"])
            return
        end
        local url = Profile.voiceUrlEdit and Profile.voiceUrlEdit.GetText and Profile.voiceUrlEdit:GetText() or ""
        local pn = UnitName("player") or ""
        if url and url ~= "" then
            local ok = VB:Set(pn, url)
            if not ok then return end
        else
            VB:Remove(pn)
            print(L["msg_voice_link_removed_for"] .. tostring(pn))
        end
    end)

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernButton then
        self.voiceTestBtn = FrostSeek.UI.CreateModernButton(F, 90, 24, L["profile_test_btn"], _tc("accent"))
    else
        self.voiceTestBtn = CreateFrame("Button", nil, F, "UIPanelButtonTemplate")
        self.voiceTestBtn:SetSize(90, 24)
        self.voiceTestBtn:SetText("|cff88ccff" .. L["voice_test"] .. "|r")
    end
    self.voiceTestBtn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + 490, curY)
    self.voiceTestBtn:SetScript("OnClick", function()
        if not VB then return end
        local pn = UnitName("player") or ""
        local url = Profile.voiceUrlEdit and Profile.voiceUrlEdit.GetText and Profile.voiceUrlEdit:GetText() or ""
        if url and url ~= "" then
            VB:Set(pn, url)
        end
        VB:JoinVoice(pn)
    end)

    curY = curY - 28

    local previewLabel = F:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    previewLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    previewLabel:SetText(_hex("accent") .. L["profile_preview"] .. "|r")
    curY = curY - 20

    self.preview = F:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.preview:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    self.preview:SetWidth(740)
    self.preview:SetHeight(45)
    self.preview:SetJustifyH("LEFT")
    self.preview:SetJustifyV("TOP")

    self:UpdateDiscordToggle()
    self:UpdateAutoInfo()

    self.frame:Hide()
end

function Profile:UpdateRoleButtons()
    if not self.roleButtons then return end
    local p = EnsureProfileDB()
    local currentRole = p.role or ""
    for role, btn in pairs(self.roleButtons) do
        if role == currentRole then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.border:SetColorTexture(unpack(_tc("borderFocus")))
            btn.accent:SetColorTexture(unpack(_tc("accentFocus")))
            if btn.text then btn.text:SetTextColor(unpack(_tc("textPrimary"))) end
        else
            btn.bg:SetPoint("TOPLEFT", 1, -1)
            btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
            btn.border:SetColorTexture(unpack(_tc("border")))
            btn.accent:SetColorTexture(unpack(_tc("accentBar")))
            if btn.text then btn.text:SetTextColor(unpack(_tc("textMuted"))) end
        end
    end
end

function Profile:UpdateDiscordToggle()
    if not self.discToggle then return end
    local p = EnsureProfileDB()
    local dt = self.discToggle
    if p.discord then
        if dt.bg then dt.bg:SetColorTexture(0.12, 0.28, 0.15, 0.85) end
        if dt.border then dt.border:SetColorTexture(0.3, 0.7, 0.4, 0.9) end
        if dt.accent then dt.accent:SetColorTexture(0.3, 0.7, 0.4, 0.9) end
        if dt.text then
            dt.text:SetText("|cff44ff44" .. L["profile_discord_ready_yes"] .. "|r")
            dt.text:SetTextColor(unpack(_tc("textPrimary")))
        end
    else
        if dt.bg then dt.bg:SetColorTexture(0.2, 0.1, 0.1, 0.85) end
        if dt.border then dt.border:SetColorTexture(unpack(_tc("border"))) end
        if dt.accent then dt.accent:SetColorTexture(unpack(_tc("accentBar"))) end
        if dt.text then
            dt.text:SetText("|cffff5555" .. L["profile_discord_ready_no"] .. "|r")
            dt.text:SetTextColor(unpack(_tc("textMuted")))
        end
    end
end

function Profile:UpdateAutoInfo()
    if not self.autoInfo then return end
    local ilvl = self:AutoFill()
    local Shared = _G.FrostSeekShared
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end
    local p = EnsureProfileDB()
    local roleName = p.role or "No Role"
    local roleColors = { ["No Role"] = "|cff888888", Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555" }

    local lines = {}
    table.insert(lines, "|cffffffff" .. tostring(UnitName("player") or "?") .. "|r  " ..
        _hex("textDim") .. L["profile_lv_label"] .. tostring(UnitLevel("player") or 60) .. " " ..
        tostring(classFile or "") .. "|r")
    table.insert(lines, L["profile_ilvl_label"] .. tostring(ilvl or 0) .. "|r   " ..
        L["profile_role_label"] .. (roleColors[p.role] or "|cffffffff") .. roleName .. "|r   " ..
        L["profile_discord_label"] .. (p.discord and L["profile_yes_label"] or L["profile_no_label"]))

    self.autoInfo:SetText(table.concat(lines, "\n"))

    if self.preview then
        local app = self:GetProfileForApp()
        local previewLines = {}
        table.insert(previewLines, _hex("textDim") .. L["profile_application_profile_header"])
        table.insert(previewLines, L["profile_name_label"] .. app.name .. L["profile_class_label"] .. app.classFile)
        table.insert(previewLines, L["profile_ilvl_colon_label"] .. app.itemLevel .. L["profile_role_inline_label"] .. app.role)
        if app.roleType and app.roleType ~= "" then
            table.insert(previewLines, L["profile_spec_label"] .. app.roleType)
        end
        if app.discord == "Yes" then
            table.insert(previewLines, L["profile_discord_available"])
        end
        if app.note and app.note ~= "" then
            table.insert(previewLines, L["profile_notes_label"] .. app.note)
        end
        self.preview:SetText(table.concat(previewLines, "\n"))
    end
end

function Profile:Show()
    self:UpdateAutoInfo()
    self:UpdateRoleButtons()
    self:UpdateDiscordToggle()
    if self.frame then self.frame:Show() end
end

function Profile:Hide()
    if self.frame then self.frame:Hide() end
end

FrostSeek.Profile = Profile

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("profile", Profile)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("profile")
end