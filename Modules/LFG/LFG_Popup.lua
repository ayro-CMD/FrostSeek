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

local LFG = _G.FrostSeek and (_G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg or _G.FrostSeek.LFG)
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg_popup", LFG)

local L = FrostSeek.L
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end

local openFrames = LFG._S.openFrames
local lastPopupTimes = LFG._S.lastPopupTimes
local mutedPlayers = LFG._S.mutedPlayers
local popupUnlockFrames = LFG._S.popupUnlockFrames
local INVITE_ALERT_ACCENT = LFG._S.INVITE_ALERT_ACCENT
local ACTIVITY_DUNGEON_LOOKUP = LFG.ACTIVITY_DUNGEON_LOOKUP
local SHORT_NAME_OVERRIDES = LFG.SHORT_NAME_OVERRIDES
local CATEGORY_ACCENT = LFG.CATEGORY_ACCENT
local popupQueue = {}
local isProcessingQueue = false

function LFG.CanShowPopup(sender, message)
    if not sender or not message then return false end
    local now = GetTime()
    local senderCooldown = lastPopupTimes["__sender_" .. sender]
    if senderCooldown and (now - senderCooldown) < 3 then
        return false
    end
    local normalizedMessage = string.lower(message):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    local messageKey = sender .. ":" .. normalizedMessage
    local lastTime = lastPopupTimes[messageKey]
    if lastTime and (now - lastTime) < (FrostSeekDB.LFG.popupCooldown or 400) then
        return false
    end
    lastPopupTimes[messageKey] = now
    lastPopupTimes["__sender_" .. sender] = now
    return true
end

function LFG.CountActivePopups()
    local count = 0
    for _, frame in ipairs(openFrames) do
        if frame and frame:IsShown() then
            count = count + 1
        end
    end
    return count
end

function LFG.ProcessPopupQueue()
    if isProcessingQueue then return end
    if #popupQueue == 0 then return end
    if LFG.CountActivePopups() >= (FrostSeekDB.LFG.maxConcurrentPopups or 3) then
        C_Timer.After(1, function()
            LFG.ProcessPopupQueue()
        end)
        return
    end
    isProcessingQueue = true
    local nextPopup = table.remove(popupQueue, 1)
    LFG.CreateLFGPopup(
        nextPopup.sender,
        nextPopup.message,
        nextPopup.dungeon,
        nextPopup.isHeroic,
        nextPopup.isMythic,
        nextPopup.isRaid,
        nextPopup.isPvp,
        nextPopup.isKeystone,
        nextPopup.isManastorm,
        nextPopup.category
    )
    isProcessingQueue = false
end

function LFG.RemovePopupFrame(frame)
    if frame then
        if frame.category and FrostSeek and FrostSeek.RemoveMinimapCategory then
            FrostSeek.RemoveMinimapCategory(frame.category)
        end
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
        frame:SetParent(nil)
        for i, popup in ipairs(openFrames) do
            if popup == frame then
                table.remove(openFrames, i)
                break
            end
        end
        LFG.RepositionPopups()
        if #popupQueue > 0 then
            C_Timer.After(1, function()
                LFG.ProcessPopupQueue()
            end)
        end
    end
end

function LFG.GetPopupAnchorPoint()
    local a = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.popupAnchor
    if a and a.point and a.relativePoint and a.x and a.y then
        return a.point, UIParent, a.relativePoint, a.x, a.y
    end
    return "TOP", UIParent, "TOP", 0, -40
end

function LFG.RepositionPopups()
    local activeCount = 0
    local point, relFrame, relPoint, xOfs, yOfs = LFG.GetPopupAnchorPoint()
    for _, frame in ipairs(openFrames) do
        if frame and frame:IsShown() then
            local h = frame:GetHeight() or 90
            local cascadeY
            if yOfs <= 0 then
                cascadeY = yOfs - (activeCount * (h + 6))
            else
                cascadeY = yOfs + (activeCount * (h + 6))
            end
            frame:ClearAllPoints()
            frame:SetPoint(point, relFrame, relPoint, xOfs, cascadeY)
            activeCount = activeCount + 1
        end
    end
end

local popupUnlockFrame = nil

