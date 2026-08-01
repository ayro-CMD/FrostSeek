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
local FrostSeekUIUtils = _G.FrostSeekUIUtils
local Shared = _G.FrostSeekShared

local LFG = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg", LFG)

local L = FrostSeek.L
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end

local searchExpirationTime = 340
local activeSearches = activeSearches or {}
LFG._activeSearches = activeSearches
local openFrames = openFrames or {}
local ignoreList = ignoreList or {}
local spammerList = spammerList or {}
local ROW_HEIGHT = 26
local MAX_DISPLAY_ROWS = 10
local lastPopupTimes = {}
local lfgSearchText = ""
local lfgSearchDebounce = nil
local mutedPlayers = {}
local popupQueue = {}
local isProcessingQueue = false
local rowPool = {}
local sessionStartTime = GetTime()

local function CloseAllDropdowns()
    if LFG.roleDropdown and LFG.roleDropdown.menu and LFG.roleDropdown.menu:IsShown() then
        LFG.roleDropdown.menu:Hide()
    end
end

local KEYSTONE_KEYWORDS = {
    "keystone",
}

local RAID_KEYWORDS = {
    "onyxia", "ony", "molten core", "mc", "blackwing lair", "bwl",
    "zul'gurub", "zg", "ruins of ahn'qiraj", "aq20", "temple of ahn'qiraj", "aq40",
    "naxxramas", "naxx", "karazhan", "kara", "gruul", "magtheridon", "mag",
    "serpentshrine cavern", "ssc", "tempest keep", "tk", "the eye", "eye",
    "hyjal", "mount hyjal", "black temple", "bt", "zul'aman", "za", "sunwell plateau", "swp",
    "vault of archavon", "voa", "archavon", "obsidian sanctum", "sarth", "sartharion",
    "eye of eternity", "eoe", "malygos", "ulduar", "uld",
    "trial of the crusader", "toc", "crusader", "icecrown citadel", "icc", "ruby sanctum", "rs", "halion",
    "blackwing lair", "molten core", "temple of ahn'qiraj", "ruins of ahn'qiraj",
    "serpentshrine cavern", "tempest keep", "the battle for mount hyjal",
    "sunwell plateau", "vault of archavon", "obsidian sanctum", "eye of eternity",
    "trial of the crusader", "icecrown citadel", "ruby sanctum",
    "naxxramas", "archavon", "sartharion", "malygos", "ulduar", "algolon",
    "anub'arak", "lich king", "sindragosa", "blood queen", "putricide",
    "baradin hold", "bh", "bastion of twilight", "blackwing descent", "bwd", "nefarian",
    "throne of the four winds", "t4w", "al'akir", "firelands", "fl", "ragnaros",
    "dragon soul", "ds", "deathwing",
    "mogu'shan vaults", "msv", "heart of fear", "hof", "shek'zeer",
    "terrace of endless spring", "toes", "throne of thunder", "tot", "lei shen",
    "siege of orgrimmar", "soo", "garrosh",
    --warmane
    "icc10","icc25","icc10n","icc25n","icc10hc","icc25hc","rs25n","rs25hc","rs10n","rs25n",
    -- Ascension/CoA Raid
    "the radiant spring","trs"
}

local WORLD_BOSS_KEYWORDS = {
    "soggoth", "sogoth", "azuregos", "kazzak", "doomwalker", "setis", "settis",
    "emeriss", "lethon", "taerar", "ysondre", "dream", "nightmare", "kaldros depthbreaker", "kaldros.depthbreaker", "kaldros",
    "snowgrave", "atal'zul", "atal.zul", "world tour", "worldboss tour", "world boss tour",
    "sha of anger", "galleon", "salyis", "nalak", "oondasta", "celestials", "celestial",
    "gonzor", "king gnok", "king mosh", "silithid lurker", "volchan", "corrupted ancient",
}

local PVP_KEYWORDS = {
    "2v2", "2s", "3v3", "3s", "5v5", "5s", "arena", "bg", "battleground", "pvp",
    "wsg", "warsong", "ab", "arathi", "av", "alterac", "eots", "wg", "wintergrasp",
}

local MANASTORM_KEYWORDS = {
    "manastorm", "bonzo", "alva", "ms","manastorm goldfarm",
}

local DUNGEON_KEYWORDS = {
    -- Classic Dungeons
    "rfc", "ragefire", "ragefire chasm", "dm", "deadmines", "vc", "wc", "wailing", "wailing caverns",
    "sfk", "shadowfang", "shadowfang keep", "stocks", "stockade", "bfd", "blackfathom", "blackfathom deeps",
    "gnomer", "gnomeregan", "rfk", "razorfen kraul", "sm", "scarlet", "scarlet monastery", "gy", "lib", "arm", "cath",
    "rfd", "razorfen downs", "ulda", "uldaman", "zf", "zul'farrak", "mara", "maraudon","blackcock spire",
    "st", "sunken temple", "brd", "blackrock depths", "dire", "dire maul", "maul", "dme", "dmn", "dmw",
    "strat", "stratholme", "scholo", "scholomance", "lbrs", "lower blackrock spire", "ubrs", "upper blackrock spire",
    -- TBC Dungeons
    "ramps", "hellfire ramparts", "ramparts", "bf", "blood furnace", "sp", "slave pens", "ub", "underbog",
    "mt", "mana-tombs", "mana tombs", "ac", "auchenai crypts", "auchenai", "sh", "sethekk halls", "sethekk",
    "ohf", "old hillsbrad", "old hillsbrad foothills", "bm", "black morass", "the black morass",
    "mecha", "mechanar", "shh", "shattered halls", "the shattered halls", "bota", "botanica",
    "sl", "shadow labyrinth", "shadow lab", "slabs", "sv", "steamvault", "the steamvault",
    "arca", "arcatraz", "mgt", "magisters terrace", "magister's terrace",
    -- WotLK Dungeons
    "uk", "utgarde keep", "up", "utgarde pinnacle", "pinnacle", "kcm",
    "nexus", "the nexus", "nex", "oculus", "the oculus", "ocu",
    "ak", "ahn'kahet", "azjol", "azjol-nerub", "dtk", "drak'tharon", "drak'tharon keep",
    "vh", "violet hold", "gun", "gundrak",
    "hos", "halls of stone", "hol", "halls of lightning",
    "cos", "culling", "culling of stratholme",
    "toc_d", "champion", "trial of the champion",
    "fos", "forge of souls", "forge", "pos", "pit of saron", "pit",
    "hor", "halls of reflection", "reflection",
    -- Cata Dungeons
    "brc", "blackrock caverns", "blackrock cavern", "tott", "throne of the tides", "naz'jar",
    "vp", "vortex pinnacle", "the vortex pinnacle", "sc", "stonecore",
    "lct", "lost city", "tol'vir", "lost city of tol'vir",
    "hoo", "halls of origination", "origination", "gb", "grim batol",
    "zg_cata", "zul'gurub", "za_cata", "zul'aman",
    "et", "end time", "woe", "well of eternity", "hot", "hour of twilight",
    -- Ascension/CoA Dungeons
    "gmm", "glittermurk", "karazhan crypt", "glittermurk mines",
    "kc", "vault", "vaults", "vault of the inquisition", "vaults of inquisition",
    "roads", "road to de", "de' other side","temple of embers","toe","sbd",
    "tor'watha", "tor watha","voult of the inquisition","voult","shadowbone depths", "the temple of embers", "shadowbone",
    -- MoP Dungeons
    "tjs", "jade serpent", "temple of the jade serpent",
    "sb", "stormstout", "stormstout brewery", "brewery",
    "spm", "shado-pan", "shado-pan monastery",
    "msp", "mogu'shan palace", "mogushan palace",
    "scarlet halls", "siege of niuzao temple", "niuzao",
    "gss", "gate of the setting sun", "setting sun",
    -- General dungeon indicators
    "dg", "aura", "mythic", "mythic+", "keystone",
    "rdf", "lfd", "random dungeon", "random heroic", "rhc", "heroic random",
    "daily heroic", "daily dungeon", "graveyard",
    -- retail porting  Dungeons
    "algeth academy", "aa", "ruby life pools", "rlp", "nokhud offensive", "no",
    "azure vault", "brackenhide hollow", "uldaman cata",
    "neltharus", "nelth", "freehold", "fh", "tol dagor", "td",
    "waycrest manor", "wm", "kings rest", "kr",
    "de other side", "dos", "mists of tirna scithe", "mots",
    "sanguine depths", "sd", "theater of pain", "top", "plaguefall", "pf",
    "spires of ascension", "soa", "spires",
    "necrotic wake", "nw", "necrotic",
    "tazavesh", "taz", "lower karazhan", "lkara", "upper karazhan", "ukara"
}

