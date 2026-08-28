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
local FrostSeekUIUtils = _G.FrostSeekUIUtils
local Shared = _G.FrostSeekShared

local LFG = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg", LFG)

local L = FrostSeek.L
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end

local searchExpirationTime = 340
local activeSearches = {}
local openFrames = {}
local lastPopupTimes = {}
local mutedPlayers = {}
LFG._S = {
    activeSearches = activeSearches,
    openFrames = openFrames,
    lastPopupTimes = lastPopupTimes,
    mutedPlayers = mutedPlayers,
    searchExpirationTime = searchExpirationTime,
    popupUnlockFrames = {},
}
LFG._activeSearches = activeSearches
local pendingInvites = {}
LFG._pendingInvites = pendingInvites
local PENDING_INVITE_TTL = 600
local inviteTrackerEnabled = true
local function NormalizePlayerName(name)
    if not name or name == "" then return "" end
    name = tostring(name)
    name = string.gsub(name, "%-[^|]+$", "")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    return name
end
LFG.NormalizePlayerName = NormalizePlayerName

local function FindActiveSearchByPlayer(playerName)
    if not playerName or playerName == "" then return nil end
    if not activeSearches then return nil end
    local target = string.lower(NormalizePlayerName(playerName))
    if target == "" then return nil end
    for _, search in ipairs(activeSearches) do
        local candidate = string.lower(NormalizePlayerName(search.player or ""))
        if candidate == target then
            return search
        end
    end
    return nil
end
LFG.FindActiveSearchByPlayer = FindActiveSearchByPlayer

function LFG.RememberWhisperSent(playerName, originalMessage, category, dungeon)
    if not inviteTrackerEnabled then return end
    local key = NormalizePlayerName(playerName)
    if key == "" then return end
    local msg = originalMessage or ""
    msg = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", "")
    msg = string.gsub(msg, "|r", "")
    msg = string.gsub(msg, "|Hitem:.-|h(.-)|h", "%1")
    if msg == "" then return end
    pendingInvites[key] = {
        message   = msg,
        time      = GetTime(),
        category  = category or "MISC",
        dungeon   = dungeon or "",
    }
end

function LFG.CleanupPendingInvites()
    local now = GetTime()
    local purged = 0
    for name, entry in pairs(pendingInvites) do
        if entry and entry.time and (now - entry.time) > PENDING_INVITE_TTL then
            pendingInvites[name] = nil
            purged = purged + 1
        end
    end
    return purged
end

function LFG.GetPendingInvite(playerName)
    if not playerName then return nil end
    local key = NormalizePlayerName(playerName)
    if key == "" then return nil end
    local entry = pendingInvites[key]
    if not entry then return nil end
    if entry.time and (GetTime() - entry.time) > PENDING_INVITE_TTL then
        pendingInvites[key] = nil
        return nil
    end
    return entry
end

function LFG.ClearPendingInvites()
    wipe(pendingInvites)
end

function LFG.SetInviteTrackerEnabled(enabled)
    inviteTrackerEnabled = enabled and true or false
    if not enabled then
        wipe(pendingInvites)
    end
end

function LFG.IsInviteTrackerEnabled()
    return inviteTrackerEnabled
end

local function PrintToChat(msg)
    if not msg or msg == "" then return end
    local frame = DEFAULT_CHAT_FRAME
    if frame and frame.AddMessage then
        frame:AddMessage(msg, 1.0, 0.85, 0.4)
    else
        print(msg)
    end
end
LFG.PrintToChat = PrintToChat

local centerAlertFrame = nil
local centerAlertText  = nil
local centerAlertTicker = nil

local INVITE_ALERT_ACCENT = { 0.70, 0.40, 1.00 }
LFG._S.INVITE_ALERT_ACCENT = INVITE_ALERT_ACCENT