local function BuildDemoPopup(kind)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(340, 100)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame.kind = kind

    local bgColor, borderColor, titleText
    if kind == "LFG" then
        bgColor     = { 0.18, 0.36, 0.55, 0.35 }
        borderColor = { 0.53, 0.80, 1.00, 0.85 }
        titleText   = L["txt_lfg_popup_anchor"]
    elseif kind == "FrostNet" then
        bgColor     = { 0.18, 0.50, 0.32, 0.35 }
        borderColor = { 0.35, 0.95, 0.55, 0.85 }
        titleText   = L["txt_frostnet_app_popup_anchor"]
    else
        bgColor     = { 0.20, 0.10, 0.32, 0.40 }
        borderColor = { INVITE_ALERT_ACCENT[1], INVITE_ALERT_ACCENT[2], INVITE_ALERT_ACCENT[3], 0.85 }
        titleText   = L["txt_invite_alert_popup_anchor"]
    end

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(unpack(bgColor))

    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints()
    frame.border:SetColorTexture(unpack(borderColor))
    frame.topAccent = frame:CreateTexture(nil, "ARTWORK")
    frame.topAccent:SetPoint("TOPLEFT", 1, 0)
    frame.topAccent:SetPoint("TOPRIGHT", -1, 0)
    frame.topAccent:SetHeight(2)
    frame.topAccent:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], 0.9)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText(titleText)
    frame.title:SetTextColor(1.0, 1.0, 1.0, 1.0)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    frame.hint:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.hint:SetText(L["txt_drag_me_position"])
    frame.hint:SetTextColor(1.0, 0.95, 0.3, 1.0)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    frame.footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    frame.footer:SetText(L["txt_shift_drag_reposition"])
    frame.footer:SetTextColor(0.92, 0.92, 0.92, 1.0)

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    return frame
end

