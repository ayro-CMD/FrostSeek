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


local MAJOR, MINOR = "FrostSeekCompat", 2
if LibStub and LibStub:GetLibrary(MAJOR, true) then return end

if not C_Timer then
    C_Timer = {}

    local timerFrame = CreateFrame("Frame", "FrostSeek_TimerFrame")
    timerFrame:SetScript("OnUpdate", nil)
    local activeTimers = {}

    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        local i = 1
        while i <= #activeTimers do
            local timer = activeTimers[i]
            if not timer then
                table.remove(activeTimers, i)
            elseif timer.finished then
                table.remove(activeTimers, i)
            elseif timer.cancelled then
                table.remove(activeTimers, i)
            else
                if now >= timer.expiry then
                    timer.finished = true
                    table.remove(activeTimers, i)
                    if timer.callback then
                        timer.callback()
                    end
                else
                    i = i + 1
                end
            end
        end

        if #activeTimers == 0 then
            self:SetScript("OnUpdate", nil)
        end
    end)

    local function ensureTickerFrame()
        if not timerFrame:GetScript("OnUpdate") then
            local existingHandler = timerFrame:GetScript("OnUpdate")
            if not existingHandler then
                timerFrame:SetScript("OnUpdate", function(self, elapsed)
                    local now = GetTime()
                    local i = 1
                    while i <= #activeTimers do
                        local timer = activeTimers[i]
                        if not timer or timer.finished or timer.cancelled then
                            table.remove(activeTimers, i)
                        elseif now >= timer.expiry then
                            timer.finished = true
                            table.remove(activeTimers, i)
                            if timer.callback then timer.callback() end
                        else
                            i = i + 1
                        end
                    end
                    if #activeTimers == 0 then
                        self:SetScript("OnUpdate", nil)
                    end
                end)
            end
        end
    end

    function C_Timer.After(delay, callback)
        local timer = {
            expiry = GetTime() + (delay or 0),
            callback = callback,
            type = "after"
        }
        table.insert(activeTimers, timer)
        ensureTickerFrame()
        return timer
    end

    function C_Timer.NewTicker(interval, callback, iterations)
        local timer = {
            interval = interval or 1,
            callback = callback,
            iterations = iterations,
            elapsed = 0,
            type = "ticker",
            cancelled = false
        }

        local tickerFrame = CreateFrame("Frame")
        tickerFrame:Hide()

        tickerFrame:SetScript("OnUpdate", function(self, elapsed)
            if timer.cancelled then
                self:Hide()
                return
            end

            timer.elapsed = timer.elapsed + elapsed
            if timer.elapsed >= timer.interval then
                timer.elapsed = timer.elapsed - timer.interval

                if timer.callback then
                    timer.callback()
                end

                if timer.iterations then
                    timer.iterations = timer.iterations - 1
                    if timer.iterations <= 0 then
                        timer.cancelled = true
                        self:Hide()
                    end
                end
            end
        end)

        tickerFrame:Show()

        return {
            Cancel = function()
                timer.cancelled = true
                tickerFrame:Hide()
            end,
            _timer = timer,
            _frame = tickerFrame
        }
    end
end

local textureMt = getmetatable(CreateFrame("Frame"):CreateTexture())
if textureMt and not textureMt.__index.SetColorTexture then
    textureMt.__index.SetColorTexture = function(self, r, g, b, a)
        self:SetTexture(r, g, b)
        if a then self:SetAlpha(a) end
    end
end

local frameMt = getmetatable(CreateFrame("Frame"))
if frameMt and not frameMt.__index.SetShown then
    frameMt.__index.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end

local testFrame = CreateFrame("Frame")
local testTex = testFrame:CreateTexture()
local textureMt2 = getmetatable(testTex)
if textureMt2 and not textureMt2.__index.SetShown then
    textureMt2.__index.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end
testFrame = nil
testTex = nil

FrostSeekCompat = FrostSeekCompat or {}

