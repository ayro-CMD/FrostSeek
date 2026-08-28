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

local LFG = _G.FrostSeek and (_G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg or _G.FrostSeek.LFG)
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg_data", LFG)

local L = FrostSeek.L
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end


local KEYSTONE_KEYWORDS = {
    "keystone",
}

local RAID_KEYWORDS = {
    "onyxia", "ony", "molten core", "mc", "blackwing lair", "bwl",
    "zul'gurub", "zg", "ruins of ahn'qiraj", "aq20", "temple of ahn'qiraj", "aq40",
    "naxxramas", "naxx", "karazhan", "kara", "gruul", "magtheridon", "mag",
    "serpentshrine cavern", "ssc", "tempest keep", "tk", "the eye",
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
    "icc10","icc25","icc10n","icc25n","icc10hc","icc25hc","rs25n","rs25hc","rs10n","rs25n",
    "the radiant spring","trs"
}

local WORLD_BOSS_KEYWORDS = {
    "soggoth", "sogoth", "azuregos", "kazzak", "doomwalker", "setis", "settis",
    "emeriss", "lethon", "taerar", "ysondre", "dream", "nightmare", "kaldros depthbreaker", "kaldros.depthbreaker", "kaldros",
    "snowgrave", "atal'zul", "atal.zul", "atal azul", "atal'azul", "world tour", "worldboss tour", "world boss tour",
    "sha of anger", "galleon", "salyis", "nalak", "oondasta", "celestials", "celestial","atalzul",
    "gonzor", "king gnok", "king mosh", "silithid lurker", "volchan", "corrupted ancient",
    "worldboss", "world boss", "wb",
}

local WORLD_BOSS_GENERIC_KEYWORDS = {
    "worldboss", "world boss", "wb",
}

local function IsGenericWorldBossKeyword(kw)
    for _, gkw in ipairs(WORLD_BOSS_GENERIC_KEYWORDS) do
        if kw == gkw then return true end
    end
    return false
end

local PVP_KEYWORDS = {
    "2v2", "2s", "3v3", "3s", "5v5", "5s", "arena", "bg", "battleground", "pvp",
    "wsg", "warsong", "ab", "arathi", "av", "alterac", "eots", "wg", "wintergrasp",
}

local MANASTORM_KEYWORDS = {
    "manastorm", "bonzo", "alva", "ms","manastorm goldfarm",
}