local ACTIVITY_FILTER_GROUPS = {
    { header = "CLASSIC DUNGEONS", isHeader = true },
    { id = "RFC", name = "Ragefire Chasm", keywords = {"RFC", "RAGEFIRE", "RAGEFIRE CHASM"} },
    { id = "DM", name = "Deadmines", keywords = {"DM", "DEADMINES", "VC"} },
    { id = "WC", name = "Wailing Caverns", keywords = {"WC", "WAILING", "WAILING CAVERNS"} },
    { id = "SFK", name = "Shadowfang Keep", keywords = {"SFK", "SHADOWFANG"} },
    { id = "STOCKS", name = "The Stockade", keywords = {"STOCKS", "STOCKADE"} },
    { id = "BFD", name = "Blackfathom Deeps", keywords = {"BFD", "BLACKFATHOM", "BLACKFATHOM DEEPS"} },
    { id = "GNOMER", name = "Gnomeregan", keywords = {"GNOMER", "GNOMEREGAN"} },
    { id = "RFK", name = "Razorfen Kraul", keywords = {"RFK", "RAZORFEN KRAUL"} },
    { id = "SM", name = "Scarlet Monastery", keywords = {"SM", "SCARLET", "GY", "LIB", "ARM", "CATH", "SCARLET MONASTERY", "GRAVEYARD"} },
    { id = "RFD", name = "Razorfen Downs", keywords = {"RFD", "RAZORFEN"} },
    { id = "ULDA", name = "Uldaman", keywords = {"ULDA", "ULDAMAN"} },
    { id = "ZF", name = "Zul'Farrak", keywords = {"ZF"} },
    { id = "MARA", name = "Maraudon", keywords = {"MARA", "MARAUDON"} },
    { id = "ST", name = "Sunken Temple", keywords = {"ST", "SUNKEN TEMPLE"} },
    { id = "BRD", name = "Blackrock Depths", keywords = {"BRD", "BLACKROCK DEPTHS"} },
    { id = "DME", name = "Dire Maul East", keywords = {"DME"} },
    { id = "DMN", name = "Dire Maul North", keywords = {"DMN"} },
    { id = "DMW", name = "Dire Maul West", keywords = {"DMW"} },
    { id = "STRAT", name = "Stratholme", keywords = {"STRAT", "STRATHOLME"} },
    { id = "SCHOLO", name = "Scholomance", keywords = {"SCHOLO", "SCHOLOMANCE"} },
    { id = "LBRS", name = "Lower Blackrock Spire", keywords = {"LBRS"} },
    { id = "UBRS", name = "Upper Blackrock Spire", keywords = {"UBRS"} },

    { header = "CLASSIC RAIDS", isHeader = true },
    { id = "ONYXIA", name = "Onyxia", keywords = {"ONYXIA", "ONY"} },
    { id = "MC", name = "Molten Core", keywords = {"MC", "MOLTEN CORE"} },
    { id = "BWL", name = "Blackwing Lair", keywords = {"BWL", "BLACKWING LAIR", "BLACKWING"} },
    { id = "ZG", name = "Zul'Gurub", keywords = {"ZG", "ZUL'GURUB"} },
    { id = "AQ20", name = "Ruins of Ahn'Qiraj", keywords = {"AQ20", "RUINS", "RUINS OF AHN'QIRAJ"} },
    { id = "AQ40", name = "Temple of Ahn'Qiraj", keywords = {"AQ40", "TEMPLE", "TEMPLE OF AHN'QIRAJ"} },

    { header = "TBC DUNGEONS", isHeader = true },
    { id = "RAMPS", name = "Hellfire Ramparts", keywords = {"RAMPS", "RAMPARTS", "HELLFIRE RAMPARTS"} },
    { id = "BF", name = "Blood Furnace", keywords = {"BF", "BLOOD FURNACE"} },
    { id = "SP", name = "Slave Pens", keywords = {"SP", "SLAVE PENS"} },
    { id = "UB", name = "Underbog", keywords = {"UB", "UNDERBOG"} },
    { id = "MT", name = "Mana-Tombs", keywords = {"MT", "MANA-TOMBS", "MANA TOMBS"} },
    { id = "AC", name = "Auchenai Crypts", keywords = {"AC", "AUCHENAI", "AUCHENAI CRYPTS", "AUCHENAI-CRYPTS"} },
    { id = "SH", name = "Sethekk Halls", keywords = {"SH", "SETHEKK", "SETHEKK HALLS", "SETHEKK-HALLS"} },
    { id = "SL", name = "Shadow Labyrinth", keywords = {"SL", "SLABS", "SHADOW LAB", "SHADOW LABYRINTH", "SHADOW-LABYRINTH"} },
    { id = "OHF", name = "Old Hillsbrad", keywords = {"OHF", "OLD HILLSBRAD"} },
    { id = "BM", name = "The Black Morass", keywords = {"BM"} },
    { id = "MECHA", name = "Mechanar", keywords = {"MECHA", "MECHANAR"} },
    { id = "BOTA", name = "Botanica", keywords = {"BOTA", "BOTANICA"} },
    { id = "ARCA", name = "Arcatraz", keywords = {"ARCA", "ARCATRAZ"} },
    { id = "MGT", name = "Magister's Terrace", keywords = {"MGT", "MAGISTERS"} },
    { id = "SHH", name = "The Shattered Halls", keywords = {"SHH", "SHATTERED HALLS"} },
    { id = "SV", name = "The Steamvault", keywords = {"SV", "STEAMVAULT"} },

    { header = "TBC RAIDS", isHeader = true },
    { id = "KARA", name = "Karazhan", keywords = {"KARA", "KARAZHAN"} },
    { id = "GRUUL", name = "Gruul's Lair", keywords = {"GRUUL"} },
    { id = "MAG", name = "Magtheridon", keywords = {"MAG", "MAGTHERIDON"} },
    { id = "SSC", name = "Serpentshrine Cavern", keywords = {"SSC", "SERPENTSHRINE", "SERPENTSHRINE CAVERN"} },
    { id = "TK", name = "Tempest Keep", keywords = {"TK", "TEMPEST", "TEMPEST KEEP"} },
    { id = "HYJAL", name = "Mount Hyjal", keywords = {"HYJAL", "MOUNT HYJAL", "THE BATTLE FOR MOUNT HYJAL"} },
    { id = "BT", name = "Black Temple", keywords = {"BT", "BLACK TEMPLE"} },
    { id = "ZA", name = "Zul'Aman", keywords = {"ZA", "ZUL'AMAN"} },
    { id = "SWP", name = "Sunwell Plateau", keywords = {"SWP", "SUNWELL", "SUNWELL PLATEAU"} },

    { header = "WOTLK DUNGEONS", isHeader = true },
    { id = "UK", name = "Utgarde Keep", keywords = {"UK", "UTGARDE KEEP"} },
    { id = "UP", name = "Utgarde Pinnacle", keywords = {"UP", "PINNACLE", "UTGARDE PINNACLE"} },
    { id = "NEXUS", name = "The Nexus", keywords = {"NEXUS", "NEX", "THE NEXUS"} },
    { id = "OCULUS", name = "The Oculus", keywords = {"OCULUS", "OCU", "THE OCULUS"} },
    { id = "AN", name = "Azjol-Nerub", keywords = {"AN", "AZJOL"} },
    { id = "AK", name = "Ahn'kahet", keywords = {"AK", "AHN'KAHET"} },
    { id = "DTK", name = "Drak'Tharon Keep", keywords = {"DTK", "DRAK'THARON"} },
    { id = "VH", name = "Violet Hold", keywords = {"VH", "VIOLET"} },
    { id = "GUN", name = "Gundrak", keywords = {"GUN", "GUNDRAK"} },
    { id = "HOS", name = "Halls of Stone", keywords = {"HOS", "HALLS STONE"} },
    { id = "HOL", name = "Halls of Lightning", keywords = {"HOL", "HALLS LIGHTNING"} },
    { id = "COS", name = "Culling of Stratholme", keywords = {"COS", "CULLING"} },
    { id = "TOC_D", name = "Trial of the Champion", keywords = {"CHAMPION"} },
    { id = "FOS", name = "Forge of Souls", keywords = {"FOS", "FORGE"} },
    { id = "POS", name = "Pit of Saron", keywords = {"POS", "PIT"} },
    { id = "HOR", name = "Halls of Reflection", keywords = {"HOR", "REFLECTION"} },

    { header = "WOTLK RAIDS", isHeader = true },
    { id = "VOA", name = "Vault of Archavon", keywords = {"VOA", "ARCHAVON", "VAULT OF ARCHAVON"} },
    { id = "OS", name = "Obsidian Sanctum", keywords = {"OS", "OBSIDIAN", "SARTH", "SARTHARION", "OBSIDIAN SANCTUM"} },
    { id = "EOE", name = "Eye of Eternity", keywords = {"EOE", "MALYGOS", "EYE", "EYE OF ETERNITY", "THE EYE"} },
    { id = "ULD", name = "Ulduar", keywords = {"ULD", "ULDUAR", "ALGOLON"} },
    { id = "TOC", name = "Trial of the Crusader", keywords = {"TOC", "CRUSADER", "TRIAL OF THE CRUSADER"} },
    { id = "ICC", name = "Icecrown Citadel", keywords = {"ICC", "ICECROWN", "ICECROWN CITADEL", "LICH KING", "SINDRAGOSA", "BLOOD QUEEN", "PUTRICIDE", "ANUB'ARAK"} },
    { id = "RS", name = "Ruby Sanctum", keywords = {"RS", "RUBY", "HALION", "RUBY SANCTUM"} },

    { header = "CATA DUNGEONS", isHeader = true },
    { id = "BRC_C", name = "Blackrock Caverns", keywords = {"BRC", "BLACKROCK CAVERNS"} },
    { id = "TOTT", name = "Throne of the Tides", keywords = {"TOTT", "THRONE TIDES", "NAZ'JAR"} },
    { id = "VP", name = "The Vortex Pinnacle", keywords = {"VP", "VORTEX PINNACLE"} },
    { id = "SC", name = "Stonecore", keywords = {"SC", "STONECORE"} },
    { id = "LCT", name = "Lost City of the Tol'vir", keywords = {"LCT", "TOL'VIR", "LOST CITY"} },
    { id = "HOO", name = "Halls of Origination", keywords = {"HOO", "ORIGINATION"} },
    { id = "GB", name = "Grim Batol", keywords = {"GB", "GRIM BATOL"} },
    { id = "ZG_C", name = "Zul'Gurub (Cata)", keywords = {"ZG", "ZUL'GURUB"} },
    { id = "ZA_C", name = "Zul'Aman (Cata)", keywords = {"ZA", "ZULAMAN"} },
    { id = "ET", name = "End Time", keywords = {"ET", "END TIME"} },
    { id = "WOE", name = "Well of Eternity", keywords = {"WOE", "WELL ETERNITY"} },
    { id = "HOT", name = "Hour of Twilight", keywords = {"HOT", "HOUR TWILIGHT"} },

    { header = "CATA RAIDS", isHeader = true },
    { id = "BH", name = "Baradin Hold", keywords = {"BH", "BARADIN"} },
    { id = "BOT", name = "Bastion of Twilight", keywords = {"BOT", "BASTION", "TWILIGHT"} },
    { id = "T4W", name = "Throne of the Four Winds", keywords = {"T4W", "FOUR WINDS", "AL'AKIR"} },
    { id = "BWD", name = "Blackwing Descent", keywords = {"BWD", "BLACKWING DESCENT", "NEFARIAN"} },
    { id = "FL", name = "Firelands", keywords = {"FL", "FIRELANDS", "RAGNAROS"} },
    { id = "DS", name = "Dragon Soul", keywords = {"DS", "DRAGON SOUL", "DEATHWING"} },

    { header = "MoP DUNGEONS", isHeader = true },
    { id = "TJS", name = "Temple of the Jade Serpent", keywords = {"TJS", "JADE SERPENT"} },
    { id = "SB", name = "Stormstout Brewery", keywords = {"SB", "STORMSTOUT", "BREWERY"} },
    { id = "SPM", name = "Shado-Pan Monastery", keywords = {"SPM", "SHADO-PAN"} },
    { id = "MSP", name = "Mogu'shan Palace", keywords = {"MSP", "MOGUSHAN PALACE"} },
    { id = "SH_M", name = "Scarlet Halls", keywords = {"SCARLET HALLS"} },
    { id = "SM_M", name = "Scarlet Monastery (MoP)", keywords = {"SM", "SCARLET MONASTERY"} },
    { id = "SNT", name = "Siege of Niuzao Temple", keywords = {"NIUZAO", "SIEGE"} },
    { id = "GSS", name = "Gate of the Setting Sun", keywords = {"GSS", "SETTING SUN"} },
    { id = "SCHOLO_M", name = "Scholomance (MoP)", keywords = {"SCHOLO", "SCHOLOMANCE"} },

    { header = "MoP RAIDS", isHeader = true },
    { id = "MSV", name = "Mogu'shan Vaults", keywords = {"MSV", "MOGUSHAN VAULTS"} },
    { id = "HOF", name = "Heart of Fear", keywords = {"HOF", "HEART OF FEAR", "SHEK'ZEER"} },
    { id = "TOES", name = "Terrace of Endless Spring", keywords = {"TOES", "TERRACE", "ENDLESS SPRING"} },
    { id = "TOT", name = "Throne of Thunder", keywords = {"TOT", "THUNDER", "LEI SHEN"} },
    { id = "SOO", name = "Siege of Orgrimmar", keywords = {"SOO", "SIEGE", "ORGRIMMAR", "GARROSH"} },

    { header = "ASCENSION DUNGEONS", isHeader = true },
    { id = "BRC", name = "Blackrock Cavern", keywords = {"BRC", "BLACKROCK CAVERN"} },
    { id = "KC", name = "Karazhan Crypt", keywords = {"KC", "KARAZHAN CRYPT"} },
    { id = "VAULT", name = "Vault of the Inquisition", keywords = {"VAULT", "INQUISITION"} },
    { id = "ROADS", name = "Road to De' Other Side", keywords = {"ROADS", "ROAD TO DE' OTHER SIDE"} },
    { id = "GMM", name = "GlitteMurk Mines", keywords = {"GLITTERMURK", "GLITTEMURK", "GLITTERMURK MINES", "GLITTEMURK MINES"} },
    { id = "BH", name = "Baradin Hold", keywords = {"BARADIN", "BARADIN HOLD"} },
    { id = "TW", name = "Tor'Watha", keywords = {"TOR'WATHA"} },
    { id = "EOE", name = "Temple of Embers", keywords = {"THE TEMPLE OF EMBERS"} },
    { id = "SD", name = "Shadowbone Depths", keywords = {"SHADOWBONE DEPTHS"} },

    { header = "ASCENSION RAID", isHeader = true },
    { id = "TRS", name = "The Radiant Spring", keywords = {"TRS", "radiant", "spring"} },
    

    { header = "WORLD BOSSES", isHeader = true },
    { id = "AZUREGOS", name = "Azuregos", keywords = {"AZUREGOS", "AZURE"} },
    { id = "KAZZAK", name = "Lord Kazzak", keywords = {"KAZZAK"} },
    { id = "DOOMWALKER", name = "Doomwalker", keywords = {"DOOMWALKER"} },
    { id = "EMERISS", name = "Emeriss", keywords = {"EMERISS"} },
    { id = "LETHON", name = "Lethon", keywords = {"LETHON"} },
    { id = "TAERAR", name = "Taerar", keywords = {"TAERAR"} },
    { id = "YSONDRE", name = "Ysondre", keywords = {"YSONDRE"} },
    { id = "SOGGOTH", name = "Soggoth", keywords = {"SOGGOTH", "SOGOTH"} },
    { id = "SETIS", name = "Setis", keywords = {"SETIS", "SETTIS"} },
    { id = "SNOWGRAVE", name = "Snowgrave", keywords = {"SNOWGRAVE"} },
    { id = "ATALZUL", name = "Atal'Zul", keywords = {"ATAL'ZUL", "ATAL.ZUL"} },
    { id = "KALDROS", name = "Kaldros Depthbreaker", keywords = {"KALDROS", "KALDROS DEPTHBREAKER", "KALDROS.DEPTHBREAKER"} },
    { id = "WBT", name = "World Boss Tour", keywords = {"WORLD TOUR", "WORLDBOSS TOUR", "WORLD BOSS TOUR"} },
    { id = "DREAM", name = "Emerald Dream", keywords = {"EMERALD DREAM"} },
    { id ="GONZOR", name = "Gonzor", keywords = {"Gonzor"} },
    { id = "K.GNOK", name = "King Gnok", keywords = {"KING GNOK", "GNOK"} },
    { id = "K.MOSH", name = "King Mosh", keywords = {"KING MOSH", "MOSH"} },
    { id = "SILITHID LURKER", name = "Silithid Lurker", keywords = {"SILITHID LURKER", "SILITHID"} },
    { id ="VOLCHAN",name = "Volchan", keywords = {"Volchan"} },
    { id = "CORRUPTED ANCIENT", name = "Corrupted Ancient", keywords = {"CORRUPTED ANCIENT", "CORRUPTED"} },

    { header = "MoP WORLD BOSSES", isHeader = true },
    { id = "SHA", name = "Sha of Anger", keywords = {"SHA", "ANGER", "SHA OF ANGER"} },
    { id = "GALLEON", name = "Galleon", keywords = {"GALLEON", "SALYIS"} },
    { id = "NALAK", name = "Nalak", keywords = {"NALAK"} },
    { id = "OONDASTA", name = "Oondasta", keywords = {"OONDASTA"} },
    { id = "CELESTIALS", name = "Celestials", keywords = {"CELESTIALS", "CELESTIAL"} },

    { header = "PVP", isHeader = true },
    { id = "ARENA", name = "Arena (2v2/3v3/5v5)", keywords = {"PVP"} },
    { id = "BG", name = "Battlegrounds", keywords = {} },
    { id = "WG", name = "Wintergrasp", keywords = {} },

    { header = "MANASTORM", isHeader = true },
    { id = "MS", name = "Manastorm (General)", keywords = {"MANASTORM", "MS"} },
    { id = "MS_ALVA", name = "Manastorm Alva", keywords = {} },
    { id = "MS_GOLD", name = "Manastorm Gold Farm", keywords = {} },
    { id = "MS_BONZO", name = "Manastorm Bonzo", keywords = {} },

    { header = "KEYSTONE", isHeader = true },
    { id = "KEYSTONE", name = "Keystone Runs", keywords = {"KEYSTONE"} },

}

local ACTIVITY_DUNGEON_LOOKUP = {}
for _, entry in ipairs(ACTIVITY_FILTER_GROUPS) do
    if not entry.isHeader and entry.keywords then
        for _, kw in ipairs(entry.keywords) do
            ACTIVITY_DUNGEON_LOOKUP[kw] = entry.id
        end
    end
end

LFG.ACTIVITY_FILTER_GROUPS = ACTIVITY_FILTER_GROUPS
LFG.ACTIVITY_DUNGEON_LOOKUP = ACTIVITY_DUNGEON_LOOKUP

function LFG.PassesActivityFilter(category, dungeon)
    if not FrostSeekDB.LFG.activityFilter then return true end
    if category == "PVP" then
        return FrostSeekDB.LFG.activityFilter["ARENA"] ~= false
    end
    if category == "MANASTORM" then
        return FrostSeekDB.LFG.activityFilter["MS"] ~= false
    end
    if category == "KEYSTONE" then
        return FrostSeekDB.LFG.activityFilter["KEYSTONE"] ~= false
    end
    local filterId = ACTIVITY_DUNGEON_LOOKUP[dungeon]
    if filterId then
        return FrostSeekDB.LFG.activityFilter[filterId] ~= false
    end
    return true
end

local SPAM_WORDS = {
    "pocket", "sadgirl","issue","when","enchanter","israel","nazi","mejor","feminista","braincells","breastfeed","bbw","comunista","cocaine","why",
    "drugs","fascista","fascist","vox","mundial","spain","anyone","know","you","staff","ticket","golf","player","players","worldforged","certain",
    "guild", "community", "recruit", "recruiting", "recru", "roster", "lf members", "lf guild","what","is","this","high","do",
    "guild lf", "new guild", "gm is", "leader is", "our guild", "us on","america","ginvite","el retard","?",
    "application", "roster spot", "core group", "core team","layers","deutsche","gilde","complicate",
    "hardcore guild", "casual guild", "semi-hardcore", "mythic raiding", "raid team", "static group",
    "looking for members", "looking for guild", "looking for a guild", "guild is looking","call","ppl",
    "active members", "mature players", "friendly guild", "pve guild", "pvp guild", "leveling guild",
    "social guild", "g looking", "is looking for", "guild event", "community night","help","boost",
    "wts", "wtb", "sell", "selling", "buy", "gdkp", "carry service","anybody","lockboxes",
    "boosting service", "pilot", "piloted", "price", "cheap", "offer","addon","frame","warhalla","<Warhalla>",
    "service", "cache", "nuked", "ksh", "keystone master","florida","grass","plf","guilde",
    "mdi", "server first", "top guild", "best guild","gf","which","every","recrute",
    "world first", "qualif","girl","small","boy","goth","gnome","testing","dont",
    "awakening", "twisting","why","crafter","whick","professions","profession",
    "transfer", "transfers", "realm transfer", "server transfer", "move to", "come join",
    "invite link", "discord link", "discord server","WTB","days","sandles","damnit",
    "website", "hipe", "raider.io", "rio", "wowprogress", "wcl", "warcraftlogs",
    "check our", "check my", "for info", "apply in", "apply on", "apply at",
    "register", "enroll","day","days","hour","hours","no","alone","them","woodworker",
    "stream", "streamer", "content creator", "clip", "recording", "obs", "studio",
    "tiktok", "instagram", "twitter", "facebook", "reddit", "patreon", "paypal",
    "donate", "donation", "support me", "follow", "subscribe", "giveaway",
    "raffle", "contest", "prize", "merch", "store", "shop", "buy now",
    "weakaura", "weakauras", "elvui", "tukui", "plater", "dbm", "bigwigs",
    "https", "discord.gg", "twitch.tv", "youtube", "but", "ahead",
    "account", "heirloom","help","bazaar","token","don't", "shit",
    "wtt","how","do","pets","stress","test","here","xd",
    "farmers","chez","plf","test","pasticcio","nearby","never",
    "tSM", "mRP", "trp", "total rp","?","other",
    "gamble", "bet", "wager", "jackpot", "lottery", "lucky draw", "spin the wheel",
    "selling.*run", "gold.*run","where is","24/7",
    "alchemy", "alch", "blacksmithing", "bs", "enchanting", "ench", "engineering", "eng", "inscription",
    "jewelcrafting", "jc", "leatherworking", "lw", "tailoring", "skinning", "mining",
    "herbalism", "herb", "herbalist", "first aid", "fishing", "archaeology", "arch",
    "prospecting", "milling", "smelting", "lf crafter", "lf craft",
    "looking for crafter", "need crafter", "craft", "crafting for",
    "wts craft", "wtb craft", "crafting service", "lw service", "bs service",
    "enchant service", "jc service", "alch service", "lf enchanter", "lf bs", "lf lw",
    "lf jc", "lf alch", "lf eng", "lf tailor", "lf miner", "lf herbalist",
    "lf skinner", "lf crafter", "crafting lf", "enchanting lf", "smelting lf",
    "cooking", "lf cook", " Cooking ",
    "raid on wednesday", "raid on thursday", "raid on friday", "raid on saturday",
    "raid on sunday", "raid on monday", "raid on tuesday",
}

local SPAM_PHRASES = {
    "lfmg", "LFguild", "lf guild", "lf gm",
    "filling roster",
    "seeking",
    "hit me up", "shoot me", "hmu", "dm me", "poke me", "ping me", "msg me",
    "whisper me for", "pm for", "whisper any",
    "trade chat", "world chat", "global chat",
    "server time", "night at",
    "bell icon", "smash that", "ring the",
}

local function IsSpamMessage(msg)
    local lowerMsg = string.lower(msg)
    local shortSpamHits = 0
    local longSpamHits = 0
    for _, word in ipairs(SPAM_WORDS) do
        local matched
        if string.find(word, " ") then
            matched = string.find(lowerMsg, word, 1, true) ~= nil
        else
            matched = string.find(lowerMsg, "%f[%a]" .. word .. "%f[^%a]") ~= nil
        end
        if matched then
            if string.len(word) < 5 then
                shortSpamHits = shortSpamHits + 1
            else
                longSpamHits = longSpamHits + 1
            end
        end
    end
    for _, phrase in ipairs(SPAM_PHRASES) do
        if string.find(lowerMsg, phrase, 1, true) then
            longSpamHits = longSpamHits + 1
        end
    end
    if longSpamHits >= 1 then
        return true
    end
    local hasStrongLFG =
        string.match(lowerMsg, "lf%d+m") ~= nil or
        string.match(lowerMsg, "lf%d") ~= nil or
        string.find(lowerMsg, "%f[%a]lfm%f[^%a]") ~= nil or
        string.find(lowerMsg, "need%s+tank") ~= nil or
        string.find(lowerMsg, "need%s+heal") ~= nil or
        string.find(lowerMsg, "need%s+dps") ~= nil or
        string.find(lowerMsg, "need%s+support") ~= nil or
        string.find(lowerMsg, "1tank") ~= nil or
        string.find(lowerMsg, "1heal") ~= nil or
        string.find(lowerMsg, "1dps") ~= nil or
        string.find(lowerMsg, "%dtank") ~= nil or
        string.find(lowerMsg, "%dheal") ~= nil or
        string.find(lowerMsg, "%ddps") ~= nil
    if hasStrongLFG then
        return shortSpamHits >= 3
    end
    return shortSpamHits >= 2
end

local function GetCustomKeywords(category)
    if not FrostSeekDB or not FrostSeekDB.LFG or not FrostSeekDB.LFG.customKeywords then
        return {}
    end
    local raw = FrostSeekDB.LFG.customKeywords[category] or ""
    if raw == "" then return {} end
    local keywords = {}
    for kw in string.gmatch(raw, "[^,]+") do
        kw = string.match(kw, "^%s*(.-)%s*$")
        if kw and kw ~= "" then
            table.insert(keywords, string.lower(kw))
        end
    end
    return keywords
end

local CATEGORY_ACCENT = setmetatable({}, {
    __index = function(_, key)
        local tokenMap = {
            DUNGEON = "catDungeon", RAID = "catRaid", WORLD_BOSS = "catWorldBoss",
            PVP = "catPvP", MANASTORM = "catMana", KEYSTONE = "catKeystone",
            ALL = "catAll", MISC = "catMisc"
        }
        local token = tokenMap[key] or "catMisc"
        return _tc(token)
    end
})

local CATEGORY_TAG = {
    DUNGEON = "|cFF00FF00D|r",
    RAID = "|cFFFFAA00R|r",
    WORLD_BOSS = "|cFFFFA500WB|r",
    PVP = "|cFFFF5555P|r",
    MANASTORM = "|cFFAA88FFM|r",
    KEYSTONE = "|cFFFF88FFK|r",
    MISC = "|cFF88CCFF?|r",
}

