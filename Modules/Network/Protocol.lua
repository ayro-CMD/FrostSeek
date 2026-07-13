local FrostSeek = _G.FrostSeek

local Protocol = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("protocol", Protocol)

local PREFIX = "FSK1"
local SEP = "~"

Protocol.MSG_TYPES = {
    LIST = "LIST",
    APP = "APP",
    PING = "PING",
    PONG = "PONG",
    REMOVE = "REMOVE",
    DECISION = "DECISION",
}

Protocol._dedupCache = {}
Protocol._dedupMaxAge = 120
Protocol._lastCleanup = 0
Protocol.MAX_WIRE = 250

local function clean(s)
    s = tostring(s or "")
    s = string.gsub(s, SEP, " ")
    s = string.gsub(s, "\n", " ")
    s = string.gsub(s, "\r", "")
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|H[^|]+|h", "")
    s = string.gsub(s, "|h", "")
    return s
end

local function split(str)
    local t = {}
    str = tostring(str or "")
    local start = 1
    while true do
        local pos = string.find(str, SEP, start, true)
        if not pos then
            table.insert(t, string.sub(str, start))
            break
        end
        table.insert(t, string.sub(str, start, pos - 1))
        start = pos + 1
    end
    return t
end

local function now()
    return time()
end

local function playerName()
    local n = UnitName("player")
    return n or ""
end

local function playerClass()
    local Shared = _G.FrostSeekShared
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end
    classFile = classFile or "WARRIOR"
    return classFile, classFile
end

local function playerLevel()
    return tostring(UnitLevel("player") or 60)
end

local function DedupKey(raw)
    if not raw then return nil end
    local stripped = raw
    if string.sub(stripped, 1, string.len(PREFIX)) == PREFIX then
        stripped = string.sub(stripped, string.len(PREFIX) + 1)
    end
    local parts = split(stripped)
    if parts and parts[2] == Protocol.MSG_TYPES.LIST and #parts >= 11 then
        return parts[2] .. SEP .. (parts[3] or "") .. SEP .. (parts[11] or "")
    end
    return string.sub(stripped, 1, 80)
end

local function CleanupDedupCache()
    local t = now()
    for k, v in pairs(Protocol._dedupCache) do
        if (t - v) > Protocol._dedupMaxAge then
            Protocol._dedupCache[k] = nil
        end
    end
    Protocol._lastCleanup = t
end

function Protocol:IsDuplicate(raw)
    local key = DedupKey(raw)
    if not key then return false end
    local entry = Protocol._dedupCache[key]
    if entry and (now() - entry) < Protocol._dedupMaxAge then
        return true
    end
    return false
end

function Protocol:MarkProcessed(raw)
    local key = DedupKey(raw)
    if key then
        Protocol._dedupCache[key] = now()
    end
    local t = now()
    if (t - Protocol._lastCleanup) > 30 then
        CleanupDedupCache()
    end
end

