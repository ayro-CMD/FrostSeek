local FrostSeek = _G.FrostSeek
local Shared = _G.FrostSeekShared
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end
local UI = _G.FrostSeekUIUtils

local Listings = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("listings", Listings)

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
local browseScrollFrame = nil

local ACTIVITY_TYPES = {"Dungeon", "Raid", "World Boss", "Key", "Event", "PvP", "Manastorm"}
local EXPANSIONS = {"Classic", "TBC", "WotLK", "Cata", "MoP", "Custom"}
local DIFFICULTIES = {"Normal", "Heroic", "Mythic"}
local EVENT_DIFFICULTIES = {"Normal"}
local MANASTORM_DIFFICULTIES = {"Normal"}
local KEY_DIFFICULTIES = {"Mythic+"}
local RAID_DIFFICULTIES = {"Normal", "Heroic", "Mythic", "Ascended", "Trial 1", "Trial 2", "Trial 3", "Trial 4", "Trial 5", "Trial 6", "Trial 7", "Trial 8", "Trial 9", "Trial 10"}
local BOSS_DIFFICULTIES = {"Open World", "Instanced", "HC Instanced", "Mythic Instanced", "Ascended Instanced"}
local PVP_DIFFICULTIES = {"Normal", "Ranked"}
local ROLES_NEEDED = {"Tank", "Healer", "DPS"}
local VOICE_OPTIONS = {"None", "Discord", "In-game"}
local LOOT_OPTIONS = {"Group Loot", "Master Looter", "Need Before Greed", "Any"}

