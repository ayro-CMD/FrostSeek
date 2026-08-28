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

local Network = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("network", Network)

local CHANNEL = "FSK"
local CHANNEL_SLOT = 12
local PROTOCOL = FrostSeek and FrostSeek.Protocol
local Compat = FrostSeekCompat
local Shared = _G.FrostSeekShared
local L = FrostSeek and FrostSeek.L or function(k) return k end
local function LPrint(key, ...)
    local body = select("#", ...) > 0 and FrostSeek.Lf and FrostSeek.Lf(key, ...) or L[key]
    print("|cff88ccffFrostNet:|r " .. tostring(body))
end

local HasAddonMessageAPI = false
local AddonMessageChannel = "FrostSeek"
do
    local ok = pcall(function()
        if C_ChatInfo and C_ChatInfo.SendAddonMessage and C_ChatInfo.RegisterAddonMessagePrefix then
            local registered = C_ChatInfo.RegisterAddonMessagePrefix(AddonMessageChannel)
            HasAddonMessageAPI = registered ~= false
        end
    end)
    if not ok then HasAddonMessageAPI = false end
end

Network.usesAddonMessageAPI = HasAddonMessageAPI
Network.addonMessagePrefix = AddonMessageChannel

local function CompatModeEnabled()
    return not (FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.frostnetCompat == false)
end
Network.CompatModeEnabled = CompatModeEnabled

Network.channelId = nil
Network.channelName = CHANNEL
Network.isConnected = false
Network.wasConnected = false
Network.joinAttempts = 0
Network.maxJoinAttempts = 10
Network.lastJoinAttempt = 0
Network.lastSendTime = 0
Network._lastSendTime = {}
Network.rxCount = 0
Network.txCount = 0
Network.droppedCount = 0
Network._lastHeartbeat = 0       
Network.HEARTBEAT_INTERVAL = 60  

Network._queue = {}
Network._queueMax = 50

local RATE_LIMITS = {
    LIST = 0.2,
    APP = 0.3,
    REMOVE = 0.3,
    DECISION = 0.3,
    PING = 1.0,
    PONG = 1.0,
    HB = 1.0,
    REPORT = 0.5,
}

local function debugLog(msg)
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
        print("|cffffcc00[FSK-DBG]|r " .. tostring(msg))
    end
    if FrostSeek and FrostSeek.Logger and FrostSeek.Logger.Debug then
        FrostSeek.Logger.Debug("[net] " .. tostring(msg))
    end
end
Network._debug = debugLog

local function getChannelId(channelName)
    if not channelName then return nil end
    local targetLower = string.lower(tostring(channelName))

    do
        local ok0, first = pcall(function()
            return (GetChannelName(channelName))
        end)
        if ok0 and type(first) == "number" and first > 0 then
            return first
        end
    end

    if Compat and Compat.ChannelAPI and Compat.ChannelAPI.GetChannelID then
        local cid = Compat.ChannelAPI.GetChannelID(channelName)
        if cid then return cid end
    end

    if GetChannelList then
        local okL, list = pcall(function() return { GetChannelList() } end)
        if okL and type(list) == "table" then
            for i = 1, #list - 1, 2 do
                local cid, cname = list[i], list[i + 1]
                if type(cid) == "number" and type(cname) == "string"
                    and string.lower(cname) == targetLower then
                    return cid
                end
            end
        end
    end

    do
        local okN, nm, _, _, num = pcall(function()
            return GetChannelName(channelName)
        end)
        if okN and type(num) == "number" and num > 0 then
            return num
        end
    end

    for i = 1, 20 do
        local ok2, r1, r2 = pcall(function()
            return GetChannelName(i)
        end)
        if ok2 then
            if type(r1) == "string" and r1 ~= ""
                and string.lower(r1) == targetLower then
                return i
            end
            if type(r1) == "number" and r1 > 0 and type(r2) == "string"
                and string.lower(r2) == targetLower then
                return r1
            end
        end
    end

    if GetNumDisplayChannels and GetChannelDisplayInfo then
        local ok3, count = pcall(function()
            return GetNumDisplayChannels()
        end)
        if ok3 and count then
            for i = 1, count do
                local ok4, dname, _, _, channelNumber = pcall(function()
                    return GetChannelDisplayInfo(i)
                end)
                if ok4 and dname and string.lower(tostring(dname)) == targetLower then
                    if channelNumber then return channelNumber end
                end
            end
        end
    end
    return nil