local function CreateCenterAlertFrame()
    if centerAlertFrame then return centerAlertFrame end
    centerAlertFrame = CreateFrame("Frame", "FrostSeekInviteAlert", UIParent)
    centerAlertFrame:SetSize(560, 90)
    centerAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    centerAlertFrame:SetFrameStrata("DIALOG")
    centerAlertFrame:SetFrameLevel(50)
    centerAlertFrame:SetClampedToScreen(true)
    local bg = centerAlertFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.02, 0.10, 0.78)
    bg:SetVertexColor(0.10, 0.06, 0.18, 0.85)
    centerAlertFrame.bg = bg
    local accent = centerAlertFrame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", centerAlertFrame, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", centerAlertFrame, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(4)
    accent:SetColorTexture(INVITE_ALERT_ACCENT[1], INVITE_ALERT_ACCENT[2], INVITE_ALERT_ACCENT[3], 1.0)
    centerAlertFrame.accent = accent
    local topAccent = centerAlertFrame:CreateTexture(nil, "ARTWORK")
    topAccent:SetPoint("TOPLEFT", 1, 0)
    topAccent:SetPoint("TOPRIGHT", -1, 0)
    topAccent:SetHeight(2)
    topAccent:SetColorTexture(INVITE_ALERT_ACCENT[1], INVITE_ALERT_ACCENT[2], INVITE_ALERT_ACCENT[3], 0.9)
    centerAlertFrame.topAccent = topAccent
    centerAlertText = centerAlertFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalHuge")
    centerAlertText:SetPoint("TOPLEFT", centerAlertFrame, "TOPLEFT", 14, -8)
    centerAlertText:SetPoint("BOTTOMRIGHT", centerAlertFrame, "BOTTOMRIGHT", -14, 8)
    centerAlertText:SetJustifyH("LEFT")
    centerAlertText:SetJustifyV("MIDDLE")
    centerAlertText:SetWordWrap(true)
    centerAlertText:SetTextColor(1, 0.92, 0.55, 1)
    centerAlertFrame:SetMovable(true)
    centerAlertFrame:RegisterForDrag("LeftButton")
    centerAlertFrame:SetScript("OnDragStart", function(self)
        if LFG.IsPopupUnlockMode() then
            self:StartMoving()
            self._dragging = true
        end
    end)
    centerAlertFrame:SetScript("OnDragStop", function(self)
        if self._dragging then
            self:StopMovingOrSizing()
            self._dragging = false
            LFG.SaveInviteAlertAnchorFromFrame(self)
        end
    end)

    centerAlertFrame:EnableMouse(false)
    centerAlertFrame:Hide()
    return centerAlertFrame
end

function LFG.GetInviteAlertAnchorPoint()
    local a = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.inviteAlertAnchor
    if a and a.point and a.relativePoint and a.x and a.y then
        return a.point, UIParent, a.relativePoint, a.x, a.y
    end
    return "CENTER", UIParent, "CENTER", 0, 120
end

function LFG.SaveInviteAlertAnchorFromFrame(frame)
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    if point and relPoint and x and y then
        if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
        FrostSeekDB.LFG.inviteAlertAnchor = {
            point = point,
            relativePoint = relPoint,
            x = x,
            y = y,
        }
    end
end

function LFG.SetInviteAlertUnlockMode(enabled)
    LFG.SetPopupUnlockMode(enabled and true or false)
end

function LFG.ResetInviteAlertAnchor()
    if FrostSeekDB and FrostSeekDB.LFG then
        FrostSeekDB.LFG.inviteAlertAnchor = nil
    end

    local popupUnlockFrames = LFG._S.popupUnlockFrames
    if popupUnlockFrames and popupUnlockFrames.Invite and popupUnlockFrames.Invite:IsShown() then
        popupUnlockFrames.Invite:ClearAllPoints()
        popupUnlockFrames.Invite:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
    print(L["msg_invite_alert_anchor_reset"])
end

function LFG.IsInviteAlertUnlockMode()
    return LFG.IsPopupUnlockMode()
end