local DUNGEON_KEYWORDS = {
    "rfc", "ragefire", "ragefire chasm", "dm", "deadmines", "vc", "wc", "wailing", "wailing caverns",
    "sfk", "shadowfang", "shadowfang keep", "stocks", "stockade", "bfd", "blackfathom", "blackfathom deeps",
    "gnomer", "gnomeregan", "rfk", "razorfen kraul", "sm", "scarlet", "scarlet monastery", "gy", "lib", "arm", "cath",
    "rfd", "razorfen downs", "ulda", "uldaman", "zf", "zul'farrak", "mara", "maraudon","blackcock spire",
    "st", "sunken temple", "brd", "blackrock depths", "dire", "dire maul", "maul", "dme", "dmn", "dmw",
    "strat", "stratholme", "scholo", "scholomance", "lbrs", "lower blackrock spire", "ubrs", "upper blackrock spire",
    "ramps", "hellfire ramparts", "ramparts", "bf", "blood furnace", "sp", "slave pens", "ub", "underbog",
    "mt", "mana-tombs", "mana tombs", "ac", "auchenai crypts", "auchenai", "sh", "sethekk halls", "sethekk",
    "ohf", "old hillsbrad", "old hillsbrad foothills", "bm", "black morass", "the black morass",
    "mecha", "mechanar", "shh", "shattered halls", "the shattered halls", "bota", "botanica",
    "sl", "shadow labyrinth", "shadow lab", "slabs", "sv", "steamvault", "the steamvault",
    "arca", "arcatraz", "mgt", "magisters terrace", "magister's terrace",
    "uk", "utgarde keep", "up", "utgarde pinnacle", "pinnacle", "kcm",
    "nexus", "the nexus", "nex", "oculus", "the oculus", "ocu",
    "ak", "ahn'kahet", "azjol", "azjol-nerub", "dtk", "drak'tharon", "drak'tharon keep",
    "vh", "violet hold", "gun", "gundrak",
    "hos", "halls of stone", "hol", "halls of lightning",
    "cos", "culling", "culling of stratholme",
    "toc_d", "champion", "trial of the champion",
    "fos", "forge of souls", "forge", "pos", "pit of saron", "pit",
    "hor", "halls of reflection", "reflection",
    "brc", "blackrock caverns", "blackrock cavern", "tott", "throne of the tides", "naz'jar",
    "vp", "vortex pinnacle", "the vortex pinnacle", "sc", "stonecore",
    "lct", "lost city", "tol'vir", "lost city of tol'vir",
    "hoo", "halls of origination", "origination", "gb", "grim batol",
    "zg_cata", "zul'gurub", "za_cata", "zul'aman",
    "et", "end time", "woe", "well of eternity", "hot", "hour of twilight",
    "gmm", "glittermurk", "karazhan crypt", "glittermurk mines",
    "kc", "vault", "vaults", "vault of the inquisition", "vaults of inquisition",
    "roads", "road to de", "de' other side","temple of embers","toe","sbd",
    "tor'watha", "tor watha","voult of the inquisition","voult","shadowbone depths", "the temple of embers", "shadowbone",
    "tjs", "jade serpent", "temple of the jade serpent",
    "sb", "stormstout", "stormstout brewery", "brewery",
    "spm", "shado-pan", "shado-pan monastery",
    "msp", "mogu'shan palace", "mogushan palace",
    "scarlet halls", "siege of niuzao temple", "niuzao",
    "gss", "gate of the setting sun", "setting sun",
    "dg", "aura",
    "rdf", "lfd", "random dungeon", "random heroic", "rhc", "heroic random",
    "daily heroic", "daily dungeon", "graveyard",
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
    { header = "CLASSIC DUNGEONS", isHeader = true, level = 0 },
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

    { header = "CLASSIC RAIDS", isHeader = true, level = 0 },
    { id = "ONYXIA", name = "Onyxia", keywords = {"ONYXIA", "ONY"} },
    { id = "MC", name = "Molten Core", keywords = {"MC", "MOLTEN CORE"} },
    { id = "BWL", name = "Blackwing Lair", keywords = {"BWL", "BLACKWING LAIR", "BLACKWING"} },
    { id = "ZG", name = "Zul'Gurub", keywords = {"ZG", "ZUL'GURUB"} },
    { id = "AQ20", name = "Ruins of Ahn'Qiraj", keywords = {"AQ20", "RUINS", "RUINS OF AHN'QIRAJ"} },
    { id = "AQ40", name = "Temple of Ahn'Qiraj", keywords = {"AQ40", "TEMPLE", "TEMPLE OF AHN'QIRAJ"} },

    { header = "TBC DUNGEONS", isHeader = true, level = 1 },
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

    { header = "TBC RAIDS", isHeader = true, level = 1 },
    { id = "KARA", name = "Karazhan", keywords = {"KARA", "KARAZHAN"} },
    { id = "GRUUL", name = "Gruul's Lair", keywords = {"GRUUL"} },
    { id = "MAG", name = "Magtheridon", keywords = {"MAG", "MAGTHERIDON"} },
    { id = "SSC", name = "Serpentshrine Cavern", keywords = {"SSC", "SERPENTSHRINE", "SERPENTSHRINE CAVERN"} },
    { id = "TK", name = "Tempest Keep", keywords = {"TK", "TEMPEST", "TEMPEST KEEP"} },
    { id = "HYJAL", name = "Mount Hyjal", keywords = {"HYJAL", "MOUNT HYJAL", "THE BATTLE FOR MOUNT HYJAL"} },
    { id = "BT", name = "Black Temple", keywords = {"BT", "BLACK TEMPLE"} },
    { id = "ZA", name = "Zul'Aman", keywords = {"ZA", "ZUL'AMAN"} },
    { id = "SWP", name = "Sunwell Plateau", keywords = {"SWP", "SUNWELL", "SUNWELL PLATEAU"} },

    { header = "WOTLK DUNGEONS", isHeader = true, level = 2 },
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

    { header = "WOTLK RAIDS", isHeader = true, level = 2 },
    { id = "NAXX", name = "Naxxramas", keywords = {"NAXX", "NAXXRAMAS"} },
    { id = "VOA", name = "Vault of Archavon", keywords = {"VOA", "ARCHAVON", "VAULT OF ARCHAVON"} },
    { id = "OS", name = "Obsidian Sanctum", keywords = {"OS", "OBSIDIAN", "SARTH", "SARTHARION", "OBSIDIAN SANCTUM"} },
    { id = "EOE", name = "Eye of Eternity", keywords = {"EOE", "MALYGOS", "EYE OF ETERNITY", "THE EYE"} },
    { id = "ULD", name = "Ulduar", keywords = {"ULD", "ULDUAR", "ALGOLON"} },
    { id = "TOC", name = "Trial of the Crusader", keywords = {"TOC", "CRUSADER", "TRIAL OF THE CRUSADER"} },
    { id = "ICC", name = "Icecrown Citadel", keywords = {"ICC", "ICECROWN", "ICECROWN CITADEL", "LICH KING", "SINDRAGOSA", "BLOOD QUEEN", "PUTRICIDE", "ANUB'ARAK"} },
    { id = "RS", name = "Ruby Sanctum", keywords = {"RS", "RUBY", "HALION", "RUBY SANCTUM"} },

    { header = "CATA DUNGEONS", isHeader = true, level = 3 },
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

    { header = "CATA RAIDS", isHeader = true, level = 3 },
    { id = "BH", name = "Baradin Hold", keywords = {"BH", "BARADIN"} },
    { id = "BOT", name = "Bastion of Twilight", keywords = {"BOT", "BASTION", "TWILIGHT"} },
    { id = "T4W", name = "Throne of the Four Winds", keywords = {"T4W", "FOUR WINDS", "AL'AKIR"} },
    { id = "BWD", name = "Blackwing Descent", keywords = {"BWD", "BLACKWING DESCENT", "NEFARIAN"} },
    { id = "FL", name = "Firelands", keywords = {"FL", "FIRELANDS", "RAGNAROS"} },
    { id = "DS", name = "Dragon Soul", keywords = {"DS", "DRAGON SOUL", "DEATHWING"} },

    { header = "MoP DUNGEONS", isHeader = true, level = 4 },
    { id = "TJS", name = "Temple of the Jade Serpent", keywords = {"TJS", "JADE SERPENT"} },
    { id = "SB", name = "Stormstout Brewery", keywords = {"SB", "STORMSTOUT", "BREWERY"} },
    { id = "SPM", name = "Shado-Pan Monastery", keywords = {"SPM", "SHADO-PAN"} },
    { id = "MSP", name = "Mogu'shan Palace", keywords = {"MSP", "MOGUSHAN PALACE"} },
    { id = "SH_M", name = "Scarlet Halls", keywords = {"SCARLET HALLS"} },
    { id = "SM_M", name = "Scarlet Monastery (MoP)", keywords = {"SM", "SCARLET MONASTERY"} },
    { id = "SNT", name = "Siege of Niuzao Temple", keywords = {"NIUZAO", "SIEGE"} },
    { id = "GSS", name = "Gate of the Setting Sun", keywords = {"GSS", "SETTING SUN"} },
    { id = "SCHOLO_M", name = "Scholomance (MoP)", keywords = {"SCHOLO", "SCHOLOMANCE"} },

    { header = "MoP RAIDS", isHeader = true, level = 4 },
    { id = "MSV", name = "Mogu'shan Vaults", keywords = {"MSV", "MOGUSHAN VAULTS"} },
    { id = "HOF", name = "Heart of Fear", keywords = {"HOF", "HEART OF FEAR", "SHEK'ZEER"} },
    { id = "TOES", name = "Terrace of Endless Spring", keywords = {"TOES", "TERRACE", "ENDLESS SPRING"} },
    { id = "TOT", name = "Throne of Thunder", keywords = {"TOT", "THUNDER", "LEI SHEN"} },
    { id = "SOO", name = "Siege of Orgrimmar", keywords = {"SOO", "SIEGE", "ORGRIMMAR", "GARROSH"} },

    { header = "EPOCH DUNGEONS", isHeader = true, level = 0 },
    { id = "GMM", name = "Glittermurk Mines", keywords = {"GLITTERMURK", "GLITTEMURK", "GLITTERMURK MINES", "GLITTEMURK MINES"} },

    { header = "CUSTOM DUNGEONS", isHeader = true, level = 0 },
    { id = "BRC", name = "Blackrock Cavern", keywords = {"BRC", "BLACKROCK CAVERN"} },
    { id = "KC", name = "Karazhan Crypt", keywords = {"KC", "KARAZHAN CRYPT"} },
    { id = "VAULT", name = "Vault of the Inquisition", keywords = {"VAULT", "INQUISITION"} },
    { id = "ROADS", name = "Road to De' Other Side", keywords = {"ROADS", "ROAD TO DE' OTHER SIDE"} },
    { id = "BH", name = "Baradin Hold", keywords = {"BARADIN", "BARADIN HOLD"} },
    { id = "TW", name = "Tor'Watha", keywords = {"TOR'WATHA"} },
    { id = "EOE", name = "Temple of Embers", keywords = {"THE TEMPLE OF EMBERS"} },
    { id = "SD", name = "Shadowbone Depths", keywords = {"SHADOWBONE DEPTHS"} },

    { header = "CUSTOM RAIDS", isHeader = true, level = 0 },
    { id = "TRS", name = "The Radiant Spring", keywords = {"TRS", "radiant", "spring"} },


    { header = "WORLD BOSSES", isHeader = true, level = 0 },
    { id = "WB_GENERIC", name = "World Boss (generic wb)", keywords = {"WB", "WORLDBOSS", "WORLD BOSS"} },
    { id = "AZUREGOS", name = "Azuregos", keywords = {"AZUREGOS", "AZURE"} },
    { id = "KAZZAK", name = "Lord Kazzak", keywords = {"KAZZAK"} },
    { id = "DOOMWALKER", name = "Doomwalker", keywords = {"DOOMWALKER"} },
    { id = "EMERISS", name = "Emeriss", keywords = {"EMERISS"} },
    { id = "LETHON", name = "Lethon", keywords = {"LETHON"} },
    { id = "TAERAR", name = "Taerar", keywords = {"TAERAR"} },
    { id = "YSONDRE", name = "Ysondre", keywords = {"YSONDRE"} },
    { id = "SOGGOTH", name = "Soggoth", keywords = {"SOGGOTH", "SOGOTH"}, exp = 97 },
    { id = "SETIS", name = "Setis", keywords = {"SETIS", "SETTIS"}, exp = 0 },
    { id = "SNOWGRAVE", name = "Snowgrave", keywords = {"SNOWGRAVE"}, exp = 97 },
    { id = "ATALZUL", name = "Atal'Zul", keywords = {"ATAL'ZUL", "ATAL.ZUL", "ATAL AZUL", "ATAL'AZUL"}, exp = 97 },
    { id = "KALDROS", name = "Kaldros Depthbreaker", keywords = {"KALDROS", "KALDROS DEPTHBREAKER", "KALDROS.DEPTHBREAKER"}, exp = 97 },
    { id = "WBT", name = "World Boss Tour", keywords = {"WORLD TOUR", "WORLDBOSS TOUR", "WORLD BOSS TOUR"}, exp = 0 },
    { id = "DREAM", name = "Emerald Dream", keywords = {"EMERALD DREAM"}, exp = 0 },
    { id ="GONZOR", name = "Gonzor", keywords = {"Gonzor"}, exp = 98 },
    { id = "K.GNOK", name = "King Gnok", keywords = {"KING GNOK", "GNOK"}, exp = 98 },
    { id = "K.MOSH", name = "King Mosh", keywords = {"KING MOSH", "MOSH"}, exp = 98 },
    { id = "SILITHID LURKER", name = "Silithid Lurker", keywords = {"SILITHID LURKER", "SILITHID"}, exp = 98 },
    { id ="VOLCHAN",name = "Volchan", keywords = {"Volchan"}, exp = 98 },
    { id = "CORRUPTED ANCIENT", name = "Corrupted Ancient", keywords = {"CORRUPTED ANCIENT", "CORRUPTED"}, exp = 98 },

    { header = "MoP WORLD BOSSES", isHeader = true, level = 4 },
    { id = "SHA", name = "Sha of Anger", keywords = {"SHA", "ANGER", "SHA OF ANGER"} },
    { id = "GALLEON", name = "Galleon", keywords = {"GALLEON", "SALYIS"} },
    { id = "NALAK", name = "Nalak", keywords = {"NALAK"} },
    { id = "OONDASTA", name = "Oondasta", keywords = {"OONDASTA"} },
    { id = "CELESTIALS", name = "Celestials", keywords = {"CELESTIALS", "CELESTIAL"} },

    { header = "PVP", isHeader = true, level = 0 },
    { id = "ARENA", name = "Arena (2v2/3v3/5v5)", keywords = {"PVP"} },
    { id = "BG", name = "Battlegrounds", keywords = {} },
    { id = "WG", name = "Wintergrasp", keywords = {} },

    { header = "MANASTORM", isHeader = true, level = 0 },
    { id = "MS", name = "Manastorm (General)", keywords = {"MANASTORM", "MS"} },
    { id = "MS_ALVA", name = "Manastorm Alva", keywords = {} },
    { id = "MS_GOLD", name = "Manastorm Gold Farm", keywords = {} },
    { id = "MS_BONZO", name = "Manastorm Bonzo", keywords = {} },

    { header = "KEYSTONE", isHeader = true, level = 0 },
    { id = "KEYSTONE", name = "Keystone Runs", keywords = {"KEYSTONE"} },

}

