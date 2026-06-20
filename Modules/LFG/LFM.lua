local FrostSeek = _G.FrostSeek
local Shared = _G.FrostSeekShared
local UI = _G.FrostSeekUIUtils

local LFM = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfm", LFM)

local _tc = _G.FrostSeekShared and _G.FrostSeekShared._tc or function(t) return {0.5,0.5,0.5} end

local currentCategory = "RAIDS"
local selectedRoles = { Tank = false, Healer = false, DPS = false, BC = false }
local needCount = { Tank = 1, Healer = 1, DPS = 1 }
local selectedDifficulty = "Normal"
local searchText = ""
local currentKeystone = nil
local keystoneUpdateTicker = nil
local autoSpamTicker = nil
local autoSpamActive = false
local customMessage = FrostSeekDB.LFM.customMessage or ""
local userEditedMessage = false
local autoInviteEnabled = false
local autoInviteMinIlvl = 0
local autoInviteMinLevel = 60
local recentInvites = {}
local spamChannels = {}
local activeEditBox = nil

local LFM_ACTIVITIES = {
    RAIDS = {
        { name = "Molten Core", template = "LFM Molten Core {difficulty} {roles}", keywords = {"mc", "molten core"} },
        { name = "Onyxia", template = "LFM Onyxia {difficulty} {roles}", keywords = {"onyxia", "ony"} },
        { name = "Blackwing Lair", template = "LFM Blackwing Lair {difficulty} {roles}", keywords = {"bwl", "blackwing"} },
        { name = "Zul'Gurub", template = "LFM Zul'Gurub {difficulty} {roles}", keywords = {"zg", "zulgurub"} },
        { name = "Ruins of Ahn'Qiraj", template = "LFM Ruins of AQ {difficulty} {roles}", keywords = {"aq20", "ruins"} },
        { name = "Temple of Ahn'Qiraj", template = "LFM Temple of AQ {difficulty} {roles}", keywords = {"aq40", "temple"} },
        { name = "Naxxramas", template = "LFM Naxxramas {difficulty} {roles}", keywords = {"naxx", "naxxramas"} },
        { name = "Karazhan", template = "LFM Karazhan {difficulty} {roles}", keywords = {"kara", "karazhan"} },
        { name = "Gruul's Lair", template = "LFM Gruul {difficulty} {roles}", keywords = {"gruul"} },
        { name = "Magtheridon", template = "LFM Magtheridon {difficulty} {roles}", keywords = {"mag", "magtheridon"} },
        { name = "Serpentshrine Cavern", template = "LFM SSC {difficulty} {roles}", keywords = {"ssc", "serpentshrine"} },
        { name = "Tempest Keep", template = "LFM TK {difficulty} {roles}", keywords = {"tk", "tempest"} },
        { name = "Hyjal Summit", template = "LFM Hyjal {difficulty} {roles}", keywords = {"hyjal"} },
        { name = "Black Temple", template = "LFM BT {difficulty} {roles}", keywords = {"bt", "black temple"} },
        { name = "Zul'Aman", template = "LFM Zul'Aman {difficulty} {roles}", keywords = {"za", "zulaman"} },
        { name = "Sunwell Plateau", template = "LFM Sunwell {difficulty} {roles}", keywords = {"swp", "sunwell"} },
        { name = "Eye of Eternity", template = "LFM Eye of Eternity {difficulty} {roles}", keywords = {"eye", "eoe", "malygos"} },
        { name = "Obsidian Sanctum", template = "LFM OS {difficulty} {roles}", keywords = {"os", "obsidian", "sarth"} },
        { name = "Vault of Archavon", template = "LFM VoA {difficulty} {roles}", keywords = {"voa", "archavon"} },
        { name = "Ulduar", template = "LFM Ulduar {difficulty} {roles}", keywords = {"ulduar", "uld"} },
        { name = "Trial of the Crusader", template = "LFM ToC {difficulty} {roles}", keywords = {"toc", "crusader"} },
        { name = "Icecrown Citadel", template = "LFM ICC {difficulty} {roles}", keywords = {"icc", "icecrown"} },
        { name = "Ruby Sanctum", template = "LFM Ruby Sanctum {difficulty} {roles}", keywords = {"rs", "ruby", "halion"} },
        { name = "Baradin Hold", template = "LFM Baradin Hold {difficulty} {roles}", keywords = {"bh", "baradin"} },
        { name = "Bastion of Twilight", template = "LFM BoT {difficulty} {roles}", keywords = {"bot", "bastion", "twilight"} },
        { name = "Throne of the Four Winds", template = "LFM T4W {difficulty} {roles}", keywords = {"t4w", "four winds", "al'akir"} },
        { name = "Blackwing Descent", template = "LFM BWD {difficulty} {roles}", keywords = {"bwd", "blackwing descent", "nefarian"} },
        { name = "Firelands", template = "LFM Firelands {difficulty} {roles}", keywords = {"fl", "firelands", "ragnaros"} },
        { name = "Dragon Soul", template = "LFM Dragon Soul {difficulty} {roles}", keywords = {"ds", "dragon soul", "deathwing"} },
        { name = "Terrace of Endless Spring", template = "LFM ToES {difficulty} {roles}", keywords = {"toes", "terrace", "endless spring"} },
        { name = "Mogu'shan Vaults", template = "LFM MSV {difficulty} {roles}", keywords = {"msv", "mogushan", "vaults"} },
        { name = "Heart of Fear", template = "LFM HoF {difficulty} {roles}", keywords = {"hof", "heart of fear", "shek'zeer"} },
        { name = "Throne of Thunder", template = "LFM ToT {difficulty} {roles}", keywords = {"tot", "thunder", "lei shen"} },
        { name = "Siege of Orgrimmar", template = "LFM SoO {difficulty} {roles}", keywords = {"soo", "siege", "orgrimmar", "garrosh"} },
    },
    DUNGEONS = {
        { name = "Deadmines", template = "LFM Deadmines {difficulty} {roles}", keywords = {"deadmines", "dm", "vc"} },
        { name = "Wailing Caverns", template = "LFM Wailing Caverns {difficulty} {roles}", keywords = {"Wailing Caverns"} },
        { name = "Ragefire Chasm", template = "LFM Ragefire Chasm {difficulty} {roles}", keywords = {"rfc", "ragefire"} },
        { name = "Shadowfang Keep", template = "LFM SFK {difficulty} {roles}", keywords = {"sfk", "shadowfang"} },
        { name = "Blackrock Depths", template = "LFM BRD {difficulty} {roles}", keywords = {"brd", "blackrock depths"} },
        { name = "Blackfathom Deeps", template = "LFM BFD {difficulty} {roles}", keywords = {"bfd", "Blackfathom Deeps"} },
        { name = "Scholomance", template = "LFM Scholo {difficulty} {roles}", keywords = {"scholo", "scholomance"} },
        { name = "Lower Blackrock Spire", template = "LFM LBRS {difficulty} {roles}", keywords = {"lbrs", "lower"} },
        { name = "Upper Blackrock Spire", template = "LFM UBRS {difficulty} {roles}", keywords = {"ubrs", "upper"} },
        { name = "Dire Maul East", template = "LFM DME {difficulty} {roles}", keywords = {"dme", "east"} },
        { name = "Dire Maul North", template = "LFM DMN {difficulty} {roles}", keywords = {"dmn", "north"} },
        { name = "Dire Maul West", template = "LFM DMW {difficulty} {roles}", keywords = {"dmw", "west"} },
        { name = "The Stockade", template = "LFM The Stockade {difficulty} {roles}", keywords = {"Stockade"} },
        { name = "Gnomeregan", template = "LFM Gnomeregan {difficulty} {roles}", keywords = {"Gnomeregan"} },
        { name = "Razorfen Kraul", template = "LFM Razorfen Kraul {difficulty} {roles}", keywords = {"Razorfen Kraul"} },
        { name = "Scarlet Monastery", template = "LFM Scarlet Monastery {difficulty} {roles}", keywords = {"Scarlet Monastery"} },
        { name = "Razorfen Downs", template = "LFM Razorfen Downs {roles}", keywords = {"Razorfen"} },
        { name = "Uldaman", template = "LFM Uldaman {difficulty} {roles}", keywords = {"Uldaman"} },
        { name = "Zul'Farrak", template = "LFM Zul'Farrak {difficulty} {roles}", keywords = {"Zul'Farrak"} },
        { name = "Maraudon", template = "LFM Maraudon {difficulty} {roles}", keywords = {"Maraudon"} },
        { name = "Stratholme", template = "LFM Strat {difficulty} {roles}", keywords = {"strat", "stratholme"} },
        { name = "Hellfire Ramparts", template = "LFM Ramparts {difficulty} {roles}", keywords = {"ramps", "ramparts"} },
        { name = "Blood Furnace", template = "LFM Blood Furnace {difficulty} {roles}", keywords = {"bf", "blood furnace"} },
        { name = "The Shattered Halls", template = "LFM Shattered Halls {difficulty} {roles}", keywords = {"Shattered Halls"} },
        { name = "Slave Pens", template = "LFM Slave Pens {difficulty} {roles}", keywords = {"sp", "slave pens"} },
        { name = "Underbog", template = "LFM Underbog {difficulty} {roles}", keywords = {"ub", "underbog"} },
        { name = "The Steamvault", template = "LFM Steamvault {difficulty} {roles}", keywords = {"st", "Steamvault"} },
        { name = "Mana-Tombs", template = "LFM Mana-Tombs {difficulty} {roles}", keywords = {"mt", "mana-tombs"} },
        { name = "Auchenai Crypts", template = "LFM Auchenai {difficulty} {roles}", keywords = {"ac", "auchenai"} },
        { name = "Sethekk Halls", template = "LFM Sethekk {difficulty} {roles}", keywords = {"sh", "sethekk"} },
        { name = "Shadow Labyrinth", template = "LFM Shadow Laby {difficulty} {roles}", keywords = {"sl", "slabs", "shadow lab"} },
        { name = "Mechanar", template = "LFM Mechanar {difficulty} {roles}", keywords = {"mecha", "mechanar"} },
        { name = "Botanica", template = "LFM Botanica {difficulty} {roles}", keywords = {"bota", "botanica"} },
        { name = "Arcatraz", template = "LFM Arcatraz {difficulty} {roles}", keywords = {"arca", "arcatraz"} },
        { name = "Magister's Terrace", template = "LFM Magister's {difficulty} {roles}", keywords = {"mgt", "magisters"} },
        { name = "Utgarde Keep", template = "LFM UK {difficulty} {roles}", keywords = {"uk", "utgarde keep"} },
        { name = "Utgarde Pinnacle", template = "LFM UP {difficulty} {roles}", keywords = {"up", "pinnacle"} },
        { name = "The Nexus", template = "LFM Nexus {difficulty} {roles}", keywords = {"nexus", "nex"} },
        { name = "The Oculus", template = "LFM Oculus {difficulty} {roles}", keywords = {"oculus", "ocu"} },
        { name = "Azjol-Nerub", template = "LFM AN {difficulty} {roles}", keywords = {"an", "azjol"} },
        { name = "Ahn'kahet", template = "LFM Old Kingdom {difficulty} {roles}", keywords = {"ak", "ahn'kahet"} },
        { name = "Drak'Tharon Keep", template = "LFM DTK {difficulty} {roles}", keywords = {"dtk", "drak'tharon"} },
        { name = "Violet Hold", template = "LFM Violet Hold {difficulty} {roles}", keywords = {"vh", "violet"} },
        { name = "Gundrak", template = "LFM Gundrak {difficulty} {roles}", keywords = {"gun", "gundrak"} },
        { name = "Halls of Stone", template = "LFM HoS {difficulty} {roles}", keywords = {"hos", "halls stone"} },
        { name = "Halls of Lightning", template = "LFM HoL {difficulty} {roles}", keywords = {"hol", "halls lightning"} },
        { name = "Culling of Stratholme", template = "LFM CoS {difficulty} {roles}", keywords = {"cos", "culling"} },
        { name = "Trial of the Champion", template = "LFM ToC Dungeon {difficulty} {roles}", keywords = {"toc", "champion"} },
        { name = "Forge of Souls", template = "LFM Forge of Souls {difficulty} {roles}", keywords = {"fos", "forge"} },
        { name = "Pit of Saron", template = "LFM Pit of Saron {difficulty} {roles}", keywords = {"pos", "pit"} },
        { name = "Halls of Reflection", template = "LFM HoR {difficulty} {roles}", keywords = {"hor", "reflection"} },
        { name = "Blackrock Caverns", template = "LFM BRC {difficulty} {roles}", keywords = {"brc", "blackrock caverns"} },
        { name = "Throne of the Tides", template = "LFM TotT {difficulty} {roles}", keywords = {"tott", "throne tides", "naz'jar"} },
        { name = "The Vortex Pinnacle", template = "LFM VP {difficulty} {roles}", keywords = {"vp", "vortex", "pinnacle"} },
        { name = "Stonecore", template = "LFM Stonecore {difficulty} {roles}", keywords = {"sc", "stonecore"} },
        { name = "Lost City of the Tol'vir", template = "LFM LCT {difficulty} {roles}", keywords = {"lct", "tol'vir", "lost city"} },
        { name = "Halls of Origination", template = "LFM HoO {difficulty} {roles}", keywords = {"hoo", "origination"} },
        { name = "Grim Batol", template = "LFM GB {difficulty} {roles}", keywords = {"gb", "grim batol"} },
        { name = "Zul'Gurub (Cata)", template = "LFM ZG {difficulty} {roles}", keywords = {"zg", "zulgurub"} },
        { name = "Zul'Aman (Cata)", template = "LFM ZA {difficulty} {roles}", keywords = {"za", "zulaman"} },
        { name = "End Time", template = "LFM End Time {difficulty} {roles}", keywords = {"et", "end time"} },
        { name = "Well of Eternity", template = "LFM WoE {difficulty} {roles}", keywords = {"woe", "well eternity"} },
        { name = "Hour of Twilight", template = "LFM HoT {difficulty} {roles}", keywords = {"hot", "hour twilight"} },
        { name = "Temple of the Jade Serpent", template = "LFM TJS {difficulty} {roles}", keywords = {"tjs", "jade serpent", "temple"} },
        { name = "Stormstout Brewery", template = "LFM SB {difficulty} {roles}", keywords = {"sb", "stormstout", "brewery"} },
        { name = "Shado-Pan Monastery", template = "LFM SPM {difficulty} {roles}", keywords = {"spm", "shado-pan"} },
        { name = "Mogu'shan Palace", template = "LFM MSP {difficulty} {roles}", keywords = {"msp", "mogushan palace"} },
        { name = "Scarlet Halls", template = "LFM Scarlet Halls {difficulty} {roles}", keywords = {"scarlet halls"} },
        { name = "Scarlet Monastery (MoP)", template = "LFM SM {difficulty} {roles}", keywords = {"sm", "scarlet monastery"} },
        { name = "Siege of Niuzao Temple", template = "LFM Niuzao {difficulty} {roles}", keywords = {"niuzao", "siege"} },
        { name = "Gate of the Setting Sun", template = "LFM GSS {difficulty} {roles}", keywords = {"gss", "setting sun"} },
        { name = "Scholomance (MoP)", template = "LFM Scholo {difficulty} {roles}", keywords = {"scholo", "scholomance"} },
        { name = "GlitterMurk Mines", template = "Glittermurk Mines {difficulty} {roles}", keywords = {"glittermurk"} },
        { name = "Tor'Watha", template = "LFM Tor'Watha {difficulty} {roles}", keywords = {"Tor'Watha", "tw"} },
        { name = "Bardid Hold", template = "LFM Bardid Hold {roles}", keywords = {"Bardid Hold", "BH"} },
        { name = "Vault of the Inquisition", template = "LFM Vault {difficulty} {roles}", keywords = {"vault", "inquisition"} },
        { name = "Road to De' Other Side", template = "LFM Other Side {difficulty} {roles}", keywords = {"Road to De' Other Side"} },
    },
    MANASTORM = {
        { name = "ALVA", template = "LFM ALVA Boss {roles}", keywords = {"alva", "boss"} },
        { name = "Manastorm Gold Farm", template = "LFM Manastorm Gold {roles}", keywords = {"manastorm", "gold", "farm"} },
        { name = "Manastorm Leveling", template = "LFM Manastorm Level {roles}", keywords = {"manastorm", "level", "xp"} },
        { name = "Manastorm Bonzo Farm", template = "LFM Bonzo {roles}", keywords = {"bonzo", "farm"} },
    },
    WORLD_BOSS = {
        { name = "Azuregos", template = "LFM Azuregos {difficulty} {roles}", keywords = {"azuregos", "azure"} },
        { name = "Lord Kazzak", template = "LFM Lord Kazzak {difficulty} {roles}", keywords = {"kazzak"} },
        { name = "Setis", template = "LFM Setis {difficulty} {roles}", keywords = {"setis", "settis"} },
        { name = "Emeriss", template = "LFM Emeriss {difficulty} {roles}", keywords = {"emeriss"} },
        { name = "Lethon", template = "LFM Lethon {difficulty} {roles}", keywords = {"lethon"} },
        { name = "Taerar", template = "LFM Taerar {difficulty} {roles}", keywords = {"taerar"} },
        { name = "Ysondre", template = "LFM Ysondre {difficulty} {roles}", keywords = {"ysondre"} },
        { name = "Doomwalker", template = "LFM Doomwalker {difficulty} {roles}", keywords = {"doomwalker"} },
        { name = "Doom Lord Kazzak", template = "LFM Doom Lord Kazzak {difficulty} {roles}", keywords = {"doom"} },
        { name = "Soggoth", template = "LFM Soggoth {difficulty} {roles}", keywords = {"soggoth"} },
        { name = "Snowgrave", template = "LFM Snowgrave {difficulty} {roles}", keywords = {"snowgrave"} },
        { name = "Atal'Zul", template = "LFM Atal'Zul {difficulty} {roles}", keywords = {"atal'Zul"} },
        { name = "Kaldros Depthbreaker", template = "LFM Kaldros Depthbreaker {difficulty} {roles}", keywords = {"Kaldros Depthbreaker"} },
        { name = "Gonzor", template = "LFM Gonzor {difficulty} {roles}", keywords = {"Gonzor"} },
        { name = "King Gnok", template = "LFM King Gnok {difficulty} {roles}", keywords = {"king, gnok"} },
        { name = "King Mosh", template = "LFM King Mosh {difficulty} {roles}", keywords = {"king, mosh"} },
        { name = "Silithid Lurker", template = "LFM Silithid Lurker {difficulty} {roles}", keywords = {"silithid, lurker"} },
        { name = "Volchan", template = "LFM Volchan {difficulty} {roles}", keywords = {"Volchan"} },
        { name = "Corrupted Ancient", template = "LFM CA {difficulty} {roles}", keywords = {"CA,Corrupted Ancient"} },
        { name = "WorldBossTour", template = "LFM World Boss Tour {difficulty} {roles}", keywords = {"worldtour"} },
        { name = "Sha of Anger", template = "LFM Sha of Anger {difficulty} {roles}", keywords = {"sha", "anger"} },
        { name = "Galleon", template = "LFM Galleon {difficulty} {roles}", keywords = {"galleon", "salyis"} },
        { name = "Nalak", template = "LFM Nalak {difficulty} {roles}", keywords = {"nalak"} },
        { name = "Oondasta", template = "LFM Oondasta {difficulty} {roles}", keywords = {"oondasta"} },
        { name = "Celestials", template = "LFM Celestials {difficulty} {roles}", keywords = {"celestials", "celestial"} },
    },
    PVP = {
        { name = "Arena 2v2", template = "LFM for Arena 2v2 {roles}", keywords = {"2v2", "2s", "twos"} },
        { name = "Arena 3v3", template = "LFM for Arena 3v3 {roles}", keywords = {"3v3", "3s", "threes"} },
        { name = "Arena 5v5", template = "LFM for Arena 5v5 {roles}", keywords = {"5v5", "5s", "fives"} },
        { name = "Battlegrounds", template = "LFM for BG {roles}", keywords = {"bg", "battleground"} },
        { name = "Wintergrasp", template = "LFM for Wintergrasp {roles}", keywords = {"wg", "wintergrasp"} },
        { name = "World Pvp", template = "LFM for worldpvp {roles}", keywords = {"wp", "worldpvp"} },
        { name = "High Risk Pvp", template = "LFM for HRPvp {roles}", keywords = {"wp", "worldpvp"} },
    },
    KEYSTONE = {},
}