function LFG.ShowCenterAlert(htmlText, duration)
    if not htmlText or htmlText == "" then return end
    if type(duration) ~= "number" or duration <= 0 then return end
    if not centerAlertFrame then CreateCenterAlertFrame() end
    if LFG.IsPopupUnlockMode() then return end
    centerAlertFrame:ClearAllPoints()
    local p, r, rp, x, y = LFG.GetInviteAlertAnchorPoint()
    centerAlertFrame:SetPoint(p, r, rp, x, y)
    centerAlertText:SetText(htmlText)
    centerAlertFrame:Show()
    centerAlertFrame:SetAlpha(0)
    UIFrameFadeIn(centerAlertFrame, 0.2, 0, 1)
    if centerAlertTicker then
        centerAlertTicker:Cancel()
        centerAlertTicker = nil
    end

    local fadeStart = math.max(0.2, duration - 0.6)
    C_Timer.After(fadeStart, function()
        if not centerAlertFrame then return end
        UIFrameFadeOut(centerAlertFrame, 0.6, 1, 0)
        centerAlertTicker = C_Timer.After(0.7, function()
            if centerAlertFrame then
                centerAlertFrame:Hide()
                centerAlertFrame:SetAlpha(1)
            end
            centerAlertTicker = nil
        end)
    end)
end

function LFG.ShouldShowCenterAlert()
    if not FrostSeekDB or not FrostSeekDB.LFG then return false end
    if FrostSeekDB.LFG.inviteCenterAlertEnabled == false then return false end
    if FrostSeekDB.LFG.doNotAlertInCombat and UnitAffectingCombat("player") then return false end
    return true
end

local inviteEventFrame = CreateFrame("Frame")
inviteEventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
inviteEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event ~= "PARTY_INVITE_REQUEST" then return end
    if not inviteTrackerEnabled then return end
    local inviter = ...
    if not inviter or inviter == "" then return end
    local entry = LFG.GetPendingInvite(inviter)
    if not entry then return end
    local key = NormalizePlayerName(inviter)
    pendingInvites[key] = nil
    local L = FrostSeek.L
    local truncated = entry.message or ""
    if #truncated > 160 then
        truncated = LFG.TruncateVisible and LFG.TruncateVisible(truncated, 160) or (string.sub(truncated, 1, 157) .. "...")
    end
    local prefix = L["msg_invite_context_prefix"] or "|cff88ccffFrostSeek:|r"
    local template = L["msg_invite_context_body"] or "%s sent you a group invite for: '%s'"
    local plain = string.gsub(prefix, "|c%x%x%x%x%x%x%x%x", "")
    plain = string.gsub(plain, "|r", "")
    local chatLine = string.format("%s %s", plain, string.format(template, inviter, truncated))
    PrintToChat(chatLine)
    if LFG.ShouldShowCenterAlert() then
        local dur = tonumber(FrostSeekDB.LFG.inviteCenterAlertDuration) or 5
        if dur > 0 then
            local colored = string.format("|cff88ccff%s|r  %s", prefix,
                string.format(template, "|cffffff00" .. inviter .. "|r", "|cff88ccff'" .. truncated .. "'|r"))
            LFG.ShowCenterAlert(colored, dur)
        end
    end
end)

local sessionStartTime = GetTime()


local CHANNEL_BLACKLIST = {
    ["LFG"] = true,
    [" LFG"] = true,
    ["FSK"] = true,
    ["BLFG"] = true,
    ["BBLC25C"] = true,
    ["FSK-EVT"] = true,

}

local function IsAddonProtocolMessage(msg)
    if not msg or type(msg) ~= "string" then return true end
    if string.match(msg, "^FSK%d~") then
        return true
    end
    if string.match(msg, "^BLFG%d~") then
        return true
    end
    if string.match(msg, "^LC[123]") then
        return true
    end
    if string.match(msg, "^[A-Z][A-Z]%d+[~:]") then
        return true
    end
    local sepCount = 0
    for _ in string.gmatch(msg, "~") do sepCount = sepCount + 1 end
    if sepCount >= 3 then
        return true
    end
    if not string.find(msg, " ", 1, true) and string.len(msg) > 40 then
        return true
    end
    local _, colonCount = string.gsub(msg, ":", "")
    if colonCount < 2 then return false end
    return string.match(msg, "^[Ll][Ff][Gg]:")
        or string.match(msg, "^[Ll][Ff][Mm]:")
        or string.match(msg, "^%[[Ll][Ff][Gg]%]:")
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
EventFrame:RegisterEvent("CHAT_MSG_SAY")
EventFrame:RegisterEvent("CHAT_MSG_YELL")
EventFrame:RegisterEvent("CHAT_MSG_GUILD")
EventFrame:RegisterEvent("CHAT_MSG_OFFICER")
EventFrame:RegisterEvent("CHAT_MSG_RAID")
EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
EventFrame:RegisterEvent("CHAT_MSG_PARTY")
EventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")

