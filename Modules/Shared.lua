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


local Shared = {}

local function _tc(token)
    local T = _G.FrostSeekTheme or (_G.FrostSeek and _G.FrostSeek.Theme)
    if T and T.Get then return T.Get(token) end
    return {0.5, 0.5, 0.5}
end

local function _hex(token)
    local c = _tc(token)
    if not c or #c < 3 then return "|cFF888888" end
    return string.format("|cFF%02X%02X%02X", math.min(255, math.floor(c[1] * 255 + 0.5)), math.min(255, math.floor(c[2] * 255 + 0.5)), math.min(255, math.floor(c[3] * 255 + 0.5)))
end

local function _cmul(color, factor)
    if not color then return {0.5, 0.5, 0.5} end
    local result = {}
    for i, v in ipairs(color) do
        if i <= 3 then result[i] = math.min(1, v * factor)
        else result[i] = v end
    end
    return result
end

Shared.CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1.00, 0.96, 0.41},
    PRIEST = {1.00, 1.00, 1.00},
    SHAMAN = {0.00, 0.44, 0.87},
    MAGE = {0.41, 0.80, 0.94},
    WARLOCK = {0.58, 0.51, 0.79},
    DRUID = {1.00, 0.49, 0.04},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
}

function Shared.GetClassColor(classFile)
    if not classFile then return {0.7, 0.7, 0.7} end
    return Shared.CLASS_COLORS[string.upper(classFile)] or {0.7, 0.7, 0.7}
end

function Shared.GetClassHex(classFile)
    local c = Shared.GetClassColor(classFile)
    return string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

local CLASS_ICON_BASE = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\class\\"
Shared.CLASS_ICON_DEFAULT = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\custom\\custom.tga"

local CLASSIC_ICONS = {
    WARRIOR        = CLASS_ICON_BASE .. "classic\\warrior.tga",
    PALADIN        = CLASS_ICON_BASE .. "classic\\paladino.tga",
    HUNTER         = CLASS_ICON_BASE .. "classic\\hunter.tga",
    ROGUE          = CLASS_ICON_BASE .. "classic\\rogue.tga",
    PRIEST         = CLASS_ICON_BASE .. "classic\\prete.tga",
    DEATHKNIGHT    = CLASS_ICON_BASE .. "classic\\dk.tga",
    SHAMAN         = CLASS_ICON_BASE .. "classic\\shaman.tga",
    MAGE           = CLASS_ICON_BASE .. "classic\\mago.tga",
    WARLOCK        = CLASS_ICON_BASE .. "classic\\warlock.tga",
    DRUID          = CLASS_ICON_BASE .. "classic\\druido.tga",
    MONK           = CLASS_ICON_BASE .. "classic\\monk.tga",
    DEMONHUNTER    = CLASS_ICON_BASE .. "classic\\demonhuntervoid.tga",
    EVOKER         = CLASS_ICON_BASE .. "classic\\evoker.tga",
    HERO           = CLASS_ICON_BASE .. "hero\\hero.tga",
}

local COA_ICONS = {
    REAPER              = CLASS_ICON_BASE .. "coa\\reaper.tga",
    TEMPLAR             = CLASS_ICON_BASE .. "coa\\templar.tga",
    TINKER              = CLASS_ICON_BASE .. "coa\\tinker.tga",
    SUNCLERIC           = CLASS_ICON_BASE .. "coa\\suncleric.tga",
    STARCALLER          = CLASS_ICON_BASE .. "coa\\starcaller.tga",
    NECROMANCER         = CLASS_ICON_BASE .. "coa\\necromanger.tga",
    PYROMANCER          = CLASS_ICON_BASE .. "coa\\pyromancer.tga",
    BARBARIAN           = CLASS_ICON_BASE .. "coa\\barbarian.tga",
    STORMBRINGER        = CLASS_ICON_BASE .. "coa\\stormbringer.tga",
    GUARDIAN            = CLASS_ICON_BASE .. "coa\\guardian.tga",
    CULTIST             = CLASS_ICON_BASE .. "coa\\cultist.tga",
    CHRONOMANCER        = CLASS_ICON_BASE .. "coa\\chronomancer.tga",
    ["WITCH DOCTOR"]    = CLASS_ICON_BASE .. "coa\\witchdoctor.tga",
    ["WITCH HUNTER"]    = CLASS_ICON_BASE .. "coa\\witchhunter.tga",
    WILDWALKER          = CLASS_ICON_BASE .. "coa\\wildwalker.tga",
    RANGER              = CLASS_ICON_BASE .. "coa\\ranger.tga",
    VENOMANCER          = CLASS_ICON_BASE .. "coa\\insetto.tga",
    RUNEMASTER          = CLASS_ICON_BASE .. "coa\\piritmage.tga",
    FELSWORN            = CLASS_ICON_BASE .. "coa\\demonhunter.tga",
    ["KNIGHT OF XOROTH"]= CLASS_ICON_BASE .. "coa\\evokerfiamma.tga",
    BLOODMAGE           = CLASS_ICON_BASE .. "coa\\sonofarugal.tga",
}

