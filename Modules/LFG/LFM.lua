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
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfm_logic", LFM)

local L = FrostSeek.L
local _tc = _G.FrostSeekShared and _G.FrostSeekShared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = _G.FrostSeekShared and _G.FrostSeekShared._hex or function(t) return "|cFF888888" end

local S = LFM._S

local LFM_ACTIVITIES = LFM.LFM_ACTIVITIES
local DIFFICULTIES = LFM.DIFFICULTIES
local CHANNELS = LFM.CHANNELS
local RAID_ROLE_REQUIREMENTS = LFM.RAID_ROLE_REQUIREMENTS

local currentKeystone = nil
local autoSpamTicker = nil
local recentInvites = {}

LFM._logic = nil

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
            if itemLink then
                local itemName
                if FrostSeekCompat and FrostSeekCompat.GetItemInfo then
                    local info = FrostSeekCompat.GetItemInfo(itemLink)
                    if info then itemName = info end
                else
                    itemName = GetItemInfo(itemLink)
                end
                if itemName and string.find(itemName, "Keystone") then
                    return itemLink, itemName, bag, slot
                end
            end
        end
    end
    return nil, nil, nil, nil
end

local function GetKeystoneInfo(itemLink)
    if not itemLink then return nil end
    local itemName = GetItemInfo(itemLink)
    if not itemName then return nil end
    return { link = itemLink, name = itemName }
end

local function UpdateKeystoneList()
    if not LFM_ACTIVITIES.KEYSTONE then
        LFM_ACTIVITIES.KEYSTONE = {}
    else
        wipe(LFM_ACTIVITIES.KEYSTONE)
    end

    local keystoneLink, keystoneName = FindKeystoneInBags()

    if keystoneLink then
        local keystoneInfo = GetKeystoneInfo(keystoneLink)
        if keystoneInfo then
            table.insert(LFM_ACTIVITIES.KEYSTONE, {
                name = keystoneInfo.name,
                template = "LFM {keystone} {roles}",
                keywords = {"keystone", "mythic", "mythic+"},
                keystoneLink = keystoneLink,
                keystoneInfo = keystoneInfo,
            })
            currentKeystone = keystoneInfo
        else
            currentKeystone = nil
        end
    else
        currentKeystone = nil
    end

    if S.currentCategory == "KEYSTONE" then
        if #LFM_ACTIVITIES.KEYSTONE > 0 then
            local activity = LFM_ACTIVITIES.KEYSTONE[1]
            LFM.UpdateMessagePreview(activity.template, activity)
        else
            LFM.UpdateMessagePreview()
        end
    end

    return currentKeystone ~= nil
end

local function StartKeystoneAutoUpdate()
    if S.keystoneUpdateTicker then
        S.keystoneUpdateTicker:Cancel()
        S.keystoneUpdateTicker = nil
    end

    local interval = FrostSeekDB.LFM.autoUpdateInterval or 60
    if interval <= 0 then return end

    S.keystoneUpdateTicker = C_Timer.NewTicker(interval, function()
        UpdateKeystoneList()
        if S.currentCategory ~= "KEYSTONE" then
            if S.keystoneUpdateTicker then
                S.keystoneUpdateTicker:Cancel()
                S.keystoneUpdateTicker = nil
            end
        end
    end)
end

local function StopKeystoneAutoUpdate()
    if S.keystoneUpdateTicker then
        S.keystoneUpdateTicker:Cancel()
        S.keystoneUpdateTicker = nil
    end
end

local function GenerateRolesText()
    local roles = {}
    if S.selectedRoles.Tank then
        local n = S.needCount.Tank or 1
        table.insert(roles, n > 1 and (n .. " Tank") or "Tank")
    end
    if S.selectedRoles.Healer then
        local n = S.needCount.Healer or 1
        table.insert(roles, n > 1 and (n .. " Healer") or "Healer")
    end
    if S.selectedRoles.DPS then
        local n = S.needCount.DPS or 1
        table.insert(roles, n > 1 and (n .. " DPS") or "DPS")
    end
    if S.selectedRoles.Support then
        local n = S.needCount.Support or 1
        table.insert(roles, n > 1 and (n .. " Support") or "Support")
    end
    if S.selectedRoles.BC then table.insert(roles, "BC") end
    if #roles == 0 then return "All Roles" end
    return table.concat(roles, " ")
