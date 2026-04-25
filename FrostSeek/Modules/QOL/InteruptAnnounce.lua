-- ============================================================
-- FrostSeek - Interrupt Announce Module
-- ============================================================

local FrostSeek = _G.FrostSeek
local InterruptAnnounce = {}

local interruptFrame = CreateFrame("Frame")

-- ==================== INIZIALIZZAZIONE DB ====================
local function InitDB()
    FrostSeekDB.InterruptAnnounce = FrostSeekDB.InterruptAnnounce or {}
    if FrostSeekDB.InterruptAnnounce.enabled == nil then
        FrostSeekDB.InterruptAnnounce.enabled = false
    end
    if FrostSeekDB.InterruptAnnounce.output == nil then
        FrostSeekDB.InterruptAnnounce.output = "Auto"
    end
    if FrostSeekDB.InterruptAnnounce.verbose == nil then
        FrostSeekDB.InterruptAnnounce.verbose = true
    end
    if FrostSeekDB.InterruptAnnounce.announceSelf == nil then
        FrostSeekDB.InterruptAnnounce.announceSelf = true
    end
end

-- ==================== REGISTRO MODULO ====================
local function RegisterModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterModule)
        return
    end
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("interruptannounce", InterruptAnnounce)
    end
end

-- ==================== FORMAT MESSAGGIO ====================
local function BuildMessage(destName, spellID, isSelf)
    local db = FrostSeekDB.InterruptAnnounce
    local spellLink = GetSpellLink(spellID) or tostring(spellID)
    local name = destName or "Unknown"

    if db.verbose then
        if isSelf then
            return "=> Interrupted: " .. name .. "'s " .. spellLink .. "."
        else
            return "=> " .. name .. "'s " .. spellLink .. " interrupted."
        end
    else
        return "Interrupted: " .. name .. "'s " .. spellLink .. "."
    end
end

-- ==================== INVIA MESSAGGIO ====================
local function SendMessage(msg)
    local db = FrostSeekDB.InterruptAnnounce
    local output = db.output

    if output == "Self" then
        -- non invia nulla, solo tooltip
        return
    end

    if output == "Auto" then
        if GetNumRaidMembers() >= 1 then
            SendChatMessage(msg, "RAID")
        elseif GetNumPartyMembers() >= 1 then
            SendChatMessage(msg, "PARTY")
        else
            return
        end
    elseif output == "Say" then
        SendChatMessage(msg, "SAY")
    elseif output == "Party" then
        if GetNumPartyMembers() >= 1 then
            SendChatMessage(msg, "PARTY")
        end
    elseif output == "Raid" then
        if GetNumRaidMembers() >= 1 then
            SendChatMessage(msg, "RAID")
        end
    end
end

-- ==================== COMBAT LOG EVENT ====================
interruptFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local db = FrostSeekDB.InterruptAnnounce
        if not db or not db.enabled then return end

        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID = CombatLogGetCurrentEventInfo()

        if combatEvent ~= "SPELL_INTERRUPT" then return end

        local isSelf = sourceName and sourceName == UnitName("player")

        if not isSelf and not db.announceSelf then return end
        if not isSelf then return end

        local _, interruptSpellID = select(4, CombatLogGetCurrentEventInfo())
        local intSpellLink = GetSpellLink(interruptSpellID) or ""
        local msg

        if db.verbose then
            msg = "=> Interrupted: " .. (destName or "Unknown") .. "'s " .. intSpellLink .. "."
        else
            msg = "Interrupted: " .. (destName or "Unknown") .. "'s " .. intSpellLink .. "."
        end

        SendMessage(msg)

    end
end)

interruptFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- ==================== AVVIO ====================
InitDB()
RegisterModule()