local ACTIVITY_DUNGEON_LOOKUP = {}
local KEYWORD_TO_NAME = {}
for _, entry in ipairs(ACTIVITY_FILTER_GROUPS) do
    if not entry.isHeader and entry.keywords then
        for _, kw in ipairs(entry.keywords) do
            if not ACTIVITY_DUNGEON_LOOKUP[kw] then
                ACTIVITY_DUNGEON_LOOKUP[kw] = {}
            end
            table.insert(ACTIVITY_DUNGEON_LOOKUP[kw], entry.id)
            if entry.name and not KEYWORD_TO_NAME[kw] then
                KEYWORD_TO_NAME[kw] = entry.name
            end
        end
    end
end

LFG.ACTIVITY_FILTER_GROUPS = ACTIVITY_FILTER_GROUPS
LFG.ACTIVITY_DUNGEON_LOOKUP = ACTIVITY_DUNGEON_LOOKUP
LFG.KEYWORD_TO_NAME = KEYWORD_TO_NAME

local KEYSTONE_SPECIAL_NAMES = {
    STRAT = "Stratholme",
    BRD = "Blackrock Depths",
    SCHOLO = "Scholomance",
    LBRS = "Lower Blackrock Spire",
    UBRS = "Upper Blackrock Spire",
    MC = "Molten Core",
    MARA = "Maraudon",
    DM = "Dire Maul",
    SFK = "Shadowfang Keep",
    SM = "Scarlet Monastery",
}

