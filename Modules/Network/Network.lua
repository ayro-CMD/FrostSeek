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
Network.joinAttempts = 0
Network.maxJoinAttempts = 10
Network.lastJoinAttempt = 0
Network.lastSendTime = 0

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
            self.isConnected = true
            self.joinAttempts = 0
            if Shared then Shared.PlaySound("connect") end
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
        self.isConnected = true
    else
        if not self.isConnected then
            self:JoinChannel()
        end
    end
end

function Network:Send(message)
    if not message or message == "" then return false end
    if not PROTOCOL then
        PROTOCOL = FrostSeek and FrostSeek.Protocol
        if not PROTOCOL then return false end
    end
    if PROTOCOL.IsAddonSpam and PROTOCOL:IsAddonSpam(message) then return false end
    if #message > (Shared and Shared.MAX_MESSAGE_LENGTH or 240) then
        message = string.sub(message, 1, Shared and Shared.MAX_MESSAGE_LENGTH or 240)
    end
    local rateLimit = Shared and Shared.MAX_SEND_RATE or 1.0
    local now = GetTime()
    if (now - self.lastSendTime) < rateLimit then return false end
    PROTOCOL:MarkProcessed(message)
    self.lastSendTime = now
    local sent = false
    if self.isConnected and self.channelId then
        local ok = pcall(function() SendChatMessage(message, "CHANNEL", nil, self.channelId) end)
        sent = ok
    else
        self:RefreshChannel()
        if self.channelId then
            local ok = pcall(function() SendChatMessage(message, "CHANNEL", nil, self.channelId) end)
            sent = ok
        end
    end
    return sent
end

function Network:SendListing(listing)
    if not PROTOCOL then return false end
    local msg = PROTOCOL.SerializeListing(listing)
    if not msg then return false end
    return self:Send(msg)
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

C_Timer.NewTicker(10, function()
    Network:RefreshChannel()
end)

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
                        Network.channelId = newId
                        Network.isConnected = true
                        Network.joinAttempts = 0
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
    if PROTOCOL.IsDuplicate and PROTOCOL:IsDuplicate(raw) then return end
    local msgType, parts = PROTOCOL.Parse(raw)
    if not msgType or not parts then return end
    if PROTOCOL.MarkProcessed then
        PROTOCOL:MarkProcessed(raw)
    end
    local pn = UnitName("player") or ""
    local authorClean = author and tostring(author) or ""
    if string.find(authorClean, "-", 1, true) then
        authorClean = string.sub(authorClean, 1, string.find(authorClean, "-", 1, true) - 1)
    end
    if authorClean == pn then return end

    if msgType == PROTOCOL.MSG_TYPES.PING then
        local user = PROTOCOL.ParsePresence(parts)
        if user and user.name and user.name ~= "" and user.name ~= pn then
            if FrostSeek.Presence and FrostSeek.Presence.HandlePresence then
                FrostSeek.Presence:HandlePresence(user)
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
    }
end

function Network:GetOnlineCount()
    if FrostSeek.Presence and FrostSeek.Presence.GetOnlineCount then
        return FrostSeek.Presence:GetOnlineCount()
    end
    return 0
end

FrostSeek.Network = Network