local ACTIVITY_DB = {
    DUNGEON = {
        CLASSIC = {"Deadmines", "Wailing Caverns", "Ragefire Chasm", "Shadowfang Keep", "Blackrock Depths", "Blackfathom Deeps", "Scholomance", "Lower Blackrock Spire", "Upper Blackrock Spire", "Dire Maul East", "Dire Maul North", "Dire Maul West", "The Stockade", "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Stratholme"},
        TBC = {"Hellfire Ramparts", "Blood Furnace", "The Shattered Halls", "Slave Pens", "Underbog", "The Steamvault", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth", "Mechanar", "Botanica", "Arcatraz", "Magister's Terrace"},
        WOTLK = {"Utgarde Keep", "Utgarde Pinnacle", "The Nexus", "The Oculus", "Azjol-Nerub", "Ahn'kahet", "Drak'Tharon Keep", "Violet Hold", "Gundrak", "Halls of Stone", "Halls of Lightning", "Culling of Stratholme", "Trial of the Champion", "Forge of Souls", "Pit of Saron", "Halls of Reflection"},
        CATA = {"Blackrock Caverns", "The Throne of the Tides", "The Vortex Pinnacle", "Stonecore", "Lost City of the Tol'vir", "Halls of Origination", "Grim Batol", "Deadmines (Heroic)", "Shadowfang Keep (Heroic)", "Zul'Gurub", "Zul'Aman", "End Time", "Well of Eternity", "Hour of Twilight"},
        MOP = {"Temple of the Jade Serpent", "Stormstout Brewery", "Shado-Pan Monastery", "Mogu'shan Palace", "Scarlet Halls", "Scarlet Monastery", "Siege of Niuzao Temple", "Gate of the Setting Sun", "Scholomance", "Darkheart Thicket", "Violet Hold"},
        CUSTOM = {"GlitterMurk Mines", "Blackrock Cavern", "Tor'Watha", "Bardid Hold", "Vault of the Inquisition", "Road to De' Other Side"},
    },
    RAID = {
        CLASSIC = {"Molten Core", "Onyxia", "Blackwing Lair", "Zul'Gurub", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas"},
        TBC = {"Karazhan", "Gruul's Lair", "Magtheridon", "Serpentshrine Cavern", "Tempest Keep", "Hyjal Summit", "Black Temple", "Zul'Aman", "Sunwell Plateau"},
        WOTLK = {"Eye of Eternity", "Obsidian Sanctum", "Vault of Archavon", "Ulduar", "Trial of the Crusader", "Icecrown Citadel", "Ruby Sanctum"},
        CATA = {"Baradin Hold", "Bastion of Twilight", "Throne of the Four Winds", "Blackwing Descent", "Firelands", "Dragon Soul"},
        MOP = {"Terrace of Endless Spring", "Mogu'shan Vaults", "Heart of Fear", "Throne of Thunder", "Siege of Orgrimmar"},
    },
    ["WORLD BOSS"] = {
        CLASSIC = {"Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Taerar", "Ysondre", "Setis"},
        TBC = {"Doomwalker", "Doom Lord Kazzak"},
        WOTLK = {"Archavon", "Emalon", "Koralon", "Toran"},
        CATA = {"Akma'hat", "Garr", "Julak-Doom", "Mobus", "Poseidus", "Xariona"},
        MOP = {"Sha of Anger", "Galleon", "Nalak", "Oondasta", "Celestials"},
        CUSTOM = {"Soggoth", "Snowgrave", "Atal'Zul", "Kaldros Depthbreaker", "Gonzor", "King Gnok", "King Mosh", "Silithid Lurker", "Volchan", "Corrupted Ancient", "WorldBossTour"},
    },
    PVP = {
        ALL = {"Arena 2v2", "Arena 3v3", "Arena 5v5", "Battlegrounds", "Wintergrasp", "World PvP", "High Risk PvP"},
    },
    EVENT = {
        ALL = {"Custom"},
    },
    KEY = {
        CLASSIC = {"Deadmines", "Wailing Caverns", "Ragefire Chasm", "Shadowfang Keep", "Blackrock Depths", "Blackfathom Deeps", "Scholomance", "Lower Blackrock Spire", "Upper Blackrock Spire", "Dire Maul East", "Dire Maul North", "Dire Maul West", "The Stockade", "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Stratholme"},
        TBC = {"Hellfire Ramparts", "Blood Furnace", "The Shattered Halls", "Slave Pens", "Underbog", "The Steamvault", "Mana-Tombs", "Auchenai Crypts", "Sethekk Halls", "Shadow Labyrinth", "Mechanar", "Botanica", "Arcatraz", "Magister's Terrace"},
        WOTLK = {"Utgarde Keep", "Utgarde Pinnacle", "The Nexus", "The Oculus", "Azjol-Nerub", "Ahn'kahet", "Drak'Tharon Keep", "Violet Hold", "Gundrak", "Halls of Stone", "Halls of Lightning", "Culling of Stratholme", "Trial of the Champion", "Forge of Souls", "Pit of Saron", "Halls of Reflection"},
        CATA = {"Blackrock Caverns", "The Throne of the Tides", "The Vortex Pinnacle", "Stonecore", "Lost City of the Tol'vir", "Halls of Origination", "Grim Batol", "Deadmines", "Shadowfang Keep"},
        MOP = {"Temple of the Jade Serpent", "Stormstout Brewery", "Shado-Pan Monastery", "Mogu'shan Palace", "Scarlet Halls", "Scarlet Monastery", "Siege of Niuzao Temple", "Gate of the Setting Sun", "Scholomance"},
        CUSTOM = {"GlitterMurk Mines", "Blackrock Cavern", "Tor'Watha", "Bardid Hold", "Vault of the Inquisition", "Road to De' Other Side"},
    },
    MANASTORM = {
        ALL = {"ALVA", "Manastorm Gold Farm", "Manastorm Leveling", "Manastorm Bonzo Farm"},
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
}

local TYPE_COLORS = {
    Dungeon = "|cff3fa7ff",
    Raid = "|cff4dff7a",
    ["World Boss"] = "|cffff9a33",
    Key = "|cffb866ff",
    Event = "|cffff9a33",
    Manastorm = "|cffaa66ff",
    PvP = "|cffff5555",
}

local function GetRelevantExpansions()
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
    if typeKey == "PVP" or typeKey == "EVENT" or typeKey == "MANASTORM" then
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
    if s < 60 then return tostring(s) .. "s ago"
    elseif s < 3600 then return tostring(math.floor(s / 60)) .. "m ago"
    else return tostring(math.floor(s / 3600)) .. "h ago" end
end

local function roleText(role)
    if Shared and Shared.GetRoleHex then
        return Shared.GetRoleHex(role) .. (role or "?") .. "|r"
    end
    local colors = { Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555" }
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
        print("|cff88ccffFrostNet:|r New group from |cffffffff" .. tostring(listing.leader) .. "|r — " .. tostring(listing.activity or "?") .. (listing.difficulty and listing.difficulty ~= "" and (" (" .. listing.difficulty .. ")") or ""))
        if Shared and Shared.PlaySound then
            Shared.PlaySound("listing")
        end
    end

    if FrostSeek.SetMinimapCategory then
        local cat = listing.type == "Raid" and "RAID" or
                    listing.type == "Key" and "KEYSTONE" or
                    listing.type == "World Boss" and "WORLD_BOSS" or
                    listing.type == "Dungeon" and "DUNGEON" or
                    listing.type == "Event" and "MANASTORM" or
                    listing.type == "Manastorm" and "MANASTORM" or
                    "DUNGEON"
        FrostSeek.SetMinimapCategory(cat)
        C_Timer.After(30, function()
            if FrostSeek.RemoveMinimapCategory then
                FrostSeek.RemoveMinimapCategory(cat)
            end
        end)
    end

    self:RefreshBrowse()
end

local appPopups = {}
local APP_POPUP_W = 240
local APP_POPUP_H = 82
local APP_POPUP_GAP = 6
local APP_POPUP_MAX = 4
local APP_POPUP_X = 20
local APP_POPUP_Y = -60

local function RepositionAppPopups()
    for i, popup in ipairs(appPopups) do
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", UIParent, "TOPLEFT", APP_POPUP_X, APP_POPUP_Y - ((i - 1) * (APP_POPUP_H + APP_POPUP_GAP)))
    end
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
    C_Timer.After(0.05, RepositionAppPopups)
end

function Listings:ShowApplicantPopup(applicant)
    if not applicant or not applicant.name then return end
    if FrostSeekDB.Listings and FrostSeekDB.Listings.disableAppPopups then return end
    if #appPopups >= APP_POPUP_MAX then
        RemoveAppPopup(appPopups[1])
    end

    local roleColorMap = {
        Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555",
        tank = "|cff4aa3ff", healer = "|cff44ff66", dps = "|cffff5555",
    }
    local roleDisplay = applicant.role or "DPS"
    local roleColor = roleColorMap[roleDisplay] or "|cffffffff"
    local activity = self.myListing and self.myListing.activity or "Unknown"
    local listingType = self.myListing and self.myListing.type or "Dungeon"
    local typeColor = TYPE_COLORS[listingType] or "|cff88ccff"

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(APP_POPUP_W, APP_POPUP_H)
    popup:SetFrameStrata("DIALOG")
    popup:SetAlpha(0)
    if UIFrameFadeIn then
        UIFrameFadeIn(popup, 0.15, 0, 1)
    else
        popup:SetAlpha(1)
    end
    popup.applicantName = applicant.name

    local frostBlue = {0.35, 0.65, 0.95}
    local frostBorder = {0.25, 0.55, 0.85}

    popup.bg = popup:CreateTexture(nil, "BACKGROUND")
    popup.bg:SetAllPoints()
    popup.bg:SetColorTexture(unpack(_tc("bgMenuBg")))

    local glowTop = popup:CreateTexture(nil, "BORDER")
    glowTop:SetPoint("TOPLEFT", 0, 0)
    glowTop:SetPoint("TOPRIGHT", 0, 0)
    glowTop:SetHeight(2)
    glowTop:SetColorTexture(frostBlue[1], frostBlue[2], frostBlue[3], 0.9)

    local glowBot = popup:CreateTexture(nil, "BORDER")
    glowBot:SetPoint("BOTTOMLEFT", 0, 0)
    glowBot:SetPoint("BOTTOMRIGHT", 0, 0)
    glowBot:SetHeight(1)
    glowBot:SetColorTexture(frostBorder[1], frostBorder[2], frostBorder[3], 0.4)

    local glowLeft = popup:CreateTexture(nil, "BORDER")
    glowLeft:SetPoint("TOPLEFT", 0, 0)
    glowLeft:SetPoint("BOTTOMLEFT", 0, 0)
    glowLeft:SetWidth(1)
    glowLeft:SetColorTexture(frostBorder[1], frostBorder[2], frostBorder[3], 0.4)

    local glowRight = popup:CreateTexture(nil, "BORDER")
    glowRight:SetPoint("TOPRIGHT", 0, 0)
    glowRight:SetPoint("BOTTOMRIGHT", 0, 0)
    glowRight:SetWidth(1)
    glowRight:SetColorTexture(frostBorder[1], frostBorder[2], frostBorder[3], 0.4)

    local dot = popup:CreateTexture(nil, "ARTWORK")
    dot:SetSize(8, 8)
    dot:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, -9)
    dot:SetColorTexture(0.35, 0.85, 1, 1)

    local headerText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerText:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -10)
    headerText:SetPoint("RIGHT", popup, "RIGHT", -8, 0)
    headerText:SetJustifyH("LEFT")
    headerText:SetText("|cff88ccffNew |r" .. roleColor .. roleDisplay .. "|r |cff88ccffapplied|r")

    popup.classIcon = popup:CreateTexture(nil, "ARTWORK")
    popup.classIcon:SetSize(16, 16)
    popup.classIcon:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, -24)
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
    local nameText = popup:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    nameText:SetPoint("TOPLEFT", popup, "TOPLEFT", 28, -27)
    nameText:SetText(nameStr)

    local infoText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", popup, "TOPLEFT", 28, -40)
    infoText:SetPoint("RIGHT", popup, "RIGHT", -8, 0)
    infoText:SetJustifyH("LEFT")
    local lvl = applicant.level or "?"
    local ilvl = applicant.itemLevel or "?"
    local gs = applicant.gearScore or "?"
    infoText:SetText("|cff888888Lv|r " .. lvl .. "  |cff88ccffiLvl:|r |cff44ff44" .. ilvl .. "|r  |cff88ccffGS:|r |cffffcc00" .. gs .. "|r  |cff888888Group:|r " .. typeColor .. activity .. "|r")

    local btnW, btnH, btnGap = 70, 20, 6
    local totalBtnW = (btnW * 2) + btnGap
    local btnStartX = (popup:GetWidth() - totalBtnW) / 2

    local acceptBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, btnW, btnH, "Accept", {0.15, 0.5, 0.25})
    if not acceptBtn then
        acceptBtn = CreateFrame("Button", nil, popup)
        acceptBtn:SetSize(btnW, btnH)
        acceptBtn:SetText("Accept")
    end
    acceptBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", btnStartX, 6)
    acceptBtn:SetScript("OnClick", function()
        Listings:AcceptApplicant(applicant.name)
        RemoveAppPopup(popup)
    end)

    local declineBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, btnW, btnH, "Decline", {0.5, 0.15, 0.15})
    if not declineBtn then
        declineBtn = CreateFrame("Button", nil, popup)
        declineBtn:SetSize(btnW, btnH)
        declineBtn:SetText("Decline")
    end
    declineBtn:SetPoint("LEFT", acceptBtn, "RIGHT", btnGap, 0)
    declineBtn:SetScript("OnClick", function()
        Listings:DeclineApplicant(applicant.name)
        RemoveAppPopup(popup)
    end)

    popup:SetScript("OnUpdate", function(self, elapsed)
        if GetTime() >= self.expiryTime then
            self:SetScript("OnUpdate", nil)
            RemoveAppPopup(self)
        end
    end)
    popup.expiryTime = GetTime() + 12

    table.insert(appPopups, popup)
    RepositionAppPopups()