function Protocol.SerializeListing(l)
    if not l or not l.id then return nil end

    local header = {
        PREFIX,
        Protocol.MSG_TYPES.LIST,
        clean(l.id),
        clean(l.activity or ""),
        clean(l.type or "Dungeon"),
        clean(l.difficulty or ""),
        clean(l.leader or playerName()),
        clean(l.roles or ""),
        clean(l.minItemLevel or ""),
        clean(l.maxMembers or "5"),
        clean(l.members or "1"),
        clean(l.voice or "None"),
        clean(l.loot or "Group Loot"),
    }
    local trailer = {
        clean(l.key or ""),
        tostring(l.created or now()),
        tostring(l.seen or now()),
    }

    local noteStr = clean(l.note or "")

    local function buildMsg(note)
        local parts = {}
        for i = 1, #header do parts[#parts + 1] = header[i] end
        parts[#parts + 1] = note
        for i = 1, #trailer do parts[#parts + 1] = trailer[i] end
        return table.concat(parts, SEP)
    end

    local msg = buildMsg(noteStr)
    while #msg > Protocol.MAX_WIRE and #noteStr > 0 do
        noteStr = string.sub(noteStr, 1, #noteStr - 1)
        msg = buildMsg(noteStr)
    end

    if #msg > Protocol.MAX_WIRE then
        msg = string.sub(msg, 1, Protocol.MAX_WIRE)
    end
    return msg
end

function Protocol.ParseListing(p)
    if not p or #p < 16 then return nil end
    return {
        id = p[3],
        activity = p[4],
        type = p[5],
        difficulty = p[6],
        leader = p[7],
        roles = p[8],
        minItemLevel = p[9],
        maxMembers = tonumber(p[10]) or 5,
        members = tonumber(p[11]) or 1,
        voice = p[12],
        loot = p[13],
        note = p[14],
        key = p[15],
        created = tonumber(p[16]) or now(),
        seen = tonumber(p[17]) or now(),
    }
end

function Protocol.SerializeApplicant(listingId, a)
    if not listingId or not a or not a.name then return nil end
    return table.concat({
        PREFIX,
        Protocol.MSG_TYPES.APP,
        clean(listingId),
        clean(a.name),
        clean(a.class or ""),
        clean(a.classFile or ""),
        clean(a.level or ""),
        clean(a.role or "DPS"),
        clean(a.itemLevel or ""),
        clean(a.roleType or ""),
        clean(a.discord or "No"),
        clean(a.note or ""),
        tostring(a.applied or now()),
    }, SEP)
end

function Protocol.ParseApplicant(p)
    if not p or #p < 10 then return nil end
    return {
        listingId = p[3],
        name = p[4],
        class = p[5],
        classFile = p[6],
        level = p[7],
        role = p[8],
        itemLevel = p[9],
        roleType = p[10],
        discord = p[11] or "No",
        note = p[12] or "",
        applied = tonumber(p[13]) or now(),
    }
end

function Protocol.SerializePresence(version, role, spec)
    local _, classFile = playerClass()
    local guildName = GetGuildInfo("player") or ""
    local zone = GetRealZoneText() or ""
    local status = "Online"
    if FrostSeekDB and FrostSeekDB.Profile and FrostSeekDB.Profile.status then
        status = FrostSeekDB.Profile.status
    end
    return table.concat({
        PREFIX,
        Protocol.MSG_TYPES.PING,
        clean(playerName()),
        clean(version or ""),
        clean(playerLevel()),
        clean(classFile or ""),
        clean(role or ""),
        clean(zone),
        clean(guildName),
        tostring(now()),
        clean(spec or ""),
        clean(status),
    }, SEP)
end

function Protocol.ParsePresence(p)
    if not p or #p < 8 then return nil end
    return {
        name = p[3],
        version = p[4],
        level = p[5],
        classFile = p[6],
        role = p[7],
        zone = p[8] or "",
        guild = p[9] or "",
        seen = tonumber(p[10]) or now(),
        spec = p[11] or "",
        status = p[12] or "Online",
    }
end

function Protocol.SerializeRemove(listingId)
    return table.concat({ PREFIX, Protocol.MSG_TYPES.REMOVE, clean(listingId) }, SEP)
end

function Protocol.SerializePong()
    return table.concat({
        PREFIX,
        Protocol.MSG_TYPES.PONG,
        clean(playerName()),
        tostring(now()),
    }, SEP)
end

function Protocol.ParsePong(p)
    if not p or #p < 3 then return nil end
    return {
        name = p[3],
        seen = tonumber(p[4]) or now(),
    }
end

function Protocol.SerializeDecision(target, result, activity)
    return table.concat({ PREFIX, Protocol.MSG_TYPES.DECISION, clean(target), clean(result), clean(activity) }, SEP)
end

function Protocol.Parse(raw)
    if not raw or type(raw) ~= "string" then return nil, nil end
    if string.sub(raw, 1, string.len(PREFIX)) == PREFIX then
        local parts = split(raw)
        if parts and #parts >= 2 and parts[1] == PREFIX then
            local msgType = parts[2]
            return msgType, parts
        end
    end
    return nil, nil
end

function Protocol:IsAddonSpam(text)
    if not text or type(text) ~= "string" then return true end
    local s = text
    local ls = string.lower(s)
    if string.sub(s, 1, string.len(PREFIX)) == PREFIX then return false end
    if string.sub(s, 1, 3) == "LC1" then return true end
    if string.sub(s, 1, 3) == "LC2" then return true end
    if string.sub(s, 1, 3) == "LC3" then return true end
    if string.find(ls, "lc1:conf", 1, true) then return true end
    if string.find(ls, "lc2:conf", 1, true) then return true end
    if string.find(ls, "lc3:conf", 1, true) then return true end
    if string.find(ls, "conf:", 1, true) then return true end
    if string.find(s, "^%u%u%d*:") then return true end
    if string.find(s, "^LC") and string.len(s) > 20 then return true end
    if not string.find(s, " ", 1, true) and string.len(s) > 35 then return true end
    return false
end

function Protocol.IsValidListing(l)
    if not l then return false end
    if not l.id or l.id == "" then return false end
    if not l.activity or l.activity == "" then return false end
    if not l.leader or l.leader == "" then return false end
    return true
end

function Protocol.IsValidApplicant(a)
    if not a then return false end
    if not a.name or a.name == "" then return false end
    if not a.listingId or a.listingId == "" then return false end
    return true
end

function Protocol.GenerateId()
    if not Protocol._seeded then
        Protocol._seeded = true
        pcall(function()
            math.randomseed(time() + math.floor(GetTime() * 1000))
            for _ = 1, 3 do math.random() end
        end)
    end
    local pn = (UnitName and UnitName("player")) or "x"
    return "fsk_" .. tostring(pn) .. "_" .. tostring(math.random(100000, 999999)) .. "_" .. tostring(now()) .. "_" .. tostring(math.floor((GetTime and GetTime() or 0) * 1000) % 100000)
end

Protocol.PREFIX = PREFIX
Protocol.clean = clean
Protocol.split = split

FrostSeek.Protocol = Protocol