local COA_CLASSFILE_ALIASES = {
    ["FLESHWARDEN"]  = "KNIGHT OF XOROTH",
    ["FLASHWARDEN"]  = "KNIGHT OF XOROTH",
    ["SPIRITMAGE"]   = "RUNEMASTER",
    ["PROFET"]       = "VENOMANCER",
    ["PROPHET"]      = "VENOMANCER",
}

function Shared.NormalizeCoAClassToken(classFile)
    if not classFile or classFile == "" then return classFile end
    local upper = string.upper(tostring(classFile))
    if COA_CLASSFILE_ALIASES[upper] then
        return COA_CLASSFILE_ALIASES[upper]
    end
    return classFile
end

function Shared.GetClassIcon(classFile)
    if not classFile or classFile == "" then
        return Shared.CLASS_ICON_DEFAULT
    end
    classFile = Shared.NormalizeCoAClassToken(classFile)
    local key = string.upper(tostring(classFile))
    local norm = string.gsub(key, "[_%-]", " ")

    local isCoA = false
    if _G.FrostSeekCompat then
        if _G.FrostSeekCompat.IsConquestOfAzeroth and _G.FrostSeekCompat.IsConquestOfAzeroth() then
            isCoA = true
        elseif _G.FrostSeekCompat.IsAscension and _G.FrostSeekCompat.IsAscension()
           and _G.FrostSeekCompat.GetAscensionMode and _G.FrostSeekCompat.GetAscensionMode() == "coa" then
            isCoA = true
        end
    end

    if isCoA then
        if COA_ICONS[key] then return COA_ICONS[key] end
        if COA_ICONS[norm] then return COA_ICONS[norm] end
    end

    if CLASSIC_ICONS[key] then return CLASSIC_ICONS[key] end
    if CLASSIC_ICONS[norm] then return CLASSIC_ICONS[norm] end
    return Shared.CLASS_ICON_DEFAULT
end

function Shared._IsCoARealm()
    if not _G.FrostSeekCompat then return false end
    if _G.FrostSeekCompat.IsConquestOfAzeroth and _G.FrostSeekCompat.IsConquestOfAzeroth() then
        return true
    end
    if _G.FrostSeekCompat.IsAscension and _G.FrostSeekCompat.IsAscension()
       and _G.FrostSeekCompat.GetAscensionMode and _G.FrostSeekCompat.GetAscensionMode() == "coa" then
        return true
    end
    return false
end

Shared._cachedPlayerClass = nil
Shared._cachedPlayerClassTime = 0
local CACHE_TTL = 10

function Shared.GetPlayerClassFile()
    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.manualClass
       and FrostSeekDB.Settings.manualClass ~= "" then
        return string.upper(FrostSeekDB.Settings.manualClass)
    end

    local now = GetTime and GetTime() or 0
    if Shared._cachedPlayerClass and (now - Shared._cachedPlayerClassTime) < CACHE_TTL then
        return Shared._cachedPlayerClass
    end

    local className, classFile = UnitClass("player")
    if not classFile then return "WARRIOR" end

    local result = classFile

    if Shared._IsCoARealm() then
        if className and className ~= "" then
            result = string.upper(className)
        end
    end

    Shared._cachedPlayerClass = result
    Shared._cachedPlayerClassTime = now
    return result
