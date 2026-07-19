--[[
==============================================================================
 FrostSeek - Advanced LFG/LFM Manager with FrostNet
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

local Tooltip = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("tooltip", Tooltip)

local ilvlCache = {}
local cacheExpiry = 300

local GS_SLOT_WEIGHTS = {
    [1]  = 1.0000,
    [2]  = 0.5625,
    [3]  = 0.7500,
    [5]  = 1.0000,
    [6]  = 0.7500,
    [7]  = 1.0000,
    [8]  = 0.7500,
    [9]  = 0.5625,
    [10] = 0.7500,
    [11] = 0.5625,
    [12] = 0.5625,
    [13] = 0.5625,
    [14] = 0.5625,
    [15] = 0.5625,
    [16] = 1.0000,
    [17] = 0.5625,
    [18] = 0.3164,
}

local GS_QUALITY_MULT = {
    [0] = 0.1,
    [1] = 0.2,
    [2] = 1.0,
    [3] = 1.0,
    [4] = 1.2,
    [5] = 1.3,
    [6] = 1.5,
    [7] = 1.0,
}

local GS_SCALE = 2.5
local GS_ILVL_BASE = 70

local GS_COLOR_THRESHOLDS = {
    { min = 5000, r = 0.95, g = 0.30, b = 0.30 },
    { min = 4500, r = 1.00, g = 0.50, b = 0.20 },
    { min = 3800, r = 1.00, g = 0.85, b = 0.20 },
    { min = 3000, r = 0.30, g = 1.00, b = 0.30 },
    { min = 2000, r = 0.30, g = 0.75, b = 1.00 },
    { min = 0,    r = 0.60, g = 0.60, b = 0.60 },
}

local function CalculatePlayerItemLevel(unit)
    if not unit then return nil end

    if FrostSeekCompat and FrostSeekCompat.GetPlayerItemLevel then
        local result = FrostSeekCompat.GetPlayerItemLevel(unit)
        if result and result > 0 then return result end
    end

    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink
            if FrostSeekCompat and FrostSeekCompat.GetInventoryItemLink then
                itemLink = FrostSeekCompat.GetInventoryItemLink(unit, i)
            else
                itemLink = GetInventoryItemLink(unit, i)
            end
            if itemLink then
                local itemName, _, itemRarity, itemLevel = GetItemInfo(itemLink)
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

local function CalculatePlayerGearScore(unit)
    if not unit then return nil end

    local totalScore = 0
    local itemCount = 0
    local ilvlSum = 0
    local ilvlCount = 0

    for slot = 1, 18 do
        if slot ~= 4 then
            local itemLink
            if FrostSeekCompat and FrostSeekCompat.GetInventoryItemLink then
                itemLink = FrostSeekCompat.GetInventoryItemLink(unit, slot)
            else
                itemLink = GetInventoryItemLink(unit, slot)
            end
            if itemLink then
                local itemName, _, itemRarity, itemLevel = GetItemInfo(itemLink)
                if itemLevel then
                    ilvlSum = ilvlSum + itemLevel
                    ilvlCount = ilvlCount + 1
                end
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

    if ilvlCount > 0 then
        local avgIlvl = ilvlSum / ilvlCount
        return math.floor((avgIlvl - GS_ILVL_BASE) * GS_SCALE * 7.0 + 0.5)
    end

    return nil
end

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

local function StoreIlvl(unitName, ilvl, gs)
    if not unitName then return end
    ilvlCache[unitName] = {
        ilvl = ilvl,
        gs = gs,
        timestamp = time()
    }
end

local inspectFrame = CreateFrame("Frame")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(self, event, guid)
    if event ~= "INSPECT_READY" then return end

    local unit = nil
    if InspectFrame and InspectFrame.unit then
        unit = InspectFrame.unit
    else
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

local inventoryFrame = CreateFrame("Frame")
inventoryFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
inventoryFrame:SetScript("OnEvent", function(self, event, unit)
    if not unit then return end

    local name = UnitName(unit)
    if not name then return end

    local ilvl = CalculatePlayerItemLevel(unit)
    local gs = CalculatePlayerGearScore(unit)
    if ilvl then
        StoreIlvl(name, ilvl, gs)
    end
end)

local cleanupTicker = C_Timer.NewTicker(120, function()
    local now = time()
    for name, data in pairs(ilvlCache) do
        if (now - data.timestamp) > cacheExpiry then
            ilvlCache[name] = nil
        end
    end
end)

function Tooltip:Initialize(parentFrame)
end

function Tooltip:Show()

end

function Tooltip:Hide()

end

FrostSeek._v.s("gs", CalculatePlayerGearScore)
FrostSeek._v.s("gsc", GetGearScoreColor)

FrostSeek.CalculateGearScore = function(unit)
    local fn = FrostSeek._v.g("gs")
    if fn then return fn(unit) end
    return nil
end
FrostSeek.GetGearScoreColor = function(gs)
    local fn = FrostSeek._v.g("gsc")
    if fn then return fn(gs) end
    return 0.6, 0.6, 0.6
end

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("tooltip", Tooltip)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("tooltip")
end