end

local function ProcessTemplate(template, activity)
    local processed = template:gsub("{roles}", GenerateRolesText())
    processed = processed:gsub("{difficulty}", S.selectedDifficulty)
    if activity and activity.keystoneLink then
        processed = processed:gsub("{keystone}", activity.keystoneLink)
    end
    return processed
end

local function FilterActivities(activities)
    local filtered = {}
    local Shared = _G.FrostSeekShared
    local profile = Shared and Shared.GetServerProfile and Shared.GetServerProfile() or "wotlk"
    local expLevel = Shared and Shared.GetServerProfileExpansionLevel and Shared.GetServerProfileExpansionLevel() or 2

    local playerLevel = UnitLevel("player") or 80
    local levelExpLevel = playerLevel
    if profile == "ascension" or profile == "epoch" then
        if playerLevel <= 60 then levelExpLevel = 0
        elseif playerLevel <= 70 then levelExpLevel = 1
        else levelExpLevel = 2 end
    else
        if playerLevel <= 60 then levelExpLevel = 0
        elseif playerLevel <= 70 then levelExpLevel = 1
        elseif playerLevel <= 80 then levelExpLevel = 2
        elseif playerLevel <= 85 then levelExpLevel = 3
        else levelExpLevel = 4 end
    end

    local effectiveExpLevel = math.min(expLevel, levelExpLevel)

    for _, activity in ipairs(activities) do
        local activityExp = activity.exp
        if activityExp == nil then
            table.insert(filtered, activity)
        elseif activityExp == 97 then
            if profile == "ascension" then
                table.insert(filtered, activity)
            end
        elseif activityExp == 98 then
            if profile == "epoch" then
                table.insert(filtered, activity)
            end
        elseif activityExp == 99 then
            if profile == "ascension" or profile == "epoch" then
                table.insert(filtered, activity)
            end
        elseif activityExp <= effectiveExpLevel then
            if S.searchText and S.searchText ~= "" then
                local nameLower = string.lower(activity.name)
                local searchLower = string.lower(S.searchText)
                if string.find(nameLower, searchLower, 1, true) then
                    table.insert(filtered, activity)
                else
                    for _, keyword in ipairs(activity.keywords) do
                        if string.find(string.lower(keyword), searchLower, 1, true) then
                            table.insert(filtered, activity)
                            break
                        end
                    end
                end
            else
                table.insert(filtered, activity)
            end
        end
    end
    return filtered
end

local function DetectRolesFromMessage(msg)
    local msgLower = string.lower(msg)
    local found = {}

    if string.find(msgLower, "tank") then
        table.insert(found, "Tank")
    end

    if string.find(msgLower, "heal") then
        table.insert(found, "Healer")
    end

    if string.find(msgLower, "dps") or string.find(msgLower, " dd") or string.find(msgLower, "^dd") then
        table.insert(found, "DPS")
    end

    if string.find(msgLower, "support") or string.find(msgLower, " supp") or string.find(msgLower, "^supp") then
        table.insert(found, "Support")
    end

    if string.find(msgLower, "bc") then
        table.insert(found, "BC")
    end

    if #found == 0 then
        return nil
    end

    return table.concat(found, "/")
end