local DIFFICULTIES = {
    RAIDS = {"Normal", "Heroic", "Mythic", "Ascended", "Trial 1", "Trial 2", "Trial 3", "Trial 4", "Trial 5", "Trial 6", "Trial 7", "Trial 8", "Trial 9", "Trial 10"},
    DUNGEONS = {"Normal", "Heroic", "Mythic"},
    WORLD_BOSS = {"Open World", "Instanced", "HC Instanced", "Mythic Instanced", "Ascended Instanced"},
    KEYSTONE = {"Mythic+"},
}

local CHANNELS = {
    "SAY", "YELL", "PARTY", "RAID", "GUILD", "INSTANCE_CHAT",
    "CHANNEL1", "CHANNEL2", "CHANNEL3", "CHANNEL4", "CHANNEL5",
    "CHANNEL6", "CHANNEL7", "CHANNEL8", "CHANNEL9", "CHANNEL10"
}

local RAID_ROLE_REQUIREMENTS = {
    RAIDS = { Tank = 2, Healer = 2, DPS = 5 },
    WORLD_BOSS = { Tank = 1, Healer = 2, DPS = 5 },
}

local function FindKeystoneInBags()
    local GetContainerNum = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local GetContainerLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
    if not GetContainerNum or not GetContainerLink then return nil end

    for bag = 0, 4 do
        local ok, numSlots = pcall(function() return GetContainerNum(bag) end)
        if not ok then numSlots = 0 end
        for slot = 1, (numSlots or 0) do
            local itemLink
            pcall(function() itemLink = GetContainerLink(bag, slot) end)
            if itemLink then
                local itemName
                if FrostSeekCompat and FrostSeekCompat.GetItemInfo then
                    local info = FrostSeekCompat.GetItemInfo(itemLink)
                    if info then itemName = info end
                else
                    itemName = GetItemInfo(itemLink)
                end
                if itemName and string.find(itemName, "Keystone") then
                    return itemLink, itemName, bag, slot
                end
            end
        end
    end
    return nil, nil, nil, nil
