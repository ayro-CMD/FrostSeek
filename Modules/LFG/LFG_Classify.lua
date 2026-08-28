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
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("lfg_classify", LFG)

local L = FrostSeek.L
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local activeSearches = LFG._S.activeSearches
local KEYSTONE_KEYWORDS = LFG.KEYSTONE_KEYWORDS
local RAID_KEYWORDS = LFG.RAID_KEYWORDS
local WORLD_BOSS_KEYWORDS = LFG.WORLD_BOSS_KEYWORDS
local PVP_KEYWORDS = LFG.PVP_KEYWORDS
local MANASTORM_KEYWORDS = LFG.MANASTORM_KEYWORDS
local DUNGEON_KEYWORDS = LFG.DUNGEON_KEYWORDS
local DUNGEON_WINGS = LFG.DUNGEON_WINGS
local DUNGEON_WING_LOOKUP = LFG.DUNGEON_WING_LOOKUP
local IsGenericWorldBossKeyword = LFG._IsGenericWorldBossKeyword

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
    "mdi", "server first", "top guild", "best guild","gf","which","every","recrute","days","kill",
    "world first", "qualif","girl","small","boy","goth","gnome","testing","dont",
    "awakening", "twisting","why","crafter","whick","professions","profession","reclutamos",
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
    "account", "heirloom","help","bazaar","token","don't", "shit","<Minimum effort>","<cleanse>",
    "wtt","how","do","pets","stress","test","here","xd","Minimum effort","cleanse",
    "farmers","chez","plf","test","pasticcio","nearby","never",
    "tSM", "mRP", "trp", "total rp","?","other","escort","rekrutac","recluta/e",
    "gamble", "bet", "wager", "jackpot", "lottery", "lucky draw", "spin the wheel",
    "selling.*run", "gold.*run","where is","24/7","recherche","roaster",
    "alchemy", "alch", "blacksmithing", "bs", "enchanting", "ench", "engineering", "eng", "inscription",
    "jewelcrafting", "jc", "leatherworking", "lw", "tailoring", "skinning", "mining",
    "herbalism", "herb", "herbalist", "first aid", "fishing", "archaeology", "arch",
    "prospecting", "milling", "smelting", "lf crafter", "lf craft",
    "looking for crafter", "need crafter", "craft", "crafting for",
    "wts craft", "wtb craft", "crafting service", "lw service", "bs service",
    "enchant service", "jc service", "alch service", "lf enchanter", "lf bs", "lf lw",
    "lf jc", "lf alch", "lf eng", "lf tailor", "lf miner", "lf herbalist",
    "lf skinner", "lf crafter", "crafting lf", "enchanting lf", "smelting lf",
    "cooking", "lf cook", " Cooking ","enchant","reclutamos","recrutando","imortal",
    "raid on wednesday", "raid on thursday", "raid on friday", "raid on saturday",
    "raid on sunday", "raid on monday", "raid on tuesday",
    "levelers", "leveler", "raiding", "raider", "mythic team", "heroic team",
    "gchat", "g-chat", "guildchat", "gchat","linkin","Guilde",
    "scheduled", "roster", "statics", "progression",
    "casuals", "casual", "hardcore", "semihardcore", "semi-hardcore",
    "america", "europe", "oceanic", "na-based", "eu-based", "na based", "eu based",
    "whisper me", "dm me", "pst me",
    "discord", "voice comms", "voice chat", "mumble", "teamspeak",
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
    "chill gamers", "make friends", "laid-back", "laid back", "laidback setting",
    "levelers welcome", "leveler welcome", "levelers welcome", "leveling welcome",
    "push keys", "push heroic", "push mythic", "pushing keys", "pushing heroic",
    "raids are @", "raid is @", "raid at ", "raids at ",
    "no weekends", "weekend raid", "weekend run",
    "m-th", "t-th", "w-f", "m-w", "m-f", "f-sun", "sun-thu", "mon-thu",
    "7pm est", "8pm est", "9pm est", "7pm cst", "8pm cst", "9pm cst",
    "7pm server", "8pm server", "9pm server", "server time",
    "pst for more", "pst for info", "pst for details", "whisper for more",
    "is lfm ", "is lfm chill", "is recruiting", "is looking for members",
    "is looking for", "we are lfm", "we are looking", "we're lfm", "we're looking",
    "all raids cleared", "all raid cleared", "raids cleared",
    "casual setting", "casual raiding", "casual group",
    "static raid", "static group", "static roster",
    "raid schedule", "raid sched", "raid nights", "raid night",
    "core raid", "core roster", "core spot", "core team",
    "mythic team", "heroic team", "progression team",
    "looking for chill", "looking for casual", "looking for mature",
    "recruiting dps", "recruiting healers", "recruiting tanks",
    "need healer for guild", "need tank for guild",
    "raid log", "raid logger", "raid logging",
    "two day raid", "three day raid", "2 day raid", "3 day raid",
    "wed sun", "tue sun", "mon wed", "tue thu",
    "static schedule", "schedule:", "schedule -", "schedule is",
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

    local hasStrongLFG =
        string.match(lowerMsg, "lf%d+m") ~= nil or
        string.match(lowerMsg, "lf%d") ~= nil or
        string.find(lowerMsg, "%f[%a]lfm%f[^%a]") ~= nil or
        string.find(lowerMsg, "%f[%a]lfg%f[^%a]") ~= nil or
        string.match(lowerMsg, "^lfm") ~= nil or
        string.match(lowerMsg, "%slfm") ~= nil or
        string.match(lowerMsg, "^lfg") ~= nil or
        string.match(lowerMsg, "%slfg") ~= nil or
        string.find(lowerMsg, "need%s+tank") ~= nil or
        string.find(lowerMsg, "need%s+heal") ~= nil or
        string.find(lowerMsg, "need%s+dps") ~= nil or
        string.find(lowerMsg, "need%s+support") ~= nil or
        string.find(lowerMsg, "need%s+supp") ~= nil or
        string.find(lowerMsg, "1tank") ~= nil or
        string.find(lowerMsg, "1heal") ~= nil or
        string.find(lowerMsg, "1dps") ~= nil or
        string.find(lowerMsg, "%dtank") ~= nil or
        string.find(lowerMsg, "%dheal") ~= nil or
        string.find(lowerMsg, "%ddps") ~= nil or
        string.find(lowerMsg, "looking%s+for%s+group") ~= nil or
        string.find(lowerMsg, "looking%s+for%s+more") ~= nil or
        string.find(lowerMsg, "looking%s+for%s+members") ~= nil or
        string.match(lowerMsg, "%s%d+/%d+%s") ~= nil or
        string.match(lowerMsg, "^%d+/%d+%s") ~= nil or
        string.match(lowerMsg, "%s%d+/%d+$") ~= nil

    if hasStrongLFG then
        if longSpamHits >= 3 then return true end
        if longSpamHits >= 2 and shortSpamHits >= 1 then return true end
        if longSpamHits >= 1 and shortSpamHits >= 3 then return true end
        if shortSpamHits >= 5 then return true end
        return false
    end

    if longSpamHits >= 1 then
        return true
    end
    return shortSpamHits >= 2
