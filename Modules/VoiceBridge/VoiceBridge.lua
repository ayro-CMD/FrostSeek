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

local VoiceBridge = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("voicebridge", VoiceBridge)

local L = FrostSeek and FrostSeek.L or function(k) return k end
local Lf = FrostSeek and FrostSeek.Lf or function(k, ...) return string.format(k, ...) end

local ALLOWED_PREFIXES = {
    "https://discord.gg/",
    "https://discord.com/invite/",
    "https://www.discord.gg/",
    "https://www.discord.com/invite/",
    "https://t.gg/", 
    "https://teamspeak.com/invite/",
    "ts3server://", 
}

local function isValidVoiceURL(url)
    if not url or type(url) ~= "string" then return false end
    if #url > 200 then return false end
    for _, prefix in ipairs(ALLOWED_PREFIXES) do
        if string.sub(url, 1, #prefix) == prefix then
            return true
        end
    end
    return false
end

VoiceBridge.IsValidURL = isValidVoiceURL
-- Ayro

local VOICELINKS_MAX = 100

local function trimVoiceLinks()
    local VL = FrostSeekDB and FrostSeekDB.VoiceLinks
    if not VL then return end
    local n = 0
    for _ in pairs(VL) do n = n + 1 end
    if n <= VOICELINKS_MAX then return end
    local sorted = {}
    for name, entry in pairs(VL) do
        sorted[#sorted + 1] = { name = name, ts = entry and entry.ts or 0 }
    end
    table.sort(sorted, function(a, b) return a.ts < b.ts end)
    local toRemove = n - VOICELINKS_MAX
    for i = 1, toRemove do
        if sorted[i] then VL[sorted[i].name] = nil end
    end
end

function VoiceBridge:Set(leaderName, url, silent)
    if not leaderName or leaderName == "" then
        return false, "no_leader"
    end
    if not isValidVoiceURL(url) then
        if not silent then
            print("|cffff5555FrostSeek:|r " .. L["voice_link_invalid"])
        end
        return false, "invalid_url"
    end
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.VoiceLinks then FrostSeekDB.VoiceLinks = {} end
    FrostSeekDB.VoiceLinks[leaderName] = {
        url = url,
        ts = time(),
    }
    trimVoiceLinks()
    if not silent then
        print("|cff88ccffFrostSeek:|r " .. Lf("voice_link_set", leaderName))
    end
    return true
end

function VoiceBridge:Get(leaderName)
    if not leaderName then return nil end
    if not FrostSeekDB or not FrostSeekDB.VoiceLinks then return nil end
    local entry = FrostSeekDB.VoiceLinks[leaderName]
    if not entry then return nil end
    return entry.url, entry.ts
end

function VoiceBridge:Remove(leaderName)
    if not leaderName or not FrostSeekDB or not FrostSeekDB.VoiceLinks then return false end
    if not FrostSeekDB.VoiceLinks[leaderName] then return false end
    FrostSeekDB.VoiceLinks[leaderName] = nil
    print("|cff88ccffFrostSeek:|r " .. Lf("voice_link_cleared", leaderName))
    return true
end

function VoiceBridge:List()
    if not FrostSeekDB or not FrostSeekDB.VoiceLinks then
        print(L["msg_no_voice_links"])
        return
    end
    local any = false
    for leader, entry in pairs(FrostSeekDB.VoiceLinks) do
        any = true
        print(string.format("  |cff88ccff%s|r -> %s",
            leader, entry.url))
    end
    if not any then
        print(L["voice_no_links_stored"])
    end
end

function VoiceBridge.EncodeVoiceField(channelName, leaderName)
    channelName = channelName or "None"
    if channelName == "None" then return "None" end
    local url = VoiceBridge:Get(leaderName)
    if url and #url > 0 then
        return channelName .. "|" .. url
    end
    return channelName
end

function VoiceBridge.DecodeVoiceField(voiceField)
    if not voiceField or voiceField == "" then
        return { channel = "None", url = nil }
    end
    local sep = string.find(voiceField, "|", 1, true)
    if not sep then
        return { channel = voiceField, url = nil }
    end
    local channel = string.sub(voiceField, 1, sep - 1)
    local url = string.sub(voiceField, sep + 1)
    return { channel = channel, url = url }
end

function VoiceBridge:JoinVoice(leaderName)
    local url = VoiceBridge:Get(leaderName)
    if not url then
        print("|cffff5555FrostSeek:|r " .. L["voice_no_link"])
        return false
    end

    print("|cff88ccffFrostSeek VoiceBridge:|r |cffe6e6e6" .. tostring(leaderName) .. "|r -> |cff4aff7a" .. url .. "|r")
    VoiceBridge._ShowVoicePopup(url, leaderName)
    return true
end

local voicePopup = nil

function VoiceBridge._ShowVoicePopup(url, leaderName)
    if voicePopup then
        voicePopup.urlEdit:SetText(url or "")
        if voicePopup.urlLabel then
            voicePopup.urlLabel:SetText("|cff88ccff" .. L["voice_join"] .. "|r  |cff888888— " .. tostring(leaderName or "") .. "|r")
        end
        voicePopup:Show()
        return
    end

    local f = CreateFrame("Frame", "FrostSeekVoicePopup", UIParent)
    f:SetSize(520, 160)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.08, 0.10, 0.14, 0.96)
    f:SetBackdropBorderColor(0.3, 0.5, 0.8, 1.0)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.urlLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    f.urlLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
    f.urlLabel:SetText("|cff88ccff" .. L["voice_join"] .. "|r  |cff888888— " .. tostring(leaderName or "") .. "|r")
    f.hint = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    f.hint:SetPoint("TOPLEFT", f.urlLabel, "BOTTOMLEFT", 0, -4)
    f.hint:SetText("|cff888888" .. L["voice_popup_hint1"] .. "|r")
    f.hint2 = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    f.hint2:SetPoint("TOPLEFT", f.hint, "BOTTOMLEFT", 0, -2)
    f.hint2:SetText("|cff888888" .. L["voice_popup_hint2"] .. "|r")
    local eb = CreateFrame("EditBox", nil, f)
    eb:SetSize(488, 24)
    eb:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -76)
    eb:SetAutoFocus(false)
    eb:SetFontObject("FSKFontNormal")
    eb:SetText(url or "")
    eb:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    eb:SetBackdropColor(0.05, 0.06, 0.08, 0.9)
    eb:SetBackdropBorderColor(0.3, 0.4, 0.5, 1.0)
    eb:SetTextInsets(6, 6, 2, 2)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self)
        self:HighlightText(0, -1)
    end)
    f.urlEdit = eb

    local copyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    copyBtn:SetSize(120, 26)
    copyBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 12)
    copyBtn:SetText("|cff44ff44" .. L["voice_copy"] .. "|r")
    copyBtn:SetScript("OnClick", function()
        local text = f.urlEdit:GetText() or ""
        local ok = false
        if CopyToClipboard then
            ok = pcall(CopyToClipboard, text)
        end
        if ok then
            print("|cff44ff44FrostSeek:|r " .. L["voice_copy_ok"])
        else
            f.urlEdit:SetFocus()
            f.urlEdit:HighlightText(0, -1)
            print("|cffffcc00FrostSeek:|r " .. L["voice_select_hint"])
        end
    end)
    f.copyBtn = copyBtn

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 26)
    closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 12)
    closeBtn:SetText("|cffff5555" .. L["close"] .. "|r")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)
    f.closeBtn = closeBtn

    f:Hide()
    voicePopup = f
    f:Show()
end

SLASH_FSVOICE1 = "/fsvoice"
SlashCmdList["FSVOICE"] = function(msg)
    msg = msg or ""
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
    end
    local cmd = (args[1] or "list"):lower()
    if cmd == "set" then
        if #args < 3 then
            print(L["msg_usage_set"])
            return
        end
        local leader = args[2]
        local url = args[3]
        VoiceBridge:Set(leader, url)
    elseif cmd == "get" then
        if not args[2] then
            print(L["msg_usage_get"])
            return
        end
        local url = VoiceBridge:Get(args[2])
        if url then
            print(string.format("|cff88ccff%s|r -> %s", args[2], url))
        else
            print(L["msg_no_voice_link_for"] .. tostring(args[2]) .. "|r")
        end
    elseif cmd == "remove" then
        if not args[2] then
            print(L["msg_usage_remove"])
            return
        end
        VoiceBridge:Remove(args[2])
    else
        VoiceBridge:List()
    end
end

FrostSeek.VoiceBridge = VoiceBridge
return VoiceBridge