end

local function GetKeystoneInfo(itemLink)
    if not itemLink then return nil end
    local itemName = GetItemInfo(itemLink)
    if not itemName then return nil end
    return { link = itemLink, name = itemName }
end

local function UpdateKeystoneList()
    if not LFM_ACTIVITIES.KEYSTONE then
        LFM_ACTIVITIES.KEYSTONE = {}
    else
        wipe(LFM_ACTIVITIES.KEYSTONE)
    end

    local keystoneLink, keystoneName = FindKeystoneInBags()

    if keystoneLink then
        local keystoneInfo = GetKeystoneInfo(keystoneLink)
        if keystoneInfo then
            table.insert(LFM_ACTIVITIES.KEYSTONE, {
                name = keystoneInfo.name,
                template = "LFM {keystone} {roles}",
                keywords = {"keystone", "mythic", "mythic+"},
                keystoneLink = keystoneLink,
                keystoneInfo = keystoneInfo,
            })
            currentKeystone = keystoneInfo
        end
    else
        currentKeystone = nil
    end

    if currentCategory == "KEYSTONE" then
        if #LFM_ACTIVITIES.KEYSTONE > 0 then
            local activity = LFM_ACTIVITIES.KEYSTONE[1]
            UpdateMessagePreview(activity.template, activity)
        else
            UpdateMessagePreview()
        end
    end

    return currentKeystone ~= nil
end

local function StartKeystoneAutoUpdate()
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end

    local interval = FrostSeekDB.LFM.autoUpdateInterval or 60
    if interval <= 0 then return end

    keystoneUpdateTicker = C_Timer.NewTicker(interval, function()
        UpdateKeystoneList()
        if currentCategory ~= "KEYSTONE" then
            if keystoneUpdateTicker then
                keystoneUpdateTicker:Cancel()
                keystoneUpdateTicker = nil
            end
        end
    end)
end

local function StopKeystoneAutoUpdate()
    if keystoneUpdateTicker then
        keystoneUpdateTicker:Cancel()
        keystoneUpdateTicker = nil
    end
end

local function GenerateRolesText()
    local roles = {}
    if selectedRoles.Tank then
        local n = needCount.Tank or 1
        table.insert(roles, n > 1 and (n .. " Tank") or "Tank")
    end
    if selectedRoles.Healer then
        local n = needCount.Healer or 1
        table.insert(roles, n > 1 and (n .. " Healer") or "Healer")
    end
    if selectedRoles.DPS then
        local n = needCount.DPS or 1
        table.insert(roles, n > 1 and (n .. " DPS") or "DPS")
    end
    if selectedRoles.BC then table.insert(roles, "BC") end
    if #roles == 0 then return "All Roles" end
    return table.concat(roles, " ")
end

local function ProcessTemplate(template, activity)
    local processed = template:gsub("{roles}", GenerateRolesText())
    processed = processed:gsub("{difficulty}", selectedDifficulty)
    if activity and activity.keystoneLink then
        processed = processed:gsub("{keystone}", activity.keystoneLink)
    end
    return processed
end

local function FilterActivities(activities)
    if not searchText or searchText == "" then return activities end
    local filtered = {}
    local searchLower = string.lower(searchText)
    for _, activity in ipairs(activities) do
        local nameLower = string.lower(activity.name)
        if string.find(nameLower, searchLower) then
            table.insert(filtered, activity)
        else
            for _, keyword in ipairs(activity.keywords) do
                if string.find(string.lower(keyword), searchLower) then
                    table.insert(filtered, activity)
                    break
                end
            end
        end
    end
    return filtered
end

local function DetectRolesFromMessage(msg)
    local msgLower = string.lower(msg)
    local found = {}

    if string.find(msgLower, "tank") then
        table.insert(found, "Tank")
    end

    if string.find(msgLower, "heal") then
        table.insert(found, "Healer")
    end

    if string.find(msgLower, "dps") or string.find(msgLower, " dd") or string.find(msgLower, "^dd") then
        table.insert(found, "DPS")
    end

    if string.find(msgLower, "bc") then
        table.insert(found, "BC")
    end

    if #found == 0 then
        return nil
    end

    return table.concat(found, "/")
end

local function ValidateGroupComposition()
    local reqs = RAID_ROLE_REQUIREMENTS[currentCategory]
    if not reqs then return nil end

    local warnings = {}
    local ROLE_COLORS = Shared and Shared.ROLE_COLORS or { Tank = {0.3, 0.5, 0.85}, Healer = {0.2, 0.8, 0.3}, DPS = {0.85, 0.3, 0.2} }

    for role, recommended in pairs(reqs) do
        if not selectedRoles[role] then
            local c = ROLE_COLORS[role] or {1, 1, 1}
            local hex = string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
            table.insert(warnings, hex .. role .. "|r")
        elseif (needCount[role] or 1) < recommended then
            local c = ROLE_COLORS[role] or {1, 1, 1}
            local hex = string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
            table.insert(warnings, hex .. role .. " (only " .. (needCount[role] or 1) .. ", recommended " .. recommended .. ")" .. "|r")
        end
    end

    if #warnings > 0 then
        return "Consider adding: " .. table.concat(warnings, ", ")
    end
    return nil
end

local function SendLFMMessage(message, channel)
    if not message or message == "" then return false end

    if currentCategory == "KEYSTONE" and not FindKeystoneInBags() then
        print("|cffff0000FrostSeek LFM:|r No Keystone found!")
        return false
    end

    local success = true
    if string.match(channel, "CHANNEL%d+") then
        local channelNum = tonumber(string.match(channel, "CHANNEL(%d+)"))
        if channelNum then
            local realId = nil
            local chName = nil

            local ok, id, name = pcall(function()
                return GetChannelName(channelNum)
            end)
            if ok then
                if type(id) == "number" and id > 0 then
                    realId = id
                    chName = name
                end
            end

            if realId and chName and tostring(chName) ~= "" then
                local ok2, err = pcall(function()
                    SendChatMessage(message, "CHANNEL", nil, realId)
                end)
                if not ok2 then
                    print("|cffff0000FrostSeek LFM:|r Failed to send on channel " .. tostring(chName) .. ": " .. tostring(err))
                    success = false
                end
            else
                print("|cffff0000FrostSeek LFM:|r Channel slot " .. channelNum .. " not found! Open chat channels to populate the list.")
                success = false
            end
        end
    else
        local ok, err = pcall(function()
            SendChatMessage(message, channel)
        end)
        if not ok then
            print("|cffff0000FrostSeek LFM:|r Failed to send on " .. tostring(channel) .. ": " .. tostring(err))
            success = false
        end
    end

    if success then
        table.insert(FrostSeekDB.LFM.lastMessages, 1, {
            message = message,
            channel = channel,
            timestamp = time()
        })
        while #FrostSeekDB.LFM.lastMessages > 10 do
            table.remove(FrostSeekDB.LFM.lastMessages)
        end
    end

    return success
end

local function SendToAllSpamChannels(message)
    local sentCount = 0
    for i = 1, 10 do
        if spamChannels[i] then
            local channelKey = "CHANNEL" .. i
            local success = SendLFMMessage(message, channelKey)
            if success then sentCount = sentCount + 1 end
        end
    end
    return sentCount
end

local function DoAutoSpamTick()
    if not autoSpamActive then return end
    local message = customMessage or ""
    if message == "" then
        print("|cffff0000FrostSeek Auto-Spam:|r No message set!")
        LFM:StopAutoSpam()
        return
    end
    local sent = SendToAllSpamChannels(message)
    if sent > 0 then
        print("|cff88ccffFrostSeek Auto-Spam:|r Sent to " .. sent .. " channel(s)")
    else
        print("|cffff0000FrostSeek Auto-Spam:|r No channels selected!")
    end
end