local function wholeWordFind(text, word)
    if not text or not word then return false end
    return string.find(text, "%f[%a%d]" .. word .. "%f[^%a%d]") ~= nil
end
--shynga
function LFG.IsLFMMessage(msg)
    if not msg then return false end
    local lowerMsg = string.lower(msg)
    if string.match(lowerMsg, "^(wts|wtb|selling|boost|advert)") then return false end
    if string.match(lowerMsg, "selling.*keystone") or string.match(lowerMsg, "wts.*keystone") or
       string.match(lowerMsg, "boost.*service") or string.match(lowerMsg, "gold.*service") then
        return false
    end
    if string.find(msg, "%[Keystone:") then
        return true
    end
    if string.match(lowerMsg, "^need%s+[thd]") or string.match(lowerMsg, "^need%s+tank") or
       string.match(lowerMsg, "^need%s+heal") or string.match(lowerMsg, "^need%s+dps") or
       string.match(lowerMsg, "^need%s+support") or string.match(lowerMsg, "^need%s+supp") or
       string.match(lowerMsg, "^lf%s+[thd]") or string.match(lowerMsg, "^lf%s+tank") or
       string.match(lowerMsg, "^lf%s+heal") or string.match(lowerMsg, "^lf%s+dps") or
       string.match(lowerMsg, "^lf%s+support") or string.match(lowerMsg, "^lf%s+supp") then
        return true
    end
    if string.match(lowerMsg, "ms.*lvl") or string.match(lowerMsg, "ms.*level") or
       string.match(lowerMsg, "ms.*aura") or string.match(lowerMsg, "mana.*lvl") or
       string.match(lowerMsg, "mana.*level") or
       string.match(lowerMsg, "ms.*gold") or string.match(lowerMsg, "lf.*gold") or
       string.match(lowerMsg, "mana.*gold") then
        return true
    end
    if string.match(lowerMsg, "lf[ %p].*[dps][ %p]") or string.match(lowerMsg, "lf[ %p].*[dd][ %p]") or
       string.match(lowerMsg, "lf[ %p].*[dmg][ %p]") or
       string.match(lowerMsg, "need[ %p].*[dps]") or
       string.match(lowerMsg, "need[ %p].*[dd]") or
       string.match(lowerMsg, "need[ %p].*[tank]") or
       string.match(lowerMsg, "need[ %p].*[heal]") or
       string.match(lowerMsg, "need[ %p].*[support]") or
       string.match(lowerMsg, "need[ %p].*[supp]") or
       string.match(lowerMsg, "lf[ %p].*tank") or
       string.match(lowerMsg, "lf[ %p].*heal") or
       string.match(lowerMsg, "lf[ %p].*support") or
       string.match(lowerMsg, "lf[ %p].*supp") then
        return true
    end
    if string.find(lowerMsg, "lfm") or string.find(lowerMsg, "lfg") then return true end
    if string.match(lowerMsg, "lf%d+m") then return true end
    if string.match(lowerMsg, "lf%d") then return true end
    if string.find(lowerMsg, " lf ") or string.find(lowerMsg, "^lf ") then return true end
    if string.match(lowerMsg, "last%s*spot") or string.match(lowerMsg, "need%s+%d") then return true end
    if string.match(lowerMsg, "inv") and (string.find(lowerMsg, "whisper") or string.find(lowerMsg, "wisp") or string.find(lowerMsg, "pm")) then return true end
    if string.match(lowerMsg, "g2g") then return true end
    if string.match(lowerMsg, "^%d+/%d+%s") or string.match(lowerMsg, "%s%d+/%d+%s") or string.match(lowerMsg, "%s%d+/%d+$") then return true end
    if string.match(lowerMsg, "tank/heal") or string.match(lowerMsg, "heal/tank") or string.match(lowerMsg, "tank%/heal") then return true end
    if string.match(lowerMsg, "^%d+%s+[thd][%s%p]?") or string.match(lowerMsg, "^%d+%s+tank") or string.match(lowerMsg, "^%d+%s+heal") or string.match(lowerMsg, "^%d+%s+dps") or string.match(lowerMsg, "^%d+%s+support") or string.match(lowerMsg, "^%d+%s+supp") then return true end
    if string.match(lowerMsg, "lf.*dg") or string.match(lowerMsg, "lf.*rdf") or string.match(lowerMsg, "need.*dg") then return true end
    return false
end

function LFG.GetMessageMode(msg)
    if not msg then return nil end
    local lowerMsg = string.lower(msg)

    local function startsWithIndividualRole()
        if string.match(lowerMsg, "^dps%s+lf") or string.match(lowerMsg, "^tank%s+lf") or
           string.match(lowerMsg, "^heal[a-z]*%s+lf") or
           string.match(lowerMsg, "^support%s+lf") or string.match(lowerMsg, "^supp%s+lf") then
            return true
        end
        if string.match(lowerMsg, "^%d+%s*i[lv]l%s+%a+%s+lf") or
           string.match(lowerMsg, "^%d+%s*lvl%s+%a+%s+lf") or
           string.match(lowerMsg, "^%d+%s*i[%a]+l%s+%a+%s+lf") then
            return true
        end
        if string.match(lowerMsg, "^%d+%s*i[lv]l%s+lf") or
           string.match(lowerMsg, "^%d+%s*lvl%s+lf") then
            return true
        end
        if string.match(lowerMsg, "^%a+%s+%d+%s*i[lv]l%s+lf") or
           string.match(lowerMsg, "^%a+%s+%d+%s*lvl%s+lf") then
            return true
        end
        return false
    end

    if string.find(lowerMsg, "%f[%a]lfg%f[^%a]") then return "LFG" end
    if string.match(lowerMsg, "^lfg") or string.match(lowerMsg, "%slfg") then return "LFG" end
    if string.match(lowerMsg, "looking%s+for%s+group") then return "LFG" end
    if string.find(lowerMsg, "%f[%a]lfm%f[^%a]") then return "LFM" end
    if string.match(lowerMsg, "lf%d+m") then return "LFM" end
    if string.match(lowerMsg, "^lfm") or string.match(lowerMsg, "%slfm") then return "LFM" end
    if string.match(lowerMsg, "looking%s+for%s+more") or string.match(lowerMsg, "looking%s+for%s+members") then return "LFM" end
    if string.match(lowerMsg, "^lf%s+team%s") or string.match(lowerMsg, "%slf%s+team%s") or
       string.match(lowerMsg, "^lf%s+team$") or string.match(lowerMsg, "%slf%s+team$") then return "LFM" end
    if startsWithIndividualRole() then return "LFG" end
    if string.match(lowerMsg, "lf[ %p]+%a*%s*group") or string.match(lowerMsg, "lf[ %p]+group") then return "LFG" end
    if string.match(lowerMsg, "%s%d+/%d+%s") or string.match(lowerMsg, "^%d+/%d+%s") or string.match(lowerMsg, "%s%d+/%d+$") then return "LFM" end
    if string.match(lowerMsg, "last%s*spot") then
        return "LFM"
    end

    if string.match(lowerMsg, "tank/heal") or string.match(lowerMsg, "heal/tank") or string.match(lowerMsg, "tank%%/heal") then return "LFM" end
    if string.match(lowerMsg, "inv") and (string.find(lowerMsg, "whisper") or string.find(lowerMsg, "wisp") or string.find(lowerMsg, "pm")) then return "LFM" end
    if string.match(lowerMsg, "%f[%a]g2g%f[^%a]") then return "LFM" end
    if string.match(lowerMsg, "need%s+%d*%s*tank") or
       string.match(lowerMsg, "need%s+%d*%s*heal") or
       string.match(lowerMsg, "need%s+%d*%s*dps") or
       string.match(lowerMsg, "need%s+%d*%s*support") or
       string.match(lowerMsg, "need%s+%d*%s*supp") then return "LFM" end
    if string.match(lowerMsg, "lf[ %p].*%stank") or string.match(lowerMsg, "lf[ %p].*%sheal") or
       string.match(lowerMsg, "lf[ %p].*%sdps") or string.match(lowerMsg, "lf[ %p].*%ssupport") or
       string.match(lowerMsg, "lf[ %p].*%ssupp") then return "LFM" end
    if string.match(lowerMsg, "^%d+%s+tank") or string.match(lowerMsg, "^%d+%s+heal") or
       string.match(lowerMsg, "^%d+%s+dps") or string.match(lowerMsg, "^%d+%s+support") or
       string.match(lowerMsg, "^%d+%s+supp") then return "LFM" end
    if string.match(lowerMsg, "lf%s+dg") or string.match(lowerMsg, "lf%s+rdf") then return "LFG" end
    if string.match(lowerMsg, "inv%s+me") or string.match(lowerMsg, "^inv%s*$") then return "LFG" end

    return "LFG"
end

