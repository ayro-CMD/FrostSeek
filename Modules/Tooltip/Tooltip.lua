-- ============================================================
-- FrostSeek - Tooltip iLvl & GearScore
-- ============================================================

local FrostSeek = _G.FrostSeek

local Tooltip = {}

-- ==================== ILVL CACHE ====================
local ilvlCache = {}
local cacheExpiry = 300

-- ==================== GEARSCORE CONSTANTS ====================
local GS_SLOT_WEIGHTS = {
    [1]  = 1.0000, -- Head
    [2]  = 0.5625, -- Neck
    [3]  = 0.7500, -- Shoulder
    [5]  = 1.0000, -- Chest
    [6]  = 0.7500, -- Waist
    [7]  = 1.0000, -- Legs
    [8]  = 0.7500, -- Feet
    [9]  = 0.5625, -- Wrist
    [10] = 0.7500, -- Hands
    [11] = 0.5625, -- Finger1
    [12] = 0.5625, -- Finger2
    [13] = 0.5625, -- Trinket1
    [14] = 0.5625, -- Trinket2
    [15] = 0.5625, -- Back/Cloak
    [16] = 1.0000, -- Main Hand
    [17] = 0.5625, -- Off Hand (shield/offhand)
    [18] = 0.3164, -- Ranged/Relic
}

-- Quality modifiers
local GS_QUALITY_MULT = {
    [0] = 0,     -- Poor (gray)
    [1] = 0,     -- Common (white)
    [2] = 1.0,   -- Uncommon (green)
    [3] = 1.0,   -- Rare (blue)
    [4] = 1.0,   -- Epic (purple)
    [5] = 1.3,   -- Legendary (orange)
    [6] = 0,     -- Artifact
    [7] = 1.0,   -- Heirloom
}

local GS_SCALE = 2.5
local GS_ILVL_BASE = 70

-- ==================== GEARSCORE COLOR THRESHOLDS ====================
local GS_COLOR_THRESHOLDS = {
    { min = 5000, r = 0.95, g = 0.30, b = 0.30 },  -- Red (very high)
    { min = 4500, r = 1.00, g = 0.50, b = 0.20 },  -- Orange (high)
    { min = 3800, r = 1.00, g = 0.85, b = 0.20 },  -- Yellow (good)
    { min = 3000, r = 0.30, g = 1.00, b = 0.30 },  -- Green (decent)
    { min = 2000, r = 0.30, g = 0.75, b = 1.00 },  -- Blue (average)
    { min = 0,    r = 0.60, g = 0.60, b = 0.60 },   -- Gray (low)
}

-- ==================== CALCULATE ITEM LEVEL ====================
local function CalculatePlayerItemLevel(unit)
    if not unit then return nil end

    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then -- exclude shirt slot
            local itemLink = GetInventoryItemLink(unit, i)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel and itemLevel > 0 then
                    sum = sum + itemLevel
                    count = count + 1
                end
            end
        end
    end

    if count > 0 then
        return math.floor((sum / count) + 0.5)
    end
    return nil
end

-- ==================== CALCULATE GEARSCORE ====================
local function CalculatePlayerGearScore(unit)
    if not unit then return nil end

    local totalScore = 0
    local itemCount = 0

    for slot = 1, 18 do
        if slot ~= 4 then -- skip shirt slot
            local itemLink = GetInventoryItemLink(unit, slot)
            if itemLink then
                local _, _, itemRarity, itemLevel = GetItemInfo(itemLink)
                if itemLevel and itemRarity then
                    local qualityMult = GS_QUALITY_MULT[itemRarity] or 0
                    if qualityMult > 0 and itemLevel > GS_ILVL_BASE then
                        local slotWeight = GS_SLOT_WEIGHTS[slot] or 0.5625
                        local itemScore = (itemLevel - GS_ILVL_BASE) * GS_SCALE * slotWeight * qualityMult
                        totalScore = totalScore + itemScore
                        itemCount = itemCount + 1
                    end
                end
            end
        end
    end

    if itemCount > 0 then
        return math.floor(totalScore + 0.5)
    end
    return nil
end

-- ==================== GET GEARSCORE COLOR ====================
local function GetGearScoreColor(gs)
    if not gs or gs <= 0 then
        return 0.6, 0.6, 0.6
    end
    for _, threshold in ipairs(GS_COLOR_THRESHOLDS) do
        if gs >= threshold.min then
            return threshold.r, threshold.g, threshold.b
        end
    end
    return 0.6, 0.6, 0.6
end

-- ==================== GET CACHED ILVL & GS ====================
local function GetCachedIlvl(unitName)
    if not unitName then return nil end
    local cached = ilvlCache[unitName]
    if cached then
        if (time() - cached.timestamp) < cacheExpiry then
            return cached.ilvl, cached.gs
        else
            ilvlCache[unitName] = nil
        end
    end
    return nil, nil