FrostSeekCompat.WOW_VERSIONS = {
    wotlk335       = "WOTLK_335",
    VANILLA        = "vanilla",
    TBC            = "tbc",
    WOTLK_CLASSIC  = "wotlk_classic",
    CATA           = "cata",
    CATA_PS        = "cata_ps",
    MISTS          = "mists",
    UNKNOWN        = "unknown",
}

do
    local detectedVersion = FrostSeekCompat.WOW_VERSIONS.UNKNOWN
    local buildVersion = 0
    local interfaceVersion = select(4, GetBuildInfo()) or 0

    if interfaceVersion >= 110000 then
        detectedVersion = FrostSeekCompat.WOW_VERSIONS.UNKNOWN
    elseif interfaceVersion >= 50000 and interfaceVersion < 60000 then
        detectedVersion = FrostSeekCompat.WOW_VERSIONS.MISTS
    elseif interfaceVersion >= 40400 and interfaceVersion < 50000 then

        detectedVersion = FrostSeekCompat.WOW_VERSIONS.CATA
    elseif interfaceVersion >= 40000 and interfaceVersion < 40400 then

        detectedVersion = FrostSeekCompat.WOW_VERSIONS.CATA_PS
    elseif interfaceVersion >= 30300 and interfaceVersion < 40000 then

        if interfaceVersion >= 30400 then
            detectedVersion = FrostSeekCompat.WOW_VERSIONS.WOTLK_CLASSIC
        else
            detectedVersion = FrostSeekCompat.WOW_VERSIONS.wotlk335
        end
    elseif interfaceVersion >= 20000 and interfaceVersion < 30000 then
        detectedVersion = FrostSeekCompat.WOW_VERSIONS.TBC
    elseif interfaceVersion >= 11000 and interfaceVersion < 20000 then
        detectedVersion = FrostSeekCompat.WOW_VERSIONS.VANILLA
    else
        detectedVersion = FrostSeekCompat.WOW_VERSIONS.UNKNOWN
    end

    FrostSeekCompat.gameVersion   = detectedVersion
    FrostSeekCompat.interfaceVersion = interfaceVersion

    local versionString, buildNumber = GetBuildInfo()
    FrostSeekCompat.buildVersion = versionString or ""
    FrostSeekCompat.buildNumber  = tonumber(buildNumber) or 0
end

function FrostSeekCompat.GetGameVersion()
    return FrostSeekCompat.gameVersion or FrostSeekCompat.WOW_VERSIONS.UNKNOWN
end

function FrostSeekCompat.GetInterfaceVersion()
    return FrostSeekCompat.interfaceVersion or 0
end

function FrostSeekCompat.Is335()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.wotlk335
end

function FrostSeekCompat.IsVanilla()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.VANILLA
end

function FrostSeekCompat.IsTBC()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.TBC
end

function FrostSeekCompat.IsWotLKClassic()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.WOTLK_CLASSIC
end

function FrostSeekCompat.IsCata()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.CATA
        or FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.CATA_PS
end

function FrostSeekCompat.IsCataPS()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.CATA_PS
end

function FrostSeekCompat.IsCataClassic()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.CATA
end

function FrostSeekCompat.IsMists()
    return FrostSeekCompat.gameVersion == FrostSeekCompat.WOW_VERSIONS.MISTS
end

function FrostSeekCompat.IsMainline()

    return false
end

function FrostSeekCompat.IsClassicEra()
    return FrostSeekCompat.IsVanilla()
end

function FrostSeekCompat.IsAnyClassic()
    return not FrostSeekCompat.IsMainline() and FrostSeekCompat.gameVersion ~= FrostSeekCompat.WOW_VERSIONS.UNKNOWN
end

function FrostSeekCompat.IsWotLKOr335()
    return FrostSeekCompat.Is335() or FrostSeekCompat.IsWotLKClassic()
end

