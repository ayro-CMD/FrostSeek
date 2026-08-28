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
local Shared = _G.FrostSeekShared
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end
local UI = _G.FrostSeekUIUtils

local Listings = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("listings", Listings)

local L = FrostSeek.L
local Lf = FrostSeek.Lf or function(k, ...) return string.format(k, ...) end

local function LPrint(key, ...)
    local body = select("#", ...) > 0 and Lf(key, ...) or L[key]
    print("|cff88ccffFrostNet:|r " .. tostring(body))
end

Listings.listings = {}
Listings.applicants = {}
Listings.myListing = nil
Listings.selectedListing = nil
Listings.selectedApplicant = nil
Listings.filter = "All"
Listings.searchText = ""
Listings.myApplications = {}

local MAX_LISTINGS = Shared and Shared.MAX_LISTINGS or 200
local MAX_BROWSE_ROWS = 10
local LISTING_EXPIRE = 300
local APP_PENDING_EXPIRE = 300

local ACTIVITY_TYPES = {"Dungeon", "Raid", "World Boss", "Key", "Event", "PvP", "Manastorm", "Quest"}
local EXPANSIONS = {"Classic", "TBC", "WotLK", "Cata", "MoP", "Custom"}
local EVENT_EXPANSIONS = {"Classic", "TBC", "WotLK", "Cata", "MoP", "Ascension", "Custom"}
local DIFFICULTIES = {"Normal", "Heroic", "Mythic"}
local EVENT_DIFFICULTIES = {"Normal", "Heroic", "Mythic", "Custom"}
local MANASTORM_DIFFICULTIES = {"Normal"}
local KEY_DIFFICULTIES = {"Mythic+"}
local QUEST_DIFFICULTIES = {"Normal", "Group", "Daily", "Weekly", "Chain"}
local RAID_DIFFICULTIES = {"Normal", "Heroic", "Mythic", "Ascended", "Trial 1", "Trial 2", "Trial 3", "Trial 4", "Trial 5", "Trial 6", "Trial 7", "Trial 8", "Trial 9", "Trial 10"}
local BOSS_DIFFICULTIES = {"Open World", "Instanced", "HC Instanced", "Mythic Instanced", "Ascended Instanced"}
local PVP_DIFFICULTIES = {"Normal", "Ranked"}
local ROLES_NEEDED = {"Tank", "Healer", "DPS", "Support"}
local VOICE_OPTIONS = {"None", "Discord", "In-game","TeamSpeak"}
local LOOT_OPTIONS = {"Group Loot", "Master Looter", "Need Before Greed", "Any"}