function LFG.SetPopupUnlockMode(enabled)
    if enabled then
        if popupUnlockFrame and popupUnlockFrame:IsShown() then return end

        if not popupUnlockFrame then
            popupUnlockFrame = CreateFrame("Frame", nil, UIParent)
            popupUnlockFrame:SetSize(420, 110)
            popupUnlockFrame:SetFrameStrata("DIALOG")
            popupUnlockFrame:SetClampedToScreen(true)
            popupUnlockFrame:EnableMouse(true)
            popupUnlockFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)

            local panelBg = popupUnlockFrame:CreateTexture(nil, "BACKGROUND")
            panelBg:SetAllPoints()
            panelBg:SetColorTexture(0.05, 0.08, 0.12, 0.92)

            local panelBorder = popupUnlockFrame:CreateTexture(nil, "BORDER")
            panelBorder:SetAllPoints()
            panelBorder:SetColorTexture(0.53, 0.80, 1.0, 0.85)

            local title = popupUnlockFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
            title:SetPoint("TOP", popupUnlockFrame, "TOP", 0, -10)
            title:SetText(L["txt_popup_anchor_editor"])
            title:SetTextColor(0.53, 0.80, 1.0, 1.0)

            local hint = popupUnlockFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
            hint:SetPoint("TOP", title, "BOTTOM", 0, -8)
            hint:SetText(L["txt_drag_demo_boxes"])
            hint:SetTextColor(1.0, 0.95, 0.3, 1.0)

            local subHint = popupUnlockFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
            subHint:SetPoint("TOP", hint, "BOTTOM", 0, -4)
            subHint:SetText(L["txt_tip_hold_shift"])
            subHint:SetTextColor(0.85, 0.85, 0.85, 1.0)

            local function makeBtn(label, color, xOff)
                local b = CreateFrame("Button", nil, popupUnlockFrame)
                b:SetSize(120, 24)
                b:SetPoint("BOTTOM", popupUnlockFrame, "BOTTOM", xOff, 10)
                b.bg = b:CreateTexture(nil, "BACKGROUND")
                b.bg:SetAllPoints()
                b.bg:SetColorTexture(color[1] * 0.30, color[2] * 0.30, color[3] * 0.30, 0.95)
                b.border = b:CreateTexture(nil, "BORDER")
                b.border:SetAllPoints()
                b.border:SetColorTexture(color[1], color[2], color[3], 0.95)
                b.text = b:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
                b.text:SetPoint("CENTER")
                b.text:SetText(label)
                b.text:SetTextColor(1, 1, 1, 1.0)
                b:SetScript("OnEnter", function(self)
                    self.bg:SetColorTexture(color[1] * 0.50, color[2] * 0.50, color[3] * 0.50, 0.95)
                end)
                b:SetScript("OnLeave", function(self)
                    self.bg:SetColorTexture(color[1] * 0.30, color[2] * 0.30, color[3] * 0.30, 0.95)
                end)
                return b
            end

            local saveBtn = makeBtn(L["save"], {0.2, 0.85, 0.2}, -70)
            saveBtn:SetScript("OnClick", function()
                LFG.SetPopupUnlockMode(false)
            end)

            local resetBtn = makeBtn(L["reset"], {0.95, 0.55, 0.2}, 70)
            resetBtn:SetScript("OnClick", function()
                LFG.ResetPopupAnchor()
            end)

            popupUnlockFrames.LFG = BuildDemoPopup("LFG")
            popupUnlockFrames.FrostNet = BuildDemoPopup("FrostNet")
            popupUnlockFrames.Invite = BuildDemoPopup("Invite")
        end

        local lfgPoint, lfgRel, lfgRelPoint, lfgX, lfgY = LFG.GetPopupAnchorPoint()
        popupUnlockFrames.LFG:ClearAllPoints()
        popupUnlockFrames.LFG:SetPoint(lfgPoint, lfgRel, lfgRelPoint, lfgX, lfgY)

        local fnPoint, fnRel, fnRelPoint, fnX, fnY = LFG.GetApplicantPopupAnchorPoint()
        popupUnlockFrames.FrostNet:ClearAllPoints()
        popupUnlockFrames.FrostNet:SetPoint(fnPoint, fnRel, fnRelPoint, fnX, fnY)

        local ivPoint, ivRel, ivRelPoint, ivX, ivY = LFG.GetInviteAlertAnchorPoint()
        popupUnlockFrames.Invite:ClearAllPoints()
        popupUnlockFrames.Invite:SetPoint(ivPoint, ivRel, ivRelPoint, ivX, ivY)

        popupUnlockFrame:Show()
        popupUnlockFrames.LFG:Show()
        popupUnlockFrames.FrostNet:Show()
        popupUnlockFrames.Invite:Show()
        print(L["msg_popup_editor_open"])
    else
        if popupUnlockFrames.LFG and popupUnlockFrames.LFG:IsShown() then
            LFG.SavePopupAnchorFromFrame(popupUnlockFrames.LFG)
            popupUnlockFrames.LFG:Hide()
        end
        if popupUnlockFrames.FrostNet and popupUnlockFrames.FrostNet:IsShown() then
            LFG.SaveApplicantPopupAnchorFromFrame(popupUnlockFrames.FrostNet)
            popupUnlockFrames.FrostNet:Hide()
        end
        if popupUnlockFrames.Invite and popupUnlockFrames.Invite:IsShown() then
            LFG.SaveInviteAlertAnchorFromFrame(popupUnlockFrames.Invite)
            popupUnlockFrames.Invite:Hide()
        end
        if popupUnlockFrame and popupUnlockFrame:IsShown() then
            popupUnlockFrame:Hide()
            print(L["msg_popup_anchors_saved"])
        end
        LFG.RepositionPopups()
        if _G.FrostSeek and _G.FrostSeek.Listings and _G.FrostSeek.Listings.RepositionAppPopups then
            _G.FrostSeek.Listings.RepositionAppPopups()
        end
    end
end

function LFG.IsPopupUnlockMode()
    return popupUnlockFrame ~= nil and popupUnlockFrame:IsShown()
end

function LFG.SavePopupAnchorFromFrame(frame)
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    if point and relPoint and x and y then
        if not FrostSeekDB.LFG then FrostSeekDB.LFG = {} end
        FrostSeekDB.LFG.popupAnchor = {
            point = point,
            relativePoint = relPoint,
            x = x,
            y = y,
        }
    end
end

function LFG.GetApplicantPopupAnchorPoint()
    local a = FrostSeekDB and FrostSeekDB.Listings and FrostSeekDB.Listings.appPopupAnchor
    if a and a.point and a.relativePoint and a.x and a.y then
        return a.point, UIParent, a.relativePoint, a.x, a.y
    end
    return "TOPLEFT", UIParent, "TOPLEFT", 10, -40