local DUNGEON_WINGS = {
    {
        id = "MARA",
        name = "Maraudon",
        keywords = { "maraudon", "mara" },
        wings = {
            { name = "Orange",   short = "Orange",   keywords = { "orange" } },
            { name = "Purple",   short = "Purple",   keywords = { "purple" } },
            { name = "Pristine", short = "Pristine", keywords = { "pristine" } },
        },
    },
    {
        id = "DM",
        name = "Dire Maul",
        keywords = { "dire maul", "dire", "maul", "dme", "dmn", "dmw" },
        wings = {
            { name = "East",  short = "East",  keywords = { "east", "dme" } },
            { name = "North", short = "North", keywords = { "north", "dmn" } },
            { name = "West",  short = "West",  keywords = { "west", "dmw" } },
        },
    },
    {
        id = "STRAT",
        name = "Stratholme",
        keywords = { "stratholme", "strat" },
        wings = {
            { name = "Living", short = "Living", keywords = { "living", "living side", "live", "main gate", "scarlet" } },
            { name = "Undead", short = "Undead", keywords = { "undead", "undead side", "dead side", "dead", "baron", "ud" } },
        },
    },
    {
        id = "SFK",
        name = "Shadowfang Keep",
        keywords = { "shadowfang keep", "shadowfang", "sfk" },
        wings = {
            { name = "Halls of the Damned", short = "HotD",   keywords = { "halls of the damned", "halls of damned", "hotd", "damned", "halls" } },
            { name = "Argal's Rise",        short = "Argal",  keywords = { "argal's rise", "argals rise", "argal rise", "argal" } },
        },
    },
    {
        id = "BRD",
        name = "Blackrock Depths",
        keywords = { "blackrock depths", "brd" },
        wings = {
            { name = "Upper", short = "Upper", keywords = { "upper" } },
            { name = "Lower", short = "Lower", keywords = { "lower" } },
        },
    },
    {
        id = "SM",
        name = "Scarlet Monastery",
        keywords = { "scarlet monastery", "scarlet", "sm" },
        wings = {
            { name = "Graveyard", short = "GY",   keywords = { "graveyard", "gy" } },
            { name = "Library",   short = "Lib",  keywords = { "library", "lib" } },
            { name = "Armory",    short = "Arm",  keywords = { "armory", "armoury", "arm" } },
            { name = "Cathedral", short = "Cath", keywords = { "cathedral", "cath" } },
        },
    },
    {
        id = "WC",
        name = "Wailing Caverns",
        keywords = { "wailing caverns", "wailing", "wc" },
        wings = {
            { name = "Pit of the Fangs", short = "Pit", keywords = { "pit of the fangs", "pit of fangs", "pit" } },
        },
    },
}