local ACTIVITY_DB = {
    DUNGEON = {
        CLASSIC = {"Deadmines", "Wailing Caverns", "Ragefire Chasm", "Shadowfang Keep", "Blackrock Depths", "Blackfathom Deeps", "Scholomance", "Lower Blackrock Spire", "Upper Blackrock Spire", "Dire Maul East", "Dire Maul North", "Dire Maul West", "The Stockade", "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Stratholme"},
        TBC = {"Hellfire Ramparts", "Blood Furnace", "The Shattered Halls", "Slave Pens", "Underbog", "The Steamvault", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth", "Mechanar", "Botanica", "Arcatraz", "Magister's Terrace"},
        WOTLK = {"Utgarde Keep", "Utgarde Pinnacle", "The Nexus", "The Oculus", "Azjol-Nerub", "Ahn'kahet", "Drak'Tharon Keep", "Violet Hold", "Gundrak", "Halls of Stone", "Halls of Lightning", "Culling of Stratholme", "Trial of the Champion", "Forge of Souls", "Pit of Saron", "Halls of Reflection"},
        CATA = {"Blackrock Caverns", "The Throne of the Tides", "The Vortex Pinnacle", "Stonecore", "Lost City of the Tol'vir", "Halls of Origination", "Grim Batol", "Deadmines (Heroic)", "Shadowfang Keep (Heroic)", "Zul'Gurub", "Zul'Aman", "End Time", "Well of Eternity", "Hour of Twilight"},
        MOP = {"Temple of the Jade Serpent", "Stormstout Brewery", "Shado-Pan Monastery", "Mogu'shan Palace", "Scarlet Halls", "Scarlet Monastery", "Siege of Niuzao Temple", "Gate of the Setting Sun", "Scholomance", "Darkheart Thicket", "Violet Hold"},
        ASCENSION = {"Blackrock Cavern", "Tor'Watha", "Bardid Hold", "Vault of the Inquisition", "Road to De' Other Side", "The Temple of Embers", "Shadowbone Depths", "RDF"},
        EPOCH = {"Glittermurk Mines"},
    },
    RAID = {
        CLASSIC = {"Molten Core", "Onyxia", "Blackwing Lair", "Zul'Gurub", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas"},
        TBC = {"Karazhan", "Gruul's Lair", "Magtheridon", "Serpentshrine Cavern", "Tempest Keep", "Hyjal Summit", "Black Temple", "Zul'Aman", "Sunwell Plateau"},
        WOTLK = {"Eye of Eternity", "Obsidian Sanctum", "Vault of Archavon", "Ulduar", "Trial of the Crusader", "Icecrown Citadel", "Ruby Sanctum"},
        CATA = {"Baradin Hold", "Bastion of Twilight", "Throne of the Four Winds", "Blackwing Descent", "Firelands", "Dragon Soul"},
        MOP = {"Terrace of Endless Spring", "Mogu'shan Vaults", "Heart of Fear", "Throne of Thunder", "Siege of Orgrimmar"},
        ASCENSION = {"The Radiant Spring"},
        EPOCH = {},
    },
    ["WORLD BOSS"] = {
        CLASSIC = {"Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Taerar", "Ysondre", "Setis"},
        TBC = {"Doomwalker", "Doom Lord Kazzak"},
        WOTLK = {"Archavon", "Emalon", "Koralon", "Toran"},
        CATA = {"Akma'hat", "Garr", "Julak-Doom", "Mobus", "Poseidus", "Xariona"},
        MOP = {"Sha of Anger", "Galleon", "Nalak", "Oondasta", "Celestials"},
        ASCENSION = {"WorldBossTour", "Soggoth", "Snowgrave", "Atal'Zul", "Kaldros Depthbreaker"},
        EPOCH = {"Gonzor", "King Gnok", "King Mosh", "Silithid Lurker", "Volchan", "Corrupted Ancient"},
    },
    PVP = {
        ALL = {"Arena 2v2", "Arena 3v3", "Arena 5v5", "Battlegrounds", "Wintergrasp", "World PvP", "High Risk PvP"},
    },

    EVENT = {
    CLASSIC = {"Ahn'Qiraj Event", "Scourge Invasion", "Darkmoon Faire", "Elemental Invasion"},
    TBC = {"Hallows' End", "Brewfest", "Love is in the Air", "Zul'Aman Event"},
    WOTLK = {"Noblegarden", "Midsummer Fire Festival", "Pilgrim's Bounty", "Wintergrasp", "Vault of Archavon"},
    CATA = {"Darkmoon Faire", "Elemental Invasion", "Day of the Dead", "Firelands Invasion"},
    MOP = {"Pandaren Festival", "Brewmoon Festival", "Shadowpan Showdown", "Celestial Tournament"},
    ASCENSION = {"The ShadowEye", "Bullet Romper", "Wonka Wonka", "Vertical Ascent", "Duck Hunt", "Rainbow Race", "A.B.Y.S.S."},
    CUSTOM = {"FrostSeek Event", "Winter Veil Special", "PvP Tournament", "Ascension MiniGame"},
    ALL = {"MiniGame", "Custom"},
},
    KEY = {
        CLASSIC = {"Deadmines", "Wailing Caverns", "Ragefire Chasm", "Shadowfang Keep", "Blackrock Depths", "Blackfathom Deeps", "Scholomance", "Lower Blackrock Spire", "Upper Blackrock Spire", "Dire Maul East", "Dire Maul North", "Dire Maul West", "The Stockade", "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Stratholme"},
        TBC = {"Hellfire Ramparts", "Blood Furnace", "The Shattered Halls", "Slave Pens", "Underbog", "The Steamvault", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth", "Mechanar", "Botanica", "Arcatraz", "Magister's Terrace"},
        WOTLK = {"Utgarde Keep", "Utgarde Pinnacle", "The Nexus", "The Oculus", "Azjol-Nerub", "Ahn'kahet", "Drak'Tharon Keep", "Violet Hold", "Gundrak", "Halls of Stone", "Halls of Lightning", "Culling of Stratholme", "Trial of the Champion", "Forge of Souls", "Pit of Saron", "Halls of Reflection"},
        CATA = {"Blackrock Caverns", "The Throne of the Tides", "The Vortex Pinnacle", "Stonecore", "Lost City of the Tol'vir", "Halls of Origination", "Grim Batol", "Deadmines", "Shadowfang Keep"},
        MOP = {"Temple of the Jade Serpent", "Stormstout Brewery", "Shado-Pan Monastery", "Mogu'shan Palace", "Scarlet Halls", "Scarlet Monastery", "Siege of Niuzao Temple", "Gate of the Setting Sun", "Scholomance"},
        ASCENSION = {"Tor'Watha", "Bardid Hold", "Vault of the Inquisition", "Road to De' Other Side"},
        EPOCH = {"Glittermurk Mines"},
    },
    MANASTORM = {
        ALL = {"ALVA", "Manastorm Gold Farm", "Manastorm Leveling", "Manastorm Bonzo Farm"},
    },
    QUEST = {
        ALL = {"Group Quest", "Daily Quest", "Weekly Quest", "Chain Quest", "Raid Quest", "PvP Quest", "Reputation Quest", "Event Quest", "Story Quest", "World Quest"},
    },
}

local TYPE_ICONS = {
    Dungeon = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\cata.tga",
    Raid = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\raid.tga",
    ["World Boss"] = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\customwc.tga",
    Key = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\keystone.tga",
    Event = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\custom.tga",
    Manastorm = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\alva.tga",
    PvP = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\pandino.tga",
    Quest = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\custom.tga",
}

local TYPE_COLORS = {
    Dungeon = "|cff3fa7ff",
    Raid = "|cff4dff7a",
    ["World Boss"] = "|cffff9a33",
    Key = "|cffb866ff",
    Event  = "|cffff9a33",
    Manastorm = "|cffaa66ff",
    PvP = "|cffff5555",
    Quest = "|cffffd966",
}

local function GetRelevantExpansions()
    local Shared = _G.FrostSeekShared
    if Shared and Shared.GetRelevantExpansionsForProfile then
        return Shared.GetRelevantExpansionsForProfile()
    end
    if Shared and Shared.GetServerProfile then
        local profile = Shared.GetServerProfile()
        if profile == "ascension" then
            return {"Classic", "TBC", "WotLK", "Ascension"}
        elseif profile == "epoch" then
            return {"Classic", "TBC", "WotLK", "Epoch"}
        elseif profile == "classic" then
            return {"Classic"}
        elseif profile == "tbc" then
            return {"Classic", "TBC"}
        elseif profile == "wotlk" then
            return {"Classic", "TBC", "WotLK"}
        elseif profile == "cata" then
            return {"Classic", "TBC", "WotLK", "Cata"}
        elseif profile == "mop" then
            return {"Classic", "TBC", "WotLK", "Cata", "MoP"}
        end
    end

    local Compat = FrostSeekCompat
    if not Compat then return EXPANSIONS end
    if Compat.Is335() then
        return {"Classic", "TBC", "WotLK", "Custom"}
    elseif Compat.IsVanilla() then
        return {"Classic"}
    elseif Compat.IsTBC() then
        return {"Classic", "TBC"}
    elseif Compat.IsWotLKClassic() then
        return {"Classic", "TBC", "WotLK"}
    elseif Compat.IsCata() then
        return {"Classic", "TBC", "WotLK", "Cata"}
    elseif Compat.IsMists() then
        return {"Classic", "TBC", "WotLK", "Cata", "MoP"}
    elseif Compat.IsMainline() then
        return {"Classic", "TBC", "WotLK", "Cata", "MoP", "Custom"}
    end
    return EXPANSIONS
end

local function GetActivitiesForType(expansion, ltype)
    if not ltype or ltype == "" then return {} end
    local typeKey = string.upper(ltype)
    local db = ACTIVITY_DB[typeKey]
    if not db then return {} end

    if typeKey == "EVENT" then
        if not expansion or expansion == "All" or expansion == "ALL" then
            local all = {}
            for _, expList in pairs(db) do
                for _, name in ipairs(expList) do
                    table.insert(all, name)
                end
            end
            return all
        end
        local expKey = string.upper(expansion)
        return db[expKey] or db.ALL or {}
    end

    if typeKey == "PVP" or typeKey == "MANASTORM" or typeKey == "QUEST" then
        return db.ALL or {}
    end

    if typeKey == "KEY" then
        if not expansion or expansion == "All" then
            local all = {}
            for _, expList in pairs(db) do
                for _, name in ipairs(expList) do
                    table.insert(all, name)
                end
            end
            return all
        end
        local expKey = string.upper(expansion)
        return db[expKey] or {}
    end

    if not expansion or expansion == "All" then
        local all = {}
        for _, expList in pairs(db) do
            for _, name in ipairs(expList) do
                table.insert(all, name)
            end
        end
        return all
    end
    local expKey = string.upper(expansion)
    return db[expKey] or {}
end

local function now()
    return time()
end

local function playerName()
    return UnitName("player") or ""
end

local function memberCount()
    local raid = GetNumRaidMembers and GetNumRaidMembers() or 0
    if raid and raid > 0 then return raid end
    return (GetNumPartyMembers and GetNumPartyMembers() or 0) + 1
end

local function ageText(ts)
    if not ts then return "?" end
    local s = now() - ts
    if s < 60 then return tostring(s) .. L["time_seconds_ago"]
    elseif s < 3600 then return tostring(math.floor(s / 60)) .. L["time_minutes_ago"]
    else return tostring(math.floor(s / 3600)) .. L["time_hours_ago"] end
end

local function roleText(role)
    if Shared and Shared.GetRoleHex then
        return Shared.GetRoleHex(role) .. (role or "?") .. "|r"
    end
    local colors = { Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555", Support = "|cffb366ff", SUPPORT = "|cffb366ff" }
    return (colors[role] or "|cffffffff") .. (role or "?") .. "|r"
end

local function classIcon(classFile)
    if Shared and Shared.GetClassIcon then
        return Shared.GetClassIcon(classFile)
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function classColorText(name, classFile)
    if Shared and Shared.GetClassHex and classFile then
        return Shared.GetClassHex(classFile) .. tostring(name) .. "|r"
    end
    return tostring(name or "")
end

local function countListings()
    local n = 0
    for _ in pairs(Listings.listings) do n = n + 1 end
    return n
end

local function trimOldestListing()
    local oldestId = nil
    local oldestSeen = math.huge
    for id, l in pairs(Listings.listings) do
        if (l.seen or 0) < oldestSeen then
            oldestSeen = l.seen or 0
            oldestId = id
        end
    end
    if oldestId then
        if Listings.selectedListing == oldestId then
            Listings.selectedListing = nil
        end
        Listings.listings[oldestId] = nil
    end
end

local _pendingMinimapCats = nil
local _pendingMinimapTimer = nil

local function _flushMinimapCats()
    _pendingMinimapTimer = nil
    if not _pendingMinimapCats then return end
    local nowT = time()
    local nextDelay
    for c, ts in pairs(_pendingMinimapCats) do
        local age = nowT - ts
        if age >= 30 then
            _pendingMinimapCats[c] = nil
            if FrostSeek.RemoveMinimapCategory then
                FrostSeek.RemoveMinimapCategory(c)
            end
        else
            local remain = 30 - age
            if not nextDelay or remain < nextDelay then nextDelay = remain end
        end
    end
    if nextDelay then
        _pendingMinimapTimer = C_Timer.NewTimer(nextDelay, function() _flushMinimapCats() end)
    end
end

function Listings:HandleIncomingListing(listing)
    if not listing or not listing.id then return end

    local isNew = not self.listings[listing.id]

    local existing = self.listings[listing.id]
    if existing then
        listing.created = existing.created or listing.created
    end
    listing.seen = now()
    self.listings[listing.id] = listing

    if countListings() > MAX_LISTINGS then
        trimOldestListing()
    end

    if isNew and self:PassFilter(listing) and listing.leader ~= playerName() then
        LPrint("net_listing_new", tostring(listing.leader), tostring(listing.activity or "?"), (listing.difficulty and listing.difficulty ~= "" and (" (" .. listing.difficulty .. ")") or ""))
        if Shared and Shared.PlaySound then
            Shared.PlaySound("listing")
        end
    end

    if FrostSeek.SetMinimapCategory then
        local cat = listing.type == "Raid" and "RAID" or
                    listing.type == "Key" and "KEYSTONE" or
                    listing.type == "World Boss" and "WORLD_BOSS" or
                    listing.type == "Dungeon" and "DUNGEON" or
                    listing.type ==  "Event" and "MANASTORM" or
                    listing.type == "Manastorm" and "MANASTORM" or
                    listing.type == "Quest" and "QUEST" or
                    "DUNGEON"
        FrostSeek.SetMinimapCategory(cat)
        if not _pendingMinimapCats then _pendingMinimapCats = {} end
        _pendingMinimapCats[cat] = time()
        if not _pendingMinimapTimer then
            _pendingMinimapTimer = C_Timer.NewTimer(2, function() _flushMinimapCats() end)
        end
    end

    if self.frame and self.frame:IsShown() then
        self:RefreshBrowse()
    end
end

local appPopups = {}
local APP_POPUP_W = 340
local APP_POPUP_H = 100
local APP_POPUP_GAP = 6
local APP_POPUP_MAX = 4

local function RepositionAppPopupsImpl()
    local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
    local point, relFrame, relPoint, xOfs, yOfs = "TOPLEFT", UIParent, "TOPLEFT", 10, -40
    if LFG and LFG.GetApplicantPopupAnchorPoint then
        point, relFrame, relPoint, xOfs, yOfs = LFG.GetApplicantPopupAnchorPoint()
    end
    for i, popup in ipairs(appPopups) do
        popup:ClearAllPoints()
        local h = popup:GetHeight() or APP_POPUP_H
        local cascadeY
        if yOfs <= 0 then
            cascadeY = yOfs - ((i - 1) * (h + APP_POPUP_GAP))
        else
            cascadeY = yOfs + ((i - 1) * (h + APP_POPUP_GAP))
        end
        popup:SetPoint(point, relFrame, relPoint, xOfs, cascadeY)
    end
end

function Listings:RepositionAppPopups()
    RepositionAppPopupsImpl()
end

local function RemoveAppPopup(popup)
    if not popup then return end
    popup:SetScript("OnUpdate", nil)
    if UIFrameFadeOut then
        UIFrameFadeOut(popup, 0.15, popup:GetAlpha() or 1, 0)
        C_Timer.After(0.2, function()
            if popup then popup:Hide() end
        end)
    else
        popup:Hide()
    end
    for i = #appPopups, 1, -1 do
        if appPopups[i] == popup then
            table.remove(appPopups, i)
            break
        end
    end
    C_Timer.After(0.05, RepositionAppPopupsImpl)
end

function Listings:ShowApplicantPopup(applicant)
    if not applicant or not applicant.name then return end
    if FrostSeekDB.Listings and FrostSeekDB.Listings.disableAppPopups then return end
    if #appPopups >= APP_POPUP_MAX then
        RemoveAppPopup(appPopups[1])
    end

    local roleColorMap = {
        Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555", Support = "|cffb366ff",
        tank = "|cff4aa3ff", healer = "|cff44ff66", dps = "|cffff5555", support = "|cffb366ff",
        SUPPORT = "|cffb366ff",
    }
    local roleDisplay = applicant.role or "DPS"
    local roleColor = roleColorMap[roleDisplay] or "|cffffffff"
    local activity = self.myListing and self.myListing.activity or L["unknown"]
    local listingType = self.myListing and self.myListing.type or "Dungeon"

    local UI = FrostSeekUIUtils
    local ar, ag, ab = 0.35, 0.65, 0.95

    local W, H = APP_POPUP_W, 100
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(W, H)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:SetAlpha(0)
    UIFrameFadeIn(popup, 0.2, 0, 1)
    popup.applicantName = applicant.name
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
            self._dragging = true
        end
    end)
    popup:SetScript("OnDragStop", function(self)
        if self._dragging then
            self:StopMovingOrSizing()
            self._dragging = false
            local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
            if LFG and LFG.SaveApplicantPopupAnchorFromFrame then
                LFG.SaveApplicantPopupAnchorFromFrame(self)
                RepositionAppPopupsImpl()
                print(L["msg_frostnet_popup_anchor_saved"])
            end
        end
    end)
    local borderTex = popup:CreateTexture(nil, "BACKGROUND")
    borderTex:SetAllPoints()
    borderTex:SetColorTexture(ar * 0.3, ag * 0.3, ab * 0.3, 0.65)

    local bgPopupColor = _tc("bgPopup")
    local bgTex = popup:CreateTexture(nil, "BORDER")
    bgTex:SetPoint("TOPLEFT", 1, -1)
    bgTex:SetPoint("BOTTOMRIGHT", -1, 1)
    bgTex:SetColorTexture(bgPopupColor[1], bgPopupColor[2], bgPopupColor[3], bgPopupColor[4])

    local topAccent = popup:CreateTexture(nil, "ARTWORK")
    topAccent:SetPoint("TOPLEFT", 1, 0)
    topAccent:SetPoint("TOPRIGHT", -1, 0)
    topAccent:SetHeight(2)
    topAccent:SetColorTexture(ar, ag, ab, 0.9)

    local glassReflect = popup:CreateTexture(nil, "ARTWORK")
    glassReflect:SetPoint("TOPLEFT", 2, -3)
    glassReflect:SetPoint("TOPRIGHT", -2, -3)
    glassReflect:SetHeight(16)
    glassReflect:SetColorTexture(ar * 0.06, ag * 0.06, ab * 0.06, 0.3)

    popup.headerText = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    popup.headerText:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -8)
    popup.headerText:SetText(L["app_new_applied"])
    popup.headerText:SetTextColor(min(ar * 1.4, 1), min(ag * 1.4, 1), min(ab * 1.4, 1))

    local badgeFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    badgeFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -10, -8)
    badgeFS:SetText("|cff88ccff" .. (activity or "?") .. "|r")

    local row1Y = -26
    popup.classIcon = popup:CreateTexture(nil, "ARTWORK")
    popup.classIcon:SetSize(16, 16)
    popup.classIcon:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, row1Y)
    popup.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    do
        local cf = applicant.classFile
        if cf and Shared and Shared.GetClassIcon then
            popup.classIcon:SetTexture(Shared.GetClassIcon(cf))
            popup.classIcon:Show()
        else
            popup.classIcon:Hide()
        end
    end

    local nameStr = classColorText(applicant.name, applicant.classFile)
    local nameFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    nameFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 32, row1Y + 1)
    nameFS:SetText(nameStr)

    local roleFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    roleFS:SetPoint("LEFT", nameFS, "RIGHT", 6, 0)
    roleFS:SetText(roleColor .. roleDisplay .. "|r")

    local row2Y = -42
    local lvl = applicant.level or "?"
    local ilvl = applicant.itemLevel or "?"
    local infoFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    infoFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 32, row2Y)
    infoFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    infoFS:SetJustifyH("LEFT")
    infoFS:SetTextColor(unpack(_tc("textNorm")))
    infoFS:SetText("|cff888888" .. L["app_level"] .. ":|r " .. lvl .. "  |cff88ccffiLvl:|r |cff44ff44" .. ilvl .. "|r")

    local row3Y = -56
    local noteText = applicant.note or applicant.message or ""
    if noteText ~= "" then
        local noteFS = popup:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        noteFS:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, row3Y)
        noteFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
        noteFS:SetJustifyH("LEFT")
        noteFS:SetWordWrap(false)
        local truncNote = #noteText > 60 and string.sub(noteText, 1, 57) .. "..." or noteText
        noteFS:SetTextColor(unpack(_tc("textDim")))
        noteFS:SetText(truncNote)
    end

    popup.countdownBar = CreateFrame("Frame", nil, popup)
    popup.countdownBar:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 4, 28)
    popup.countdownBar:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -4, 28)
    popup.countdownBar:SetHeight(3)

    popup.countdownBg = popup.countdownBar:CreateTexture(nil, "BACKGROUND")
    popup.countdownBg:SetAllPoints()
    popup.countdownBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    popup.countdownFill = popup.countdownBar:CreateTexture(nil, "ARTWORK")
    popup.countdownFill:SetPoint("TOPLEFT", popup.countdownBar, "TOPLEFT", 0, 0)
    popup.countdownFill:SetPoint("BOTTOMLEFT", popup.countdownBar, "BOTTOMLEFT", 0, 0)
    popup.countdownFill:SetWidth(W - 10)
    popup.countdownFill:SetColorTexture(ar, ag, ab, 0.7)

    local footerY = 6

    local acceptBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 68, 20, L["listings_accept"], _tc("success"))
    if not acceptBtn then
        acceptBtn = CreateFrame("Button", nil, popup)
        acceptBtn:SetSize(68, 20)
        acceptBtn.text = acceptBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        acceptBtn.text:SetPoint("CENTER")
        acceptBtn.text:SetText(L["listings_accept"])
    end
    acceptBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 8, footerY)
    acceptBtn:SetScript("OnClick", function()
        Listings:AcceptApplicant(applicant.name)
        RemoveAppPopup(popup)
    end)

    local declineBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 68, 20, L["listings_decline"], _tc("danger"))
    if not declineBtn then
        declineBtn = CreateFrame("Button", nil, popup)
        declineBtn:SetSize(68, 20)
        declineBtn.text = declineBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        declineBtn.text:SetPoint("CENTER")
        declineBtn.text:SetText(L["listings_decline"])
    end
    declineBtn:SetPoint("LEFT", acceptBtn, "RIGHT", 4, 0)
    declineBtn:SetScript("OnClick", function()
        Listings:DeclineApplicant(applicant.name)
        RemoveAppPopup(popup)
    end)

    local closeBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 48, 20, L["close"], _tc("secondary"))
    if not closeBtn then
        closeBtn = CreateFrame("Button", nil, popup)
        closeBtn:SetSize(48, 20)
        closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        closeBtn.text:SetPoint("CENTER")
        closeBtn.text:SetText(L["close"])
    end
    closeBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -8, footerY)
    closeBtn:SetScript("OnClick", function()
        RemoveAppPopup(popup)
    end)

    local duration = 12
    popup.expiryTime = GetTime() + duration
    popup:SetScript("OnUpdate", function(self, elapsed)
        local remaining = self.expiryTime - GetTime()
        if remaining <= 0 then
            self:SetScript("OnUpdate", nil)
            RemoveAppPopup(self)
        else
            local pct = remaining / duration
            self.countdownFill:SetWidth(math.max(1, (W - 10) * pct))
            if pct < 0.3 then
                self.countdownFill:SetColorTexture(0.9, 0.3, 0.2, 0.8)
            else
                self.countdownFill:SetColorTexture(ar, ag, ab, 0.7)
            end
            if remaining < 1 then
                self:SetAlpha(remaining / 1)
            end
        end
    end)

    table.insert(appPopups, popup)
    RepositionAppPopupsImpl()