function LFM:StartAutoSpam()
    local message = customMessage or ""
    if message == "" then
        print("|cffff0000FrostSeek LFM:|r Cannot start spam - no message!")
        return
    end

    local hasChannel = false
    for i = 1, 10 do
        if spamChannels[i] then hasChannel = true; break end
    end
    if not hasChannel then
        print("|cffff0000FrostSeek LFM:|r Cannot start spam - no channels selected!")
        return
    end

    local interval = tonumber(LFM.spamTimerBox:GetText()) or 30
    if interval < 5 then interval = 5 end
    LFM.spamTimerBox:SetText(tostring(interval))

    if Shared and Shared.ConfirmDialog then
        Shared.ConfirmDialog(
            "Start Auto-Spam",
            "This will spam \"" .. string.sub(message, 1, 60) .. (string.len(message) > 60 and "..." or "") .. "\" every " .. interval .. "s on " .. table.concat({(function()
                local chs = {}
                for i = 1, 10 do
                    if spamChannels[i] then
                        local ok, id, name = pcall(function() return GetChannelName(i) end)
                        if ok and type(id) == "number" and id > 0 and name then
                            table.insert(chs, tostring(name))
                        end
                    end
                end
                return chs
            end)()}, ", ") .. ". Continue?",
            function()
                autoSpamActive = true
                DoAutoSpamTick()
                autoSpamTicker = C_Timer.NewTicker(interval, DoAutoSpamTick)
                LFM.spamBtn.text:SetText("Stop Spam")
                local dangerC = _tc("danger")
                LFM.spamBtn.color = dangerC
                LFM.spamBtn.text:SetTextColor(min(dangerC[1] * 1.4, 1), min(dangerC[2] * 1.4, 1), min(dangerC[3] * 1.4, 1))
                LFM.spamBtn.bg:SetColorTexture(dangerC[1] * 0.25, dangerC[2] * 0.25, dangerC[3] * 0.25, 0.8)
                LFM.spamBtn.border:SetColorTexture(dangerC[1] * 0.5, dangerC[2] * 0.5, dangerC[3] * 0.5, 0.7)
                LFM.spamBtn.accent:SetColorTexture(dangerC[1], dangerC[2], dangerC[3], 0.4)
                LFM.spamStatusText:SetText(string.format("|cFF00FF00Spamming every %ds|r", interval))
                LFM.spamStatusText:Show()
                print("|cff88ccffFrostSeek LFM:|r Auto-spam started (every " .. interval .. "s)")
            end
        )
    else
        autoSpamActive = true
        DoAutoSpamTick()
        autoSpamTicker = C_Timer.NewTicker(interval, DoAutoSpamTick)
        LFM.spamBtn.text:SetText("Stop Spam")
        local dangerC = _tc("danger")
        LFM.spamBtn.color = dangerC
        LFM.spamBtn.text:SetTextColor(min(dangerC[1] * 1.4, 1), min(dangerC[2] * 1.4, 1), min(dangerC[3] * 1.4, 1))
        LFM.spamBtn.bg:SetColorTexture(dangerC[1] * 0.25, dangerC[2] * 0.25, dangerC[3] * 0.25, 0.8)
        LFM.spamBtn.border:SetColorTexture(dangerC[1] * 0.5, dangerC[2] * 0.5, dangerC[3] * 0.5, 0.7)
        LFM.spamBtn.accent:SetColorTexture(dangerC[1], dangerC[2], dangerC[3], 0.4)
        LFM.spamStatusText:SetText(string.format("|cFF00FF00Spamming every %ds|r", interval))
        LFM.spamStatusText:Show()
        print("|cff88ccffFrostSeek LFM:|r Auto-spam started (every " .. interval .. "s)")
    end
end

function LFM:StopAutoSpam()
    autoSpamActive = false
    if autoSpamTicker then
        autoSpamTicker:Cancel()
        autoSpamTicker = nil
    end

    if LFM.spamBtn then
        LFM.spamBtn.text:SetText("Start Spam")
        local successC = _tc("success")
        LFM.spamBtn.color = successC
        LFM.spamBtn.text:SetTextColor(min(successC[1] * 1.4, 1), min(successC[2] * 1.4, 1), min(successC[3] * 1.4, 1))
        LFM.spamBtn.bg:SetColorTexture(successC[1] * 0.25, successC[2] * 0.25, successC[3] * 0.25, 0.8)
        LFM.spamBtn.border:SetColorTexture(successC[1] * 0.5, successC[2] * 0.5, successC[3] * 0.5, 0.7)
        LFM.spamBtn.accent:SetColorTexture(successC[1], successC[2], successC[3], 0.4)
    end
    if LFM.spamStatusText then
        LFM.spamStatusText:Hide()
    end

    print("|cff88ccffFrostSeek LFM:|r Auto-spam stopped")
end

local whisperHandler = CreateFrame("Frame")
whisperHandler:RegisterEvent("CHAT_MSG_WHISPER")
whisperHandler:SetScript("OnEvent", function(self, event, msg, sender, ...)
    if not autoInviteEnabled then return end

    local senderName = Ambiguate(sender, "none")

    if UnitName("player") == senderName then return end
    if GetNumGroupMembers() >= 5 then
        if not IsInRaid() then return end
    end

    local now = time()
    if recentInvites[senderName] and (now - recentInvites[senderName]) < 120 then
        return
    end

    local detectedRole = DetectRolesFromMessage(msg)

    local ilvl = nil

    local patterns = {
        "[Ii][Ll][Vv][Ll]%s*(%d+)",
        "[Ll][Vv][Ll]%s*(%d+)",
        "(%d+)%s*[Ii][Ll][Vv][Ll]",
        "(%d+)%s*[Ll][Vv][Ll]",
        "(%d+)%+",
    }

    for _, pattern in ipairs(patterns) do
        local match = string.match(msg, pattern)
        if match then
            local num = tonumber(match)
            if num and num >= 1 and num <= 1000 then
                ilvl = num
                break
            end
        end
    end

    if not ilvl then
        local numbers = {}
        for num in string.gmatch(msg, "%d+") do
            local n = tonumber(num)
            if n and n >= 1 and n <= 1000 then
                table.insert(numbers, n)
            end
        end
        if #numbers > 0 then
            ilvl = numbers[1]
        end
    end

    local needRole = false
    local neededRolesList = {}
    if selectedRoles.Tank then needRole = true; table.insert(neededRolesList, "Tank") end
    if selectedRoles.Healer then needRole = true; table.insert(neededRolesList, "Healer") end
    if selectedRoles.DPS then needRole = true; table.insert(neededRolesList, "DPS") end
    local neededRolesStr = table.concat(neededRolesList, "/")

    local roleMatch = true
    if needRole then
        if detectedRole then
            roleMatch = false
            for _, role in ipairs(neededRolesList) do
                if string.find(detectedRole, role) then
                    roleMatch = true
                    break
                end
            end
        else
            roleMatch = false
        end
    end

    local playerLevel = UnitLevel(senderName) or 0

    if ilvl and ilvl >= autoInviteMinIlvl and roleMatch and playerLevel >= autoInviteMinLevel then
        InviteUnit(senderName)
        recentInvites[senderName] = now

        local roleInfo = ""
        if detectedRole then
            roleInfo = " Role: " .. detectedRole .. " |"
        end
        print("|cff88ccffFrostSeek Auto-Invite:|r Invited " .. senderName .. " (iLvl: " .. ilvl .. " | Lvl: " .. playerLevel .. roleInfo .. ")")

        C_Timer.After(1, function()
            local replyMsg = "Auto-invited! Welcome to the group."
            if detectedRole then
                replyMsg = replyMsg .. " (" .. detectedRole .. ")"
            end
            pcall(function() SendChatMessage(replyMsg, "WHISPER", nil, senderName) end)
        end)
    elseif ilvl and ilvl >= autoInviteMinIlvl and playerLevel < autoInviteMinLevel then
        print("|cffffaa00FrostSeek Auto-Invite:|r Rejected " .. senderName .. " - Level too low (need: " .. autoInviteMinLevel .. ", got: " .. playerLevel .. ")")
        C_Timer.After(1, function()
            pcall(function() SendChatMessage("Sorry, minimum level required is " .. autoInviteMinLevel .. ". You are level " .. playerLevel .. ".", "WHISPER", nil, senderName) end)
        end)
    elseif ilvl and ilvl >= autoInviteMinIlvl and not roleMatch then
        print("|cffffaa00FrostSeek Auto-Invite:|r Rejected " .. senderName .. " - Role mismatch (need: " .. neededRolesStr .. ", got: " .. (detectedRole or "none") .. ")")

        C_Timer.After(1, function()
            if not detectedRole then
                pcall(function() SendChatMessage("Sorry, we need " .. neededRolesStr .. " only. Please include your role in your whisper.", "WHISPER", nil, senderName) end)
            else
                pcall(function() SendChatMessage("Sorry, we need " .. neededRolesStr .. " only. You stated: " .. detectedRole .. ".", "WHISPER", nil, senderName) end)
            end
        end)
    end
end)

C_Timer.NewTicker(300, function()
    local now = time()
    for name, timestamp in pairs(recentInvites) do
        if (now - timestamp) > 300 then
            recentInvites[name] = nil
        end
    end
end)

local _orig_SetItemRef = SetItemRef
function SetItemRef(link, text, button)
    if link and type(link) == "string" then
        local linkType = string.match(link, "^([^:]+)")
        if linkType == "frostseeklfm" then
            local cmd = string.match(link, "^frostseeklfm:(.+)")
            if cmd == "copy" then
                local editBox = ChatEdit_GetActiveWindow()
                if not editBox then
                    if FrostSeekCompat and FrostSeekCompat.OpenChat then
                        FrostSeekCompat.OpenChat("")
                    elseif ChatFrame_OpenChat then
                        ChatFrame_OpenChat("")
                    end
                    editBox = ChatEdit_GetActiveWindow()
                end
                if editBox and customMessage and customMessage ~= "" then
                    editBox:SetText(customMessage)
                end
                return
            elseif cmd == "send" then
                local message = customMessage or ""
                if message ~= "" then
                    for i = 1, 10 do
                        if spamChannels[i] then
                            SendLFMMessage(message, "CHANNEL" .. i)
                            break
                        end
                    end
                end
                return
            end
        end
    end
    _orig_SetItemRef(link, text, button)
end

function UpdateMessagePreview(template, activity)
    if not LFM.messageEditBox then return end

    if template then
        local processed = ProcessTemplate(template, activity)
        if not LFM.messageEditBox:HasFocus() then
            if userEditedMessage then
                return
            end
            customMessage = processed
            FrostSeekDB.LFM.customMessage = customMessage
            LFM.messageEditBox:SetText(processed)
        end
    else
        if not LFM.messageEditBox:HasFocus() then
            if userEditedMessage then
                return
            end
            customMessage = ""
            FrostSeekDB.LFM.customMessage = ""
            LFM.messageEditBox:SetText("")
            LFM.messageEditBox:SetTextColor(unpack(_tc("textMuted")))
        end
    end