end
Network.getChannelId = getChannelId

function Network:JoinChannel()
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.frostnetEnabled == false then return end
    if self.isConnected and self.channelId then return end
    local now = GetTime()
    if now - self.lastJoinAttempt < 5 then return end
    self.lastJoinAttempt = now
    self.joinAttempts = self.joinAttempts + 1

    local joinedViaCompat = false
    if Compat and Compat.ChannelAPI and Compat.ChannelAPI.JoinChannel then
        joinedViaCompat = pcall(function()
            Compat.ChannelAPI.JoinChannel(CHANNEL, nil, CHANNEL_SLOT)
        end)
    end

    if not joinedViaCompat then
        pcall(function()
            if JoinChannelByName then
                JoinChannelByName(CHANNEL, nil, nil, CHANNEL_SLOT)
            elseif JoinPermanentChannel then
                JoinPermanentChannel(CHANNEL)
            end
        end)
    end

    C_Timer.After(3, function()
        self.channelId = getChannelId(CHANNEL)
        if self.channelId then
            local wasConn = self.isConnected
            self.isConnected = true
            self.joinAttempts = 0
            if not self.wasConnected then
                self.wasConnected = true
                if Shared then Shared.PlaySound("connect") end
                LPrint("net_connected", CHANNEL, tostring(CHANNEL_SLOT))
            end
            if not wasConn then self:ScheduleRebroadcast() end
        else
            self.isConnected = false
            if self.joinAttempts < self.maxJoinAttempts then
                C_Timer.After(5, function() self:JoinChannel() end)
            end
        end
    end)
end

function Network:LeaveChannel()
    if self.channelId then
        if Compat and Compat.ChannelAPI and Compat.ChannelAPI.LeaveChannel then
            Compat.ChannelAPI.LeaveChannel(CHANNEL)
        else
            pcall(function() LeaveChannelByName(CHANNEL) end)
        end
        self.channelId = nil
        self.isConnected = false
    end
end

function Network:RefreshChannel()
    local newId = getChannelId(CHANNEL)
    if newId then
        self.channelId = newId
        if not self.isConnected then
            self.isConnected = true
            if not self.wasConnected then
                self.wasConnected = true
                if Shared then Shared.PlaySound("connect") end
                LPrint("net_connected", CHANNEL, tostring(CHANNEL_SLOT))
            end
        end
    elseif self.channelId then
        if not self.isConnected then
            self.isConnected = true
            if not self.wasConnected then
                self.wasConnected = true
            end
        end
    else
        if self.isConnected then
            self.isConnected = false
            LPrint("net_disconnected", CHANNEL)
        end
    end
end

local function detectMsgType(message)
    if not message then return nil end
    local sep = string.find(message, "~", 1, true)
    if not sep then return nil end
    local after = string.sub(message, sep + 1)
    local sep2 = string.find(after, "~", 1, true)
    if sep2 then return string.sub(after, 1, sep2 - 1) end
    return after
end