function LFG.ClassifyMessage(msg)
    if not msg then
        return "MISC", "MISC", false, false, false, false, false
    end
    local lowerMsg = string.lower(msg)
    if string.find(msg, "%[Keystone:") then
        local dungeonName = string.match(msg, "%[Keystone: ([^%]]+)")
        if dungeonName then
            dungeonName = string.lower(dungeonName)
            for _, d in ipairs(DUNGEON_KEYWORDS) do
                if string.find(dungeonName, d) then
                    return "KEYSTONE", string.upper(d), false, false, false, true, false
                end
            end
            return "KEYSTONE", "KEYSTONE", false, false, false, true, false
        end
    end
    for _, kw in ipairs(WORLD_BOSS_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "WORLD_BOSS", string.upper(kw), false, false, false, false, false
        end
    end
    for _, kw in ipairs(KEYSTONE_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            if wholeWordFind(lowerMsg, "strath") then
                return "KEYSTONE", "STRAT", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "dire maul") or wholeWordFind(lowerMsg, "dme") or wholeWordFind(lowerMsg, "dmn") or wholeWordFind(lowerMsg, "dmw") then
                return "KEYSTONE", "DM", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "brd") or wholeWordFind(lowerMsg, "blackrock depths") then
                return "KEYSTONE", "BRD", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "scholo") then
                return "KEYSTONE", "SCHOLO", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "lbrs") then
                return "KEYSTONE", "LBRS", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "ubrs") then
                return "KEYSTONE", "UBRS", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "mc") or wholeWordFind(lowerMsg, "molten core") then
                return "KEYSTONE", "MC", false, false, false, true, false
            else
                return "KEYSTONE", "KEYSTONE", false, false, false, true, false
            end
        end
    end
    for _, kw in ipairs(RAID_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "RAID", string.upper(kw), false, false, true, false, false
        end
    end
    for _, kw in ipairs(PVP_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "PVP", "PVP", false, false, false, false, true
        end
    end
    for _, kw in ipairs(MANASTORM_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            return "MANASTORM", "MANASTORM", false, false, false, false, false
        end
    end

    local function DetectMythicDungeon(msg)
        if not msg then return false end
        if wholeWordFind(msg, "mythic") then return true end
        if wholeWordFind(msg, "m+") then return true end
        if string.match(msg, "%sm(%d+)") then return true end     
        if string.match(msg, "^m(%d+)") then return true end   
        if string.match(msg, "%[m%d*%]") then return true end    
        if string.match(msg, "%[mythic%]") then return true end 
        return false
    end

    local RDF_INDICATORS = {"rdf", "lfd", "random dungeon", "random heroic", "rhc", "heroic random", "daily heroic", "daily dungeon"}
    for _, rdfKw in ipairs(RDF_INDICATORS) do
        if wholeWordFind(lowerMsg, rdfKw) then
            local isHeroic = wholeWordFind(lowerMsg, "hc") or
                             wholeWordFind(lowerMsg, "heroic") or
                             wholeWordFind(lowerMsg, "rhc")
            local isMythic = DetectMythicDungeon(lowerMsg)
            for _, d in ipairs(DUNGEON_KEYWORDS) do
                if wholeWordFind(lowerMsg, d) then
                    return "DUNGEON", string.upper(d), isHeroic, isMythic, false, false, false
                end
            end
            return "DUNGEON", "RDF", isHeroic, isMythic, false, false, false
        end
    end

    if wholeWordFind(lowerMsg, "dg") then
        local isHeroic = wholeWordFind(lowerMsg, "hc") or
                         wholeWordFind(lowerMsg, "heroic") or
                         string.match(lowerMsg, " h[%s%p]") or
                         string.match(lowerMsg, " h$")
        local isMythic = DetectMythicDungeon(lowerMsg)
        for _, d in ipairs(DUNGEON_KEYWORDS) do
            if wholeWordFind(lowerMsg, d) then
                return "DUNGEON", string.upper(d), isHeroic, isMythic, false, false, false
            end
        end
        return "DUNGEON", "RDF", isHeroic, isMythic, false, false, false
    end
    for _, d in ipairs(DUNGEON_KEYWORDS) do
        if wholeWordFind(lowerMsg, d) then
            local isHeroic = wholeWordFind(lowerMsg, "hc") or
                             wholeWordFind(lowerMsg, "heroic") or
                             string.match(lowerMsg, " h[%s%p]") or
                             string.match(lowerMsg, " h$")
            local isMythic = DetectMythicDungeon(lowerMsg)
            return "DUNGEON", string.upper(d), isHeroic, isMythic, false, false, false
        end
    end
    local customCategoryMap = {
        DUNGEON = { category = "DUNGEON", isDungeon = true },
        RAID = { category = "RAID", isRaid = true },
        WORLD_BOSS = { category = "WORLD_BOSS", isWorldBoss = true },
        PVP = { category = "PVP", isPvp = true },
        MANASTORM = { category = "MANASTORM", isManastorm = true },
        KEYSTONE = { category = "KEYSTONE", isKeystone = true },
    }
    for catKey, catInfo in pairs(customCategoryMap) do
        local customKws = GetCustomKeywords(catKey)
        for _, kw in ipairs(customKws) do
            if wholeWordFind(lowerMsg, kw) or string.find(lowerMsg, kw, 1, true) then
                return catInfo.category, string.upper(kw), false, false,
                       catInfo.isRaid or false, catInfo.isKeystone or false,
                       catInfo.isPvp or false
            end
        end
    end
    
    return "MISC", "MISC", false, false, false, false, false
end

function LFG.GetLegendaryEnchant()
    if not MysticEnchantUtil then
        return ""
    end
    local legendaryEnchantName = ""
    local enchantData = MysticEnchantUtil.GetAppliedEnchantCountByQuality("player")
    if enchantData then
        enchantData = enchantData[5]
    end
    if enchantData then
        for spellID, _ in pairs(enchantData) do
            legendaryEnchantName = GetSpellInfo(spellID)
            if legendaryEnchantName then
                return string.format("|cff71d5ff|Hspell:%d|h[%s]|h|r", spellID, legendaryEnchantName)
            end
        end
    end
    return ""
end

function LFG.GetFullPlayerInfo()
    local classInfo = LFG.GetClassInfo()
    local ilvl = LFG.GetAverageItemLevel()
    local enchant = LFG.GetLegendaryEnchant()
    return classInfo, ilvl, enchant
end

function LFG.GetClassInfo()
    local Shared = _G.FrostSeekShared
    local className, classFile
    if Shared and Shared.GetPlayerClass then
        className, classFile = Shared.GetPlayerClass()
    else
        className, classFile = UnitClass("player")
    end
    local classMap = {
        ["WARRIOR"] = "Warrior", ["PALADIN"] = "Paladin", ["HUNTER"] = "Hunter",
        ["ROGUE"] = "Rogue", ["PRIEST"] = "Priest", ["DEATHKNIGHT"] = "Death Knight",
        ["SHAMAN"] = "Shaman", ["MAGE"] = "Mage", ["WARLOCK"] = "Warlock",
        ["DRUID"] = "Druid",
        ["HERO"] = "Hero",
        ["NECROMANCER"] = "Necromancer", ["PYROMANCER"] = "Pyromancer",
        ["CULTIST"] = "Cultist", ["STARCALLER"] = "Starcaller",
        ["SUNCLERIC"] = "Suncleric", ["TINKER"] = "Tinker",
        ["RUNEMASTER"] = "Runemaster", ["PRIMAALIST"] = "Primaalist",
        ["REAPER"] = "Reaper", ["VENOMANCER"] = "Venomancer",
        ["CHRONOMANCER"] = "Chronomancer", ["BLOODMAGE"] = "Bloodmage",
        ["GUARDIAN"] = "Guardian", ["STORMBRINGER"] = "Stormbringer",
        ["FELSWORN"] = "Felsworn", ["BARBARIAN"] = "Barbarian",
        ["WITCH DOCTOR"] = "Witch Doctor", ["WITCH HUNTER"] = "Witch Hunter",
        ["KNIGHT OF XOROTH"] = "Knight of Xoroth",
        ["TEMPLAR"] = "Templar", ["RANGER"] = "Ranger",
        ["WILDWALKER"] = "Wildwalker",
        ["SON OF ARUGAL"] = "Son of Arugal",
        ["INSETTO"] = "Insetto", ["PIRITMAGE"] = "Piritmage",
        ["DEMON HUNTER"] = "Demon Hunter", ["DEMONHUNTER"] = "Demon Hunter",
    }
    return classMap[classFile] or className or "Unknown"
end

function LFG.GetAverageItemLevel()
    local sum, count = 0, 0
    for i = 1, 17 do
        if i ~= 4 then
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
                if itemLevel then
                    sum = sum + itemLevel
                    count = count + 1
                end
            end
        end
    end
    return count > 0 and math.floor((sum / count) + 0.5) or 0
end

function LFG.CreateWhisperMessage()
    local classInfo, ilvl, enchant = LFG.GetFullPlayerInfo()
    local roleText = FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole ~= L["none"] and FrostSeekDB.LFG.myRole or ""
    local playerLevel = UnitLevel("player") or 0
    if FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled then
        local template = FrostSeekDB.LFG.customMessages.template or "inv {role} {class} {ench} {ilvl} ilvl"
        local message = template
        if FrostSeekDB.LFG.customMessages.showClass then
            message = string.gsub(message, "{class}", classInfo or "")
        else
            message = string.gsub(message, "{class}", "")
        end
        if FrostSeekDB.LFG.customMessages.showIlvl then
            message = string.gsub(message, "{ilvl}", tostring(ilvl or 0))
        else
            message = string.gsub(message, "{ilvl}", "")
        end
        message = string.gsub(message, "{gs}", "")
        if FrostSeekDB.LFG.customMessages.showEnchant then
            message = string.gsub(message, "{ench}", enchant or "")
        else
            message = string.gsub(message, "{ench}", "")
        end
        if FrostSeekDB.LFG.customMessages.showRole then
            message = string.gsub(message, "{role}", roleText or "")
        else
            message = string.gsub(message, "{role}", "")
        end
        if FrostSeekDB.LFG.customMessages.showLevel then
            message = string.gsub(message, "{level}", tostring(playerLevel))
        else
            message = string.gsub(message, "{level}", "")
        end
        if FrostSeekDB.LFG.customMessages.showAchievement and FrostSeekDB.LFG.customMessages.achievementLink ~= "" then
            message = string.gsub(message, "{achievement}", FrostSeekDB.LFG.customMessages.achievementLink)
        else
            message = string.gsub(message, "{achievement}", "")
        end
        if FrostSeekDB.LFG.customMessages.showKeystone and FrostSeekDB.LFG.customMessages.keystoneLink ~= "" then
            message = string.gsub(message, "{keystone}", FrostSeekDB.LFG.customMessages.keystoneLink)
        else
            message = string.gsub(message, "{keystone}", "")
        end
        message = string.gsub(message, "%s+", " ")
        message = string.gsub(message, "^%s*(.-)%s*$", "%1")
        if message == "" then
            message = "inv " .. roleText .. " " .. classInfo .. " " .. ilvl .. " ilvl"
        end
        return message
    else
        local enchantText = enchant ~= "" and (" " .. enchant) or ""
        local rolePrefix = roleText ~= "" and (roleText .. " ") or ""
        local levelText = " lv" .. playerLevel
        if classInfo == "Hero" then
            return "inv " .. rolePrefix .. ilvl .. " ilvl" .. levelText .. enchantText
        else
            return "inv " .. rolePrefix .. classInfo .. enchantText .. " " .. ilvl .. " ilvl" .. levelText
        end
    end
end

function LFG.SetRole(role)
    if role == "" or role == nil then
        role = L["none"]
    end
    FrostSeekDB.LFG.myRole = role
    if FrostSeekDB.Profile then
        FrostSeekDB.Profile.role = role
    end
    if LFG.roleDropdown then
        LFG.roleDropdown:SetText(role)
        LFG.roleDropdown.selectedValue = role
    end
    if LFG.UpdatePlayerInfo then
        LFG.UpdatePlayerInfo()
    end
    if FrostSeek and FrostSeek.Profile and FrostSeek.Profile.UpdateRoleButtons then
        FrostSeek.Profile:UpdateRoleButtons()
        FrostSeek.Profile:UpdateAutoInfo()
    end
    print("|cff88ccffFrostSeek LFG:|r Role set to: " .. role)
end

function LFG.RecordActiveSearch(sender, message, channel)
    local lowerMsg = string.lower(message)
    if IsSpamMessage(message) then
        return
    end
    local category, dungeon, isHeroic, isMythic, isRaid, isKeystone, isPvp = LFG.ClassifyMessage(message)
    if not LFG.PassesActivityFilter(category, dungeon) then
        return
    end
    if category == "MISC" then
        
    end
    if not activeSearches then activeSearches = {} end
    local isManastorm = (category == "MANASTORM")
    local isWorldBoss = (category == "WORLD_BOSS")
    local now = GetTime()
    for _, record in ipairs(activeSearches) do
        if record.player == sender then
            record.message = message
            record.lastUpdate = now
            record.dungeon = dungeon
            record.category = category
            record.isHeroic = isHeroic
            record.isMythic = isMythic
            record.isRaid = isRaid
            record.isPvp = isPvp
            record.isKeystone = isKeystone
            record.isManastorm = isManastorm
            record.isWorldBoss = isWorldBoss
            record.mode = LFG.GetMessageMode(message)
                    record.channel = channel
            if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
            LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isMythic, isRaid, isPvp, isKeystone, isManastorm, category)
            return
        end
    end
    table.insert(activeSearches, {
        player = sender,
        message = message,
        dungeon = dungeon,
        category = category,
        isHeroic = isHeroic,
        isMythic = isMythic,
        isRaid = isRaid,
        isPvp = isPvp,
        isKeystone = isKeystone,
        isManastorm = isManastorm,
        isWorldBoss = isWorldBoss,
        mode = LFG.GetMessageMode(message),
        channel = channel,
        lastUpdate = now,
        startTime = now,
    })
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isMythic, isRaid, isPvp, isKeystone, isManastorm, category)
end

function LFG.RecordFromListing(listing)
    if not listing then return end
    if not listing.leader or listing.leader == "" then return end
    if not listing.activity or listing.activity == "" then return end
    local sender = listing.leader
    local pn = UnitName("player") or ""
    if sender == pn then return end
    if not activeSearches then activeSearches = {} end
    local category = "DUNGEON"
    local ltype = listing.type or ""
    if ltype == "Key" then
        category = "KEYSTONE"
    elseif ltype == "Raid" then
        category = "RAID"
    elseif ltype == "World Boss" then
        category = "WORLD_BOSS"
    elseif ltype == "Event" then
        category = "MANASTORM"
    elseif ltype == "Manastorm" then
        category = "MANASTORM"
    elseif ltype == "PvP" then
        category = "PVP"
    end
    local msg = ""
    local roles = listing.roles or ""
    if roles ~= "" then
        msg = "LFM " .. roles
    else
        msg = "LFM"
    end
    if listing.key and listing.key ~= "" then
        msg = msg .. " [Keystone: " .. listing.key .. "]"
    end
    if listing.note and listing.note ~= "" then
        msg = msg .. " " .. listing.note
    end
    if not LFG.PassesActivityFilter(category, listing.activity) then
        return
    end
    local now = GetTime()
    local isKeystone = (ltype == "Key")
    local isRaid = (ltype == "Raid")
    local isPvp = (ltype == "PvP")
    local isManastorm = (ltype == "Event" or ltype == "Manastorm")
    local isWorldBoss = (ltype == "World Boss")
    for _, record in ipairs(activeSearches) do
        if record.player == sender then
            record.message = msg
            record.lastUpdate = now
            record.dungeon = listing.activity
            record.category = category
            record.isHeroic = false
            record.isRaid = isRaid
            record.isPvp = isPvp
            record.isKeystone = isKeystone
            record.isManastorm = isManastorm
            record.isWorldBoss = isWorldBoss
                    record.channel = "FrostNet"
            record.source = "protocol"
            if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
            return
        end
    end
    table.insert(activeSearches, {
        player = sender,
        message = msg,
        dungeon = listing.activity,
        category = category,
        isHeroic = false,
        isRaid = isRaid,
        isPvp = isPvp,
        isKeystone = isKeystone,
        isManastorm = isManastorm,
        isWorldBoss = isWorldBoss,
        channel = "FrostNet",
        lastUpdate = now,
        startTime = now,
        source = "protocol",
    })
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

LFG.DifficultyFilter = nil

local DIFFICULTY_FILTERS = {
    DUNGEON = {
        { label = "Normal",  match = function(d) return not d or d:lower():find("normal") end },
        { label = "Heroic",  match = function(d) return d and (d:lower():find("heroic") or d:lower():find("hc")) end },
        { label = "Mythic",  match = function(d) return d and d:lower():find("mythic") end },
    },
    RAID = {
        { label = "Normal",   match = function(d) return not d or d:lower():find("normal") end },
        { label = "Heroic",   match = function(d) return d and (d:lower():find("heroic") or d:lower():find("hc")) end },
        { label = "Mythic",   match = function(d) return d and d:lower():find("mythic") end },
        { label = "Ascended", match = function(d) return d and (d:lower():find("ascended") or d:lower():find("asc")) end },
        { label = "Trial",    match = function(d) return d and d:lower():find("trial") end },
    },
    WORLD_BOSS = {
        { label = "Normal",   match = function(d) return not d or d:lower():find("open world") or d:lower():find("normal") or d:lower() == "instanced" end },
        { label = "HC",       match = function(d) return d and (d:lower():find("hc") or d:lower():find("heroic")) end },
        { label = "Mythic",   match = function(d) return d and d:lower():find("mythic") end },
        { label = "Ascended", match = function(d) return d and (d:lower():find("ascended") or d:lower():find("asc")) end },
    },
    MANASTORM = {
        { label = "Leveling", match = function(d) return d and (d:lower():find("leveling") or d:lower():find("level")) end },
        { label = "Farm",     match = function(d) return d and (d:lower():find("farm") or d:lower():find("gold") or d:lower():find("bonzo")) end },
        { label = "ALVA",     match = function(d) return d and d:lower():find("alva") end },
    },
   
}

function LFG.GroupMatchesCategory(group, category)
    if not group then return false end
    if category == "ALL" then
        if group.category == "MISC" then return false end
        return true
    end
    return group.category == category
end

local DIFFICULTY_PATTERNS = {
    RAID = {
        { keywords = {"ascended", "asc"}, label = "Ascended" },
        { keywords = {"trial 10", "trial10", "t10"}, label = "Trial 10" },
        { keywords = {"trial 9", "trial9", "t9"}, label = "Trial 9" },
        { keywords = {"trial 8", "trial8", "t8"}, label = "Trial 8" },
        { keywords = {"trial 7", "trial7", "t7"}, label = "Trial 7" },
        { keywords = {"trial 6", "trial6", "t6"}, label = "Trial 6" },
        { keywords = {"trial 5", "trial5", "t5"}, label = "Trial 5" },
        { keywords = {"trial 4", "trial4", "t4"}, label = "Trial 4" },
        { keywords = {"trial 3", "trial3", "t3"}, label = "Trial 3" },
        { keywords = {"trial 2", "trial2", "t2"}, label = "Trial 2" },
        { keywords = {"trial 1", "trial1", "t1"}, label = "Trial 1" },
        { keywords = {"mythic"}, label = "Mythic" },
        { keywords = {"heroic", "hc"}, label = "Heroic" },
        { keywords = {"normal", "norm"}, label = "Normal" },
    },
    DUNGEON = {
        { keywords = {"mythic", "m%+", "mythic%+"}, label = "Mythic" },
        { keywords = {"heroic", "hc"}, label = "Heroic" },
        { keywords = {"normal", "norm"}, label = "Normal" },
    },
    WORLD_BOSS = {
        { keywords = {"ascended", "asc%d", " asc "}, label = "Ascended" },
        { keywords = {"mythic"}, label = "Mythic" },
        { keywords = {"heroic", "hc"}, label = "HC" },
        { keywords = {"instanced"}, label = "Instanced" },
        { keywords = {"open world"}, label = "Open World" },
    },
    MANASTORM = {
        { keywords = {"alva"}, label = "Alva" },
        { keywords = {"gold farm", "goldfarm", "bonzo farm", "bonzofarm", "bonzo", "gold"}, label = "Farm" },
        { keywords = {"leveling", "level"}, label = "Leveling" },
    },
    PVP = {
        { keywords = {"rated", "rbg"}, label = "Rated" },
        { keywords = {"arena", "2v2", "3v3", "5v5"}, label = "Arena" },
        { keywords = {"bg", "battleground"}, label = "Battleground" },
        { keywords = {"skirmish"}, label = "Skirmish" },
    },
}

function LFG.ParseDifficulty(message, category)
    if not message or not category then return nil end
    local lowerMsg = string.lower(message)
    local patterns = DIFFICULTY_PATTERNS[category]
    if not patterns then return nil end
    for _, entry in ipairs(patterns) do
        for _, kw in ipairs(entry.keywords) do
            if string.find(kw, "%%") then
                if string.match(lowerMsg, kw) then
                    return entry.label
                end
            else
                if string.find(lowerMsg, kw, 1, true) then
                    return entry.label
                end
            end
        end
    end
    return nil
end

function LFG.ParseRoles(message)
    if not message then return { tank = 0, healer = 0, dps = 0, support = 0 } end
    local roles = { tank = 0, healer = 0, dps = 0, support = 0 }
    local lowerMsg = string.lower(message)
    local function parseRole(roleKeywords, roleName)
        for _, kw in ipairs(roleKeywords) do
            local num = string.match(lowerMsg, "(%d)%s*" .. kw .. "%f[^%a%d]")
            if num then
                roles[roleName] = roles[roleName] + tonumber(num)
            end
        end
        if roles[roleName] == 0 then
            for _, kw in ipairs(roleKeywords) do
                if string.find(lowerMsg, "%f[%a]" .. kw .. "%f[^%a]") then
                    roles[roleName] = roles[roleName] + 1
                    break
                end
            end
        end
    end
    parseRole({"tank", "tanks"}, "tank")
    parseRole({"healer", "healers", "heal", "heals"}, "healer")
    parseRole({"dps", "damage", "dd"}, "dps")
    parseRole({"support", "supp", "supt"}, "support")
    local totalRoles = roles.tank + roles.healer + roles.dps + roles.support
    if totalRoles == 0 then
        local lfCount = string.match(lowerMsg, "lf(%d)")
        if lfCount then
            lfCount = tonumber(lfCount)
            if lfCount == 1 then
                roles.dps = 1
            elseif lfCount == 2 then
                roles.dps = 1
                roles.healer = 1
            elseif lfCount >= 3 then
                roles.tank = 1
                roles.healer = 1
                roles.dps = lfCount - 2
            end
        end
    end
    return roles
end

local ROLE_TAG_COLOR = {
    tank    = "|cff3a7bff",
    healer  = "|cff2ecf3a",
    dps     = "|cffe0432b",
    support = "|cff9b4dff",
}

function LFG.FormatRolesText(roles)
    if not roles then return "" end
    local tank = tonumber(roles.tank) or 0
    local healer = tonumber(roles.healer) or 0
    local dps = tonumber(roles.dps) or 0
    local support = tonumber(roles.support) or 0
    local parts = {}
    if tank > 0 then
        table.insert(parts, ROLE_TAG_COLOR.tank .. "[T]|r")
    end
    if healer > 0 then
        table.insert(parts, ROLE_TAG_COLOR.healer .. "[H]|r")
    end
    if dps > 0 then
        table.insert(parts, ROLE_TAG_COLOR.dps .. "[D]|r")
    end
    if support > 0 then
        table.insert(parts, ROLE_TAG_COLOR.support .. "[S]|r")
    end
    return table.concat(parts, " ")
end

local function FormatRolesFullText(roles)
    if not roles then return "" end
    local tank = tonumber(roles.tank) or 0
    local healer = tonumber(roles.healer) or 0
    local dps = tonumber(roles.dps) or 0
    local support = tonumber(roles.support) or 0
    local parts = {}
    if tank > 0 then
        table.insert(parts, string.format("%d Tank", tank))
    end
    if healer > 0 then
        table.insert(parts, string.format("%d Healer", healer))
    end
    if dps > 0 then
        table.insert(parts, string.format("%d DPS", dps))
    end
    if support > 0 then
        table.insert(parts, string.format("%d Support", support))
    end
    return table.concat(parts, "  ")
end
LFG.FormatRolesFullText = FormatRolesFullText

function LFG.ParseKeystoneInfo(message)
    if not message then return nil, nil end
    local name, level = string.match(message, "%[Keystone: ([^%]]+)%]%s*%((%d+)%)")
    if name and level then
        return name, tonumber(level)
    end
    name = string.match(message, "%[Keystone: ([^%]]+)%]")
    return name or nil, nil
end

function LFG.ShortenMessage(message)
    if not message then return "" end
    local maxLength = FrostSeekDB.LFG.maxMessageLength or 150
    if string.len(message) <= maxLength then
        return message
    end
    return string.sub(message, 1, maxLength - 3) .. "..."
end

function LFG.CanShowPopup(sender, message)
    if not sender or not message then return false end
    local normalizedMessage = string.lower(message):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    local messageKey = sender .. ":" .. normalizedMessage
    local now = GetTime()
    local lastTime = lastPopupTimes[messageKey]
    if lastTime and (now - lastTime) < (FrostSeekDB.LFG.popupCooldown or 400) then
        return false
    end
    lastPopupTimes[messageKey] = now
    return true
end

function LFG.CountActivePopups()
    local count = 0
    for _, frame in ipairs(openFrames) do
        if frame and frame:IsShown() then
            count = count + 1
        end
    end
    return count
end

function LFG.ProcessPopupQueue()
    if isProcessingQueue then return end
    if #popupQueue == 0 then return end
    if LFG.CountActivePopups() >= (FrostSeekDB.LFG.maxConcurrentPopups or 3) then
        C_Timer.After(1, function()
            LFG.ProcessPopupQueue()
        end)
        return
    end
    isProcessingQueue = true
    local nextPopup = table.remove(popupQueue, 1)
    LFG.CreateLFGPopup(
        nextPopup.sender,
        nextPopup.message,
        nextPopup.dungeon,
        nextPopup.isHeroic,
        nextPopup.isRaid,
        nextPopup.isPvp,
        nextPopup.isKeystone,
        nextPopup.isManastorm,
        nextPopup.category
    )
end

function LFG.RemovePopupFrame(frame)
    if frame then
        if frame.category and FrostSeek and FrostSeek.RemoveMinimapCategory then
            FrostSeek.RemoveMinimapCategory(frame.category)
        end
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
        frame:SetParent(nil)
        for i, popup in ipairs(openFrames) do
            if popup == frame then
                table.remove(openFrames, i)
                break
            end
        end
        LFG.RepositionPopups()
        if #popupQueue > 0 then
            C_Timer.After(1, function()
                LFG.ProcessPopupQueue()
            end)
        end
    end
end

function LFG.RepositionPopups()
    local activeCount = 0
    for _, frame in ipairs(openFrames) do
        if frame and frame:IsShown() then
            local h = frame:GetHeight() or 90
            local yOffset = 40 + (activeCount * (h + 6))
            frame:ClearAllPoints()
            frame:SetPoint("TOP", UIParent, "TOP", 0, -yOffset)
            activeCount = activeCount + 1
        end
    end
end

function LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isMythic, isRaid, isPvp, isKeystone, isManastorm, category)
    if category == "MISC" then return end
    if FrostSeekDB.LFG.disablePopups then return end
    if FrostSeekDB.LFG.disableLFG then return end
    if FrostSeekDB.LFG.doNotAlertInGroup and ((GetNumPartyMembers and GetNumPartyMembers() > 0) or (GetNumRaidMembers and GetNumRaidMembers() > 0) or (GetNumGroupMembers and GetNumGroupMembers() > 1)) then return end
    if FrostSeekDB.LFG.doNotAlertInCombat and UnitAffectingCombat("player") then return end
    local activePopupCount = LFG.CountActivePopups()
    if mutedPlayers[sender] and GetTime() < mutedPlayers[sender] then
        return
    end
    if activePopupCount >= (FrostSeekDB.LFG.maxConcurrentPopups or 3) then
        table.insert(popupQueue, {
            sender = sender,
            message = message,
            dungeon = dungeon,
            isHeroic = isHeroic,
            isRaid = isRaid,
            isPvp = isPvp,
            isKeystone = isKeystone,
            isManastorm = isManastorm,
            category = category,
        })
        return
    end
    if category ~= "MISC" and not FrostSeekDB.LFG.popupCategories[category] and not FrostSeekDB.LFG.popupCategories["ALL"] then
        return
    end
    local modeFilter = FrostSeekDB.LFG.popupModeFilter
    if modeFilter and modeFilter ~= "All" then
        local msgMode = LFG.GetMessageMode(message) or "LFG"
        if msgMode ~= modeFilter then
            return
        end
    end
    if not LFG.CanShowPopup(sender, message) then return end

    local accent = CATEGORY_ACCENT[category] or CATEGORY_ACCENT.MISC
    local ar, ag, ab = accent[1], accent[2], accent[3]

    local UI = FrostSeekUIUtils
    local W, H = 340, 100
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(W, H)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup.category = category

    
    local borderTex = popup:CreateTexture(nil, "BACKGROUND")
    borderTex:SetAllPoints()
    borderTex:SetColorTexture(ar * 0.3, ag * 0.3, ab * 0.3, 0.65)

    
    local bgPopupColor = _tc("bgPopup")
    local bgTex = popup:CreateTexture(nil, "BORDER")
    bgTex:SetPoint("TOPLEFT", 1, -1)
    bgTex:SetPoint("BOTTOMRIGHT", -1, 1)
    bgTex:SetColorTexture(bgPopupColor[1], bgPopupColor[2], bgPopupColor[3], bgPopupColor[4])

    local yOffset = 40 + (activePopupCount * (H + 6))
    popup:SetPoint("TOP", UIParent, "TOP", 0, -yOffset)
    popup:SetAlpha(0)
    UIFrameFadeIn(popup, 0.2, 0, 1)

    
    local topAccent = popup:CreateTexture(nil, "ARTWORK")
    topAccent:SetPoint("TOPLEFT", 1, 0)
    topAccent:SetPoint("TOPRIGHT", -1, 0)
    topAccent:SetHeight(2)
    topAccent:SetColorTexture(ar, ag, ab, 0.9)

    
    local glassReflect = popup:CreateTexture(nil, "ARTWORK")
    glassReflect:SetPoint("TOPLEFT", 2, -3)
    glassReflect:SetPoint("TOPRIGHT", -2, -3)
    glassReflect:SetHeight(14)
    glassReflect:SetColorTexture(ar * 0.06, ag * 0.06, ab * 0.06, 0.3)

    
    local catLabels = {
        DUNGEON = L["cat_dungeon"], RAID = L["cat_raid"],
        WORLD_BOSS = L["cat_world_boss"], PVP = L["cat_pvp"],
        MANASTORM = L["cat_manastorm"], KEYSTONE = L["cat_keystone"],
    }
    local catText = catLabels[category] or L["cat_misc"]
    popup.headerText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popup.headerText:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -8)
    popup.headerText:SetText(catText)
    popup.headerText:SetTextColor(min(ar * 1.4, 1), min(ag * 1.4, 1), min(ab * 1.4, 1))

    local difficulty = LFG.ParseDifficulty(message, category)
    local diffTag = ""
    local diffColor = "|cffcccccc"
    if difficulty then
        local dl = difficulty:lower()
        if dl:find("ascended") or dl == "asc" then
            local num = dl:match("ascended%s*(%d+)") or dl:match("asc%s*(%d+)") or ""
            diffTag = L["diff_ascended"] .. (num ~= "" and num or "")
            diffColor = "|cffaa44ff"
        elseif dl:find("trial") then
            local num = dl:match("trial%s*(%d+)") or ""
            diffTag = L["diff_trial"] .. (num ~= "" and num or "")
            diffColor = "|cffff8800"
        elseif dl:find("mythic") then
            local num = dl:match("mythic%s*(%d+)") or dl:match("m%s*(%d+)") or ""
            diffTag = L["diff_mythic"] .. (num ~= "" and num or "")
            diffColor = "|cffff44ff"
        elseif dl:find("heroic") or dl == "hc" then
            diffTag = L["diff_heroic"]
            diffColor = "|cff44cc44"
        elseif dl:find("ranked") then
            diffTag = L["diff_ranked"]
            diffColor = "|cffff4444"
        elseif dl == "instanced" then
            diffTag = L["diff_normal"] .. " (Inst)"
            diffColor = "|cffcccccc"
        elseif dl:find("instanced") then
            diffTag = difficulty
            diffColor = "|cffff8800"
        elseif dl:find("open world") then
            diffTag = L["diff_normal"]
            diffColor = "|cffcccccc"
        else
            diffTag = difficulty
            diffColor = "|cffcccccc"
        end
    elseif isMythic then
        diffTag = L["diff_mythic"]
        diffColor = "|cffff44ff"
    elseif isHeroic then
        diffTag = L["diff_heroic"]
        diffColor = "|cff44cc44"
    elseif category == "DUNGEON" or category == "RAID" then
        diffTag = L["diff_normal"]
        diffColor = "|cffcccccc"
    end

    local catHex = string.format("%02x%02x%02x", math.floor(ar*255), math.floor(ag*255), math.floor(ab*255))
    local dungeonDisplay = ""
    if isKeystone then
        local ksName, ksLevel = LFG.ParseKeystoneInfo(message)
        if ksName then
            dungeonDisplay = ksName
            if ksLevel then
                diffTag = L["diff_mythic"] .. ksLevel
                diffColor = "|cffff44ff"
            end
        end
    elseif category == "RAID" then
        dungeonDisplay = dungeon and dungeon ~= "RAID" and dungeon or L["cat_raid"]
    elseif category == "WORLD_BOSS" then
        dungeonDisplay = dungeon and dungeon ~= "WORLD_BOSS" and dungeon or L["cat_world_boss"]
    elseif category == "MANASTORM" then
        dungeonDisplay = L["cat_manastorm"]
    elseif category == "PVP" then
        dungeonDisplay = dungeon and dungeon ~= "PVP" and dungeon or L["cat_pvp"]
    else
        dungeonDisplay = dungeon and dungeon ~= "MISC" and dungeon ~= "DUNGEON" and dungeon or L["cat_dungeon"]
    end

    local row1Y = -22
    local iconX = 10

    local dungeonFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonFS:SetPoint("TOPLEFT", popup, "TOPLEFT", iconX, row1Y)
    dungeonFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    dungeonFS:SetJustifyH("LEFT")
    local dungeonColorHex = catHex
    if diffColor == "|cffaa44ff" then dungeonColorHex = "aa44ff"
    elseif diffColor == "|cffff8800" then dungeonColorHex = "ff8800"
    elseif diffColor == "|cffff44ff" then dungeonColorHex = "ff44ff"
    elseif diffColor == "|cff44cc44" then dungeonColorHex = "44cc44"
    elseif diffColor == "|cffff4444" then dungeonColorHex = "ff4444"
    end
    local dungeonLine = "|cff" .. dungeonColorHex .. dungeonDisplay .. "|r"
    if diffTag ~= "" then
        dungeonLine = dungeonLine .. "  " .. diffColor .. "[" .. diffTag .. "]|r"
    end
    dungeonLine = dungeonLine .. "  |cffffffff" .. (sender or "Unknown") .. "|r"
    dungeonFS:SetText(dungeonLine)

    local row2Y = -40
    local roles = LFG.ParseRoles(message)
    local roleTagStr = LFG.FormatRolesText(roles)
    local roleFullStr = LFG.FormatRolesFullText(roles)
    local rolesFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rolesFS:SetPoint("TOPLEFT", popup, "TOPLEFT", iconX, row2Y)
    rolesFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    rolesFS:SetJustifyH("LEFT")
    if roleTagStr and roleTagStr ~= "" then
        rolesFS:SetText("|cff88ccffLooking for:|r " .. roleTagStr)
    else
        rolesFS:SetText("|cff888888Looking for: anyone|r")
    end

    local row3Y = -58
    local msgFS = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgFS:SetPoint("TOPLEFT", popup, "TOPLEFT", iconX, row3Y)
    msgFS:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
    msgFS:SetJustifyH("LEFT")
    msgFS:SetWordWrap(false)
    local truncMsg = message and #message > 60 and string.sub(message, 1, 57) .. "..." or (message or "")
    msgFS:SetTextColor(1, 1, 1, 1)
    msgFS:SetText(truncMsg)

    local footerY = 6

    local whisperBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 64, 20, L["popup_whisper"], _tc("success"))
    if not whisperBtn then
        whisperBtn = CreateFrame("Button", nil, popup)
        whisperBtn:SetSize(64, 20)
        whisperBtn.text = whisperBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        whisperBtn.text:SetPoint("CENTER")
        whisperBtn.text:SetText(L["popup_whisper"])
    end
    whisperBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 6, footerY)
    whisperBtn:SetScript("OnClick", function()
        local whisperMsg = LFG.CreateWhisperMessage()
        SendChatMessage(whisperMsg, "WHISPER", nil, sender)
        LFG.RemovePopupFrame(popup)
        UIErrorsFrame:AddMessage("|cff88ccff" .. FrostSeek.Lf("popup_whisper_sent", sender) .. "|r", 1, 1, 1, 3)
    end)

    local muteBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 48, 20, L["popup_mute"], _tc("warning"))
    if not muteBtn then
        muteBtn = CreateFrame("Button", nil, popup)
        muteBtn:SetSize(48, 20)
        muteBtn.text = muteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        muteBtn.text:SetPoint("CENTER")
        muteBtn.text:SetText(L["popup_mute"])
    end
    muteBtn:SetPoint("LEFT", whisperBtn, "RIGHT", 4, 0)
    muteBtn:SetScript("OnClick", function()
        mutedPlayers[sender] = GetTime() + 1800
        LFG.RemovePopupFrame(popup)
        print("|cffff8800FrostSeek:|r " .. FrostSeek.Lf("popup_muted", sender))
    end)

    local closeBtn = UI and UI.CreateModernButton and UI.CreateModernButton(popup, 48, 20, L["close"], _tc("secondary"))
    if not closeBtn then
        closeBtn = CreateFrame("Button", nil, popup)
        closeBtn:SetSize(48, 20)
        closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        closeBtn.text:SetPoint("CENTER")
        closeBtn.text:SetText(L["close"])
    end
    closeBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -6, footerY)
    closeBtn:SetScript("OnClick", function()
        LFG.RemovePopupFrame(popup)
    end)

    local duration = FrostSeekDB.LFG.frameDuration or 5
    popup.expiryTime = GetTime() + duration
    popup:SetScript("OnUpdate", function(self, elapsed)
        local remaining = self.expiryTime - GetTime()
        if remaining <= 0 then
            self:SetScript("OnUpdate", nil)
            LFG.RemovePopupFrame(self)
        elseif remaining < 0.8 then
            self:SetAlpha(remaining / 0.8)
        end
    end)

    if not FrostSeekDB.LFG.silentNotifications then
        if FrostSeekDB.LFG.soundEnabled ~= false and Shared and Shared.PlaySound then
            Shared.PlaySound("popup")
        else
            PlaySoundFile("Sound\\Interface\\MapPing.wav")
        end
    end
    table.insert(openFrames, popup)
    if FrostSeek and FrostSeek.SetMinimapCategory then
        FrostSeek.SetMinimapCategory(category)
    end