local messageQueue = {}
local messageQueueSize = 0
local MAX_QUEUE_SIZE = 200
local queueProcessorFrame = nil
local queueProcessorActive = false

local function ProcessMessageQueue()
    if messageQueueSize == 0 then
        queueProcessorActive = false
        if queueProcessorFrame then queueProcessorFrame:Hide() end
        return
    end
    local toProcess = messageQueue
    messageQueue = {}
    messageQueueSize = 0
    for i = 1, #toProcess do
        local entry = toProcess[i]
        if entry and LFG.IsLFMMessage(entry.message) then
            LFG.RecordActiveSearch(entry.sender, entry.message, entry.channel)
        end
    end
end

local function ScheduleQueueProcessing()
    if queueProcessorActive then return end
    queueProcessorActive = true
    if not queueProcessorFrame then
        queueProcessorFrame = CreateFrame("Frame")
        queueProcessorFrame:Hide()
        local t = 0
        queueProcessorFrame:SetScript("OnUpdate", function(self, elapsed)
            t = t + elapsed
            if t >= 0.15 then
                t = 0
                ProcessMessageQueue()
                if messageQueueSize == 0 then
                    queueProcessorActive = false
                    self:Hide()
                end
            end
        end)
    end
    queueProcessorFrame:Show()
end

EventFrame:SetScript("OnEvent", function(self, event, message, sender, language, channelName, ...)
    if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then return end
    if not message or not sender then return end
    sender = string.gsub(sender, "%-[^|]+", "")
    if sender == UnitName("player") then return end
    if IsAddonProtocolMessage(message) then return end
    local channel = event
    if event == "CHAT_MSG_CHANNEL" then
        local cleanName = channelName and string.match(channelName, "^%s*%d*%.?%s*(.-)%s*$") or ""
        if CHANNEL_BLACKLIST[cleanName] then return end
        local chIdx = select(4, ...)
        if chIdx then
            local okGN, _, chanName = pcall(function() return GetChannelName(chIdx) end)
            if okGN and chanName then
                local cn = tostring(chanName)
                if CHANNEL_BLACKLIST[cn] then return end
            end
        end
        local chBase = select(5, ...)
        if chBase and CHANNEL_BLACKLIST[tostring(chBase)] then return end
        channel = cleanName or "CHANNEL"
    end
    if messageQueueSize < MAX_QUEUE_SIZE then
        messageQueueSize = messageQueueSize + 1
        messageQueue[messageQueueSize] = { sender = sender, message = message, channel = channel }
        ScheduleQueueProcessing()
    end
end)