end

-- ==================== STORE ILVL & GS IN CACHE ====================
local function StoreIlvl(unitName, ilvl, gs)
    if not unitName then return end
    ilvlCache[unitName] = {
        ilvl = ilvl,
        gs = gs,
        timestamp = time()
    }
end

-- ==================== TOOLTIP HOOK ====================
local function OnTooltipSetUnit(self)
    local name, unit = self:GetUnit()
    if not name or not unit then return end
    if not UnitIsPlayer(unit) then return end
    if UnitIsUnit(unit, "player") then return end -- skip self

    -- Try cache first
    local ilvl, gs = GetCachedIlvl(name)

    -- If not cached or expired, try to calculate
    if not ilvl then
        local canInspect = CanInspect(unit)
        if canInspect then

        end

        ilvl = CalculatePlayerItemLevel(unit)
        gs = CalculatePlayerGearScore(unit)
        if ilvl then
            StoreIlvl(name, ilvl, gs)
        end
    end

    -- Add the lines to tooltip
    if ilvl and ilvl > 0 then
        self:AddDoubleLine(
            "|cff88ccffFS-iLvl|r",
            "|cffffffff" .. tostring(ilvl) .. " iLvl|r"
        )

        -- GearScore line with color
        if gs and gs > 0 then
            local r, g, b = GetGearScoreColor(gs)
            local gsColorHex = string.format("%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            self:AddDoubleLine(
                "|cff88ccffFS-GearScore|r",
                "|cff" .. gsColorHex .. tostring(gs) .. " GS|r"
            )
        end
    else
        self:AddDoubleLine(
            "|cff88ccffFrostSeek|r",
            "|cff888888N/A|r"
        )
    end
end

-- ==================== INSPECT HANDLER ====================
local inspectFrame = CreateFrame("Frame")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(self, event, guid)
    if event ~= "INSPECT_READY" then return end

    -- Find the unit that was inspected
    local unit = nil
    if InspectFrame and InspectFrame.unit then
        unit = InspectFrame.unit
    else
        -- Try to find by GUID
        if guid then
            if UnitGUID("target") == guid then
                unit = "target"
            elseif UnitGUID("mouseover") == guid then
                unit = "mouseover"
            end
        end
    end

    if not unit then return end

    local name = UnitName(unit)
    if not name then return end

    local ilvl = CalculatePlayerItemLevel(unit)
    local gs = CalculatePlayerGearScore(unit)
    if ilvl then
        StoreIlvl(name, ilvl, gs)
    end
end)

-- ==================== INVENTORY CHANGE HANDLER ====================
local inventoryFrame = CreateFrame("Frame")
inventoryFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
inventoryFrame:SetScript("OnEvent", function(self, event, unit)
    if not unit then return end

    local name = UnitName(unit)
    if not name then return end

    -- Recalculate and update cache
    local ilvl = CalculatePlayerItemLevel(unit)
    local gs = CalculatePlayerGearScore(unit)
    if ilvl then
        StoreIlvl(name, ilvl, gs)
    end
end)

-- ==================== CACHE CLEANUP ====================
local cleanupTicker = C_Timer.NewTicker(120, function()
    local now = time()
    for name, data in pairs(ilvlCache) do
        if (now - data.timestamp) > cacheExpiry then
            ilvlCache[name] = nil
        end
    end
end)

-- ==================== HOOK TOOLTIP ====================
GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)

-- ==================== INSPECT ON MOUSEOVER (optional) ====================
local autoInspectFrame = CreateFrame("Frame")
autoInspectFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
autoInspectFrame:SetScript("OnEvent", function(self, event)
    local unit = "mouseover"
    if not unit then return end
    if not UnitIsPlayer(unit) then return end
    if UnitIsUnit(unit, "player") then return end

    local name = UnitName(unit)
    if not name then return end

    -- Only auto-inspect if not cached or cache is old
    local cachedIlvl = GetCachedIlvl(name)
    if not cachedIlvl and CanInspect(unit) then
        -- Throttle: don't inspect too often
        NotifyInspect(unit)
    end
end)

-- ==================== MODULE INTERFACE ====================
function Tooltip:Initialize(parentFrame)
    -- This module doesn't need a UI frame, it works passively
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
        print("|cff88ccffFrostSeek Tooltip:|r iLvl + GearScore tooltip module active")
    end
end

function Tooltip:Show()
    
end

function Tooltip:Hide()
    
end

-- ==================== EXPOSE GEARSCORE FUNCTION FOR OTHER MODULES ====================
FrostSeek.CalculateGearScore = CalculatePlayerGearScore
FrostSeek.GetGearScoreColor = GetGearScoreColor

-- ==================== MODULE REGISTRATION ====================
local function RegisterTooltipModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterTooltipModule)
        return
    end

    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("tooltip", Tooltip)
    end
end

RegisterTooltipModule()