end

function LFG.CleanupActiveSearches()
    if not activeSearches then activeSearches = {} end
    local now = GetTime()
    local removedCount = 0
    for i = #activeSearches, 1, -1 do
        if activeSearches[i] and activeSearches[i].lastUpdate and
           (now - activeSearches[i].lastUpdate > searchExpirationTime) then
            table.remove(activeSearches, i)
            removedCount = removedCount + 1
        end
    end
    if removedCount > 0 then
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end
end

C_Timer.NewTicker(300, function()
    local now = GetTime()
    for name, expiry in pairs(mutedPlayers) do
        if now >= expiry then
            mutedPlayers[name] = nil
        end
    end
end)

function LFG.ClearAllSearches()
    activeSearches = {}
    for i = #openFrames, 1, -1 do
        LFG.RemovePopupFrame(openFrames[i])
    end
    openFrames = {}
    if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    print("|cff88ccffFrostSeek LFG:|r All searches cleared")
end

function LFG.ScrollRecruitersList(direction)
    if not LFG.recruitersScrollFrame then return end
    local scrollBar = LFG.recruitersScrollFrame:GetScrollChild()
    if not scrollBar then return end
    local range = scrollBar:GetHeight() - LFG.recruitersScrollFrame:GetHeight()
    if range <= 0 then return end
    local cur = LFG.recruitersScrollFrame:GetVerticalScroll()
    if direction == "UP" then
        LFG.recruitersScrollFrame:SetVerticalScroll(math.max(0, cur - ROW_HEIGHT))
    elseif direction == "DOWN" then
        LFG.recruitersScrollFrame:SetVerticalScroll(math.min(range, cur + ROW_HEIGHT))
    end
end

function LFG.CountFilteredSearches()
    local count = 0
    for _, search in ipairs(activeSearches or {}) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
            count = count + 1
        end
    end
    return count
end

function LFG.UpdatePlayerInfo()
    if not LFG.playerInfoText then return end
    local classInfo, ilvl, enchant = LFG.GetFullPlayerInfo()
    local roleText = (FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole ~= L["none"]) and ("Role: " .. FrostSeekDB.LFG.myRole) or "Role: Not Set"
    LFG.playerInfoText:SetText(string.format("|cffffffff%s | |cff00ff00%diLvl|r | %s %s",
        classInfo, ilvl, roleText, enchant))
end

local contextMenu = nil

