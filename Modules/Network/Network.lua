local FrostSeek = _G.FrostSeek

local Network = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("network", Network)

local CHANNEL = "FSK"
local PROTOCOL = FrostSeek and FrostSeek.Protocol
local Compat = FrostSeekCompat
local Shared = _G.FrostSeekShared

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

Network._queue = {}
Network._queueMax = 50

local RATE_LIMITS = {
    LIST = 0.2,
    APP = 0.3,
    REMOVE = 0.3,
    DECISION = 0.3,
    PING = 1.0,
    PONG = 1.0,
}

local function debugLog(msg)
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
        print("|cffffcc00[FSK-DBG]|r " .. tostring(msg))
    end
end
Network._debug = debugLog

local function getChannelId(channelName)
    if not channelName then return nil end
    local ok, id = pcall(function()
        local result = GetChannelName(channelName)
        if type(result) == "number" and result > 0 then
            return result
        end
        return nil
    end)
    if ok and id and type(id) == "number" then return id end
    if Compat and Compat.ChannelAPI and Compat.ChannelAPI.GetChannelID then
        local cid = Compat.ChannelAPI.GetChannelID(channelName)
        if cid then return cid end
    end
    local targetLower = string.lower(channelName)
    for i = 1, 20 do
        local ok2, name = pcall(function()
            return GetChannelName(i)
        end)
        if ok2 and name and tostring(name) ~= "" and string.lower(tostring(name)) == targetLower then
            return i
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

function Network:JoinChannel()
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.frostnetEnabled == false then return end
    if self.isConnected and self.channelId then return end
    local now = GetTime()
    if now - self.lastJoinAttempt < 5 then return end
    self.lastJoinAttempt = now
    self.joinAttempts = self.joinAttempts + 1
    pcall(function()
        if JoinChannelByName then
            JoinChannelByName(CHANNEL)
        elseif JoinPermanentChannel then
            JoinPermanentChannel(CHANNEL)
        end
    end)
    if Compat and Compat.ChannelAPI and Compat.ChannelAPI.JoinChannel then
        pcall(function() Compat.ChannelAPI.JoinChannel(CHANNEL) end)
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
                print("|cff88ccffFrostNet:|r Connected to channel |cffffffff" .. CHANNEL .. "|r")
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
                print("|cff88ccffFrostNet:|r Connected to channel |cffffffff" .. CHANNEL .. "|r")
            end
        end
    else
        if self.isConnected then
            self.isConnected = false
            print("|cffff5555FrostNet:|r Disconnected from channel |cffffffff" .. CHANNEL .. "|r, will retry...")
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

    local function actuallySend()
        if not self.channelId then
            self:RefreshChannel()
        end
        if not self.channelId then
            return false, "no_channel"
        end
        local ok, err = pcall(function()
            SendChatMessage(message, "CHANNEL", nil, self.channelId)
        end)
        if not ok then
            debugLog("SendChatMessage error: " .. tostring(err))
            return false, "send_error"
        end
        return true
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
    if not self.channelId then
        if #self._queue >= 5 and not self._queueWarned then
            self._queueWarned = true
            print("|cffff5555FrostNet:|r Cannot reach channel |cffffffffFSK|r — " .. tostring(#self._queue) .. " messages queued. Run /fsdebug to check channel status.")
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
            local ok = pcall(function()
                SendChatMessage(message, "CHANNEL", nil, self.channelId)
            end)
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
        print("|cff88ccffFrostNet:|r Group published to channel |cffffffffFSK|r (" .. tostring(listing.activity or "?") .. ") |cff888888[id=" .. tostring(self.channelId) .. " len=" .. tostring(#msg) .. "]|r")
        self._lastSentListingId = listing.id
        self._lastSentEchoTime = GetTime()
        self._echoReceived = false
        local sentId = listing.id
        C_Timer.After(2, function()
            if Network._lastSentListingId == sentId and not Network._echoReceived then
                print("|cffff8800FrostNet:|r No loopback echo from server within 2s — the server may be dropping your messages. Run /fsnet to verify.")
            end
        end)
    else
        if not self.channelId then
            print("|cffff8800FrostNet:|r Channel not connected yet — your group is queued and will be published automatically when FSK reconnects.")
        else
            print("|cffff8800FrostNet:|r Group publish deferred (rate-limit), will retry in ~2s.")
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

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    if event == "PLAYER_LOGIN" then
        Network:JoinChannel()
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        local message, _, _, _, _, _, _, _, channelName = ...
        if message == "YOU_CHANGED" or message == "YOU_JOINED" or message == "CHANNEL_JOIN" or message == "CHANNEL_COUNT_UPDATE" then
            if channelName then
                local cnLower = string.lower(tostring(channelName))
                if cnLower == string.lower(CHANNEL) then
                    local newId = getChannelId(CHANNEL)
                    if newId then
                        local wasConnected = Network.isConnected
                        Network.channelId = newId
                        Network.isConnected = true
                        Network.joinAttempts = 0
                        if not wasConnected then
                            debugLog("FSK channel joined (id=" .. tostring(newId) .. ")")
                            Network:ScheduleRebroadcast()
                        end
                    end
                end
            end
            Network:RefreshChannel()
        end

    elseif event == "CHAT_MSG_CHANNEL" then
        local text, author, _, _, _, _, _, num, channelName = ...
        local isFSK = false
        if channelName and tostring(channelName) ~= "" then
            local cnLower = string.lower(tostring(channelName))
            if cnLower == string.lower(CHANNEL) then isFSK = true end
        end
        if not isFSK then
            if num and tonumber(num) == tonumber(Network.channelId) then
                isFSK = true
            end
        end
        if not isFSK and text then
            if string.sub(text, 1, 4) == "FSK1" then
                isFSK = true
            end
        end
        if isFSK then
            Network:HandleMessage(text, author)
        end

    elseif event == "CHANNEL_UI_UPDATE" then
        Network:RefreshChannel()
    end
end)

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
            if string.find(raw, sentId, 1, true) then
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
            Network:SendPong()
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
                FrostSeek.Listings:HandleDecision(target, result, activity)
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