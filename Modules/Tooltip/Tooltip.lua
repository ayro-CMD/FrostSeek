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

local Tooltip = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("tooltip", Tooltip)

local ilvlCache = {}
local cacheExpiry = 300

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

local function GetCachedIlvl(unitName)
    if not unitName then return nil end
    local cached = ilvlCache[unitName]
    if cached then
        if (time() - cached.timestamp) < cacheExpiry then
            return cached.ilvl
        else
            ilvlCache[unitName] = nil
        end
    end
    return nil
end

local function StoreIlvl(unitName, ilvl)
    if not unitName then return end
    ilvlCache[unitName] = {
        ilvl = ilvl,
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
    if ilvl then
        StoreIlvl(name, ilvl)
    end
end)

local inventoryFrame = CreateFrame("Frame")
inventoryFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
inventoryFrame:SetScript("OnEvent", function(self, event, unit)
    if not unit then return end

    local name = UnitName(unit)
    if not name then return end

    local ilvl = CalculatePlayerItemLevel(unit)
    if ilvl then
        StoreIlvl(name, ilvl)
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

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("tooltip", Tooltip)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("tooltip")
end