end

local GUILD_RECRUIT_PATTERNS = {
    "is lfm%s",
    "is lfg%s",
    "is recruiting",
    "is looking for members",
    "is looking for chill",
    "is looking for casual",
    "we are lfm",
    "we are recruiting",
    "we are looking for members",
    "we're lfm",
    "we're recruiting",
    "we're looking for members",
    "is now recruiting",
    "currently recruiting",
    "now recruiting",
    "active recruitment",
    "open recruitment",
    "casual guild",
    "hardcore guild",
    "semi-hardcore guild",
    "pve guild",
    "pvp guild",
    "leveling guild",
    "social guild",
    "friendly guild",
    "mythic raiding guild",
    "top guild",
    "best guild",
    "gildia",
    "new guild",
    "our guild",
    "this guild",
    "the guild is",
    "guild is looking",
    "guild lf",
    "guild recruiting",
    "guild recruitment",
    "guild seeks",
    "guild wants",
    "gilda cerca",
    "gilda recluta",
    "gilda cerca",
    "hermandad busca",
    "guilde recrute",
    "gilde sucht",
    "^%s*<[gG][^>]+>%s",
    "^%s*%[[gG][^%]]+%]%s",
}

local GUILD_RECRUIT_INDICATORS = {
    "chill", "casual", "hardcore", "laid", "levelers", "leveler",
    "make friends", "push keys", "push heroic", "push mythic",
    "raid schedule", "raid night", "raid nights", "raid log",
    "static", "progression", "core team", "core spot",
    "discord.gg", "discord server", "voice comms", "voice chat",
    "na-based", "eu-based", "na based", "eu based","guilde",
    "america", "europe", "oceanic", "est", "cst", "pst", "server time",
    "no weekends", "m-th", "t-th", "w-f", "wed sun",
}

local function IsGuildRecruitmentMessage(msg)
    if not msg or msg == "" then return false end
    local lowerMsg = string.lower(msg)
    for _, pat in ipairs(GUILD_RECRUIT_PATTERNS) do
        if string.find(lowerMsg, pat) then
            return true
        end
    end

    local hasLFM = string.find(lowerMsg, "%f[%a]lfm%f[^%a]") ~= nil
                   or string.find(lowerMsg, "%f[%a]lfg%f[^%a]") ~= nil
                   or string.find(lowerMsg, "lf%d*m") ~= nil
                   or string.find(lowerMsg, "lf%d*g") ~= nil
    if hasLFM then
        local indicatorHits = 0
        for _, ind in ipairs(GUILD_RECRUIT_INDICATORS) do
            if string.find(lowerMsg, ind, 1, true) then
                indicatorHits = indicatorHits + 1
            end
        end

        if indicatorHits >= 2 then
            return true
        end
    end
    return false
end

local INFO_REQUEST_PATTERNS = {
    -- Inglese
    "%f[%a]questions%f[^%a]", "%f[%a]tips%f[^%a]", "%f[%a]advice%f[^%a]",
    "how to", "how do", "how does", "how can", "anyone know", "anybody know",
    "does anyone", "any suggestion", "someone explain", "can someone explain",
    "teach me", "%f[%a]coach%f[^%a]", "%f[%a]explain%f[^%a]",
    -- Italiano
    "%f[%a]domande%f[^%a]", "%f[%a]consigli%f[^%a]", "come si", "qualcuno sa",
    "qualcuno conosce", "spiegazioni", "spiegarmi", "aiuto con", "%f[%a]dubbi%f[^%a]",
    -- Spagnolo
    "%f[%a]preguntas%f[^%a]", "%f[%a]consejos%f[^%a]", "alguien sabe",
    "alguien conoce", "como se", "%f[%a]dudas%f[^%a]",
    -- Tedesco
    "%f[%a]fragen%f[^%a]", "%f[%a]tipps%f[^%a]", "kann mir jemand",
    "%f[%a]ratschl",
    -- Francese
    "%f[%a]conseils%f[^%a]", "quelqu. sait", "quelqu. connait",
    -- Portoghese
    "%f[%a]duvidas%f[^%a]", "%f[%a]dúvidas%f[^%a]", "alguem sabe", "alguém sabe",
    "%f[%a]perguntas%f[^%a]", "%f[%a]conselhos%f[^%a]",
}

