-- ============================================================
-- FrostSeek - Boss Announce Module
-- ============================================================

local BossAnnounce = {}

-- ==================== STATO INTERNO ====================
local bossName = nil
local startTime = 0
local isFighting = false
local announcedHealth = {}
local bossEventFrame = nil
local healthCheckTicker = nil

-- ==================== FUNZIONE HELPER: INVIA ANNUNCIO ====================
local function SendAnnouncement(message)
    local db = FrostSeekDB and FrostSeekDB.BossAnnounce
    if not db then return end

    if db.announceParty and (IsInGroup() and not IsInRaid()) then
        SendChatMessage(message, "PARTY")
    end

    if db.announceRaid and IsInRaid() then
        SendChatMessage(message, "RAID")
    end

    if db.announceGuild and IsInGuild() then
        SendChatMessage(message, "GUILD")
    end
end

-- ==================== FORMATTAZIONE TIMER ====================
local function FormatDuration(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- ==================== REGISTRAZIONE EVENTI BOSS ====================
local function RegisterBossEvents()
    if bossEventFrame then return end

    bossEventFrame = CreateFrame("Frame")
    bossEventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    bossEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    bossEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    bossEventFrame:SetScript("OnEvent", function(self, event, ...)
        BossAnnounce:OnEvent(event, ...)
    end)
end

-- ==================== AVVIA HEALTH CHECK ====================
local function StartHealthCheck()
    if healthCheckTicker then healthCheckTicker:Cancel() end

    healthCheckTicker = C_Timer.NewTicker(0.5, function()
        if not isFighting then
            healthCheckTicker:Cancel()
            healthCheckTicker = nil
            return
        end

        local db = FrostSeekDB and FrostSeekDB.BossAnnounce
        if not db or not db.enabled or db.minBossHealth <= 0 then return end

        for i = 1, 5 do
            local unit = "boss" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name and not announcedHealth[name] then
                    local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
                    if healthPct <= db.minBossHealth then
                        announcedHealth[name] = true
                        SendAnnouncement("!! " .. name .. " below " .. db.minBossHealth .. "% HP !!")

                        if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
                            print("|cff88ccff[BossAnnounce]|r Health alert: " .. name .. " at " .. string.format("%.1f", healthPct) .. "%")
                        end
                    end
                end
            end
        end
    end)
end

-- ==================== RESET STATO COMBATTIMENTO ====================
local function ResetFightState()
    bossName = nil
    startTime = 0
    isFighting = false
    announcedHealth = {}
end

-- ==================== GESTIONE EVENTO PRINCIPALE ====================
function BossAnnounce:OnEvent(event, ...)
    local db = FrostSeekDB and FrostSeekDB.BossAnnounce
    if not db or not db.enabled then return end

    -- Controlla se siamo in istanza (se richiesto)
    if db.announceOnlyInInstance then
        local _, instanceType = GetInstanceInfo()
        if instanceType ~= "party" and instanceType ~= "raid" then return end
    end

    -- Cerca un boss attivo
    local currentBoss = nil
    for i = 1, 5 do
        if UnitExists("boss" .. i) then
            currentBoss = UnitName("boss" .. i)
            break
        end
    end

    -- ==================== INIZIO COMBATTIMENTO ====================
    if (event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "PLAYER_REGEN_DISABLED") then
        if currentBoss and not isFighting then
            bossName = currentBoss
            startTime = GetTime()
            isFighting = true
            announcedHealth = {}

            local msg = "Boss fight: " .. bossName
            SendAnnouncement(msg)

            if db.playSound then
                PlaySound("RaidWarning")
            end

            if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
                print("|cff88ccff[BossAnnounce]|r Boss START: " .. bossName)
            end

            -- Avvia controllo salute se necessario
            if db.minBossHealth and db.minBossHealth > 0 then
                StartHealthCheck()
            end
        end
    end

    -- ==================== FINE COMBATTIMENTO (BOSS MORTO) ====================
    if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and not currentBoss and isFighting then
        local duration = GetTime() - startTime
        local timeStr = FormatDuration(duration)

        local msg = "Boss fight end: " .. bossName
        if db.showTimer then
            msg = msg .. " (" .. timeStr .. ")"
        end
        SendAnnouncement(msg)

        if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
            print("|cff88ff88[BossAnnounce]|r Boss DOWN: " .. bossName .. " (" .. timeStr .. ")")
        end

        ResetFightState()
    end

    -- ==================== USCITA DAL COMBATTIMENTO (WIPE) ====================
    if event == "PLAYER_REGEN_ENABLED" and not currentBoss then
        if isFighting then
            local duration = GetTime() - startTime
            local timeStr = FormatDuration(duration)

            -- Non annunciare il wipe, solo reset
            if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
                print("|cffff4444[BossAnnounce]|r Wipe on " .. (bossName or "Unknown") .. " (" .. timeStr .. ")")
            end
        end
        ResetFightState()
    end
end

-- ==================== MODULE INTERFACE ====================
function BossAnnounce:Initialize(parentFrame)
    -- Assicura struttura DB
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.BossAnnounce then
        FrostSeekDB.BossAnnounce = {
            enabled = false,
            announceParty = true,
            announceRaid = false,
            announceGuild = false,
            showTimer = true,
            minBossHealth = 50,
            playSound = true,
            announceTrash = false,
            announceOnlyInInstance = true,
        }
    end

    -- Crea il frame del modulo
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", self.frame, "TOP", 0, -20)
    self.title:SetText("|cff88ccffBoss Announce|r")

    self.desc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -10)
    self.desc:SetText("Automatic boss fight announcements")
    self.desc:SetTextColor(0.8, 0.8, 0.8)

    -- Status display
    self.statusFrame = CreateFrame("Frame", nil, self.frame)
    self.statusFrame:SetSize(400, 120)
    self.statusFrame:SetPoint("CENTER", self.frame, "CENTER", 0, -30)

    local statusBg = self.statusFrame:CreateTexture(nil, "BACKGROUND")
    statusBg:SetAllPoints()
    statusBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)

    local statusTitle = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusTitle:SetPoint("TOP", self.statusFrame, "TOP", 0, -10)
    statusTitle:SetText("Boss Announce Status")
    statusTitle:SetTextColor(1, 1, 1)

    self.statusText = self.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.statusText:SetPoint("TOP", statusTitle, "BOTTOM", 0, -10)
    self.statusText:SetTextColor(0.9, 0.9, 0.9)

    -- Registra gli eventi
    RegisterBossEvents()

    -- Se abilitato nel DB, stampa conferma
    if FrostSeekDB.BossAnnounce.enabled then
        print("|cff88ccff[BossAnnounce]|r Loaded and |cff00ff00ENABLED|r")
    else
        print("|cff88ccff[BossAnnounce]|r Loaded (disabled - enable in Options)")
    end

    self.frame:Hide()