function Network:Send(message)
    if not message or message == "" then return false end
    if not PROTOCOL then
        PROTOCOL = FrostSeek and FrostSeek.Protocol
        if not PROTOCOL then return false end
    end
    if PROTOCOL.IsAddonSpam and PROTOCOL:IsAddonSpam(message) then
        debugLog("Send dropped (spam filter): " .. tostring(string.sub(message, 1, 40)))
        return false
    end

    local maxWire = (PROTOCOL and PROTOCOL.MAX_WIRE) or (Shared and Shared.MAX_MESSAGE_LENGTH) or 240
    if #message > maxWire then
        message = string.sub(message, 1, maxWire)
    end

    local msgType = detectMsgType(message)
    local rateLimit = (msgType and RATE_LIMITS[msgType]) or (Shared and Shared.MAX_SEND_RATE) or 1.0
    local now = GetTime()
    local lastT = (msgType and self._lastSendTime[msgType]) or 0
    local tooSoon = (now - lastT) < rateLimit

    local function sendHidden()
        if not HasAddonMessageAPI then return false end
        local ok = pcall(function()
            C_ChatInfo.SendAddonMessage(AddonMessageChannel, message, "CHANNEL", CHANNEL)
        end)
        if not ok then
            debugLog("SendAddonMessage (CHANNEL) failed, falling back to chat")
        end
        return ok
    end

    local function sendVisible()
        if not self.channelId then
            self.channelId = getChannelId(CHANNEL)
        end
        if not self.channelId then return false end
        local ok = pcall(function()
            SendChatMessage(message, "CHANNEL", nil, self.channelId)
        end)
        if not ok then
            debugLog("SendChatMessage error")
        end
        return ok
    end

    local function actuallySend()
        if not self.channelId then
            self:RefreshChannel()
        end
        if not self.channelId and not HasAddonMessageAPI then
            return false, "no_channel"
        end
        local sent = false
        if sendHidden() then
            sent = true
        end
        if CompatModeEnabled() or not sent then
            if sendVisible() then
                sent = true
            end
        end
        if sent then
            return true
        end
        return false, "send_error"
    end

    if tooSoon then
        debugLog("Send deferred by rate-limit (" .. tostring(msgType) .. "), queuing")
        self:_Enqueue(message)
        return false
    end

    local ok, why = actuallySend()
    if ok then
        PROTOCOL:MarkProcessed(message)
        if msgType then self._lastSendTime[msgType] = GetTime() end
        self.lastSendTime = GetTime()
        self.txCount = self.txCount + 1
        debugLog("Send OK (" .. tostring(msgType) .. ") len=" .. tostring(#message))
        return true
    end

    debugLog("Send failed (" .. tostring(why) .. "), queuing for retry")
    self:_Enqueue(message)
    return false
end

function Network:_Enqueue(message)
    if not message then return end
    for _, m in ipairs(self._queue) do
        if m == message then return end
    end
    table.insert(self._queue, message)
    while #self._queue > self._queueMax do
        table.remove(self._queue, 1)
    end
end

function Network:_FlushQueue()
    if not self._queue or #self._queue == 0 then return end
    if not self.channelId then self:RefreshChannel() end
    if not self.channelId and not HasAddonMessageAPI then
        if #self._queue >= 5 and not self._queueWarned then
            self._queueWarned = true
            print(L["net_cannot_reach_prefix"] .. tostring(#self._queue) .. L["net_messages_queued_hint"])
        end
        return
    end
    self._queueWarned = false

    local snapshot = self._queue
    self._queue = {}

    for i, message in ipairs(snapshot) do
        local msgType = detectMsgType(message)
        local rateLimit = (msgType and RATE_LIMITS[msgType]) or 1.0
        local now = GetTime()
        local lastT = (msgType and self._lastSendTime[msgType]) or 0
        if (now - lastT) < rateLimit then
            self:_Enqueue(message)
        else
            local ok = false
            if HasAddonMessageAPI then
                ok = pcall(function()
                    C_ChatInfo.SendAddonMessage(AddonMessageChannel, message, "CHANNEL", CHANNEL)
                end)
            end
            if (CompatModeEnabled() or not ok) and self.channelId then
                local okVis = pcall(function()
                    SendChatMessage(message, "CHANNEL", nil, self.channelId)
                end)
                if okVis then ok = true end
            end
            if ok then
                if PROTOCOL and PROTOCOL.MarkProcessed then
                    PROTOCOL:MarkProcessed(message)
                end
                if msgType then self._lastSendTime[msgType] = GetTime() end
                self.lastSendTime = GetTime()
                self.txCount = self.txCount + 1
                debugLog("Queue flush OK (" .. tostring(msgType) .. ")")
            else
                self:_Enqueue(message)
            end
        end
    end
end

function Network:SendListing(listing)
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializeListing(listing)
    if not msg then return false end
    local ok = self:Send(msg)
    if ok then
        print(L["net_published_prefix"] .. tostring(listing.activity or "?") .. L["net_debug_id_prefix"] .. tostring(self.channelId) .. L["net_debug_len_label"] .. tostring(#msg) .. L["net_debug_id_close"])
        self._lastSentListingId = listing.id
        self._lastSentEchoTime = GetTime()
        self._echoReceived = false
        local sentId = listing.id
        C_Timer.After(2, function()
            if Network._lastSentListingId == sentId and not Network._echoReceived then
            LPrint("net_no_loopback")
            end
        end)
    else
        if not self.channelId then
            LPrint("net_publish_queued")
        else
            LPrint("net_publish_ratelimited")
        end
    end
    return ok
end

function Network:SendApplicant(listingId, applicant)
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializeApplicant(listingId, applicant)
    if not msg then return false end
    return self:Send(msg)
end

function Network:SendPresence(version, role, spec)
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializePresence(version, role, spec)
    if not msg then return false end
    return self:Send(msg)
end

function Network:SendRemove(listingId)
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializeRemove(listingId)
    if not msg then return false end
    return self:Send(msg)
end

function Network:SendDecision(target, result, activity)
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializeDecision(target, result, activity)
    if not msg then return false end
    return self:Send(msg)
end

function Network:SendPong()
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializePong()
    if not msg then return false end
    return self:Send(msg)
end

function Network:SendHeartbeat()
    if not PROTOCOL then return false end
    if not PROTOCOL.SerializeHeartbeat then return false end
    local pn = UnitName("player") or ""
    if pn == "" then return false end
    local msg = PROTOCOL.SerializeHeartbeat(pn)
    if not msg then return false end
    return self:Send(msg)
end

C_Timer.NewTicker(10, function()
    Network:RefreshChannel()
end)

C_Timer.NewTicker(2, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    Network:_FlushQueue()
end)

C_Timer.NewTicker(60, function()
    if not Network.isConnected then
        Network.joinAttempts = 0
        Network:JoinChannel()
    end
end)

C_Timer.NewTicker(Network.HEARTBEAT_INTERVAL, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    if Network.isConnected or HasAddonMessageAPI then
        Network:SendHeartbeat()
    end
    if PROTOCOL and PROTOCOL.CleanupSenderBuckets then
        PROTOCOL:CleanupSenderBuckets()
    end
end)

Network._rebroadcastPending = false
function Network:ScheduleRebroadcast()
    if self._rebroadcastPending then return end
    self._rebroadcastPending = true
    C_Timer.After(3, function()
        self._rebroadcastPending = false
        if not FrostSeek or not FrostSeek.Listings then return end
        local Listings = FrostSeek.Listings
        if Listings.myListing then
            debugLog("Channel (re)connected: re-broadcasting my listing")
            if Listings.BroadcastMyListing then
                Listings:BroadcastMyListing()
            elseif self and self.SendListing then
                self:SendListing(Listings.myListing)
            end
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHANNEL_UI_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")

if HasAddonMessageAPI then
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
end

local rawHandler = function(_, event, ...)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    if event == "PLAYER_LOGIN" then
        C_Timer.After(10, function()
            Network:JoinChannel()
        end)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channelType, sender = ...
        if prefix ~= AddonMessageChannel then return end
        if not message or message == "" then return end
        Network:HandleMessage(message, sender or "?")
        return
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        local message, _, _, _, _, _, zoneChannelID, _, channelName = ...
        local nameMatched = false
        if channelName and tostring(channelName) ~= "" then
            local cnLower = string.lower(tostring(channelName))
            local cnNorm = string.match(cnLower, "^%s*%d*%.?%s*(.-)%s*$") or cnLower
            if cnNorm == string.lower(CHANNEL) then nameMatched = true end
        end
        local isFSKNotice = nameMatched
        if not isFSKNotice
            and (message == "YOU_JOINED" or message == "YOU_CHANGED" or message == "CHANNEL_JOIN") then
            if getChannelId(CHANNEL) then
                isFSKNotice = true
                debugLog("FSK notice matched via resolution fallback (arg9: " .. tostring(channelName) .. ")")
            end
        end
        if isFSKNotice then
            local newId = nil
            if nameMatched and type(zoneChannelID) == "number" and zoneChannelID > 0 then
                newId = zoneChannelID
            end
            if not newId then newId = getChannelId(CHANNEL) end
            if newId then
                local wasConnected = Network.isConnected
                Network.channelId = newId
                Network.isConnected = true
                Network.joinAttempts = 0
                if not wasConnected then
                    debugLog("FSK channel joined (id=" .. tostring(newId) .. ")")
                    Network:ScheduleRebroadcast()
                end
            elseif Network.channelId and not Network.isConnected then
                Network.isConnected = true
            end
        end
        if message == "YOU_CHANGED" or message == "YOU_JOINED" or message == "CHANNEL_JOIN" or message == "CHANNEL_COUNT_UPDATE" then
            Network:RefreshChannel()
        end

    elseif event == "CHAT_MSG_CHANNEL" then
        local text, author, _, _, _, _, zoneChannelID, num, channelName = ...
        local isFSK = false
        if channelName and tostring(channelName) ~= "" then
            local cnLower = string.lower(tostring(channelName))
            local cnNorm = string.match(cnLower, "^%s*%d*%.?%s*(.-)%s*$") or cnLower
            if cnNorm == string.lower(CHANNEL) then isFSK = true end
        end
        if not isFSK then
            if num and tonumber(num) == tonumber(Network.channelId) then
                isFSK = true
            end
            if not isFSK and zoneChannelID and tonumber(zoneChannelID) == tonumber(Network.channelId) then
                isFSK = true
            end
        end
        if not isFSK and text then
            local head = string.sub(text, 1, 4)
            if (head == "FSK2" or head == "FSK1")
                and string.len(text) >= 5 and string.sub(text, 5, 5) == "~" then
                isFSK = true
                debugLog("RX accepted via prefix fallback (channel arg: " .. tostring(channelName) .. ")")
            end
        end
        if isFSK then
            local zid = tonumber(zoneChannelID)
            if zid and zid > 0 and Network.channelId ~= zid then
                debugLog("FSK channel id self-healed from traffic: " .. tostring(zid))
                Network.channelId = zid
            end
            if not Network.channelId then
                Network.channelId = getChannelId(CHANNEL)
            end
            if Network.channelId and not Network.isConnected then
                Network.isConnected = true
                Network.joinAttempts = 0
            end
        end
        if isFSK and text then
            local head = string.sub(text, 1, 4)
            if head ~= "FSK2" and head ~= "FSK1" then
                isFSK = false
            elseif string.len(text) < 5 or string.sub(text, 5, 5) ~= "~" then
                isFSK = false
            end
        end
        if isFSK then
            Network:HandleMessage(text, author)
        end

    elseif event == "CHANNEL_UI_UPDATE" then
        Network:RefreshChannel()
    end
end

if FrostSeek and FrostSeek.SafeHandler then
    eventFrame:SetScript("OnEvent", FrostSeek.SafeHandler(rawHandler))
else
    eventFrame:SetScript("OnEvent", rawHandler)
end

local function FrostNetProtocolChatFilter(self, event, msg, sender, langName, channelName)
    if type(msg) ~= "string" or msg == "" then return false end
    local head = string.sub(msg, 1, 4)
    if head == "FSK2" or head == "FSK1" then
        return true
    end
    if event == "CHAT_MSG_CHANNEL" and channelName then
        local cn = string.match(tostring(channelName), "^%s*%d*%.?%s*(.-)%s*$")
        if cn and string.lower(cn) == string.lower(CHANNEL) then
            -- mimi
            if string.find(msg, "~", 1, true) then
                return true
            end
        end
    end
    return false
end
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FrostNetProtocolChatFilter)
end

function Network:HandleMessage(raw, author)
    if not PROTOCOL then
        PROTOCOL = FrostSeek and FrostSeek.Protocol
        if not PROTOCOL then return end
    end
    if self._lastSentListingId and raw and author then
        local pn = UnitName("player") or ""
        local authorClean = tostring(author)
        if string.find(authorClean, "-", 1, true) then
            authorClean = string.sub(authorClean, 1, string.find(authorClean, "-", 1, true) - 1)
        end
        if authorClean == pn then
            local sentId = self._lastSentListingId
            if sentId ~= nil and string.find(raw, tostring(sentId), 1, true) then
                self._echoReceived = true
                debugLog("Loopback echo received for listing " .. tostring(sentId) .. " (channel is healthy)")
            end
        end
    end

    if PROTOCOL.IsDuplicate and PROTOCOL:IsDuplicate(raw) then
        debugLog("RX dropped (dup): " .. tostring(string.sub(raw, 1, 40)))
        self.droppedCount = self.droppedCount + 1
        return
    end
    local parseOk, msgType, parts = pcall(function()
        return PROTOCOL.Parse(raw)
    end)
    if not parseOk or not msgType or not parts then
        debugLog("RX dropped (unparseable): " .. tostring(string.sub(raw or "", 1, 60)))
        self.droppedCount = self.droppedCount + 1
        return
    end
    if PROTOCOL.CheckSenderRate then
        local allowed = PROTOCOL:CheckSenderRate(parts)
        if not allowed then
            debugLog("RX dropped (sender flooding): " .. tostring(string.sub(raw, 1, 60)))
            self.droppedCount = self.droppedCount + 1
            return
        end
    end
    if PROTOCOL.MarkProcessed then
        PROTOCOL:MarkProcessed(raw)
    end
    local pn = UnitName("player") or ""
    local authorClean = author and tostring(author) or ""
    if string.find(authorClean, "-", 1, true) then
        authorClean = string.sub(authorClean, 1, string.find(authorClean, "-", 1, true) - 1)
    end
    if authorClean == pn then return end

    self.rxCount = self.rxCount + 1
    debugLog("RX " .. tostring(msgType) .. " from " .. tostring(authorClean) .. " (parts=" .. tostring(#parts) .. ")")

    if msgType == PROTOCOL.MSG_TYPES.PING then
        local user = PROTOCOL.ParsePresence(parts)
        if user and user.name and user.name ~= "" and user.name ~= pn then
            if FrostSeek.Presence and FrostSeek.Presence.HandlePresence then
                FrostSeek.Presence:HandlePresence(user)
            end
            local lastPong = self._pongSentAt and self._pongSentAt[user.name]
            if not lastPong or (time() - lastPong) > 5 then
                if not self._pongSentAt then self._pongSentAt = {} end
                if (self._pongCount or 0) > 256 then
                    self._pongSentAt = {}
                    self._pongCount = 0
                end
                self._pongSentAt[user.name] = time()
                self._pongCount = (self._pongCount or 0) + 1
                Network:SendPong()
            end
        end

    elseif msgType == PROTOCOL.MSG_TYPES.PONG then
        local pongData = PROTOCOL.ParsePong(parts)
        if pongData and pongData.name and pongData.name ~= "" and pongData.name ~= pn then
            if FrostSeek.Presence and FrostSeek.Presence.HandlePong then
                FrostSeek.Presence:HandlePong(pongData.name, pongData.seen)
            end
        end

    elseif msgType == PROTOCOL.MSG_TYPES.LIST then
        local listing = PROTOCOL.ParseListing(parts)
        if listing and PROTOCOL.IsValidListing(listing) then
            if FrostSeek.Listings and FrostSeek.Listings.HandleIncomingListing then
                FrostSeek.Listings:HandleIncomingListing(listing)
            end
            if FrostSeek.LFG and FrostSeek.LFG.RecordFromListing then
                FrostSeek.LFG:RecordFromListing(listing)
            end
        else
            debugLog("RX LIST invalid (parts=" .. tostring(#parts) .. ") raw=" .. tostring(string.sub(raw, 1, 80)))
        end

    elseif msgType == PROTOCOL.MSG_TYPES.APP then
        local applicant = PROTOCOL.ParseApplicant(parts)
        if applicant and PROTOCOL.IsValidApplicant(applicant) then
            if FrostSeek.Listings and FrostSeek.Listings.HandleIncomingApplicant then
                FrostSeek.Listings:HandleIncomingApplicant(applicant)
            end
        end

    elseif msgType == PROTOCOL.MSG_TYPES.REMOVE then
        local listingId = parts[3]
        if listingId then
            if FrostSeek.Listings and FrostSeek.Listings.HandleRemove then
                FrostSeek.Listings:HandleRemove(listingId)
            end
        end

    elseif msgType == PROTOCOL.MSG_TYPES.DECISION then
        local target, result, activity = parts[3], parts[4], parts[5] or "group"
        if target then
            if FrostSeek.Listings and FrostSeek.Listings.HandleDecision then
                FrostSeek.Listings:HandleDecision(target, result, activity, authorClean)
            end
        end

    elseif msgType == PROTOCOL.MSG_TYPES.HEARTBEAT then
        if PROTOCOL.ParseHeartbeat then
            local hb = PROTOCOL.ParseHeartbeat(parts)
            if hb and hb.name and hb.name ~= "" and hb.name ~= pn then
                if FrostSeek.Presence and FrostSeek.Presence.HandleHeartbeat then
                    FrostSeek.Presence:HandleHeartbeat(hb.name, hb.seen)
                elseif FrostSeek.Presence and FrostSeek.Presence.HandlePong then
                    FrostSeek.Presence:HandlePong(hb.name, hb.seen)
                end
            end
        end
    end
end

function Network:GetStatus()
    return {
        connected = self.isConnected,
        channelId = self.channelId,
        channel = self.channelName,
        queueLen = self._queue and #self._queue or 0,
    }
end

function Network:GetOnlineCount()
    if FrostSeek.Presence and FrostSeek.Presence.GetOnlineCount then
        return FrostSeek.Presence:GetOnlineCount()
    end
    return 0
end

FrostSeek.Network = Network