local function ValidateGroupComposition()
    local reqs = RAID_ROLE_REQUIREMENTS[S.currentCategory]
    if not reqs then return nil end

    local warnings = {}
    local ROLE_COLORS = Shared and Shared.ROLE_COLORS or { Tank = {0.3, 0.5, 0.85}, Healer = {0.2, 0.8, 0.3}, DPS = {0.85, 0.3, 0.2}, Support = {0.7, 0.4, 1.0} }

    for role, recommended in pairs(reqs) do
        if recommended == 0 then
        elseif not S.selectedRoles[role] then
            local c = ROLE_COLORS[role] or {1, 1, 1}
            local hex = string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
            table.insert(warnings, hex .. role .. "|r")
        elseif (S.needCount[role] or 1) < recommended then
            local c = ROLE_COLORS[role] or {1, 1, 1}
            local hex = string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
            table.insert(warnings, hex .. role .. " (only " .. (S.needCount[role] or 1) .. ", recommended " .. recommended .. ")" .. "|r")
        end
    end

    if #warnings > 0 then
        return "Consider adding: " .. table.concat(warnings, ", ")
    end
    return nil
end

local LFM_ADDON_CHANNEL_BLACKLIST = {
    ["FSK"]          = true,
    [" FSK"]         = true,
    ["FrostSeek"]    = true,
    ["FrostNet"]     = true,
    ["BLFG"]         = true,
    ["BBLC25C"]      = true,
    ["HGE"]          = true,
    ["FSK-EVT"]      = true,
}

local function IsLFMAddonChannel(channelName)
    if not channelName or channelName == "" then return false end
    local trimmed = string.match(channelName, "^%s*(.-)%s*$") or channelName
    if trimmed == "" then return false end
    local key = string.upper(trimmed)
    if LFM_ADDON_CHANNEL_BLACKLIST[key] then return true end
    if LFM_ADDON_CHANNEL_BLACKLIST[" " .. key] then return true end
    return false
end

local function SendLFMMessage(message, channel)
    if not message or message == "" then return false end

    if S.currentCategory == "KEYSTONE" and not FindKeystoneInBags() then
        print(L["msg_no_keystone_found"])
        return false
    end

    local success = true
    if string.match(channel, "CHANNEL%d+") then
        local channelNum = tonumber(string.match(channel, "CHANNEL(%d+)"))
        if channelNum then
            local realId = nil
            local chName = nil

            local ok, id, name = pcall(function()
                return GetChannelName(channelNum)
            end)
            if ok then
                if type(id) == "number" and id > 0 then
                    realId = id
                    chName = name
                end
            end

            if realId and chName and tostring(chName) ~= "" then
                if IsLFMAddonChannel(tostring(chName)) then
                    print(L["msg_skipped_addon_channel"] .. " '" .. tostring(chName) .. L["msg_slot_inline"] .. channelNum .. ")")
                    success = false
                else
                    local ok2, err = pcall(function()
                        SendChatMessage(message, "CHANNEL", nil, realId)
                    end)
                    if not ok2 then
                        print(L["msg_failed_send_channel"] .. tostring(chName) .. ": " .. tostring(err))
                        success = false
                    end
                end
            else
                print(L["msg_channel_slot"] .. channelNum .. L["msg_channel_not_found_hint"])
                success = false
            end
        end
    else
        local ok, err = pcall(function()
            SendChatMessage(message, channel)
        end)
        if not ok then
            print(L["msg_failed_send_on"] .. tostring(channel) .. ": " .. tostring(err))
            success = false
        end
    end

    if success then
        table.insert(FrostSeekDB.LFM.lastMessages, 1, {
            message = message,
            channel = channel,
            timestamp = time()
        })
        while #FrostSeekDB.LFM.lastMessages > 10 do
            table.remove(FrostSeekDB.LFM.lastMessages)
        end
    end

    return success
end

local function SendToAllSpamChannels(message)
    local sentCount = 0
    for i = 1, 10 do
        if S.spamChannels[i] then
            local channelKey = "CHANNEL" .. i
            local success = SendLFMMessage(message, channelKey)
            if success then sentCount = sentCount + 1 end
        end
    end
    return sentCount
end