local function CreateContextMenu()
    if contextMenu then return contextMenu end
    contextMenu = CreateFrame("Frame", "FrostSeekContextMenu", UIParent, "UIDropDownMenuTemplate")
    contextMenu.playerName = nil
    local function OnClick_Whisper()
        if not contextMenu.playerName then return end
        local editBox = ChatEdit_GetActiveWindow()
        if not editBox then
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat("/w " .. contextMenu.playerName .. " ")
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat("/w " .. contextMenu.playerName .. " ")
            end
        else
            editBox:SetText("/w " .. contextMenu.playerName .. " ")
            editBox:SetCursorPosition(string.len(editBox:GetText()))
        end
    end
    local function OnClick_Invite()
        if not contextMenu.playerName then return end
        InviteUnit(contextMenu.playerName)
        print("|cff88ccffFrostSeek:|r Invite sent to " .. contextMenu.playerName)
    end
    local function OnClick_SendWhisperWithLFG()
        if not contextMenu.playerName then return end
        local msg = LFG.CreateWhisperMessage()
        SendChatMessage(msg, "WHISPER", nil, contextMenu.playerName)
        print("|cff88ccffFrostSeek:|r LFG whisper sent to " .. contextMenu.playerName)
    end
    local function OnClick_AddFriend()
        if not contextMenu.playerName then return end
        if C_FriendList and C_FriendList.AddFriend then
            C_FriendList.AddFriend(contextMenu.playerName)
        elseif AddFriend then
            AddFriend(contextMenu.playerName)
        end
        print("|cff88ccffFrostSeek:|r Friend request sent to " .. contextMenu.playerName)
    end
    local function OnClick_Ignore()
        if not contextMenu.playerName then return end
        if C_FriendList and C_FriendList.AddIgnore then
            C_FriendList.AddIgnore(contextMenu.playerName)
        elseif AddIgnore then
            AddIgnore(contextMenu.playerName)
        end
        print("|cff88ccffFrostSeek:|r " .. contextMenu.playerName .. " added to ignore list")
    end
    local function OnClick_CopyName()
        if not contextMenu.playerName then return end
        local editBox = ChatEdit_GetActiveWindow()
        if not editBox then
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat(contextMenu.playerName)
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat(contextMenu.playerName)
            end
        else
            editBox:SetText(contextMenu.playerName)
        end
    end
    local menuItems = {
        { text = "FrostSeek Player Menu", isTitle = true, notCheckable = true },
        { text = "|cff88ccffWhisper|r", func = OnClick_Whisper, notCheckable = true },
        { text = "|cff2fff5fLFG Whisper (Auto)|r", func = OnClick_SendWhisperWithLFG, notCheckable = true },
        { text = "|cffffaa00Invite to Group|r", func = OnClick_Invite, notCheckable = true },
        { text = "Add Friend", func = OnClick_AddFriend, notCheckable = true },
        { text = "|cffff5555Ignore|r", func = OnClick_Ignore, notCheckable = true },
        { text = "Copy Name", func = OnClick_CopyName, notCheckable = true },
    }
    UIDropDownMenu_Initialize(contextMenu, function(self, level)
        if not level then return end
        for _, item in ipairs(menuItems) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.isTitle = item.isTitle or false
            info.notCheckable = item.notCheckable or false
            info.func = item.func
            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")
    return contextMenu
end

local function ShowPlayerContextMenu(playerName, anchor)
    if not playerName or playerName == "" then return end
    CreateContextMenu()
    contextMenu.playerName = playerName
    ToggleDropDownMenu(1, nil, contextMenu, anchor or "cursor", 0, 0)
end

LFG.ShowPlayerContextMenu = ShowPlayerContextMenu

function LFG.InitRowPool(parent)
    rowPool = {}
    local rowW = parent:GetWidth() or 740
    for i = 1, MAX_DISPLAY_ROWS do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(rowW, ROW_HEIGHT)
        if i == 1 then
            row:SetPoint("TOP", parent, "TOP", 0, -2)
        else
            row:SetPoint("TOP", rowPool[i-1].frame, "BOTTOM", 0, 0)
        end
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 3, 0)
        bg:SetPoint("BOTTOMRIGHT", 0, 0)
        bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        local accentBar = row:CreateTexture(nil, "BACKGROUND")
        accentBar:SetPoint("TOPLEFT", 0, 0)
        accentBar:SetSize(3, ROW_HEIGHT)
        accentBar:SetColorTexture(unpack(_tc("border")))
        local separator = row:CreateTexture(nil, "BACKGROUND")
        separator:SetPoint("BOTTOMLEFT", 6, 0)
        separator:SetPoint("BOTTOMRIGHT", -2, 0)
        separator:SetHeight(1)
        separator:SetColorTexture(unpack(_tc("separator")))
        local dot = row:CreateTexture(nil, "OVERLAY")
        dot:SetSize(6, 6)
        dot:SetPoint("LEFT", row, "LEFT", 12, 0)
        dot:SetColorTexture(unpack(_tc("border")))
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 18, 0)
        nameText:SetWidth(80)
        nameText:SetJustifyH("LEFT")
        nameText:SetText("")
        nameText:SetTextColor(unpack(_tc("textAccent")))
        local nameClickFrame = CreateFrame("Button", nil, row)
        nameClickFrame:SetPoint("LEFT", row, "LEFT", 18, 0)
        nameClickFrame:SetSize(80, ROW_HEIGHT)
        nameClickFrame:RegisterForClicks("RightButtonUp")
        nameClickFrame:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                local pr = rowPool[i]
                if pr and pr.currentRecord and pr.currentRecord.player then
                    LFG.ShowPlayerContextMenu(pr.currentRecord.player, self)
                end
            end
        end)
        local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        timeText:SetPoint("LEFT", row, "LEFT", 108, 0)
        timeText:SetWidth(40)
        timeText:SetJustifyH("LEFT")
        timeText:SetText("")
        timeText:SetTextColor(unpack(_tc("textDim")))
        local catText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        catText:SetPoint("LEFT", row, "LEFT", 158, 0)
        catText:SetWidth(30)
        catText:SetJustifyH("LEFT")
        catText:SetText("")
        local roleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        roleText:SetPoint("LEFT", row, "LEFT", 192, 0)
        roleText:SetWidth(70)
        roleText:SetJustifyH("LEFT")
        roleText:SetText("")
        roleText:SetTextColor(unpack(_tc("textNorm")))
        local dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dungeonText:SetPoint("LEFT", row, "LEFT", 266, 0)
        dungeonText:SetWidth(80)
        dungeonText:SetJustifyH("LEFT")
        dungeonText:SetText("")
        dungeonText:SetTextColor(unpack(_tc("textNorm")))
        local msgText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        msgText:SetPoint("LEFT", row, "LEFT", 350, 0)
        msgText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        msgText:SetJustifyH("LEFT")
        msgText:SetText("")
        msgText:SetTextColor(unpack(_tc("textPrimary")))
        local tooltipFrame = CreateFrame("Frame", nil, row)
        tooltipFrame:SetPoint("LEFT", row, "LEFT", 350, 0)
        tooltipFrame:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        tooltipFrame:SetHeight(ROW_HEIGHT)
        tooltipFrame:EnableMouse(true)
        local tooltipBg = tooltipFrame:CreateTexture(nil, "BACKGROUND")
        tooltipBg:SetAllPoints()
        tooltipBg:SetColorTexture(0, 0, 0, 0)
        local acceptBtn = FrostSeekUIUtils.CreateModernButton(row, 60, 20, L["listings_accept"], _tc("catDungeon"))
        acceptBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        acceptBtn:SetScript("OnClick", function()
            local pr = rowPool[i]
            if pr and pr.currentRecord then
                local msg = LFG.CreateWhisperMessage()
                SendChatMessage(msg, "WHISPER", nil, pr.currentRecord.player)
                print("|cff88ccffFrostSeek LFG:|r Whisper sent to " .. pr.currentRecord.player)
            end
        end)
        row:SetScript("OnEnter", function(self)
            local pr = rowPool[i]
            local accent = pr.accent
            local ri = pr.rowIndex
            pr.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
            pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
            pr.nameText:SetTextColor(unpack(_tc("textAccent")))
        end)
        row:SetScript("OnLeave", function(self)
            local pr = rowPool[i]
            local accent = pr.accent
            local ri = pr.rowIndex
            if ri % 2 == 0 then
                pr.bg:SetColorTexture(unpack(_tc("bgRowEven")))
            else
                pr.bg:SetColorTexture(unpack(_tc("bgRowOdd")))
            end
            pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
            pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
            pr.nameText:SetTextColor(unpack(_tc("textAccent")))
        end)
        row:Hide()
        rowPool[i] = {
            frame = row,
            bg = bg,
            accentBar = accentBar,
            dot = dot,
            nameText = nameText,
            timeText = timeText,
            catText = catText,
            roleText = roleText,
            dungeonText = dungeonText,
            msgText = msgText,
            tooltipFrame = tooltipFrame,
            accent = {0.5, 0.5, 0.5},
            currentRecord = nil,
            rowIndex = i,
        }
    end
end

function LFG.CreateRowForPool(parent, idx)
    local prev = rowPool[idx - 1]
    local row = CreateFrame("Frame", nil, parent)
    local rowW = parent:GetWidth() or 740
    row:SetSize(rowW, ROW_HEIGHT)
    if prev then
        row:SetPoint("TOP", prev.frame, "BOTTOM", 0, 0)
    else
        row:SetPoint("TOP", parent, "TOP", 0, -2)
    end
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 3, 0)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    bg:SetColorTexture(unpack(_tc("bgRowOdd")))
    local accentBar = row:CreateTexture(nil, "BACKGROUND")
    accentBar:SetPoint("TOPLEFT", 0, 0)
    accentBar:SetSize(3, ROW_HEIGHT)
    accentBar:SetColorTexture(unpack(_tc("border")))
    local dot = row:CreateTexture(nil, "OVERLAY")
    dot:SetSize(6, 6)
    dot:SetPoint("LEFT", row, "LEFT", 12, 0)
    dot:SetColorTexture(unpack(_tc("border")))
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", row, "LEFT", 18, 0)
    nameText:SetWidth(80)
    nameText:SetJustifyH("LEFT")
    nameText:SetText("")
    nameText:SetTextColor(unpack(_tc("textAccent")))
    local nameClickFrame = CreateFrame("Button", nil, row)
    nameClickFrame:SetPoint("LEFT", row, "LEFT", 18, 0)
    nameClickFrame:SetSize(80, ROW_HEIGHT)
    nameClickFrame:RegisterForClicks("RightButtonUp")
    nameClickFrame:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            local pr = rowPool[idx]
            if pr and pr.currentRecord and pr.currentRecord.player then
                LFG.ShowPlayerContextMenu(pr.currentRecord.player, self)
            end
        end
    end)
    local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("LEFT", row, "LEFT", 108, 0)
    timeText:SetWidth(40)
    timeText:SetJustifyH("LEFT")
    timeText:SetText("")
    timeText:SetTextColor(unpack(_tc("textDim")))
    local catText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catText:SetPoint("LEFT", row, "LEFT", 158, 0)
    catText:SetWidth(30)
    catText:SetJustifyH("LEFT")
    catText:SetText("")
    local roleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleText:SetPoint("LEFT", row, "LEFT", 192, 0)
    roleText:SetWidth(70)
    roleText:SetJustifyH("LEFT")
    roleText:SetText("")
    roleText:SetTextColor(unpack(_tc("textNorm")))
    local dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonText:SetPoint("LEFT", row, "LEFT", 266, 0)
    dungeonText:SetWidth(80)
    dungeonText:SetJustifyH("LEFT")
    dungeonText:SetText("")
    dungeonText:SetTextColor(unpack(_tc("textNorm")))
    local msgText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgText:SetPoint("LEFT", row, "LEFT", 350, 0)
    msgText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    msgText:SetJustifyH("LEFT")
    msgText:SetText("")
    msgText:SetTextColor(unpack(_tc("textPrimary")))
    local tooltipFrame = CreateFrame("Frame", nil, row)
    tooltipFrame:SetPoint("LEFT", row, "LEFT", 350, 0)
    tooltipFrame:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    tooltipFrame:SetHeight(ROW_HEIGHT)
    tooltipFrame:EnableMouse(true)
    local tooltipBg = tooltipFrame:CreateTexture(nil, "BACKGROUND")
    tooltipBg:SetAllPoints()
    tooltipBg:SetColorTexture(0, 0, 0, 0)
    local acceptBtn = FrostSeekUIUtils.CreateModernButton(row, 60, 20, L["listings_accept"], _tc("catDungeon"))
    acceptBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    acceptBtn:SetScript("OnClick", function()
        local pr = rowPool[idx]
        if pr and pr.currentRecord then
            local msg = LFG.CreateWhisperMessage()
            SendChatMessage(msg, "WHISPER", nil, pr.currentRecord.player)
            print("|cff88ccffFrostSeek LFG:|r Whisper sent to " .. pr.currentRecord.player)
        end
    end)
    row:SetScript("OnEnter", function(self)
        local pr = rowPool[idx]
        local accent = pr.accent
        local ri = pr.rowIndex
        pr.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
        pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 1.0)
        pr.nameText:SetTextColor(unpack(_tc("textAccent")))
    end)
    row:SetScript("OnLeave", function(self)
        local pr = rowPool[idx]
        local accent = pr.accent
        local ri = pr.rowIndex
        if ri % 2 == 0 then
            pr.bg:SetColorTexture(unpack(_tc("bgRowEven")))
        else
            pr.bg:SetColorTexture(unpack(_tc("bgRowOdd")))
        end
        pr.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
        pr.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
        pr.nameText:SetTextColor(unpack(_tc("textAccent")))
    end)
    row:Hide()
    local newRow = {
        frame = row,
        bg = bg,
        accentBar = accentBar,
        dot = dot,
        nameText = nameText,
        timeText = timeText,
        catText = catText,
        roleText = roleText,
        dungeonText = dungeonText,
        msgText = msgText,
        tooltipFrame = tooltipFrame,
        accent = {0.5, 0.5, 0.5},
        currentRecord = nil,
        rowIndex = idx,
    }
    rowPool[idx] = newRow
    return newRow
end