local GROUP_COMPOSITION_SIGNALS = {
    "%f[%a]tank%f[^%a]", "%f[%a]tanks%f[^%a]", "%f[%a]heal%f[^%a]", "%f[%a]healer%f[^%a]",
    "%f[%a]healers%f[^%a]", "%f[%a]dps%f[^%a]", "%f[%a]support%f[^%a]", "%f[%a]supp%f[^%a]",
    "%f[%a]dd%f[^%a]", "%f[%a]mdps%f[^%a]", "%f[%a]rdps%f[^%a]",
    "%d+%s*/%s*%d+",
    "%[keystone:",
    "%f[%a]lfm%f[^%a]", "%f[%a]lf%dm%f[^%a]",
}

function LFG.IsInfoRequestMessage(msg)
    if not msg or msg == "" then return false end
    local lowerMsg = string.lower(msg)
    local hasInfoPattern = false
    for _, pat in ipairs(INFO_REQUEST_PATTERNS) do
        if string.find(lowerMsg, pat) then
            hasInfoPattern = true
            break
        end
    end
    if not hasInfoPattern then return false end
    for _, sig in ipairs(GROUP_COMPOSITION_SIGNALS) do
        if string.find(lowerMsg, sig) then
            return false
        end
    end
    return true
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

function LFG.ParseDungeonWing(message, category, dungeon)
    if not message or message == "" then return nil end
    local lowerMsg = string.lower(message)
    local entry = dungeon and DUNGEON_WING_LOOKUP[string.upper(tostring(dungeon))] or nil
    if not entry then
        for _, e in ipairs(DUNGEON_WINGS) do
            for _, kw in ipairs(e.keywords) do
                if wholeWordFind(lowerMsg, kw) then
                    entry = e
                    break
                end
            end
            if entry then break end
        end
    end
    if not entry and category == "KEYSTONE" and wholeWordFind(lowerMsg, "dm") then
        entry = DUNGEON_WING_LOOKUP["DM"]
    end
    if not entry then return nil end
    for _, wing in ipairs(entry.wings) do
        for _, kw in ipairs(wing.keywords) do
            if wholeWordFind(lowerMsg, kw) then
                return wing.name, wing.short, entry.name, entry.id
            end
        end
    end
    return nil, nil, entry.name, entry.id
end

function LFG.ParseKeystoneLevel(message)
    if not message then return nil end
    local _, level = LFG.ParseKeystoneInfo(message)
    if level then return level end
    local lvl = string.match(message, "%+(%d+)")
    if lvl then return tonumber(lvl) end
    local lowerMsg = string.lower(message)
    lvl = string.match(lowerMsg, "%sm(%d+)")
    if lvl then return tonumber(lvl) end
    lvl = string.match(lowerMsg, "^m(%d+)")
    if lvl then return tonumber(lvl) end
    lvl = string.match(message, "%((%d+)%)")
    if lvl then return tonumber(lvl) end
    return nil
end

