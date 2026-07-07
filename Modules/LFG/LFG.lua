local FrostSeek = _G.FrostSeek
local FrostSeekUIUtils = _G.FrostSeekUIUtils
local Shared = _G.FrostSeekShared

local LFG = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg", LFG)

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
    "vault of archavon", "voa", "archavon", "obsidian sanctum", "os", "sarth", "sartharion",
    "eye of eternity", "eoe", "malygos", "ulduar", "uld",
    "trial of the crusader", "toc", "crusader", "icecrown citadel", "icc", "ruby sanctum", "rs", "halion",
    "blackwing lair", "molten core", "temple of ahn'qiraj", "ruins of ahn'qiraj",
    "serpentshrine cavern", "tempest keep", "the battle for mount hyjal",
    "sunwell plateau", "vault of archavon", "obsidian sanctum", "eye of eternity",
    "trial of the crusader", "icecrown citadel", "ruby sanctum",
    "naxxramas", "archavon", "sartharion", "malygos", "ulduar", "algolon",
    "anub'arak", "lich king", "sindragosa", "blood queen", "putricide",
    "baradin hold", "bh", "bastion of twilight", "bot", "blackwing descent", "bwd", "nefarian",
    "throne of the four winds", "t4w", "al'akir", "firelands", "fl", "ragnaros",
    "dragon soul", "ds", "deathwing",
    "mogu'shan vaults", "msv", "heart of fear", "hof", "shek'zeer",
    "terrace of endless spring", "toes", "throne of thunder", "tot", "lei shen",
    "siege of orgrimmar", "soo", "garrosh"
}

local WORLD_BOSS_KEYWORDS = {
    "soggoth", "sogoth", "azuregos", "kazzak", "doomwalker", "setis", "settis",
    "emeriss", "lethon", "taerar", "ysondre", "dream", "nightmare","Kaldros Depthbreaker","Kaldros.Depthbreaker",
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
    "rfc", "ragefire", "dm", "deadmines", "vc", "wc", "wailing", "sfk", "shadowfang",
    "stocks", "bfd", "gnomer", "rfk", "sm", "scarlet", "gy", "lib", "arm", "cath",
    "rfd", "ulda", "zf", "mara", "st", "brd", "dire", "maul", "dme", "dmn", "dmw","gmm",
    "strat", "scholo", "lbrs", "ubrs", "ramps", "bf", "sp", "ub", "mt", "ac", "sh",
    "ohf", "mecha", "bm", "mgt", "shh", "bota", "sl", "sv", "arca", "uk", "up","kcm",
    "nexus", "oculus", "ak", "dtk", "vh", "gun", "hos", "hol", "cos", "fos", "pos", "hor", "vault", "roads", "brc", "kc", "graveyard", "scarlet monastery","",
    "ragefire chasm", "deadmines", "wailing caverns", "shadowfang keep",
    "blackfathom deeps", "gnomeregan", "razorfen kraul", "razorfen downs",
    "scarlet monastery", "uldaman", "zul'farrak", "maraudon",
    "sunken temple", "blackrock depths", "dire maul", "stratholme",
    "scholomance", "lower blackrock spire", "upper blackrock spire",
    "hellfire ramparts", "blood furnace", "slave pens", "underbog", "mana-tombs", "mana tombs",
    "auchenai crypts", "sethekk halls", "shadow labyrinth", "auchenai-crypts",
    "old hillsbrad foothills", "the black morass", "mechanar", "botanica", "sethekk-halls",
    "arcatraz", "magisters terrace", "sunken temple", "shadow labyrinth", "shadow-labyrinth",
    "utgarde keep", "utgarde pinnacle", "the nexus", "the oculus",
    "azjol-nerub", "ahn'kahet", "drak'tharon keep", "violet hold",
    "gundrak", "halls of stone", "halls of lightning", "culling of stratholme",
    "trial of the champion", "forge of souls", "pit of saron", "halls of reflection",
    "blackrock caverns", "throne of the tides", "vortex pinnacle",
    "lost city of tol'vir", "halls of origination", "grim batol",
    "stonecore", "zul'aman", "end time", "well of eternity",
    "hour of twilight","karazhan crypt","glittermurk mines",
    "temple of the jade serpent", "jade serpent", "tjs",
    "stormstout brewery", "brewery", "shado-pan monastery", "shado-pan",
    "mogu'shan palace", "scarlet halls", "siege of niuzao temple", "niuzao",
    "gate of the setting sun", "setting sun",
    "mythic", "mythic+", "keystone"
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

    { header = "CUSTOM DUNGEONS", isHeader = true },
    { id = "BRC", name = "Blackrock Cavern", keywords = {"BRC", "BLACKROCK CAVERN"} },
    { id = "KC", name = "Karazhan Crypt", keywords = {"KC", "KARAZHAN CRYPT"} },
    { id = "VAULT", name = "Vault of the Inquisition", keywords = {"VAULT", "INQUISITION"} },
    { id = "ROADS", name = "Road to De' Other Side", keywords = {"ROADS", "ROAD TO DE' OTHER SIDE"} },
    { id = "GMM", name = "GlitteMurk Mines", keywords = {"GLITTERMURK", "GLITTEMURK", "GLITTERMURK MINES", "GLITTEMURK MINES"} },
    { id = "BH", name = "Baradin Hold", keywords = {"BARADIN", "BARADIN HOLD"} },
    { id = "TW", name = "Tor'Watha", keywords = {"TOR'WATHA"} },

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

    { header = "CUSTOM", isHeader = true },
    { id = "CSTM", name = "Custom (General)", keywords = {"CUSTOM", "CSTM"} },
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
    "pocket", "sadgirl", "speed", "some", "silver", "put",
    "guild", "community", "recruit", "recruiting", "recru", "roster", "lf members", "lf guild",
    "guild lf", "new guild", "gm is", "leader is", "we are", "our guild", "us on",
    "application", "roster spot", "core group", "core team", "ru",
    "hardcore guild", "casual guild", "semi-hardcore", "mythic raiding", "raid team", "static group",
    "looking for members", "looking for guild", "looking for a guild", "guild is looking", "we are looking",
    "active members", "mature players", "friendly guild", "pve guild", "pvp guild", "leveling guild",
    "social guild", "g looking", "is looking for", "guild event", "community night",
    "boost", "wts", "wtb", "sell", "selling", "buy", "gdkp", "carry service",
    "boosting service", "pilot", "piloted", "price", "cheap", "offer",
    "service", "cache", "nuked", "ksh", "keystone master", "wts %d",
    "learning run", "fun run", "train", "mythic%+", "pick", "able", "something", "you", "you're",
    "pushing", "mdi", "speedrun", "server first", "top guild", "best guild", "cant", "found",
    "world first", "qualif", "naxxramas progress", "icc progress", "progression",
    "awakening", "twisting", "raid night", "raid schedule", "raid times", "raid day",
    "transfer", "transfers", "realm transfer", "server transfer", "move to", "come join",
    "invite link", "discord link", "discord server", "info and", "for more",
    "contact", "website", "armory", "raider.io", "rio", "wowprogress", "wcl", "warcraftlogs",
    "check our", "check my", "for info", "apply in", "apply on", "apply at",
    "register", "enroll",
    "stream", "streamer", "content creator", "clip", "recording", "obs", "studio",
    "tiktok", "instagram", "twitter", "facebook", "reddit", "patreon", "paypal",
    "donate", "donation", "support me", "follow", "subscribe", "giveaway",
    "raffle", "contest", "prize", "merch", "store", "shop", "buy now",
    "weakaura", "weakauras", "elvui", "tukui", "plater", "dbm", "bigwigs",
    "https", "discord.gg", "twitch.tv", "youtube", "sfoglia", "scene", "dude",
    "account", "heirloom", "spoils", "reins", "meta", "wtt",
    "glyph", "opposition", "warhorn", "farmers", "dedicated",
    "long term", "first realm",
    "tSM", "mRP", "trp", "total rp", "help",
    "<Forsaken>", "Forsaken","<Seventy Saints>","Seventy Saints",
    "gamble", "bet", "wager", "jackpot", "lottery", "lucky draw", "spin the wheel",
    "raid on wednesday", "raid on thursday", "raid on friday", "raid on saturday",
    "raid on sunday", "raid on monday", "raid on tuesday",
}