function LFG.UpdateRecruitersList()
    if not LFG.recruitersList then return end
    if not activeSearches then activeSearches = {} end
    local scrollChild = LFG.recruitersList.scrollChild
    for i = 1, #rowPool do
        if rowPool[i] then
            rowPool[i].frame:Hide()
            rowPool[i].currentRecord = nil
        end
    end
    if LFG.noRecruitersText then
        LFG.noRecruitersText:Hide()
    end
    local filteredSearches = {}
    local searchLower = lfgSearchText and string.lower(lfgSearchText) or ""
    local diffFilter = LFG.DifficultyFilter
    local diffFilters = diffFilter and DIFFICULTY_FILTERS[LFG.CurrentCategory or ""] or nil
    local activeDiffMatch = nil
    if diffFilters and diffFilter then
        for _, f in ipairs(diffFilters) do
            if f.label == diffFilter then activeDiffMatch = f.match; break end
        end
    end
    for _, search in ipairs(activeSearches) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
            local passesMode = true
            if LFG.ModeFilter and LFG.ModeFilter ~= "ALL" then
                local recMode = LFG.GetMessageMode(search.message) or "LFG"
                search.mode = recMode
                passesMode = (recMode == LFG.ModeFilter)
            end
            if not passesMode then
                
            elseif activeDiffMatch then
                local diffLabel = LFG.ParseDifficulty(search.message, search.category)
                if activeDiffMatch(diffLabel) then
                    if searchLower == "" then
                        table.insert(filteredSearches, search)
                    else
                        local msgLower = string.lower(search.message or "")
                        local playerLower = string.lower(search.player or "")
                        local dungeonLower = string.lower(search.dungeon or "")
                        local catLower = string.lower(search.category or "")
                        if string.find(msgLower, searchLower, 1, true)
                            or string.find(playerLower, searchLower, 1, true)
                            or string.find(dungeonLower, searchLower, 1, true)
                            or string.find(catLower, searchLower, 1, true) then
                            table.insert(filteredSearches, search)
                        end
                    end
                end
            else
                if searchLower == "" then
                    table.insert(filteredSearches, search)
                else
                    local msgLower = string.lower(search.message or "")
                    local playerLower = string.lower(search.player or "")
                    local dungeonLower = string.lower(search.dungeon or "")
                    local catLower = string.lower(search.category or "")
                    if string.find(msgLower, searchLower, 1, true)
                        or string.find(playerLower, searchLower, 1, true)
                        or string.find(dungeonLower, searchLower, 1, true)
                        or string.find(catLower, searchLower, 1, true) then
                        table.insert(filteredSearches, search)
                    end
                end
            end
        end
    end
    table.sort(filteredSearches, function(a, b)
        return (a.lastUpdate or 0) > (b.lastUpdate or 0)
    end)
    if LFG.lfgCountText then
        LFG.lfgCountText:SetText(string.format(L["lfg_active_recruiters"], #filteredSearches))
    end
    local totalFiltered = #filteredSearches
    if scrollChild then
        scrollChild:SetHeight(math.max(260, totalFiltered * ROW_HEIGHT + 4))
    end
    if LFG.scrollIndicator then
        if totalFiltered > MAX_DISPLAY_ROWS then
            LFG.scrollIndicator:SetText(tostring(totalFiltered) .. " recruiters")
        else
            LFG.scrollIndicator:SetText(tostring(totalFiltered) .. " recruiters")
        end
    end
    local now = GetTime()
    for idx = 1, totalFiltered do
        local record = filteredSearches[idx]
        local poolRow = rowPool[idx]
        if not poolRow and scrollChild then
            poolRow = LFG.CreateRowForPool(scrollChild, idx)
        end
        if poolRow and record then
            poolRow.currentRecord = record
            local accent = CATEGORY_ACCENT[record.category] or CATEGORY_ACCENT.MISC
            poolRow.accent = accent
            poolRow.rowIndex = idx
            if idx % 2 == 0 then
                poolRow.bg:SetColorTexture(unpack(_tc("bgRowEven")))
            else
                poolRow.bg:SetColorTexture(unpack(_tc("bgRowOdd")))
            end
            poolRow.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 0.7)
            poolRow.dot:SetColorTexture(accent[1], accent[2], accent[3], 0.9)
            poolRow.nameText:SetText(record.player or "Unknown")
            local timeSince = now - (record.lastUpdate or 0)
            if timeSince < 60 then
                poolRow.timeText:SetText(string.format("%ds", timeSince))
            else
                poolRow.timeText:SetText(string.format("%dm", math.floor(timeSince/60)))
            end
            poolRow.catText:SetText(CATEGORY_TAG[record.category] or "|cFF00FF00D|r")
            local roles = LFG.ParseRoles(record.message)
            local roleStr = LFG.FormatRolesText(roles)
            local roleFullStr = LFG.FormatRolesFullText(roles)
            poolRow.roleText:SetText(roleStr)
            if record.dungeon and record.dungeon ~= "MISC" and record.dungeon ~= "KEYSTONE" and record.dungeon ~= "PVP" and record.dungeon ~= "MANASTORM" and record.dungeon ~= "WORLD_BOSS" then
                
                local diffLabel = LFG.ParseDifficulty(record.message, record.category)
                local diffTag, diffColor
                if diffLabel then
                    local dl = diffLabel:lower()
                    if dl:find("ascended") or dl:find("asc") then
                        local num = dl:match("ascended%s*(%d+)") or dl:match("asc%s*(%d+)") or ""
                        diffTag = L["diff_ascended"] .. (num ~= "" and num or "")
                        diffColor = "|cffaa44ff"
                    elseif dl:find("trial") then
                        local num = dl:match("trial%s*(%d+)") or ""
                        diffTag = L["diff_trial"] .. (num ~= "" and num or "")
                        diffColor = "|cffff8800"
                    elseif dl:find("mythic") then
                        local num = dl:match("mythic%s*(%d+)") or dl:match("m%s*(%d+)") or ""
                        diffTag = L["diff_mythic"] .. (num ~= "" and num or "")
                        diffColor = "|cffff44ff"
                    elseif dl:find("heroic") or dl:find("hc") then
                        diffTag = L["diff_heroic"]
                        diffColor = "|cff44cc44"
                    elseif dl:find("ranked") then
                        diffTag = L["diff_ranked"]
                        diffColor = "|cffff4444"
                    elseif dl == "instanced" then
                        diffTag = L["diff_normal"] .. " (Inst)"
                        diffColor = "|cffcccccc"
                    elseif dl:find("instanced") then
                        diffTag = diffLabel
                        diffColor = "|cffff8800"
                    elseif dl:find("open world") then
                        diffTag = L["diff_normal"]
                        diffColor = "|cffcccccc"
                    else
                        diffTag = diffLabel
                        diffColor = "|cffcccccc"
                    end
                elseif record.isMythic then
                    diffTag = L["diff_mythic"]
                    diffColor = "|cffff44ff"
                elseif record.isHeroic then
                    diffTag = L["diff_heroic"]
                    diffColor = "|cff44cc44"
                elseif record.category == "DUNGEON" or record.category == "RAID" or record.category == "WORLD_BOSS" then
                    diffTag = L["diff_normal"]
                    diffColor = "|cffcccccc"
                end
                local dungeonDisplay = record.dungeon
                if diffTag and diffTag ~= "" then
                    dungeonDisplay = dungeonDisplay .. " " .. diffColor .. "[" .. diffTag .. "]|r"
                end
                poolRow.dungeonText:SetText(dungeonDisplay)
            else
                poolRow.dungeonText:SetText("")
            end
            poolRow.msgText:SetText(LFG.ShortenMessage(record.message) or "")
            local timeSinceForTooltip = timeSince
            poolRow.tooltipFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 10)
                GameTooltip:SetText("|cFFFFFF00" .. (record.player or "Unknown") .. "|r", 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cFF00FF00Full Message:|r", 0, 1, 0)
                GameTooltip:AddLine(record.message or "", 1, 1, 1, true)
                GameTooltip:AddLine(" ")
                if roleFullStr and roleFullStr ~= "" then
                    GameTooltip:AddLine("|cFF88CCFFLooking for:|r " .. roleFullStr, 0.9, 0.85, 0.4)
                end
                GameTooltip:AddLine("|cFF88CCFFTime:|r " .. string.format("%ds ago", timeSinceForTooltip), 0.8, 0.8, 0.8)
                if record.dungeon and record.dungeon ~= "MISC" then
                    GameTooltip:AddLine("|cFF88CCFFDungeon:|r " .. record.dungeon, 0.8, 0.8, 0.8)
                end
                GameTooltip:AddLine("|cFF88CCFFCategory:|r " .. record.category, 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            poolRow.tooltipFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            poolRow.frame:Show()
        end
    end
    for idx = totalFiltered + 1, #rowPool do
        if rowPool[idx] then
            rowPool[idx].frame:Hide()
            rowPool[idx].currentRecord = nil
        end
    end
    if totalFiltered == 0 then
        if LFG.noRecruitersText then
            LFG.noRecruitersText:Show()
        end
    end
end

function LFG.ChangeCategory(category)
    LFG.CurrentCategory = category
    LFG.DifficultyFilter = nil
    if LFG.recruitersScrollFrame then
        LFG.recruitersScrollFrame:SetVerticalScroll(0)
    end
    CloseAllDropdowns()
    if LFG.lfgTabs then
        for cat, tab in pairs(LFG.lfgTabs) do
            if tab and tab.text then
                if cat == category then
                    tab.bg:SetColorTexture(unpack(_tc("bgTabActive")))
                    tab.text:SetTextColor(unpack(_tc("textPrimary")))
                else
                    tab.bg:SetColorTexture(unpack(_tc("bgTabInactive")))
                    tab.text:SetTextColor(unpack(_tc("textNorm")))
                end
            end
        end
    end
    if LFG.UpdateDiffFilterVisibility then LFG.UpdateDiffFilterVisibility() end
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

function LFG:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local CW = math.max(700, (parentFrame:GetWidth() or 800) - 20)
    local IW = CW - 20

    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(CW, 500)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.mainContainer:EnableMouse(true)
    self.mainContainer:SetScript("OnMouseDown", function()
        CloseAllDropdowns()
    end)
    self.playerFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.playerFrame:SetSize(IW, 35)
    self.playerFrame:SetPoint("TOP", self.mainContainer, "TOP", 0, -5)
    local playerBg = self.playerFrame:CreateTexture(nil, "BACKGROUND")
    playerBg:SetPoint("TOPLEFT", 1, -1)
    playerBg:SetPoint("BOTTOMRIGHT", -1, 1)
    playerBg:SetColorTexture(unpack(_tc("bgSection")))
    local playerBorder = self.playerFrame:CreateTexture(nil, "BORDER")
    playerBorder:SetPoint("TOPLEFT", 0, 0)
    playerBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    playerBorder:SetColorTexture(unpack(_tc("borderInput")))
    local playerAccent = self.playerFrame:CreateTexture(nil, "OVERLAY")
    playerAccent:SetPoint("BOTTOMLEFT", 2, 0)
    playerAccent:SetPoint("BOTTOMRIGHT", -2, 0)
    playerAccent:SetHeight(1.5)
    playerAccent:SetColorTexture(unpack(_tc("accentBar")))
    self.playerInfoText = self.playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.playerInfoText:SetPoint("LEFT", self.playerFrame, "LEFT", 10, 0)
    self.playerInfoText:SetText(L["loading"])
    self.playerInfoText:SetTextColor(unpack(_tc("textPrimary")))
    local toggleWidth, toggleHeight = 40, 22
    local knobSize = 18
    local lfgToggle = CreateFrame("Button", nil, self.playerFrame)
    lfgToggle:SetSize(toggleWidth, toggleHeight)
    lfgToggle:SetPoint("RIGHT", self.playerFrame, "RIGHT", 0, -35)
    lfgToggle.track = lfgToggle:CreateTexture(nil, "BACKGROUND")
    lfgToggle.track:SetAllPoints()
    lfgToggle.track:SetColorTexture(unpack(_tc("bgToggleOff")))
    lfgToggle.trackBorder = lfgToggle:CreateTexture(nil, "BORDER")
    lfgToggle.trackBorder:SetPoint("TOPLEFT", -1, 1)
    lfgToggle.trackBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    lfgToggle.trackBorder:SetColorTexture(unpack(_tc("border")))
    lfgToggle.knob = lfgToggle:CreateTexture(nil, "OVERLAY")
    lfgToggle.knob:SetSize(knobSize, knobSize)
    lfgToggle.knob:SetPoint("CENTER", lfgToggle, "LEFT", knobSize / 2, 0)
    lfgToggle.knob:SetColorTexture(1, 1, 1, 1)
    local lfgToggleLabel = self.playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lfgToggleLabel:SetPoint("RIGHT", lfgToggle, "LEFT", -6, 0)
    lfgToggleLabel:SetText("LFG:")
    lfgToggleLabel:SetTextColor(unpack(_tc("textMuted")))
    local function UpdateToggleVisual(isOn)
        if isOn then
            lfgToggle.track:SetColorTexture(unpack(_tc("bgToggleOn")))
            lfgToggle.knob:ClearAllPoints()
            lfgToggle.knob:SetPoint("CENTER", lfgToggle, "RIGHT", -knobSize / 2, 0)
            lfgToggleLabel:SetTextColor(unpack(_tc("success")))
        else
            lfgToggle.track:SetColorTexture(unpack(_tc("bgToggleOff")))
            lfgToggle.knob:ClearAllPoints()
            lfgToggle.knob:SetPoint("CENTER", lfgToggle, "LEFT", knobSize / 2, 0)
            lfgToggleLabel:SetTextColor(unpack(_tc("danger")))
        end
    end
    local isLFGEnabled = not FrostSeekDB.LFG.disableLFG
    UpdateToggleVisual(isLFGEnabled)
    lfgToggle:SetScript("OnClick", function()
        FrostSeekDB.LFG.disableLFG = not FrostSeekDB.LFG.disableLFG
        local nowOn = not FrostSeekDB.LFG.disableLFG
        UpdateToggleVisual(nowOn)
        if nowOn then
            print("|cff88ccffFrostSeek:|r LFG |cff33cc33enabled|r")
        else
            print("|cff88ccffFrostSeek:|r LFG |cffff4444disabled|r")
        end
    end)
    lfgToggle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["lfg_toggle"], 0.8, 0.9, 1)
        if FrostSeekDB.LFG.disableLFG then
            GameTooltip:AddLine(L["lfg_currently_disabled"], 1, 1, 1)
            GameTooltip:AddLine(L["lfg_click_enable"], 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(L["lfg_currently_enabled"], 1, 1, 1)
            GameTooltip:AddLine(L["lfg_click_disable"], 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    lfgToggle:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    LFG.lfgToggle = lfgToggle
    LFG.UpdateToggleVisual = UpdateToggleVisual
    local roleLabel = self.playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleLabel:SetPoint("RIGHT", self.playerFrame, "RIGHT", -100, 0)
    roleLabel:SetText(L["lfg_role"] .. ":")
    roleLabel:SetTextColor(unpack(_tc("textMuted")))
    self.roleDropdown = FrostSeekUIUtils.CreateModernDropdown(self.playerFrame, 95, 22)
    self.roleDropdown:SetPoint("LEFT", roleLabel, "RIGHT", 0, 0)
    self.roleDropdown:SetOptions({L["none"], "Tank", "Healer", "DPS", "Support"})
    local savedRole = FrostSeekDB.LFG and (FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole or L["none"]) or L["none"]
    self.roleDropdown:SetText(savedRole)
    self.roleDropdown.selectedValue = savedRole
    self.roleDropdown.onChange = function(val)
        LFG.SetRole(val)
    end
    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("TOP", self.playerFrame, "BOTTOM", 0, -8)
    self.title:SetText("|cff88ccff" .. L["lfg_title"] .. "|r")
    self.title:SetTextColor(unpack(_tc("textAccent")))
    local filterBtn = CreateFrame("Button", "FrostSeekLFGFilterBtn", self.mainContainer)
    filterBtn:SetSize(18, 18)
    filterBtn:SetPoint("LEFT", self.title, "RIGHT", 10, 0)
    filterBtn.icon = filterBtn:CreateTexture(nil, "ARTWORK")
    filterBtn.icon:SetAllPoints()
    filterBtn.icon:SetTexture("Interface\\AddOns\\FrostSeek\\Media\\texture\\bottoni\\filtri.tga")
    filterBtn.icon:SetTexCoord(0, 1, 0, 1)
    filterBtn.bg = filterBtn:CreateTexture(nil, "BACKGROUND")
    filterBtn.bg:SetPoint("TOPLEFT", -2, 2)
    filterBtn.bg:SetPoint("BOTTOMRIGHT", 2, -2)
    filterBtn.bg:SetColorTexture(unpack(_tc("bgSection")))
    filterBtn.border = filterBtn:CreateTexture(nil, "BORDER")
    filterBtn.border:SetPoint("TOPLEFT", -1, 1)
    filterBtn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    filterBtn.border:SetColorTexture(unpack(_tc("accentBar")))
    local function UpdateFilterIconState()
        if not FrostSeekDB.LFG.activityFilter then return end
        local unchecked = 0
        for _, entry in ipairs(ACTIVITY_FILTER_GROUPS) do
            if not entry.isHeader and entry.id then
                if FrostSeekDB.LFG.activityFilter[entry.id] == false then
                    unchecked = unchecked + 1
                end
            end
        end
        if unchecked > 0 then
            filterBtn.border:SetColorTexture(unpack(_tc("borderHover")))
            filterBtn.bg:SetColorTexture(unpack(_tc("bgInput")))
        else
            filterBtn.border:SetColorTexture(unpack(_tc("accentBar")))
            filterBtn.bg:SetColorTexture(unpack(_tc("bgSection")))
        end
    end
    UpdateFilterIconState()
    filterBtn:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(unpack(_tc("borderHover")))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["tooltip_activity_filter"], 0.8, 0.9, 1)
        GameTooltip:AddLine(L["tooltip_activity_filter_desc"], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    filterBtn:SetScript("OnLeave", function(self)
        UpdateFilterIconState()
        GameTooltip:Hide()
    end)
    filterBtn:SetScript("OnClick", function()
        if _G.ShowOptionsWindow then
            _G.ShowOptionsWindow()
            if _G.SwitchSettingsCategory then
                _G.SwitchSettingsCategory("activityfilter")
            end
        end
    end)
    LFG.filterBtn = filterBtn
    LFG.UpdateFilterIconState = UpdateFilterIconState
    self.lfgCountText = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.lfgCountText:SetPoint("TOP", self.title, "BOTTOM", 0, -4)
    self.lfgCountText:SetText(string.format(L["lfg_active_recruiters"], 0))
    self.lfgCountText:SetTextColor(unpack(_tc("textAccent")))

    self.modeFilterFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.modeFilterFrame:SetSize(IW, 26)
    self.modeFilterFrame:SetPoint("TOP", self.lfgCountText, "BOTTOM", 0, -4)
    local modeLabel = self.modeFilterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("LEFT", self.modeFilterFrame, "LEFT", 10, 0)
    modeLabel:SetText(L["search_mode_label"] or "Mode:")
    modeLabel:SetTextColor(unpack(_tc("textNorm")))
    LFG.modeDropdown = FrostSeekUIUtils.CreateModernDropdown(self.modeFilterFrame, 110, 20)
    LFG.modeDropdown:SetPoint("LEFT", modeLabel, "RIGHT", 8, 0)
    LFG.modeDropdown:SetText("All")
    LFG.modeDropdown.selectedValue = "ALL"
    LFG.modeDropdown:SetOptions({"All", "LFG", "LFM"})
    LFG.ModeFilter = "ALL"
    LFG.modeDropdown.onChange = function(value)
        if value == "All" then
            LFG.ModeFilter = "ALL"
        else
            LFG.ModeFilter = value
        end
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end

    self.searchFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.searchFrame:SetSize(IW, 26)
    self.searchFrame:SetPoint("TOP", self.modeFilterFrame, "BOTTOM", 0, -4)
    local searchLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", self.searchFrame, "LEFT", 10, 0)
    searchLabel:SetText(L["search"] .. ":")
    searchLabel:SetTextColor(unpack(_tc("textNorm")))
    self.lfgSearchBox = FrostSeekUIUtils.CreateModernEditBox(self.searchFrame, 300, 18)
    self.lfgSearchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    self.lfgSearchBox:SetText("")
    self.lfgSearchBox:SetScript("OnTextChanged", function(self)
        lfgSearchText = self:GetText()
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if lfgSearchDebounce and lfgSearchDebounce.Cancel then lfgSearchDebounce:Cancel() end
        lfgSearchDebounce = C_Timer.After(0.25, function()
            LFG.UpdateRecruitersList()
        end)
    end)
    local clearSearchBtn = FrostSeekUIUtils.CreateModernButton(self.searchFrame, 45, 18, L["clear"], _tc("border"))
    clearSearchBtn:SetPoint("LEFT", self.lfgSearchBox, "RIGHT", 5, 0)
    clearSearchBtn:SetScript("OnClick", function()
        self.lfgSearchBox:SetText("")
        lfgSearchText = ""
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if lfgSearchDebounce and lfgSearchDebounce.Cancel then lfgSearchDebounce:Cancel() end
        LFG.UpdateRecruitersList()
    end)

    self.diffFilterButtons = {}
    local allDiffLabels = {"All", "Normal", "Heroic", "HC", "Mythic", "Ascended", "Trial", "Leveling", "Farm", "ALVA"}
    for _, label in ipairs(allDiffLabels) do
        local btn = FrostSeekUIUtils.CreateModernButton(self.searchFrame, 55, 18, label, _tc("border"))
        btn:Hide()
        btn.label = label
        btn:SetScript("OnClick", function()
            if label == "All" then
                LFG.DifficultyFilter = nil
            else
                if LFG.DifficultyFilter == label then
                    LFG.DifficultyFilter = nil
                else
                    LFG.DifficultyFilter = label
                end
            end
            LFG.UpdateDiffFilterVisuals()
            LFG.UpdateRecruitersList()
        end)
        btn:SetScript("OnEnter", function(self)
            LFG.UpdateDiffFilterVisuals(label)
        end)
        btn:SetScript("OnLeave", function(self)
            LFG.UpdateDiffFilterVisuals()
        end)
        self.diffFilterButtons[label] = btn
    end

    function LFG.UpdateDiffFilterVisibility()
        local cat = LFG.CurrentCategory or "ALL"
        local filters = DIFFICULTY_FILTERS[cat]
        for _, btn in pairs(self.diffFilterButtons) do btn:Hide() end
        if filters then
            local anchor = clearSearchBtn
            local allBtn = self.diffFilterButtons["All"]
            if allBtn then
                allBtn:ClearAllPoints()
                allBtn:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
                allBtn:Show()
                anchor = allBtn
            end
            for _, f in ipairs(filters) do
                local btn = self.diffFilterButtons[f.label]
                if btn then
                    btn:ClearAllPoints()
                    btn:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
                    btn:Show()
                    anchor = btn
                end
            end
        end
        LFG.UpdateDiffFilterVisuals()
    end

    function LFG.UpdateDiffFilterVisuals(hovered)
        local active = LFG.DifficultyFilter
        local cat = LFG.CurrentCategory or "ALL"
        local accent = CATEGORY_ACCENT[cat] or {0.5, 0.5, 0.5}
        for label, btn in pairs(self.diffFilterButtons) do
            if not btn.text then btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") btn.text:SetPoint("CENTER") btn.text:SetText(label) end
            local isHovered = (label == hovered)
            if label == "All" then
                if not active then
                    local m = isHovered and 0.75 or 0.55
                    if btn.bg then btn.bg:SetColorTexture(accent[1] * m, accent[2] * m, accent[3] * m, 0.95) end
                    if btn.border then btn.border:SetColorTexture(min(accent[1] * 1.3, 1), min(accent[2] * 1.3, 1), min(accent[3] * 1.3, 1), 1) end
                    if btn.text then btn.text:SetTextColor(1, 1, 1) end
                else
                    if btn.bg then
                        if isHovered then
                            btn.bg:SetColorTexture(accent[1] * 0.3, accent[2] * 0.3, accent[3] * 0.3, 0.7)
                        else
                            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
                        end
                    end
                    if btn.border then
                        if isHovered then
                            btn.border:SetColorTexture(accent[1] * 0.6, accent[2] * 0.6, accent[3] * 0.6, 0.9)
                        else
                            btn.border:SetColorTexture(unpack(_tc("border")))
                        end
                    end
                    if btn.text then btn.text:SetTextColor(isHovered and 1 or unpack(_tc("textMuted"))) end
                end
            elseif label == active then
                local m = isHovered and 1.0 or 0.85
                if btn.bg then btn.bg:SetColorTexture(accent[1] * m, accent[2] * m, accent[3] * m, m) end
                if btn.border then btn.border:SetColorTexture(min(accent[1] * 1.5, 1), min(accent[2] * 1.5, 1), min(accent[3] * 1.5, 1), 1) end
                if btn.text then btn.text:SetTextColor(1, 1, 1) end
            else
                if btn.bg then
                    if isHovered then
                        btn.bg:SetColorTexture(accent[1] * 0.25, accent[2] * 0.25, accent[3] * 0.25, 0.7)
                    else
                        btn.bg:SetColorTexture(unpack(_tc("bgButton")))
                    end
                end
                if btn.border then
                    if isHovered then
                        btn.border:SetColorTexture(accent[1] * 0.5, accent[2] * 0.5, accent[3] * 0.5, 0.85)
                    else
                        btn.border:SetColorTexture(unpack(_tc("border")))
                    end
                end
                if btn.text then btn.text:SetTextColor(isHovered and 1 or unpack(_tc("textMuted"))) end
            end
        end
    end
    self.recruitersFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.recruitersFrame:SetSize(IW, 360)
    self.recruitersFrame:SetPoint("TOP", self.searchFrame, "BOTTOM", 0, -8)
    local recruitersBg = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    recruitersBg:SetAllPoints()
    recruitersBg:SetColorTexture(unpack(_tc("bgRowOdd")))
    self.lfgTabs = {}
    local lfgTabTypes = {"ALL", "DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE"}
    local lfgTabNames = {"All", L["col_dungeon"], "Raid", "WBoss", "PvP", "Mana", "Key"}
    for i, tabName in ipairs(lfgTabNames) do
        local tab = CreateFrame("Button", nil, self.recruitersFrame)
        tab:SetSize(70, 22)
        tab:SetPoint("TOPLEFT", self.recruitersFrame, "TOPLEFT", 5 + ((i-1) * 75), -8)
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(unpack(_tc("bgTabInactive")))
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(tabName)
        tab.text:SetTextColor(unpack(_tc("textPrimary")))
        tab:SetScript("OnClick", function()
            LFG.ChangeCategory(lfgTabTypes[i])
        end)
        tab:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        end)
        tab:SetScript("OnLeave", function(self)
            if lfgTabTypes[i] == LFG.CurrentCategory then
                self.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            else
                self.bg:SetColorTexture(unpack(_tc("bgTabInactive")))
            end
        end)
        self.lfgTabs[lfgTabTypes[i]] = tab
    end
    local headerFrame = CreateFrame("Frame", nil, self.recruitersFrame)
    headerFrame:SetSize(IW, 18)
    headerFrame:SetPoint("TOPRIGHT", self.recruitersFrame, "TOPRIGHT", -24, -40)
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 18, 0)
    nameHeader:SetText(L["col_player"])
    nameHeader:SetTextColor(unpack(_tc("textAccent")))
    local timeHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeHeader:SetPoint("LEFT", headerFrame, "LEFT", 108, 0)
    timeHeader:SetText(L["col_time"])
    timeHeader:SetTextColor(unpack(_tc("textAccent")))
    local catHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catHeader:SetPoint("LEFT", headerFrame, "LEFT", 158, 0)
    catHeader:SetText(L["col_type"])
    catHeader:SetTextColor(unpack(_tc("textAccent")))
    local roleHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleHeader:SetPoint("LEFT", headerFrame, "LEFT", 192, 0)
    roleHeader:SetText(L["col_role"])
    roleHeader:SetTextColor(unpack(_tc("textAccent")))
    local dungeonHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonHeader:SetPoint("LEFT", headerFrame, "LEFT", 266, 0)
    dungeonHeader:SetText(L["col_dungeon"])
    dungeonHeader:SetTextColor(unpack(_tc("textAccent")))
    local msgHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgHeader:SetPoint("LEFT", headerFrame, "LEFT", 350, 0)
    msgHeader:SetText(L["col_message"])
    msgHeader:SetTextColor(unpack(_tc("textAccent")))
    local acceptHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    acceptHeader:SetPoint("RIGHT", headerFrame, "RIGHT", -10, 0)
    acceptHeader:SetText(L["col_action"])
    acceptHeader:SetTextColor(unpack(_tc("textAccent")))
    local separator = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    separator:SetPoint("TOP", headerFrame, "BOTTOM", 0, -2)
    separator:SetSize(IW, 1)
    separator:SetColorTexture(unpack(_tc("separator")))
    local LIST_HEIGHT = 260
    MAX_DISPLAY_ROWS = math.floor(LIST_HEIGHT / ROW_HEIGHT)
    self.recruitersList = CreateFrame("Frame", nil, self.recruitersFrame)
    self.recruitersList:SetSize(IW, LIST_HEIGHT)
    self.recruitersList:SetPoint("TOP", headerFrame, "BOTTOM", 0, -8)
    self.recruitersList:SetPoint("RIGHT", self.recruitersFrame, "RIGHT", -24, 0)

    self.recruitersScrollFrame = CreateFrame("ScrollFrame", "FrostSeekRecruitersScroll", self.recruitersFrame, "UIPanelScrollFrameTemplate")
    self.recruitersScrollFrame:SetPoint("TOPLEFT", self.recruitersList, "TOPLEFT", 0, 0)
    self.recruitersScrollFrame:SetPoint("BOTTOMRIGHT", self.recruitersList, "BOTTOMRIGHT", 0, 0)

    local scrollChild = CreateFrame("Frame", nil, self.recruitersScrollFrame)
    scrollChild:SetSize(IW, LIST_HEIGHT)
    self.recruitersScrollFrame:SetScrollChild(scrollChild)
    self.recruitersList.scrollChild = scrollChild

    self.recruitersList.rows = {}
    LFG.noRecruitersText = self.recruitersList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    LFG.noRecruitersText:SetPoint("CENTER", self.recruitersList, "CENTER", 0, 0)
    LFG.noRecruitersText:SetText(L["lfg_no_recruiters"])
    LFG.noRecruitersText:SetTextColor(unpack(_tc("textDim")))
    LFG.noRecruitersText:Hide()
    LFG.InitRowPool(scrollChild)
    local scrollInfoFrame = CreateFrame("Frame", nil, self.recruitersFrame)
    scrollInfoFrame:SetPoint("TOPLEFT", self.recruitersList, "BOTTOMLEFT", 0, -4)
    scrollInfoFrame:SetPoint("BOTTOMRIGHT", self.recruitersList, "BOTTOMRIGHT", 20, -10)
    self.scrollIndicator = scrollInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.scrollIndicator:SetPoint("CENTER", scrollInfoFrame, "CENTER", 0, 0)
    self.scrollIndicator:SetText("")
    self.scrollIndicator:SetTextColor(unpack(_tc("textDim")))
    self.controlsFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.controlsFrame:SetSize(IW, 30)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 5)
    self.refreshBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 70, 22, L["refresh"], _tc("primary"))
    self.refreshBtn:SetPoint("LEFT", self.controlsFrame, "LEFT", 10, -30)
    self.refreshBtn:SetScript("OnClick", function()
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    self.clearAllBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 70, 22, L["clear_all"], _tc("catPvP"))
    self.clearAllBtn:SetPoint("LEFT", self.refreshBtn, "RIGHT", 5, 0)
    self.clearAllBtn:SetScript("OnClick", function()
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog(L["clear_all"], "Clear all active LFG searches?", function()
                LFG.ClearAllSearches()
            end)
        else
            LFG.ClearAllSearches()
        end
    end)
    self.frostnetBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 100, 22, L["frostnet_title"], _tc("accent"))
    self.frostnetBtn:SetPoint("LEFT", self.clearAllBtn, "RIGHT", 10, 0)
    self.frostnetBtn:SetScript("OnClick", function()
        if FrostSeek.Presence then
            FrostSeek.Presence:TogglePanel(FrostSeek.MainFrame)
        end
    end)
    LFG.CurrentCategory = "ALL"
    LFG.ChangeCategory("ALL")
    LFG.UpdatePlayerInfo()
    LFG.UpdateRecruitersList()
    self.frame:Hide()