end

function BossAnnounce:Show()
    if self.frame then
        -- Aggiorna stato
        if self.statusText then
            local db = FrostSeekDB and FrostSeekDB.BossAnnounce
            if db and db.enabled then
                local channels = {}
                if db.announceParty then table.insert(channels, "Party") end
                if db.announceRaid then table.insert(channels, "Raid") end
                if db.announceGuild then table.insert(channels, "Guild") end

                local chStr = #channels > 0 and table.concat(channels, ", ") or "None"
                local timerStr = db.showTimer and "ON" or "OFF"
                local soundStr = db.playSound and "ON" or "OFF"

                self.statusText:SetText(
                    "Status: |cFF00FF00Active|r\n" ..
                    "Channels: " .. chStr .. "\n" ..
                    "Timer: " .. timerStr .. "  |  Sound: " .. soundStr
                )
            else
                self.statusText:SetText("Status: |cFFFF0000Disabled|r")
            end
        end
        self.frame:Show()
    end
end

function BossAnnounce:Hide()
    if self.frame then self.frame:Hide() end
end

function BossAnnounce:Enable()
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.BossAnnounce then FrostSeekDB.BossAnnounce = {} end
    FrostSeekDB.BossAnnounce.enabled = true
    RegisterBossEvents()
    print("|cff88ccff[BossAnnounce]|r |cff00ff00Enabled|r")
end

function BossAnnounce:Disable()
    if FrostSeekDB and FrostSeekDB.BossAnnounce then
        FrostSeekDB.BossAnnounce.enabled = false
    end
    ResetFightState()
    print("|cff88ccff[BossAnnounce]|r |cffff0000Disabled|r")
end

function BossAnnounce:SendTestAnnouncement()
    local db = FrostSeekDB and FrostSeekDB.BossAnnounce
    if not db then
        print("|cff88ccff[BossAnnounce]|r No configuration found")
        return
    end

    local msg = "[TEST] Boss fight: TestBoss (00:00)"
    if db.showTimer then
        msg = "[TEST] Boss fight: TestBoss (00:42)"
    end
    SendAnnouncement(msg)

    if db.playSound then
        PlaySound("RaidWarning", "master")
    end

    print("|cff88ccff[BossAnnounce]|r Test announcement sent!")
end

-- ==================== REGISTRAZIONE MODULO ====================
if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("bossannounce", BossAnnounce)
end