local SPAM_PHRASES = {
    "lfm guild", "lfm raid", "lfmg", "LFguild", "lf guild", "lf gm",
    "looking for more", "need more", "filling last", "filling roster",
    "any class", "all classes", "all roles", "seeking",
    "anyone want", "anyone interested", "who wants", "interested in",
    "hit me up", "shoot me", "hmu", "dm me", "poke me", "ping me", "msg me",
    "whisper me for", "pm for", "whisper any",
    "trade chat", "world chat", "global chat",
    "server time", "night at",
    "bell icon", "smash that", "ring the",
}

local function IsSpamMessage(msg)
    local lowerMsg = string.lower(msg)
    for _, word in ipairs(SPAM_WORDS) do
        if string.find(lowerMsg, word, 1, true) then
            return true
        end
    end
    for _, phrase in ipairs(SPAM_PHRASES) do
        if string.find(lowerMsg, phrase, 1, true) then
            return true
        end
    end
    return false
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
            CUSTOM = "catCustom", ALL = "catAll", MISC = "catMisc"
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
    CUSTOM = "|cFFFFCC00C|r",
}

local function wholeWordFind(text, word)
    if not text or not word then return false end
    return string.find(text, "%f[%a%d]" .. word .. "%f[^%a%d]") ~= nil