end

function Listings:HandleIncomingApplicant(applicant)
    if not applicant or not applicant.name then return end
    if not self.myListing or applicant.listingId ~= self.myListing.id then return end

    self.applicants[applicant.name] = applicant
    LPrint("net_applicant_received", tostring(applicant.name), tostring(self.myListing.activity))
    if FrostSeek.Dashboard and FrostSeek.Dashboard.IncrementStat then
        FrostSeek.Dashboard:IncrementStat("applicantsReceived")
    end
    Listings:UpdateApplicantBadge()

    if Shared and Shared.PlaySound then
        Shared.PlaySound("applicant")
    end

    if FrostSeek.SetMinimapCategory then
        FrostSeek.SetMinimapCategory("RAID")
        C_Timer.After(15, function()
            if FrostSeek.RemoveMinimapCategory then FrostSeek.RemoveMinimapCategory("RAID") end
        end)
    end

    self:ShowApplicantPopup(applicant)
    self:RefreshApplicants()
end

function Listings:HandleRemove(listingId)
    if not listingId then return end
    self.listings[listingId] = nil
    if self.selectedListing == listingId then
        self.selectedListing = nil
    end
    self:RefreshBrowse()
end

function Listings:HandleDecision(target, result, activity, senderName)
    if target ~= playerName() then return end
    local act = activity or "the group"
    if result == "accepted" then
        LPrint("net_app_accepted", act)
        if FrostSeek.Dashboard and FrostSeek.Dashboard.IncrementStat then
            FrostSeek.Dashboard:IncrementStat("applicationsAccepted")
        end
    else
        LPrint("net_app_declined", act)
    end

    for id, app in pairs(self.myApplications) do
        if app.status == "pending" and app.activity == act then
            if not senderName or not app.leader or app.leader == "" or app.leader == senderName then
                app.status = result == "accepted" and "accepted" or "declined"
                app.decidedAt = time()
                break
            end
        end
    end
    self:RefreshApplications()