end

function Listings:HandleIncomingApplicant(applicant)
    if not applicant or not applicant.name then return end
    if not self.myListing or applicant.listingId ~= self.myListing.id then return end

    self.applicants[applicant.name] = applicant
    print("|cff88ccffFrostNet:|r " .. tostring(applicant.name) .. " applied for " .. tostring(self.myListing.activity))

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

function Listings:HandleDecision(target, result, activity)
    if target ~= playerName() then return end
    local act = activity or "the group"
    if result == "accepted" then
        print("|cff88ccffFrostNet:|r |cff44ff44Application accepted|r for " .. act .. "!")
    else
        print("|cff88ccffFrostNet:|r |cffff5555Application declined|r for " .. act)
    end

    for id, app in pairs(self.myApplications) do
        if app.status == "pending" and app.activity == act then
            app.status = result == "accepted" and "accepted" or "declined"
            app.decidedAt = time()
            break
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
        print("|cff88ccffFrostNet:|r Previous listing removed (only one group allowed at a time)")
    end

    local id = FrostSeek.Protocol.GenerateId()
    local listing = {
        id = id,
        activity = activity or "Unknown",
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

    print("|cff88ccffFrostNet:|r Group created: " .. tostring(activity))
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
            print("|cff88ccffFrostNet:|r Group full, listing removed for " .. activity)
        else
            print("|cff88ccffFrostNet:|r Listing removed for " .. activity)
        end
        self:RefreshBrowse()
    end

    if reason == "full" then
        doCancel()
    else
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog("Remove Listing", "Are you sure you want to remove your listing for " .. activity .. "?", doCancel)
        else
            doCancel()
        end
    end
end

function Listings:Apply()
    local id = self.selectedListing
    if not id then
        print("|cff88ccffFrostNet:|r Select a group before applying")
        return
    end
    local listing = self.listings[id]
    if not listing then return end

    if listing.leader == playerName() then
        print("|cff88ccffFrostNet:|r You cannot apply to your own group!")
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
    print("|cff88ccffFrostNet:|r Application sent for " .. tostring(listing.activity))

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
    print("|cff88ccffFrostNet:|r Accepted and invited " .. tostring(name))
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
    print("|cff88ccffFrostNet:|r Application declined")
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

function Listings:ScrollBrowse(direction)
    if not browseScrollFrame then return end
    local range = self.browseScrollChild:GetHeight() - browseScrollFrame:GetHeight()
    if range <= 0 then return end
    local cur = browseScrollFrame:GetVerticalScroll()
    if direction == "UP" then
        browseScrollFrame:SetVerticalScroll(math.max(0, cur - 30))
    elseif direction == "DOWN" then
        browseScrollFrame:SetVerticalScroll(math.min(range, cur + 30))
    end
end

function Listings:Initialize(parentFrame)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local F = self.frame
    local pad = 14
    local curY = -10

    self.subTab = "browse"

    self.subTabs = {}
    local subTabDefs = {
        { id = "browse", name = "Browse" },
        { id = "create", name = "Create Group" },
        { id = "mylisting", name = "My Group" },
        { id = "applications", name = "Applications" },
        { id = "profile", name = "Profile" },
    }

    for i, st in ipairs(subTabDefs) do
        local btn = CreateFrame("Button", nil, F)
        btn:SetSize(120, 26)
        btn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + (i - 1) * 125, curY)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(st.name)
        btn.text:SetTextColor(unpack(_tc("textNorm")))

        btn.subId = st.id
        btn:SetScript("OnClick", function(self)
            Listings.subTab = self.subId
            Listings:RefreshSubTabs()
            Listings:RefreshContent()
        end)

        self.subTabs[st.id] = btn
    end
    curY = curY - 35

    self.content = CreateFrame("Frame", nil, F)
    self.content:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    self.content:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad, pad)
    self:BuildBrowseFrame()
    self:BuildCreateFrame()
    self:BuildMyListingFrame()
    self:BuildApplicationsFrame()
    self.profileFrame = CreateFrame("Frame", nil, self.content)
    self.profileFrame:SetAllPoints(self.content)
    self.profileFrame:Hide()
    if FrostSeek.Profile and FrostSeek.Profile.Initialize then
        FrostSeek.Profile:Initialize(self.profileFrame)
    end

    self:RefreshSubTabs()
    self:RefreshContent()

    self.frame:Hide()
end

function Listings:RefreshSubTabs()
    for id, btn in pairs(self.subTabs) do
        if id == self.subTab then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.border:SetColorTexture(unpack(_tc("borderFocus")))
            btn.text:SetTextColor(unpack(_tc("textPrimary")))
        else
            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
            btn.border:SetColorTexture(unpack(_tc("border")))
            btn.text:SetTextColor(unpack(_tc("textNorm")))
        end
    end
end

function Listings:RefreshContent()
    if self.browseFrame then self.browseFrame:SetShown(self.subTab == "browse") end
    if self.createFrame then self.createFrame:SetShown(self.subTab == "create") end
    if self.myListingFrame then self.myListingFrame:SetShown(self.subTab == "mylisting") end
    if self.applicationsFrame then self.applicationsFrame:SetShown(self.subTab == "applications") end
    if self.profileFrame then self.profileFrame:SetShown(self.subTab == "profile") end

    if self.subTab == "browse" then self:RefreshBrowse()
    elseif self.subTab == "mylisting" then self:RefreshMyListing()
    elseif self.subTab == "applications" then self:RefreshApplications()
    elseif self.subTab == "profile" then
        if FrostSeek.Profile and FrostSeek.Profile.Show then
            FrostSeek.Profile:Show()
        end
    end