end

function UpdateDifficultyDropdown()
    local difficulties = DIFFICULTIES[currentCategory] or {"Normal"}
    if not LFM.difficultyDropdown then return end

    LFM.difficultyDropdown:SetOptions(difficulties)

    selectedDifficulty = difficulties[1] or "Normal"
    LFM.difficultyDropdown:SetText(selectedDifficulty)
    LFM.difficultyDropdown.selectedValue = selectedDifficulty
end

function UpdateActivityList()
    if not LFM.activitiesContent then return end

    if LFM.activitiesContent.buttons then
        for i, btn in ipairs(LFM.activitiesContent.buttons) do
            if btn then
                btn:Hide()
                btn:SetParent(nil)
            end
        end
    end

    LFM.activitiesContent.buttons = {}

    local activities = LFM_ACTIVITIES[currentCategory] or {}
    local filteredActivities = FilterActivities(activities)
    local yOffset = -4

    local accentColors = {
        RAIDS = _tc("catRaid"),
        DUNGEONS = _tc("catDungeon"),
        MANASTORM = _tc("catMana"),
        WORLD_BOSS = _tc("catWorldBoss"),
        PVP = _tc("catPvP"),
        KEYSTONE = _tc("catKeystone"),
    }
    local accent = accentColors[currentCategory] or _tc("catAll")

    for i, activity in ipairs(filteredActivities) do
        local btn = CreateFrame("Button", nil, LFM.activitiesContent)
        btn:SetSize(700, 26)
        btn:SetPoint("TOPLEFT", LFM.activitiesContent, "TOPLEFT", 2, yOffset)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 3, 0)
        bg:SetPoint("BOTTOMRIGHT", 0, 0)
        if i % 2 == 0 then
            bg:SetColorTexture(unpack(_tc("bgRowEven")))
        else
            bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        end

        local accentBar = btn:CreateTexture(nil, "BACKGROUND")
        accentBar:SetPoint("TOPLEFT", 0, 0)
        accentBar:SetSize(3, 26)
        accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)

        local separator = btn:CreateTexture(nil, "BACKGROUND")
        separator:SetPoint("BOTTOMLEFT", 6, 0)
        separator:SetPoint("BOTTOMRIGHT", -2, 0)
        separator:SetHeight(1)
        separator:SetColorTexture(unpack(_tc("separator")))

        local dot = btn:CreateTexture(nil, "OVERLAY")
        dot:SetSize(6, 6)
        dot:SetPoint("LEFT", btn, "LEFT", 12, 0)
        dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)

        local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", dot, "RIGHT", 8, 0)
        if currentCategory == "KEYSTONE" and activity.keystoneLink then
            nameText:SetText(activity.keystoneLink)
        else
            nameText:SetText(activity.name)
        end
        nameText:SetTextColor(unpack(_tc("textPrimary")))

        local templateText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        templateText:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
        local shortTemplate = activity.template or ""
        if #shortTemplate > 40 then
            shortTemplate = string.sub(shortTemplate, 1, 37) .. "..."
        end
        templateText:SetText(shortTemplate)
        templateText:SetTextColor(unpack(_tc("textDim")))

        btn:SetScript("OnEnter", function(self)
            bg:SetColorTexture(unpack(_tc("bgRowHover")))
            accentBar:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
            dot:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
            nameText:SetTextColor(1, 1, 1)
            templateText:SetTextColor(unpack(_tc("textNorm")))
        end)

        btn:SetScript("OnLeave", function(self)
            if i % 2 == 0 then
                bg:SetColorTexture(unpack(_tc("bgRowEven")))
            else
                bg:SetColorTexture(unpack(_tc("bgRowOdd")))
            end
            accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
            dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
            nameText:SetTextColor(unpack(_tc("textPrimary")))
            templateText:SetTextColor(unpack(_tc("textDim")))
        end)

        btn:SetScript("OnClick", function()
            userEditedMessage = false
            UpdateMessagePreview(activity.template, activity)
        end)

        LFM.activitiesContent.buttons[i] = btn
        yOffset = yOffset - 27
    end

    LFM.activitiesContent:SetHeight(math.max(math.abs(yOffset) + 10, 100))
end

function UpdateTabsAppearance()
    local categoryTabs = {
        { key = "RAIDS", name = "Raid" },
        { key = "DUNGEONS", name = "Dungeon" },
        { key = "MANASTORM", name = "Mana" },
        { key = "WORLD_BOSS", name = "WBoss" },
        { key = "PVP", name = "PvP" },
        { key = "KEYSTONE", name = "Key" }
    }

    for i, tabInfo in ipairs(categoryTabs) do
        local tab = _G["LFM_Tab_" .. tabInfo.key]
        if tab then
            if tabInfo.key == currentCategory then
                tab.bg:SetColorTexture(unpack(_tc("bgTabActive")))
                tab.text:SetTextColor(1, 1, 1)
            else
                tab.bg:SetColorTexture(unpack(_tc("bgBlock")))
                tab.text:SetTextColor(unpack(_tc("textMuted")))
            end
        end
    end
end

function LFM:UpdateAutoUpdateInterval()
    if keystoneUpdateTicker and currentCategory == "KEYSTONE" then
        StartKeystoneAutoUpdate()
    end
end

local function ClearActiveEditBox()
    if activeEditBox then
        activeEditBox:ClearFocus()
        activeEditBox = nil
    end
end

local function CloseAllDropdowns()
    if LFM.difficultyDropdown and LFM.difficultyDropdown.menu and LFM.difficultyDropdown.menu:IsShown() then
        LFM.difficultyDropdown.menu:Hide()
    end
end

local CreateModernButton = UI and UI.CreateModernButton or CreateFrame and function(parent, width, height, text, color)
    local c = color or _tc("primary")
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 70, height or 22)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 1, -1)
    btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", 0, 0)
    btn.border:SetPoint("BOTTOMRIGHT", 0, 0)
    btn.border:SetColorTexture(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.7)
    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    btn.accent:SetHeight(1.5)
    btn.accent:SetColorTexture(c[1], c[2], c[3], 0.4)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text or "")
    btn.text:SetTextColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2)
    btn.color = c
    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 0.9)
        self.border:SetColorTexture(c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 0.9)
        self.accent:SetColorTexture(c[1], c[2], c[3], 0.8)
        self.text:SetTextColor(min(c[1] * 1.4, 1), min(c[2] * 1.4, 1), min(c[3] * 1.4, 1))
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)
        self.border:SetColorTexture(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.7)
        self.accent:SetColorTexture(c[1], c[2], c[3], 0.4)
        self.text:SetTextColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2)
    end)
    return btn
end