local function InitializeLFGSystem()
    sessionStartTime = GetTime()
    FrostSeekDB.LFG = FrostSeekDB.LFG or {}
    FrostSeekDB.LFG.myRole = FrostSeekDB.LFG.myRole or L["none"]
    FrostSeekDB.LFG.popupCategories = FrostSeekDB.LFG.popupCategories or {
        ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true, PVP = true, MANASTORM = true, KEYSTONE = true, MISC = false
    }
    if FrostSeekDB.LFG.popupModeFilter == nil then FrostSeekDB.LFG.popupModeFilter = "LFM" end

    if FrostSeekDB.LFG.popupRoleFilter == nil then
        FrostSeekDB.LFG.popupRoleFilter = "ALL"
    end

    if FrostSeekDB.LFG.popupShowLFG == nil or FrostSeekDB.LFG.popupShowLFM == nil then
        local legacy = FrostSeekDB.LFG.popupModeFilter
        if legacy == "LFG" then
            FrostSeekDB.LFG.popupShowLFG = true
            FrostSeekDB.LFG.popupShowLFM = false
        elseif legacy == "LFM" then
            FrostSeekDB.LFG.popupShowLFG = false
            FrostSeekDB.LFG.popupShowLFM = true
        else
            FrostSeekDB.LFG.popupShowLFG = true
            FrostSeekDB.LFG.popupShowLFM = true
        end
        FrostSeekDB.LFG.popupModeFilter = nil
    end
    FrostSeekDB.LFG.popupShowLFG = FrostSeekDB.LFG.popupShowLFG ~= false
    FrostSeekDB.LFG.popupShowLFM = FrostSeekDB.LFG.popupShowLFM ~= false

    if FrostSeekDB.LFG.popupCategories.CUSTOM ~= nil then
        FrostSeekDB.LFG.popupCategories.CUSTOM = nil
    end
    if FrostSeekDB.LFG.popupCategories.RDF ~= nil then
        FrostSeekDB.LFG.popupCategories.RDF = nil
    end
    if not FrostSeekDB.LFG.activityFilter then
        FrostSeekDB.LFG.activityFilter = {}
    end
    for _, entry in ipairs(LFG.ACTIVITY_FILTER_GROUPS) do
        if not entry.isHeader and entry.id then
            if FrostSeekDB.LFG.activityFilter[entry.id] == nil then
                FrostSeekDB.LFG.activityFilter[entry.id] = true
            end
        end
    end

    if FrostSeekDB.LFG.showActiveRecruitersWindow == nil then
        FrostSeekDB.LFG.showActiveRecruitersWindow = false
    end
    if type(FrostSeekDB.LFG.inviteContextEnabled) ~= "boolean" then
        FrostSeekDB.LFG.inviteContextEnabled = true
    end
    inviteTrackerEnabled = FrostSeekDB.LFG.inviteContextEnabled ~= false
    if type(FrostSeekDB.LFG.inviteCenterAlertEnabled) ~= "boolean" then
        FrostSeekDB.LFG.inviteCenterAlertEnabled = true
    end
    if type(FrostSeekDB.LFG.inviteCenterAlertDuration) ~= "number" then
        FrostSeekDB.LFG.inviteCenterAlertDuration = 5
    end

    C_Timer.NewTicker(60, LFG.CleanupPendingInvites)
    C_Timer.NewTicker(10, LFG.CleanupActiveSearches)
    print(L["msg_lfg_system_initialized"])
end

