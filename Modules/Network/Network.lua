-- FrostSeek Network Module

local FrostSeek = _G.FrostSeek

local Network = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("network", Network)

local CHANNEL = "FSK"
local BLFG_CHANNEL = "BLFG"
local PROTOCOL = FrostSeek and FrostSeek.Protocol

Network.channelId = nil
Network.blfgChannelId = nil
Network.channelName = CHANNEL
Network.blfgChannelName = BLFG_CHANNEL
Network.isConnected = false
Network.isBLFGConnected = false
Network.joinAttempts = 0
Network.maxJoinAttempts = 10
Network.lastJoinAttempt = 0

local function getChannelIdByName(channelName)
    if not channelName then return nil end
    local targetLower = string.lower(channelName)

    for i = 1, 20 do
        local name = GetChannelName(i)
        if name and tostring(name) ~= "" and string.lower(tostring(name)) == targetLower then
            return i
        end
    end

    for i = 1, GetNumDisplayChannels() do
        local name, _, _, channelNumber = GetChannelDisplayInfo(i)
        if name and string.lower(tostring(name)) == targetLower then
            if channelNumber then return channelNumber end
            for j = 1, 20 do
                local chName = GetChannelName(j)
                if chName and string.lower(tostring(chName)) == targetLower then
                    return j
                end
            end
        end
    end

    return nil
end

function Network:JoinChannel()
    if self.isConnected and self.channelId then return end

    local now = GetTime()
    if now - self.lastJoinAttempt < 5 then return end
    self.lastJoinAttempt = now
    self.joinAttempts = self.joinAttempts + 1

    JoinChannelByName(CHANNEL, nil)
    C_Timer.After(3, function()
        self.channelId = getChannelIdByName(CHANNEL)
        if self.channelId then
            self.isConnected = true
            self.joinAttempts = 0
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
        LeaveChannelByName(CHANNEL)
        self.channelId = nil
        self.isConnected = false
    end
end

function Network:RefreshChannel()
    local newId = getChannelIdByName(CHANNEL)
    if newId then
        self.channelId = newId
        self.isConnected = true
    else
        if not self.isConnected then
            self:JoinChannel()
        end
    end
end

function Network:JoinBLFGChannel()
    if self.isBLFGConnected and self.blfgChannelId then return end

    JoinChannelByName(BLFG_CHANNEL, nil)
    C_Timer.After(4, function()
        self.blfgChannelId = getChannelIdByName(BLFG_CHANNEL)
        if self.blfgChannelId then
            self.isBLFGConnected = true
        else
            self.isBLFGConnected = false
            C_Timer.After(10, function()
                if not self.blfgChannelId then
                    self.blfgChannelId = getChannelIdByName(BLFG_CHANNEL)
                    self.isBLFGConnected = self.blfgChannelId ~= nil
                end
            end)
        end
    end)
end

function Network:RefreshBLFGChannel()
    local newId = getChannelIdByName(BLFG_CHANNEL)
    if newId then
        self.blfgChannelId = newId
        self.isBLFGConnected = true
    end
end


function Network:Send(message)
    if not message or message == "" then return false end
    if not PROTOCOL then
        PROTOCOL = FrostSeek and FrostSeek.Protocol
        if not PROTOCOL then return false end
    end
    if PROTOCOL.IsAddonSpam and PROTOCOL:IsAddonSpam(message) then return false end

    local sentFSK = false
    if self.isConnected and self.channelId then
        local ok, err = pcall(function()
            SendChatMessage(message, "CHANNEL", nil, self.channelId)
        end)
        sentFSK = ok
    else
        self:RefreshChannel()
        if self.channelId then
            local ok, err = pcall(function()
                SendChatMessage(message, "CHANNEL", nil, self.channelId)
            end)
            sentFSK = ok
        end
    end

    local sentBLFG = false
    if self.isBLFGConnected and self.blfgChannelId then
        PROTOCOL:MarkProcessed(message)
        local ok, err = pcall(function()
            SendChatMessage(message, "CHANNEL", nil, self.blfgChannelId)
        end)
        sentBLFG = ok
    end

    return sentFSK or sentBLFG
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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHANNEL_UI_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    if event == "PLAYER_LOGIN" then
        C_Timer.After(3, function()
            Network:JoinChannel()
            C_Timer.After(5, function()
                Network:JoinBLFGChannel()
            end)
        end)

    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        local message, _, _, _, _, _, _, _, channelName = ...
        if not channelName then return end
        local cnLower = string.lower(tostring(channelName))
        if message == "YOU_CHANGED" or message == "CHANNEL_JOIN" or message == "CHANNEL_COUNT_UPDATE" then
            if cnLower == string.lower(CHANNEL) then
                local newId = getChannelIdByName(CHANNEL)
                if newId then
                    Network.channelId = newId
                    Network.isConnected = true
                    Network.joinAttempts = 0
                end
            elseif cnLower == string.lower(BLFG_CHANNEL) then
                local newId = getChannelIdByName(BLFG_CHANNEL)
                if newId then
                    Network.blfgChannelId = newId
                    Network.isBLFGConnected = true
                end
            end
        end

    elseif event == "CHAT_MSG_CHANNEL" then
        local text, author, _, _, _, _, _, num, channelName = ...

        local isFSK = false
        local isBLFG = false

        if channelName and tostring(channelName) ~= "" then
            local cnLower = string.lower(tostring(channelName))
            if cnLower == string.lower(CHANNEL) then isFSK = true end
            if cnLower == string.lower(BLFG_CHANNEL) then isBLFG = true end
        end

        if not isFSK and not isBLFG then
            if num and tonumber(num) == tonumber(Network.channelId) then
                isFSK = true
            elseif num and tonumber(num) == tonumber(Network.blfgChannelId) then
                isBLFG = true
            end
        end

        if isFSK or isBLFG then
            Network:HandleMessage(text, author)
        end

    elseif event == "CHANNEL_UI_UPDATE" then
        Network:RefreshChannel()
        Network:RefreshBLFGChannel()
    end
end)