function FrostSeekCompat.IsOfficialClassic()
    return FrostSeekCompat.IsVanilla()
        or FrostSeekCompat.IsTBC()
        or FrostSeekCompat.IsWotLKClassic()
        or FrostSeekCompat.IsCataClassic()
        or FrostSeekCompat.IsMists()
end

FrostSeekCompat.hasBackdropTemplate = false

do
    local testOk, testErr = pcall(function()
        local testFrame = CreateFrame("Frame", "FrostSeek_CompatTest", UIParent, "BackdropTemplate")
        testFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        FrostSeekCompat.hasBackdropTemplate = true
        testFrame:Hide()
        _G["FrostSeek_CompatTest"] = nil
    end)
end

function FrostSeekCompat.GetBackdropTemplateStr()
    if FrostSeekCompat.hasBackdropTemplate then
        return "BackdropTemplate"
    end
    return ""
end

if not C_ChatInfo then
    C_ChatInfo = {}

    function C_ChatInfo.GetChannelInfoFromIdentifier(identifier)

        if not identifier then return nil end
        local targetLower = string.lower(tostring(identifier))
        for i = 1, 20 do
            local name = GetChannelName(i)
            if name and tostring(name) ~= "" and string.lower(tostring(name)) == targetLower then
                return {
                    name = name,
                    channelID = i,
                }
            end
        end
        return nil
    end

    function C_ChatInfo.GetChannelRuleset(channelID)
        return 1

    end

    function C_ChatInfo.GetChannelShortcut(channelID)
        return tostring(channelID)
    end

    function C_ChatInfo.IsChannelRegional(channelID)
        return false
    end
end

FrostSeekCompat.ChannelAPI = {}

function FrostSeekCompat.ChannelAPI.JoinChannel(channelName, password, slot)
    if not channelName then return false end
    password = password or nil
    slot = slot or nil

    local ok, err = pcall(function()
        if JoinChannelByName then

            if FrostSeekCompat.Is335() then
                pcall(function()
                    if slot then
                        JoinChannelByName(channelName, password, nil, slot)
                    else
                        JoinChannelByName(channelName, password)
                    end
                end)
            else
                if slot then
                    JoinChannelByName(channelName, password, nil, slot)
                else
                    JoinChannelByName(channelName, password, nil, 1)
                end
            end
        elseif JoinPermanentChannel then
            JoinPermanentChannel(channelName, password)
        else

            local info = C_ChatInfo and C_ChatInfo.GetChannelInfoFromIdentifier and C_ChatInfo.GetChannelInfoFromIdentifier(channelName)
            if info then

            end
        end
    end)

    return ok
end

function FrostSeekCompat.ChannelAPI.LeaveChannel(channelName)
    if not channelName then return end

    pcall(function()
        if LeaveChannelByName then
            LeaveChannelByName(channelName)
        elseif C_ChatInfo and C_ChatInfo.LeaveChannel then
            C_ChatInfo.LeaveChannel(channelName)
        end
    end)
end

function FrostSeekCompat.ChannelAPI.GetChannelID(channelName)
    if not channelName then return nil end
    local targetLower = string.lower(tostring(channelName))

    if C_ChatInfo and C_ChatInfo.GetChannelInfoFromIdentifier then
        local ok, info = pcall(function()
            return C_ChatInfo.GetChannelInfoFromIdentifier(channelName)
        end)
        if ok and info and info.channelID then
            return info.channelID
        end
    end

    for i = 1, 20 do
        local ok, _, name = pcall(function()
            return GetChannelName(i)
        end)
        if ok and name and tostring(name) ~= "" and string.lower(tostring(name)) == targetLower then
            return i
        end
    end

    if GetNumDisplayChannels and GetChannelDisplayInfo then
        local ok, count = pcall(function()
            return GetNumDisplayChannels()
        end)
        if ok and count then
            for i = 1, count do
                local ok2, name, _, _, channelNumber = pcall(function()
                    return GetChannelDisplayInfo(i)
                end)
                if ok2 and name and string.lower(tostring(name)) == targetLower then
                    if channelNumber then return channelNumber end

                    for j = 1, 20 do
                        local chName = GetChannelName(j)
                        if chName and string.lower(tostring(chName)) == targetLower then
                            return j
                        end
                    end
                end
            end
        end
    end

    return nil