end

function Listings:CreateListing(activity, ltype, difficulty, roles, minIlvl, maxMembers, voice, loot, note, key)
    if not FrostSeek.Protocol then return nil end

    if self.myListing then
        local oldId = self.myListing.id
        local Network = FrostSeek.Network
        if Network and Network.SendRemove then
            Network:SendRemove(oldId)
        end
        self.listings[oldId] = nil
        self.applicants = {}
        self.selectedApplicant = nil
        LPrint("net_listing_only_one")
    end

    local id = FrostSeek.Protocol.GenerateId()
    local listing = {
        id = id,
        activity = activity or L["unknown"],
        type = ltype or "Dungeon",
        difficulty = difficulty or "",
        leader = playerName(),
        roles = roles or "",
        minItemLevel = minIlvl or "",
        maxMembers = tostring(maxMembers or 5),
        members = tostring(memberCount()),
        voice = voice or "None",
        loot = loot or "Group Loot",
        note = note or "",
        key = key or "",
        created = now(),
        seen = now(),
    }
    self.myListing = listing
    self.listings[id] = listing
    self.applicants = {}

    local Network = FrostSeek.Network
    if Network and Network.SendListing then
        Network:SendListing(listing)
    end

    LPrint("net_listing_created", tostring(activity))
    if FrostSeek.Dashboard and FrostSeek.Dashboard.IncrementStat then
        FrostSeek.Dashboard:IncrementStat("listingsCreated")
    end
    return listing