local DUNGEON_WING_LOOKUP = {}
for _, entry in ipairs(DUNGEON_WINGS) do
    DUNGEON_WING_LOOKUP[entry.id] = entry
end

LFG.DUNGEON_WINGS = DUNGEON_WINGS
LFG.DUNGEON_WING_LOOKUP = DUNGEON_WING_LOOKUP

local function SafeTipLabel(key, fallback)
    local v = L[key]
    if type(v) == "string" and v ~= "" and v ~= key then
        return v
    end
    return fallback
end
LFG.GetTipLabel = SafeTipLabel

local WING_LABEL_COLOR = "|cff8cc7ff"
local WING_NAME_COLOR = "|cffffffff"

local PVP_SUBTYPE_NAMES = {
    ARENA_2V2 = "Arena 2v2",
    ARENA_3V3 = "Arena 3v3",
    ARENA_5V5 = "Arena 5v5",
    ARENA     = "Arena",
    BG_WSG    = "Warsong Gulch",
    BG_AB     = "Arathi Basin",
    BG_AV     = "Alterac Valley",
    BG_EOTS   = "Eye of the Storm",
    BG_WG     = "Wintergrasp",
    BATTLEGROUND = "Battleground",
}

function LFG.GetCanonicalDungeonName(category, dungeon)
    if not dungeon or dungeon == "" then
        return ""
    end
    if category == "KEYSTONE" and dungeon == "DM" then
        return "Dire Maul"
    end
    if KEYSTONE_SPECIAL_NAMES[dungeon] and category == "KEYSTONE" then
        return KEYSTONE_SPECIAL_NAMES[dungeon]
    end
    if category == "PVP" and PVP_SUBTYPE_NAMES[dungeon] then
        return PVP_SUBTYPE_NAMES[dungeon]
    end

    if category == "PVP" and dungeon == "PVP" then
        return L["cat_pvp"]
    end
    if KEYWORD_TO_NAME[dungeon] then
        return KEYWORD_TO_NAME[dungeon]
    end
    if dungeon == "RAID" then return L["cat_raid"] end
    if dungeon == "DUNGEON" then return L["cat_dungeon"] end
    if dungeon == "WORLD_BOSS" then return L["cat_world_boss"] end
    if dungeon == "PVP" then return L["cat_pvp"] end
    if dungeon == "MANASTORM" then return L["cat_manastorm"] end
    if dungeon == "KEYSTONE" then return L["cat_keystone"] end
    if dungeon == "MISC" then return L["cat_misc"] end
    if dungeon == "RDF" then return "Random Dungeon Finder" end
    return dungeon