end

function FrostSeekCompat.ChannelAPI.SendChannelMessage(message, channelId)
    if not message or message == "" then return false end
    if not channelId then return false end

    local ok, err = pcall(function()
        SendChatMessage(message, "CHANNEL", nil, channelId)
    end)

    return ok
end

FrostSeekCompat.IsFriendCached = function(name)
    if not name or name == "" then return false end

    if C_FriendList and C_FriendList.IsFriend then
        local ok, result = pcall(function()
            return C_FriendList.IsFriend(name)
        end)
        if ok then return result end
    end

    local numFriends = 0
    local ok, count = pcall(function()
        return GetNumFriends()
    end)
    if ok then numFriends = count or 0 end

    for i = 1, numFriends do
        local ok2, friendName = pcall(function()
            return GetFriendInfo(i)
        end)
        if ok2 and friendName then

            if tostring(friendName) == name then
                return true
            end
        end
    end

    if IsFriend then
        local ok, result = pcall(function()
            return IsFriend(name)
        end)
        if ok then return result == true end
    end

    return false
end

FrostSeekCompat.GetOnlineFriendsCount = function()
    local onlineFriends = 0
    local numFriends = 0

    if C_FriendList and C_FriendList.GetNumFriends then
        local ok, count = pcall(function() return C_FriendList.GetNumFriends() end)
        if ok then numFriends = count or 0 end
    end

    if numFriends == 0 and GetNumFriends then
        local ok, count = pcall(function() return GetNumFriends() end)
        if ok then numFriends = count or 0 end
    end

    for i = 1, numFriends do
        local connected = false
        if C_FriendList and C_FriendList.GetFriendInfoByIndex then
            local ok, info = pcall(function() return C_FriendList.GetFriendInfoByIndex(i) end)
            if ok and info then connected = info.connected or false end
        elseif GetFriendInfo then
            local ok, _, _, _, conn5, conn6 = pcall(function() return GetFriendInfo(i) end)
            if ok then
                if type(conn5) == "boolean" then
                    connected = conn5
                elseif type(conn6) == "boolean" then
                    connected = conn6
                elseif conn5 ~= nil then
                    connected = conn5 and true or false
                end
            end
        end
        if connected then onlineFriends = onlineFriends + 1 end
    end

    return onlineFriends
end

FrostSeekCompat.GetInventoryItemLink = function(unit, slot)
    local ok, link = pcall(function()
        return GetInventoryItemLink(unit, slot)
    end)
    if ok and link then return link end

    if C_Item and C_Item.GetInventoryItemLink then
        local ok2, link2 = pcall(function()
            return C_Item.GetInventoryItemLink(unit, slot)
        end)
        if ok2 then return link2 end
    end

    return nil
end

FrostSeekCompat.GetItemInfo = function(itemIDorLink)
    local ok, result = pcall(function()
        return GetItemInfo(itemIDorLink)
    end)
    if ok then return result end

    if C_Item and C_Item.GetItemInfo then
        local ok2, result2 = pcall(function()
            return C_Item.GetItemInfo(itemIDorLink)
        end)
        if ok2 then return result2 end
    end

    return nil
end

FrostSeekCompat.CanInspect = function(unit)
    if CanInspect then
        local ok, result = pcall(function()
            return CanInspect(unit)
        end)
        if ok then return result end
    end
    return false
end

FrostSeekCompat.NotifyInspect = function(unit)
    if NotifyInspect then
        pcall(function()
            NotifyInspect(unit)
        end)
    end
end

FrostSeekCompat.OpenChat = function(msg)
    if ChatFrame_OpenChat then
        pcall(function()
            ChatFrame_OpenChat(msg)
        end)
    elseif ChatEdit_GetActiveWindow then
        local editBox = ChatEdit_GetActiveWindow()
        if editBox then
            editBox:SetText(msg)
            editBox:SetFocus()
        end
    end