local function DoAutoSpamTick()
    if not S.autoSpamActive then return end
    local message = S.customMessage or ""
    if message == "" then
        print(L["msg_no_message_set"])
        LFM:StopAutoSpam()
        return
    end

    local threshold = FrostSeekDB and FrostSeekDB.LFM and FrostSeekDB.LFM.autoStopMemberCount or 0
    if threshold and threshold > 0 then
        local members = 1
        local raid = GetNumRaidMembers and GetNumRaidMembers() or 0
        if raid and raid > 0 then
            members = raid
        else
            local party = GetNumPartyMembers and GetNumPartyMembers() or 0
            members = party + 1
        end
        if members >= threshold then
            print(L["msg_group_reached"] .. members .. "/" .. threshold .. L["msg_members_autostop_suffix"])
            LFM:StopAutoSpam()
            return
        end
    end

    local sent = SendToAllSpamChannels(message)
    if sent > 0 then
        print(L["msg_sent_to"] .. sent .. L["msg_channel_count_suffix"])
    else
        print(L["msg_no_channels_selected"])
    end
end
--mimi
function LFM:StartAutoSpam()
    local message = S.customMessage or ""
    if message == "" then
        print(L["msg_cannot_start_no_msg"])
        return
    end

    local hasChannel = false
    for i = 1, 10 do
        if S.spamChannels[i] then hasChannel = true; break end
    end
    if not hasChannel then
        print(L["msg_cannot_start_no_ch"])
        return
    end

    local interval = tonumber(LFM.spamTimerBox:GetText()) or 0
    if interval <= 0 then
        interval = (FrostSeekDB and FrostSeekDB.LFM and FrostSeekDB.LFM.autoSpamInterval) or 30
    end
    if interval < 15 then interval = 15 end
    LFM.spamTimerBox:SetText(tostring(interval))
    if FrostSeekDB and FrostSeekDB.LFM then
        FrostSeekDB.LFM.autoSpamInterval = interval
    end

    if Shared and Shared.ConfirmDialog then
        Shared.ConfirmDialog(
            L["txt_start_auto_spam"],
            L["msg_confirm_spam_prefix"] .. string.sub(message, 1, 60) .. (string.len(message) > 60 and "..." or "") .. L["msg_confirm_spam_every"] .. interval .. L["msg_confirm_spam_on"] .. table.concat((function()
                local chs = {}
                for i = 1, 10 do
                    if S.spamChannels[i] then
                        local ok, id, name = pcall(function() return GetChannelName(i) end)
                        if ok and type(id) == "number" and id > 0 and name then
                            table.insert(chs, tostring(name))
                        end
                    end
                end
                return chs
            end)(), ", ") .. L["msg_confirm_spam_continue"],
            function()
                if autoSpamTicker then
                    autoSpamTicker:Cancel()
                    autoSpamTicker = nil
                end
                S.autoSpamActive = true
                DoAutoSpamTick()
                autoSpamTicker = C_Timer.NewTicker(interval, DoAutoSpamTick)
                LFM.spamBtn.text:SetText(L["lfm_stop_spam"])
                local dangerC = _tc("danger")
                LFM.spamBtn.color = dangerC
                LFM.spamBtn.text:SetTextColor(min(dangerC[1] * 1.4, 1), min(dangerC[2] * 1.4, 1), min(dangerC[3] * 1.4, 1))
                LFM.spamBtn.bg:SetColorTexture(dangerC[1] * 0.25, dangerC[2] * 0.25, dangerC[3] * 0.25, 0.8)
                LFM.spamBtn.border:SetColorTexture(dangerC[1] * 0.5, dangerC[2] * 0.5, dangerC[3] * 0.5, 0.7)
                LFM.spamBtn.accent:SetColorTexture(dangerC[1], dangerC[2], dangerC[3], 0.4)
                LFM.spamStatusText:SetText(string.format(L["msg_spamming_every"], interval))
                LFM.spamStatusText:Show()
                print(L["msg_auto_spam_started"] .. interval .. "s)")
            end
        )
    else
        if autoSpamTicker then
            autoSpamTicker:Cancel()
            autoSpamTicker = nil
        end
        S.autoSpamActive = true
        DoAutoSpamTick()
        autoSpamTicker = C_Timer.NewTicker(interval, DoAutoSpamTick)
        LFM.spamBtn.text:SetText(L["lfm_stop_spam"])
        local dangerC = _tc("danger")
        LFM.spamBtn.color = dangerC
        LFM.spamBtn.text:SetTextColor(min(dangerC[1] * 1.4, 1), min(dangerC[2] * 1.4, 1), min(dangerC[3] * 1.4, 1))
        LFM.spamBtn.bg:SetColorTexture(dangerC[1] * 0.25, dangerC[2] * 0.25, dangerC[3] * 0.25, 0.8)
        LFM.spamBtn.border:SetColorTexture(dangerC[1] * 0.5, dangerC[2] * 0.5, dangerC[3] * 0.5, 0.7)
        LFM.spamBtn.accent:SetColorTexture(dangerC[1], dangerC[2], dangerC[3], 0.4)
        LFM.spamStatusText:SetText(string.format(L["msg_spamming_every"], interval))
        LFM.spamStatusText:Show()
        print(L["msg_auto_spam_started"] .. interval .. "s)")
    end