end

function Listings:CancelListing(reason)
    if not self.myListing then return end
    local id = self.myListing.id
    local activity = self.myListing.activity or "group"

    local function doCancel()
        local Network = FrostSeek.Network
        if Network and Network.SendRemove then
            Network:SendRemove(id)
        end
        self.listings[id] = nil
        self.myListing = nil
        self.applicants = {}
        self.selectedApplicant = nil

        if reason == "full" then
            LPrint("net_listing_full", activity)
        else
            LPrint("net_listing_removed", activity)
        end
        self:RefreshBrowse()
    end

    if reason == "full" then
        doCancel()
    else
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog(L["listings_remove_listing"], (L["listings_confirm_remove"] or "Are you sure?"):format(tostring(activity)), doCancel)
        else
            doCancel()
        end
    end
end

function Listings:Apply()
    local id = self.selectedListing
    if not id then
        LPrint("net_select_group")
        return
    end
    local listing = self.listings[id]
    if not listing then return end

    if listing.leader == playerName() then
        LPrint("net_cant_apply_own")
        return
    end

    local Profile = FrostSeek.Profile
    if not Profile or not Profile.GetProfileForApp then return end

    local app = Profile:GetProfileForApp()
    app.listingId = id

    local Network = FrostSeek.Network
    if Network and Network.SendApplicant then
        Network:SendApplicant(id, app)
    end

    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.applyWhisper then
        pcall(function()
            SendChatMessage("[FrostSeek] I applied for: " .. tostring(listing.activity), "WHISPER", nil, listing.leader)
        end)
    end
    LPrint("net_app_sent", tostring(listing.activity))
    if FrostSeek.Dashboard and FrostSeek.Dashboard.IncrementStat then
        FrostSeek.Dashboard:IncrementStat("applicationsSent")
    end

    self.myApplications[id] = {
        id = id,
        activity = listing.activity or "Unknown",
        type = listing.type or "Dungeon",
        difficulty = listing.difficulty or "",
        leader = listing.leader or "",
        key = listing.key or "",
        note = listing.note or "",
        status = "pending",
        appliedAt = time(),
    }
    self:RefreshApplications()