local RAID_ICON_TEXTURES = {
    ["star"]     = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    ["circle"]   = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
    ["diamond"]  = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    ["triangle"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
    ["moon"]     = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
    ["square"]   = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    ["cross"]    = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    ["skull"]    = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    ["x"]        = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    ["todo"]     = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
}

function LFG.FormatMessageWithIcons(msg)
    if not msg or msg == "" then return msg end
    return (string.gsub(msg, "%{(%a+)%}", function(name)
        local lower = string.lower(name)
        local tex = RAID_ICON_TEXTURES[lower]
        if tex then
            return "|T" .. tex .. ":14:14:0:0|t"
        end
        return name
    end))
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
       string.match(lowerMsg, "^need%s+support") or string.match(lowerMsg, "^need%s+supp") or
       string.match(lowerMsg, "^lf%s+[thd]%f[%A]") or string.match(lowerMsg, "^lf%s+tank") or
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

    if string.match(lowerMsg, "%f[%a]lf[ %p].*dps") or string.match(lowerMsg, "%f[%a]lf[ %p].*dd") or
       string.match(lowerMsg, "%f[%a]lf[ %p].*dmg") or
       string.match(lowerMsg, "%f[%a]need[ %p].*dps") or
       string.match(lowerMsg, "%f[%a]need[ %p].*dd") or
       string.match(lowerMsg, "%f[%a]need[ %p].*tank") or
       string.match(lowerMsg, "%f[%a]need[ %p].*heal") or
       string.match(lowerMsg, "%f[%a]need[ %p].*support") or
       string.match(lowerMsg, "%f[%a]need[ %p].*supp") or
       string.match(lowerMsg, "%f[%a]lf[ %p].*tank") or
       string.match(lowerMsg, "%f[%a]lf[ %p].*heal") or
       string.match(lowerMsg, "%f[%a]lf[ %p].*support") or
       string.match(lowerMsg, "%f[%a]lf[ %p].*supp") then
        return true
    end
    if string.find(lowerMsg, "lfm") or string.find(lowerMsg, "lfg") then return true end
    if string.match(lowerMsg, "%f[%a]lf%d") then return true end
    if string.find(lowerMsg, " lf ") or string.find(lowerMsg, "^lf ") then return true end
    if string.match(lowerMsg, "last%s*spot") or string.match(lowerMsg, "need%s+%d") then return true end
    if string.match(lowerMsg, "%f[%a]inv%f[%A]") and (string.find(lowerMsg, "whisper") or string.find(lowerMsg, "wisp") or string.match(lowerMsg, "%f[%a]pm%f[%A]")) then return true end
    if string.match(lowerMsg, "g2g") then return true end
    if string.match(lowerMsg, "^%d+/%d+%s") or string.match(lowerMsg, "%s%d+/%d+%s") or string.match(lowerMsg, "%s%d+/%d+$") then return true end
    if string.match(lowerMsg, "tank/heal") or string.match(lowerMsg, "heal/tank") or string.match(lowerMsg, "tank%/heal") then return true end
    if string.match(lowerMsg, "^%d+%s+[thd]%f[%A]") or string.match(lowerMsg, "^%d+%s+tank") or string.match(lowerMsg, "^%d+%s+heal") or string.match(lowerMsg, "^%d+%s+dps") or string.match(lowerMsg, "^%d+%s+support") or string.match(lowerMsg, "^%d+%s+supp") then return true end
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
            if string.match(lowerMsg, "^%a+%s+lf[ %p]+%a*heal") or
               string.match(lowerMsg, "^%a+%s+lf[ %p]+%a*tank") or
               string.match(lowerMsg, "^%a+%s+lf[ %p]+%a*dps") or
               string.match(lowerMsg, "^%a+%s+lf[ %p]+%a*support") or
               string.match(lowerMsg, "^%a+%s+lf[ %p]+%a*supp") then
                return false
            end
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
        if string.match(lowerMsg, "^%d+%s+dps%s+lf") or
           string.match(lowerMsg, "^%d+%s+tank%s+lf") or
           string.match(lowerMsg, "^%d+%s+heal[a-z]*%s+lf") or
           string.match(lowerMsg, "^%d+%s+support%s+lf") or
           string.match(lowerMsg, "^%d+%s+supp%s+lf") then
            return true
        end
        if string.match(lowerMsg, "^%d+%s+dps%s+%a+%s+lf") or
           string.match(lowerMsg, "^%d+%s+tank%s+%a+%s+lf") or
           string.match(lowerMsg, "^%d+%s+heal[a-z]*%s+%a+%s+lf") or
           string.match(lowerMsg, "^%d+%s+support%s+%a+%s+lf") or
           string.match(lowerMsg, "^%d+%s+supp%s+%a+%s+lf") then
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
    if string.match(lowerMsg, "lf[ %p]+%a*heal") or
       string.match(lowerMsg, "lf[ %p]+%a*tank") or
       string.match(lowerMsg, "lf[ %p]+%a*dps") or
       string.match(lowerMsg, "lf[ %p]+%a*support") or
       string.match(lowerMsg, "lf[ %p]+%a*supp") or
       string.match(lowerMsg, "lf[ %p]+%d[%d%s%p]*heal") or
       string.match(lowerMsg, "lf[ %p]+%d[%d%s%p]*tank") or
       string.match(lowerMsg, "lf[ %p]+%d[%d%s%p]*dps") or
       string.match(lowerMsg, "lf[ %p]+%d[%d%s%p]*support") or
       string.match(lowerMsg, "lf[ %p]+%d[%d%s%p]*supp") then return "LFM" end
    if string.match(lowerMsg, "lf%d*[ %p]+%d*[%s%p]*heal") or
       string.match(lowerMsg, "lf%d*[ %p]+%d*[%s%p]*tank") or
       string.match(lowerMsg, "lf%d*[ %p]+%d*[%s%p]*dps") or
       string.match(lowerMsg, "lf%d*[ %p]+%d*[%s%p]*support") or
       string.match(lowerMsg, "lf%d*[ %p]+%d*[%s%p]*supp") then return "LFM" end
    if string.match(lowerMsg, "^%d+%s+tank") or string.match(lowerMsg, "^%d+%s+heal") or
       string.match(lowerMsg, "^%d+%s+dps") or string.match(lowerMsg, "^%d+%s+support") or
       string.match(lowerMsg, "^%d+%s+supp") then return "LFM" end
    if string.match(lowerMsg, "lf%s+dg") or string.match(lowerMsg, "lf%s+rdf") then return "LFG" end
    if string.match(lowerMsg, "inv%s+me") or string.match(lowerMsg, "^inv%s*$") then return "LFG" end

    return "LFG"
end
function LFG.ClassifyPvP(lowerMsg)
    if not lowerMsg then return "PVP", false end
    local isRanked = false
    if string.find(lowerMsg, "ranked") or string.find(lowerMsg, "rank") then
        isRanked = true
    elseif string.find(lowerMsg, "yolo") then
        isRanked = true
    elseif string.find(lowerMsg, "rating") or string.find(lowerMsg, "cr ") or string.find(lowerMsg, "%scr") then
        isRanked = true
    end

    if wholeWordFind(lowerMsg, "2v2") or wholeWordFind(lowerMsg, "2s") then
        return "ARENA_2V2", isRanked
    end
    if wholeWordFind(lowerMsg, "3v3") or wholeWordFind(lowerMsg, "3s") then
        return "ARENA_3V3", isRanked
    end
    if wholeWordFind(lowerMsg, "5v5") or wholeWordFind(lowerMsg, "5s") then
        return "ARENA_5V5", isRanked
    end
    if wholeWordFind(lowerMsg, "arena") then
        return "ARENA", isRanked
    end
    if wholeWordFind(lowerMsg, "wsg") or wholeWordFind(lowerMsg, "warsong") then
        return "BG_WSG", false
    end
    if wholeWordFind(lowerMsg, "ab") or wholeWordFind(lowerMsg, "arathi") then
        return "BG_AB", false
    end
    if wholeWordFind(lowerMsg, "av") or wholeWordFind(lowerMsg, "alterac") then
        return "BG_AV", false
    end
    if wholeWordFind(lowerMsg, "eots") then
        return "BG_EOTS", false
    end
    if wholeWordFind(lowerMsg, "wg") or wholeWordFind(lowerMsg, "wintergrasp") then
        return "BG_WG", false
    end
    if wholeWordFind(lowerMsg, "bg") or wholeWordFind(lowerMsg, "battleground") then
        return "BATTLEGROUND", false
    end
    return "PVP", isRanked
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
            local keystoneNameChecks = {
                { "stratholme", "STRAT" }, { "strath", "STRAT" }, { "strat", "STRAT" },
                { "dire maul", "DM" },
                { "blackrock depths", "BRD" },
                { "scholomance", "SCHOLO" }, { "scholo", "SCHOLO" },
                { "lower blackrock spire", "LBRS" }, { "lbrs", "LBRS" },
                { "upper blackrock spire", "UBRS" }, { "ubrs", "UBRS" },
                { "molten core", "MC" },
                { "maraudon", "MARA" }, { "mara", "MARA" },
                { "wailing caverns", "WC" }, { "wailing", "WC" },
                { "shadowfang keep", "SFK" }, { "shadowfang", "SFK" }, { "sfk", "SFK" },
                { "scarlet monastery", "SM" }, { "scarlet", "SM" },
                { "dme", "DM" }, { "dmn", "DM" }, { "dmw", "DM" }, { "brd", "BRD" }, { "mc", "MC" },
            }
            for _, check in ipairs(keystoneNameChecks) do
                if string.find(dungeonName, check[1], 1, true) then
                    return "KEYSTONE", check[2], false, false, false, true, false
                end
            end
            for _, d in ipairs(DUNGEON_KEYWORDS) do
                if string.find(dungeonName, d) then
                    return "KEYSTONE", string.upper(d), false, false, false, true, false
                end
            end
            return "KEYSTONE", "KEYSTONE", false, false, false, true, false
        end
    end
    local wbGenericMatch = nil
    for _, kw in ipairs(WORLD_BOSS_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            if not IsGenericWorldBossKeyword(kw) then
                return "WORLD_BOSS", string.upper(kw), false, false, false, false, false
            elseif not wbGenericMatch then
                wbGenericMatch = kw
            end
        end
    end
    if wbGenericMatch then
        return "WORLD_BOSS", string.upper(wbGenericMatch), false, false, false, false, false
    end
    for _, kw in ipairs(KEYSTONE_KEYWORDS) do
        if wholeWordFind(lowerMsg, kw) then
            if wholeWordFind(lowerMsg, "stratholme") or wholeWordFind(lowerMsg, "strath") or wholeWordFind(lowerMsg, "strat") then
                return "KEYSTONE", "STRAT", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "dire maul") or wholeWordFind(lowerMsg, "dme") or wholeWordFind(lowerMsg, "dmn") or wholeWordFind(lowerMsg, "dmw") then
                return "KEYSTONE", "DM", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "brd") or wholeWordFind(lowerMsg, "blackrock depths") then
                return "KEYSTONE", "BRD", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "scholomance") or wholeWordFind(lowerMsg, "scholo") then
                return "KEYSTONE", "SCHOLO", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "lbrs") or wholeWordFind(lowerMsg, "lower blackrock spire") then
                return "KEYSTONE", "LBRS", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "ubrs") or wholeWordFind(lowerMsg, "upper blackrock spire") then
                return "KEYSTONE", "UBRS", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "maraudon") or wholeWordFind(lowerMsg, "mara") then
                return "KEYSTONE", "MARA", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "shadowfang") or wholeWordFind(lowerMsg, "sfk") then
                return "KEYSTONE", "SFK", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "scarlet monastery") or wholeWordFind(lowerMsg, "sm") then
                return "KEYSTONE", "SM", false, false, false, true, false
            elseif wholeWordFind(lowerMsg, "molten core") or wholeWordFind(lowerMsg, "mc") then
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
            local pvpSub, pvpRanked = LFG.ClassifyPvP(lowerMsg)
            return "PVP", pvpSub, false, false, false, false, true, pvpRanked
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
            local isMythic = wholeWordFind(lowerMsg, "mythic") or
                             wholeWordFind(lowerMsg, "m+") or
                             string.match(lowerMsg, "%sm(%d+)") or
                             string.match(lowerMsg, "^m(%d+)")
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