end

function Listings:BuildBrowseFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.browseFrame = f

    local filters = {"All", "Dungeons", "Raids", "Keys", "Events", "Manastorm"}
    self.filterButtons = {}
    for i, ft in ipairs(filters) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(75, 22)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", (i - 1) * 80, 0)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(_tc("bgBlock")))
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(ft)
        btn.text:SetTextColor(unpack(_tc("textNorm")))
        btn.filterType = ft
        btn:SetScript("OnClick", function(self)
            Listings.filter = self.filterType
            if browseScrollFrame then browseScrollFrame:SetVerticalScroll(0) end
            Listings:RefreshFilterButtons()
            Listings:RefreshBrowse()
        end)
        self.filterButtons[ft] = btn
    end

    self.searchBox = UI and UI.CreateModernEditBox(f, 200, 20) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.searchBox:SetAutoFocus(false)
        self.searchBox:SetFontObject("GameFontNormalSmall")
        self.searchBox:SetWidth(200)
        self.searchBox:SetHeight(20)
    end
    self.searchBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    self.searchBox:SetScript("OnTextChanged", function(self)
        Listings.searchText = self:GetText() or ""
        if browseScrollFrame then browseScrollFrame:SetVerticalScroll(0) end
        Listings:RefreshBrowse()
    end)

    self.browseCount = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.browseCount:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -24)
    self.browseCount:SetTextColor(unpack(_tc("textDim")))

    local browseListFrame = CreateFrame("Frame", nil, f)
    browseListFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -44)
    browseListFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 135)

    browseScrollFrame = CreateFrame("ScrollFrame", "FrostSeekBrowseScroll", browseListFrame, "UIPanelScrollFrameTemplate")
    browseScrollFrame:SetPoint("TOPLEFT", browseListFrame, "TOPLEFT", 0, 0)
    browseScrollFrame:SetPoint("BOTTOMRIGHT", browseListFrame, "BOTTOMRIGHT", 0, 0)

    local scrollChild = CreateFrame("Frame", nil, browseScrollFrame)
    scrollChild:SetSize(750, 200)
    browseScrollFrame:SetScrollChild(scrollChild)
    self.browseScrollChild = scrollChild

    self.browseRows = {}
    for i = 1, MAX_BROWSE_ROWS do
        local r = CreateFrame("Button", nil, scrollChild)
        r:SetWidth(750)
        r:SetHeight(28)
        if i == 1 then
            r:SetPoint("TOP", scrollChild, "TOP", 0, 0)
        else
            r:SetPoint("TOP", self.browseRows[i-1], "BOTTOM", 0, 2)
        end

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(20, 20)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)

        r.title = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.title:SetPoint("LEFT", r, "LEFT", 28, 0)
        r.title:SetWidth(180)
        r.title:SetJustifyH("LEFT")

        r.leaderIcon = r:CreateTexture(nil, "ARTWORK")
        r.leaderIcon:SetSize(16, 16)
        r.leaderIcon:SetPoint("LEFT", r, "LEFT", 212, 0)
        r.leaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.leaderIcon:Hide()

        r.leader = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.leader:SetPoint("LEFT", r, "LEFT", 232, 0)
        r.leader:SetWidth(70)

        r.diff = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.diff:SetPoint("LEFT", r, "LEFT", 305, 0)
        r.diff:SetWidth(80)

        r.ilvl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.ilvl:SetPoint("LEFT", r, "LEFT", 388, 0)
        r.ilvl:SetWidth(50)

        r.members = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.members:SetPoint("LEFT", r, "LEFT", 440, 0)
        r.members:SetWidth(55)

        r.roles = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.roles:SetPoint("LEFT", r, "LEFT", 497, 0)
        r.roles:SetWidth(80)
        r.roles:SetJustifyH("LEFT")

        r.note = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.note:SetPoint("LEFT", r, "LEFT", 579, 0)
        r.note:SetWidth(170)
        r.note:SetJustifyH("LEFT")

        r:SetScript("OnClick", function()
            if r.listingId then
                Listings.selectedListing = r.listingId
                Listings:RefreshBrowse()
            end
        end)
        r:SetScript("OnDoubleClick", function()
            if r.listingId then
                Listings.selectedListing = r.listingId
                Listings:Apply()
            end
        end)

        self.browseRows[i] = r
        r:Hide()
    end

    self.scrollIndicator = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.scrollIndicator:SetPoint("BOTTOM", f, "BOTTOM", 0, -12)
    self.scrollIndicator:SetText("")
    self.scrollIndicator:SetTextColor(unpack(_tc("textDim")))

    self.detailPanel = CreateFrame("Frame", nil, f)
    self.detailPanel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    self.detailPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    self.detailPanel:SetHeight(120)

    local dpBg = self.detailPanel:CreateTexture(nil, "BACKGROUND")
    dpBg:SetAllPoints()
    dpBg:SetColorTexture(unpack(_tc("bgBlock")))

    self.detailText = self.detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.detailText:SetPoint("TOPLEFT", self.detailPanel, "TOPLEFT", 10, -8)
    self.detailText:SetPoint("TOPRIGHT", self.detailPanel, "TOPRIGHT", -10, -8)
    self.detailText:SetHeight(80)
    self.detailText:SetJustifyH("LEFT")
    self.detailText:SetJustifyV("TOP")
    self.detailText:SetText(_hex("textDim") .. "Select a group to see details|r")

    self.applyBtn = UI and UI.CreateModernButton(self.detailPanel, 120, 26, "Apply") or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.applyBtn:SetSize(120, 26)
        self.applyBtn:SetText("Apply")
    end
    self.applyBtn:SetPoint("BOTTOMRIGHT", self.detailPanel, "BOTTOMRIGHT", -10, 8)
    self.applyBtn:SetScript("OnClick", function() Listings:Apply() end)

    self.whisperBtn = UI and UI.CreateModernButton(self.detailPanel, 90, 26, "Whisper") or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.whisperBtn:SetSize(90, 26)
        self.whisperBtn:SetText("Whisper")
    end
    self.whisperBtn:SetPoint("BOTTOMRIGHT", self.applyBtn, "BOTTOMLEFT", -8, 0)
    self.whisperBtn:SetScript("OnClick", function()
        local l = Listings.listings[Listings.selectedListing]
        if l and l.leader then
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat("/w " .. l.leader .. " ")
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat("/w " .. l.leader .. " ")
            end
        end
    end)

    self.frostnetBtn = UI and UI.CreateModernButton(self.detailPanel, 100, 26, "FrostNet", _tc("accent")) or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.frostnetBtn:SetSize(100, 26)
        self.frostnetBtn:SetText("FrostNet")
    end
    self.frostnetBtn:SetPoint("BOTTOMLEFT", self.whisperBtn, "BOTTOMLEFT", -108, 0)
    self.frostnetBtn:SetScript("OnClick", function()
        if FrostSeek.Presence then
            FrostSeek.Presence:TogglePanel(FrostSeek.MainFrame)
        end
    end)

    self:RefreshFilterButtons()
end