end

FrostSeekCompat.GetPlayerItemLevel = function(unit)
    if not unit then return nil end

    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink = FrostSeekCompat.GetInventoryItemLink(unit, i)
            if itemLink then
                local info = FrostSeekCompat.GetItemInfo(itemLink)
                if info then

                    local itemLevel = select(4, info)
                    if itemLevel and itemLevel > 0 then
                        sum = sum + itemLevel
                        count = count + 1
                    end
                end
            end
        end
    end

    if count > 0 then
        return math.floor((sum / count) + 0.5)
    end
    return nil
end

FrostSeekCompat.GetRealZoneText = function()
    if GetRealZoneText then
        return GetRealZoneText()
    end
    return ""
end

FrostSeekCompat.UnitLevel = function(unit)
    local level = UnitLevel(unit) or 0
    return level
end

FrostSeekCompat.GetGuildInfo = function(unit)
    if GetGuildInfo then
        local ok, result = pcall(function()
            return GetGuildInfo(unit)
        end)
        if ok then return result end
    end
    return nil
end

FrostSeekCompat.HookTooltipScript = function(scriptName, handler)
    if GameTooltip and GameTooltip.HookScript then
        local ok, err = pcall(function()
            GameTooltip:HookScript(scriptName, handler)
        end)
        if ok then return true end
    end

    if GameTooltip then
        local origScript = GameTooltip:GetScript(scriptName)
        if origScript then
            GameTooltip:SetScript(scriptName, function(self, ...)
                origScript(self, ...)
                handler(self, ...)
            end)
        else
            GameTooltip:SetScript(scriptName, handler)
        end
        return true
    end

    return false
end

FrostSeekCompat.SendChatMessage = function(msg, chatType, language, channel)
    if not msg or msg == "" then return false end
    chatType = chatType or "CHANNEL"

    local ok, err = pcall(function()
        SendChatMessage(msg, chatType, language, channel)
    end)

    return ok
end

FrostSeekCompat.GetFontPath = function()
    return "Fonts\\FRIZQT__.TTF"
end

FrostSeekCompat.GetMaxLevel = function()
    local v = FrostSeekCompat.GetGameVersion()
    if v == FrostSeekCompat.WOW_VERSIONS.MISTS then
        return 90
    elseif v == FrostSeekCompat.WOW_VERSIONS.CATA or v == FrostSeekCompat.WOW_VERSIONS.CATA_PS then
        return 85
    elseif v == FrostSeekCompat.WOW_VERSIONS.WOTLK_CLASSIC or v == FrostSeekCompat.WOW_VERSIONS.wotlk335 then
        return 80
    elseif v == FrostSeekCompat.WOW_VERSIONS.TBC then
        return 70
    elseif v == FrostSeekCompat.WOW_VERSIONS.VANILLA then
        return 60
    end
    return 80
end

FrostSeekCompat.GetExpansionLabel = function()
    local v = FrostSeekCompat.GetGameVersion()
    if v == FrostSeekCompat.WOW_VERSIONS.MISTS then
        return "MoP Classic"
    elseif v == FrostSeekCompat.WOW_VERSIONS.CATA then
        return "Cata Classic"
    elseif v == FrostSeekCompat.WOW_VERSIONS.CATA_PS then
        return "Cata 4.3.4"
    elseif v == FrostSeekCompat.WOW_VERSIONS.WOTLK_CLASSIC then
        return "WotLK Classic"
    elseif v == FrostSeekCompat.WOW_VERSIONS.wotlk335 then
        return "WotLK 3.3.5"
    elseif v == FrostSeekCompat.WOW_VERSIONS.TBC then
        return "TBC Classic"
    elseif v == FrostSeekCompat.WOW_VERSIONS.VANILLA then
        return "Classic Era"
    end
    return "Unknown"
end

FrostSeekCompat.hasBackdropTemplate = FrostSeekCompat.hasBackdropTemplate or false