function LFG.GetPlayerSpec()
    if GetSpecialization and GetSpecializationInfo then
        local ok, specIndex = pcall(GetSpecialization)
        if ok and specIndex then
            local ok2, _, specName = pcall(GetSpecializationInfo, specIndex)
            if ok2 and specName and specName ~= "" then
                return specName
            end
        end
    end
    if GetPrimaryTalentTree and GetTalentTabInfo then
        local ok, primaryTab = pcall(GetPrimaryTalentTree)
        if ok and primaryTab then
            local ok2, tabName = pcall(GetTalentTabInfo, primaryTab)
            if ok2 and tabName and tabName ~= "" then
                return tabName
            end
        end
    end
    if GetNumTalentTabs and GetTalentTabInfo then
        local okN, numTabs = pcall(GetNumTalentTabs)
        if okN and numTabs and numTabs > 0 then
            local bestName, bestPoints
            for i = 1, numTabs do
                local ok, tabName, _, pointsSpent = pcall(GetTalentTabInfo, i)
                if ok and tabName then
                    local pts = tonumber(pointsSpent) or 0
                    if not bestPoints or pts > bestPoints then
                        bestPoints = pts
                        bestName = tabName
                    end
                end
            end
            if bestName and bestName ~= "" and (bestPoints or 0) > 0 then
                return bestName
            end
        end
    end
    if FrostSeekDB and FrostSeekDB.Profile and FrostSeekDB.Profile.spec
        and FrostSeekDB.Profile.spec ~= "" then
        return FrostSeekDB.Profile.spec
    end
    return ""
end