local CreateModernEditBox = UI and UI.CreateModernEditBox or function(parent, width, height)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width or 120, height or 20)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormalSmall")
    eb:SetTextInsets(6, 6, 0, 0)
    eb.bg = eb:CreateTexture(nil, "BACKGROUND")
    eb.bg:SetPoint("TOPLEFT", 1, -1)
    eb.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    eb.bg:SetColorTexture(unpack(_tc("bgInput")))
    eb.border = eb:CreateTexture(nil, "BORDER")
    eb.border:SetPoint("TOPLEFT", 0, 0)
    eb.border:SetPoint("BOTTOMRIGHT", 0, 0)
    eb.border:SetColorTexture(unpack(_tc("borderInput")))
    eb.accent = eb:CreateTexture(nil, "OVERLAY")
    eb.accent:SetPoint("BOTTOMLEFT", 2, 0)
    eb.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    eb.accent:SetHeight(1.5)
    eb.accent:SetColorTexture(unpack(_tc("accentBar")))
    eb:SetScript("OnEditFocusGained", function(self)
        if activeEditBox and activeEditBox ~= self then
            activeEditBox:ClearFocus()
        end
        activeEditBox = self
        self.bg:SetColorTexture(unpack(_tc("bgInputFocus")))
        self.border:SetColorTexture(unpack(_tc("borderFocus")))
        self.accent:SetColorTexture(unpack(_tc("accentFocus")))
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        if activeEditBox == self then
            activeEditBox = nil
        end
        self.bg:SetColorTexture(unpack(_tc("bgInput")))
        self.border:SetColorTexture(unpack(_tc("borderInput")))
        self.accent:SetColorTexture(unpack(_tc("accentBar")))
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return eb
end

local CreateModernDropdown = UI and UI.CreateModernDropdown or function(parent, width, height)
    local dd = CreateFrame("Frame", nil, parent)
    dd:SetSize(width or 120, height or 22)
    dd.bg = dd:CreateTexture(nil, "BACKGROUND")
    dd.bg:SetPoint("TOPLEFT", 0, 0)
    dd.bg:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.bg:SetColorTexture(0, 0, 0, 1)
    dd.border = dd:CreateTexture(nil, "BORDER")
    dd.border:SetPoint("TOPLEFT", 0, 0)
    dd.border:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.border:SetColorTexture(unpack(_tc("borderMenu")))
    dd.accent = dd:CreateTexture(nil, "OVERLAY")
    dd.accent:SetPoint("BOTTOMLEFT", 2, 0)
    dd.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    dd.accent:SetHeight(1.5)
    dd.accent:SetColorTexture(unpack(_tc("accentBar")))
    dd.button = CreateFrame("Button", nil, dd)
    dd.button:SetAllPoints(dd)
    dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dd.text:SetPoint("LEFT", 6, 0)
    dd.text:SetTextColor(unpack(_tc("textPrimary")))
    dd.text:SetText("")
    dd.arrowText = dd:CreateFontString(nil, "OVERLAY")
    dd.arrowText:SetPoint("RIGHT", -6, 0)
    dd.arrowText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    dd.arrowText:SetText("v")
    dd.arrowText:SetTextColor(unpack(_tc("textNorm")))
    dd.menu = CreateFrame("Frame", nil, UIParent)
    dd.menu:SetFrameStrata("DIALOG")
    dd.menu:SetToplevel(true)
    dd.menu:EnableMouse(true)
    dd.menu:SetSize(width or 120, 10)
    dd.menu:Hide()
    dd.menuBg = dd.menu:CreateTexture(nil, "BACKGROUND")
    dd.menuBg:SetPoint("TOPLEFT", 0, 0)
    dd.menuBg:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.menuBg:SetColorTexture(unpack(_tc("bgMenuBg")))
    dd.menuBorder = dd.menu:CreateTexture(nil, "BORDER")
    dd.menuBorder:SetPoint("TOPLEFT", 0, 0)
    dd.menuBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.menuBorder:SetColorTexture(unpack(_tc("borderMenu")))
    dd.menu.buttons = {}
    dd.menu.maxShown = 20
    dd.options = {}
    dd.onChange = nil
    dd.menu:SetScript("OnHide", function()
        dd.border:SetColorTexture(unpack(_tc("borderMenu")))
        dd.accent:SetColorTexture(unpack(_tc("accentBar")))
    end)
    local function CloseMenu()
        dd.menu:Hide()
    end
    dd.closeHandler = CreateFrame("Frame", nil, UIParent)
    dd.closeHandler:RegisterEvent("GLOBAL_MOUSE_DOWN")
    dd.closeHandler:SetScript("OnEvent", function(self, event)
        if dd.menu:IsShown() then
            if not MouseIsOver(dd.menu) and not MouseIsOver(dd) then
                CloseMenu()
            end
        end
    end)
    local function ToggleMenu()
        if dd.menu:IsShown() then
            CloseMenu()
        else
            dd.menu:ClearAllPoints()
            dd.menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
            dd.menu:Show()
            dd.border:SetColorTexture(unpack(_tc("borderFocus")))
            dd.accent:SetColorTexture(unpack(_tc("accentFocus")))
        end
    end
    dd.button:SetScript("OnClick", ToggleMenu)
    dd.button:SetScript("OnEnter", function()
        if not dd.menu:IsShown() then
            dd.border:SetColorTexture(unpack(_tc("borderHover")))
            dd.accent:SetColorTexture(unpack(_tc("accentFocus")))
        end
    end)
    dd.button:SetScript("OnLeave", function()
        if not dd.menu:IsShown() then
            dd.border:SetColorTexture(unpack(_tc("borderMenu")))
            dd.accent:SetColorTexture(unpack(_tc("accentBar")))
        end
    end)
    function dd:SetOptions(options)
        self.options = options or {}
        for _, b in ipairs(self.menu.buttons) do
            b:Hide()
            b:SetParent(nil)
        end
        wipe(self.menu.buttons)
        local count = #self.options
        local maxH = min(count, self.menu.maxShown)
        self.menu:SetHeight(maxH * 22 + 4)
        for i, opt in ipairs(self.options) do
            local b = CreateFrame("Button", nil, self.menu)
            b:SetSize(self:GetWidth() - 2, 22)
            b:SetPoint("TOPLEFT", 1, -2 - (i-1) * 22)
            b.optBg = b:CreateTexture(nil, "BACKGROUND")
            b.optBg:SetAllPoints()
            b.optBg:SetColorTexture(0, 0, 0, 0)
            b.optAccent = b:CreateTexture(nil, "OVERLAY")
            b.optAccent:SetPoint("TOPLEFT", 0, 0)
            b.optAccent:SetSize(2, 22)
            b.optAccent:SetColorTexture(unpack(_tc("accentBar")))
            b.optAccent:SetAlpha(0)
            b.optText = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            b.optText:SetPoint("LEFT", 8, 0)
            b.optText:SetText(opt)
            b.optText:SetTextColor(unpack(_tc("textNorm")))
            b:Show()
            b:SetScript("OnEnter", function(self)
                self.optBg:SetColorTexture(unpack(_tc("bgRowHover")))
                self.optAccent:SetAlpha(1)
                self.optAccent:SetColorTexture(unpack(_tc("accentFocus")))
                self.optText:SetTextColor(unpack(_tc("textPrimary")))
            end)
            b:SetScript("OnLeave", function(self)
                self.optBg:SetColorTexture(0, 0, 0, 0)
                self.optAccent:SetAlpha(0)
                self.optText:SetTextColor(unpack(_tc("textNorm")))
            end)
            b:SetScript("OnClick", function()
                dd:SetText(opt)
                dd.selectedValue = opt
                CloseMenu()
                if dd.onChange then dd.onChange(opt) end
            end)
            self.menu.buttons[i] = b
        end
    end
    function dd:SetText(txt)
        self.text:SetText(txt)
    end
    function dd:GetText()
        return self.text:GetText()
    end
    return dd
end

local CreateSmallToggle = UI and UI.CreateSmallToggle or function(parent, text, x, y, width, height, onClick)
    local sc = _tc("success")
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 36, height or 20)
    btn:SetPoint("LEFT", parent, "LEFT", x, y)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 1, -1)
    btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bg:SetColorTexture(unpack(_tc("bgBlock")))
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", 0, 0)
    btn.border:SetPoint("BOTTOMRIGHT", 0, 0)
    local _bi = _tc("borderInput")
    btn.border:SetColorTexture(_bi[1], _bi[2], _bi[3], 0.7)
    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    btn.accent:SetHeight(1.5)
    local _ab = _tc("accentBar")
    btn.accent:SetColorTexture(_ab[1], _ab[2], _ab[3], 0.3)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(unpack(_tc("textMuted")))
    btn.active = false
    btn:SetScript("OnClick", function(self)
        self.active = not self.active
        if self.active then
            self.bg:SetColorTexture(sc[1] * 0.4, sc[2] * 0.4, sc[3] * 0.4, 0.85)
            self.border:SetColorTexture(sc[1] * 0.7, sc[2] * 0.7, sc[3] * 0.7, 0.9)
            self.accent:SetColorTexture(sc[1], sc[2], sc[3], 0.7)
            self.text:SetTextColor(min(sc[1] * 1.4, 1), min(sc[2] * 1.4, 1), min(sc[3] * 1.4, 1))
        else
            self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            local bi2 = _tc("borderInput")
            self.border:SetColorTexture(bi2[1], bi2[2], bi2[3], 0.7)
            local ab2 = _tc("accentBar")
            self.accent:SetColorTexture(ab2[1], ab2[2], ab2[3], 0.3)
            self.text:SetTextColor(unpack(_tc("textMuted")))
        end
        if onClick then onClick(self.active) end
    end)
    btn:SetScript("OnEnter", function(self)
        if self.active then
            self.bg:SetColorTexture(sc[1] * 0.5, sc[2] * 0.5, sc[3] * 0.5, 0.9)
            self.border:SetColorTexture(sc[1] * 0.8, sc[2] * 0.8, sc[3] * 0.8, 1.0)
            self.accent:SetColorTexture(min(sc[1] * 1.1, 1), min(sc[2] * 1.1, 1), min(sc[3] * 1.1, 1), 0.9)
        else
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            self.border:SetColorTexture(unpack(_tc("borderHover")))
            local ab3 = _tc("accentBar")
            self.accent:SetColorTexture(ab3[1], ab3[2], ab3[3], 0.5)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.active then
            self.bg:SetColorTexture(sc[1] * 0.4, sc[2] * 0.4, sc[3] * 0.4, 0.85)
            self.border:SetColorTexture(sc[1] * 0.7, sc[2] * 0.7, sc[3] * 0.7, 0.9)
            self.accent:SetColorTexture(sc[1], sc[2], sc[3], 0.7)
            self.text:SetTextColor(min(sc[1] * 1.4, 1), min(sc[2] * 1.4, 1), min(sc[3] * 1.4, 1))
        else
            self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            local bi3 = _tc("borderInput")
            self.border:SetColorTexture(bi3[1], bi3[2], bi3[3], 0.7)
            local ab4 = _tc("accentBar")
            self.accent:SetColorTexture(ab4[1], ab4[2], ab4[3], 0.3)
            self.text:SetTextColor(unpack(_tc("textMuted")))
        end
    end)
    btn:SetScript("OnMouseDown", function()
        ClearActiveEditBox()
        CloseAllDropdowns()
    end)
    return btn
end