end

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
       string.match(lowerMsg, "^lf%s+[thd]") or string.match(lowerMsg, "^lf%s+tank") or
       string.match(lowerMsg, "^lf%s+heal") or string.match(lowerMsg, "^lf%s+dps") then
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
       string.match(lowerMsg, "lf[ %p].*tank") or
       string.match(lowerMsg, "lf[ %p].*heal") then
        return true
    end
    if string.find(lowerMsg, "lfm") or string.find(lowerMsg, "lfg") then return true end
    if string.match(lowerMsg, "lf%d+m") then return true end
    if string.match(lowerMsg, "lf%d") then return true end
    if string.find(lowerMsg, " lf ") or string.find(lowerMsg, "^lf ") then return true end
    if string.match(lowerMsg, "last%s*spot") or string.match(lowerMsg, "need%s+%d") then return true end
    return false
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
    for _, d in ipairs(DUNGEON_KEYWORDS) do
        if wholeWordFind(lowerMsg, d) then
            local isHeroic = wholeWordFind(lowerMsg, "hc") or
                             wholeWordFind(lowerMsg, "heroic") or
                             string.match(lowerMsg, " h[%s%p]") or
                             string.match(lowerMsg, " h$")
            return "DUNGEON", string.upper(d), isHeroic, false, false, false, false
        end
    end
    local customCategoryMap = {
        DUNGEON = { category = "DUNGEON", isDungeon = true },
        RAID = { category = "RAID", isRaid = true },
        WORLD_BOSS = { category = "WORLD_BOSS", isWorldBoss = true },
        PVP = { category = "PVP", isPvp = true },
        MANASTORM = { category = "MANASTORM", isManastorm = true },
        KEYSTONE = { category = "KEYSTONE", isKeystone = true },
        CUSTOM = { category = "CUSTOM", isCustom = true },
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

function LFG.GetGearScore()
    if FrostSeek and FrostSeek.CalculateGearScore then
        return FrostSeek.CalculateGearScore("player") or 0
    end
    return 0
end

function LFG.CreateWhisperMessage()
    local classInfo, ilvl, enchant = LFG.GetFullPlayerInfo()
    local gs = LFG.GetGearScore()
    local roleText = FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole ~= "No Role" and FrostSeekDB.LFG.myRole or ""
    local playerLevel = UnitLevel("player") or 0
    if FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled then
        local template = FrostSeekDB.LFG.customMessages.template or "inv {role} {class} {ench} {ilvl} ilvl {gs}gs"
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
        if FrostSeekDB.LFG.customMessages.showGs then
            message = string.gsub(message, "{gs}", tostring(gs or 0))
        else
            message = string.gsub(message, "{gs}", "")
        end
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
            message = "inv " .. roleText .. " " .. classInfo .. " " .. ilvl .. " ilvl " .. gs .. "gs"
        end
        return message
    else
        local enchantText = enchant ~= "" and (" " .. enchant) or ""
        local rolePrefix = roleText ~= "" and (roleText .. " ") or ""
        local levelText = " lv" .. playerLevel
        if classInfo == "Hero" then
            return "inv " .. rolePrefix .. ilvl .. " ilvl " .. gs .. "gs" .. levelText .. enchantText
        else
            return "inv " .. rolePrefix .. classInfo .. enchantText .. " " .. ilvl .. " ilvl " .. gs .. "gs" .. levelText
        end
    end
end

function LFG.SetRole(role)
    if role == "" or role == nil then
        role = "No Role"
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
    if not activeSearches then activeSearches = {} end
    local category, dungeon, isHeroic, isMythic, isRaid, isKeystone, isPvp = LFG.ClassifyMessage(message)
    if category == "MISC" then
        return
    end
    if not LFG.PassesActivityFilter(category, dungeon) then
        return
    end
    local isManastorm = (category == "MANASTORM")
    local isWorldBoss = (category == "WORLD_BOSS")
    local isCustom = (category == "CUSTOM")
    local now = GetTime()
    for _, record in ipairs(activeSearches) do
        if record.player == sender then
            record.message = message
            record.lastUpdate = now
            record.dungeon = dungeon
            record.category = category
            record.isHeroic = isHeroic
            record.isRaid = isRaid
            record.isPvp = isPvp
            record.isKeystone = isKeystone
            record.isManastorm = isManastorm
            record.isWorldBoss = isWorldBoss
            record.isCustom = isCustom
            record.channel = channel
            if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
            LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isRaid, isPvp, isKeystone, isManastorm, isCustom, category)
            return
        end
    end
    table.insert(activeSearches, {
        player = sender,
        message = message,
        dungeon = dungeon,
        category = category,
        isHeroic = isHeroic,
        isRaid = isRaid,
        isPvp = isPvp,
        isKeystone = isKeystone,
        isManastorm = isManastorm,
        isWorldBoss = isWorldBoss,
        isCustom = isCustom,
        channel = channel,
        lastUpdate = now,
        startTime = now,
    })
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isRaid, isPvp, isKeystone, isManastorm, isCustom, category)
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
    elseif ltype == "Custom" then
        category = "CUSTOM"
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
    local isCustom = (ltype == "Custom")
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
            record.isCustom = isCustom
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
        isCustom = isCustom,
        channel = "FrostNet",
        lastUpdate = now,
        startTime = now,
        source = "protocol",
    })
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