end

function Shared.GetPlayerClass()
    local className, classFile = UnitClass("player")
    local resolved = Shared.GetPlayerClassFile()
    if resolved ~= classFile then
        className = string.gsub(string.lower(resolved), "(%a)([%w ']*)", function(first, rest)
            return string.upper(first) .. rest
        end)
        className = string.gsub(className, "Of", "of")
    end
    return className, resolved
end

Shared.ROLE_COLORS = {
    Tank = {0.29, 0.64, 1.00},
    Healer = {0.27, 1.00, 0.40},
    DPS = {1.00, 0.33, 0.33},
    Support = {0.70, 0.40, 1.00},
    SUPPORT = {0.70, 0.40, 1.00},
}

function Shared.GetRoleColor(role)
    if not role then return {0.7, 0.7, 0.7} end
    return Shared.ROLE_COLORS[role] or {0.7, 0.7, 0.7}
end

function Shared.GetRoleHex(role)
    local c = Shared.GetRoleColor(role)
    return string.format("|cFF%02X%02X%02X", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

function Shared.SimplifyRealmName(fullName)
    if not fullName then return "" end
    local dash = string.find(fullName, " - ", 1, true)
    if dash then
        return string.sub(fullName, 1, dash - 1)
    end
    return fullName
end

Shared.MAX_LISTINGS = 200
Shared.MAX_SEND_RATE = 1.0
Shared.MAX_MESSAGE_LENGTH = 240

function Shared.ConfirmDialog(title, text, onConfirm, onCancel)
    local _tc = Shared._tc or function(t) return {0.05, 0.05, 0.1, 0.9} end

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetPoint("CENTER")
    frame:SetSize(320, 120)
    frame:SetBackdrop(nil)

    local borderTex = frame:CreateTexture(nil, "BACKGROUND")
    borderTex:SetAllPoints()
    local accentColor = _tc("accent") or {0.3, 0.5, 1}
    borderTex:SetColorTexture(accentColor[1] * 0.3, accentColor[2] * 0.3, accentColor[3] * 0.3, 0.65)

    local bgPopupColor = _tc("bgPopup")
    local bgTex = frame:CreateTexture(nil, "BORDER")
    bgTex:SetPoint("TOPLEFT", 1, -1)
    bgTex:SetPoint("BOTTOMRIGHT", -1, 1)
    bgTex:SetColorTexture(bgPopupColor[1], bgPopupColor[2], bgPopupColor[3], bgPopupColor[4])

    local topAccent = frame:CreateTexture(nil, "ARTWORK")
    topAccent:SetPoint("TOPLEFT", 1, 0)
    topAccent:SetPoint("TOPRIGHT", -1, 0)
    topAccent:SetHeight(2)
    topAccent:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], 0.9)

    local glassReflect = frame:CreateTexture(nil, "ARTWORK")
    glassReflect:SetPoint("TOPLEFT", 2, -3)
    glassReflect:SetPoint("TOPRIGHT", -2, -3)
    glassReflect:SetHeight(14)
    glassReflect:SetColorTexture(accentColor[1] * 0.06, accentColor[2] * 0.06, accentColor[3] * 0.06, 0.3)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -16)
    frame.title:SetText(title or _G.FrostSeek.L["dialog_confirm"])
    local titleColor = _tc("textBright") or {1, 1, 1}
    frame.title:SetTextColor(titleColor[1], titleColor[2], titleColor[3])

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("TOP", frame.title, "BOTTOM", 0, -8)
    frame.text:SetWidth(280)
    frame.text:SetText(text or _G.FrostSeek.L["dialog_are_you_sure"])
    local textColor = _tc("textNorm") or {0.8, 0.8, 0.8}
    frame.text:SetTextColor(textColor[1], textColor[2], textColor[3])

    local confirmColor = _tc("success") or {0.3, 0.8, 0.3}
    frame.confirmBtn = CreateFrame("Button", nil, frame)
    frame.confirmBtn:SetSize(128, 24)
    frame.confirmBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 14)
    frame.confirmBtn.bg = frame.confirmBtn:CreateTexture(nil, "BACKGROUND")
    frame.confirmBtn.bg:SetPoint("TOPLEFT", 1, -1)
    frame.confirmBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.confirmBtn.bg:SetColorTexture(unpack(_tc("bgButton") or {0.1, 0.1, 0.15}))
    frame.confirmBtn.border = frame.confirmBtn:CreateTexture(nil, "BORDER")
    frame.confirmBtn.border:SetAllPoints()
    frame.confirmBtn.border:SetColorTexture(unpack(_tc("border") or {0.3, 0.3, 0.4}))
    frame.confirmBtn.accent = frame.confirmBtn:CreateTexture(nil, "OVERLAY")
    frame.confirmBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    frame.confirmBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    frame.confirmBtn.accent:SetHeight(2)
    frame.confirmBtn.accent:SetColorTexture(unpack(confirmColor))
    frame.confirmBtn.text = frame.confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.confirmBtn.text:SetPoint("CENTER")
    frame.confirmBtn.text:SetText("|cff44ff66" .. (YES or _G.FrostSeek.L["yes"]) .. "|r")
    frame.confirmBtn:SetScript("OnClick", function()
        frame:Hide()
        if onConfirm then onConfirm() end
    end)

    local dangerColor = _tc("danger") or {0.8, 0.3, 0.3}
    frame.cancelBtn = CreateFrame("Button", nil, frame)
    frame.cancelBtn:SetSize(128, 24)
    frame.cancelBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 8, 14)
    frame.cancelBtn.bg = frame.cancelBtn:CreateTexture(nil, "BACKGROUND")
    frame.cancelBtn.bg:SetPoint("TOPLEFT", 1, -1)
    frame.cancelBtn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.cancelBtn.bg:SetColorTexture(unpack(_tc("bgButton") or {0.1, 0.1, 0.15}))
    frame.cancelBtn.border = frame.cancelBtn:CreateTexture(nil, "BORDER")
    frame.cancelBtn.border:SetAllPoints()
    frame.cancelBtn.border:SetColorTexture(unpack(_tc("border") or {0.3, 0.3, 0.4}))
    frame.cancelBtn.accent = frame.cancelBtn:CreateTexture(nil, "OVERLAY")
    frame.cancelBtn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    frame.cancelBtn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    frame.cancelBtn.accent:SetHeight(2)
    frame.cancelBtn.accent:SetColorTexture(unpack(dangerColor))
    frame.cancelBtn.text = frame.cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.cancelBtn.text:SetPoint("CENTER")
    frame.cancelBtn.text:SetText("|cffff5555" .. (NO or _G.FrostSeek.L["no"]) .. "|r")
    frame.cancelBtn:SetScript("OnClick", function()
        frame:Hide()
        if onCancel then onCancel() end
    end)

    frame:SetAlpha(0)
    if UIFrameFadeIn then
        UIFrameFadeIn(frame, 0.15, 0, 1)
    else
        frame:SetAlpha(1)
    end
    frame:Show()
    return frame