function LFM:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(760, 520)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.mainContainer:EnableMouse(true)
    self.mainContainer:SetScript("OnMouseDown", function()
        ClearActiveEditBox()
        CloseAllDropdowns()
    end)

    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("TOP", self.mainContainer, "TOP", 0, -8)
    self.title:SetText("|cff88ccffLooking For Members|r")
    self.title:SetTextColor(0.8, 0.9, 1)

    self.desc = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.desc:SetPoint("TOP", self.title, "BOTTOM", 0, -3)
    self.desc:SetText("Create, edit and auto-spam LFM messages")
    self.desc:SetTextColor(unpack(_tc("textMuted")))

    self.rolesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.rolesFrame:SetSize(740, 26)
    self.rolesFrame:SetPoint("TOP", self.desc, "BOTTOM", 0, -6)

    local rolesLabel = self.rolesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rolesLabel:SetPoint("LEFT", self.rolesFrame, "LEFT", 10, 0)
    rolesLabel:SetText("Need:")
    rolesLabel:SetTextColor(unpack(_tc("textMuted")))

    self.roleCheckboxes = {}
    local roleTypes = {"Tank", "Healer", "DPS", "BC"}
    local ROLE_COLORS = Shared and Shared.ROLE_COLORS or { Tank = {0.3, 0.5, 0.85}, Healer = {0.2, 0.8, 0.3}, DPS = {0.85, 0.3, 0.2}, BC = {1, 0.8, 0.1} }
    local roleLabels = {Tank = "Tank", Healer = "Healer", DPS = "DPS", BC = "BC"}
    local xOffset = 20
    for i, role in ipairs(roleTypes) do
        local checkbox = CreateFrame("CheckButton", "FrostSeekLFM_Role_" .. role, self.rolesFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("LEFT", rolesLabel, "RIGHT", xOffset, 0)
        checkbox:SetSize(18, 18)
        local text = _G[checkbox:GetName() .. "Text"]
        if text then
            text:SetText(roleLabels[role])
            text:SetFontObject("GameFontNormalSmall")
            local rc = ROLE_COLORS[role] or {0.7, 0.7, 0.7}
            text:SetTextColor(rc[1], rc[2], rc[3])
        end
        checkbox:SetScript("OnClick", function(self)
            selectedRoles[role] = self:GetChecked()
            UpdateMessagePreview()
        end)
        self.roleCheckboxes[role] = checkbox

        if role ~= "BC" then
            local countBox = CreateModernEditBox(self.rolesFrame, 26, 18)
            if text then
                countBox:SetPoint("LEFT", text, "RIGHT", 4, 0)
            else
                countBox:SetPoint("LEFT", checkbox, "RIGHT", 40, 0)
            end
            countBox:SetText(tostring(needCount[role] or 1))
            countBox:SetMaxLetters(2)
            countBox:SetNumeric(true)
            countBox:SetScript("OnTextChanged", function(self)
                local val = tonumber(self:GetText()) or 1
                if val < 1 then val = 1 end
                needCount[role] = val
                UpdateMessagePreview()
            end)
            self.roleCheckboxes[role .. "Count"] = countBox
            xOffset = xOffset + 100
        else
            xOffset = xOffset + 55
        end
    end

    local difficultyLabel = self.rolesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    difficultyLabel:SetPoint("LEFT", self.roleCheckboxes["BC"], "RIGHT", 30, 0)
    difficultyLabel:SetText("Diff:")
    difficultyLabel:SetTextColor(unpack(_tc("textMuted")))

    self.difficultyDropdown = CreateModernDropdown(self.rolesFrame, 100, 22)
    self.difficultyDropdown:SetPoint("LEFT", difficultyLabel, "RIGHT", 5, 0)
    self.difficultyDropdown:SetText(selectedDifficulty)
    self.difficultyDropdown.onChange = function(val)
        selectedDifficulty = val
        UpdateMessagePreview()
    end

    self.searchFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.searchFrame:SetSize(740, 26)
    self.searchFrame:SetPoint("TOP", self.rolesFrame, "BOTTOM", 0, -4)

    local searchLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", self.searchFrame, "LEFT", 10, 0)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(unpack(_tc("textMuted")))

    self.searchBox = CreateModernEditBox(self.searchFrame, 160, 18)
    self.searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    self.searchBox:SetText("")
    self.searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText()
        UpdateActivityList()
    end)

    self.clearSearchBtn = CreateModernButton(self.searchFrame, 45, 18, "Clear", _tc("border"))
    self.clearSearchBtn:SetPoint("LEFT", self.searchBox, "RIGHT", 5, 0)
    self.clearSearchBtn:SetScript("OnClick", function()
        self.searchBox:SetText("")
        searchText = ""
        UpdateActivityList()
    end)

    self.categoriesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.categoriesFrame:SetSize(740, 26)
    self.categoriesFrame:SetPoint("TOP", self.searchFrame, "BOTTOM", 0, -4)

    local categoryTabs = {
        { key = "RAIDS", name = "Raid" },
        { key = "DUNGEONS", name = "Dungeon" },
        { key = "MANASTORM", name = "Mana" },
        { key = "WORLD_BOSS", name = "WBoss" },
        { key = "PVP", name = "PvP" },
        { key = "KEYSTONE", name = "Key" }
    }

    for i, tabInfo in ipairs(categoryTabs) do
        local tab = CreateFrame("Button", nil, self.categoriesFrame)
        tab:SetSize(70, 22)
        tab:SetPoint("LEFT", 10 + ((i-1) * 75), 0)

        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(unpack(_tc("bgBlock")))

        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabInfo.name)
        tab.text:SetTextColor(unpack(_tc("textPrimary")))

        tab:SetScript("OnClick", function()
            CloseAllDropdowns()
            ClearActiveEditBox()
            currentCategory = tabInfo.key
            if currentCategory == "KEYSTONE" then
                UpdateKeystoneList()
                StartKeystoneAutoUpdate()
                if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Show() end
            else
                StopKeystoneAutoUpdate()
                if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Hide() end
            end
            UpdateDifficultyDropdown()
            UpdateActivityList()
            UpdateTabsAppearance()
        end)

        tab:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        end)

        tab:SetScript("OnLeave", function(self)
            if tabInfo.key == currentCategory then
                self.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            else
                self.bg:SetColorTexture(unpack(_tc("bgBlock")))
            end
        end)

        _G["LFM_Tab_" .. tabInfo.key] = tab
    end

    self.activitiesFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.activitiesFrame:SetSize(740, 200)
    self.activitiesFrame:SetPoint("TOP", self.categoriesFrame, "BOTTOM", 0, -6)

    local activitiesBg = self.activitiesFrame:CreateTexture(nil, "BACKGROUND")
    activitiesBg:SetAllPoints()
    activitiesBg:SetColorTexture(unpack(_tc("bgRowOdd")))
    self.activitiesScrollFrame = CreateFrame("ScrollFrame", "FrostSeekActivitiesScroll", self.activitiesFrame, "UIPanelScrollFrameTemplate")

    self.activitiesScrollFrame:SetPoint("TOPLEFT", 5, -5)
    self.activitiesScrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

    self.activitiesContent = CreateFrame("Frame", nil, self.activitiesScrollFrame)
    self.activitiesContent:SetSize(700, 200)
    self.activitiesScrollFrame:SetScrollChild(self.activitiesContent)

    self.messageFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.messageFrame:SetSize(740, 32)
    self.messageFrame:SetPoint("TOP", self.activitiesFrame, "BOTTOM", 0, -6)

    local messageLabel = self.messageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    messageLabel:SetPoint("TOPLEFT", self.messageFrame, "TOPLEFT", 10, -2)
    messageLabel:SetText("Message:")
    messageLabel:SetTextColor(0.6, 0.8, 1)

    self.messageEditBox = CreateModernEditBox(self.messageFrame, 500, 20)
    self.messageEditBox:SetPoint("LEFT", messageLabel, "RIGHT", 5, 0)
    self.messageEditBox:SetPoint("RIGHT", self.messageFrame, "RIGHT", -10, 0)
    self.messageEditBox:SetText(customMessage)
    self.messageEditBox:SetMaxLetters(255)
    self.messageEditBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        customMessage = text
        FrostSeekDB.LFM.customMessage = customMessage
        if LFM.messageEditBox:HasFocus() then
            userEditedMessage = true
        end
    end)

    self.spamFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.spamFrame:SetSize(740, 28)
    self.spamFrame:SetPoint("TOP", self.messageFrame, "BOTTOM", 0, -4)

    local spamLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spamLabel:SetPoint("LEFT", self.spamFrame, "LEFT", 10, 0)
    spamLabel:SetText("Spam:")
    spamLabel:SetTextColor(0.6, 0.8, 1)

    local timerLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerLabel:SetPoint("LEFT", spamLabel, "RIGHT", 8, 0)
    timerLabel:SetText("Every")
    timerLabel:SetTextColor(unpack(_tc("textMuted")))

    self.spamTimerBox = CreateModernEditBox(self.spamFrame, 40, 18)
    self.spamTimerBox:SetPoint("LEFT", timerLabel, "RIGHT", 5, 0)
    self.spamTimerBox:SetText("30")
    self.spamTimerBox:SetMaxLetters(4)
    self.spamTimerBox:SetNumeric(true)

    local secLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    secLabel:SetPoint("LEFT", self.spamTimerBox, "RIGHT", 5, 0)
    secLabel:SetText("s")
    secLabel:SetTextColor(unpack(_tc("textMuted")))

    self.spamBtn = CreateModernButton(self.spamFrame, 76, 20, "Start Spam", _tc("success"))
    self.spamBtn:SetPoint("LEFT", secLabel, "RIGHT", 10, 0)
    self.spamBtn:SetScript("OnClick", function()
        if autoSpamActive then
            LFM:StopAutoSpam()
        else
            LFM:StartAutoSpam()
        end
    end)

    self.spamStatusText = self.spamFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.spamStatusText:SetPoint("LEFT", self.spamBtn, "RIGHT", 10, 0)
    self.spamStatusText:SetText("")
    self.spamStatusText:Hide()

    local chLabel = self.spamFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chLabel:SetPoint("RIGHT", self.spamFrame, "RIGHT", -290, 0)
    chLabel:SetText("Channel:")
    chLabel:SetTextColor(unpack(_tc("textMuted")))

    local function GetChannelSlotName(slotIndex)
        local ok, id, name = pcall(function() return GetChannelName(slotIndex) end)
        if ok and type(id) == "number" and id > 0 and name and tostring(name) ~= "" then
            return tostring(name)
        end
        return nil
    end

    self.spamChannelButtons = {}
    self.spamChannelLabels = {}
    for i = 1, 5 do
        local chSlotName = GetChannelSlotName(i)
        local btnLabel = chSlotName and string.sub(chSlotName, 1, 5) or tostring(i)
        local btn = CreateSmallToggle(self.spamFrame, btnLabel,
            740 - 270 + (i-1) * 40, 0, 34, 20,
            function(active)
                spamChannels[i] = active
                if not FrostSeekDB.LFM.spamChannels then FrostSeekDB.LFM.spamChannels = {} end
                FrostSeekDB.LFM.spamChannels[i] = active
            end
        )

        if chSlotName then
            btn:SetScript("OnEnter", function(selfBtn)
                GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
                GameTooltip:AddLine("Channel " .. i .. ": " .. chSlotName, 1, 1, 1)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(selfBtn)
                GameTooltip:Hide()
            end)
        end
        if FrostSeekDB.LFM.spamChannels and FrostSeekDB.LFM.spamChannels[i] then
            btn.active = true
            spamChannels[i] = true
            if chSlotName then
                btn.bg:SetColorTexture(unpack(_tc("success")))
                btn.text:SetTextColor(0.4, 1, 0.4)
            else
                btn.bg:SetColorTexture(unpack(_tc("textDim")))
                btn.text:SetTextColor(0.5, 0.5, 0.5)
            end
        elseif not chSlotName then
            btn.text:SetTextColor(0.4, 0.4, 0.4)
        end
        self.spamChannelButtons[i] = btn
    end

    self.refreshChannelTimer = C_Timer.NewTicker(5, function()
        for i = 1, 5 do
            local btn = self.spamChannelButtons[i]
            if btn then
                local chSlotName = GetChannelSlotName(i)
                local newLabel = chSlotName and string.sub(chSlotName, 1, 5) or tostring(i)
                if btn.text then
                    btn.text:SetText(newLabel)
                end
                if chSlotName then
                    btn:SetScript("OnEnter", function(selfBtn)
                        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
                        GameTooltip:AddLine("Channel " .. i .. ": " .. chSlotName, 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function(selfBtn)
                        GameTooltip:Hide()
                    end)
                    if spamChannels[i] then
                        btn.bg:SetColorTexture(unpack(_tc("success")))
                        btn.text:SetTextColor(0.4, 1, 0.4)
                    else
                        btn.text:SetTextColor(1, 1, 1)
                    end
                else
                    btn:SetScript("OnEnter", function(selfBtn)
                        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
                        GameTooltip:AddLine("Channel " .. i .. ": (empty)", 0.6, 0.6, 0.6)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function(selfBtn)
                        GameTooltip:Hide()
                    end)
                    btn.text:SetTextColor(0.4, 0.4, 0.4)
                end
            end
        end
    end)

    self.autoInviteFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.autoInviteFrame:SetSize(740, 28)
    self.autoInviteFrame:SetPoint("TOP", self.spamFrame, "BOTTOM", 0, -4)

    local aiLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    aiLabel:SetPoint("LEFT", self.autoInviteFrame, "LEFT", 10, 0)
    aiLabel:SetText("Auto-Invite:")
    aiLabel:SetTextColor(0.6, 0.8, 1)

    self.autoInviteToggle = CreateSmallToggle(self.autoInviteFrame, "ON/OFF", 90, 0, 50, 20,
        function(active)
            autoInviteEnabled = active
            FrostSeekDB.LFM.autoInviteEnabled = active
            if active then
                print("|cff88ccffFrostSeek LFM:|r Auto-Invite enabled (min iLvl: " .. autoInviteMinIlvl .. ", min Lvl: " .. autoInviteMinLevel .. ")")
            else
                print("|cff88ccffFrostSeek LFM:|r Auto-Invite disabled")
            end
        end
    )

    if FrostSeekDB.LFM.autoInviteEnabled then
        self.autoInviteToggle.active = true
        autoInviteEnabled = true
        self.autoInviteToggle.bg:SetColorTexture(unpack(_tc("success")))
        self.autoInviteToggle.text:SetTextColor(0.4, 1, 0.4)
    end

    local minIlvlLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minIlvlLabel:SetPoint("LEFT", self.autoInviteToggle, "RIGHT", 10, 0)
    minIlvlLabel:SetText("Min iLvl:")
    minIlvlLabel:SetTextColor(unpack(_tc("textMuted")))

    self.minIlvlBox = CreateModernEditBox(self.autoInviteFrame, 50, 18)
    self.minIlvlBox:SetPoint("LEFT", minIlvlLabel, "RIGHT", 5, 0)
    self.minIlvlBox:SetText(tostring(FrostSeekDB.LFM.autoInviteMinIlvl or 150))
    self.minIlvlBox:SetMaxLetters(4)
    self.minIlvlBox:SetNumeric(true)
    autoInviteMinIlvl = FrostSeekDB.LFM.autoInviteMinIlvl or 150

    local plusLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    plusLabel:SetPoint("LEFT", self.minIlvlBox, "RIGHT", 3, 0)
    plusLabel:SetText("+")
    plusLabel:SetTextColor(0.4, 1, 0.4)

    self.minIlvlBox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText()) or 0
        autoInviteMinIlvl = val
        FrostSeekDB.LFM.autoInviteMinIlvl = val
    end)

    local minLevelLabel = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minLevelLabel:SetPoint("LEFT", plusLabel, "RIGHT", 15, 0)
    minLevelLabel:SetText("Min Lvl:")
    minLevelLabel:SetTextColor(unpack(_tc("textMuted")))

    self.minLevelBox = CreateModernEditBox(self.autoInviteFrame, 40, 18)
    self.minLevelBox:SetPoint("LEFT", minLevelLabel, "RIGHT", 5, 0)
    self.minLevelBox:SetText(tostring(FrostSeekDB.LFM.autoInviteMinLevel or 60))
    self.minLevelBox:SetMaxLetters(3)
    self.minLevelBox:SetNumeric(true)
    autoInviteMinLevel = FrostSeekDB.LFM.autoInviteMinLevel or 60

    self.minLevelBox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText()) or 0
        autoInviteMinLevel = val
        FrostSeekDB.LFM.autoInviteMinLevel = val
    end)

    local aiDesc = self.autoInviteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    aiDesc:SetPoint("LEFT", self.minLevelBox, "RIGHT", 8, 0)
    aiDesc:SetText("(invites on whisper if iLvl/lvl >= threshold)")
    aiDesc:SetTextColor(unpack(_tc("textDim")))

    self.controlsFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.controlsFrame:SetSize(740, 32)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 8)

    self.sendAllBtn = CreateModernButton(self.controlsFrame, 76, 22, "Send All", _tc("warning"))
    self.sendAllBtn:SetPoint("RIGHT", -5, 20)
    self.sendAllBtn:SetScript("OnClick", function(btn)
        local message = LFM.messageEditBox:GetText()
        if message and message ~= "" then
            local warning = ValidateGroupComposition()
            if warning then
                print("|cffffaa00FrostSeek LFM:|r " .. warning)
            end
            local sent = SendToAllSpamChannels(message)
            if sent > 0 then
                print("|cff88ccffFrostSeek LFM:|r Sent to " .. sent .. " channel(s)")
                if Shared and Shared.PlaySound then
                    Shared.PlaySound("listing")
                end
            else
                print("|cffff0000FrostSeek LFM:|r No spam channels selected! Select Ch# toggles above.")
            end
        else
            print("|cffff0000FrostSeek LFM:|r No message to send!")
        end
    end)
    self.sendAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Send to All Spam Channels", 1, 1, 1)
        GameTooltip:AddLine("Sends the message to all selected Ch#.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    self.sendAllBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    UpdateDifficultyDropdown()
    UpdateTabsAppearance()
    UpdateActivityList()

    self.frame:Hide()
end

function LFM:Show()
    if not self.frame then return end
    if currentCategory == "KEYSTONE" then
        UpdateKeystoneList()
        StartKeystoneAutoUpdate()
        if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Show() end
    else
        StopKeystoneAutoUpdate()
        if self.refreshKeystoneBtn then self.refreshKeystoneBtn:Hide() end
    end
    self.frame:Show()
end

function LFM:Hide()
    if self.frame then self.frame:Hide() end
    StopKeystoneAutoUpdate()
end

function LFM:RefreshData()
    UpdateActivityList()
    UpdateMessagePreview()
end

local bagUpdateHandler = CreateFrame("Frame")
bagUpdateHandler:RegisterEvent("BAG_UPDATE_DELAYED")
bagUpdateHandler:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" and currentCategory == "KEYSTONE" then
        C_Timer.After(0.5, function()
            UpdateKeystoneList()
        end)
    end
end)