end

local SHORT_NAME_OVERRIDES = {
    ["Kaldros Depthbreaker"] = "Kaldros",
    ["Silithid Lurker"] = "Silithid",
    ["Corrupted Ancient"] = "Corrupted",
    ["Lord Kazzak"] = "Kazzak",
    ["Random Dungeon Finder"] = "RDF",
    ["World Boss (generic wb)"] = "World Boss",
    ["Warsong Gulch"] = "WSG",
    ["Arathi Basin"] = "AB",
    ["Alterac Valley"] = "AV",
    ["Eye of the Storm"] = "EotS",
    ["Wintergrasp"] = "WG",
    ["Temple of the Jade Serpent"] = "Jade Serpent",
    ["Siege of Orgrimmar"] = "SoO",
    ["Throne of Thunder"] = "ToT",
    ["Terrace of Endless Spring"] = "ToES",
    ["Mogu'shan Vaults"] = "MSV",
    ["Heart of Fear"] = "HoF",
    ["Bastion of Twilight"] = "BoT",
    ["Blackwing Descent"] = "BWD",
    ["Throne of the Four Winds"] = "T4W",
    ["Halls of Origination"] = "Origination",
    ["Lost City of the Tol'vir"] = "Tol'vir",
    ["Culling of Stratholme"] = "CoS",
    ["Halls of Reflection"] = "HoR",
    ["Halls of Lightning"] = "HoL",
    ["Utgarde Pinnacle"] = "UP",
    ["Drak'Tharon Keep"] = "DTK",
    ["Lower Blackrock Spire"] = "LBRS",
    ["Upper Blackrock Spire"] = "UBRS",
    ["Blackrock Depths"] = "BRD",
    ["Razorfen Kraul"] = "RFK",
    ["Razorfen Downs"] = "RFD",
    ["Scarlet Monastery"] = "SM",
    ["Hellfire Ramparts"] = "Ramps",
    ["Auchenai Crypts"] = "AC",
    ["Sethekk Halls"] = "SH",
    ["Shadow Labyrinth"] = "SL",
    ["The Shattered Halls"] = "SHH",
    ["The Steamvault"] = "SV",
    ["The Black Morass"] = "BM",
    ["Magister's Terrace"] = "MgT",
    ["Old Hillsbrad"] = "OHF",
    ["Gate of the Setting Sun"] = "Setting Sun",
    ["Siege of Niuzao Temple"] = "Niuzao",
    ["Stormstout Brewery"] = "Brewery",
    ["Shado-Pan Monastery"] = "Shado-Pan",
    ["Mogu'shan Palace"] = "Mogu'shan",
    ["Vault of the Inquisition"] = "Vault",
    ["Road to De' Other Side"] = "Roads",
    ["The Radiant Spring"] = "TRS",
    ["Glittermurk Mines"] = "GMM",
    ["Karazhan Crypt"] = "KC",
    ["World Boss Tour"] = "WB Tour",
    ["Emerald Dream"] = "Dream",
    ["Serpentshrine Cavern"] = "SSC",
    ["Sunwell Plateau"] = "SWP",
    ["Blackwing Lair"] = "BWL",
    ["Molten Core"] = "MC",
    ["Ruins of Ahn'Qiraj"] = "AQ20",
    ["Temple of Ahn'Qiraj"] = "AQ40",
    ["Zul'Gurub"] = "ZG",
    ["Zul'Aman"] = "ZA",
    ["Icecrown Citadel"] = "ICC",
    ["Trial of the Crusader"] = "ToC",
    ["Trial of the Champion"] = "ToC",
    ["Ruby Sanctum"] = "RS",
    ["Baradin Hold"] = "BH",
    ["Dragon Soul"] = "DS",
    ["Vault of Archavon"] = "VoA",
    ["Obsidian Sanctum"] = "OS",
    ["Eye of Eternity"] = "EoE",
    ["Black Temple"] = "BT",
    ["Mount Hyjal"] = "Hyjal",
    ["Tempest Keep"] = "TK",
    ["The Vortex Pinnacle"] = "Vortex",
    ["Throne of the Tides"] = "Tides",
    ["Blackrock Caverns"] = "BRC",
    ["Stonecore"] = "SC",
    ["Grim Batol"] = "GB",
    ["End Time"] = "ET",
    ["Well of Eternity"] = "WoE",
    ["Hour of Twilight"] = "HoT",
    ["Firelands"] = "FL",
    ["Dire Maul"] = "DM",
    ["Scholomance"] = "Scholo",
    ["Stratholme"] = "Strat",
    ["Wailing Caverns"] = "WC",
    ["Shadowfang Keep"] = "SFK",
    ["Blackfathom Deeps"] = "BFD",
    ["Blackrock Cavern"] = "BRC",
    ["Dire Maul North"] = "DMN",
    ["Dire Maul East"] = "DME",
    ["Dire Maul West"] = "DMW",
    ["Shadowbone Depths"] = "SD",
    ["Temple of Embers"] = "Embers",
    ["Arena (2v2/3v3/5v5)"] = "Arena",
    ["Manastorm (General)"] = "MStorm",
    ["Manastorm Gold Farm"] = "MS Gold",
    ["Manastorm Bonzo"] = "MS Bonzo",
    ["Scarlet Monastery (MoP)"] = "SM (MoP)",
    ["Scholomance (MoP)"] = "Scholo (MoP)",
    ["Zul'Gurub (Cata)"] = "ZG (Cata)",
    ["Zul'Aman (Cata)"] = "ZA (Cata)",
    ["Utgarde Pinnacle"] = "UP",
    ["Utgarde Keep"] = "UK",
    ["Halls of Stone"] = "HoS",
    ["Halls of Lightning"] = "HoL",
    ["Culling of Stratholme"] = "CoS",
    ["Trial of the Champion"] = "ToC",
    ["Halls of Reflection"] = "HoR",
    ["Forge of Souls"] = "FoS",
    ["Pit of Saron"] = "PoS",
    ["Drak'Tharon Keep"] = "DTK",
    ["Lower Blackrock Spire"] = "LBRS",
    ["Upper Blackrock Spire"] = "UBRS",
    ["Blackrock Depths"] = "BRD",
    ["Hellfire Ramparts"] = "Ramps",
    ["Auchenai Crypts"] = "AC",
    ["Sethekk Halls"] = "SH",
    ["Shadow Labyrinth"] = "SL",
    ["The Shattered Halls"] = "SHH",
    ["The Steamvault"] = "SV",
    ["The Black Morass"] = "BM",
    ["Magister's Terrace"] = "MgT",
    ["Old Hillsbrad"] = "OHF",
    ["Gate of the Setting Sun"] = "Setting Sun",
    ["Siege of Niuzao Temple"] = "Niuzao",
    ["Stormstout Brewery"] = "Brewery",
    ["Shado-Pan Monastery"] = "Shado-Pan",
    ["Mogu'shan Palace"] = "Mogu'shan",
    ["Vault of the Inquisition"] = "Vault",
    ["Road to De' Other Side"] = "Roads",
    ["The Radiant Spring"] = "TRS",
    ["Glittermurk Mines"] = "GMM",
    ["Karazhan Crypt"] = "KC",
    ["Temple of the Jade Serpent"] = "Jade Serpent",
    ["Siege of Orgrimmar"] = "SoO",
    ["Throne of Thunder"] = "ToT",
    ["Terrace of Endless Spring"] = "ToES",
    ["Mogu'shan Vaults"] = "MSV",
    ["Heart of Fear"] = "HoF",
    ["Bastion of Twilight"] = "BoT",
    ["Blackwing Descent"] = "BWD",
    ["Throne of the Four Winds"] = "T4W",
    ["Halls of Origination"] = "Origination",
    ["Lost City of the Tol'vir"] = "Tol'vir",
    ["Serpentshrine Cavern"] = "SSC",
    ["Sunwell Plateau"] = "SWP",
    ["Blackwing Lair"] = "BWL",
    ["Molten Core"] = "MC",
    ["Ruins of Ahn'Qiraj"] = "AQ20",
    ["Temple of Ahn'Qiraj"] = "AQ40",
    ["Zul'Gurub"] = "ZG",
    ["Zul'Aman"] = "ZA",
    ["Icecrown Citadel"] = "ICC",
    ["Trial of the Crusader"] = "ToC",
    ["Ruby Sanctum"] = "RS",
    ["Baradin Hold"] = "BH",
    ["Dragon Soul"] = "DS",
    ["Vault of Archavon"] = "VoA",
    ["Obsidian Sanctum"] = "OS",
    ["Eye of Eternity"] = "EoE",
    ["Black Temple"] = "BT",
    ["Mount Hyjal"] = "Hyjal",
    ["Tempest Keep"] = "TK",
    ["The Vortex Pinnacle"] = "Vortex",
    ["Throne of the Tides"] = "Tides",
    ["World Boss Tour"] = "WB Tour",
    ["Emerald Dream"] = "Dream",
}