function Listings:RefreshFilterButtons()
    for ft, btn in pairs(self.filterButtons) do
        if ft == self.filter then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.text:SetTextColor(unpack(_tc("textPrimary")))
        else
            btn.bg:SetColorTexture(unpack(_tc("bgBlock")))
            btn.text:SetTextColor(unpack(_tc("textNorm")))
        end
    end
end

function Listings:RefreshBrowse()
    if not self.browseFrame then return end
    local list = self:GetVisibleListings()
    local totalFiltered = #list

    if self.browseCount then
        self.browseCount:SetText("Active groups: " .. tostring(totalFiltered))
    end

    if self.scrollIndicator then
        self.scrollIndicator:SetText(tostring(totalFiltered) .. " groups")
    end

    local scrollChild = self.browseScrollChild
    if scrollChild then
        scrollChild:SetHeight(math.max(200, totalFiltered * 30 + 4))
    end

    for i, row in ipairs(self.browseRows) do
        local l = list[i]
        if l then
            row:Show()
            row.listingId = l.id

            if l.id == self.selectedListing then
                row.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            else
                row.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))
            end

            local icon = TYPE_ICONS[l.type] or TYPE_ICONS.Dungeon
            row.icon:SetTexture(icon)
            row.title:SetText((TYPE_COLORS[l.type] or "|cffffffff") .. (l.activity or "?") .. "|r")

            if row.leaderIcon then
                local leaderName = tostring(l.leader or "")
                local cf = nil
                if leaderName ~= "" and FrostSeek.Presence and FrostSeek.Presence.onlineUsers then
                    local u = FrostSeek.Presence.onlineUsers[leaderName]
                    if u and u.classFile and u.classFile ~= "" then
                        cf = u.classFile
                    end
                end
                if cf then
                    row.leaderIcon:SetTexture(classIcon(cf))
                    row.leaderIcon:Show()
                else
                    row.leaderIcon:Hide()
                end
            end

            row.leader:SetText(tostring(l.leader or ""))
            row.diff:SetText(tostring(l.difficulty or ""))
            row.ilvl:SetText((l.minItemLevel and l.minItemLevel ~= "") and (l.minItemLevel .. "+") or "--")
            row.members:SetText(tostring(l.members or 1) .. "/" .. tostring(l.maxMembers or 5))
            if l.roles and l.roles ~= "" then
                local roleStr = ""
                for roleName in string.gmatch(l.roles, "[^/]+") do
                    roleStr = roleStr .. roleText(roleName) .. " "
                end
                row.roles:SetText(roleStr ~= "" and roleStr or "--")
            else
                row.roles:SetText(_hex("textDim") .. "Any|r")
            end
            row.note:SetText(tostring(l.note or ""))
        else
            row:Hide()
            row.listingId = nil
            if row.leaderIcon then row.leaderIcon:Hide() end
        end
    end

    local sl = self.listings[self.selectedListing]
    if sl then
        local lines = {}
        table.insert(lines, (TYPE_COLORS[sl.type] or "|cffffffff") .. tostring(sl.activity) .. "|r  " .. tostring(sl.difficulty or ""))
        table.insert(lines, _hex("textDim") .. "Leader:|r " .. tostring(sl.leader or "?") .. "   " .. _hex("textDim") .. "Members:|r " .. tostring(sl.members or 1) .. "/" .. tostring(sl.maxMembers or 5))
        if sl.roles and sl.roles ~= "" then
            local detailRoles = ""
            for roleName in string.gmatch(sl.roles, "[^/]+") do
                detailRoles = detailRoles .. roleText(roleName) .. "  "
            end
            if detailRoles ~= "" then
                table.insert(lines, _hex("textDim") .. "LF:|r " .. detailRoles)
            end
        end
        if sl.minItemLevel and sl.minItemLevel ~= "" then
            table.insert(lines, _hex("textDim") .. "Min iLvl:|r " .. sl.minItemLevel .. "+")
        end
        if sl.voice and sl.voice ~= "None" then
            table.insert(lines, _hex("textDim") .. "Voice:|r " .. tostring(sl.voice))
        end
        if sl.loot and sl.loot ~= "Group Loot" then
            table.insert(lines, _hex("textDim") .. "Loot:|r " .. tostring(sl.loot))
        end
        if sl.note and sl.note ~= "" then
            table.insert(lines, _hex("textDim") .. "Note:|r " .. tostring(sl.note))
        end
        table.insert(lines, _hex("textDim") .. "Published:|r " .. ageText(sl.created))
        self.detailText:SetText(table.concat(lines, "\n"))
    else
        self.detailText:SetText(_hex("textDim") .. "Select a group to see details|r")
    end
end

local MAX_APP_ROWS = 10