end

function Listings:AcceptApplicant(name)
    if not name then return end
    local a = self.applicants[name]
    if not a then return end

    if InviteUnit then InviteUnit(name) end

    local Network = FrostSeek.Network
    if Network and Network.SendDecision then
        Network:SendDecision(name, "accepted", self.myListing and self.myListing.activity or "")
    end

    self.applicants[name] = nil
    if self.selectedApplicant == name then self.selectedApplicant = nil end
    self:RefreshApplicants()
    self:CheckAutoClose()
    LPrint("net_app_accepted_invited", tostring(name))
    if FrostSeek.Dashboard and FrostSeek.Dashboard.IncrementStat then
        FrostSeek.Dashboard:IncrementStat("applicantsAccepted")
    end
    Listings:UpdateApplicantBadge()
end

function Listings:DeclineApplicant(name)
    if not name then return end
    local Network = FrostSeek.Network
    if Network and Network.SendDecision then
        Network:SendDecision(name, "declined", self.myListing and self.myListing.activity or "")
    end
    self.applicants[name] = nil
    if self.selectedApplicant == name then self.selectedApplicant = nil end
    self:RefreshApplicants()
    LPrint("net_app_declined_sent")
    if FrostSeek.Dashboard and FrostSeek.Dashboard.IncrementStat then
        FrostSeek.Dashboard:IncrementStat("applicantsDeclined")
    end
    Listings:UpdateApplicantBadge()
