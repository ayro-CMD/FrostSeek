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
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg_ui", LFG)

local L = FrostSeek.L
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end

local activeSearches = LFG._S.activeSearches
local openFrames = LFG._S.openFrames
local lastPopupTimes = LFG._S.lastPopupTimes
local mutedPlayers = LFG._S.mutedPlayers
local searchExpirationTime = LFG._S.searchExpirationTime
local ROW_HEIGHT = 26
local MAX_DISPLAY_ROWS = 10
local rowPool = {}
local lfgSearchText = ""
local lfgSearchDebounce = nil
local ACTIVITY_FILTER_GROUPS = LFG.ACTIVITY_FILTER_GROUPS

local function StripTooltipEscapes(s)
    if not s then return "" end
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|T[^|]-|t", "  ")
    return s
end

function LFG.WrapTooltipText(text, maxChars)
    local lines = {}
    if not text or text == "" then return lines end
    maxChars = maxChars or 55
    local cur, curLen = "", 0
    for w in string.gmatch(text, "%S+") do
        local wl = #StripTooltipEscapes(w)
        if curLen == 0 then
            cur, curLen = w, wl
        elseif curLen + 1 + wl <= maxChars then
            cur = cur .. " " .. w
            curLen = curLen + 1 + wl
        else
            table.insert(lines, cur)
            cur, curLen = w, wl
        end
    end
    if cur ~= "" then table.insert(lines, cur) end
    return lines
end
local DUNGEON_WING_LOOKUP = LFG.DUNGEON_WING_LOOKUP
local SHORT_NAME_OVERRIDES = LFG.SHORT_NAME_OVERRIDES
local CATEGORY_TAG = LFG.CATEGORY_TAG
local DIFFICULTY_FILTERS = LFG.DIFFICULTY_FILTERS
local CATEGORY_ACCENT = LFG.CATEGORY_ACCENT
local WING_LABEL_COLOR = LFG.WING_LABEL_COLOR
local WING_NAME_COLOR = LFG.WING_NAME_COLOR
local SafeTipLabel = LFG.GetTipLabel

local function CloseAllDropdowns()
    if LFG.roleDropdown and LFG.roleDropdown.menu and LFG.roleDropdown.menu:IsShown() then
        LFG.roleDropdown.menu:Hide()
    end
end

function LFG.CleanupActiveSearches()
    if not activeSearches then activeSearches = {} end
    local now = GetTime()
    local removedCount = 0
    for i = #activeSearches, 1, -1 do
        if activeSearches[i] and activeSearches[i].lastUpdate and
           (now - activeSearches[i].lastUpdate > searchExpirationTime) then
            table.remove(activeSearches, i)
            removedCount = removedCount + 1
        end
    end
    if removedCount > 0 then
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end
end

C_Timer.NewTicker(300, function()
    local now = GetTime()
    for name, expiry in pairs(mutedPlayers) do
        if now >= expiry then
            mutedPlayers[name] = nil
        end
    end

    local cooldown = (FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.popupCooldown) or 370
    for k, t in pairs(lastPopupTimes) do
        if (now - t) > (cooldown + 60) then
            lastPopupTimes[k] = nil
        end
    end
end)

function LFG.ClearAllSearches()
    if activeSearches then wipe(activeSearches) else activeSearches = {} end
    for i = #openFrames, 1, -1 do
        LFG.RemovePopupFrame(openFrames[i])
    end
    openFrames = {}
    if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    print(L["msg_all_searches_cleared"])
end

function LFG.ScrollRecruitersList(direction)
    if not LFG.recruitersScrollFrame then return end
    local scrollBar = LFG.recruitersScrollFrame:GetScrollChild()
    if not scrollBar then return end
    local range = scrollBar:GetHeight() - LFG.recruitersScrollFrame:GetHeight()
    if range <= 0 then return end
    local cur = LFG.recruitersScrollFrame:GetVerticalScroll()
    if direction == "UP" then
        LFG.recruitersScrollFrame:SetVerticalScroll(math.max(0, cur - ROW_HEIGHT))
    elseif direction == "DOWN" then
        LFG.recruitersScrollFrame:SetVerticalScroll(math.min(range, cur + ROW_HEIGHT))
    end
end

function LFG.CountFilteredSearches()
    local count = 0
    for _, search in ipairs(activeSearches or {}) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
            count = count + 1
        end
    end
    return count
end

function LFG.UpdatePlayerInfo()
    if not LFG.playerInfoText then return end
    local classInfo, ilvl, enchant = LFG.GetFullPlayerInfo()
    local roleText = (FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole ~= L["none"]) and (L["txt_role_prefix"] .. FrostSeekDB.LFG.myRole) or L["txt_role_not_set"]
    LFG.playerInfoText:SetText(string.format("|cffffffff%s | |cff00ff00%diLvl|r | %s %s",
        classInfo, ilvl, roleText, enchant))
end

local contextMenu = nil