end

local SOUNDS = {
    popup = "Sound\\Interface\\iQuestComplete",
    listing = "Sound\\Interface\\AuctionWindowOpen",
    applicant = "Sound\\Interface\\AuctionWindowOpen",
    connect = "Sound\\Interface\\igCharacterInfoTab",
    disconnect = "Sound\\Interface\\igCharacterInfoClose",
    whisper = "Sound\\Interface\\TellMessage",
}

function Shared.PlaySound(type)
    if not FrostSeekDB or not FrostSeekDB.Settings then return end
    local snd = FrostSeekDB.Settings.soundEnabled
    if snd == false then return end
    local soundFile = SOUNDS[type]
    if soundFile then
        PlaySoundFile(soundFile)
    end
end

function Shared.SetupConfirmHook(originalFunc, title, confirmText)
    return function(...)
        local args = {...}
        Shared.ConfirmDialog(title, confirmText, function()
            originalFunc(unpack(args))
        end)
    end
end

Shared._tc = _tc
Shared._hex = _hex
Shared._cmul = _cmul

function Shared.GetServerProfile()
    local dbProfile = FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.serverProfile or "auto"
    if dbProfile ~= "auto" then return dbProfile end

    local Compat = _G.FrostSeekCompat
    if not Compat then return "wotlk" end

    if Compat.IsEpoch and Compat.IsEpoch() then return "epoch" end
    if Compat.IsAscension and Compat.IsAscension() then return "ascension" end
    if Compat.IsVanilla and Compat.IsVanilla() then return "classic" end
    if Compat.IsTBC and Compat.IsTBC() then return "tbc" end
    if Compat.Is335 and Compat.Is335() then return "wotlk" end
    if Compat.IsWotLKClassic and Compat.IsWotLKClassic() then return "wotlk" end
    if Compat.IsCata and Compat.IsCata() then return "cata" end
    if Compat.IsMists and Compat.IsMists() then return "mop" end
    if Compat.IsMainline and Compat.IsMainline() then return "mop" end
    return "wotlk"