end

function Listings:CheckAutoClose()
    if not self.myListing then return end
    local max = tonumber(self.myListing.maxMembers) or 5
    if memberCount() >= max then
        self:CancelListing("full")
    end
end

function Listings:BroadcastMyListing()
    if not self.myListing then return end
    self.myListing.members = tostring(memberCount())
    self.myListing.seen = now()
    local Network = FrostSeek.Network
    if Network and Network.SendListing then
        Network:SendListing(self.myListing)
    end
end

function Listings:PassFilter(listing)
    if not listing then return false end
    if self.filter == "Dungeons" and listing.type ~= "Dungeon" then return false end
    if self.filter == "Raids" and listing.type ~= "Raid" and listing.type ~= "Ascended" then return false end
    if self.filter == "Keys" and listing.type ~= "Key" then return false end
    if self.filter == "Events" and listing.type ~= "Event" and listing.type ~= "World Boss" then return false end
    if self.filter == "Manastorm" and listing.type ~= "Manastorm" then return false end
    if self.filter == "Quests" and listing.type ~= "Quest" then return false end

    if self.searchText and self.searchText ~= "" then
        local hay = string.lower((listing.activity or "") .. " " .. (listing.leader or "") .. " " .. (listing.note or ""))
        if not string.find(hay, string.lower(self.searchText), 1, true) then return false end
    end

    if listing.seen and now() - listing.seen > LISTING_EXPIRE then return false end
    return true