SLASH_FSINVITES1 = "/fsinvites"
SlashCmdList["FSINVITES"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local L = FrostSeek.L
    if msg == "clear" then
        local count = 0
        for _ in pairs(pendingInvites) do count = count + 1 end
        LFG.ClearPendingInvites()
        print((L["msg_invites_cleared"] or "|cff88ccffFrostSeek:|r Cleared %d pending invite(s)."):format(count))
        return
    end
    if msg == "on" then
        LFG.SetInviteTrackerEnabled(true)
        FrostSeekDB.LFG.inviteContextEnabled = true
        print(L["msg_invites_enabled"] or "|cff88ccffFrostSeek:|r Invite context message enabled.")
        return
    end
    if msg == "off" then
        LFG.SetInviteTrackerEnabled(false)
        FrostSeekDB.LFG.inviteContextEnabled = false
        print(L["msg_invites_disabled"] or "|cff88ccffFrostSeek:|r Invite context message disabled.")
        return
    end

    local count = 0
    for _ in pairs(pendingInvites) do count = count + 1 end
    print((L["msg_invites_status"] or "|cff88ccffFrostSeek:|r Invite tracker: %s, %d pending whisper(s) tracked."):format(
        LFG.IsInviteTrackerEnabled() and (L["on"] or "ON") or (L["off"] or "OFF"),
        count
    ))
    print(L["msg_invites_usage"] or "Usage: /fsinvites [on|off|clear]")
end


C_Timer.After(2, InitializeLFGSystem)

SLASH_FSDEBUGTOGGLE1 = "/fsdebugtoggle"
SlashCmdList["FSDEBUGTOGGLE"] = function()
    FrostSeekDB.Settings.debugMode = not FrostSeekDB.Settings.debugMode
    print(L["msg_debug_mode"] .. (FrostSeekDB.Settings.debugMode and L["txt_debug_enabled"] or L["txt_debug_disabled"]))
end


function LFG:ApplyTheme()
    if self.UpdateRecruitersList then
        self:UpdateRecruitersList()
    end
    if self.frame and self.frame:IsShown() then
        if self.RefreshList then self:RefreshList() end
    end
    if self.refreshBtn then
        local primaryC = _tc("primary")
        self.refreshBtn.color = primaryC
        self.refreshBtn.text:SetTextColor(min(primaryC[1] * 1.2, 1), min(primaryC[2] * 1.2, 1), min(primaryC[3] * 1.2, 1))
        self.refreshBtn.bg:SetColorTexture(primaryC[1] * 0.25, primaryC[2] * 0.25, primaryC[3] * 0.25, 0.8)
        self.refreshBtn.border:SetColorTexture(primaryC[1] * 0.5, primaryC[2] * 0.5, primaryC[3] * 0.5, 0.7)
        self.refreshBtn.accent:SetColorTexture(primaryC[1], primaryC[2], primaryC[3], 0.4)
    end
    if self.clearAllBtn then
        local dangerC = _tc("catPvP")
        self.clearAllBtn.color = dangerC
        self.clearAllBtn.text:SetTextColor(min(dangerC[1] * 1.2, 1), min(dangerC[2] * 1.2, 1), min(dangerC[3] * 1.2, 1))
        self.clearAllBtn.bg:SetColorTexture(dangerC[1] * 0.25, dangerC[2] * 0.25, dangerC[3] * 0.25, 0.8)
        self.clearAllBtn.border:SetColorTexture(dangerC[1] * 0.5, dangerC[2] * 0.5, dangerC[3] * 0.5, 0.7)
        self.clearAllBtn.accent:SetColorTexture(dangerC[1], dangerC[2], dangerC[3], 0.4)
    end
    if self.profileBtn then
        local accentC = _tc("accent")
        if self.profileBtn.color then
            self.profileBtn.color = accentC
            self.profileBtn.text:SetTextColor(min(accentC[1] * 1.2, 1), min(accentC[2] * 1.2, 1), min(accentC[3] * 1.2, 1))
            self.profileBtn.bg:SetColorTexture(accentC[1] * 0.25, accentC[2] * 0.25, accentC[3] * 0.25, 0.8)
            self.profileBtn.border:SetColorTexture(accentC[1] * 0.5, accentC[2] * 0.5, accentC[3] * 0.5, 0.7)
            self.profileBtn.accent:SetColorTexture(accentC[1], accentC[2], accentC[3], 0.4)
        end
    end
    if self.wispBtn then
        local accentC = _tc("accent")
        if self.wispBtn.color then
            self.wispBtn.color = accentC
            self.wispBtn.text:SetTextColor(min(accentC[1] * 1.2, 1), min(accentC[2] * 1.2, 1), min(accentC[3] * 1.2, 1))
            self.wispBtn.bg:SetColorTexture(accentC[1] * 0.25, accentC[2] * 0.25, accentC[3] * 0.25, 0.8)
            self.wispBtn.border:SetColorTexture(accentC[1] * 0.5, accentC[2] * 0.5, accentC[3] * 0.5, 0.7)
            self.wispBtn.accent:SetColorTexture(accentC[1], accentC[2], accentC[3], 0.4)
        end
    end
end


local _rolePromptShownThisSession = false

StaticPopupDialogs["FROSTSEEK_ROLE_PROMPT"] = {
    text = L["popup_role_prompt_text"],
    button1 = L["role_tank"],
    button2 = L["role_healer"],
    button3 = L["role_dps"],
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    OnAccept = function()
        LFG.SetRole("Tank")
        print(L["msg_role_set_tank"])
    end,
    OnCancel = function()
        LFG.SetRole("Healer")
        print(L["msg_role_set_healer"])
    end,
    OnAlt = function()
        LFG.SetRole("DPS")
        print(L["msg_role_set_dps"])
    end,
}

function LFG.PromptForRoleIfMissing()
    if _rolePromptShownThisSession then return end
    if not FrostSeekDB or not FrostSeekDB.LFG then return end
    local role = FrostSeekDB.LFG.myRole
    if role and role ~= "" and role ~= "No Role" and role ~= L["none"] then
        return
    end
    _rolePromptShownThisSession = true
    C_Timer.After(2, function()
        if StaticPopupDialogs and StaticPopupDialogs["FROSTSEEK_ROLE_PROMPT"] then
            StaticPopup_Show("FROSTSEEK_ROLE_PROMPT")
        end
    end)
end


if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("lfg", LFG)
end

_G.FrostSeek.LFG = LFG
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("lfg")
end