function LFG.GetSpecWithEnchant()
    local enchant = LFG.GetLegendaryEnchant()
    local spec = LFG.GetPlayerSpec()
    if enchant and enchant ~= "" then
        if spec and spec ~= "" then
            return spec .. " " .. enchant
        end
        return enchant
    end
    return spec or ""
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
    return classMap[classFile] or className or L["unknown"]
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
    local specValue = LFG.GetSpecWithEnchant()
    local roleText = FrostSeekDB.LFG.myRole ~= "" and FrostSeekDB.LFG.myRole ~= L["none"] and FrostSeekDB.LFG.myRole or ""
    local playerLevel = UnitLevel("player") or 0
    if FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled then
        local template = FrostSeekDB.LFG.customMessages.template or "inv {role} {class} {spec} {ilvl} ilvl"
        local message = template
        message = string.gsub(message, "{class}", classInfo or "")
        message = string.gsub(message, "{ilvl}", tostring(ilvl or 0))
        message = string.gsub(message, "{gs}", "")
        message = string.gsub(message, "{ench}", enchant or "")
        message = string.gsub(message, "{spec}", specValue or "")
        message = string.gsub(message, "{role}", roleText or "")
        message = string.gsub(message, "{level}", tostring(playerLevel))
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
    print(L["msg_role_set_to_lfg"] .. role)
end

SLASH_FSKEYTEST1 = "/fskeytest"
SlashCmdList["FSKEYTEST"] = function(msg)
    if not msg or msg == "" then
        print("|cff88ccffUso:|r /fskeytest <messaggio con keystone>")
        print("  Esempio: /fskeytest LF TANK [Keystone: Maraudon (6)]")
        return
    end
    print("|cff88ccff=== Keystone Parser Test ===|r")
    print("  Input: " .. msg)
    local category, dungeon, isHeroic, isMythic, isRaid, isKeystone = LFG.ClassifyMessage(msg)
    print("  Categoria: " .. tostring(category))
    print("  Dungeon: " .. tostring(dungeon))
    print("  isKeystone: " .. tostring(isKeystone))
    local ksName, ksLevel = LFG.ParseKeystoneInfo(msg)
    print("  ksName: " .. tostring(ksName))
    print("  ksLevel: " .. tostring(ksLevel))
    if ksName and ksName ~= "" then
        local linkBase, linkWing = LFG.SplitKeystoneWingName(ksName)
        if linkWing then
            print("  KsSplit: " .. tostring(linkBase) .. " / " .. tostring(linkWing))
        end
    end
    if not ksLevel then
        print("  ksLevel (fallback): " .. tostring(LFG.ParseKeystoneLevel(msg)))
    end
    local wingName, wingShort, wingParentName, wingParentId = LFG.ParseDungeonWing(msg, category, dungeon)
    print("  Wing: " .. tostring(wingName) .. " (" .. tostring(wingShort) .. ")")
    print("  WingDungeon: " .. tostring(wingParentName) .. " [" .. tostring(wingParentId) .. "]")
    local minLevel = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.keystoneMinLevel or 0
    print("  keystoneMinLevel (DB): " .. tostring(minLevel))
    if isKeystone and minLevel and minLevel > 0 and ksLevel then
        local wouldFilter = ksLevel < minLevel
        print("  Filtro attivo: " .. tostring(wouldFilter) .. " (level " .. tostring(ksLevel) .. " < min " .. tostring(minLevel) .. ")")
    end
end

function LFG.ApplyKeystoneMinLevelFilter()
    if not activeSearches then return end
    local minLevel = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.keystoneMinLevel or 0
    if not minLevel or minLevel <= 0 then return end
    local removed = 0
    for i = #activeSearches, 1, -1 do
        local record = activeSearches[i]
        if record and record.isKeystone then
            local _, ksLevel = LFG.ParseKeystoneInfo(record.message)
            if ksLevel and ksLevel < minLevel then
                table.remove(activeSearches, i)
                removed = removed + 1
            end
        end
    end
    if removed > 0 then
    end
end