function Listings:BuildApplicationsFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.applicationsFrame = f

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    title:SetText("|cff88ccffMy Applications|r")

    self.appCount = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.appCount:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -4)
    self.appCount:SetTextColor(unpack(_tc("textDim")))

    local header = CreateFrame("Frame", nil, f)
    header:SetWidth(750)
    header:SetHeight(22)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -30)
    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetColorTexture(unpack(_tc("bgBlock")))

    local hLabels = {{"Activity", 4}, {"Type", 200}, {"Leader", 280}, {"Key", 360}, {"Status", 460}, {"Applied", 550}, {"Decided", 630}}
    for _, lbl in ipairs(hLabels) do
        local t = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("LEFT", header, "LEFT", lbl[2], 0)
        t:SetText(_hex("textDim") .. lbl[1] .. "|r")
    end

    self.appRows = {}
    for i = 1, MAX_APP_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(750)
        r:SetHeight(26)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -54 - ((i - 1) * 28))

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))

        r.activity = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.activity:SetPoint("LEFT", r, "LEFT", 4, 0)
        r.activity:SetWidth(192)
        r.activity:SetJustifyH("LEFT")

        r.type = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.type:SetPoint("LEFT", r, "LEFT", 200, 0)
        r.type:SetWidth(78)

        r.leader = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.leader:SetPoint("LEFT", r, "LEFT", 280, 0)
        r.leader:SetWidth(78)

        r.key = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.key:SetPoint("LEFT", r, "LEFT", 360, 0)
        r.key:SetWidth(98)
        r.key:SetJustifyH("LEFT")

        r.status = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.status:SetPoint("LEFT", r, "LEFT", 460, 0)
        r.status:SetWidth(88)

        r.applied = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.applied:SetPoint("LEFT", r, "LEFT", 550, 0)
        r.applied:SetWidth(78)

        r.decided = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.decided:SetPoint("LEFT", r, "LEFT", 630, 0)
        r.decided:SetWidth(78)

        r:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        end)
        r:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))
        end)

        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.appData and self.appData.status == "pending" then
                Listings:WithdrawApplication(self.appData.id)
            end
        end)

        self.appRows[i] = r
        r:Hide()
    end

    self.clearAppsBtn = UI and UI.CreateModernButton(f, 140, 24, "Clear History", _tc("catPvP")) or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    if not UI then
        self.clearAppsBtn:SetSize(140, 24)
        self.clearAppsBtn:SetText("Clear History")
    end
    self.clearAppsBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    self.clearAppsBtn:SetScript("OnClick", function()
        local function doClear()
            for id, app in pairs(Listings.myApplications) do
                if app.status ~= "pending" then
                    Listings.myApplications[id] = nil
                end
            end
            Listings:RefreshApplications()
        end
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog("Clear History", "Clear all non-pending application history?", doClear)
        else
            doClear()
        end
    end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", self.clearAppsBtn, "BOTTOMRIGHT", 12, 4)
    hint:SetText(_hex("textDim") .. "Right-click pending app to withdraw|r")

    f:Hide()
end

function Listings:RefreshApplications()
    if not self.applicationsFrame then return end

    local apps = {}
    for id, app in pairs(self.myApplications) do
        table.insert(apps, app)
    end
    table.sort(apps, function(a, b)
        return (a.appliedAt or 0) > (b.appliedAt or 0)
    end)

    local pending = 0
    for _, app in ipairs(apps) do
        if app.status == "pending" then pending = pending + 1 end
    end
    if self.appCount then
        self.appCount:SetText("Total: " .. #apps .. "  |  Pending: " .. pending)
    end

    for i, row in ipairs(self.appRows) do
        local app = apps[i]
        if app then
            row:Show()
            row.appData = app

            local typeColor = TYPE_COLORS[app.type] or "|cffffffff"
            row.activity:SetText(typeColor .. (app.activity or "?") .. "|r")
            row.type:SetText(tostring(app.type or ""))
            row.leader:SetText(tostring(app.leader or ""))

            if app.key and app.key ~= "" then
                row.key:SetText("|cffb866ff" .. tostring(app.key) .. "|r")
            else
                row.key:SetText(_hex("textDim") .. "--|r")
            end

            local statusText = app.status or "pending"
            if statusText == "pending" then
                row.status:SetText("|cffffcc00Pending|r")
            elseif statusText == "accepted" then
                row.status:SetText("|cff44ff44Accepted|r")
            elseif statusText == "declined" then
                row.status:SetText("|cffff5555Declined|r")
            elseif statusText == "withdrawn" then
                row.status:SetText("|cff888888Withdrawn|r")
            elseif statusText == "expired" then
                row.status:SetText("|cffff8800Expired|r")
            else
                row.status:SetText(tostring(statusText))
            end

            if app.appliedAt then
                row.applied:SetText(ageText(app.appliedAt))
            else
                row.applied:SetText("--")
            end

            if app.decidedAt then
                row.decided:SetText(ageText(app.decidedAt))
            else
                row.decided:SetText(_hex("textDim") .. "--|r")
            end
        else
            row:Hide()
            row.appData = nil
        end
    end
end

function Listings:WithdrawApplication(id)
    if not id or not self.myApplications[id] then return end
    self.myApplications[id].status = "withdrawn"
    self.myApplications[id].decidedAt = time()
    print("|cff88ccffFrostNet:|r Application withdrawn for " .. tostring(self.myApplications[id].activity))
    self:RefreshApplications()
end

function Listings:BuildCreateFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.createFrame = f

    local curY = -5
    local leftPad = 10
    local labelW = 120
    local inputW = 250
    local rowH = 32

    local tLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    tLabel:SetText(_hex("accent") .. "Type|r")

    self.createType = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createType:SetSize(200, 24)
    end
    self.createType:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createType.SetOptions then
        self.createType:SetOptions(ACTIVITY_TYPES)
        self.createType:SetText("Dungeon")
    end
    curY = curY - rowH

    local eLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    eLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    eLabel:SetText(_hex("accent") .. "Expansion|r")

    self.createExpansion = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createExpansion:SetSize(200, 24)
    end
    self.createExpansion:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createExpansion.SetOptions then
        self.createExpansion:SetOptions(EXPANSIONS)
        self.createExpansion:SetText("Classic")
    end
    curY = curY - rowH

    local aLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    aLabel:SetText(_hex("accent") .. "Activity|r")

    self.createActivity = UI and UI.CreateModernDropdown(f, inputW, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createActivity:SetSize(inputW, 24)
    end
    self.createActivity:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    local initialActs = GetActivitiesForType("Classic", "Dungeon")
    if self.createActivity.SetOptions then
        self.createActivity:SetOptions(initialActs)
        if #initialActs > 0 then self.createActivity:SetText(initialActs[1]) end
    end

    self.createActivityEdit = nil
    curY = curY - rowH

    local dLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    dLabel:SetText(_hex("accent") .. "Difficulty|r")

    self.createDiff = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createDiff:SetSize(200, 24)
    end
    self.createDiff:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createDiff.SetOptions then
        self.createDiff:SetOptions(DIFFICULTIES)
        self.createDiff:SetText("Normal")
    end
    curY = curY - rowH

    local kLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    kLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    kLabel:SetText(_hex("accent") .. "Key Level|r")
    self.createKeyLevelLabel = kLabel

    self.createKeyLevel = UI and UI.CreateModernEditBox(f, 60, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createKeyLevel:SetAutoFocus(false)
        self.createKeyLevel:SetFontObject("GameFontNormalSmall")
        self.createKeyLevel:SetWidth(60)
        self.createKeyLevel:SetHeight(24)
    end
    self.createKeyLevel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createKeyLevel:SetText("")
    self.createKeyLevel:SetNumeric(true)
    self.createKeyLevel:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.createKeyLevel:Hide()
    kLabel:Hide()
    curY = curY - rowH

    local rLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    rLabel:SetText(_hex("accent") .. "Roles Needed|r")

    self.createRoles = { Tank = false, Healer = false, DPS = false }
    self.createRoleToggles = {}
    local roleColors = { Tank = _tc("catDungeon"), Healer = _tc("success"), DPS = _tc("danger") }
    local roleLabels = { Tank = "Tank", Healer = "Healer", DPS = "DPS" }

    for i, role in ipairs(ROLES_NEEDED) do
        local toggle
        if UI and UI.CreateSmallToggle then
            toggle = UI.CreateSmallToggle(f, roleLabels[role], (i - 1) * 95, 0, 80, 22, function(active)
                Listings.createRoles[role] = active
            end)
        else
            toggle = CreateFrame("Button", nil, f)
            toggle:SetSize(80, 22)
            toggle:SetPoint("LEFT", f, "LEFT", leftPad + labelW + (i - 1) * 95, 0)
            toggle.bg = toggle:CreateTexture(nil, "BACKGROUND")
            toggle.bg:SetAllPoints()
            toggle.bg:SetColorTexture(0.1, 0.1, 0.12, 0.4)
            toggle.text = toggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            toggle.text:SetPoint("CENTER")
            toggle.text:SetText(roleLabels[role])
            toggle.text:SetTextColor(0.7, 0.7, 0.7)
            toggle.active = false
            toggle:SetScript("OnClick", function(self)
                self.active = not self.active
                self.text:SetTextColor(self.active and 0.4 or 0.7, self.active and 1 or 0.7, self.active and 0.4 or 0.7)
                Listings.createRoles[role] = self.active
            end)
        end
        if toggle.ClearAllPoints then
            toggle:ClearAllPoints()
            toggle:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW + (i - 1) * 95, curY + 4)
        end
        self.createRoleToggles[role] = toggle
    end
    curY = curY - rowH

    local mLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    mLabel:SetText(_hex("accent") .. "Max Members|r")

    self.createMaxMembers = UI and UI.CreateModernEditBox(f, 60, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createMaxMembers:SetAutoFocus(false)
        self.createMaxMembers:SetFontObject("GameFontNormalSmall")
        self.createMaxMembers:SetWidth(60)
        self.createMaxMembers:SetHeight(24)
    end
    self.createMaxMembers:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createMaxMembers:SetText("5")
    self.createMaxMembers:SetNumeric(true)
    self.createMaxMembers:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - rowH

    local iLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    iLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    iLabel:SetText(_hex("accent") .. "Min iLvl|r")

    self.createMinIlvl = UI and UI.CreateModernEditBox(f, 80, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createMinIlvl:SetAutoFocus(false)
        self.createMinIlvl:SetFontObject("GameFontNormalSmall")
        self.createMinIlvl:SetWidth(80)
        self.createMinIlvl:SetHeight(24)
    end
    self.createMinIlvl:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createMinIlvl:SetText("")
    self.createMinIlvl:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - rowH

    local vLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    vLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    vLabel:SetText(_hex("accent") .. "Voice Chat|r")

    self.createVoice = UI and UI.CreateModernDropdown(f, 150, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createVoice:SetSize(150, 24)
    end
    self.createVoice:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createVoice.SetOptions then
        self.createVoice:SetOptions(VOICE_OPTIONS)
        self.createVoice:SetText("None")
    end
    curY = curY - rowH

    local lLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    lLabel:SetText(_hex("accent") .. "Loot Method|r")

    self.createLoot = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createLoot:SetSize(200, 24)
    end
    self.createLoot:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createLoot.SetOptions then
        self.createLoot:SetOptions(LOOT_OPTIONS)
        self.createLoot:SetText("Group Loot")
    end
    curY = curY - rowH

    local nLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    nLabel:SetText(_hex("accent") .. "Note|r")

    self.createNote = UI and UI.CreateModernEditBox(f, 400, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createNote:SetAutoFocus(false)
        self.createNote:SetFontObject("GameFontNormalSmall")
        self.createNote:SetWidth(400)
        self.createNote:SetHeight(24)
    end
    self.createNote:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createNote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - rowH - 10

    self.createBtn = UI and UI.CreateModernButton(f, 160, 30, "Publish Group") or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    if not UI then
        self.createBtn:SetSize(160, 30)
        self.createBtn:SetText("|cff44ff44Publish Group|r")
    end
    self.createBtn:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createBtn:SetScript("OnClick", function()
        Listings:SubmitCreate()
    end)

    self.createType.onChange = function(selected)
        local ltype = selected or "Dungeon"

        if Listings.createExpansion then
            if ltype == "PvP" or ltype == "Event" or ltype == "Manastorm" then
                Listings.createExpansion:SetAlpha(0.4)
                Listings.createExpansion.button:Disable()
            else
                Listings.createExpansion:SetAlpha(1.0)
                Listings.createExpansion.button:Enable()
                if Listings.createExpansion.SetOptions then
                    Listings.createExpansion:SetOptions(EXPANSIONS)
                    Listings.createExpansion:SetText("Classic")
                end
            end
        end

        local expansion = Listings.createExpansion and Listings.createExpansion.GetText and Listings.createExpansion:GetText() or "Classic"
        local acts = GetActivitiesForType(expansion, ltype)
        if Listings.createActivity and Listings.createActivity.SetOptions then
            Listings.createActivity:SetOptions(acts)
            if #acts > 0 then Listings.createActivity:SetText(acts[1]) end
        end

        if Listings.createDiff and Listings.createDiff.SetOptions then
            if ltype == "Key" then
                Listings.createDiff:SetOptions(KEY_DIFFICULTIES)
                Listings.createDiff:SetText("Mythic+")
            elseif ltype == "Raid" then
                Listings.createDiff:SetOptions(RAID_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "World Boss" then
                Listings.createDiff:SetOptions(BOSS_DIFFICULTIES)
                Listings.createDiff:SetText("Open World")
            elseif ltype == "PvP" then
                Listings.createDiff:SetOptions(PVP_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "Event" then
                Listings.createDiff:SetOptions(EVENT_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "Manastorm" then
                Listings.createDiff:SetOptions(MANASTORM_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            else
                Listings.createDiff:SetOptions(DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            end
        end

        if ltype == "Key" then
            if Listings.createKeyLevel then Listings.createKeyLevel:Show() end
            if Listings.createKeyLevelLabel then Listings.createKeyLevelLabel:Show() end
        else
            if Listings.createKeyLevel then Listings.createKeyLevel:Hide() end
            if Listings.createKeyLevelLabel then Listings.createKeyLevelLabel:Hide() end
        end
    end

    self.createExpansion.onChange = function(selected)
        local ltype = Listings.createType and Listings.createType.GetText and Listings.createType:GetText() or "Dungeon"
        local acts = GetActivitiesForType(selected, ltype)
        if Listings.createActivity and Listings.createActivity.SetOptions then
            Listings.createActivity:SetOptions(acts)
            if #acts > 0 then Listings.createActivity:SetText(acts[1]) end
        end
    end

    f:Hide()
end

function Listings:SubmitCreate()
    local activity = self.createActivity and self.createActivity.GetText and self.createActivity:GetText() or ""
    if activity == "" then
        print("|cff88ccffFrostNet:|r Select an activity!")
        return
    end

    local ltype = self.createType and self.createType.GetText and self.createType:GetText() or "Dungeon"
    local diff = self.createDiff and self.createDiff.GetText and self.createDiff:GetText() or "Normal"
    local keyLvl = self.createKeyLevel and self.createKeyLevel.GetText and self.createKeyLevel:GetText() or ""

    if ltype == "Key" and keyLvl ~= "" then
        diff = "Mythic+ " .. tostring(keyLvl)
    end
    local maxM = self.createMaxMembers and tonumber(self.createMaxMembers:GetText()) or 5
    local minIlvl = self.createMinIlvl and self.createMinIlvl:GetText() or ""
    local voice = self.createVoice and self.createVoice.GetText and self.createVoice:GetText() or "None"
    local note = self.createNote and self.createNote:GetText() or ""
    local keyData = ltype == "Key" and keyLvl or ""
    local loot = self.createLoot and self.createLoot.GetText and self.createLoot:GetText() or "Group Loot"

    local rolesList = {}
    if self.createRoles then
        for role, active in pairs(self.createRoles) do
            if active then table.insert(rolesList, role) end
        end
    end
    local rolesStr = table.concat(rolesList, "/")

    self:CreateListing(activity, ltype, diff, rolesStr, minIlvl, maxM, voice, loot, note, keyData)

    self.subTab = "mylisting"
    self:RefreshSubTabs()
    self:RefreshContent()
end

function Listings:BuildMyListingFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.myListingFrame = f
    self.myListingInfo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.myListingInfo:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    self.myListingInfo:SetWidth(740)
    self.myListingInfo:SetHeight(100)
    self.myListingInfo:SetJustifyH("LEFT")
    self.myListingInfo:SetJustifyV("TOP")
    self.applicantsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.applicantsLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -120)
    self.applicantsLabel:SetText("|cff88ccffApplicants|r")
    self.applicantRows = {}
    for i = 1, 8 do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(750)
        r:SetHeight(26)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -145 - ((i - 1) * 28))

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)

        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.name:SetPoint("LEFT", r, "LEFT", 26, 0)
        r.name:SetWidth(100)

        r.class = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.class:SetPoint("LEFT", r, "LEFT", 130, 0)
        r.class:SetWidth(70)

        r.role = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.role:SetPoint("LEFT", r, "LEFT", 205, 0)
        r.role:SetWidth(50)

        r.ilvl = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.ilvl:SetPoint("LEFT", r, "LEFT", 260, 0)
        r.ilvl:SetWidth(50)

        r.gs = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.gs:SetPoint("LEFT", r, "LEFT", 315, 0)
        r.gs:SetWidth(50)

        r.note = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.note:SetPoint("LEFT", r, "LEFT", 370, 0)
        r.note:SetWidth(200)
        r.note:SetJustifyH("LEFT")

        r.acceptBtn = UI and UI.CreateModernButton(r, 55, 20, "OK") or CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        if not UI then
            r.acceptBtn:SetSize(55, 20)
            r.acceptBtn:SetText("OK")
        end
        r.acceptBtn:SetPoint("RIGHT", r, "RIGHT", -62, 0)
        r.acceptBtn:SetScript("OnClick", function()
            if r.applicantName then Listings:AcceptApplicant(r.applicantName) end
        end)

        r.declineBtn = UI and UI.CreateModernButton(r, 55, 20, "No") or CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        if not UI then
            r.declineBtn:SetSize(55, 20)
            r.declineBtn:SetText("No")
        end
        r.declineBtn:SetPoint("RIGHT", r, "RIGHT", -4, 0)
        r.declineBtn:SetScript("OnClick", function()
            if r.applicantName then Listings:DeclineApplicant(r.applicantName) end
        end)

        self.applicantRows[i] = r
        r:Hide()
    end

    self.cancelBtn = UI and UI.CreateModernButton(f, 140, 28, "Remove Listing") or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    if not UI then
        self.cancelBtn:SetSize(140, 28)
        self.cancelBtn:SetText("|cffff5555Remove Listing|r")
    end
    self.cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    self.cancelBtn:SetScript("OnClick", function() Listings:CancelListing("manual") end)

    f:Hide()
end

function Listings:RefreshMyListing()
    if not self.myListingFrame then return end

    if not self.myListing then
        self.myListingInfo:SetText(_hex("textDim") .. "No active group.\nGo to 'Create Group' to publish a listing on FrostNet!|r")
        if self.applicantsLabel then self.applicantsLabel:Hide() end
        for _, r in ipairs(self.applicantRows or {}) do r:Hide() end
        if self.cancelBtn then self.cancelBtn:Hide() end
        return
    end

    if self.cancelBtn then self.cancelBtn:Show() end
    if self.applicantsLabel then self.applicantsLabel:Show() end

    local l = self.myListing
    local lines = {}
    table.insert(lines, (TYPE_COLORS[l.type] or "|cffffffff") .. tostring(l.activity) .. "|r  " .. tostring(l.difficulty or ""))
    table.insert(lines, _hex("textDim") .. "Leader:|r " .. tostring(l.leader) .. "   " .. _hex("textDim") .. "Members:|r " .. tostring(memberCount()) .. "/" .. tostring(l.maxMembers or 5))
    if l.roles and l.roles ~= "" then
        local myRoles = ""
        for roleName in string.gmatch(l.roles, "[^/]+") do
            myRoles = myRoles .. roleText(roleName) .. "  "
        end
        if myRoles ~= "" then
            table.insert(lines, _hex("textDim") .. "LF:|r " .. myRoles)
        end
    end
    if l.minItemLevel and l.minItemLevel ~= "" then
        table.insert(lines, _hex("textDim") .. "Min iLvl:|r " .. l.minItemLevel .. "+")
    end
    if l.voice and l.voice ~= "None" then
        table.insert(lines, _hex("textDim") .. "Voice:|r " .. l.voice)
    end
    if l.note and l.note ~= "" then
        table.insert(lines, _hex("textDim") .. "Note:|r " .. l.note)
    end
    self.myListingInfo:SetText(table.concat(lines, "\n"))

    self:RefreshApplicants()
end

function Listings:RefreshApplicants()
    if not self.applicantRows then return end

    local apps = {}
    for _, a in pairs(self.applicants) do
        table.insert(apps, a)
    end
    table.sort(apps, function(a, b) return (a.applied or 0) < (b.applied or 0) end)

    for i, row in ipairs(self.applicantRows) do
        local a = apps[i]
        if a then
            row:Show()
            row.applicantName = a.name

            if a.name == self.selectedApplicant then
                row.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            else
                row.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))
            end

            row.icon:SetTexture(classIcon(a.classFile))
            row.name:SetText(classColorText(a.name, a.classFile))
            row.class:SetText(tostring(a.class or ""))
            row.role:SetText(roleText(a.role))
            row.ilvl:SetText((a.itemLevel and a.itemLevel ~= "" and a.itemLevel ~= "0") and (a.itemLevel .. " ilvl") or "--")
            row.gs:SetText((a.gearScore and a.gearScore ~= "" and a.gearScore ~= "0") and (a.gearScore .. " gs") or "--")
            row.note:SetText(tostring(a.note or ""))
        else
            row:Hide()
            row.applicantName = nil
        end
    end

    if self.applicantsLabel then
        self.applicantsLabel:SetText("|cff88ccffApplicants|r (" .. tostring(#apps) .. ")")
    end
end

function Listings:Show()
    if self.frame then self.frame:Show() end
    self:RefreshContent()
end

function Listings:Hide()
    if self.frame then self.frame:Hide() end
end

C_Timer.NewTicker(20, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    if Listings.myListing then
        Listings:CheckAutoClose()
        Listings:BroadcastMyListing()
    end
    for id, l in pairs(Listings.listings) do
        if l.seen and now() - l.seen > LISTING_EXPIRE then
            Listings.listings[id] = nil
        end
    end
    local expired = false
    for id, app in pairs(Listings.myApplications) do
        if app.status == "pending" and app.appliedAt and (now() - app.appliedAt) > APP_PENDING_EXPIRE then
            app.status = "expired"
            app.decidedAt = time()
            expired = true
        end
    end
    if expired and Listings.frame and Listings.frame:IsShown() then
        Listings:RefreshApplications()
    end
end)

local rosterFrame = CreateFrame("Frame")
rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
rosterFrame:RegisterEvent("RAID_ROSTER_UPDATE")
rosterFrame:SetScript("OnEvent", function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    if Listings.myListing then
        Listings:CheckAutoClose()
        Listings:BroadcastMyListing()
    end
end)

FrostSeek.Listings = Listings

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("listings", Listings)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("listings")
end