local function CreateContextMenu()
    if contextMenu then return contextMenu end
    contextMenu = CreateFrame("Frame", "FrostSeekContextMenu", UIParent, "UIDropDownMenuTemplate")
    contextMenu.playerName = nil
    local function OnClick_Whisper()
        if not contextMenu.playerName then return end
        local editBox = ChatEdit_GetActiveWindow()
        if not editBox then
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat("/w " .. contextMenu.playerName .. " ")
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat("/w " .. contextMenu.playerName .. " ")
            end
        else
            editBox:SetText("/w " .. contextMenu.playerName .. " ")
            editBox:SetCursorPosition(string.len(editBox:GetText()))
        end
    end
    local function OnClick_Invite()
        if not contextMenu.playerName then return end
        InviteUnit(contextMenu.playerName)
        print(L["msg_invite_sent_to"] .. contextMenu.playerName)
    end
    local function OnClick_SendWhisperWithLFG()
        if not contextMenu.playerName then return end
        local msg = LFG.CreateWhisperMessage()
        SendChatMessage(msg, "WHISPER", nil, contextMenu.playerName)
        local search = LFG.FindActiveSearchByPlayer(contextMenu.playerName)
        if search then
            LFG.RememberWhisperSent(
                contextMenu.playerName,
                search.message,
                search.category,
                search.dungeon
            )
        else
            LFG.RememberWhisperSent(contextMenu.playerName, "")
        end
        print(L["msg_lfg_whisper_sent_to"] .. contextMenu.playerName)
    end
    local function OnClick_AddFriend()
        if not contextMenu.playerName then return end
        if C_FriendList and C_FriendList.AddFriend then
            C_FriendList.AddFriend(contextMenu.playerName)
        elseif AddFriend then
            AddFriend(contextMenu.playerName)
        end
        print(L["msg_friend_request_sent_to"] .. contextMenu.playerName)
    end
    local function OnClick_Ignore()
        if not contextMenu.playerName then return end
        if C_FriendList and C_FriendList.AddIgnore then
            C_FriendList.AddIgnore(contextMenu.playerName)
        elseif AddIgnore then
            AddIgnore(contextMenu.playerName)
        end
        print("|cff88ccffFrostSeek:|r " .. contextMenu.playerName .. L["msg_added_to_ignore_list"])
    end
    local function OnClick_CopyName()
        if not contextMenu.playerName then return end
        local editBox = ChatEdit_GetActiveWindow()
        if not editBox then
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat(contextMenu.playerName)
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat(contextMenu.playerName)
            end
        else
            editBox:SetText(contextMenu.playerName)
        end
    end
    local menuItems = {
        { text = L["txt_player_menu_title"], isTitle = true, notCheckable = true },
        { text = L["txt_menu_whisper"], func = OnClick_Whisper, notCheckable = true },
        { text = L["txt_menu_lfg_whisper_auto"], func = OnClick_SendWhisperWithLFG, notCheckable = true },
        { text = L["txt_menu_invite_to_group"], func = OnClick_Invite, notCheckable = true },
        { text = L["presence_add_friend"], func = OnClick_AddFriend, notCheckable = true },
        { text = L["txt_menu_ignore"], func = OnClick_Ignore, notCheckable = true },
        { text = L["txt_menu_copy_name"], func = OnClick_CopyName, notCheckable = true },
    }
    UIDropDownMenu_Initialize(contextMenu, function(self, level)
        if not level then return end
        for _, item in ipairs(menuItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.isTitle = item.isTitle or false
            info.notCheckable = item.notCheckable or false
            info.func = item.func
            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")
    return contextMenu
end

local function ShowPlayerContextMenu(playerName, anchor)
    if not playerName or playerName == "" then return end
    CreateContextMenu()
    contextMenu.playerName = playerName
    ToggleDropDownMenu(1, nil, contextMenu, anchor or "cursor", 0, 0)
end

LFG.ShowPlayerContextMenu = ShowPlayerContextMenu

function LFG.InitRowPool(parent)
    rowPool = {}
    local rowW = parent:GetWidth()
    if not rowW or rowW <= 0 then rowW = 740 end
    for i = 1, MAX_DISPLAY_ROWS do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(rowW, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2 - (i - 1) * ROW_HEIGHT)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 3, 0)
        bg:SetPoint("BOTTOMRIGHT", 0, 0)
        bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        local accentBar = row:CreateTexture(nil, "BACKGROUND")
        accentBar:SetPoint("TOPLEFT", 0, 0)
        accentBar:SetSize(3, ROW_HEIGHT)
        accentBar:SetColorTexture(unpack(_tc("border")))
        local separator = row:CreateTexture(nil, "BACKGROUND")
        separator:SetPoint("BOTTOMLEFT", 6, 0)
        separator:SetPoint("BOTTOMRIGHT", -2, 0)
        separator:SetHeight(1)
        separator:SetColorTexture(unpack(_tc("separator")))
        local dot = row:CreateTexture(nil, "OVERLAY")
        dot:SetSize(6, 6)
        dot:SetPoint("LEFT", row, "LEFT", 12, 0)
        dot:SetColorTexture(unpack(_tc("border")))
        local nameText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 18, 0)
        nameText:SetWidth(80)
        nameText:SetJustifyH("LEFT")
        nameText:SetText("")
        nameText:SetTextColor(unpack(_tc("textAccent")))
        local nameClickFrame = CreateFrame("Button", nil, row)
        nameClickFrame:SetPoint("LEFT", row, "LEFT", 18, 0)
        nameClickFrame:SetSize(80, ROW_HEIGHT)
        nameClickFrame:RegisterForClicks("RightButtonUp")
        nameClickFrame:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                local pr = rowPool[i]
                if pr and pr.currentRecord and pr.currentRecord.player then
                    LFG.ShowPlayerContextMenu(pr.currentRecord.player, self)
                end
            end
        end)
        local timeText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        timeText:SetPoint("LEFT", row, "LEFT", 108, 0)
        timeText:SetWidth(40)
        timeText:SetJustifyH("LEFT")
        timeText:SetText("")
        timeText:SetTextColor(unpack(_tc("textDim")))
        local catText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        catText:SetPoint("LEFT", row, "LEFT", 158, 0)
        catText:SetWidth(30)
        catText:SetJustifyH("LEFT")
        catText:SetText("")
        local roleText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        roleText:SetPoint("LEFT", row, "LEFT", 192, 0)
        roleText:SetWidth(70)
        roleText:SetJustifyH("LEFT")
        roleText:SetText("")
        roleText:SetTextColor(unpack(_tc("textNorm")))
        local dungeonText = row:CreateFontString(nil, "OVERLAY", "FSKFontDisableSmall")
        dungeonText:SetPoint("LEFT", row, "LEFT", 266, 0)
        dungeonText:SetWidth(82)
        dungeonText:SetJustifyH("LEFT")
        dungeonText:SetText("")
        dungeonText:SetTextColor(unpack(_tc("textNorm")))
        local msgText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        msgText:SetPoint("LEFT", row, "LEFT", 350, 0)
        msgText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        msgText:SetJustifyH("LEFT")
        msgText:SetText("")
        msgText:SetTextColor(unpack(_tc("textPrimary")))
        local tooltipFrame = CreateFrame("Frame", nil, row)
        tooltipFrame:SetPoint("LEFT", row, "LEFT", 350, 0)
        tooltipFrame:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        tooltipFrame:SetHeight(ROW_HEIGHT)
        tooltipFrame:EnableMouse(true)
        local tooltipBg = tooltipFrame:CreateTexture(nil, "BACKGROUND")
        tooltipBg:SetAllPoints()
        tooltipBg:SetColorTexture(0, 0, 0, 0)
        local acceptBtn = FrostSeekUIUtils.CreateModernButton(row, 60, 20, L["listings_accept"], _tc("catDungeon"))
        acceptBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        acceptBtn:SetScript("OnClick", function()
            local pr = rowPool[i]
            if pr and pr.currentRecord then
                local msg = LFG.CreateWhisperMessage()
                SendChatMessage(msg, "WHISPER", nil, pr.currentRecord.player)
                LFG.RememberWhisperSent(
                    pr.currentRecord.player,
                    pr.currentRecord.message,
                    pr.currentRecord.category,
                    pr.currentRecord.dungeon
                )
                print(L["msg_whisper_sent_to_lfg"] .. pr.currentRecord.player)
            end
        end)
        acceptBtn:SetScript("OnEnter", function(self)
            local pr = rowPool[i]
            if not pr or not pr.currentRecord then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["listings_accept"] .. " -> " .. tostring(pr.currentRecord.player), 0.8, 1, 0.8)
            local previewMsg = LFG.CreateWhisperMessage() or ""
            if #previewMsg > 200 then previewMsg = LFG.TruncateVisible and LFG.TruncateVisible(previewMsg, 200) or (string.sub(previewMsg, 1, 197) .. "...") end
            local isCustom = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled
            local label = isCustom and (L["tip_preview_custom"] or "Preview (custom):") or (L["tip_preview_base"] or "Preview (base):")
            GameTooltip:AddLine(label, 0.7, 0.85, 1, true)
            GameTooltip:AddLine("|cff88ccff" .. previewMsg .. "|r", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        acceptBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        row:SetScript("OnEnter", function(self)
            local pr = rowPool[i]
            local accent = pr.accent
            local ri = pr.rowIndex
            pr.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
            pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
            pr.nameText:SetTextColor(unpack(_tc("textAccent")))
        end)
        row:SetScript("OnLeave", function(self)
            local pr = rowPool[i]
            local accent = pr.accent
            local ri = pr.rowIndex
            if ri % 2 == 0 then
                pr.bg:SetColorTexture(unpack(_tc("bgRowEven")))
            else
                pr.bg:SetColorTexture(unpack(_tc("bgRowOdd")))
            end
            pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
            pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
            pr.nameText:SetTextColor(unpack(_tc("textAccent")))
        end)
        row:Hide()
        rowPool[i] = {
            frame = row,
            bg = bg,
            accentBar = accentBar,
            dot = dot,
            nameText = nameText,
            timeText = timeText,
            catText = catText,
            roleText = roleText,
            dungeonText = dungeonText,
            msgText = msgText,
            tooltipFrame = tooltipFrame,
            accent = {0.5, 0.5, 0.5},
            currentRecord = nil,
            rowIndex = i,
        }
    end
end

function LFG.CreateRowForPool(parent, idx)
    local row = CreateFrame("Frame", nil, parent)
    local rowW = parent:GetWidth()
    if not rowW or rowW <= 0 then rowW = 740 end
    row:SetSize(rowW, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2 - (idx - 1) * ROW_HEIGHT)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 3, 0)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    bg:SetColorTexture(unpack(_tc("bgRowOdd")))
    local accentBar = row:CreateTexture(nil, "BACKGROUND")
    accentBar:SetPoint("TOPLEFT", 0, 0)
    accentBar:SetSize(3, ROW_HEIGHT)
    accentBar:SetColorTexture(unpack(_tc("border")))
    local dot = row:CreateTexture(nil, "OVERLAY")
    dot:SetSize(6, 6)
    dot:SetPoint("LEFT", row, "LEFT", 12, 0)
    dot:SetColorTexture(unpack(_tc("border")))
    local nameText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    nameText:SetPoint("LEFT", row, "LEFT", 18, 0)
    nameText:SetWidth(80)
    nameText:SetJustifyH("LEFT")
    nameText:SetText("")
    nameText:SetTextColor(unpack(_tc("textAccent")))
    local nameClickFrame = CreateFrame("Button", nil, row)
    nameClickFrame:SetPoint("LEFT", row, "LEFT", 18, 0)
    nameClickFrame:SetSize(80, ROW_HEIGHT)
    nameClickFrame:RegisterForClicks("RightButtonUp")
    nameClickFrame:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            local pr = rowPool[idx]
            if pr and pr.currentRecord and pr.currentRecord.player then
                LFG.ShowPlayerContextMenu(pr.currentRecord.player, self)
            end
        end
    end)
    local timeText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    timeText:SetPoint("LEFT", row, "LEFT", 108, 0)
    timeText:SetWidth(40)
    timeText:SetJustifyH("LEFT")
    timeText:SetText("")
    timeText:SetTextColor(unpack(_tc("textDim")))
    local catText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    catText:SetPoint("LEFT", row, "LEFT", 158, 0)
    catText:SetWidth(30)
    catText:SetJustifyH("LEFT")
    catText:SetText("")
    local roleText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    roleText:SetPoint("LEFT", row, "LEFT", 192, 0)
    roleText:SetWidth(70)
    roleText:SetJustifyH("LEFT")
    roleText:SetText("")
    roleText:SetTextColor(unpack(_tc("textNorm")))
    local dungeonText = row:CreateFontString(nil, "OVERLAY", "FSKFontDisableSmall")
    dungeonText:SetPoint("LEFT", row, "LEFT", 266, 0)
    dungeonText:SetWidth(82)
    dungeonText:SetJustifyH("LEFT")
    dungeonText:SetText("")
    dungeonText:SetTextColor(unpack(_tc("textNorm")))
    local msgText = row:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    msgText:SetPoint("LEFT", row, "LEFT", 350, 0)
    msgText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    msgText:SetJustifyH("LEFT")
    msgText:SetText("")
    msgText:SetTextColor(unpack(_tc("textPrimary")))
    local tooltipFrame = CreateFrame("Frame", nil, row)
    tooltipFrame:SetPoint("LEFT", row, "LEFT", 350, 0)
    tooltipFrame:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    tooltipFrame:SetHeight(ROW_HEIGHT)
    tooltipFrame:EnableMouse(true)
    local tooltipBg = tooltipFrame:CreateTexture(nil, "BACKGROUND")
    tooltipBg:SetAllPoints()
    tooltipBg:SetColorTexture(0, 0, 0, 0)
    local acceptBtn = FrostSeekUIUtils.CreateModernButton(row, 60, 20, L["listings_accept"], _tc("catDungeon"))
    acceptBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    acceptBtn:SetScript("OnClick", function()
        local pr = rowPool[idx]
        if pr and pr.currentRecord then
            local msg = LFG.CreateWhisperMessage()
            SendChatMessage(msg, "WHISPER", nil, pr.currentRecord.player)
            LFG.RememberWhisperSent(
                pr.currentRecord.player,
                pr.currentRecord.message,
                pr.currentRecord.category,
                pr.currentRecord.dungeon
            )
            print(L["msg_whisper_sent_to_lfg"] .. pr.currentRecord.player)
        end
    end)
    acceptBtn:SetScript("OnEnter", function(self)
        local pr = rowPool[idx]
        if not pr or not pr.currentRecord then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["listings_accept"] .. " -> " .. tostring(pr.currentRecord.player), 0.8, 1, 0.8)
        local previewMsg = LFG.CreateWhisperMessage() or ""
        if #previewMsg > 200 then previewMsg = LFG.TruncateVisible and LFG.TruncateVisible(previewMsg, 200) or (string.sub(previewMsg, 1, 197) .. "...") end
        local isCustom = FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled
        local label = isCustom and (L["tip_preview_custom"] or "Preview (custom):") or (L["tip_preview_base"] or "Preview (base):")
        GameTooltip:AddLine(label, 0.7, 0.85, 1, true)
        GameTooltip:AddLine("|cff88ccff" .. previewMsg .. "|r", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    acceptBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    row:SetScript("OnEnter", function(self)
        local pr = rowPool[idx]
        local accent = pr.accent
        local ri = pr.rowIndex
        pr.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
        pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
        pr.nameText:SetTextColor(unpack(_tc("textAccent")))
    end)
    row:SetScript("OnLeave", function(self)
        local pr = rowPool[idx]
        local accent = pr.accent
        local ri = pr.rowIndex
        if ri % 2 == 0 then
            pr.bg:SetColorTexture(unpack(_tc("bgRowEven")))
        else
            pr.bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        end
        pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
        pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
        pr.nameText:SetTextColor(unpack(_tc("textAccent")))
    end)
    row:Hide()
    local newRow = {
        frame = row,
        bg = bg,
        accentBar = accentBar,
        dot = dot,
        nameText = nameText,
        timeText = timeText,
        catText = catText,
        roleText = roleText,
        dungeonText = dungeonText,
        msgText = msgText,
        tooltipFrame = tooltipFrame,
        accent = {0.5, 0.5, 0.5},
        currentRecord = nil,
        rowIndex = idx,
    }
    rowPool[idx] = newRow
    return newRow
end

function LFG.UpdateKeySortHeader()
    if not LFG.keySortHeaderText then return end
    local baseText = L["col_dungeon"] or "Dungeon"
    if LFG.CurrentCategory == "KEYSTONE" and LFG.KeySortState == "desc" then
        LFG.keySortHeaderText:SetText(baseText .. " |cff88ccffv|r")
    elseif LFG.CurrentCategory == "KEYSTONE" and LFG.KeySortState == "asc" then
        LFG.keySortHeaderText:SetText(baseText .. " |cff88ccff^|r")
    else
        LFG.keySortHeaderText:SetText(baseText)
    end
end

function LFG.UpdateRecruitersList()
    if not LFG.recruitersList then return end
    if not activeSearches then activeSearches = {} end
    local scrollChild = LFG.recruitersList.scrollChild
    for i = 1, #rowPool do
        if rowPool[i] then
            rowPool[i].frame:Hide()
            rowPool[i].currentRecord = nil
        end
    end
    if LFG.noRecruitersText then
        LFG.noRecruitersText:Hide()
    end
    local filteredSearches = {}
    local searchLower = lfgSearchText and string.lower(lfgSearchText) or ""
    local diffFilter = LFG.DifficultyFilter
    local diffFilters = diffFilter and DIFFICULTY_FILTERS[LFG.CurrentCategory or ""] or nil
    local activeDiffMatch = nil
    if diffFilters and diffFilter then
        for _, f in ipairs(diffFilters) do
            if f.label == diffFilter then activeDiffMatch = f.match; break end
        end
    end

    local roleFilter = LFG.RoleFilter or "ALL"
    local roleFilterKey = nil
    if roleFilter ~= "ALL" then
        roleFilterKey = string.lower(roleFilter)
    end

    local function passesRoleFilter(search)
        if not roleFilterKey then return true end
        local roles = LFG.ParseRoles(search.message)
        if not roles then return true end
        local totalParsed = (roles.tank or 0) + (roles.healer or 0)
                         + (roles.dps or 0) + (roles.support or 0)
        
        if totalParsed == 0 then return true end
        local count = tonumber(roles[roleFilterKey]) or 0
        return count > 0
    end

    for _, search in ipairs(activeSearches) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
            local passesMode = true
            if LFG.ModeFilter and LFG.ModeFilter ~= "ALL" then
                local recMode = LFG.GetMessageMode(search.message) or "LFG"
                search.mode = recMode
                passesMode = (recMode == LFG.ModeFilter)
            end
            if not passesMode then

            elseif not passesRoleFilter(search) then

            elseif activeDiffMatch then
                local diffLabel = LFG.ParseDifficulty(search.message, search.category)
                if activeDiffMatch(diffLabel) then
                    if searchLower == "" then
                        table.insert(filteredSearches, search)
                    else
                        local msgLower = string.lower(search.message or "")
                        local playerLower = string.lower(search.player or "")
                        local dungeonLower = string.lower(search.dungeon or "")
                        local dungeonNameLower = string.lower(search.dungeonName or "")
                        local catLower = string.lower(search.category or "")
                        if string.find(msgLower, searchLower, 1, true)
                            or string.find(playerLower, searchLower, 1, true)
                            or string.find(dungeonLower, searchLower, 1, true)
                            or string.find(dungeonNameLower, searchLower, 1, true)
                            or string.find(catLower, searchLower, 1, true) then
                            table.insert(filteredSearches, search)
                        end
                    end
                end
            else
                if searchLower == "" then
                    table.insert(filteredSearches, search)
                else
                    local msgLower = string.lower(search.message or "")
                    local playerLower = string.lower(search.player or "")
                    local dungeonLower = string.lower(search.dungeon or "")
                    local dungeonNameLower = string.lower(search.dungeonName or "")
                    local catLower = string.lower(search.category or "")
                    if string.find(msgLower, searchLower, 1, true)
                        or string.find(playerLower, searchLower, 1, true)
                        or string.find(dungeonLower, searchLower, 1, true)
                        or string.find(dungeonNameLower, searchLower, 1, true)
                        or string.find(catLower, searchLower, 1, true) then
                        table.insert(filteredSearches, search)
                    end
                end
            end
        end
    end
    table.sort(filteredSearches, function(a, b)
        return (a.lastUpdate or 0) > (b.lastUpdate or 0)
    end)
    if LFG.CurrentCategory == "KEYSTONE" and LFG.KeySortState then
        local function GetRecordKeyLevel(rec)
            if not rec then return -1 end
            if rec._ksLevel == nil then
                local _, lvl = LFG.ParseKeystoneInfo(rec.message)
                rec._ksLevel = lvl or -1
            end
            return rec._ksLevel
        end
        table.sort(filteredSearches, function(a, b)
            local la = GetRecordKeyLevel(a)
            local lb = GetRecordKeyLevel(b)
            local aHas = la >= 0
            local bHas = lb >= 0
            if aHas ~= bHas then
                return aHas
            end
            if not aHas and not bHas then
                return (a.lastUpdate or 0) > (b.lastUpdate or 0)
            end
            if la ~= lb then
                if LFG.KeySortState == "desc" then
                    return la > lb
                else
                    return la < lb
                end
            end
            return (a.lastUpdate or 0) > (b.lastUpdate or 0)
        end)
    end
    if LFG.lfgCountText then
        LFG.lfgCountText:SetText(string.format(L["lfg_active_recruiters"], #filteredSearches))
    end
    local totalFiltered = #filteredSearches
    if scrollChild then
        scrollChild:SetHeight(math.max(260, totalFiltered * ROW_HEIGHT + 4))
    end
    if LFG.scrollIndicator then
        if totalFiltered > MAX_DISPLAY_ROWS then
            LFG.scrollIndicator:SetText(tostring(totalFiltered) .. L["msg_recruiters_count"])
        else
            LFG.scrollIndicator:SetText(tostring(totalFiltered) .. L["msg_recruiters_count"])
        end
    end
    local now = GetTime()
    for idx = 1, totalFiltered do
        local record = filteredSearches[idx]
        local poolRow = rowPool[idx]
        if not poolRow and scrollChild then
            poolRow = LFG.CreateRowForPool(scrollChild, idx)
        end
        if poolRow and record then
            poolRow.currentRecord = record
            local accent = CATEGORY_ACCENT[record.category] or CATEGORY_ACCENT.MISC
            poolRow.accent = accent
            poolRow.rowIndex = idx
            if idx % 2 == 0 then
                poolRow.bg:SetColorTexture(unpack(_tc("bgRowEven")))
            else
                poolRow.bg:SetColorTexture(unpack(_tc("bgRowOdd")))
            end
            poolRow.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
            poolRow.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
            poolRow.nameText:SetText(record.player or L["unknown"])
            local timeSince = now - (record.lastUpdate or 0)
            if timeSince < 60 then
                poolRow.timeText:SetText(string.format("%ds", math.floor(timeSince)))
            else
                poolRow.timeText:SetText(string.format("%dm", math.floor(timeSince/60)))
            end
            poolRow.catText:SetText(CATEGORY_TAG[record.category] or "|cFF00FF00D|r")
            local roles = LFG.ParseRoles(record.message)
            local roleStr = LFG.FormatRolesText(roles)
            local roleFullStr = LFG.FormatRolesFullText(roles)
            poolRow.roleText:SetText(roleStr)
            local ksName, ksLevel
            if record.isKeystone then
                ksName, ksLevel = LFG.ParseKeystoneInfo(record.message)
                if not ksLevel then
                    ksLevel = LFG.ParseKeystoneLevel(record.message)
                end
            end
            local ksBaseName, ksLinkWing
            if ksName and ksName ~= "" then
                local linkBase, linkWing = LFG.SplitKeystoneWingName(ksName)
                if linkWing then
                    ksBaseName = linkBase
                    ksLinkWing = linkWing
                end
            end
            local wingName, wingShort, wingParentName, wingParentId = LFG.ParseDungeonWing(record.message, record.category, record.dungeon)
            if record.dungeon and record.dungeon ~= "MISC" and record.dungeon ~= "PVP" and record.dungeon ~= "MANASTORM" and record.dungeon ~= "WORLD_BOSS" then

                local diffLabel = LFG.ParseDifficulty(record.message, record.category)
                local diffTag, diffColor
                if diffLabel then
                    local dl = diffLabel:lower()
                    if dl:find("ascended") or dl:find("asc") then
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
                    elseif dl:find("heroic") or dl:find("hc") then
                        diffTag = L["diff_heroic"]
                        diffColor = "|cff44cc44"
                    elseif dl:find("ranked") then
                        diffTag = L["diff_ranked"]
                        diffColor = "|cffff4444"
                    elseif dl == "instanced" then
                        diffTag = L["diff_normal"] .. " (Inst)"
                        diffColor = "|cffcccccc"
                    elseif dl:find("instanced") then
                        diffTag = diffLabel
                        diffColor = "|cffff8800"
                    elseif dl:find("open world") then
                        diffTag = L["diff_normal"]
                        diffColor = "|cffcccccc"
                    else
                        diffTag = diffLabel
                        diffColor = "|cffcccccc"
                    end
                elseif record.isMythic then
                    diffTag = L["diff_mythic"]
                    diffColor = "|cffff44ff"
                elseif record.isHeroic then
                    diffTag = L["diff_heroic"]
                    diffColor = "|cff44cc44"
                elseif record.category == "DUNGEON" or record.category == "RAID" or record.category == "WORLD_BOSS" then
                    local plusLvl = string.match(record.message or "", "%+(%d%d+)")
                    if plusLvl then
                        diffTag = "+" .. plusLvl
                        diffColor = "|cffff44ff"
                    else
                        diffTag = L["diff_normal"]
                        diffColor = "|cffcccccc"
                    end
                end
                if record.isKeystone and ksLevel then
                    diffTag = "+" .. tostring(ksLevel)
                    diffColor = "|cffff44ff"
                end
                local fullDungeonName = record.dungeonName or record.dungeon or ""
                local dungeonName = LFG.GetShortDungeonName(record.category, record.dungeon) or fullDungeonName
                if record.isKeystone and ksName and ksName ~= "" then
                    local rowName = ksBaseName or ksName
                    if SHORT_NAME_OVERRIDES[rowName] then
                        dungeonName = SHORT_NAME_OVERRIDES[rowName]
                    elseif string.len(rowName) > 16 then
                        local firstWord = string.match(rowName, "^(%S+)")
                        if firstWord and string.len(firstWord) <= 16 then
                            dungeonName = firstWord
                        else
                            dungeonName = string.sub(rowName, 1, 14) .. "..."
                        end
                    else
                        dungeonName = rowName
                    end
                end
                if record.isKeystone and (not ksName or ksName == "") and wingParentName
                    and (record.dungeon == "KEYSTONE" or DUNGEON_WING_LOOKUP[record.dungeon]) then
                    dungeonName = SHORT_NAME_OVERRIDES[wingParentName] or LFG.GetShortDungeonName(record.category, wingParentId) or dungeonName
                end
                if wingShort and wingParentName then
                    local wingBaseLower = string.lower(dungeonName or "")
                    if not string.find(wingBaseLower, string.lower(wingShort), 1, true) then
                        local wingBaseName = SHORT_NAME_OVERRIDES[wingParentName] or LFG.GetShortDungeonName(record.category, wingParentId) or dungeonName
                        if wingBaseName and wingBaseName ~= "" then
                            dungeonName = wingBaseName .. " " .. wingShort
                        else
                            dungeonName = dungeonName .. " " .. wingShort
                        end
                    end
                end
                if ksLinkWing and not (wingShort and wingParentName) then
                    local linkShort = ksLinkWing
                    if string.len(linkShort) > 12 then
                        linkShort = string.match(ksLinkWing, "^(%S+)") or ksLinkWing
                    end
                    local rowBaseLower = string.lower(dungeonName or "")
                    if not string.find(rowBaseLower, string.lower(linkShort), 1, true) then
                        dungeonName = dungeonName .. " " .. linkShort
                    end
                end
                local catAccent = CATEGORY_ACCENT[record.category] or CATEGORY_ACCENT.MISC
                local ar2, ag2, ab2 = catAccent[1] or 0.7, catAccent[2] or 0.7, catAccent[3] or 0.7
                local nameColorHex = string.format("|cff%02x%02x%02x",
                    math.floor(math.max(0, math.min(1, ar2)) * 255),
                    math.floor(math.max(0, math.min(1, ag2)) * 255),
                    math.floor(math.max(0, math.min(1, ab2)) * 255))
                local dungeonDisplay = nameColorHex .. dungeonName .. "|r"
                if diffTag and diffTag ~= "" then
                    dungeonDisplay = dungeonDisplay .. " " .. diffColor .. "[" .. diffTag .. "]|r"
                end
                poolRow.dungeonText:SetText(dungeonDisplay)
            else
                poolRow.dungeonText:SetText("")
            end
            poolRow.msgText:SetText(LFG.FormatMessageWithIcons(LFG.ShortenMessage(record.message) or ""))
            local timeSinceForTooltip = timeSince
            poolRow.tooltipFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 10)
                GameTooltip:AddLine("|cFFFFFF00" .. (record.player or L["unknown"]) .. "|r", 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["tip_full_message"], 0, 1, 0)
                local fullMsg = LFG.FormatMessageWithIcons(record.message or "")
                local msgLines = LFG.WrapTooltipText(fullMsg, 55)
                if #msgLines == 0 then msgLines = { fullMsg } end
                for _, chunk in ipairs(msgLines) do
                    GameTooltip:AddLine(chunk, 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
                if roleFullStr and roleFullStr ~= "" then
                    GameTooltip:AddLine(L["tip_looking_for_label"] .. roleFullStr, 0.9, 0.85, 0.4)
                end
                GameTooltip:AddLine(L["tip_time_label"] .. string.format("%ds ago", timeSinceForTooltip), 0.8, 0.8, 0.8)
                if record.dungeon and record.dungeon ~= "MISC" then
                    local tipDungeon = record.dungeonName or record.dungeon
                    local tipWing = wingName
                    if record.isKeystone then
                        if ksName and ksName ~= "" then
                            tipDungeon = ksName
                            local linkBase, linkWing = LFG.SplitKeystoneWingName(ksName)
                            if linkWing then
                                tipWing = linkWing
                                if linkBase and linkBase ~= "" then
                                    tipDungeon = linkBase
                                end
                            elseif wingName then
                                local stripped = string.gsub(tipDungeon, "%s*%-?%s*" .. wingName .. "%s*$", "")
                                stripped = string.gsub(stripped, "%s*[%-:]%s*$", "")
                                if stripped ~= "" and stripped ~= tipDungeon then
                                    tipDungeon = stripped
                                end
                            end
                        elseif wingParentName and (record.dungeon == "KEYSTONE" or DUNGEON_WING_LOOKUP[record.dungeon]) then
                            tipDungeon = wingParentName
                        end
                    elseif wingName and wingParentName then
                        tipDungeon = wingParentName
                    end
                    GameTooltip:AddLine(L["tip_dungeon_label"] .. tipDungeon, 0.8, 0.8, 0.8)
                    if tipWing then
                        GameTooltip:AddLine(WING_LABEL_COLOR .. SafeTipLabel("tip_wing_label", "Wing: ") .. "|r " .. WING_NAME_COLOR .. tipWing .. "|r")
                    end
                end
                GameTooltip:AddLine(L["tip_category_label"] .. record.category, 0.8, 0.8, 0.8)
                local tipDifficulty = nil
                if record.isKeystone then
                    if ksLevel then
                        tipDifficulty = "+" .. tostring(ksLevel)
                    end
                elseif record.category == "PVP" or record.category == "MISC" then
                    tipDifficulty = nil
                elseif record.isMythic then
                    tipDifficulty = L["diff_mythic"]
                elseif record.isHeroic then
                    tipDifficulty = L["diff_heroic"]
                else
                    tipDifficulty = LFG.ParseDifficulty(record.message, record.category)
                    if not tipDifficulty then
                        local plusLvl = string.match(record.message or "", "%+(%d%d+)")
                        if plusLvl then
                            tipDifficulty = "+" .. plusLvl
                        end
                    end
                end
                if tipDifficulty and tipDifficulty ~= "" then
                    GameTooltip:AddLine(SafeTipLabel("tip_difficulty_label", "Difficulty: ") .. tipDifficulty, 1, 0.6, 0.3)
                end
                local Presence = FrostSeek and FrostSeek.Presence
                local presenceUser = Presence and Presence.onlineUsers and record.player and Presence.onlineUsers[record.player] or nil
                if presenceUser then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cff88ccff" .. (L["tooltip_frostnet_user"] or "FrostNet User") .. "|r")
                    if presenceUser.version and presenceUser.version ~= "" then
                        GameTooltip:AddLine(string.format(L["tooltip_frostnet_version"] or "FrostSeek v%s", presenceUser.version), 0.6, 0.8, 1)
                    end
                    if presenceUser.role and presenceUser.role ~= "" and presenceUser.role ~= L["none"] then
                        GameTooltip:AddLine((L["col_role"] or "Role") .. ": " .. presenceUser.role, 0.8, 0.8, 0.8)
                    end
                end
                GameTooltip:Show()
            end)
            poolRow.tooltipFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            poolRow.frame:Show()
        end
    end
    for idx = totalFiltered + 1, #rowPool do
        if rowPool[idx] then
            rowPool[idx].frame:Hide()
            rowPool[idx].currentRecord = nil
        end
    end
    if totalFiltered == 0 then
        if LFG.noRecruitersText then
            LFG.noRecruitersText:Show()
        end
    end
end

function LFG.ChangeCategory(category)
    LFG.CurrentCategory = category
    LFG.DifficultyFilter = nil
    if category ~= "KEYSTONE" then
        LFG.KeySortState = nil
    end
    if LFG.UpdateKeySortHeader then LFG.UpdateKeySortHeader() end
    if LFG.recruitersScrollFrame then
        LFG.recruitersScrollFrame:SetVerticalScroll(0)
    end
    CloseAllDropdowns()
    if LFG.lfgTabs then
        for cat, tab in pairs(LFG.lfgTabs) do
            if tab and tab.text then
                if cat == category then
                    tab.bg:SetColorTexture(unpack(_tc("bgTabActive")))
                    tab.text:SetTextColor(unpack(_tc("textPrimary")))
                else
                    tab.bg:SetColorTexture(unpack(_tc("bgTabInactive")))
                    tab.text:SetTextColor(unpack(_tc("textNorm")))
                end
            end
        end
    end
    if LFG.UpdateDiffFilterVisibility then LFG.UpdateDiffFilterVisibility() end
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

function LFG:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local CW = math.max(700, (parentFrame:GetWidth() or 800) - 20)
    local IW = CW - 20

    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(CW, 500)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.mainContainer:EnableMouse(true)
    self.mainContainer:SetScript("OnMouseDown", function()
        CloseAllDropdowns()
    end)
    self.playerFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.playerFrame:SetSize(IW, 24)
    self.playerFrame:SetPoint("TOP", self.mainContainer, "TOP", 0, -4)

    local function UpdateToggleVisual(isOn)
    end
    LFG.lfgToggle = nil
    LFG.UpdateToggleVisual = UpdateToggleVisual
    self.roleDropdown = nil
    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    self.title:SetPoint("TOP", self.playerFrame, "BOTTOM", 0, -4)
    self.title:SetText("|cff88ccff" .. L["lfg_title"] .. "|r")
    self.title:SetTextColor(unpack(_tc("textAccent")))


    local filterBtn = CreateFrame("Button", "FrostSeekLFGFilterBtn", self.mainContainer)
    filterBtn:SetSize(18, 18)
    filterBtn:SetPoint("LEFT", self.title, "RIGHT", 10, 0)
    filterBtn.icon = filterBtn:CreateTexture(nil, "ARTWORK")
    filterBtn.icon:SetAllPoints()
    filterBtn.icon:SetTexture("Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\filtri.tga")
    filterBtn.icon:SetTexCoord(0, 1, 0, 1)
    filterBtn.bg = filterBtn:CreateTexture(nil, "BACKGROUND")
    filterBtn.bg:SetPoint("TOPLEFT", -2, 2)
    filterBtn.bg:SetPoint("BOTTOMRIGHT", 2, -2)
    filterBtn.bg:SetColorTexture(unpack(_tc("bgSection")))
    filterBtn.border = filterBtn:CreateTexture(nil, "BORDER")
    filterBtn.border:SetPoint("TOPLEFT", -1, 1)
    filterBtn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    filterBtn.border:SetColorTexture(unpack(_tc("accentBar")))
    local function UpdateFilterIconState()
        if not FrostSeekDB.LFG.activityFilter then return end
        local unchecked = 0
        for _, entry in ipairs(ACTIVITY_FILTER_GROUPS) do
            if not entry.isHeader and entry.id then
                if FrostSeekDB.LFG.activityFilter[entry.id] == false then
                    unchecked = unchecked + 1
                end
            end
        end
        if unchecked > 0 then
            filterBtn.border:SetColorTexture(unpack(_tc("borderHover")))
            filterBtn.bg:SetColorTexture(unpack(_tc("bgInput")))
        else
            filterBtn.border:SetColorTexture(unpack(_tc("accentBar")))
            filterBtn.bg:SetColorTexture(unpack(_tc("bgSection")))
        end
    end
    UpdateFilterIconState()
    filterBtn:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(unpack(_tc("borderHover")))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["tooltip_activity_filter"], 0.8, 0.9, 1)
        GameTooltip:AddLine(L["tooltip_activity_filter_desc"], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    filterBtn:SetScript("OnLeave", function(self)
        UpdateFilterIconState()
        GameTooltip:Hide()
    end)
    filterBtn:SetScript("OnClick", function()
        if _G.ShowOptionsWindow then
            _G.ShowOptionsWindow()
            if _G.SwitchSettingsCategory then
                _G.SwitchSettingsCategory("activityfilter")
            end
        end
    end)
    LFG.filterBtn = filterBtn
    LFG.UpdateFilterIconState = UpdateFilterIconState
    self.lfgCountText = self.mainContainer:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.lfgCountText:SetPoint("TOP", self.title, "BOTTOM", 0, -4)
    self.lfgCountText:SetText(string.format(L["lfg_active_recruiters"], 0))
    self.lfgCountText:SetTextColor(unpack(_tc("textAccent")))

    self.modeFilterFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.modeFilterFrame:SetSize(IW, 26)
    self.modeFilterFrame:SetPoint("TOP", self.lfgCountText, "BOTTOM", 0, -4)
    local modeLabel = self.modeFilterFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    modeLabel:SetPoint("LEFT", self.modeFilterFrame, "LEFT", 10, 0)
    modeLabel:SetText(L["search_mode_label"] or "Mode:")
    modeLabel:SetTextColor(unpack(_tc("textNorm")))

    LFG.ModeFilter = "ALL"

    local MODE_OPTIONS = {
        { label = L["cat_all"] or "All", value = "ALL", color = { 0.40, 0.40, 0.45 } },
        { label = "LFG",                  value = "LFG", color = { 0.25, 0.55, 1.00 } },
        { label = "LFM",                  value = "LFM", color = { 1.00, 0.55, 0.10 } },
    }
    local function GetModeOptionIndex(value)
        for i, opt in ipairs(MODE_OPTIONS) do
            if opt.value == value then return i end
        end
        return 1
    end

    local modeBtnWidth, modeBtnHeight = 80, 22
    local modeBtn = FrostSeekUIUtils.CreateModernButton(
        self.modeFilterFrame, modeBtnWidth, modeBtnHeight,
        MODE_OPTIONS[1].label, MODE_OPTIONS[1].color
    )
    modeBtn:SetPoint("LEFT", modeLabel, "RIGHT", 8, 0)
    modeBtn:SetScript("OnClick", function()
        local curIdx = GetModeOptionIndex(LFG.ModeFilter)
        local nextIdx = (curIdx % #MODE_OPTIONS) + 1
        LFG.ModeFilter = MODE_OPTIONS[nextIdx].value
        LFG.UpdateModeFilterVisuals()
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    LFG.modeButton = modeBtn

    function LFG.UpdateModeFilterVisuals()
        local opt = MODE_OPTIONS[GetModeOptionIndex(LFG.ModeFilter)]
        if not opt then return end
        local c = opt.color
        if modeBtn.text then
            modeBtn.text:SetText(opt.label)
        end

        if modeBtn.bg then
            modeBtn.bg:SetColorTexture(c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 0.95)
        end
        if modeBtn.border then
            modeBtn.border:SetColorTexture(c[1], c[2], c[3], 1.0)
        end
        if modeBtn.text then
            modeBtn.text:SetTextColor(
                math.min(c[1] * 1.5 + 0.3, 1),
                math.min(c[2] * 1.5 + 0.3, 1),
                math.min(c[3] * 1.5 + 0.3, 1)
            )
        end

        modeBtn.color = c
        modeBtn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(c[1] * 0.65, c[2] * 0.65, c[3] * 0.65, 1.0)
            self.border:SetColorTexture(c[1], c[2], c[3], 1.0)
            self.text:SetTextColor(1, 1, 1)
        end)
        modeBtn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 0.95)
            self.border:SetColorTexture(c[1], c[2], c[3], 1.0)
            self.text:SetTextColor(
                math.min(c[1] * 1.5 + 0.3, 1),
                math.min(c[2] * 1.5 + 0.3, 1),
                math.min(c[3] * 1.5 + 0.3, 1)
            )
        end)
    end

    
    LFG.RoleFilter = "ALL"

    local ROLE_OPTIONS = {
        { label = L["role_all"]     or "All",     value = "ALL",     color = { 0.40, 0.40, 0.45 } },
        { label = L["role_tank"]    or "Tank",    value = "TANK",    color = { 0.25, 0.55, 1.00 } },
        { label = L["role_healer"]  or "Healer",  value = "HEALER",  color = { 0.20, 0.80, 0.40 } },
        { label = L["role_dps"]     or "DPS",     value = "DPS",     color = { 1.00, 0.30, 0.20 } },
        { label = L["role_support"] or "Support", value = "SUPPORT", color = { 0.65, 0.35, 1.00 } },
    }
    local function GetRoleOptionIndex(value)
        for i, opt in ipairs(ROLE_OPTIONS) do
            if opt.value == value then return i end
        end
        return 1
    end

    local roleLabel = self.modeFilterFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    roleLabel:SetPoint("LEFT", modeBtn, "RIGHT", 20, 0)
    roleLabel:SetText(L["filter_role_label"] or "Role:")
    roleLabel:SetTextColor(unpack(_tc("textNorm")))

    local roleBtnWidth, roleBtnHeight = 90, 22
    local roleBtn = FrostSeekUIUtils.CreateModernButton(
        self.modeFilterFrame, roleBtnWidth, roleBtnHeight,
        ROLE_OPTIONS[1].label, ROLE_OPTIONS[1].color
    )
    roleBtn:SetPoint("LEFT", roleLabel, "RIGHT", 8, 0)
    roleBtn:SetScript("OnClick", function()
        local curIdx = GetRoleOptionIndex(LFG.RoleFilter)
        local nextIdx = (curIdx % #ROLE_OPTIONS) + 1
        LFG.RoleFilter = ROLE_OPTIONS[nextIdx].value
        LFG.UpdateRoleFilterVisuals()
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    LFG.roleButton = roleBtn

    function LFG.UpdateRoleFilterVisuals()
        local opt = ROLE_OPTIONS[GetRoleOptionIndex(LFG.RoleFilter)]
        if not opt then return end
        local c = opt.color
        if roleBtn.text then
            roleBtn.text:SetText(opt.label)
        end
        if roleBtn.bg then
            roleBtn.bg:SetColorTexture(c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 0.95)
        end
        if roleBtn.border then
            roleBtn.border:SetColorTexture(c[1], c[2], c[3], 1.0)
        end
        if roleBtn.text then
            roleBtn.text:SetTextColor(
                math.min(c[1] * 1.5 + 0.3, 1),
                math.min(c[2] * 1.5 + 0.3, 1),
                math.min(c[3] * 1.5 + 0.3, 1)
            )
        end

        roleBtn.color = c
        roleBtn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(c[1] * 0.65, c[2] * 0.65, c[3] * 0.65, 1.0)
            self.border:SetColorTexture(c[1], c[2], c[3], 1.0)
            self.text:SetTextColor(1, 1, 1)
        end)
        roleBtn:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 0.95)
            self.border:SetColorTexture(c[1], c[2], c[3], 1.0)
            self.text:SetTextColor(
                math.min(c[1] * 1.5 + 0.3, 1),
                math.min(c[2] * 1.5 + 0.3, 1),
                math.min(c[3] * 1.5 + 0.3, 1)
            )
        end)
    end

    LFG.UpdateModeFilterVisuals()
    LFG.UpdateRoleFilterVisuals()

    LFG.modeDropdown = nil

    self.searchFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.searchFrame:SetSize(IW, 26)
    self.searchFrame:SetPoint("TOP", self.modeFilterFrame, "BOTTOM", 0, -4)
    local searchLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    searchLabel:SetPoint("LEFT", self.searchFrame, "LEFT", 10, 0)
    searchLabel:SetText(L["search"] .. ":")
    searchLabel:SetTextColor(unpack(_tc("textNorm")))
    self.lfgSearchBox = FrostSeekUIUtils.CreateModernEditBox(self.searchFrame, 300, 18)
    self.lfgSearchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    self.lfgSearchBox:SetText("")
    self.lfgSearchBox:SetScript("OnTextChanged", function(self)
        lfgSearchText = self:GetText()
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if lfgSearchDebounce and lfgSearchDebounce.Cancel then lfgSearchDebounce:Cancel() end
        lfgSearchDebounce = C_Timer.After(0.25, function()
            LFG.UpdateRecruitersList()
        end)
    end)
    local clearSearchBtn = FrostSeekUIUtils.CreateModernButton(self.searchFrame, 45, 18, L["clear"], _tc("border"))
    clearSearchBtn:SetPoint("LEFT", self.lfgSearchBox, "RIGHT", 5, 0)
    clearSearchBtn:SetScript("OnClick", function()
        self.lfgSearchBox:SetText("")
        lfgSearchText = ""
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if lfgSearchDebounce and lfgSearchDebounce.Cancel then lfgSearchDebounce:Cancel() end
        LFG.UpdateRecruitersList()
    end)

    self.diffFilterButtons = {}
    local allDiffLabels = {"All", "Normal", "Heroic", "HC", "Mythic", "Ascended", "Trial", "Leveling", "Farm", "ALVA"}
    for _, label in ipairs(allDiffLabels) do
        local btn = FrostSeekUIUtils.CreateModernButton(self.searchFrame, 55, 18, label, _tc("border"))
        btn:Hide()
        btn.label = label
        btn:SetScript("OnClick", function()
            if label == "All" then
                LFG.DifficultyFilter = nil
            else
                if LFG.DifficultyFilter == label then
                    LFG.DifficultyFilter = nil
                else
                    LFG.DifficultyFilter = label
                end
            end
            LFG.UpdateDiffFilterVisuals()
            LFG.UpdateRecruitersList()
        end)
        btn:SetScript("OnEnter", function(self)
            LFG.UpdateDiffFilterVisuals(label)
        end)
        btn:SetScript("OnLeave", function(self)
            LFG.UpdateDiffFilterVisuals()
        end)
        self.diffFilterButtons[label] = btn
    end

    self.keystoneMinLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.keystoneMinLabel:SetText(L["lfg_min_keystone"] or "Min Key:")
    self.keystoneMinLabel:SetTextColor(unpack(_tc("textMuted")))
    self.keystoneMinLabel:Hide()
    self.keystoneMinBox = FrostSeekUIUtils.CreateModernEditBox(self.searchFrame, 40, 18)
    self.keystoneMinBox:SetNumeric(true)
    self.keystoneMinBox:SetMaxLetters(3)
    self.keystoneMinBox:SetText(tostring(FrostSeekDB.LFG.keystoneMinLevel or 0))
    self.keystoneMinBox:Hide()
    self.keystoneMinBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 0
        if val < 0 then val = 0 end
        if val > 255 then val = 255 end
        FrostSeekDB.LFG.keystoneMinLevel = val
        self:SetText(tostring(val))
        self:ClearFocus()
        LFG.ApplyKeystoneMinLevelFilter()
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    self.keystoneMinBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(FrostSeekDB.LFG.keystoneMinLevel or 0))
        self:ClearFocus()
    end)
    self.keystoneMinBox:SetScript("OnEditFocusLost", function(self)
        local val = tonumber(self:GetText()) or 0
        if val < 0 then val = 0 end
        if val > 255 then val = 255 end
        FrostSeekDB.LFG.keystoneMinLevel = val
        self:SetText(tostring(val))
        LFG.ApplyKeystoneMinLevelFilter()
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    self.keystoneMinBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["lfg_min_keystone"] or "Min Key", 0.8, 0.9, 1)
        GameTooltip:AddLine(L["lfg_min_keystone_desc"] or "Mostra solo keystone di questo livello o superiore. 0 = disattivato.", 0.7, 0.85, 1, true)
        GameTooltip:Show()
    end)
    self.keystoneMinBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    function LFG.UpdateDiffFilterVisibility()
        local cat = LFG.CurrentCategory or "ALL"
        local filters = DIFFICULTY_FILTERS[cat]
        for _, btn in pairs(self.diffFilterButtons) do btn:Hide() end
        local lastAnchor = clearSearchBtn
        if filters then
            local anchor = clearSearchBtn
            local allBtn = self.diffFilterButtons["All"]
            if allBtn then
                allBtn:ClearAllPoints()
                allBtn:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
                allBtn:Show()
                anchor = allBtn
            end
            for _, f in ipairs(filters) do
                local btn = self.diffFilterButtons[f.label]
                if btn then
                    btn:ClearAllPoints()
                    btn:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
                    btn:Show()
                    anchor = btn
                end
            end
            lastAnchor = anchor
        end
        if cat == "KEYSTONE" and self.keystoneMinLabel and self.keystoneMinBox then
            self.keystoneMinLabel:ClearAllPoints()
            self.keystoneMinLabel:SetPoint("LEFT", lastAnchor, "RIGHT", 15, 0)
            self.keystoneMinLabel:Show()
            self.keystoneMinBox:ClearAllPoints()
            self.keystoneMinBox:SetPoint("LEFT", self.keystoneMinLabel, "RIGHT", 5, 0)
            self.keystoneMinBox:Show()
        else
            if self.keystoneMinLabel then self.keystoneMinLabel:Hide() end
            if self.keystoneMinBox then self.keystoneMinBox:Hide() end
        end
        LFG.UpdateDiffFilterVisuals()
    end

    function LFG.UpdateDiffFilterVisuals(hovered)
        local active = LFG.DifficultyFilter
        local cat = LFG.CurrentCategory or "ALL"
        local accent = CATEGORY_ACCENT[cat] or {0.5, 0.5, 0.5}
        for label, btn in pairs(self.diffFilterButtons) do
            if not btn.text then btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall") btn.text:SetPoint("CENTER") end
            local isHovered = (label == hovered)
            if label == "All" then
                if not active then
                    local m = isHovered and 0.75 or 0.55
                    if btn.bg then btn.bg:SetColorTexture(accent[1] * m, accent[2] * m, accent[3] * m, 0.95) end
                    if btn.border then btn.border:SetColorTexture(min(accent[1] * 1.3, 1), min(accent[2] * 1.3, 1), min(accent[3] * 1.3, 1), 1) end
                    if btn.text then btn.text:SetTextColor(1, 1, 1) end
                else
                    if btn.bg then
                        if isHovered then
                            btn.bg:SetColorTexture(accent[1] * 0.3, accent[2] * 0.3, accent[3] * 0.3, 0.7)
                        else
                            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
                        end
                    end
                    if btn.border then
                        if isHovered then
                            btn.border:SetColorTexture(accent[1] * 0.6, accent[2] * 0.6, accent[3] * 0.6, 0.9)
                        else
                            btn.border:SetColorTexture(unpack(_tc("border")))
                        end
                    end
                    if btn.text then btn.text:SetTextColor(isHovered and 1 or unpack(_tc("textMuted"))) end
                end
            elseif label == active then
                local m = isHovered and 1.0 or 0.85
                if btn.bg then btn.bg:SetColorTexture(accent[1] * m, accent[2] * m, accent[3] * m, m) end
                if btn.border then btn.border:SetColorTexture(min(accent[1] * 1.5, 1), min(accent[2] * 1.5, 1), min(accent[3] * 1.5, 1), 1) end
                if btn.text then btn.text:SetTextColor(1, 1, 1) end
            else
                if btn.bg then
                    if isHovered then
                        btn.bg:SetColorTexture(accent[1] * 0.25, accent[2] * 0.25, accent[3] * 0.25, 0.7)
                    else
                        btn.bg:SetColorTexture(unpack(_tc("bgButton")))
                    end
                end
                if btn.border then
                    if isHovered then
                        btn.border:SetColorTexture(accent[1] * 0.5, accent[2] * 0.5, accent[3] * 0.5, 0.85)
                    else
                        btn.border:SetColorTexture(unpack(_tc("border")))
                    end
                end
                if btn.text then btn.text:SetTextColor(isHovered and 1 or unpack(_tc("textMuted"))) end
            end
        end
    end
    self.recruitersFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.recruitersFrame:SetSize(IW, 360)
    self.recruitersFrame:SetPoint("TOP", self.searchFrame, "BOTTOM", 0, -8)
    local recruitersBg = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    recruitersBg:SetAllPoints()
    recruitersBg:SetColorTexture(unpack(_tc("bgRowOdd")))
    self.lfgTabs = {}
    local lfgTabTypes = {"ALL", "DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE"}
    local lfgTabNames = {"All", L["col_dungeon"], "Raid", "WBoss", "PvP", "Mana", "Key"}
    for i, tabName in ipairs(lfgTabNames) do
        local tab = CreateFrame("Button", nil, self.recruitersFrame)
        tab:SetSize(70, 22)
        tab:SetPoint("TOPLEFT", self.recruitersFrame, "TOPLEFT", 5 + ((i-1) * 75), -8)
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(unpack(_tc("bgTabInactive")))
        tab.text = tab:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabName)
        tab.text:SetTextColor(unpack(_tc("textPrimary")))
        tab:SetScript("OnClick", function()
            LFG.ChangeCategory(lfgTabTypes[i])
        end)
        tab:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        end)
        tab:SetScript("OnLeave", function(self)
            if lfgTabTypes[i] == LFG.CurrentCategory then
                self.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            else
                self.bg:SetColorTexture(unpack(_tc("bgTabInactive")))
            end
        end)
        self.lfgTabs[lfgTabTypes[i]] = tab
    end
    local headerFrame = CreateFrame("Frame", nil, self.recruitersFrame)
    headerFrame:SetSize(IW, 18)
    headerFrame:SetPoint("TOPRIGHT", self.recruitersFrame, "TOPRIGHT", -24, -40)
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 18, 0)
    nameHeader:SetWidth(80)
    nameHeader:SetJustifyH("LEFT")
    nameHeader:SetText(L["col_player"])
    nameHeader:SetTextColor(unpack(_tc("textAccent")))
    local timeHeader = headerFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    timeHeader:SetPoint("LEFT", headerFrame, "LEFT", 108, 0)
    timeHeader:SetWidth(40)
    timeHeader:SetJustifyH("LEFT")
    timeHeader:SetText(L["col_time"])
    timeHeader:SetTextColor(unpack(_tc("textAccent")))
    local catHeader = headerFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    catHeader:SetPoint("LEFT", headerFrame, "LEFT", 158, 0)
    catHeader:SetWidth(30)
    catHeader:SetJustifyH("LEFT")
    catHeader:SetText(L["col_type"])
    catHeader:SetTextColor(unpack(_tc("textAccent")))
    local roleHeader = headerFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    roleHeader:SetPoint("LEFT", headerFrame, "LEFT", 192, 0)
    roleHeader:SetWidth(70)
    roleHeader:SetJustifyH("LEFT")
    roleHeader:SetText(L["col_role"])
    roleHeader:SetTextColor(unpack(_tc("textAccent")))
    local dungeonHeaderBtn = CreateFrame("Button", nil, headerFrame)
    dungeonHeaderBtn:SetSize(92, 18)
    dungeonHeaderBtn:SetPoint("LEFT", headerFrame, "LEFT", 266, 0)
    local dungeonHeader = dungeonHeaderBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    dungeonHeader:SetPoint("LEFT", dungeonHeaderBtn, "LEFT", 0, 0)
    dungeonHeader:SetWidth(92)
    dungeonHeader:SetJustifyH("LEFT")
    dungeonHeader:SetText(L["col_dungeon"])
    dungeonHeader:SetTextColor(unpack(_tc("textAccent")))
    dungeonHeaderBtn:SetScript("OnClick", function()
        if LFG.CurrentCategory ~= "KEYSTONE" then return end
        if LFG.KeySortState == nil then
            LFG.KeySortState = "desc"
        elseif LFG.KeySortState == "desc" then
            LFG.KeySortState = "asc"
        else
            LFG.KeySortState = nil
        end
        LFG.UpdateKeySortHeader()
        if LFG.recruitersScrollFrame then
            LFG.recruitersScrollFrame:SetVerticalScroll(0)
        end
        LFG.UpdateRecruitersList()
    end)
    dungeonHeaderBtn:SetScript("OnEnter", function(self)
        if LFG.CurrentCategory == "KEYSTONE" then
            dungeonHeader:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["tooltip_sort_key_level"] or "Sort by keystone level", 0.8, 0.9, 1)
            GameTooltip:Show()
        end
    end)
    dungeonHeaderBtn:SetScript("OnLeave", function(self)
        dungeonHeader:SetTextColor(unpack(_tc("textAccent")))
        GameTooltip:Hide()
    end)
    LFG.keySortBtn = dungeonHeaderBtn
    LFG.keySortHeaderText = dungeonHeader
    LFG.KeySortState = nil
    local msgHeader = headerFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    msgHeader:SetPoint("LEFT", headerFrame, "LEFT", 350, 0)
    msgHeader:SetWidth(120)
    msgHeader:SetJustifyH("LEFT")
    msgHeader:SetText(L["col_message"])
    msgHeader:SetTextColor(unpack(_tc("textAccent")))
    local acceptHeader = headerFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    acceptHeader:SetPoint("RIGHT", headerFrame, "RIGHT", -8, 0)
    acceptHeader:SetWidth(60)
    acceptHeader:SetJustifyH("RIGHT")
    acceptHeader:SetText(L["col_action"])
    acceptHeader:SetTextColor(unpack(_tc("textAccent")))
    local separator = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    separator:SetPoint("TOP", headerFrame, "BOTTOM", 0, -2)
    separator:SetSize(IW, 1)
    separator:SetColorTexture(unpack(_tc("separator")))
    local LIST_HEIGHT = 260
    MAX_DISPLAY_ROWS = math.floor(LIST_HEIGHT / ROW_HEIGHT)
    self.recruitersList = CreateFrame("Frame", nil, self.recruitersFrame)
    self.recruitersList:SetSize(IW, LIST_HEIGHT)
    self.recruitersList:SetPoint("TOP", headerFrame, "BOTTOM", 0, -8)
    self.recruitersList:SetPoint("RIGHT", self.recruitersFrame, "RIGHT", -24, 0)

    self.recruitersScrollFrame = CreateFrame("ScrollFrame", "FrostSeekRecruitersScroll", self.recruitersFrame, "UIPanelScrollFrameTemplate")
    self.recruitersScrollFrame:SetPoint("TOPLEFT", self.recruitersList, "TOPLEFT", 0, 0)
    self.recruitersScrollFrame:SetPoint("BOTTOMRIGHT", self.recruitersList, "BOTTOMRIGHT", 0, 0)

    local scrollChild = CreateFrame("Frame", nil, self.recruitersScrollFrame)
    scrollChild:SetSize(IW, LIST_HEIGHT)
    self.recruitersScrollFrame:SetScrollChild(scrollChild)
    self.recruitersList.scrollChild = scrollChild

    self.recruitersList.rows = {}
    LFG.noRecruitersText = self.recruitersList:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    LFG.noRecruitersText:SetPoint("CENTER", self.recruitersList, "CENTER", 0, 0)
    LFG.noRecruitersText:SetText(L["lfg_no_recruiters"])
    LFG.noRecruitersText:SetTextColor(unpack(_tc("textDim")))
    LFG.noRecruitersText:Hide()
    LFG.InitRowPool(scrollChild)
    local scrollInfoFrame = CreateFrame("Frame", nil, self.recruitersFrame)
    scrollInfoFrame:SetPoint("TOPLEFT", self.recruitersList, "BOTTOMLEFT", 0, -4)
    scrollInfoFrame:SetPoint("BOTTOMRIGHT", self.recruitersList, "BOTTOMRIGHT", 20, -10)
    self.scrollIndicator = scrollInfoFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.scrollIndicator:SetPoint("CENTER", scrollInfoFrame, "CENTER", 0, 0)
    self.scrollIndicator:SetText("")
    self.scrollIndicator:SetTextColor(unpack(_tc("textDim")))
    self.controlsFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.controlsFrame:SetSize(IW, 30)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 5)
    self.refreshBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 70, 22, L["refresh"], _tc("primary"))
    self.refreshBtn:SetPoint("LEFT", self.controlsFrame, "LEFT", 10, -30)
    self.refreshBtn:SetScript("OnClick", function()
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    self.clearAllBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 70, 22, L["clear_all"], _tc("catPvP"))
    self.clearAllBtn:SetPoint("LEFT", self.refreshBtn, "RIGHT", 5, 0)
    self.clearAllBtn:SetScript("OnClick", function()
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog(L["clear_all"], L["msg_clear_all_confirm"], function()
                LFG.ClearAllSearches()
            end)
        else
            LFG.ClearAllSearches()
        end
    end)


    self.profileBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 80, 22, L["tab_profile"] or "Profile", _tc("accent"))
    self.profileBtn:SetPoint("RIGHT", self.controlsFrame, "RIGHT", -10, -30)
    self.profileBtn:SetScript("OnClick", function()
        if FrostSeek and FrostSeek.Tabs and FrostSeek.Tabs.listings and FrostSeek.Tabs.listings.module then
            FrostSeek:SwitchTab("listings")
            if FrostSeek.Listings then
                FrostSeek.Listings.subTab = "profile"
                FrostSeek.Listings:RefreshSubTabs()
                FrostSeek.Listings:RefreshContent()
            end
        end
    end)
    self.profileBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["tab_profile"] or "Profile", 1, 1, 1)
        GameTooltip:AddLine(L["options_open_profile_desc"] or "Apri il tuo profilo FrostSeek", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    self.profileBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.wispBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 80, 22, L["options_custom_whisper"] or "Custom Wisp", _tc("accent"))
    self.wispBtn:SetPoint("RIGHT", self.profileBtn, "LEFT", -8, 0)
    self.wispBtn:SetScript("OnClick", function()
        if _G.ShowOptionsWindow then
            _G.ShowOptionsWindow()
            if _G.SwitchSettingsCategory then
                _G.SwitchSettingsCategory("custommessage")
            end
        end
    end)
    self.wispBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["options_custom_whisper"] or "Custom Wisp", 1, 1, 1)
        GameTooltip:AddLine(L["options_custom_whisper_desc"] or "Personalizza il messaggio inviato quando accetti in LFG", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    self.wispBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    LFG.CurrentCategory = "ALL"
    LFG.ChangeCategory("ALL")
    LFG.UpdatePlayerInfo()
    LFG.UpdateRecruitersList()
    self.frame:Hide()
end

function LFG:Show()
    if not self.frame then return end
    LFG.UpdatePlayerInfo()
    LFG.UpdateRecruitersList()
    self.frame:Show()
end

function LFG:Hide()
    CloseAllDropdowns()
    if self.frame then self.frame:Hide() end
end

function LFG:RefreshData()
    LFG.UpdateRecruitersList()
end

function LFG:GetActiveRecruiterCount()
    return activeSearches and #activeSearches or 0
end

local _origInit = LFG.Initialize
if _origInit then
    LFG.Initialize = function(self, parentFrame)
        local r1, r2 = _origInit(self, parentFrame)
        C_Timer.After(5, function()
            LFG.PromptForRoleIfMissing()
        end)
        return r1, r2
    end
end