LFG.SHORT_NAME_OVERRIDES = SHORT_NAME_OVERRIDES

function LFG.GetShortDungeonName(category, dungeon)
    local name = LFG.GetCanonicalDungeonName(category, dungeon)
    if not name or name == "" then return "" end
    if SHORT_NAME_OVERRIDES[name] then
        return SHORT_NAME_OVERRIDES[name]
    end
    if string.len(name) <= 16 then return name end
    local firstWord = string.match(name, "^(%S+)")
    if firstWord and string.len(firstWord) <= 16 then
        return firstWord
    end
    return string.sub(name, 1, 14) .. "..."
end

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
    local filterIds = ACTIVITY_DUNGEON_LOOKUP[dungeon]
    if filterIds and #filterIds > 0 then
        for _, id in ipairs(filterIds) do
            if FrostSeekDB.LFG.activityFilter[id] ~= false then
                return true
            end
        end
        return false
    end
    return true
end

LFG.KEYSTONE_KEYWORDS = KEYSTONE_KEYWORDS
LFG.RAID_KEYWORDS = RAID_KEYWORDS
LFG.WORLD_BOSS_KEYWORDS = WORLD_BOSS_KEYWORDS
LFG.WORLD_BOSS_GENERIC_KEYWORDS = WORLD_BOSS_GENERIC_KEYWORDS
LFG.PVP_KEYWORDS = PVP_KEYWORDS
LFG.MANASTORM_KEYWORDS = MANASTORM_KEYWORDS
LFG.DUNGEON_KEYWORDS = DUNGEON_KEYWORDS
LFG._IsGenericWorldBossKeyword = IsGenericWorldBossKeyword
LFG.WING_LABEL_COLOR = WING_LABEL_COLOR
LFG.WING_NAME_COLOR = WING_NAME_COLOR

local function sortKeywordsByLength(tbl)
    table.sort(tbl, function(a, b) return string.len(a) > string.len(b) end)
end

sortKeywordsByLength(RAID_KEYWORDS)
sortKeywordsByLength(WORLD_BOSS_KEYWORDS)
sortKeywordsByLength(PVP_KEYWORDS)
sortKeywordsByLength(MANASTORM_KEYWORDS)
sortKeywordsByLength(DUNGEON_KEYWORDS)