end

function LFM:StopAutoSpam()
    S.autoSpamActive = false
    if autoSpamTicker then
        autoSpamTicker:Cancel()
        autoSpamTicker = nil
    end

    if LFM.spamBtn then
        LFM.spamBtn.text:SetText(L["lfm_start_spam"])
        local successC = _tc("success")
        LFM.spamBtn.color = successC
        LFM.spamBtn.text:SetTextColor(min(successC[1] * 1.4, 1), min(successC[2] * 1.4, 1), min(successC[3] * 1.4, 1))
        LFM.spamBtn.bg:SetColorTexture(successC[1] * 0.25, successC[2] * 0.25, successC[3] * 0.25, 0.8)
        LFM.spamBtn.border:SetColorTexture(successC[1] * 0.5, successC[2] * 0.5, successC[3] * 0.5, 0.7)
        LFM.spamBtn.accent:SetColorTexture(successC[1], successC[2], successC[3], 0.4)
    end
    if LFM.spamStatusText then
        LFM.spamStatusText:Hide()
    end

    print(L["msg_auto_spam_stopped"])
end

local whisperHandler = CreateFrame("Frame")
whisperHandler:RegisterEvent("CHAT_MSG_WHISPER")
whisperHandler:SetScript("OnEvent", function(self, event, msg, sender, ...)
    -- AYRO
    if not (S.autoInviteEnabled or (FrostSeekDB and FrostSeekDB.LFM and FrostSeekDB.LFM.autoInviteEnabled)) then return end

    local senderName = (Ambiguate and Ambiguate(sender, "none")) or sender
    if not senderName then return end

    if UnitName("player") == senderName then return end
    -- noah
    local groupCount = 0
    if GetNumGroupMembers then
        groupCount = GetNumGroupMembers() or 0
    elseif GetNumRaidMembers and IsInRaid and IsInRaid() then
        groupCount = GetNumRaidMembers() or 0
    elseif GetNumPartyMembers then
        groupCount = (GetNumPartyMembers() or 0) + 1
    end
    if groupCount >= 5 then
        if not (IsInRaid and IsInRaid()) then return end
    end

    local now = time()
    if recentInvites[senderName] and (now - recentInvites[senderName]) < 120 then
        return
    end

    local detectedRole = DetectRolesFromMessage(msg)

    local ilvl = nil

    local patterns = {
        "[Ii][Ll][Vv][Ll]%s*(%d+)",
        "[Ll][Vv][Ll]%s*(%d+)",
        "(%d+)%s*[Ii][Ll][Vv][Ll]",
        "(%d+)%s*[Ll][Vv][Ll]",
        "(%d+)%+",
    }

    for _, pattern in ipairs(patterns) do
        local match = string.match(msg, pattern)
        if match then
            local num = tonumber(match)
            if num and num >= 1 and num <= 1000 then
                ilvl = num
                break
            end
        end
    end

    local needRole = false
    local neededRolesList = {}
    if S.selectedRoles.Tank then needRole = true; table.insert(neededRolesList, "Tank") end
    if S.selectedRoles.Healer then needRole = true; table.insert(neededRolesList, "Healer") end
    if S.selectedRoles.DPS then needRole = true; table.insert(neededRolesList, "DPS") end
    if S.selectedRoles.Support then needRole = true; table.insert(neededRolesList, "Support") end
    local neededRolesStr = table.concat(neededRolesList, "/")

    local roleMatch = true
    if needRole then
        if detectedRole then
            roleMatch = false
            for _, role in ipairs(neededRolesList) do
                if string.find(detectedRole, role) then
                    roleMatch = true
                    break
                end
            end
        else
            roleMatch = false
        end
    end

    local playerLevel = UnitLevel(senderName) or 0
    local levelOk = (playerLevel <= 0) or (playerLevel >= S.autoInviteMinLevel)
    local ilvlOk = (not ilvl and S.autoInviteMinIlvl <= 0) or (ilvl and ilvl >= S.autoInviteMinIlvl)

    if ilvlOk and roleMatch and levelOk then
        InviteUnit(senderName)
        recentInvites[senderName] = now

        local roleInfo = ""
        if detectedRole then
            roleInfo = L["txt_role_inline"] .. detectedRole .. " |"
        end
        -- vinny
        print(L["msg_auto_invite_invited"] .. senderName .. L["txt_ilvl_inline"] .. tostring(ilvl) .. L["txt_lvl_inline"] .. tostring(playerLevel) .. roleInfo .. ")")

        C_Timer.After(1, function()
            local replyMsg = L["msg_auto_invite_welcome"]
            if detectedRole then
                replyMsg = replyMsg .. " (" .. detectedRole .. ")"
            end
            pcall(function() SendChatMessage(replyMsg, "WHISPER", nil, senderName) end)
        end)
    elseif ilvlOk and not levelOk then
        print(L["msg_auto_invite_rejected"] .. senderName .. L["msg_reject_level_low"] .. S.autoInviteMinLevel .. L["msg_reject_got_suffix"] .. playerLevel .. ")")
        C_Timer.After(1, function()
            pcall(function() SendChatMessage(L["msg_invite_reject_min_level"] .. S.autoInviteMinLevel .. L["msg_invite_reject_you_are_level"] .. playerLevel .. ".", "WHISPER", nil, senderName) end)
        end)
    elseif ilvlOk and not roleMatch then
        print(L["msg_auto_invite_rejected"] .. senderName .. L["msg_reject_role_mismatch"] .. neededRolesStr .. L["msg_reject_got_suffix"] .. (detectedRole or L["none"]) .. ")")

        C_Timer.After(1, function()
            if not detectedRole then
                pcall(function() SendChatMessage(L["msg_invite_reject_we_need"] .. neededRolesStr .. L["msg_invite_reject_include_role"], "WHISPER", nil, senderName) end)
            else
                pcall(function() SendChatMessage(L["msg_invite_reject_we_need"] .. neededRolesStr .. L["msg_invite_reject_you_stated"] .. detectedRole .. ".", "WHISPER", nil, senderName) end)
            end
        end)
    end
end)