end

function LFG.SaveApplicantPopupAnchorFromFrame(frame)
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    if point and relPoint and x and y then
        if not FrostSeekDB.Listings then FrostSeekDB.Listings = {} end
        FrostSeekDB.Listings.appPopupAnchor = {
            point = point,
            relativePoint = relPoint,
            x = x,
            y = y,
        }
    end
end

function LFG.ResetPopupAnchor()
    if FrostSeekDB and FrostSeekDB.LFG then
        FrostSeekDB.LFG.popupAnchor = nil
        FrostSeekDB.LFG.inviteAlertAnchor = nil
    end
    if FrostSeekDB and FrostSeekDB.Listings then
        FrostSeekDB.Listings.appPopupAnchor = nil
    end
    if popupUnlockFrames.LFG then
        popupUnlockFrames.LFG:ClearAllPoints()
        popupUnlockFrames.LFG:SetPoint("TOP", UIParent, "TOP", 0, -40)
    end
    if popupUnlockFrames.FrostNet then
        popupUnlockFrames.FrostNet:ClearAllPoints()
        popupUnlockFrames.FrostNet:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -40)
    end
    if popupUnlockFrames.Invite then
        popupUnlockFrames.Invite:ClearAllPoints()
        popupUnlockFrames.Invite:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
    LFG.RepositionPopups()
    if _G.FrostSeek and _G.FrostSeek.Listings and _G.FrostSeek.Listings.RepositionAppPopups then
        _G.FrostSeek.Listings.RepositionAppPopups()
    end
    print(L["msg_popup_anchors_reset"])
end

function LFG.AttachPopupDragHandler(popup)
    if not popup then return end
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
            self._dragging = true
        end
    end)
    popup:SetScript("OnDragStop", function(self)
        if self._dragging then
            self:StopMovingOrSizing()
            self._dragging = false
            LFG.SavePopupAnchorFromFrame(self)
            LFG.RepositionPopups()
            print(L["msg_popup_anchor_saved"])
        end
    end)
end

function LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isMythic, isRaid, isPvp, isKeystone, isManastorm, category)
    if category == "MISC" then return end
    if FrostSeekDB.LFG.disablePopups then return end
    if FrostSeekDB.LFG.disableLFG then return end
    if FrostSeekDB.LFG.doNotAlertInGroup and ((GetNumPartyMembers and GetNumPartyMembers() > 0) or (GetNumRaidMembers and GetNumRaidMembers() > 0) or (GetNumGroupMembers and GetNumGroupMembers() > 1)) then return end
    if FrostSeekDB.LFG.doNotAlertInCombat and UnitAffectingCombat("player") then return end
    local activePopupCount = LFG.CountActivePopups()
    if mutedPlayers[sender] and GetTime() < mutedPlayers[sender] then
        return
    end
    if isKeystone and FrostSeekDB.LFG.keystoneMinLevel and FrostSeekDB.LFG.keystoneMinLevel > 0 then
        local _, ksLevel = LFG.ParseKeystoneInfo(message)
        if ksLevel and ksLevel < FrostSeekDB.LFG.keystoneMinLevel then
            return
        end
    end
    if category ~= "MISC" and not FrostSeekDB.LFG.popupCategories[category] and not FrostSeekDB.LFG.popupCategories["ALL"] then
        return
    end
    local roleFilter = FrostSeekDB.LFG.popupRoleFilter or "ALL"
    if roleFilter ~= "ALL" then
        local parsedRoles = LFG.ParseRoles(message)
        local roleKey = string.lower(roleFilter)
        local totalParsed = 0
        if parsedRoles then
            totalParsed = (parsedRoles.tank or 0) + (parsedRoles.healer or 0)
                       + (parsedRoles.dps or 0) + (parsedRoles.support or 0)
        end

        if totalParsed > 0 and not (parsedRoles[roleKey] and parsedRoles[roleKey] > 0) then
            return
        end
    end
    local msgModePre = LFG.GetMessageMode(message) or "LFG"
    local showLFGPre = FrostSeekDB.LFG.popupShowLFG ~= false
    local showLFMPre = FrostSeekDB.LFG.popupShowLFM ~= false
    if msgModePre == "LFG" and not showLFGPre then return end
    if msgModePre == "LFM" and not showLFMPre then return end
    if (not showLFGPre) and (not showLFMPre) then return end
    if activePopupCount >= (FrostSeekDB.LFG.maxConcurrentPopups or 3) then
        table.insert(popupQueue, {
            sender = sender,
            message = message,
            dungeon = dungeon,
            isHeroic = isHeroic,
            isMythic = isMythic,
            isRaid = isRaid,
            isPvp = isPvp,
            isKeystone = isKeystone,
            isManastorm = isManastorm,
            category = category,
        })
        return
    end

    if not LFG.CanShowPopup(sender, message) then return end

    local accent = CATEGORY_ACCENT[category] or CATEGORY_ACCENT.MISC
    local ar, ag, ab = accent[1], accent[2], accent[3]

    local UI = FrostSeekUIUtils
    local W, H = 340, 100
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(W, H)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup.category = category


    local borderTex = popup:CreateTexture(nil, "BACKGROUND")
    borderTex:SetAllPoints()
    borderTex:SetColorTexture(ar * 0.3, ag * 0.3, ab * 0.3, 0.65)


    local bgPopupColor = _tc("bgPopup")
    local bgTex = popup:CreateTexture(nil, "BORDER")
    bgTex:SetPoint("TOPLEFT", 1, -1)
    bgTex:SetPoint("BOTTOMRIGHT", -1, 1)
    bgTex:SetColorTexture(bgPopupColor[1], bgPopupColor[2], bgPopupColor[3], bgPopupColor[4])

    local aPoint, aRel, aRelPoint, aX, aY = LFG.GetPopupAnchorPoint()
    local cascadeY
    if aY <= 0 then
        cascadeY = aY - (activePopupCount * (H + 6))
    else
        cascadeY = aY + (activePopupCount * (H + 6))
    end
    popup:SetPoint(aPoint, aRel, aRelPoint, aX, cascadeY)
    popup:SetAlpha(0)
    UIFrameFadeIn(popup, 0.2, 0, 1)
    LFG.AttachPopupDragHandler(popup)


    local topAccent = popup:CreateTexture(nil, "ARTWORK")
    topAccent:SetPoint("TOPLEFT", 1, 0)
    topAccent:SetPoint("TOPRIGHT", -1, 0)
    topAccent:SetHeight(2)
    topAccent:SetColorTexture(ar, ag, ab, 0.9)


    local glassReflect = popup:CreateTexture(nil, "ARTWORK")
    glassReflect:SetPoint("TOPLEFT", 2, -3)
    glassReflect:SetPoint("TOPRIGHT", -2, -3)
    glassReflect:SetHeight(14)
    glassReflect:SetColorTexture(ar * 0.06, ag * 0.06, ab * 0.06, 0.3)


    local catLabels = {
        DUNGEON = L["cat_dungeon"], RAID = L["cat_raid"],
        WORLD_BOSS = L["cat_world_boss"], PVP = L["cat_pvp"],
        MANASTORM = L["cat_manastorm"], KEYSTONE = L["cat_keystone"],
    }
    local catText = catLabels[category] or L["cat_misc"]
    popup.headerText = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    popup.headerText:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -8)
    popup.headerText:SetText(catText)
    popup.headerText:SetTextColor(min(ar * 1.4, 1), min(ag * 1.4, 1), min(ab * 1.4, 1))

    local difficulty = LFG.ParseDifficulty(message, category)
    local diffTag = ""
    local diffColor = "|cffcccccc"
    if difficulty then
        local dl = difficulty:lower()
        if dl:find("ascended") or dl == "asc" then
            local num = dl:match("ascended%s*(%d+)") or dl:match("asc%s*(%d+)") or ""
            diffTag = L["diff_ascended"] .. (num ~= "" and num or "")
            diffColor = "|cffaa44ff"
        elseif dl:find("trial") then
            local num = dl:match("trial%s*(%d+)") or ""
            diffTag = L["diff_trial"] .. (num ~= "" and num or "")
            diffColor = "|cffff8800"
        elseif dl:find("mythic") then
            local num = dl:match("mythic%s*(%d+)") or dl:match("m%s*(%d+)") or ""
            diffTag = L["diff_mythic"] .. (num ~= "" and num or "")
            diffColor = "|cffff44ff"
        elseif dl:find("heroic") or dl == "hc" then
            diffTag = L["diff_heroic"]
            diffColor = "|cff44cc44"
        elseif dl:find("ranked") then
            diffTag = L["diff_ranked"]
            diffColor = "|cffff4444"
        elseif dl == "instanced" then
            diffTag = L["diff_normal"] .. " (Inst)"
            diffColor = "|cffcccccc"
        elseif dl:find("instanced") then
            diffTag = difficulty
            diffColor = "|cffff8800"
        elseif dl:find("open world") then
            diffTag = L["diff_normal"]
            diffColor = "|cffcccccc"
        else
            diffTag = difficulty
            diffColor = "|cffcccccc"
        end
    elseif isMythic then
        diffTag = L["diff_mythic"]
        diffColor = "|cffff44ff"
    elseif isHeroic then
        diffTag = L["diff_heroic"]
        diffColor = "|cff44cc44"
    elseif category == "PVP" then
        local lowerForPvP = string.lower(message or "")
        local _, pvpRanked = LFG.ClassifyPvP(lowerForPvP)
        if pvpRanked then
            diffTag = L["diff_ranked"]
            diffColor = "|cffff4444"
        else
            diffTag = L["diff_normal"]
            diffColor = "|cffcccccc"
        end
    elseif category == "DUNGEON" or category == "RAID" then
        diffTag = L["diff_normal"]
        diffColor = "|cffcccccc"
    end

    local catHex = string.format("%02x%02x%02x", math.floor(ar*255), math.floor(ag*255), math.floor(ab*255))
    local dungeonDisplay = ""
    local shortDungeon = LFG.GetShortDungeonName(category, dungeon)
    if isKeystone then
        local ksName, ksLevel = LFG.ParseKeystoneInfo(message)
        if not ksLevel then
            ksLevel = LFG.ParseKeystoneLevel(message)
        end
        local _, wingShort, wingParentName, wingParentId = LFG.ParseDungeonWing(message, category, dungeon)
        if ksName and ksName ~= "" then
            local linkBase, linkWing = LFG.SplitKeystoneWingName(ksName)
            if linkWing then
                local dispBase = linkBase
                if SHORT_NAME_OVERRIDES[dispBase] then
                    dispBase = SHORT_NAME_OVERRIDES[dispBase]
                elseif string.len(dispBase) > 16 then
                    local firstWord = string.match(dispBase, "^(%S+)")
                    if firstWord and string.len(firstWord) <= 16 then
                        dispBase = firstWord
                    else
                        dispBase = string.sub(dispBase, 1, 14) .. "..."
                    end
                end
                local linkShort = linkWing
                if string.len(linkShort) > 12 then
                    linkShort = string.match(linkWing, "^(%S+)") or linkWing
                end
                local dispBaseLower = string.lower(dispBase or "")
                if not string.find(dispBaseLower, string.lower(linkShort), 1, true) then
                    dungeonDisplay = dispBase .. " " .. linkShort
                else
                    dungeonDisplay = dispBase
                end
            else
                dungeonDisplay = ksName
            end
        else
            if wingParentName and (dungeon == "KEYSTONE" or wingParentId == dungeon) then
                dungeonDisplay = SHORT_NAME_OVERRIDES[wingParentName] or LFG.GetShortDungeonName(category, wingParentId) or (shortDungeon ~= "" and shortDungeon or L["cat_keystone"])
            else
                dungeonDisplay = shortDungeon ~= "" and shortDungeon or L["cat_keystone"]
            end
            if wingShort and wingParentId and wingParentId == dungeon then
                local dispLower = string.lower(dungeonDisplay)
                if not string.find(dispLower, string.lower(wingShort), 1, true) then
                    dungeonDisplay = dungeonDisplay .. " " .. wingShort
                end
            end
        end
        if ksLevel then
            diffTag = L["diff_mythic"] .. ksLevel
            diffColor = "|cffff44ff"
        end
    elseif category == "RAID" then
        dungeonDisplay = shortDungeon ~= "" and shortDungeon or L["cat_raid"]
    elseif category == "WORLD_BOSS" then
        dungeonDisplay = shortDungeon ~= "" and shortDungeon or L["cat_world_boss"]
    elseif category == "MANASTORM" then
        dungeonDisplay = shortDungeon ~= "" and shortDungeon or L["cat_manastorm"]
    elseif category == "PVP" then
        dungeonDisplay = shortDungeon ~= "" and shortDungeon or L["cat_pvp"]
    else
        dungeonDisplay = shortDungeon ~= "" and shortDungeon or L["cat_dungeon"]
    end

    local row1Y = -22
    local iconX = 10

    local dungeonFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    dungeonFS:SetPoint("TOPLEFT", popup, "TOPLEFT", iconX, row1Y)
    dungeonFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    dungeonFS:SetJustifyH("LEFT")
    dungeonFS:SetWordWrap(false)
    local dungeonColorHex = catHex
    if diffColor == "|cffaa44ff" then dungeonColorHex = "aa44ff"
    elseif diffColor == "|cffff8800" then dungeonColorHex = "ff8800"
    elseif diffColor == "|cffff44ff" then dungeonColorHex = "ff44ff"
    elseif diffColor == "|cff44cc44" then dungeonColorHex = "44cc44"
    elseif diffColor == "|cffff4444" then dungeonColorHex = "ff4444"
    end
    local dungeonLine = "|cff" .. dungeonColorHex .. dungeonDisplay .. "|r"
    if diffTag ~= "" then
        dungeonLine = dungeonLine .. "  " .. diffColor .. "[" .. diffTag .. "]|r"
    end
    dungeonLine = dungeonLine .. "  |cffffffff" .. (sender or L["unknown"]) .. "|r"
    dungeonFS:SetText(dungeonLine)

    local row2Y = -40
    local roles = LFG.ParseRoles(message)
    local roleTagStr = LFG.FormatRolesText(roles)
    local roleFullStr = LFG.FormatRolesFullText(roles)
    local rolesFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    rolesFS:SetPoint("TOPLEFT", popup, "TOPLEFT", iconX, row2Y)
    rolesFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    rolesFS:SetJustifyH("LEFT")
    if roleTagStr and roleTagStr ~= "" then
        rolesFS:SetText(L["txt_looking_for"] .. roleTagStr)
    else
        rolesFS:SetText(L["txt_looking_for_anyone"])
    end

    local row3Y = -58
    local msgFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    msgFS:SetPoint("TOPLEFT", popup, "TOPLEFT", iconX, row3Y)
    msgFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    msgFS:SetJustifyH("LEFT")
    msgFS:SetWordWrap(false)
    local rawForDisplay = message or ""
    local truncMsg = #rawForDisplay > 80
        and (LFG.TruncateVisible and LFG.TruncateVisible(rawForDisplay, 80) or string.sub(rawForDisplay, 1, 77) .. "...")
        or rawForDisplay
    msgFS:SetTextColor(1, 1, 1, 1)
    msgFS:SetText(LFG.FormatMessageWithIcons(truncMsg))

    local footerY = 6

    local whisperBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 64, 20, L["popup_whisper"], _tc("success"))
    if not whisperBtn then
        whisperBtn = CreateFrame("Button", nil, popup)
        whisperBtn:SetSize(64, 20)
        whisperBtn.text = whisperBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        whisperBtn.text:SetPoint("CENTER")
        whisperBtn.text:SetText(L["popup_whisper"])
    end
    whisperBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 6, footerY)
    whisperBtn:SetScript("OnClick", function()
        local whisperMsg = LFG.CreateWhisperMessage()
        SendChatMessage(whisperMsg, "WHISPER", nil, sender)
        LFG.RememberWhisperSent(sender, message, category, dungeon)
        LFG.RemovePopupFrame(popup)
        UIErrorsFrame:AddMessage("|cff88ccff" .. FrostSeek.Lf("popup_whisper_sent", sender) .. "|r", 1, 1, 1, 3)
    end)
    whisperBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["popup_whisper"] .. " -> " .. tostring(sender), 0.8, 1, 0.8)
        local previewMsg = LFG.CreateWhisperMessage() or ""
        if #previewMsg > 200 then
            previewMsg = LFG.TruncateVisible and LFG.TruncateVisible(previewMsg, 200) or (string.sub(previewMsg, 1, 197) .. "...")
        end
        local isCustom = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled
        local label = isCustom and (L["tip_preview_custom"] or "Preview (custom):") or (L["tip_preview_base"] or "Preview (base):")
        GameTooltip:AddLine(label, 0.7, 0.85, 1, true)
        GameTooltip:AddLine("|cff88ccff" .. previewMsg .. "|r", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    whisperBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local muteBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 48, 20, L["popup_mute"], _tc("warning"))
    if not muteBtn then
        muteBtn = CreateFrame("Button", nil, popup)
        muteBtn:SetSize(48, 20)
        muteBtn.text = muteBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        muteBtn.text:SetPoint("CENTER")
        muteBtn.text:SetText(L["popup_mute"])
    end
    muteBtn:SetPoint("LEFT", whisperBtn, "RIGHT", 4, 0)
    muteBtn:SetScript("OnClick", function()
        mutedPlayers[sender] = GetTime() + 1800
        LFG.RemovePopupFrame(popup)
        print("|cffff8800FrostSeek:|r " .. FrostSeek.Lf("popup_muted", sender))
    end)

    local muteBossBtn
    if category == "WORLD_BOSS" and dungeon and dungeon ~= "" then
        muteBossBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 80, 20, L["popup_mute_boss"], _tc("catWorldBoss"))
        if not muteBossBtn then
            muteBossBtn = CreateFrame("Button", nil, popup)
            muteBossBtn:SetSize(80, 20)
            muteBossBtn.text = muteBossBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
            muteBossBtn.text:SetPoint("CENTER")
            muteBossBtn.text:SetText(L["popup_mute_boss"])
        end
        muteBossBtn:SetPoint("LEFT", muteBtn, "RIGHT", 4, 0)
        muteBossBtn:SetScript("OnClick", function()
            local filterIds = ACTIVITY_DUNGEON_LOOKUP[dungeon]
            if filterIds and #filterIds > 0 then
                for _, id in ipairs(filterIds) do
                    FrostSeekDB.LFG.activityFilter[id] = false
                end
            end
            for i = #openFrames, 1, -1 do
                local f = openFrames[i]
                if f and f.category == "WORLD_BOSS" and f.dungeon == dungeon then
                    LFG.RemovePopupFrame(f)
                end
            end
            if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
            print("|cffff8800FrostSeek:|r " .. FrostSeek.Lf("popup_boss_muted", tostring(dungeon)))
        end)
        muteBossBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["popup_mute_boss"])
            GameTooltip:AddLine(L["popup_mute_boss_desc"], 0.85, 0.85, 0.85, true)
            GameTooltip:Show()
        end)
        muteBossBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    popup.dungeon = dungeon

    local closeBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 48, 20, L["close"], _tc("secondary"))
    if not closeBtn then
        closeBtn = CreateFrame("Button", nil, popup)
        closeBtn:SetSize(48, 20)
        closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        closeBtn.text:SetPoint("CENTER")
        closeBtn.text:SetText(L["close"])
    end
    closeBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -6, footerY)
    closeBtn:SetScript("OnClick", function()
        LFG.RemovePopupFrame(popup)
    end)

    local duration = FrostSeekDB.LFG.frameDuration or 5
    popup.expiryTime = GetTime() + duration
    popup:SetScript("OnUpdate", function(self, elapsed)
        local remaining = self.expiryTime - GetTime()
        if remaining <= 0 then
            self:SetScript("OnUpdate", nil)
            LFG.RemovePopupFrame(self)
        elseif remaining < 0.8 then
            self:SetAlpha(remaining / 0.8)
        end
    end)

    if not FrostSeekDB.LFG.silentNotifications then
        if Shared and Shared.PlaySound then
            Shared.PlaySound("popup")
        elseif PlaySoundFile then
            PlaySoundFile("Interface\\AddOns\\FrostSeek\\Media\\sound\\popup.wav")
        end
    end
    table.insert(openFrames, popup)
    if FrostSeek and FrostSeek.SetMinimapCategory then
        FrostSeek.SetMinimapCategory(category)
    end
end