function Network:HandleMessage(raw, author)
    if not PROTOCOL then
        PROTOCOL = FrostSeek and FrostSeek.Protocol
        if not PROTOCOL then return end
    end

    if PROTOCOL.IsDuplicate and PROTOCOL:IsDuplicate(raw) then
        return
    end

    local msgType, parts, source = PROTOCOL.Parse(raw)
    if not msgType or not parts then return end

    if PROTOCOL.MarkProcessed then
        PROTOCOL:MarkProcessed(raw)
    end

    local pn = UnitName("player") or ""
    if author and tostring(author) == pn then return end

    if source == "BLFG" then
        if msgType == "LIST" then
            local listing = PROTOCOL.ConvertBLFGListing(parts)
            if listing and PROTOCOL.IsValidListing(listing) then
                if FrostSeek.Listings and FrostSeek.Listings.HandleIncomingListing then
                    FrostSeek.Listings:HandleIncomingListing(listing)
                end
                if FrostSeek.LFG and FrostSeek.LFG.RecordFromListing then
                    FrostSeek.LFG.RecordFromListing(listing)
                end
            end
            return

        elseif msgType == "PING" then
            local user = PROTOCOL.ConvertBLFGPresence(parts)
            if user and user.name and user.name ~= "" and user.name ~= pn then
                if FrostSeek.Presence and FrostSeek.Presence.HandlePresence then
                    FrostSeek.Presence:HandlePresence(user)
                end
            end
            return

        elseif msgType == "APP" then
            local applicant = PROTOCOL.ConvertBLFGApplicant(parts)
            if applicant and PROTOCOL.IsValidApplicant(applicant) then
                if FrostSeek.Listings and FrostSeek.Listings.HandleIncomingApplicant then
                    FrostSeek.Listings:HandleIncomingApplicant(applicant)
                end
            end
            return

        elseif msgType == "REMOVE" then
            local listingId = parts[3]
            if listingId then
                if FrostSeek.Listings and FrostSeek.Listings.HandleRemove then
                    FrostSeek.Listings:HandleRemove(listingId)
                end
            end
            return

        elseif msgType == "DECISION" then
            local target, result, activity = parts[3], parts[4], parts[5] or "group"
            if target then
                if FrostSeek.Listings and FrostSeek.Listings.HandleDecision then
                    FrostSeek.Listings:HandleDecision(target, result, activity)
                end
            end
            return
        end
        return
    end

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
                FrostSeek.LFG.RecordFromListing(listing)
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
        blfgConnected = self.isBLFGConnected,
        blfgChannelId = self.blfgChannelId,
        blfgChannel = self.blfgChannelName,
    }
end

function Network:GetOnlineCount()
    if FrostSeek.Presence and FrostSeek.Presence.GetOnlineCount then
        return FrostSeek.Presence:GetOnlineCount()
    end
    return 0
end

FrostSeek.Network = Network

local FROSTSEEK_SIG = "FSK-" .. string.char(70,82,79,83,84) .. "-" .. "0x4FSK7"
