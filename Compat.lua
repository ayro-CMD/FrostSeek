-- ============================================================
-- FrostSeek - Compatibility Layer
-- ============================================================

local MAJOR, MINOR = "FrostSeekCompat", 1
if LibStub and LibStub:GetLibrary(MAJOR, true) then return end

-- ==================== C_Timer Polyfill ====================

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
            timerFrame:SetScript("OnUpdate", timerFrame.OnUpdate)
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

-- ==================== Texture:SetColorTexture Polyfill ====================
local textureMt = getmetatable(CreateFrame("Frame"):CreateTexture())
if textureMt and not textureMt.__index.SetColorTexture then
    textureMt.__index.SetColorTexture = function(self, r, g, b, a)
        self:SetTexture(r, g, b)
        if a then self:SetAlpha(a) end
    end
end

-- ==================== Region:SetShown Polyfill ====================
-- Frame metatable
local frameMt = getmetatable(CreateFrame("Frame"))
if frameMt and not frameMt.__index.SetShown then
    frameMt.__index.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end

-- Texture metatable
local testFrame = CreateFrame("Frame")
local testTex = testFrame:CreateTexture()
local textureMt = getmetatable(testTex)
if textureMt and not textureMt.__index.SetShown then
    textureMt.__index.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end
testFrame = nil
testTex = nil

FrostSeekCompat = FrostSeekCompat or {}
FrostSeekCompat.hasBackdropTemplate = false


-- ==================== ASCENSION REALM DATABASE ====================
local ASCENSION_REALMS = {
    -- Classless realms
    ["area 52"]       = "classless",
    ["area52"]        = "classless",
    ["a52"]           = "classless",
    ["andorhal"]      = "classless",
    ["naladu"]        = "classless",
    ["thrall"]        = "classless",

    -- Seasonal classless
    ["elune"]         = "seasonal",

    -- Classic+ realm 
    ["bronzebeard"]   = "bronzebeard",

    -- Conquest of Azeroth
    ["conquest of azeroth"] = "coa",
    ["conquest"]      = "coa",
    ["coa"]           = "coa",
}

do
    local realmName = GetRealmName and GetRealmName() or ""
    local realmLower = string.lower(realmName)

    local detectedType = "vanilla"
    local isAsc = false
    local ascMode = nil

    -- Try exact match first
    if ASCENSION_REALMS[realmLower] then
        isAsc = true
        ascMode = ASCENSION_REALMS[realmLower]
    else
        -- Try partial match (realm name contains a known key)
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
        ascMode = "classless"   -- Mystic Enchants = classless-type realm
    end

    -- Finalize
    if isAsc then
        detectedType = "ascension"
    end

    FrostSeekCompat.serverType     = detectedType
    FrostSeekCompat.isAscension    = isAsc
    FrostSeekCompat.realmName      = realmName
    FrostSeekCompat.ascensionMode  = ascMode
end

-- ==================== Server Type Utility API ====================

--- Returns the raw realm name from GetRealmName().
function FrostSeekCompat.GetRealmName()
    return FrostSeekCompat.realmName or ""
end

--- Returns "ascension" or "vanilla".
function FrostSeekCompat.GetServerType()
    return FrostSeekCompat.serverType or "vanilla"
end

--- Returns true if running on any Ascension server.
function FrostSeekCompat.IsAscension()
    return FrostSeekCompat.isAscension == true
end

--- Returns true if running on a Vanilla server.
function FrostSeekCompat.IsVanilla()
    return not FrostSeekCompat.IsAscension()
end

--- Returns the Ascension realm type.
-- "classless"     = Free-pick abilities, HERO class, Mystic Enchants
-- "bronzebeard"   = Original 9 Classes + Classic+ content + Mystic Enchants
-- "coa"           = Conquest of Azeroth, custom classes, NO Mystic Enchants
-- "seasonal"      = Seasonal classless (draft/random abilities)
-- nil             = Not Ascension or unknown mode
function FrostSeekCompat.GetAscensionMode()
    return FrostSeekCompat.ascensionMode
end

--- Returns true if the server has Mystic Enchants (classless/bronzebeard).
function FrostSeekCompat.HasMysticEnchants()
    local mode = FrostSeekCompat.ascensionMode
    return mode == "classless" or mode == "bronzebeard" or mode == "seasonal"
end

--- Returns true if the server uses custom CoA classes.
function FrostSeekCompat.IsConquestOfAzeroth()
    return FrostSeekCompat.ascensionMode == "coa"
end

--- Returns a human-readable label for display.
function FrostSeekCompat.GetServerTypeLabel()
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
        return "Vanilla"
    end
end

--- Returns a color {r,g,b} for the server type (UI display).
function FrostSeekCompat.GetServerTypeColor()
    if FrostSeekCompat.IsAscension() then
        local mode = FrostSeekCompat.ascensionMode
        if mode == "coa" then
            return {0.85, 0.45, 0.15}   -- Orange for CoA
        elseif mode == "bronzebeard" then
            return {0.6, 0.5, 0.3}      -- Bronze for Bronzebeard
        else
            return {0.6, 0.3, 0.85}     -- Purple for classless/seasonal
        end
    else
        return {0.2, 0.75, 0.2}         -- Green for Vanilla
    end
end


do
    local testOk, testErr = pcall(function()
        local testFrame = CreateFrame("Frame", "FrostSeek_CompatTest", UIParent, "BackdropTemplate")
        testFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        FrostSeekCompat.hasBackdropTemplate = true
        testFrame:Hide()
        -- Remove from global
        _G["FrostSeek_CompatTest"] = nil
    end)
end

-- Utility
function FrostSeekCompat.GetBackdropTemplateStr()
    if FrostSeekCompat.hasBackdropTemplate then
        return "BackdropTemplate"
    end
    return ""
end

-- Print compatibility & server type
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

    print("|cff88ccffFrostSeek Compat:|r " ..
        (FrostSeekCompat.hasBackdropTemplate and "|cff00ff00BackdropTemplate: YES|r" or "|cffff8800BackdropTemplate: NO (native fallback)|r") ..
        " | " ..
        (C_Timer and "|cff00ff00C_Timer: OK|r" or "|cffff0000C_Timer: MISSING|r") ..
        " | " ..
        serverHex .. "Server: " .. serverLabel .. "|r" ..
        " | " ..
        "|cff00ff00Compat layer loaded|r"
    )
end)
