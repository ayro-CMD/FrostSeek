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

local LFM = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfm", LFM)

LFM._S = {
    currentCategory = "RAIDS",
    selectedRoles = { Tank = false, Healer = false, DPS = false, Support = false, BC = false },
    needCount = { Tank = 1, Healer = 1, DPS = 1, Support = 0 },
    selectedDifficulty = "Normal",
    searchText = "",
    keystoneUpdateTicker = nil,
    autoSpamActive = false,
    customMessage = (FrostSeekDB and FrostSeekDB.LFM and FrostSeekDB.LFM.customMessage) or "",
    autoInviteEnabled = false,
    autoInviteMinIlvl = 0,
    autoInviteMinLevel = 60,
    spamChannels = {},
}

local LFM_ACTIVITIES = {
    RAIDS = {
        { name = "Molten Core", template = "LFM Molten Core {difficulty} {roles}", keywords = {"mc", "molten core"}, exp = 0 },
        { name = "Onyxia", template = "LFM Onyxia {difficulty} {roles}", keywords = {"onyxia", "ony"}, exp = 0 },
        { name = "Blackwing Lair", template = "LFM Blackwing Lair {difficulty} {roles}", keywords = {"bwl", "blackwing"}, exp = 0 },
        { name = "Zul'Gurub", template = "LFM Zul'Gurub {difficulty} {roles}", keywords = {"zg", "zulgurub"}, exp = 0 },
        { name = "Ruins of Ahn'Qiraj", template = "LFM Ruins of AQ {difficulty} {roles}", keywords = {"aq20", "ruins"}, exp = 0 },
        { name = "Temple of Ahn'Qiraj", template = "LFM Temple of AQ {difficulty} {roles}", keywords = {"aq40", "temple"}, exp = 0 },
        { name = "Naxxramas", template = "LFM Naxxramas {difficulty} {roles}", keywords = {"naxx", "naxxramas"}, exp = 0 },
        { name = "Karazhan", template = "LFM Karazhan {difficulty} {roles}", keywords = {"kara", "karazhan"}, exp = 1 },
        { name = "Gruul's Lair", template = "LFM Gruul {difficulty} {roles}", keywords = {"gruul"}, exp = 1 },
        { name = "Magtheridon", template = "LFM Magtheridon {difficulty} {roles}", keywords = {"mag", "magtheridon"}, exp = 1 },
        { name = "Serpentshrine Cavern", template = "LFM SSC {difficulty} {roles}", keywords = {"ssc", "serpentshrine"}, exp = 1 },
        { name = "Tempest Keep", template = "LFM TK {difficulty} {roles}", keywords = {"tk", "tempest"}, exp = 1 },
        { name = "Hyjal Summit", template = "LFM Hyjal {difficulty} {roles}", keywords = {"hyjal"}, exp = 1 },
        { name = "Black Temple", template = "LFM BT {difficulty} {roles}", keywords = {"bt", "black temple"}, exp = 1 },
        { name = "Zul'Aman", template = "LFM Zul'Aman {difficulty} {roles}", keywords = {"za", "zulaman"}, exp = 1 },
        { name = "Sunwell Plateau", template = "LFM Sunwell {difficulty} {roles}", keywords = {"swp", "sunwell"}, exp = 1 },
        { name = "Eye of Eternity", template = "LFM Eye of Eternity {difficulty} {roles}", keywords = {"eye", "eoe", "malygos"}, exp = 2 },
        { name = "Obsidian Sanctum", template = "LFM OS {difficulty} {roles}", keywords = {"os", "obsidian", "sarth"}, exp = 2 },
        { name = "Vault of Archavon", template = "LFM VoA {difficulty} {roles}", keywords = {"voa", "archavon"}, exp = 2 },
        { name = "Ulduar", template = "LFM Ulduar {difficulty} {roles}", keywords = {"ulduar", "uld"}, exp = 2 },
        { name = "Trial of the Crusader", template = "LFM ToC {difficulty} {roles}", keywords = {"toc", "crusader"}, exp = 2 },
        { name = "Icecrown Citadel", template = "LFM ICC {difficulty} {roles}", keywords = {"icc", "icecrown"}, exp = 2 },
        { name = "Ruby Sanctum", template = "LFM Ruby Sanctum {difficulty} {roles}", keywords = {"rs", "ruby", "halion"}, exp = 2 },
        { name = "Baradin Hold", template = "LFM Baradin Hold {difficulty} {roles}", keywords = {"bh", "baradin"}, exp = 3 },
        { name = "Bastion of Twilight", template = "LFM BoT {difficulty} {roles}", keywords = {"bot", "bastion", "twilight"}, exp = 3 },
        { name = "Throne of the Four Winds", template = "LFM T4W {difficulty} {roles}", keywords = {"t4w", "four winds", "al'akir"}, exp = 3 },
        { name = "Blackwing Descent", template = "LFM BWD {difficulty} {roles}", keywords = {"bwd", "blackwing descent", "nefarian"}, exp = 3 },
        { name = "Firelands", template = "LFM Firelands {difficulty} {roles}", keywords = {"fl", "firelands", "ragnaros"}, exp = 3 },
        { name = "Dragon Soul", template = "LFM Dragon Soul {difficulty} {roles}", keywords = {"ds", "dragon soul", "deathwing"}, exp = 3 },
        { name = "Terrace of Endless Spring", template = "LFM ToES {difficulty} {roles}", keywords = {"toes", "terrace", "endless spring"}, exp = 4 },
        { name = "Mogu'shan Vaults", template = "LFM MSV {difficulty} {roles}", keywords = {"msv", "mogushan", "vaults"}, exp = 4 },
        { name = "Heart of Fear", template = "LFM HoF {difficulty} {roles}", keywords = {"hof", "heart of fear", "shek'zeer"}, exp = 4 },
        { name = "Throne of Thunder", template = "LFM ToT {difficulty} {roles}", keywords = {"tot", "thunder", "lei shen"}, exp = 4 },
        { name = "Siege of Orgrimmar", template = "LFM SoO {difficulty} {roles}", keywords = {"soo", "siege", "orgrimmar", "garrosh"}, exp = 4 },
        { name = "The Radiant Spring", template = "LFM TRS {difficulty} {roles}", keywords = {"TRS", "radiant", "spring"}, exp = 97 },

    },
    DUNGEONS = {
        { name = "Deadmines", template = "LFM Deadmines {difficulty} {roles}", keywords = {"deadmines", "dm", "vc"}, exp = 0 },
        { name = "Wailing Caverns", template = "LFM Wailing Caverns {difficulty} {roles}", keywords = {"Wailing Caverns"}, exp = 0 },
        { name = "Ragefire Chasm", template = "LFM Ragefire Chasm {difficulty} {roles}", keywords = {"rfc", "ragefire"}, exp = 0 },
        { name = "Shadowfang Keep", template = "LFM SFK {difficulty} {roles}", keywords = {"sfk", "shadowfang"}, exp = 0 },
        { name = "Blackrock Depths", template = "LFM BRD {difficulty} {roles}", keywords = {"brd", "blackrock depths"}, exp = 0 },
        { name = "Blackfathom Deeps", template = "LFM BFD {difficulty} {roles}", keywords = {"bfd", "Blackfathom Deeps"}, exp = 0 },
        { name = "Scholomance", template = "LFM Scholo {difficulty} {roles}", keywords = {"scholo", "scholomance"}, exp = 0 },
        { name = "Lower Blackrock Spire", template = "LFM LBRS {difficulty} {roles}", keywords = {"lbrs", "lower"}, exp = 0 },
        { name = "Upper Blackrock Spire", template = "LFM UBRS {difficulty} {roles}", keywords = {"ubrs", "upper"}, exp = 0 },
        { name = "Dire Maul East", template = "LFM DME {difficulty} {roles}", keywords = {"dme", "east"}, exp = 0 },
        { name = "Dire Maul North", template = "LFM DMN {difficulty} {roles}", keywords = {"dmn", "north"}, exp = 0 },
        { name = "Dire Maul West", template = "LFM DMW {difficulty} {roles}", keywords = {"dmw", "west"}, exp = 0 },
        { name = "The Stockade", template = "LFM The Stockade {difficulty} {roles}", keywords = {"Stockade"}, exp = 0 },
        { name = "Gnomeregan", template = "LFM Gnomeregan {difficulty} {roles}", keywords = {"Gnomeregan"}, exp = 0 },
        { name = "Razorfen Kraul", template = "LFM Razorfen Kraul {difficulty} {roles}", keywords = {"Razorfen Kraul"}, exp = 0 },
        { name = "Scarlet Monastery", template = "LFM Scarlet Monastery {difficulty} {roles}", keywords = {"Scarlet Monastery"}, exp = 0 },
        { name = "Razorfen Downs", template = "LFM Razorfen Downs {roles}", keywords = {"Razorfen"}, exp = 0 },
        { name = "Uldaman", template = "LFM Uldaman {difficulty} {roles}", keywords = {"Uldaman"}, exp = 0 },
        { name = "Zul'Farrak", template = "LFM Zul'Farrak {difficulty} {roles}", keywords = {"Zul'Farrak"}, exp = 0 },
        { name = "Maraudon", template = "LFM Maraudon {difficulty} {roles}", keywords = {"Maraudon"}, exp = 0 },
        { name = "Stratholme", template = "LFM Strat {difficulty} {roles}", keywords = {"strat", "stratholme"}, exp = 0 },
        { name = "Hellfire Ramparts", template = "LFM Ramparts {difficulty} {roles}", keywords = {"ramps", "ramparts"}, exp = 1 },
        { name = "Blood Furnace", template = "LFM Blood Furnace {difficulty} {roles}", keywords = {"bf", "blood furnace"}, exp = 1 },
        { name = "The Shattered Halls", template = "LFM Shattered Halls {difficulty} {roles}", keywords = {"Shattered Halls"}, exp = 1 },
        { name = "Slave Pens", template = "LFM Slave Pens {difficulty} {roles}", keywords = {"sp", "slave pens"}, exp = 1 },
        { name = "Underbog", template = "LFM Underbog {difficulty} {roles}", keywords = {"ub", "underbog"}, exp = 1 },
        { name = "The Steamvault", template = "LFM Steamvault {difficulty} {roles}", keywords = {"st", "Steamvault"}, exp = 1 },
        { name = "Mana-Tombs", template = "LFM Mana-Tombs {difficulty} {roles}", keywords = {"mt", "mana-tombs"}, exp = 1 },
        { name = "Auchenai Crypts", template = "LFM Auchenai {difficulty} {roles}", keywords = {"ac", "auchenai"}, exp = 1 },
        { name = "Sethekk Halls", template = "LFM Sethekk {difficulty} {roles}", keywords = {"sh", "sethekk"}, exp = 1 },
        { name = "Shadow Labyrinth", template = "LFM Shadow Laby {difficulty} {roles}", keywords = {"sl", "slabs", "shadow lab"}, exp = 1 },
        { name = "Mechanar", template = "LFM Mechanar {difficulty} {roles}", keywords = {"mecha", "mechanar"}, exp = 1 },
        { name = "Botanica", template = "LFM Botanica {difficulty} {roles}", keywords = {"bota", "botanica"}, exp = 1 },
        { name = "Arcatraz", template = "LFM Arcatraz {difficulty} {roles}", keywords = {"arca", "arcatraz"}, exp = 1 },
        { name = "Magister's Terrace", template = "LFM Magister's {difficulty} {roles}", keywords = {"mgt", "magisters"}, exp = 1 },
        { name = "Utgarde Keep", template = "LFM UK {difficulty} {roles}", keywords = {"uk", "utgarde keep"}, exp = 2 },
        { name = "Utgarde Pinnacle", template = "LFM UP {difficulty} {roles}", keywords = {"up", "pinnacle"}, exp = 2 },
        { name = "The Nexus", template = "LFM Nexus {difficulty} {roles}", keywords = {"nexus", "nex"}, exp = 2 },
        { name = "The Oculus", template = "LFM Oculus {difficulty} {roles}", keywords = {"oculus", "ocu"}, exp = 2 },
        { name = "Azjol-Nerub", template = "LFM AN {difficulty} {roles}", keywords = {"an", "azjol"}, exp = 2 },
        { name = "Ahn'kahet", template = "LFM Old Kingdom {difficulty} {roles}", keywords = {"ak", "ahn'kahet"}, exp = 2 },
        { name = "Drak'Tharon Keep", template = "LFM DTK {difficulty} {roles}", keywords = {"dtk", "drak'tharon"}, exp = 2 },
        { name = "Violet Hold", template = "LFM Violet Hold {difficulty} {roles}", keywords = {"vh", "violet"}, exp = 2 },
        { name = "Gundrak", template = "LFM Gundrak {difficulty} {roles}", keywords = {"gun", "gundrak"}, exp = 2 },
        { name = "Halls of Stone", template = "LFM HoS {difficulty} {roles}", keywords = {"hos", "halls stone"}, exp = 2 },
        { name = "Halls of Lightning", template = "LFM HoL {difficulty} {roles}", keywords = {"hol", "halls lightning"}, exp = 2 },
        { name = "Culling of Stratholme", template = "LFM CoS {difficulty} {roles}", keywords = {"cos", "culling"}, exp = 2 },
        { name = "Trial of the Champion", template = "LFM ToC Dungeon {difficulty} {roles}", keywords = {"toc", "champion"}, exp = 2 },
        { name = "Forge of Souls", template = "LFM Forge of Souls {difficulty} {roles}", keywords = {"fos", "forge"}, exp = 2 },
        { name = "Pit of Saron", template = "LFM Pit of Saron {difficulty} {roles}", keywords = {"pos", "pit"}, exp = 2 },
        { name = "Halls of Reflection", template = "LFM HoR {difficulty} {roles}", keywords = {"hor", "reflection"}, exp = 2 },
        { name = "Blackrock Caverns", template = "LFM BRC {difficulty} {roles}", keywords = {"brc", "blackrock caverns"}, exp = 3 },
        { name = "Throne of the Tides", template = "LFM TotT {difficulty} {roles}", keywords = {"tott", "throne tides", "naz'jar"}, exp = 3 },
        { name = "The Vortex Pinnacle", template = "LFM VP {difficulty} {roles}", keywords = {"vp", "vortex", "pinnacle"}, exp = 3 },
        { name = "Stonecore", template = "LFM Stonecore {difficulty} {roles}", keywords = {"sc", "stonecore"}, exp = 3 },
        { name = "Lost City of the Tol'vir", template = "LFM LCT {difficulty} {roles}", keywords = {"lct", "tol'vir", "lost city"}, exp = 3 },
        { name = "Halls of Origination", template = "LFM HoO {difficulty} {roles}", keywords = {"hoo", "origination"}, exp = 3 },
        { name = "Grim Batol", template = "LFM GB {difficulty} {roles}", keywords = {"gb", "grim batol"}, exp = 3 },
        { name = "Zul'Gurub (Cata)", template = "LFM ZG {difficulty} {roles}", keywords = {"zg", "zulgurub"}, exp = 3 },
        { name = "Zul'Aman (Cata)", template = "LFM ZA {difficulty} {roles}", keywords = {"za", "zulaman"}, exp = 3 },
        { name = "End Time", template = "LFM End Time {difficulty} {roles}", keywords = {"et", "end time"}, exp = 3 },
        { name = "Well of Eternity", template = "LFM WoE {difficulty} {roles}", keywords = {"woe", "well eternity"}, exp = 3 },
        { name = "Hour of Twilight", template = "LFM HoT {difficulty} {roles}", keywords = {"hot", "hour twilight"}, exp = 3 },
        { name = "Temple of the Jade Serpent", template = "LFM TJS {difficulty} {roles}", keywords = {"tjs", "jade serpent", "temple"}, exp = 4 },
        { name = "Stormstout Brewery", template = "LFM SB {difficulty} {roles}", keywords = {"sb", "stormstout", "brewery"}, exp = 4 },
        { name = "Shado-Pan Monastery", template = "LFM SPM {difficulty} {roles}", keywords = {"spm", "shado-pan"}, exp = 4 },
        { name = "Mogu'shan Palace", template = "LFM MSP {difficulty} {roles}", keywords = {"msp", "mogushan palace"}, exp = 4 },
        { name = "Scarlet Halls", template = "LFM Scarlet Halls {difficulty} {roles}", keywords = {"scarlet halls"}, exp = 4 },
        { name = "Scarlet Monastery (MoP)", template = "LFM SM {difficulty} {roles}", keywords = {"sm", "scarlet monastery"}, exp = 4 },
        { name = "Siege of Niuzao Temple", template = "LFM Niuzao {difficulty} {roles}", keywords = {"niuzao", "siege"}, exp = 4 },
        { name = "Gate of the Setting Sun", template = "LFM GSS {difficulty} {roles}", keywords = {"gss", "setting sun"}, exp = 4 },
        { name = "Scholomance (MoP)", template = "LFM Scholo {difficulty} {roles}", keywords = {"scholo", "scholomance"}, exp = 4 },
        { name = "Glittermurk Mines", template = "Glittermurk Mines {difficulty} {roles}", keywords = {"glittermurk"}, exp = 98 },
        { name = "Tor'Watha", template = "LFM Tor'Watha {difficulty} {roles}", keywords = {"Tor'Watha", "tw"}, exp = 97 },
        { name = "Bardid Hold", template = "LFM Bardid Hold {roles}", keywords = {"Bardid Hold", "BH"}, exp = 97 },
        { name = "Vault of the Inquisition", template = "LFM Vault {difficulty} {roles}", keywords = {"vault", "inquisition"}, exp = 97 },
        { name = "Road to De' Other Side", template = "LFM Other Side {difficulty} {roles}", keywords = {"Road to De' Other Side"}, exp = 97 },
        { name = "Shadowbone depths", template = "LFM SBD {difficulty} {roles}", keywords = {"sbd", "Shadowbone depths"}, exp = 97 },
        { name = "The Temple of Embers", template = "LFM TOE {difficulty} {roles}", keywords = {"toe", "the temple of embers"}, exp = 97 },
        { name = "RDF", template = "LFM RDF {difficulty} {roles}", keywords = {"rdf", "random dungeon finder"} },
    },
    MANASTORM = {
        { name = "ALVA", template = "LFM ALVA Boss {roles}", keywords = {"alva", "boss"}, exp = 97 },
        { name = "Manastorm Gold Farm", template = "LFM Manastorm Gold {roles}", keywords = {"manastorm", "gold", "farm"}, exp = 97 },
        { name = "Manastorm Leveling", template = "LFM Manastorm Level {roles}", keywords = {"manastorm", "level", "xp"}, exp = 97 },
        { name = "Manastorm Bonzo Farm", template = "LFM Bonzo {roles}", keywords = {"bonzo", "farm"}, exp = 97 },
    },
    WORLD_BOSS = {
        { name = "Azuregos", template = "LFM Azuregos {difficulty} {roles}", keywords = {"azuregos", "azure"}, exp = 0 },
        { name = "Lord Kazzak", template = "LFM Lord Kazzak {difficulty} {roles}", keywords = {"kazzak"}, exp = 0 },
        { name = "Setis", template = "LFM Setis {difficulty} {roles}", keywords = {"setis", "settis"}, exp = 0 },
        { name = "Emeriss", template = "LFM Emeriss {difficulty} {roles}", keywords = {"emeriss"}, exp = 0 },
        { name = "Lethon", template = "LFM Lethon {difficulty} {roles}", keywords = {"lethon"}, exp = 0 },
        { name = "Taerar", template = "LFM Taerar {difficulty} {roles}", keywords = {"taerar"}, exp = 0 },
        { name = "Ysondre", template = "LFM Ysondre {difficulty} {roles}", keywords = {"ysondre"}, exp = 0 },
        { name = "Doomwalker", template = "LFM Doomwalker {difficulty} {roles}", keywords = {"doomwalker"}, exp = 1 },
        { name = "Doom Lord Kazzak", template = "LFM Doom Lord Kazzak {difficulty} {roles}", keywords = {"doom"}, exp = 1 },
        { name = "Soggoth", template = "LFM Soggoth {difficulty} {roles}", keywords = {"soggoth"}, exp = 97 },
        { name = "Snowgrave", template = "LFM Snowgrave {difficulty} {roles}", keywords = {"snowgrave"}, exp = 97 },
        { name = "Atal'Zul", template = "LFM Atal'Zul {difficulty} {roles}", keywords = {"atal'Zul"}, exp = 97 },
        { name = "Kaldros Depthbreaker", template = "LFM Kaldros Depthbreaker {difficulty} {roles}", keywords = {"Kaldros Depthbreaker"}, exp = 97 },
        { name = "Gonzor", template = "LFM Gonzor {difficulty} {roles}", keywords = {"Gonzor"}, exp = 98 },
        { name = "King Gnok", template = "LFM King Gnok {difficulty} {roles}", keywords = {"king", "gnok"}, exp = 98 },
        { name = "King Mosh", template = "LFM King Mosh {difficulty} {roles}", keywords = {"king", "mosh"}, exp = 98 },
        { name = "Silithid Lurker", template = "LFM Silithid Lurker {difficulty} {roles}", keywords = {"silithid", "lurker"}, exp = 98 },
        { name = "Volchan", template = "LFM Volchan {difficulty} {roles}", keywords = {"Volchan"}, exp = 98 },
        { name = "Corrupted Ancient", template = "LFM CA {difficulty} {roles}", keywords = {"CA", "Corrupted Ancient"}, exp = 98 },
        { name = "WorldBossTour", template = "LFM World Boss Tour {difficulty} {roles}", keywords = {"worldtour"}, exp = 0 },
        { name = "Sha of Anger", template = "LFM Sha of Anger {difficulty} {roles}", keywords = {"sha", "anger"}, exp = 4 },
        { name = "Galleon", template = "LFM Galleon {difficulty} {roles}", keywords = {"galleon", "salyis"}, exp = 4 },
        { name = "Nalak", template = "LFM Nalak {difficulty} {roles}", keywords = {"nalak"}, exp = 4 },
        { name = "Oondasta", template = "LFM Oondasta {difficulty} {roles}", keywords = {"oondasta"}, exp = 4 },
        { name = "Celestials", template = "LFM Celestials {difficulty} {roles}", keywords = {"celestials", "celestial"}, exp = 4 },
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
    RAIDS = { Tank = 2, Healer = 2, DPS = 5, Support = 0 },
    WORLD_BOSS = { Tank = 1, Healer = 2, DPS = 5, Support = 0 },
}

LFM.LFM_ACTIVITIES = LFM_ACTIVITIES
LFM.DIFFICULTIES = DIFFICULTIES
LFM.CHANNELS = CHANNELS
LFM.RAID_ROLE_REQUIREMENTS = RAID_ROLE_REQUIREMENTS

_G.FrostSeek.LFM = LFM
if FrostSeek.RegisterModule then
    FrostSeek:RegisterModule("lfm", LFM)
end