local ASCENSION_REALMS = {
    ["area 52"]           = "classless",
    ["area52"]            = "classless",
    ["a52"]               = "classless",
    ["bronzebeard"]       = "bronzebeard",
    ["dawnrisedarkmoon"]  = "seasonal",
    ["dawnrise"]          = "seasonal",
    ["darkmoon"]          = "seasonal",
    ["voljinrexxar"]      = "coa",
    ["voljin"]            = "coa",
    ["vol'jin"]           = "coa",
    ["vol jin"]           = "coa",
    ["rexxar"]            = "coa",
    ["conquest of azeroth"] = "coa",
    ["conquest"]          = "coa",
    ["coa"]               = "coa",
}

local EPOCH_REALMS = {
    ["kezan"]          = "epoch",
    ["gurubashi"]      = "epoch",
}

local CATA_PS_REALMS = {
    ["whitemane"]   = "whitemane",
    ["blackrock"]   = "blackrock",
    ["sulfuras"]    = "sulfuras",
    ["benevolence"] = "benevolence",
    ["mal'ganis"]   = "malganis",
}

do
    local realmName = GetRealmName and GetRealmName() or ""
    local realmLower = string.lower(realmName)

    local detectedType = FrostSeekCompat.GetExpansionLabel():lower()
    local isAsc = false
    local ascMode = nil
    local isEpoch = false
    local isCataPS = FrostSeekCompat.IsCataPS()
    local cataPSRealm = nil

    if FrostSeekCompat.Is335() then
        if EPOCH_REALMS[realmLower] then
            isEpoch = true
        else
            for key, _ in pairs(EPOCH_REALMS) do
                if string.find(realmLower, key, 1, true) then
                    isEpoch = true
                    break
                end
            end
        end

        if not isEpoch then
            if ASCENSION_REALMS[realmLower] then
                isAsc = true
                ascMode = ASCENSION_REALMS[realmLower]
            else
                for key, mode in pairs(ASCENSION_REALMS) do
                    if string.find(realmLower, key, 1, true) then
                        isAsc = true
                        ascMode = mode
                        break
                    end
                end
            end

            if not isAsc and _G.MysticEnchantUtil then
                isAsc = true
                ascMode = "classless"
            end
        end

        if isEpoch then
            detectedType = "epoch"
        elseif isAsc then
            detectedType = "ascension"
        end
    end

    if FrostSeekCompat.IsCataPS() then
        if CATA_PS_REALMS[realmLower] then
            cataPSRealm = CATA_PS_REALMS[realmLower]
        else
            for key, mode in pairs(CATA_PS_REALMS) do
                if string.find(realmLower, key, 1, true) then
                    cataPSRealm = mode
                    break
                end
            end
        end
        detectedType = "cata_ps"
    end

    FrostSeekCompat.serverType     = detectedType
    FrostSeekCompat.isAscension    = isAsc
    FrostSeekCompat.isEpoch        = isEpoch
    FrostSeekCompat.realmName      = realmName
    FrostSeekCompat.ascensionMode  = ascMode
    FrostSeekCompat.isCataPrivate  = isCataPS
    FrostSeekCompat.cataPSRealm    = cataPSRealm
end

function FrostSeekCompat.IsEpoch()
    return FrostSeekCompat.isEpoch == true
end

function FrostSeekCompat.GetRealmName()
    return FrostSeekCompat.realmName or ""
end

function FrostSeekCompat.GetServerType()
    return FrostSeekCompat.serverType or "vanilla"
end

function FrostSeekCompat.IsAscension()
    return FrostSeekCompat.isAscension == true
end

function FrostSeekCompat.IsVanillaServer()
    return not FrostSeekCompat.IsAscension()
end

function FrostSeekCompat.GetAscensionMode()
    return FrostSeekCompat.ascensionMode
end

function FrostSeekCompat.HasMysticEnchants()
    local mode = FrostSeekCompat.ascensionMode
    return mode == "classless" or mode == "bronzebeard" or mode == "seasonal"