function LFG.GroupMatchesCategory(group, category)
    if not group then return false end
    if group.category == "MISC" then return false end
    if category == "ALL" then return true end
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
        { keywords = {"ascended"}, label = "Ascended" },
        { keywords = {"mythic"}, label = "Mythic Instanced" },
        { keywords = {"heroic instanced", "hc instanced"}, label = "HC Instanced" },
        { keywords = {"instanced"}, label = "Instanced" },
        { keywords = {"open world"}, label = "Open World" },
    },
    MANASTORM = {
        { keywords = {"alva"}, label = "Alva" },
        { keywords = {"gold farm", "goldfarm"}, label = "Gold Farm" },
        { keywords = {"bonzo farm", "bonzofarm", "bonzo"}, label = "Bonzo Farm" },
        { keywords = {"leveling", "level"}, label = "Leveling" },
    },
    PVP = {
        { keywords = {"rated", "rbg"}, label = "Rated" },
        { keywords = {"arena", "2v2", "3v3", "5v5"}, label = "Arena" },
        { keywords = {"bg", "battleground"}, label = "Battleground" },
        { keywords = {"skirmish"}, label = "Skirmish" },
    },
    CUSTOM = {
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
    if not message then return { tank = 0, healer = 0, dps = 0 } end
    local roles = { tank = 0, healer = 0, dps = 0 }
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
    local totalRoles = roles.tank + roles.healer + roles.dps
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

function LFG.FormatRolesText(roles)
    if not roles then return "" end
    local tank = tonumber(roles.tank) or 0
    local healer = tonumber(roles.healer) or 0
    local dps = tonumber(roles.dps) or 0
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
    return table.concat(parts, "  ")
end

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
        nextPopup.isCustom,
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
            local yOffset = 50 + (activeCount * 110)
            frame:ClearAllPoints()
            frame:SetPoint("TOP", UIParent, "TOP", 0, -yOffset)
            activeCount = activeCount + 1
        end
    end
end

function LFG.CreateLFGPopup(sender, message, dungeon, isHeroic, isRaid, isPvp, isKeystone, isManastorm, isCustom, category)
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
            isCustom = isCustom,
            category = category,
        })
        return
    end
    if not FrostSeekDB.LFG.popupCategories[category] and not FrostSeekDB.LFG.popupCategories["ALL"] then
        return
    end
    if not LFG.CanShowPopup(sender, message) then return end
    local accent = CATEGORY_ACCENT[category] or CATEGORY_ACCENT.MISC
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(320, 100)
    popup:SetFrameStrata("DIALOG")
    popup.category = category
    local yOffset = 50 + (activePopupCount * 110)
    popup:SetPoint("TOP", UIParent, "TOP", 0, -yOffset)
    popup:SetAlpha(0)
    UIFrameFadeIn(popup, 0.15, 0, 1)
    popup.bg = popup:CreateTexture(nil, "BACKGROUND")
    popup.bg:SetPoint("TOPLEFT", 0, 0)
    popup.bg:SetPoint("BOTTOMRIGHT", 0, 0)
    popup.bg:SetColorTexture(unpack(_tc("bgMenuBg")))
    local bw = 1.5
    local br, bg2, bb = accent[1], accent[2], accent[3]
    popup.borderTop = popup:CreateTexture(nil, "BORDER")
    popup.borderTop:SetPoint("TOPLEFT", 0, 0)
    popup.borderTop:SetPoint("TOPRIGHT", 0, 0)
    popup.borderTop:SetHeight(bw)
    popup.borderTop:SetColorTexture(br, bg2, bb, 0.9)
    popup.borderBottom = popup:CreateTexture(nil, "BORDER")
    popup.borderBottom:SetPoint("BOTTOMLEFT", 0, 0)
    popup.borderBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    popup.borderBottom:SetHeight(bw)
    popup.borderBottom:SetColorTexture(br, bg2, bb, 0.9)
    popup.borderLeft = popup:CreateTexture(nil, "BORDER")
    popup.borderLeft:SetPoint("TOPLEFT", 0, 0)
    popup.borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
    popup.borderLeft:SetWidth(bw)
    popup.borderLeft:SetColorTexture(br, bg2, bb, 0.9)
    popup.borderRight = popup:CreateTexture(nil, "BORDER")
    popup.borderRight:SetPoint("TOPRIGHT", 0, 0)
    popup.borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
    popup.borderRight:SetWidth(bw)
    popup.borderRight:SetColorTexture(br, bg2, bb, 0.9)

    popup.classIcon = popup:CreateTexture(nil, "ARTWORK")
    popup.classIcon:SetSize(18, 18)
    popup.classIcon:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -11)
    popup.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    do
        local cf = nil
        if sender and FrostSeek and FrostSeek.Presence and FrostSeek.Presence.onlineUsers then
            local u = FrostSeek.Presence.onlineUsers[sender]
            if u and u.classFile and u.classFile ~= "" then cf = u.classFile end
        end
        if cf and Shared and Shared.GetClassIcon then
            popup.classIcon:SetTexture(Shared.GetClassIcon(cf))
            popup.classIcon:Show()
        else
            popup.classIcon:Hide()
        end
    end

    local nameText = popup:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    nameText:SetPoint("TOPLEFT", popup, "TOPLEFT", 34, -12)
    nameText:SetText(string.format("|cffffffff%s|r", sender or "Unknown"))
    local catColors = {
        KEYSTONE = "|cFFFF88FF[KS]|r",
        PVP = "|cFFFF5555[PVP]|r",
        MANASTORM = "|cFFAA88FF[MS]|r",
        RAID = "|cFFFFAA00[RAID]|r",
        WORLD_BOSS = "|cFFFFA500[WB]|r",
        CUSTOM = "|cFFFFCC00[CSTM]|r",
    }
    local contentText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    contentText:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -30)
    contentText:SetPoint("RIGHT", popup, "RIGHT", -14, 0)
    contentText:SetJustifyH("LEFT")
    local difficulty = LFG.ParseDifficulty(message, category)
    local contentLine = ""
    if isKeystone then
        local ksName, ksLevel = LFG.ParseKeystoneInfo(message)
        if ksName and ksLevel then
            contentLine = string.format("%s %s (%d)", catColors.KEYSTONE, ksName, ksLevel)
        elseif ksName then
            contentLine = string.format("%s %s", catColors.KEYSTONE, ksName)
        else
            contentLine = catColors.KEYSTONE
        end
    elseif category == "RAID" then
        local raidName = dungeon and dungeon ~= "RAID" and dungeon or ""
        local diffTag = difficulty and (" |cffcccccc" .. difficulty .. "|r") or ""
        if raidName ~= "" then
            contentLine = string.format("%s %s%s", catColors.RAID, raidName, diffTag)
        else
            contentLine = catColors.RAID .. diffTag
        end
    elseif category == "WORLD_BOSS" then
        local bossName = dungeon and dungeon ~= "WORLD_BOSS" and dungeon or ""
        local diffTag = difficulty and (" |cffcccccc" .. difficulty .. "|r") or ""
        if bossName ~= "" then
            contentLine = string.format("%s %s%s", catColors.WORLD_BOSS, bossName, diffTag)
        else
            contentLine = catColors.WORLD_BOSS .. diffTag
        end
    elseif category == "MANASTORM" then
        local diffTag = difficulty and (" " .. difficulty) or ""
        contentLine = catColors.MANASTORM .. " |cffcccccc" .. diffTag .. "|r"
    elseif category == "PVP" then
        local diffTag = difficulty and (" " .. difficulty) or ""
        contentLine = catColors.PVP .. " |cffcccccc" .. diffTag .. "|r"
    elseif category == "CUSTOM" then
        local customName = dungeon and dungeon ~= "MISC" and dungeon ~= "CUSTOM" and dungeon or ""
        local diffTag = difficulty and (" |cffcccccc" .. difficulty .. "|r") or ""
        if customName ~= "" then
            contentLine = string.format("%s %s%s", catColors.CUSTOM, customName, diffTag)
        else
            contentLine = catColors.CUSTOM .. diffTag
        end
    else
        local dungeonName = dungeon and dungeon ~= "MISC" and dungeon ~= "DUNGEON" and dungeon or ""
        local diffTag = difficulty and (" |cffcccccc" .. difficulty .. "|r") or (isHeroic and " |cFFFF0000Heroic|r" or "")
        if dungeonName ~= "" then
            contentLine = string.format("|cFF00FF00[DNG]|r %s%s", dungeonName, diffTag)
        else
            contentLine = "|cFF00FF00[DNG]|r" .. diffTag
        end
    end
    contentText:SetText(contentLine)
    local roles = LFG.ParseRoles(message)
    local rolesText = LFG.FormatRolesText(roles)
    local rolesDisplay = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rolesDisplay:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -48)
    rolesDisplay:SetPoint("RIGHT", popup, "RIGHT", -14, 0)
    rolesDisplay:SetJustifyH("LEFT")
    if rolesText ~= "" then
        rolesDisplay:SetText(string.format("|cff888888LF:|r |cffffffff%s|r", rolesText))
    elseif category == "MANASTORM" or category == "CUSTOM" then
        rolesDisplay:SetText("|cff888888LF:|r |cffffffffAll|r")
    else
        local shortMsg = LFG.ShortenMessage(message or "")
        if shortMsg ~= "" then
            rolesDisplay:SetText(string.format("|cff888888LF:|r |cffaaaaaa%s|r", shortMsg))
        end
    end
    local btnSpacing = 8
    local btnWidth = 88
    local btnHeight = 24
    local totalWidth = (btnWidth * 2) + btnSpacing
    local startX = (popup:GetWidth() - totalWidth) / 2
    local acceptBtn = FrostSeekUIUtils.CreateModernButton(popup, btnWidth, btnHeight, "Accept", _tc("catDungeon"))
    acceptBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", startX, 8)
    acceptBtn:SetScript("OnClick", function()
        local whisperMsg = LFG.CreateWhisperMessage()
        SendChatMessage(whisperMsg, "WHISPER", nil, sender)
        LFG.RemovePopupFrame(popup)
        UIErrorsFrame:AddMessage("|cff88ccffWhisper sent to " .. sender, 1, 1, 1, 3)
    end)
    local declineBtn = FrostSeekUIUtils.CreateModernButton(popup, btnWidth, btnHeight, "Close", _tc("catPvP"))
    declineBtn:SetPoint("LEFT", acceptBtn, "RIGHT", btnSpacing, 0)
    declineBtn:SetScript("OnClick", function()
        LFG.RemovePopupFrame(popup)
    end)
    local muteBtn = FrostSeekUIUtils.CreateModernButton(popup, 50, btnHeight, "Mute", _tc("catRaid"))
    muteBtn:SetPoint("LEFT", declineBtn, "RIGHT", btnSpacing, 0)
    muteBtn:SetScript("OnClick", function()
        mutedPlayers[sender] = GetTime() + 1800
        LFG.RemovePopupFrame(popup)
        print("|cffff8800FrostSeek:|r Muted " .. sender .. " for 30 minutes")
    end)
    local duration = FrostSeekDB.LFG.frameDuration or 5
    popup.expiryTime = GetTime() + duration
    popup:SetScript("OnUpdate", function(self, elapsed)
        if GetTime() >= self.expiryTime then
            self:SetScript("OnUpdate", nil)
            LFG.RemovePopupFrame(self)
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
    local roleText = (FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole ~= "No Role") and ("Role: " .. FrostSeekDB.LFG.myRole) or "Role: Not Set"
    local gs = LFG.GetGearScore()
    local gsColor = "|cff88ccff"
    if FrostSeek and FrostSeek.GetGearScoreColor then
        local r, g, b = FrostSeek.GetGearScoreColor(gs)
        gsColor = string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    end
    LFG.playerInfoText:SetText(string.format("|cffffffff%s | |cff00ff00%diLvl|r | %s%dGS|r | %s %s",
        classInfo, ilvl, gsColor, gs, roleText, enchant))
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
    for i = 1, MAX_DISPLAY_ROWS do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(740, ROW_HEIGHT)
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
        local dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dungeonText:SetPoint("LEFT", row, "LEFT", 198, 0)
        dungeonText:SetWidth(80)
        dungeonText:SetJustifyH("LEFT")
        dungeonText:SetText("")
        dungeonText:SetTextColor(unpack(_tc("textNorm")))
        local msgText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        msgText:SetPoint("LEFT", row, "LEFT", 290, 0)
        msgText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        msgText:SetJustifyH("LEFT")
        msgText:SetText("")
        msgText:SetTextColor(unpack(_tc("textPrimary")))
        local tooltipFrame = CreateFrame("Frame", nil, row)
        tooltipFrame:SetPoint("LEFT", row, "LEFT", 290, 0)
        tooltipFrame:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        tooltipFrame:SetHeight(ROW_HEIGHT)
        tooltipFrame:EnableMouse(true)
        local tooltipBg = tooltipFrame:CreateTexture(nil, "BACKGROUND")
        tooltipBg:SetAllPoints()
        tooltipBg:SetColorTexture(0, 0, 0, 0)
        local acceptBtn = FrostSeekUIUtils.CreateModernButton(row, 60, 20, "Accept", _tc("catDungeon"))
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
    row:SetSize(740, ROW_HEIGHT)
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
    local dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonText:SetPoint("LEFT", row, "LEFT", 198, 0)
    dungeonText:SetWidth(80)
    dungeonText:SetJustifyH("LEFT")
    dungeonText:SetText("")
    dungeonText:SetTextColor(unpack(_tc("textNorm")))
    local msgText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgText:SetPoint("LEFT", row, "LEFT", 290, 0)
    msgText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    msgText:SetJustifyH("LEFT")
    msgText:SetText("")
    msgText:SetTextColor(unpack(_tc("textPrimary")))
    local tooltipFrame = CreateFrame("Frame", nil, row)
    tooltipFrame:SetPoint("LEFT", row, "LEFT", 290, 0)
    tooltipFrame:SetPoint("RIGHT", row, "RIGHT", -70, 0)
    tooltipFrame:SetHeight(ROW_HEIGHT)
    tooltipFrame:EnableMouse(true)
    local tooltipBg = tooltipFrame:CreateTexture(nil, "BACKGROUND")
    tooltipBg:SetAllPoints()
    tooltipBg:SetColorTexture(0, 0, 0, 0)
    local acceptBtn = FrostSeekUIUtils.CreateModernButton(row, 60, 20, "Accept", _tc("catDungeon"))
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
    for _, search in ipairs(activeSearches) do
        if LFG.GroupMatchesCategory(search, LFG.CurrentCategory or "ALL") then
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
    if LFG.lfgCountText then
        LFG.lfgCountText:SetText("Active Recruiters: " .. #filteredSearches)
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
            if record.dungeon and record.dungeon ~= "MISC" and record.dungeon ~= "KEYSTONE" and record.dungeon ~= "PVP" and record.dungeon ~= "MANASTORM" and record.dungeon ~= "WORLD_BOSS" and record.dungeon ~= "CUSTOM" then
                poolRow.dungeonText:SetText(record.dungeon)
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
    if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
end

function LFG:Initialize(parentFrame)
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    self.mainContainer = CreateFrame("Frame", nil, self.frame)
    self.mainContainer:SetSize(760, 500)
    self.mainContainer:SetPoint("TOP", self.frame, "TOP", 0, -5)
    self.mainContainer:EnableMouse(true)
    self.mainContainer:SetScript("OnMouseDown", function()
        CloseAllDropdowns()
    end)
    self.playerFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.playerFrame:SetSize(740, 35)
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
    self.playerInfoText:SetText("Loading player info...")
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
        GameTooltip:SetText("LFG Toggle", 0.8, 0.9, 1)
        if FrostSeekDB.LFG.disableLFG then
            GameTooltip:AddLine("Currently: |cffff4444Disabled|r", 1, 1, 1)
            GameTooltip:AddLine("Click to enable LFG radar", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Currently: |cff33cc33Enabled|r", 1, 1, 1)
            GameTooltip:AddLine("Click to disable LFG radar", 0.7, 0.7, 0.7)
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
    roleLabel:SetText("Role:")
    roleLabel:SetTextColor(unpack(_tc("textMuted")))
    self.roleDropdown = FrostSeekUIUtils.CreateModernDropdown(self.playerFrame, 95, 22)
    self.roleDropdown:SetPoint("LEFT", roleLabel, "RIGHT", 0, 0)
    self.roleDropdown:SetOptions({"No Role", "Tank", "Healer", "DPS"})
    local savedRole = FrostSeekDB.LFG and (FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole or "No Role") or "No Role"
    self.roleDropdown:SetText(savedRole)
    self.roleDropdown.selectedValue = savedRole
    self.roleDropdown.onChange = function(val)
        LFG.SetRole(val)
    end
    self.title = self.mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("TOP", self.playerFrame, "BOTTOM", 0, -8)
    self.title:SetText("|cff88ccffLooking For Group|r")
    self.title:SetTextColor(unpack(_tc("textAccent")))
    local filterBtn = CreateFrame("Button", "FrostSeekLFGFilterBtn", self.mainContainer)
    filterBtn:SetSize(22, 22)
    filterBtn:SetPoint("LEFT", self.title, "RIGHT", 8, 0)
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
        GameTooltip:SetText("Activity Filter", 0.8, 0.9, 1)
        GameTooltip:AddLine("Click to configure which dungeons\nand raids appear in LFG", 0.8, 0.8, 0.8, true)
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
    self.lfgCountText:SetText("Active Recruiters: 0")
    self.lfgCountText:SetTextColor(unpack(_tc("textAccent")))
    self.searchFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.searchFrame:SetSize(740, 26)
    self.searchFrame:SetPoint("TOP", self.lfgCountText, "BOTTOM", 0, -4)
    local searchLabel = self.searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", self.searchFrame, "LEFT", 10, 0)
    searchLabel:SetText("Search:")
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
    local clearSearchBtn = FrostSeekUIUtils.CreateModernButton(self.searchFrame, 45, 18, "Clear", _tc("border"))
    clearSearchBtn:SetPoint("LEFT", self.lfgSearchBox, "RIGHT", 5, 0)
    clearSearchBtn:SetScript("OnClick", function()
        self.lfgSearchBox:SetText("")
        lfgSearchText = ""
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if lfgSearchDebounce and lfgSearchDebounce.Cancel then lfgSearchDebounce:Cancel() end
        LFG.UpdateRecruitersList()
    end)
    self.recruitersFrame = CreateFrame("Frame", nil, self.mainContainer)
    self.recruitersFrame:SetSize(740, 360)
    self.recruitersFrame:SetPoint("TOP", self.searchFrame, "BOTTOM", 0, -8)
    local recruitersBg = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    recruitersBg:SetAllPoints()
    recruitersBg:SetColorTexture(unpack(_tc("bgRowOdd")))
    self.lfgTabs = {}
    local lfgTabTypes = {"ALL", "DUNGEON", "RAID", "WORLD_BOSS", "PVP", "MANASTORM", "KEYSTONE"}
    local lfgTabNames = {"All", "Dungeon", "Raid", "WBoss", "PvP", "Mana", "Key"}
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
    headerFrame:SetSize(740, 18)
    headerFrame:SetPoint("TOPRIGHT", self.recruitersFrame, "TOPRIGHT", -24, -40)
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 18, 0)
    nameHeader:SetText("Player")
    nameHeader:SetTextColor(unpack(_tc("textAccent")))
    local timeHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeHeader:SetPoint("LEFT", headerFrame, "LEFT", 108, 0)
    timeHeader:SetText("Time")
    timeHeader:SetTextColor(unpack(_tc("textAccent")))
    local catHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catHeader:SetPoint("LEFT", headerFrame, "LEFT", 158, 0)
    catHeader:SetText("Type")
    catHeader:SetTextColor(unpack(_tc("textAccent")))
    local dungeonHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dungeonHeader:SetPoint("LEFT", headerFrame, "LEFT", 198, 0)
    dungeonHeader:SetText("Dungeon")
    dungeonHeader:SetTextColor(unpack(_tc("textAccent")))
    local msgHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msgHeader:SetPoint("LEFT", headerFrame, "LEFT", 290, 0)
    msgHeader:SetText("Message")
    msgHeader:SetTextColor(unpack(_tc("textAccent")))
    local acceptHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    acceptHeader:SetPoint("RIGHT", headerFrame, "RIGHT", -10, 0)
    acceptHeader:SetText("Action")
    acceptHeader:SetTextColor(unpack(_tc("textAccent")))
    local separator = self.recruitersFrame:CreateTexture(nil, "BACKGROUND")
    separator:SetPoint("TOP", headerFrame, "BOTTOM", 0, -2)
    separator:SetSize(740, 1)
    separator:SetColorTexture(unpack(_tc("separator")))
    local LIST_HEIGHT = 260
    MAX_DISPLAY_ROWS = math.floor(LIST_HEIGHT / ROW_HEIGHT)
    self.recruitersList = CreateFrame("Frame", nil, self.recruitersFrame)
    self.recruitersList:SetSize(740, LIST_HEIGHT)
    self.recruitersList:SetPoint("TOP", headerFrame, "BOTTOM", 0, -8)
    self.recruitersList:SetPoint("RIGHT", self.recruitersFrame, "RIGHT", -24, 0)

    self.recruitersScrollFrame = CreateFrame("ScrollFrame", "FrostSeekRecruitersScroll", self.recruitersFrame, "UIPanelScrollFrameTemplate")
    self.recruitersScrollFrame:SetPoint("TOPLEFT", self.recruitersList, "TOPLEFT", 0, 0)
    self.recruitersScrollFrame:SetPoint("BOTTOMRIGHT", self.recruitersList, "BOTTOMRIGHT", 0, 0)

    local scrollChild = CreateFrame("Frame", nil, self.recruitersScrollFrame)
    scrollChild:SetSize(740, LIST_HEIGHT)
    self.recruitersScrollFrame:SetScrollChild(scrollChild)
    self.recruitersList.scrollChild = scrollChild

    self.recruitersList.rows = {}
    LFG.noRecruitersText = self.recruitersList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    LFG.noRecruitersText:SetPoint("CENTER", self.recruitersList, "CENTER", 0, 0)
    LFG.noRecruitersText:SetText("No active recruiters found")
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
    self.controlsFrame:SetSize(740, 30)
    self.controlsFrame:SetPoint("BOTTOM", self.mainContainer, "BOTTOM", 0, 5)
    self.refreshBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 70, 22, "Refresh", _tc("primary"))
    self.refreshBtn:SetPoint("LEFT", self.controlsFrame, "LEFT", 10, -30)
    self.refreshBtn:SetScript("OnClick", function()
        if LFG.recruitersScrollFrame then LFG.recruitersScrollFrame:SetVerticalScroll(0) end
        if LFG.UpdateRecruitersList then LFG.UpdateRecruitersList() end
    end)
    self.clearAllBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 70, 22, "Clear All", _tc("catPvP"))
    self.clearAllBtn:SetPoint("LEFT", self.refreshBtn, "RIGHT", 5, 0)
    self.clearAllBtn:SetScript("OnClick", function()
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog("Clear All", "Clear all active LFG searches?", function()
                LFG.ClearAllSearches()
            end)
        else
            LFG.ClearAllSearches()
        end
    end)
    self.frostnetBtn = FrostSeekUIUtils.CreateModernButton(self.controlsFrame, 100, 22, "FrostNet", _tc("accent"))
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
}

local function IsAddonProtocolMessage(msg)
    if not msg then return false end
    if string.match(msg, "^FSK%d~") then
        return true
    end
    local _, count = string.gsub(msg, ":", "")
    if count < 2 then return false end
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
    FrostSeekDB.LFG.myRole = FrostSeekDB.LFG.myRole or "No Role"
    FrostSeekDB.LFG.popupCategories = FrostSeekDB.LFG.popupCategories or {
        ALL = true, DUNGEON = true, RAID = true, WORLD_BOSS = true, PVP = true, MANASTORM = true, KEYSTONE = true, CUSTOM = true
    }
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
    FrostSeekDB.LFG.frameDuration = FrostSeekDB.LFG.frameDuration or 6
    FrostSeekDB.LFG.popupCooldown = FrostSeekDB.LFG.popupCooldown or 400
    FrostSeekDB.LFG.maxConcurrentPopups = FrostSeekDB.LFG.maxConcurrentPopups or 3
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