function LFG.RecordActiveSearch(sender, message, channel)
    local lowerMsg = string.lower(message)
    if IsSpamMessage(message) then
        return
    end
    if IsGuildRecruitmentMessage(message) then
        return
    end

    if LFG.IsInfoRequestMessage(message) then
        return
    end
    local category, dungeon, isHeroic, isMythic, isRaid, isKeystone, isPvp, isRanked = LFG.ClassifyMessage(message)
    if not LFG.PassesActivityFilter(category, dungeon) then
        return
    end
    if isKeystone and FrostSeekDB.LFG.keystoneMinLevel and FrostSeekDB.LFG.keystoneMinLevel > 0 then
        local _, ksLevel = LFG.ParseKeystoneInfo(message)
        if ksLevel and ksLevel < FrostSeekDB.LFG.keystoneMinLevel then
            return
        end
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
            record._ksLevel = nil
            record.lastUpdate = now
            record.dungeon = dungeon
            record.dungeonName = LFG.GetCanonicalDungeonName(category, dungeon)
            record.category = category
            record.isHeroic = isHeroic
            record.isMythic = isMythic
            record.isRaid = isRaid
            record.isPvp = isPvp
            record.isRanked = isRanked or false
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
        dungeonName = LFG.GetCanonicalDungeonName(category, dungeon),
        category = category,
        isHeroic = isHeroic,
        isMythic = isMythic,
        isRaid = isRaid,
        isPvp = isPvp,
        isRanked = isRanked or false,
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
            record.dungeonName = listing.activity
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
        dungeonName = listing.activity,
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
        { keywords = {"ascended", "%f[%a%d]asc%f[^%a%d]"}, label = "Ascended" },
        { keywords = {"trial 10", "trial10", "%f[%a%d]t10%f[^%a%d]"}, label = "Trial 10" },
        { keywords = {"trial 9", "trial9", "%f[%a%d]t9%f[^%a%d]"}, label = "Trial 9" },
        { keywords = {"trial 8", "trial8", "%f[%a%d]t8%f[^%a%d]"}, label = "Trial 8" },
        { keywords = {"trial 7", "trial7", "%f[%a%d]t7%f[^%a%d]"}, label = "Trial 7" },
        { keywords = {"trial 6", "trial6", "%f[%a%d]t6%f[^%a%d]"}, label = "Trial 6" },
        { keywords = {"trial 5", "trial5", "%f[%a%d]t5%f[^%a%d]"}, label = "Trial 5" },
        { keywords = {"trial 4", "trial4", "%f[%a%d]t4%f[^%a%d]"}, label = "Trial 4" },
        { keywords = {"trial 3", "trial3", "%f[%a%d]t3%f[^%a%d]"}, label = "Trial 3" },
        { keywords = {"trial 2", "trial2", "%f[%a%d]t2%f[^%a%d]"}, label = "Trial 2" },
        { keywords = {"trial 1", "trial1", "%f[%a%d]t1%f[^%a%d]"}, label = "Trial 1" },
        { keywords = {"mythic"}, label = "Mythic" },
        { keywords = {"heroic", "hc"}, label = "Heroic" },
        { keywords = {"normal", "norm", "%f[%a%d]nm%f[^%a%d]"}, label = "Normal" },
    },
    DUNGEON = {
        { keywords = {"mythic", "m%+", "mythic%+"}, label = "Mythic" },
        { keywords = {"heroic", "hc"}, label = "Heroic" },
        { keywords = {"normal", "norm", "%f[%a%d]nm%f[^%a%d]"}, label = "Normal" },
    },
    WORLD_BOSS = {
        { keywords = {"ascended", "asc%d", "%f[%a%d]asc%f[^%a%d]"}, label = "Ascended" },
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

local DIFFICULTY_ANCHOR_KEYWORDS = {
    RAID = RAID_KEYWORDS,
    DUNGEON = DUNGEON_KEYWORDS,
    WORLD_BOSS = WORLD_BOSS_KEYWORDS,
}

function LFG.ParseDifficulty(message, category)
    if not message or not category then return nil end
    local lowerMsg = string.lower(message)
    local patterns = DIFFICULTY_PATTERNS[category]
    if not patterns then return nil end
    local matches = {}
    for order, entry in ipairs(patterns) do
        for _, kw in ipairs(entry.keywords) do
            local isPattern = string.find(kw, "%%", 1, true) ~= nil
            local startPos = 1
            while startPos <= #lowerMsg do
                local s
                if isPattern then
                    s = string.match(lowerMsg, "()" .. kw, startPos)
                else
                    s = string.find(lowerMsg, kw, startPos, true)
                end
                if not s then break end
                table.insert(matches, { pos = s, label = entry.label, order = order })
                startPos = s + 1
                if #matches > 50 then break end
            end
            if #matches > 50 then break end
        end
        if #matches > 50 then break end
    end
    if #matches == 0 then return nil end
    local anchorPos = nil
    local anchorList = DIFFICULTY_ANCHOR_KEYWORDS[category]
    if anchorList then
        for _, kw in ipairs(anchorList) do
            local s = string.find(lowerMsg, kw, 1, true)
            if s and (not anchorPos or s < anchorPos) then
                anchorPos = s
            end
        end
    end
    if anchorPos then
        local best
        for _, m in ipairs(matches) do
            local dist = math.abs(m.pos - anchorPos)
            if not best or dist < best.dist or (dist == best.dist and m.order < best.order) then
                best = { dist = dist, label = m.label, order = m.order, pos = m.pos }
            end
        end
        return best.label
    end
    local best
    for _, m in ipairs(matches) do
        if not best or m.pos < best.pos or (m.pos == best.pos and m.order < best.order) then
            best = m
        end
    end
    return best and best.label or nil
end

local function lower_cyrillic(s)
    if not s then return s end
    local out = {}
    local i = 1
    local len = #s
    while i <= len do
        local b1 = string.byte(s, i)
        if b1 == 0xD0 and i + 1 <= len then
            local b2 = string.byte(s, i + 1)
            if b2 >= 0x90 and b2 <= 0x9F then
                table.insert(out, string.char(0xD0, b2 + 0x20))
                i = i + 2
            elseif b2 >= 0xA0 and b2 <= 0xAF then
                table.insert(out, string.char(0xD1, b2 - 0x20))
                i = i + 2
            else
                table.insert(out, string.char(b1, b2))
                i = i + 2
            end
        else
            table.insert(out, string.char(b1))
            i = i + 1
        end
    end
    return table.concat(out)
end

local function is_ascii_kw(kw)
    for i = 1, #kw do
        if string.byte(kw, i) > 127 then return false end
    end
    return true
end

function LFG.ParseRoles(message)
    if not message then return { tank = 0, healer = 0, dps = 0, support = 0 } end
    local roles = { tank = 0, healer = 0, dps = 0, support = 0 }
    local lowerMsg = lower_cyrillic(string.lower(message))

    local function count_role(roleKeywords)
        local total = 0
        local pos = 1
        local len = #lowerMsg
        while pos <= len do
            local best_kw = nil
            local best_end = nil
            local best_len = 0
            for _, kw in ipairs(roleKeywords) do
                local s, e = string.find(lowerMsg, kw, pos, true)
                if s == pos then
                    local ok_boundary = true
                    if is_ascii_kw(kw) and pos > 1 then
                        local prev_byte = string.byte(lowerMsg, pos - 1)
                        if (prev_byte >= 48 and prev_byte <= 57)
                           or (prev_byte >= 65 and prev_byte <= 90)
                           or (prev_byte >= 97 and prev_byte <= 122) then
                            ok_boundary = false
                        end
                    end
                    if ok_boundary then
                        local kw_len = e - s + 1
                        if kw_len > best_len then
                            best_len = kw_len
                            best_kw = kw
                            best_end = e
                        end
                    end
                end
            end
            if best_kw then
                local num = nil
                local after_byte = string.byte(lowerMsg, best_end + 1)
                if after_byte and after_byte >= 48 and after_byte <= 57 then
                    local after = string.sub(lowerMsg, best_end + 1, math.min(len, best_end + 4))
                    num = string.match(after, "^(%d+)")
                end

                if not num then
                    local before = string.sub(lowerMsg, math.max(1, pos - 8), pos - 1)
                    num = string.match(before, "(%d)%s*$")
                end
                if num then
                    total = total + tonumber(num)
                end
                pos = best_end + 1
            else
                pos = pos + 1
            end
        end
        return total
    end

    local function has_role(roleKeywords)
        for _, kw in ipairs(roleKeywords) do
            if is_ascii_kw(kw) then
                if string.find(lowerMsg, "%f[%a]" .. kw .. "%f[^%a]") then
                    return true
                end
            else
                if string.find(lowerMsg, kw, 1, true) then
                    return true
                end
            end
        end
        return false
    end

    local function parseRole(roleKeywords, roleName)
        roles[roleName] = count_role(roleKeywords)
        if roles[roleName] == 0 and has_role(roleKeywords) then
            roles[roleName] = 1
        end
    end

    parseRole({
        "tank", "tanks",
        "танк", "танка", "танки", "танков",
        "坦克",
        "탱커", "탱",
    }, "tank")
    parseRole({
        "healer", "healers", "heal", "heals",
        "хил", "хила", "хилер", "хилов",
        "целитель", "лекарь",
        "治疗", "奶",
        "힐러", "힐",
    }, "healer")
    parseRole({
        "dps", "damage", "dd",
        "дд", "дамагер", "дилер",
        "输出", "伤害",
        "딜러", "딜",
    }, "dps")
    parseRole({
        "support", "supp", "supt",
        "саппорт", "саппорта", "саппортов",
        "辅助", 
        "서포터",
    }, "support")

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

    totalRoles = roles.tank + roles.healer + roles.dps + roles.support
    if totalRoles == 0 then
        if string.find(lowerMsg, "%f[%a]all%f[^%a]")
           or string.find(lowerMsg, "%f[%a]anyone%f[^%a]")
           or string.find(lowerMsg, "%f[%a]any%f[^%a]") then
            roles.tank = 1
            roles.healer = 1
            roles.dps = 1
            roles.support = 1
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

local KEYSTONE_LINKED = "|Hitem:(%d+):[^|]*|h%[Keystone:%s*([^%]]+)%]"
local KEYSTONE_BARE = "%[Keystone:%s*([^%]]+)%]"
local KEYSTONE_UNBRACKETED = "Keystone:%s*([%a%s'%-]-%(%d+%))"
local KEYSTONE_NAME_MAX = 44

function LFG.ParseKeystoneInfo(message)
    if not message then return nil, nil end
    if not string.find(message, "Keystone:", 1, true) then return nil, nil end

    local itemId, inner = string.match(message, KEYSTONE_LINKED)
    if not inner then
        itemId, inner = nil, string.match(message, KEYSTONE_BARE)
    end
    if not inner then
        inner = string.match(message, KEYSTONE_UNBRACKETED)
        if inner and #inner > KEYSTONE_NAME_MAX then inner = nil end
    end
    if not inner then return nil, nil end

    local level, s0, e0
    local pos = 1
    while true do
        local s, e, digits = string.find(inner, "%((%d+)%)", pos)
        if not s then break end
        level, s0, e0 = tonumber(digits), s, e
        pos = e + 1
    end

    local name = inner
    if s0 then
        name = string.sub(inner, 1, s0 - 1) .. string.sub(inner, e0 + 1)
    end
    name = string.gsub(name, "%s+", " ")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")

    return name, level
end

function LFG.SplitKeystoneWingName(name)
    if not name or name == "" then return nil, nil end
    local base, wing = string.match(name, "^(.-)%s+%-%s+(.+)$")
    if not base or base == "" or not wing or wing == "" then return nil, nil end
    return base, wing
end

local function TruncateVisible(msg, maxVisible)
    if not msg or msg == "" then return msg or "" end
    local len = #msg
    local vis = 0
    local i = 1
    local safeCut = 0
    local inLink = false
    local colorDepth = 0
    while i <= len do
        local c = string.sub(msg, i, i)
        if c == "|" then
            local n = string.sub(msg, i + 1, i + 1)
            local isColorOpen = (n == "c")
            if n == "c" then
                i = i + 10
                colorDepth = colorDepth + 1
            elseif n == "H" then
                local e = string.find(msg, "|h", i, true)
                i = e and (e + 2) or (len + 1)
                inLink = true
            elseif n == "T" then
                local e = string.find(msg, "|t", i, true)
                i = e and (e + 2) or (len + 1)
            elseif n == "h" then
                i = i + 2
                inLink = false
            else
                i = i + 2
                if n == "r" then
                    colorDepth = math.max(0, colorDepth - 1)
                end
            end
            if not inLink and not isColorOpen then
                safeCut = i
                if vis >= maxVisible then
                    local suffix = "..."
                    if colorDepth > 0 then suffix = suffix .. "|r" end
                    return string.sub(msg, 1, i - 1) .. suffix
                end
            end
        else
            vis = vis + 1
            if vis > maxVisible then
                local suffix = "..."
                if colorDepth > 0 then suffix = suffix .. "|r" end
                if safeCut > 0 then
                    return string.sub(msg, 1, safeCut - 1) .. suffix
                else
                    return string.sub(msg, 1, i - 1) .. suffix
                end
            end
            if not inLink then safeCut = i end
            i = i + 1
        end
    end
    return msg
end
LFG.TruncateVisible = TruncateVisible

function LFG.ShortenMessage(message)
    if not message then return "" end
    local maxLength = FrostSeekDB.LFG.maxMessageLength or 150
    if string.len(message) <= maxLength then
        return message
    end
    return TruncateVisible(message, maxLength)
end

LFG.CATEGORY_TAG = CATEGORY_TAG
LFG.DIFFICULTY_FILTERS = DIFFICULTY_FILTERS
LFG.CATEGORY_ACCENT = CATEGORY_ACCENT