local recentInvitesTicker = C_Timer.NewTicker(120, function()
    local now = time()
    for name, timestamp in pairs(recentInvites) do
        if (now - timestamp) >= 120 then
            recentInvites[name] = nil
        end
    end
end)

local function InitializeLFMSystem()
    FrostSeekDB.LFM = FrostSeekDB.LFM or {
        lastMessages = {},
        favoriteTemplates = {},
        channelPresets = {},
        autoUpdateInterval = 60,
        autoSpamInterval = 30,
        spamChannels = {},
        autoInviteEnabled = false,
        autoInviteMinIlvl = 150,
        autoInviteMinLevel = 60,
    }

    if not FrostSeekDB.LFM.spamChannels then
        FrostSeekDB.LFM.spamChannels = {}
    end
    if FrostSeekDB.LFM.autoInviteMinIlvl == nil then
        FrostSeekDB.LFM.autoInviteMinIlvl = 150
    end
    if FrostSeekDB.LFM.autoInviteMinLevel == nil then
        FrostSeekDB.LFM.autoInviteMinLevel = 60
    end

    if not LFM_ACTIVITIES.KEYSTONE then
        LFM_ACTIVITIES.KEYSTONE = {}
    end
end

function LFM:ApplyTheme()
    if LFM.UpdateTabsAppearance then LFM.UpdateTabsAppearance() end
    if LFM.UpdateActivityList then LFM.UpdateActivityList() end
    if LFM.UpdateDifficultyDropdown then LFM.UpdateDifficultyDropdown() end
    if LFM.spamBtn and not S.autoSpamActive then
        local successC = _tc("success")
        LFM.spamBtn.color = successC
        LFM.spamBtn.text:SetTextColor(min(successC[1] * 1.2, 1), min(successC[2] * 1.2, 1), min(successC[3] * 1.2, 1))
        LFM.spamBtn.bg:SetColorTexture(successC[1] * 0.25, successC[2] * 0.25, successC[3] * 0.25, 0.8)
        LFM.spamBtn.border:SetColorTexture(successC[1] * 0.5, successC[2] * 0.5, successC[3] * 0.5, 0.7)
        LFM.spamBtn.accent:SetColorTexture(successC[1], successC[2], successC[3], 0.4)
    end

    if LFM.sendAllBtn then
        local warnC = _tc("warning")
        LFM.sendAllBtn.color = warnC
        LFM.sendAllBtn.text:SetTextColor(min(warnC[1] * 1.2, 1), min(warnC[2] * 1.2, 1), min(warnC[3] * 1.2, 1))
        LFM.sendAllBtn.bg:SetColorTexture(warnC[1] * 0.25, warnC[2] * 0.25, warnC[3] * 0.25, 0.8)
        LFM.sendAllBtn.border:SetColorTexture(warnC[1] * 0.5, warnC[2] * 0.5, warnC[3] * 0.5, 0.7)
        LFM.sendAllBtn.accent:SetColorTexture(warnC[1], warnC[2], warnC[3], 0.4)
    end

    if LFM.clearSearchBtn then
        local borderC = _tc("border")
        LFM.clearSearchBtn.color = borderC
        LFM.clearSearchBtn.text:SetTextColor(min(borderC[1] * 1.2, 1), min(borderC[2] * 1.2, 1), min(borderC[3] * 1.2, 1))
        LFM.clearSearchBtn.bg:SetColorTexture(borderC[1] * 0.25, borderC[2] * 0.25, borderC[3] * 0.25, 0.8)
        LFM.clearSearchBtn.border:SetColorTexture(borderC[1] * 0.5, borderC[2] * 0.5, borderC[3] * 0.5, 0.7)
        LFM.clearSearchBtn.accent:SetColorTexture(borderC[1], borderC[2], borderC[3], 0.4)
    end
end

if not _G.FrostSeek then return end
if not _G.FrostSeek._v or not _G.FrostSeek._v.c(_tk) then return end

InitializeLFMSystem()

if _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("lfm", LFM)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("lfm")
end

LFM._logic = {
    FilterActivities = FilterActivities,
    ProcessTemplate = ProcessTemplate,
    SendLFMMessage = SendLFMMessage,
    SendToAllSpamChannels = SendToAllSpamChannels,
    StartKeystoneAutoUpdate = StartKeystoneAutoUpdate,
    StopKeystoneAutoUpdate = StopKeystoneAutoUpdate,
    UpdateKeystoneList = UpdateKeystoneList,
    ValidateGroupComposition = ValidateGroupComposition,
    DetectRolesFromMessage = DetectRolesFromMessage,
    GenerateRolesText = GenerateRolesText,
}