end

function LFG:Show()
    if not self.frame then return end
    LFG.UpdatePlayerInfo()
    LFG.UpdateRecruitersList()
    self.frame:Show()
end

function LFG:Hide()
    CloseAllDropdowns()
    if self.frame then self.frame:Hide() end
end

function LFG:RefreshData()
    LFG.UpdateRecruitersList()
end

function LFG:GetActiveRecruiterCount()
    return activeSearches and #activeSearches or 0
end

local CHANNEL_BLACKLIST = {
    ["LFG"] = true,
    [" LFG"] = true,
    ["FSK"] = true,
    ["BLFG"] = true,
    ["BBLC25C"] = true,
    ["FSK-EVT"] = true,

}

local function IsAddonProtocolMessage(msg)
    if not msg or type(msg) ~= "string" then return true end
    if string.match(msg, "^FSK%d~") then
        return true
    end
    if string.match(msg, "^BLFG%d~") then
        return true
    end
    if string.match(msg, "^LC[123]") then
        return true
    end
    if string.match(msg, "^[A-Z][A-Z]%d+[~:]") then
        return true
    end
    local sepCount = 0
    for _ in string.gmatch(msg, "~") do sepCount = sepCount + 1 end
    if sepCount >= 3 then
        return true
    end
    if not string.find(msg, " ", 1, true) and string.len(msg) > 40 then
        return true
    end
    local _, colonCount = string.gsub(msg, ":", "")
    if colonCount < 2 then return false end
    return string.match(msg, "^[Ll][Ff][Gg]:")
        or string.match(msg, "^[Ll][Ff][Mm]:")
        or string.match(msg, "^%[[Ll][Ff][Gg]%]:")
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
EventFrame:RegisterEvent("CHAT_MSG_SAY")
EventFrame:RegisterEvent("CHAT_MSG_YELL")
EventFrame:RegisterEvent("CHAT_MSG_GUILD")
EventFrame:RegisterEvent("CHAT_MSG_OFFICER")
EventFrame:RegisterEvent("CHAT_MSG_RAID")
EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
EventFrame:RegisterEvent("CHAT_MSG_PARTY")
EventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")

EventFrame:SetScript("OnEvent", function(self, event, message, sender, language, channelName, ...)
    if FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG then return end
    if not message or not sender then return end
    sender = string.gsub(sender, "%-[^|]+", "")
    if sender == UnitName("player") then return end
    if IsAddonProtocolMessage(message) then return end
    local channel = event
    if event == "CHAT_MSG_CHANNEL" then
        local cleanName = channelName and string.match(channelName, "^%s*(.-)%s*$") or ""
        if CHANNEL_BLACKLIST[cleanName] then return end
        local chNum = select(9, ...)
        if chNum then
            local n = GetChannelName(chNum)
            if n then
                n = string.match(n, "^%s*(.-)%s*$") or ""
                if CHANNEL_BLACKLIST[n] then return end
            end
        end
        local chIdx = select(8, ...)
        if chIdx then
            local n = GetChannelName(chIdx)
            if n then
                n = string.match(n, "^%s*(.-)%s*$") or ""
                if CHANNEL_BLACKLIST[n] then return end
            end
        end
        channel = cleanName or "CHANNEL"
    end
    if LFG.IsLFMMessage(message) then
        LFG.RecordActiveSearch(sender, message, channel)
    end
end)

local function InitializeLFGSystem()
    activeSearches = activeSearches or {}
    openFrames = openFrames or {}
    ignoreList = ignoreList or {}
    spammerList = spammerList or {}
    lastPopupTimes = lastPopupTimes or {}
    sessionStartTime = GetTime()
    FrostSeekDB.LFG = FrostSeekDB.LFG or {}
    FrostSeekDB.LFG.myRole = FrostSeekDB.LFG.myRole or L["none"]
    FrostSeekDB.LFG.popupCategories = FrostSeekDB.LFG.popupCategories or {
        ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true, PVP = true, MANASTORM = true, KEYSTONE = true, MISC = false
    }
    if FrostSeekDB.LFG.popupModeFilter == nil then FrostSeekDB.LFG.popupModeFilter = "LFM" end

    if FrostSeekDB.LFG.popupCategories.CUSTOM ~= nil then
        FrostSeekDB.LFG.popupCategories.CUSTOM = nil
    end
    if FrostSeekDB.LFG.popupCategories.RDF ~= nil then
        FrostSeekDB.LFG.popupCategories.RDF = nil
    end
    if not FrostSeekDB.LFG.activityFilter then
        FrostSeekDB.LFG.activityFilter = {}
    end
    for _, entry in ipairs(ACTIVITY_FILTER_GROUPS) do
        if not entry.isHeader and entry.id then
            if FrostSeekDB.LFG.activityFilter[entry.id] == nil then
                FrostSeekDB.LFG.activityFilter[entry.id] = true
            end
        end
    end
    FrostSeekDB.LFG.filterWords = FrostSeekDB.LFG.filterWords or "boost,carry,wts,wtb,buy,sell,gold,account"
    FrostSeekDB.LFG.customFilterWords = FrostSeekDB.LFG.customFilterWords or ""
    FrostSeekDB.LFG.showActiveRecruitersWindow = false
    FrostSeekDB.LFG.maxMessageLength = FrostSeekDB.LFG.maxMessageLength or 150
    FrostSeekDB.LFG.frameDuration = FrostSeekDB.LFG.frameDuration or 5
    FrostSeekDB.LFG.popupCooldown = FrostSeekDB.LFG.popupCooldown or 370
    FrostSeekDB.LFG.maxConcurrentPopups = FrostSeekDB.LFG.maxConcurrentPopups or 2
    FrostSeekDB.LFG.soundEnabled = FrostSeekDB.LFG.soundEnabled ~= false
    C_Timer.NewTicker(10, LFG.CleanupActiveSearches)
    print("|cff88ccffFrostSeek LFG:|r System initialized")
end

C_Timer.After(2, InitializeLFGSystem)

SLASH_FSDEBUGTOGGLE1 = "/fsdebugtoggle"
SlashCmdList["FSDEBUGTOGGLE"] = function()
    FrostSeekDB.Settings.debugMode = not FrostSeekDB.Settings.debugMode
    print("|cff88ccffFrostSeek:|r Debug mode " .. (FrostSeekDB.Settings.debugMode and "enabled" or "disabled"))
end

local function sortKeywordsByLength(tbl)
    table.sort(tbl, function(a, b) return string.len(a) > string.len(b) end)
end

sortKeywordsByLength(RAID_KEYWORDS)
sortKeywordsByLength(WORLD_BOSS_KEYWORDS)
sortKeywordsByLength(PVP_KEYWORDS)
sortKeywordsByLength(MANASTORM_KEYWORDS)
sortKeywordsByLength(DUNGEON_KEYWORDS)

function LFG:ApplyTheme()
    if self.UpdateRecruitersList then
        self:UpdateRecruitersList()
    end
    if self.frame and self.frame:IsShown() then
        if self.RefreshList then self:RefreshList() end
    end
    if self.refreshBtn then
        local primaryC = _tc("primary")
        self.refreshBtn.color = primaryC
        self.refreshBtn.text:SetTextColor(min(primaryC[1] * 1.2, 1), min(primaryC[2] * 1.2, 1), min(primaryC[3] * 1.2, 1))
        self.refreshBtn.bg:SetColorTexture(primaryC[1] * 0.25, primaryC[2] * 0.25, primaryC[3] * 0.25, 0.8)
        self.refreshBtn.border:SetColorTexture(primaryC[1] * 0.5, primaryC[2] * 0.5, primaryC[3] * 0.5, 0.7)
        self.refreshBtn.accent:SetColorTexture(primaryC[1], primaryC[2], primaryC[3], 0.4)
    end
    if self.clearAllBtn then
        local dangerC = _tc("catPvP")
        self.clearAllBtn.color = dangerC
        self.clearAllBtn.text:SetTextColor(min(dangerC[1] * 1.2, 1), min(dangerC[2] * 1.2, 1), min(dangerC[3] * 1.2, 1))
        self.clearAllBtn.bg:SetColorTexture(dangerC[1] * 0.25, dangerC[2] * 0.25, dangerC[3] * 0.25, 0.8)
        self.clearAllBtn.border:SetColorTexture(dangerC[1] * 0.5, dangerC[2] * 0.5, dangerC[3] * 0.5, 0.7)
        self.clearAllBtn.accent:SetColorTexture(dangerC[1], dangerC[2], dangerC[3], 0.4)
    end
    if self.frostnetBtn then
        local accentC = _tc("accent")
        self.frostnetBtn.color = accentC
        self.frostnetBtn.text:SetTextColor(min(accentC[1] * 1.2, 1), min(accentC[2] * 1.2, 1), min(accentC[3] * 1.2, 1))
        self.frostnetBtn.bg:SetColorTexture(accentC[1] * 0.25, accentC[2] * 0.25, accentC[3] * 0.25, 0.8)
        self.frostnetBtn.border:SetColorTexture(accentC[1] * 0.5, accentC[2] * 0.5, accentC[3] * 0.5, 0.7)
        self.frostnetBtn.accent:SetColorTexture(accentC[1], accentC[2], accentC[3], 0.4)
    end
end

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("lfg", LFG)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("lfg")
end
