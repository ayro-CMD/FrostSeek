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

local L = FrostSeek and FrostSeek.L or {}

local ilvlCache = {}
local cacheExpiry = 300

local function GetFrostNetUser(name)
    if not name or name == "" then return nil end
    local cleanName = string.match(name, "^([^%-]+)")
    if not cleanName or cleanName == "" then return nil end
    local Presence = FrostSeek and FrostSeek.Presence
    if Presence and Presence.onlineUsers then
        local u = Presence.onlineUsers[cleanName]
        if u then return u end
    end
    local myName = UnitName and UnitName("player") or ""
    if cleanName == myName then
        return { version = FrostSeek and FrostSeek.VERSION or "", role = (FrostSeekDB and FrostSeekDB.Profile and FrostSeekDB.Profile.role) or "" }
    end
    return nil
end

local function AppendFrostNetLines(tip, name)
    local u = GetFrostNetUser(name)
    if not u then return end
    tip:AddLine("|cff88ccff" .. (L["tooltip_frostnet_user"] or "FrostNet User") .. "|r")
    if u.version and u.version ~= "" then
        tip:AddLine(string.format(L["tooltip_frostnet_version"] or "FrostSeek v%s", u.version), 0.6, 0.8, 1, true)
    end
    if u.role and u.role ~= "" and u.role ~= (L["none"] or "None") then
        tip:AddLine((L["col_role"] or "Role") .. ": " .. tostring(u.role), 0.8, 0.8, 0.8)
    end
end

local function GetTooltipUnitName(tip)
    local ok, name = pcall(function() return tip:GetUnit() end)
    if ok and name and name ~= "" then
        return name
    end
    local okL, line = pcall(function()
        if tip.TextLeft1 then return tip.TextLeft1:GetText() end
    end)
    if okL and line and line ~= "" then
        return string.match(line, "^%s*([%w]+)")
    end
    return nil
end

pcall(function()
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        local name = GetTooltipUnitName(self)
        if name then
            AppendFrostNetLines(self, name)
        end
    end)
end)

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