end

function Shared.GetServerProfileExpansionLevel()
    local profile = Shared.GetServerProfile()
    local map = {
        classic = 0, tbc = 1, wotlk = 2, cata = 3, mop = 4,
        ascension = 2, epoch = 2,
    }
    return map[profile] or 2
end

function Shared.IsExpansionVisibleForServer(expansionKey)
    local profile = Shared.GetServerProfile()
    local upper = string.upper(expansionKey or "")

    if upper == "WORLD BOSSES" or upper == "PVP" or upper == "MANASTORM"
       or upper == "KEYSTONE" or upper == "MISC" then
        return true
    end

    if profile == "ascension" then
        if upper == "EPOCH DUNGEONS" then return false end
        if upper == "CUSTOM DUNGEONS" or upper == "CUSTOM RAIDS"
           or upper == "CLASSIC DUNGEONS" or upper == "CLASSIC RAIDS"
           or upper == "TBC DUNGEONS" or upper == "TBC RAIDS"
           or upper == "WOTLK DUNGEONS" or upper == "WOTLK RAIDS" then
            return true
        end
        return false
    end

    if profile == "epoch" then
        if upper == "EPOCH DUNGEONS" then return true end
        if upper == "CUSTOM DUNGEONS" or upper == "CUSTOM RAIDS" then return false end
        if upper == "CLASSIC DUNGEONS" or upper == "CLASSIC RAIDS"
           or upper == "TBC DUNGEONS" or upper == "TBC RAIDS"
           or upper == "WOTLK DUNGEONS" or upper == "WOTLK RAIDS" then
            return true
        end
        return false
    end

    if upper == "CUSTOM DUNGEONS" or upper == "CUSTOM RAIDS"
       or upper == "EPOCH DUNGEONS" then
        return false
    end

    local expLevel = Shared.GetServerProfileExpansionLevel()
    local keyToLevel = {
        ["CLASSIC DUNGEONS"] = 0, ["CLASSIC RAIDS"] = 0,
        ["TBC DUNGEONS"] = 1, ["TBC RAIDS"] = 1,
        ["WOTLK DUNGEONS"] = 2, ["WOTLK RAIDS"] = 2,
        ["CATA DUNGEONS"] = 3, ["CATA RAIDS"] = 3,
        ["MoP DUNGEONS"] = 4, ["MoP RAIDS"] = 4, ["MoP WORLD BOSSES"] = 4,
    }
    local lvl = keyToLevel[upper]
    if lvl == nil then return true end
    return lvl <= expLevel
end

function Shared.GetRelevantExpansionsForProfile()
    local profile = Shared.GetServerProfile()
    if profile == "classic" then
        return { "Classic" }
    elseif profile == "tbc" then
        return { "Classic", "TBC" }
    elseif profile == "wotlk" then
        return { "Classic", "TBC", "WotLK" }
    elseif profile == "cata" then
        return { "Classic", "TBC", "WotLK", "Cata" }
    elseif profile == "mop" then
        return { "Classic", "TBC", "WotLK", "Cata", "MoP" }
    elseif profile == "ascension" then
        return { "Classic", "TBC", "WotLK", "Ascension" }
    elseif profile == "epoch" then
        return { "Classic", "TBC", "WotLK", "Epoch" }
    end
    return { "Classic", "TBC", "WotLK" }
end

_G.FrostSeekShared = Shared

if _G.FrostSeek then
    _G.FrostSeek.Shared = Shared
end

return Shared