local function InitializeLFMSystem()
    FrostSeekDB.LFM = FrostSeekDB.LFM or {
        lastMessages = {},
        favoriteTemplates = {},
        channelPresets = {},
        autoUpdateInterval = 60,
        autoSpamInterval = 30,
        spamChannels = {},
        autoInviteEnabled = false,
        autoInviteMinIlvl = 150,
        autoInviteMinLevel = 60,
    }

    if not FrostSeekDB.LFM.spamChannels then
        FrostSeekDB.LFM.spamChannels = {}
    end
    if FrostSeekDB.LFM.autoInviteMinIlvl == nil then
        FrostSeekDB.LFM.autoInviteMinIlvl = 150
    end
    if FrostSeekDB.LFM.autoInviteMinLevel == nil then
        FrostSeekDB.LFM.autoInviteMinLevel = 60
    end

    if not LFM_ACTIVITIES.KEYSTONE then
        LFM_ACTIVITIES.KEYSTONE = {}
    end
end

function LFM:ApplyTheme()
    if UpdateTabsAppearance then UpdateTabsAppearance() end
    if UpdateActivityList then UpdateActivityList() end
    if UpdateDifficultyDropdown then UpdateDifficultyDropdown() end
    if LFM.spamBtn and not autoSpamActive then
        local successC = _tc("success")
        LFM.spamBtn.color = successC
        LFM.spamBtn.text:SetTextColor(min(successC[1] * 1.2, 1), min(successC[2] * 1.2, 1), min(successC[3] * 1.2, 1))
        LFM.spamBtn.bg:SetColorTexture(successC[1] * 0.25, successC[2] * 0.25, successC[3] * 0.25, 0.8)
        LFM.spamBtn.border:SetColorTexture(successC[1] * 0.5, successC[2] * 0.5, successC[3] * 0.5, 0.7)
        LFM.spamBtn.accent:SetColorTexture(successC[1], successC[2], successC[3], 0.4)
    end

    if LFM.sendAllBtn then
        local warnC = _tc("warning")
        LFM.sendAllBtn.color = warnC
        LFM.sendAllBtn.text:SetTextColor(min(warnC[1] * 1.2, 1), min(warnC[2] * 1.2, 1), min(warnC[3] * 1.2, 1))
        LFM.sendAllBtn.bg:SetColorTexture(warnC[1] * 0.25, warnC[2] * 0.25, warnC[3] * 0.25, 0.8)
        LFM.sendAllBtn.border:SetColorTexture(warnC[1] * 0.5, warnC[2] * 0.5, warnC[3] * 0.5, 0.7)
        LFM.sendAllBtn.accent:SetColorTexture(warnC[1], warnC[2], warnC[3], 0.4)
    end

    if LFM.clearSearchBtn then
        local borderC = _tc("border")
        LFM.clearSearchBtn.color = borderC
        LFM.clearSearchBtn.text:SetTextColor(min(borderC[1] * 1.2, 1), min(borderC[2] * 1.2, 1), min(borderC[3] * 1.2, 1))
        LFM.clearSearchBtn.bg:SetColorTexture(borderC[1] * 0.25, borderC[2] * 0.25, borderC[3] * 0.25, 0.8)
        LFM.clearSearchBtn.border:SetColorTexture(borderC[1] * 0.5, borderC[2] * 0.5, borderC[3] * 0.5, 0.7)
        LFM.clearSearchBtn.accent:SetColorTexture(borderC[1], borderC[2], borderC[3], 0.4)
    end
end

if not _G.FrostSeek then return end
if not _G.FrostSeek._v or not _G.FrostSeek._v.c(_tk) then return end

InitializeLFMSystem()

if _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("lfm", LFM)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("lfm")
end