end

function Listings:GetVisibleListings()
    local out = {}
    for _, l in pairs(self.listings) do
        if self:PassFilter(l) then table.insert(out, l) end
    end
    table.sort(out, function(a, b) return (a.seen or 0) > (b.seen or 0) end)
    return out
end

Listings._core = {
    ACTIVITY_TYPES = ACTIVITY_TYPES,
    APP_PENDING_EXPIRE = APP_PENDING_EXPIRE,
    BOSS_DIFFICULTIES = BOSS_DIFFICULTIES,
    DIFFICULTIES = DIFFICULTIES,
    EVENT_DIFFICULTIES = EVENT_DIFFICULTIES,
    KEY_DIFFICULTIES = KEY_DIFFICULTIES,
    LISTING_EXPIRE = LISTING_EXPIRE,
    LOOT_OPTIONS = LOOT_OPTIONS,
    MANASTORM_DIFFICULTIES = MANASTORM_DIFFICULTIES,
    MAX_BROWSE_ROWS = MAX_BROWSE_ROWS,
    PVP_DIFFICULTIES = PVP_DIFFICULTIES,
    QUEST_DIFFICULTIES = QUEST_DIFFICULTIES,
    RAID_DIFFICULTIES = RAID_DIFFICULTIES,
    ROLES_NEEDED = ROLES_NEEDED,
    TYPE_COLORS = TYPE_COLORS,
    TYPE_ICONS = TYPE_ICONS,
    VOICE_OPTIONS = VOICE_OPTIONS,
    GetActivitiesForType = GetActivitiesForType,
    GetRelevantExpansions = GetRelevantExpansions,
    LPrint = LPrint,
    ageText = ageText,
    classColorText = classColorText,
    classIcon = classIcon,
    memberCount = memberCount,
    now = now,
    roleText = roleText,
}

FrostSeek.Listings = Listings

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("listings", Listings)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("listings")
end