end

function FrostSeekCompat.IsConquestOfAzeroth()
    return FrostSeekCompat.ascensionMode == "coa"
end

function FrostSeekCompat.GetServerTypeLabel()

    if FrostSeekCompat.IsCataPS() then
        local realm = FrostSeekCompat.GetRealmName()
        local realmKey = FrostSeekCompat.cataPSRealm
        if realmKey == "whitemane" then
            return "Whitemane (" .. realm .. ")"
        elseif realmKey then
            return "Cata PS (" .. realm .. ")"
        else
            return "Cata 4.3.4 (" .. realm .. ")"
        end
    end

    if not FrostSeekCompat.Is335() then
        return FrostSeekCompat.GetExpansionLabel()
    end

    if FrostSeekCompat.IsAscension() then
        local mode = FrostSeekCompat.GetAscensionMode()
        local realm = FrostSeekCompat.GetRealmName()
        if mode == "classless" then
            return "Ascension (" .. realm .. " - Classless)"
        elseif mode == "bronzebeard" then
            return "Ascension (Bronzebeard - Classic+)"
        elseif mode == "coa" then
            return "Ascension (CoA)"
        elseif mode == "seasonal" then
            return "Ascension (" .. realm .. " - Seasonal)"
        else
            return "Ascension (" .. realm .. ")"
        end
    else
        return "WotLK 3.3.5"
    end
end

function FrostSeekCompat.GetServerTypeColor()
    if FrostSeekCompat.IsAscension() then
        local mode = FrostSeekCompat.ascensionMode
        if mode == "coa" then
            return {0.85, 0.45, 0.15}
        elseif mode == "bronzebeard" then
            return {0.6, 0.5, 0.3}
        else
            return {0.6, 0.3, 0.85}
        end
    elseif FrostSeekCompat.IsCataPS() then
        return {0.75, 0.40, 0.20}
    elseif FrostSeekCompat.IsMists() then
        return {0.0, 0.65, 0.55}
    elseif FrostSeekCompat.IsCata() then
        return {0.85, 0.35, 0.25}
    elseif FrostSeekCompat.IsWotLKClassic() then
        return {0.15, 0.55, 0.85}
    elseif FrostSeekCompat.IsTBC() then
        return {0.55, 0.25, 0.75}
    elseif FrostSeekCompat.IsVanilla() then
        return {0.65, 0.55, 0.30}
    else
        return {0.2, 0.75, 0.2}
    end
end

local compatFrame = CreateFrame("Frame")
compatFrame:RegisterEvent("ADDON_LOADED")
compatFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "FrostSeek" then return end
    self:UnregisterEvent("ADDON_LOADED")

    local serverLabel = FrostSeekCompat.GetServerTypeLabel()
    local serverColor = FrostSeekCompat.GetServerTypeColor()
    local serverHex = string.format("|cff%02x%02x%02x",
        math.floor(serverColor[1] * 255),
        math.floor(serverColor[2] * 255),
        math.floor(serverColor[3] * 255))

    local versionInfo = string.format(_G.FrostSeek.L["compat_version_info"],
        FrostSeekCompat.GetInterfaceVersion(),
        FrostSeekCompat.GetExpansionLabel())

    print("|cff88ccffFrostSeek Compat:|r " ..
        (FrostSeekCompat.hasBackdropTemplate and _G.FrostSeek.L["compat_backdrop_yes"] or _G.FrostSeek.L["compat_backdrop_no"]) ..
        " | " ..
        (C_Timer and _G.FrostSeek.L["compat_ctimer_ok"] or _G.FrostSeek.L["compat_ctimer_missing"]) ..
        " | " ..
        versionInfo ..
        " | " ..
        serverHex .. _G.FrostSeek.L["compat_server_label"] .. serverLabel .. "|r" ..
        " | " ..
        _G.FrostSeek.L["compat_layer_loaded"]
    )
end)