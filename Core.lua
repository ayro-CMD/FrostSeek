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


local FrostSeek = {}
_G.FrostSeek = FrostSeek

FrostSeek._v = {}
FrostSeek._v.t = tostring(math.random(1e6, 9e6)) .. "_" .. string.format("%.3f", GetTime())
FrostSeek._v.r = {}
FrostSeek._v.n = 0
FrostSeek._v.w = {}
FrostSeek._v.f = false

function FrostSeek._v.a(name, ref)
    if not name then return nil end
    if not FrostSeek._v.t then return nil end
    FrostSeek._v.r[name] = ref
    FrostSeek._v.n = FrostSeek._v.n + 1
    return FrostSeek._v.t
end

function FrostSeek._v.c(tok)
    return tok == FrostSeek._v.t
end

function FrostSeek._v.e(name)
    return FrostSeek._v.r[name] ~= nil
end

function FrostSeek._v.s(name, fn)
    FrostSeek._v.w[name] = fn
end

function FrostSeek._v.g(name)
    if FrostSeek._v.f then return nil end
    return FrostSeek._v.w[name]
end

FrostSeek.VERSION = "2.4"

local L = setmetatable({}, {
    __index = function(_, key)
        if FrostSeek and FrostSeek.L then
            return FrostSeek.L[key]
        end
        return key
    end,
})

local function LPrint(key, ...)
    local L = FrostSeek and FrostSeek.L
    if not L then
        print("[FrostSeek] " .. tostring(key))
        return
    end
    local body
    if select("#", ...) > 0 then
        local Lf = FrostSeek.Lf or function(k, ...) return string.format(k, ...) end
        body = Lf(key, ...)
    else
        body = L[key] or key
    end
    print(body)
end

FrostSeek.SCHEMA_VERSION = 6


local LOG_LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local LOG_COLORS = { DEBUG = "888888", INFO = "88ccff", WARN = "ffcc00", ERROR = "ff5555" }
local LOG_BUFFER_MAX = 200

FrostSeek.Logger = {
    Buffer = {},
    Level = "WARN",
}

local function tsNow()
    return date("%H:%M:%S")
end

local function shouldLog(level)
    local cur = FrostSeek.Logger.Level or "WARN"
    return (LOG_LEVELS[level] or 0) >= (LOG_LEVELS[cur] or 0)
end

local function pushBuffer(level, msg)
    local buf = FrostSeek.Logger.Buffer
    buf[#buf + 1] = {
        ts = tsNow(),
        level = level,
        color = LOG_COLORS[level] or "888888",
        msg = tostring(msg),
    }
    if #buf > LOG_BUFFER_MAX then
        table.remove(buf, 1)
    end
end

function FrostSeek.Logger.Log(level, msg)
    level = (level or "INFO"):upper()
    if not LOG_LEVELS[level] then level = "INFO" end
    pushBuffer(level, msg)
    if shouldLog(level) then
        local color = LOG_COLORS[level] or "888888"
        print("|cff" .. color .. "[FSK:" .. level .. "]|r " .. tostring(msg))
    end
end

function FrostSeek.Logger.Debug(msg) FrostSeek.Logger.Log("DEBUG", msg) end
function FrostSeek.Logger.Info(msg)  FrostSeek.Logger.Log("INFO",  msg) end
function FrostSeek.Logger.Warn(msg)  FrostSeek.Logger.Log("WARN",  msg) end
function FrostSeek.Logger.Error(msg) FrostSeek.Logger.Log("ERROR", msg) end

function FrostSeek.SafeCall(fn, ...)
    local args = { ... }
    local ok, err = xpcall(function() return fn(unpack(args)) end,
        function(e)
            return tostring(e) .. "\n" .. (debugstack and debugstack(2, 8) or "")
        end)
    if not ok then
        FrostSeek.Logger.Error("SafeCall failed: " .. tostring(err))
        return false
    end
    return true, err
end

function FrostSeek.SafeHandler(fn)
    return function(self, ...)
        local ok, err = xpcall(fn, function(e)
            return tostring(e) .. "\n" .. (debugstack and debugstack(2, 8) or "")
        end, self, ...)
        if not ok then
            FrostSeek.Logger.Error("Event handler crashed: " .. tostring(err))
        end
    end
end

FrostSeekDB = FrostSeekDB or {}

if not FrostSeekDB.LFG then
    FrostSeekDB.LFG = {
        myRole = "No Role",
        includeCurrentLre = true,
        silentNotifications = true,
        frameDuration = 5,
        dontDisplayDeclinedDuration = 300,
        dontDisplaySpammers = 30,
        disablePopups = true,
        disableLFG = false,
        doNotAlertInGroup = true,
        doNotAlertInCombat = true,
        filterWords = "echo,lfg,wts,buy,shop,gold,sell,account,boost,carry,pve,eu,na,need,wtt,wtb,bazar,hello,player",
        maxMessageLength = 90,
        popupCooldown = 370,
        maxConcurrentPopups = 2,
        popupCategories = {
            ALL = false,
            DUNGEON = true,
            RAID = true,
            WORLD_BOSS = true,
            PVP = false,
            MANASTORM = true,
            KEYSTONE = true,
            MISC = false
        },
        popupModeFilter = "LFM",
        popupShowLFG = false,
        popupShowLFM = true,
        popupAnchor = nil,
        customFilterWords = "",
        keystoneMinLevel = 0,
        chatFilterEnabled = false,
        chatFilterGuildPartyRaid = false,
        chatFilterHideOwnMessages = false,
        chatFilterKeywords = "lfg,lfm,lf,lfg+,looking for group,looking for member,looking for raid,looking for,inv,invite,keystone,wts,wtb,boost,carry",
        showActiveRecruitersWindow = false,
        activeWindowPosition = nil,
        activeWindowCategory = "ALL",
        customMessages = {
            enabled = false,
            template = "inv {role} {class} {spec} {ilvl} ilvl",
            showClass = true,
            showIlvl = true,
            showEnchant = true,
            showSpec = true,
            showRole = true,
            showAchievement = false,
            achievementLink = "",
            showKeystone = false,
            keystoneLink = ""
        },
        customKeywords = {
            DUNGEON = "",
            RAID = "",
            WORLD_BOSS = "",
            PVP = "",
            MANASTORM = "",
            KEYSTONE = "",
            MISC = ""
        }
    }
end

if not FrostSeekDB.LFM then
    FrostSeekDB.LFM = {
        lastMessages = {},
        favoriteTemplates = {},
        channelPresets = {},
        autoUpdateInterval = 60,
        autoSpamInterval = 30,
        spamChannels = {},
        autoInviteEnabled = false,
        autoInviteMinIlvl = 0,
        customMessage = "",
        autoStopMemberCount = 0,
    }
end

if FrostSeekDB.LFM then
    if FrostSeekDB.LFM.autoSpamInterval == nil then FrostSeekDB.LFM.autoSpamInterval = 30 end
    if FrostSeekDB.LFM.spamChannels == nil then FrostSeekDB.LFM.spamChannels = {} end
    if FrostSeekDB.LFM.autoInviteEnabled == nil then FrostSeekDB.LFM.autoInviteEnabled = false end
    if FrostSeekDB.LFM.autoInviteMinIlvl == nil or FrostSeekDB.LFM.autoInviteMinIlvl == 150 then
        FrostSeekDB.LFM.autoInviteMinIlvl = 0
    end
    if FrostSeekDB.LFM.customMessage == nil then FrostSeekDB.LFM.customMessage = "" end
    if FrostSeekDB.LFM.autoStopMemberCount == nil then FrostSeekDB.LFM.autoStopMemberCount = 0 end
end

if FrostSeekDB.MPlusScores ~= nil then FrostSeekDB.MPlusScores = nil end

if not FrostSeekDB.Favorites then
    FrostSeekDB.Favorites = {}
end

if not FrostSeekDB.Guilds then
    FrostSeekDB.Guilds = {}
end

if not FrostSeekDB.GuildTemplates then
    FrostSeekDB.GuildTemplates = {}
end

if not FrostSeekDB.SessionStats then
    FrostSeekDB.SessionStats = {
        listingsCreated = 0,
        applicantsReceived = 0,
        applicantsAccepted = 0,
        applicantsDeclined = 0,
        applicationsSent = 0,
        applicationsAccepted = 0,
        peakOnline = 0,
        sessionStart = time(),
    }
end

if not FrostSeekDB.Profile then
    FrostSeekDB.Profile = {
        role = "No Role",
        spec = "",
        discord = false,
        note = "",
        autoFill = true,
        autoIlvl = 0,
    }
end

if not FrostSeekDB.Settings then
    FrostSeekDB.Settings = {
        uiScale = 1.0,
        windowPosition = nil,
        minimapButton = true,
        autoOpen = false,
        showWelcome = true,
        debugMode = false,
        savePosition = true,
        theme = "Shadow",
        frostnetEnabled = true,
        applyWhisper = false,
        serverProfile = "auto",
        serverProfileManual = false,
        setupCompleted = false,
    }
end

local MIGRATIONS = {}
MIGRATIONS[2] = function(db)
    if not db._backup_v1 then
        local snap = {}
        for _, k in ipairs({"LFG","LFM","Favorites","Guilds","GuildTemplates","SessionStats","Profile","Settings"}) do
            if db[k] ~= nil then snap[k] = db[k] end
        end
        db._backup_v1 = snap
    end
end

MIGRATIONS[3] = function(db)
    db.Settings = db.Settings or {}
    if db.Settings.language == nil then db.Settings.language = "auto" end
    if db.Settings.logLevel  == nil then db.Settings.logLevel  = "WARN"  end
    if not db.VoiceLinks then db.VoiceLinks = {} end
    if not db.Calendar then
        db.Calendar = {
            entries = {},
            reminders = {},
        }
    end
end

MIGRATIONS[4] = function(db)
    db.Calendar = nil
end

MIGRATIONS[5] = function(db)
    db.Settings = db.Settings or {}
    if db.Settings.serverProfile == nil then db.Settings.serverProfile = "auto" end
    if db.Settings.setupCompleted == nil then db.Settings.setupCompleted = false end
    if db.Settings.serverProfileManual == nil then db.Settings.serverProfileManual = false end
end

MIGRATIONS[6] = function(db)
    db.Settings = db.Settings or {}
    db.Settings.serverProfileManual = false
    db.Settings.serverProfile = "auto"
end

local function MigrateSchema()
    local db = FrostSeekDB
    db._schemaVersion = db._schemaVersion or 1

    if db._schemaVersion < 2 and MIGRATIONS[2] then
        MIGRATIONS[2](db)
        db._schemaVersion = 2
    end

    while db._schemaVersion < FrostSeek.SCHEMA_VERSION do
        local nextV = db._schemaVersion + 1
        local fn = MIGRATIONS[nextV]
        if not fn then
            db._schemaVersion = nextV
        else
            local ok, err = pcall(fn, db)
            if ok then
                db._schemaVersion = nextV
            else
                LPrint("migration_failed", tostring(nextV), tostring(err))
                break
            end
        end
    end
end

MigrateSchema()

local function EnsureSettingsIntegrity()
    if FrostSeekDB.Settings.uiScale == nil then FrostSeekDB.Settings.uiScale = 1.0 end
    if FrostSeekDB.Settings.autoOpen == nil then FrostSeekDB.Settings.autoOpen = false end
    if FrostSeekDB.Settings.minimapButton == nil then FrostSeekDB.Settings.minimapButton = true end
    if FrostSeekDB.Settings.savePosition == nil then FrostSeekDB.Settings.savePosition = true end
    if FrostSeekDB.Settings.debugMode == nil then FrostSeekDB.Settings.debugMode = false end
    if FrostSeekDB.Settings.showWelcome == nil then FrostSeekDB.Settings.showWelcome = true end
    if FrostSeekDB.Settings.theme == nil then FrostSeekDB.Settings.theme = "Frost" end
    if FrostSeekDB.Settings.frostnetEnabled == nil then FrostSeekDB.Settings.frostnetEnabled = true end
    if FrostSeekDB.Settings.applyWhisper == nil then FrostSeekDB.Settings.applyWhisper = false end
    if FrostSeekDB.Settings.language == nil then FrostSeekDB.Settings.language = "auto" end
    if FrostSeekDB.Settings.logLevel == nil then FrostSeekDB.Settings.logLevel = "WARN" end
    if FrostSeekDB.Settings.serverProfile == nil then FrostSeekDB.Settings.serverProfile = "auto" end
    if FrostSeekDB.Settings.setupCompleted == nil then FrostSeekDB.Settings.setupCompleted = false end
    if FrostSeekDB.Settings.serverProfileManual == nil then FrostSeekDB.Settings.serverProfileManual = false end

    FrostSeek.Logger.Level = FrostSeekDB.Settings.logLevel or "WARN"
    if not FrostSeekDB.VoiceLinks then FrostSeekDB.VoiceLinks = {} end
    if FrostSeekDB.LFG and FrostSeekDB.LFG.popupCategories then
        if FrostSeekDB.LFG.popupCategories.WORLD_BOSS == nil then
            FrostSeekDB.LFG.popupCategories.WORLD_BOSS = true
        end
    end
    if FrostSeekDB.LFG then
        if FrostSeekDB.LFG.popupModeFilter == nil then FrostSeekDB.LFG.popupModeFilter = "LFM" end

        if FrostSeekDB.LFG.popupShowLFG == nil or FrostSeekDB.LFG.popupShowLFM == nil then
            local legacy = FrostSeekDB.LFG.popupModeFilter
            if legacy == "LFG" then
                FrostSeekDB.LFG.popupShowLFG = true
                FrostSeekDB.LFG.popupShowLFM = false
            elseif legacy == "LFM" then
                FrostSeekDB.LFG.popupShowLFG = false
                FrostSeekDB.LFG.popupShowLFM = true
            else
                FrostSeekDB.LFG.popupShowLFG = false
                FrostSeekDB.LFG.popupShowLFM = true
            end
            FrostSeekDB.LFG.popupModeFilter = nil
        end
        if FrostSeekDB.LFG.keystoneMinLevel == nil then FrostSeekDB.LFG.keystoneMinLevel = 0 end
        if FrostSeekDB.LFG.doNotAlertInGroup == nil then FrostSeekDB.LFG.doNotAlertInGroup = true end
        if FrostSeekDB.LFG.doNotAlertInCombat == nil then FrostSeekDB.LFG.doNotAlertInCombat = true end
        if FrostSeekDB._silentNotifMigrated ~= true then
            FrostSeekDB.LFG.silentNotifications = true
            FrostSeekDB._silentNotifMigrated = true
        end
        if FrostSeekDB.LFG.chatFilterEnabled == nil then FrostSeekDB.LFG.chatFilterEnabled = false end
        if FrostSeekDB.LFG.chatFilterGuildPartyRaid == nil then FrostSeekDB.LFG.chatFilterGuildPartyRaid = false end
        if FrostSeekDB.LFG.chatFilterHideOwnMessages == nil then FrostSeekDB.LFG.chatFilterHideOwnMessages = false end
        if not FrostSeekDB.LFG.chatFilterKeywords or FrostSeekDB.LFG.chatFilterKeywords == "" then
            FrostSeekDB.LFG.chatFilterKeywords = "lfg,lfm,lf,lfg+,looking for group,looking for member,looking for raid,looking for,inv,invite,keystone,wts,wtb,boost,carry"
        end
    end

    if FrostSeekDB.LFG and not FrostSeekDB.LFG.customKeywords then
        FrostSeekDB.LFG.customKeywords = {
            DUNGEON = "", RAID = "", WORLD_BOSS = "",
            PVP = "", MANASTORM = "", KEYSTONE = ""
        }
    end

    if FrostSeekDB.LFG and FrostSeekDB.LFG.customMessages then
        local cm = FrostSeekDB.LFG.customMessages
        if cm.enabled == nil then cm.enabled = false end
        if cm.template and string.find(cm.template, "{ench}") then
            cm.template = string.gsub(cm.template, "{ench}", "{spec}")
        end
        if cm.template == nil or cm.template == "" then cm.template = "inv {role} {class} {spec} {ilvl} ilvl" end
        if cm.showClass == nil then cm.showClass = true end
        if cm.showIlvl == nil then cm.showIlvl = true end
        if cm.showEnchant == nil then cm.showEnchant = true end
        if cm.showSpec == nil then cm.showSpec = cm.showEnchant end
        if cm.showRole == nil then cm.showRole = true end
        if cm.showAchievement == nil then cm.showAchievement = false end
        if cm.achievementLink == nil then cm.achievementLink = "" end
        if cm.showKeystone == nil then cm.showKeystone = false end
        if cm.keystoneLink == nil then cm.keystoneLink = "" end
        if cm.showGs ~= nil then cm.showGs = nil end
    end

    if FrostSeekDB.Profile then
        if FrostSeekDB.Profile.role == nil or FrostSeekDB.Profile.role == "" then FrostSeekDB.Profile.role = "No Role" end
        if FrostSeekDB.Profile.spec == nil then FrostSeekDB.Profile.spec = "" end
        if FrostSeekDB.Profile.discord == nil then FrostSeekDB.Profile.discord = false end
        if FrostSeekDB.Profile.note == nil then FrostSeekDB.Profile.note = "" end
        if FrostSeekDB.Profile.autoFill == nil then FrostSeekDB.Profile.autoFill = true end
        if FrostSeekDB.Profile.autoIlvl == nil then FrostSeekDB.Profile.autoIlvl = 0 end
        if FrostSeekDB.Profile.autoGs ~= nil then FrostSeekDB.Profile.autoGs = nil end
    end
end

EnsureSettingsIntegrity()

function FrostSeek.IsAddonDisabled()
    return FrostSeekDB and FrostSeekDB.LFG and
        FrostSeekDB.LFG.disableLFG == true and
        FrostSeekDB.LFG.disablePopups == true
end

function FrostSeek.SetAddonDisabled(disabled)
    if not FrostSeekDB or not FrostSeekDB.LFG then return end
    disabled = disabled and true or false
    FrostSeekDB.LFG.disableLFG = disabled
    FrostSeekDB.LFG.disablePopups = disabled

    local lfg = FrostSeek.Modules and FrostSeek.Modules.lfg
    if lfg and lfg.UpdateToggleVisual then
        lfg.UpdateToggleVisual(not disabled)
    end

    FrostSeek.UpdateMinimapDisabledOverlay()
end

function FrostSeek.ToggleAddonDisabled()
    FrostSeek.SetAddonDisabled(not FrostSeek.IsAddonDisabled())
    return FrostSeek.IsAddonDisabled()
end

local _themeRef = FrostSeekTheme

FrostSeek.Config = {
    PrimaryColor = function() local c = _themeRef.Get("primary"); return {c[1], c[2], c[3], 1} end,
    SecondaryColor = function() local c = _themeRef.Get("secondary"); return {c[1], c[2], c[3], 1} end,
    ActiveColor = function() local c = _themeRef.Get("primary"); return {c[1]*0.7, c[2]*0.7, c[3]*0.7, 1} end,
    BackgroundColor = function() return _themeRef.Get("bgMain") end,
    BorderColor = function() return _themeRef.Get("border") end,

    TabHeight = 40,
    TabWidth = 110,
    ButtonHeight = 30,
    ButtonWidth = 120,

    TitleFont = "FSKFontNormalLarge",
    NormalFont = "FSKFontNormal",
    SmallFont = "FSKFontNormalSmall"
}

FrostSeek.MainFrame = CreateFrame("Frame", "FrostSeekFrame", UIParent)
local MainFrame = FrostSeek.MainFrame

MainFrame:Hide()

MainFrame:SetWidth(960)
MainFrame:SetHeight(630)
MainFrame:SetPoint("CENTER")
MainFrame:SetFrameStrata("HIGH")

if MainFrame.SetBackdrop then
    MainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    MainFrame:SetBackdropColor(unpack(FrostSeek.Config.BackgroundColor()))
    MainFrame:SetBackdropBorderColor(unpack(FrostSeek.Config.BorderColor()))
elseif BackdropTemplateMixin then
    Mixin(MainFrame, BackdropTemplateMixin)
    MainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    MainFrame:SetBackdropColor(unpack(FrostSeek.Config.BackgroundColor()))
    MainFrame:SetBackdropBorderColor(unpack(FrostSeek.Config.BorderColor()))
end

MainFrame:EnableMouse(true)
MainFrame:SetMovable(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)

tinsert(UISpecialFrames, "FrostSeekFrame")

local title = MainFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
title:SetPoint("TOP", MainFrame, "TOP", 0, -12)

if FSK_FontSystem and FSK_FontSystem.SafeText then
    FSK_FontSystem.SafeText(title, "FSKFontNormalLarge", "|cff88ccffFrost|r|cffffffffSeek|r")
else
    pcall(title.SetText, title, "|cff88ccffFrost|r|cffffffffSeek|r")
end
title:SetTextColor(0.8, 0.9, 1)

local versionText = MainFrame:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
versionText:SetPoint("TOP", title, "BOTTOM", 0, -2)

local function GetServerTypeLabel()
    local Shared = _G.FrostSeekShared
    local profile = Shared and Shared.GetServerProfile and Shared.GetServerProfile() or "wotlk"
    local Compat = _G.FrostSeekCompat
    local realmName = Compat and Compat.GetRealmName and Compat.GetRealmName() or ""
    local ascMode = Compat and Compat.GetAscensionMode and Compat.GetAscensionMode() or nil

    if profile == "ascension" then
        if ascMode == "coa" then return "COA" end
        if ascMode == "classless" then return "Ascension" end
        if ascMode == "seasonal" then return "Ascension" end
        if ascMode == "bronzebeard" then return "Ascension" end
        return "Ascension"
    elseif profile == "epoch" then return "Epoch" end

    local labels = { classic = "Classic", tbc = "TBC", wotlk = "WotLK", cata = "Cataclysm", mop = "MoP" }
    return labels[profile] or profile
end

local function UpdateVersionText()
    local txt = "v" .. FrostSeek.VERSION .. "  |cff888888" .. GetServerTypeLabel() .. "|r"
    if FSK_FontSystem and FSK_FontSystem.SafeText then
        FSK_FontSystem.SafeText(versionText, "FSKFontNormalSmall", txt)
    else
        pcall(versionText.SetText, versionText, txt)
    end
end
UpdateVersionText()

local versionUpdateFrame = CreateFrame("Frame")
versionUpdateFrame:RegisterEvent("PLAYER_LOGIN")
versionUpdateFrame:SetScript("OnEvent", function()
    C_Timer.After(3, function()
        UpdateVersionText()
    end)
end)

MainFrame.TabFrame = CreateFrame("Frame", nil, MainFrame)
local TabFrame = MainFrame.TabFrame

TabFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -50)
TabFrame:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -15, -50)
TabFrame:SetHeight(FrostSeek.Config.TabHeight)

local ContentFrame = CreateFrame("Frame", nil, MainFrame)
MainFrame.ContentFrame = ContentFrame

ContentFrame:SetPoint("TOPLEFT", TabFrame, "BOTTOMLEFT", 0, -5)
ContentFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 15)

FrostSeek.Tabs = {}
FrostSeek.ActiveTab = nil
FrostSeek.Modules = {}

FrostSeek.Theme = FrostSeekTheme
FrostSeek.UIUtils = FrostSeekUIUtils
FrostSeek.UI = FrostSeekUIUtils
FrostSeek.Shared = _G.FrostSeekShared

if FrostSeekTheme and FrostSeekTheme.RegisterModule then
    FrostSeekTheme.RegisterModule("core")
end

function FrostSeek:CreateModernTab(name, displayName)
    local T = _themeRef
    local tab = CreateFrame("Button", "FrostSeekTab_" .. name, TabFrame)
    tab:SetWidth(FrostSeek.Config.TabWidth)
    tab:SetHeight(FrostSeek.Config.TabHeight)

    local bgInactive = T.Get("bgTabInactive")
    local borderC = T.Get("border")
    local primaryC = T.Get("primary")
    local accentC = T.Get("textAccent")

    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    tab.bg:SetColorTexture(unpack(bgInactive))

    tab.border = tab:CreateTexture(nil, "BORDER")
    tab.border:SetAllPoints()
    tab.border:SetColorTexture(unpack(borderC))

    tab.highlight = tab:CreateTexture(nil, "BACKGROUND")
    tab.highlight:SetAllPoints()
    local hoverBg = T.Get("bgRowHover")
    tab.highlight:SetColorTexture(unpack(hoverBg))
    tab.highlight:Hide()

    tab.activeOverlay = tab:CreateTexture(nil, "OVERLAY")
    tab.activeOverlay:SetAllPoints()
    tab.activeOverlay:SetColorTexture(primaryC[1], primaryC[2], primaryC[3], 0.15)
    tab.activeOverlay:Hide()

    tab.text = tab:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    tab.text:SetPoint("CENTER")
    tab.text:SetText(displayName)
    local mutedC = T.Get("textMuted")
    tab.text:SetTextColor(mutedC[1], mutedC[2], mutedC[3])

    tab:SetScript("OnEnter", function(self)
        if FrostSeek.ActiveTab ~= name then
            self.highlight:Show()
            local ac = T.Get("textAccent")
            self.text:SetTextColor(ac[1], ac[2], ac[3])
            local bc = T.Get("borderHover")
            self.border:SetColorTexture(unpack(bc))
        end
    end)

    tab:SetScript("OnLeave", function(self)
        if FrostSeek.ActiveTab ~= name then
            self.highlight:Hide()
            local mc = T.Get("textMuted")
            self.text:SetTextColor(mc[1], mc[2], mc[3])
            self.border:SetColorTexture(unpack(T.Get("border")))
        end
    end)

    tab:SetScript("OnClick", function()
        FrostSeek:SwitchTab(name)
    end)

    self.Tabs[name] = {
        button = tab,
        module = nil,
        frame = nil
    }

    return tab
end

function FrostSeek:SwitchTab(tabName)
    local T = _themeRef

    if self.ActiveTab and self.Tabs[self.ActiveTab] then
        local oldTab = self.Tabs[self.ActiveTab]

        oldTab.button.bg:SetColorTexture(unpack(T.Get("bgTabInactive")))
        oldTab.button.border:SetColorTexture(unpack(T.Get("border")))
        oldTab.button.activeOverlay:Hide()
        local mc = T.Get("textMuted")
        oldTab.button.text:SetTextColor(mc[1], mc[2], mc[3])

        if oldTab.module and oldTab.module.Hide then
            oldTab.module:Hide()
        end
    end

    local newTab = self.Tabs[tabName]
    if newTab then
        newTab.button.bg:SetColorTexture(unpack(T.Get("bgTabActive")))
        local bc = T.Get("borderFocus")
        newTab.button.border:SetColorTexture(unpack(bc))
        local pc = T.Get("primary")
        newTab.button.activeOverlay:SetColorTexture(pc[1], pc[2], pc[3], 0.2)
        newTab.button.activeOverlay:Show()
        local tc = T.Get("textPrimary")
        newTab.button.text:SetTextColor(tc[1], tc[2], tc[3])

        if newTab.module and newTab.module.Show then
            newTab.module:Show()
        end

        self.ActiveTab = tabName

        if tabName == "listings" and self.Tabs.listings and self.Tabs.listings.badge then
            self.Tabs.listings.badge:Hide()
        end
    end
end

function FrostSeek:RegisterModule(name, moduleTable)
    self.Modules[name] = moduleTable
    if self.Tabs[name] then
        self.Tabs[name].module = moduleTable
    end
end

local tabDefinitions = {
    { id = "dashboard",  nameFn = function() return FrostSeek.L["tab_dashboard"] end,  descFn = function() return FrostSeek.L["tab_dashboard_desc"] end,  fallbackName = "Dashboard" },
    { id = "listings",   nameFn = function() return "FrostNet" end,                     descFn = function() return FrostSeek.L["tab_frostnet_desc"] end,     fallbackName = "FrostNet" },
    { id = "lfg",        nameFn = function() return "LFG" end,                          descFn = function() return FrostSeek.L["tab_lfg_desc"] end,          fallbackName = "LFG" },
    { id = "lfm",        nameFn = function() return "LFM" end,                          descFn = function() return FrostSeek.L["tab_lfm_desc"] end,          fallbackName = "LFM" },
    { id = "community",  nameFn = function() return FrostSeek.L["tab_community"] end,  descFn = function() return FrostSeek.L["tab_community_desc"] end,  fallbackName = "Community" },
    { id = "options",    nameFn = function() return FrostSeek.L["tab_options"] end,    descFn = function() return FrostSeek.L["tab_options_desc"] end,    fallbackName = "Options" },
}

for i, tabDef in ipairs(tabDefinitions) do
    local resolvedName = tabDef.fallbackName
    if L and tabDef.nameFn then
        local ok, result = pcall(tabDef.nameFn)
        if ok and result then resolvedName = result end
    end
    local tab = FrostSeek:CreateModernTab(tabDef.id, resolvedName)

    if i == 1 then
        tab:SetPoint("LEFT", TabFrame, "LEFT", 0, 0)
    else
        tab:SetPoint("LEFT", FrostSeek.Tabs[tabDefinitions[i-1].id].button, "RIGHT", 2, 0)
    end

    if tabDef.id == "listings" then
        local badge = tab:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        badge:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -2, -2)
        badge:SetText("")
        badge:SetTextColor(1, 0.3, 0.3, 1)
        badge:Hide()
        FrostSeek.Tabs[tabDef.id].badge = badge
    end

    tab:SetScript("OnEnter", function(self)
        if FrostSeek.ActiveTab ~= tabDef.id then
            self.highlight:Show()
            local ac = _themeRef.Get("textAccent")
            self.text:SetTextColor(ac[1], ac[2], ac[3])
            local bc = _themeRef.Get("borderHover")
            self.border:SetColorTexture(unpack(bc))
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local displayName = tabDef.fallbackName
        local displayDesc = ""
        local L = FrostSeek.L
        if L then
            if tabDef.nameFn then
                local ok, result = pcall(tabDef.nameFn)
                if ok and result then displayName = result end
            end
            if tabDef.descFn then
                local ok, result = pcall(tabDef.descFn)
                if ok and result then displayDesc = result end
            end
        end
        GameTooltip:SetText(displayName)
        GameTooltip:AddLine(displayDesc, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    tab:SetScript("OnLeave", function(self)
        if FrostSeek.ActiveTab ~= tabDef.id then
            self.highlight:Hide()
            local mc = _themeRef.Get("textMuted")
            self.text:SetTextColor(mc[1], mc[2], mc[3])
            self.border:SetColorTexture(unpack(_themeRef.Get("border")))
        end
        GameTooltip:Hide()
    end)
end

local closeBtn = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -5, -5)
closeBtn:SetWidth(30)
closeBtn:SetHeight(30)

local miniButton = CreateFrame("Button", "FrostSeekMiniMapButton", Minimap)
miniButton:SetWidth(32)
miniButton:SetHeight(32)
miniButton:SetFrameStrata("TOOLTIP")
miniButton:SetFrameLevel(100)

local MINIMAP_DEFAULT_ANGLE = 45
local MINIMAP_RADIUS = 80
local minimapAngle = FrostSeekDB.MinimapButtonPosition or MINIMAP_DEFAULT_ANGLE
local rad = math.rad(minimapAngle)
miniButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * MINIMAP_RADIUS, math.sin(rad) * MINIMAP_RADIUS)

local ICON_BASE = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\map\\"

miniButton:SetNormalTexture(ICON_BASE .. "multi.tga")
miniButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

miniButton:EnableMouse(true)
miniButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
miniButton:RegisterForDrag("LeftButton")
miniButton:SetMovable(true)
miniButton:SetClampedToScreen(true)
miniButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
miniButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    local angle = math.deg(math.atan2(y, x))
    FrostSeekDB.MinimapButtonPosition = angle
end)

miniButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" and IsControlKeyDown() then
        local nowDisabled = FrostSeek.ToggleAddonDisabled()
        if nowDisabled then
            LPrint("core_lfg_popups_disabled_hint")
        else
            LPrint("core_lfg_popups_enabled")
        end
        if GameTooltip:IsOwned(self) then
            local onEnter = self:GetScript("OnEnter")
            if onEnter then onEnter(self) end
        end
        return
    end

    if button == "LeftButton" then
        if MainFrame:IsShown() and FrostSeek.ActiveTab == "lfg" then
            MainFrame:Hide()
        else
            MainFrame:Show()
            FrostSeek:SwitchTab("lfg")
        end
    end
end)

miniButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local activeCat = FrostSeek._activeMinimapCategory
    local onlineCount = 0
    if FrostSeek.Presence and FrostSeek.Presence.GetOnlineCount then
        onlineCount = FrostSeek.Presence:GetOnlineCount()
    end
    local isDisabled = FrostSeek.IsAddonDisabled()
    if isDisabled then
        GameTooltip:SetText(L["core_minimap_disabled_title"], 0.8, 0.9, 1)
        GameTooltip:AddLine(L["core_minimap_disabled_lfg"], 1, 0.3, 0.3, true)
        GameTooltip:AddLine(L["core_minimap_disabled_frostnet"], 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine(L["core_minimap_disabled_reenable"], 0.7, 0.85, 1, true)
    elseif activeCat then
        GameTooltip:SetText(L["core_minimap_new_cat_title"] .. activeCat .. "|r", 0.8, 0.9, 1)
    else
        GameTooltip:SetText("FrostSeek", 0.8, 0.9, 1)
    end
    if not isDisabled and onlineCount > 1 then
        GameTooltip:AddLine(string.format(L["core_minimap_online_count"], onlineCount), 0.53, 0.8, 1)
    end
    GameTooltip:AddLine(L["core_minimap_left_click"], 1, 1, 1)
    GameTooltip:AddLine(L["core_minimap_ctrl_click_label"] .. (isDisabled and L["core_minimap_enable_lfg_popups"] or L["core_minimap_disable_lfg_popups"]), 1, 0.6, 0.3)
    GameTooltip:AddLine(L["core_minimap_drag_move"], 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

miniButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

FrostSeek.MiniMapButton = miniButton
FrostSeek._activeMinimapCategory = nil

local CATEGORY_ICONS = {
    KEYSTONE    = ICON_BASE .. "key.tga",
    RAID        = ICON_BASE .. "raid.tga",
    PVP         = ICON_BASE .. "pvp.tga",
    WORLD_BOSS  = ICON_BASE .. "boss.tga",
    MANASTORM   = ICON_BASE .. "manastorm.tga",
    DUNGEON     = ICON_BASE .. "dungeon.tga",
    QUEST       = ICON_BASE .. "quest.tga",
}

local ICON_PRIORITY = {
    KEYSTONE = 6, RAID = 5, PVP = 4,
    WORLD_BOSS = 3, MANASTORM = 2, DUNGEON = 1,
    QUEST = 0,
}

local DEFAULT_ICON = ICON_BASE .. "multi.tga"
local activeMinimapCats = {}

local blinkFrame = CreateFrame("Frame")
blinkFrame:Hide()
local blinkTime = 0
local blinkOn = true

blinkFrame:SetScript("OnUpdate", function(self, elapsed)
    blinkTime = blinkTime + elapsed
    if blinkTime >= 0.4 then
        blinkTime = 0
        blinkOn = not blinkOn
        miniButton:SetAlpha(blinkOn and 1 or 0.3)
    end
end)

local function GetHighestPriorityCategory()
    local bestCat = nil
    local bestPri = 0
    for cat, _ in pairs(activeMinimapCats) do
        if (ICON_PRIORITY[cat] or 0) > bestPri then
            bestPri = ICON_PRIORITY[cat] or 0
            bestCat = cat
        end
    end
    return bestCat
end

local function UpdateMinimapVisual()
    if FrostSeek.IsAddonDisabled() then
        miniButton:SetNormalTexture(ICON_BASE .. "pvp.tga")
        FrostSeek._activeMinimapCategory = nil
        blinkFrame:Hide()
        miniButton:SetAlpha(1)
        return
    end

    local bestCat = GetHighestPriorityCategory()
    if bestCat and CATEGORY_ICONS[bestCat] then
        miniButton:SetNormalTexture(CATEGORY_ICONS[bestCat])
        FrostSeek._activeMinimapCategory = bestCat
        blinkFrame:Show()
        blinkTime = 0
        blinkOn = true
        miniButton:SetAlpha(1)
    else
        miniButton:SetNormalTexture(DEFAULT_ICON)
        FrostSeek._activeMinimapCategory = nil
        blinkFrame:Hide()
        miniButton:SetAlpha(1)
    end
end

function FrostSeek.UpdateMinimapDisabledOverlay()
    if not miniButton then return end
    UpdateMinimapVisual()
end
FrostSeek.UpdateMinimapDisabledOverlay()

function FrostSeek.SetMinimapCategory(category)
    if not category then return end
    activeMinimapCats[category] = true
    UpdateMinimapVisual()
end

function FrostSeek.RemoveMinimapCategory(category)
    if not category then return end
    activeMinimapCats[category] = nil
    UpdateMinimapVisual()
end

if not FrostSeekDB.Settings.minimapButton then
    miniButton:Hide()
end

SLASH_FROSTSEEK1 = "/fs"
SLASH_FROSTSEEK2 = "/frostseek"
SlashCmdList["FROSTSEEK"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "" then
        if MainFrame:IsShown() then
            MainFrame:Hide()
        else
            MainFrame:Show()
            if not FrostSeek.ActiveTab then
                FrostSeek:SwitchTab("dashboard")
            end
        end
    elseif cmd == "online" or cmd == "who" then
        if FrostSeek.Presence then
            FrostSeek.Presence:PrintOnlineUsers()
        end
    elseif cmd == "net" then
        if FrostSeek.Presence and FrostSeek.Presence.TogglePanel then
            FrostSeek.Presence:TogglePanel(MainFrame)
        end
    elseif cmd == "create" then
        MainFrame:Show()
        FrostSeek:SwitchTab("listings")
        if FrostSeek.Listings then
            FrostSeek.Listings.subTab = "create"
            FrostSeek.Listings:RefreshSubTabs()
            FrostSeek.Listings:RefreshContent()
        end
    elseif cmd == "profile" then
        MainFrame:Show()
        FrostSeek:SwitchTab("profile")
    elseif cmd == "ping" then
        if FrostSeek.Presence and FrostSeek.Presence.SendPing then
            FrostSeek.Presence:SendPing()
            LPrint("core_ping_sent")
        end
    else
        MainFrame:Show()
        if not FrostSeek.ActiveTab then
            FrostSeek:SwitchTab("dashboard")
        end
    end
end

SLASH_FSLFG1 = "/fslfg"
SlashCmdList["FSLFG"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("lfg")
end

SLASH_FSLFM1 = "/fslfm"
SlashCmdList["FSLFM"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("lfm")
end

SLASH_FSCOMMUNITY1 = "/fscommunity"
SLASH_FSCOMMUNITY2 = "/fsguild"
SlashCmdList["FSCOMMUNITY"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("community")
end

SLASH_FSLOADTPL1 = "/fsloadtemplate"
SlashCmdList["FSLOADTPL"] = function(msg)
    local name = msg and msg:match("^%s*(.-)%s*$") or ""
    if name == "" then
        LPrint("core_usage_loadtemplate")
        return
    end
    if FrostSeek.Community and FrostSeek.Community.LoadTemplateByName then
        FrostSeek.Community:LoadTemplateByName(name)
    end
end

SLASH_FSDELTPL1 = "/fsdeltemplate"
SlashCmdList["FSDELTPL"] = function(msg)
    local name = msg and msg:match("^%s*(.-)%s*$") or ""
    if name == "" then
        LPrint("core_usage_deltemplate")
        return
    end
    if FrostSeek.Community and FrostSeek.Community.DeleteTemplateByName then
        FrostSeek.Community:DeleteTemplateByName(name)
    end
end

SLASH_FSOPTIONS1 = "/fsoptions"
SlashCmdList["FSOPTIONS"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("options")
end

SLASH_FSPOPUP1 = "/fspopup"
SlashCmdList["FSPOPUP"] = function(msg)
    local LFG = FrostSeek and FrostSeek.Modules and FrostSeek.Modules.lfg
    if not LFG or not LFG.SetPopupUnlockMode then
        print(L["msg_lfg_module_not_loaded"])
        return
    end
    msg = (msg or ""):lower():gsub("%s+", "")
    if msg == "reset" or msg == "default" then
        LFG.ResetPopupAnchor()
    elseif msg == "status" then
        local a = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.popupAnchor
        local b = FrostSeekDB and FrostSeekDB.Listings and FrostSeekDB.Listings.appPopupAnchor
        if a then
            print(string.format(L["core_popup_lfg_anchor_saved"],
                tostring(a.point), tostring(a.relativePoint), a.x or 0, a.y or 0))
        else
            print(L["core_popup_lfg_anchor_default"])
        end
        if b then
            print(string.format(L["core_popup_frostnet_anchor_saved"],
                tostring(b.point), tostring(b.relativePoint), b.x or 0, b.y or 0))
        else
            print(L["core_popup_frostnet_anchor_default"])
        end
    else
        LFG.SetPopupUnlockMode(true)
    end
end

SLASH_FSDISABLE1 = "/fsdisable"
SlashCmdList["FSDISABLE"] = function()
    FrostSeek.SetAddonDisabled(true)
    LPrint("core_lfg_popups_disabled")
end

SLASH_FSENABLE1 = "/fsenable"
SlashCmdList["FSENABLE"] = function()
    FrostSeek.SetAddonDisabled(false)
    LPrint("core_lfg_popups_enabled")
end

SLASH_FSTOGGLE1 = "/fstoggle"
SlashCmdList["FSTOGGLE"] = function()
    local nowDisabled = FrostSeek.ToggleAddonDisabled()
    if nowDisabled then
        LPrint("core_lfg_popups_disabled")
    else
        LPrint("core_lfg_popups_enabled")
    end
end

SLASH_FSDEBUG1 = "/fsdebug"
SlashCmdList["FSDEBUG"] = function()
    print(L["core_debug_header"])
    print(L["core_debug_version"] .. tostring(FrostSeek.VERSION))
    print(L["core_debug_schema_version"] .. tostring(FrostSeekDB._schemaVersion) .. "/" .. tostring(FrostSeek.SCHEMA_VERSION))
    print(L["core_debug_language"] .. tostring(FrostSeekDB.Settings.language))
    print(L["core_debug_log_level"] .. tostring(FrostSeekDB.Settings.logLevel))
    print(L["core_debug_auto_open"] .. tostring(FrostSeekDB.Settings.autoOpen))
    print(L["core_debug_minimap_button"] .. tostring(FrostSeekDB.Settings.minimapButton))
    print(L["core_debug_debug_mode"] .. tostring(FrostSeekDB.Settings.debugMode))
    print(L["core_debug_frostnet_enabled"] .. tostring(FrostSeekDB.Settings.frostnetEnabled))
    print(L["core_debug_save_position"] .. tostring(FrostSeekDB.Settings.savePosition))
    print(L["core_debug_ui_scale"] .. tostring(FrostSeekDB.Settings.uiScale))
    print(L["core_debug_mainframe_scale"] .. tostring(MainFrame:GetScale()))
    print(L["core_debug_mainframe_shown"] .. tostring(MainFrame:IsShown()))
    print(L["core_debug_lfg_disable_lfg"] .. tostring(FrostSeekDB.LFG and FrostSeekDB.LFG.disableLFG))
    print(L["core_debug_lfg_disable_popups"] .. tostring(FrostSeekDB.LFG and FrostSeekDB.LFG.disablePopups))
    print(L["core_debug_quick_disabled"] .. tostring(FrostSeek.IsAddonDisabled()))

    print(L["core_debug_modules_header"])
    for name, module in pairs(FrostSeek.Modules) do
        print("  " .. name .. ": " .. tostring(module ~= nil))
    end

    print(L["core_debug_frostnet_header"])
    local Network = FrostSeek.Network
    if Network then
        print(L["core_debug_channel"] .. tostring(Network.channelName))
        print(L["core_debug_connected"] .. tostring(Network.isConnected))
        print(L["core_debug_channel_id"] .. tostring(Network.channelId))
        print(L["core_debug_queue_length"] .. tostring(Network._queue and #Network._queue or 0))
        if Network._queue and #Network._queue > 0 then
            for i, m in ipairs(Network._queue) do
                if i <= 5 then
                    print("    [" .. i .. "] " .. tostring(string.sub(m, 1, 60)))
                end
            end
            if #Network._queue > 5 then
                print(string.format(L["core_debug_and_more"], #Network._queue - 5))
            end
        end
    end
    local Presence = FrostSeek.Presence
    if Presence then
        print(L["core_debug_online_users"] .. tostring(Presence:GetOnlineCount()))
    end

    print(L["core_debug_v225_modules_header"])
    local VB = FrostSeek.VoiceBridge
    if VB then
        local count = 0
        if FrostSeekDB.VoiceLinks then
            for _ in pairs(FrostSeekDB.VoiceLinks) do count = count + 1 end
        end
        print(string.format(L["core_debug_voicebridge_count"], count))
        print(L["core_debug_voicebridge_api"] .. tostring(Network and Network.usesAddonMessageAPI and "C_ChatInfo.SendAddonMessage" or "Legacy custom channel (FSK)"))
    else
        print(L["core_debug_voicebridge_not_loaded"])
    end

    if FrostSeek.Logger then
        print(string.format(L["core_debug_logger"], #FrostSeek.Logger.Buffer, tostring(FrostSeek.Logger.Level)))
    end

    print(L["core_debug_separator"])
end

SLASH_FSRESET1 = "/fsreset"
SlashCmdList["FSRESET"] = function(msg)
    msg = (msg or ""):lower():gsub("%s+", "")
    if msg ~= "confirm" then
        LPrint("core_reset_warning")
        LPrint("core_reset_hint")
        return
    end

    local savedTemplates = FrostSeekDB.LFM and FrostSeekDB.LFM.favoriteTemplates or nil
    local savedChannelPresets = FrostSeekDB.LFM and FrostSeekDB.LFM.channelPresets or nil

    for k, _ in pairs(FrostSeekDB) do
        if k ~= "_backup_v1" and k ~= "_schemaVersion" then
            FrostSeekDB[k] = nil
        end
    end
    FrostSeekDB._schemaVersion = 1

    MigrateSchema()
    EnsureSettingsIntegrity()

    if savedTemplates and FrostSeekDB.LFM then
        FrostSeekDB.LFM.favoriteTemplates = savedTemplates
    end
    if savedChannelPresets and FrostSeekDB.LFM then
        FrostSeekDB.LFM.channelPresets = savedChannelPresets
    end

    LPrint("core_reset_done")
end

SLASH_FSDUMPLOG1 = "/fsdumplog"
SlashCmdList["FSDUMPLOG"] = function()
    if not FrostSeek.Logger or not FrostSeek.Logger.Buffer then
        LPrint("core_log_empty")
        return
    end
    print(L["core_dumplog_header"] .. #FrostSeek.Logger.Buffer .. L["core_dumplog_entries_suffix"])
    for i, entry in ipairs(FrostSeek.Logger.Buffer) do
        print(string.format("|cff666666[%s]|r |cff%s%s|r: %s",
            entry.ts or "?",
            entry.color or "888888",
            entry.level or "INFO",
            entry.msg or ""))
    end
    print(L["core_dumplog_footer"])
end

SLASH_FSOPEN1 = "/fsopen"
SlashCmdList["FSOPEN"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("dashboard")
    LPrint("core_welcome")
end

SLASH_FSSOUND1 = "/fssound"
SlashCmdList["FSSOUND"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local valid = { "popup", "listing", "applicant", "connect", "disconnect", "whisper" }
    if msg == "" then
        print("|cff88ccffFrostSeek:|r Test suoni custom. Uso: /fssound <tipo>")
        print("  Tipi disponibili: " .. table.concat(valid, ", "))
        print("  Esempio: |cff88ccff/fssound popup|r")
        print("  Nota: questo comando ignora l'impostazione 'Notifiche Silenziose'.")
        return
    end
    local found = false
    for _, v in ipairs(valid) do
        if v == msg then found = true; break end
    end
    if not found then
        print("|cffff5555FrostSeek:|r Tipo suono non valido: '" .. msg .. "'")
        print("  Tipi disponibili: " .. table.concat(valid, ", "))
        return
    end
    local SOUNDS = {
        popup = "Interface\\AddOns\\FrostSeek\\Media\\sound\\popup.wav",
        listing = "Interface\\AddOns\\FrostSeek\\Media\\sound\\listing.wav",
        applicant = "Interface\\AddOns\\FrostSeek\\Media\\sound\\applicant.wav",
        connect = "Interface\\AddOns\\FrostSeek\\Media\\sound\\connect.wav",
        disconnect = "Interface\\AddOns\\FrostSeek\\Media\\sound\\connect.wav",
        whisper = "Sound\\Interface\\TellMessage",
    }
    local soundFile = SOUNDS[msg]
    if not soundFile then
        print("|cffff5555FrostSeek:|r Suono non mappato: " .. msg)
        return
    end
    print("|cff88ccffFrostSeek:|r Riproduco il suono: |cffffff00" .. msg .. "|r")
    if PlaySoundFile then
        PlaySoundFile(soundFile)
    else
        print("|cffff5555FrostSeek:|r PlaySoundFile non disponibile in questo client.")
    end
end

SLASH_FSNET1 = "/fsnet"
SlashCmdList["FSNET"] = function()
    print(L["core_net_status_header"])
    local Network = FrostSeek.Network
    if not Network then
        print(L["core_net_module_not_loaded_err"])
        return
    end
    print(L["core_net_channel_name"] .. tostring(Network.channelName))
    print(L["core_net_connected"] .. tostring(Network.isConnected))
    print(L["core_net_channel_id"] .. tostring(Network.channelId))
    print(L["core_net_queue_length"] .. tostring(Network._queue and #Network._queue or 0))
    print(L["core_net_was_connected"] .. tostring(Network.wasConnected))
    print(L["core_net_join_attempts"] .. tostring(Network.joinAttempts) .. "/" .. tostring(Network.maxJoinAttempts))


    print(L["core_net_channels_seen_header"])
    if GetNumDisplayChannels then
        local okCount, count = pcall(function() return GetNumDisplayChannels() end)
        count = (okCount and count) or 0
        if count == 0 then
            print(L["core_net_no_channels_msg"])
        end
        for i = 1, count do
            local ok, name, _, _, channelNumber = pcall(function()
                return GetChannelDisplayInfo(i)
            end)
            if ok and name then
                local marker = (string.lower(tostring(name)) == "fsk") and "  <== FSK" or ""
                print("  " .. tostring(i) .. ". " .. tostring(name) .. " (num=" .. tostring(channelNumber) .. ")" .. marker)
            end
        end
    else
        print(L["core_net_getnumchannels_unavail"])
    end

    print(L["core_net_my_listing_header"])
    local Listings = FrostSeek.Listings
    if Listings then
        if Listings.myListing then
            local ml = Listings.myListing
            print(L["core_net_listing_id"] .. tostring(ml.id))
            print(L["core_net_listing_activity"] .. tostring(ml.activity))
            print(L["core_net_listing_type"] .. tostring(ml.type))
            print(L["core_net_listing_leader"] .. tostring(ml.leader))
            print(L["core_net_listing_members"] .. tostring(ml.members) .. "/" .. tostring(ml.maxMembers))
        else
            print(L["core_net_no_active_listing"])
        end
        print(L["core_net_total_listings_cache"] .. tostring(Listings.listings and (function() local n=0; for _ in pairs(Listings.listings) do n=n+1 end; return n end)() or 0))
    end

    print(L["core_net_online_users_header"])
    local Presence = FrostSeek.Presence
    if Presence and Presence.GetOnlineCount then
        print(L["core_net_online_count"] .. tostring(Presence:GetOnlineCount()))
        if Presence.onlineUsers then
            local n = 0
            for name, _ in pairs(Presence.onlineUsers) do
                n = n + 1
                if n <= 10 then
                    print("  - " .. tostring(name))
                end
            end
            if n > 10 then
                print(string.format(L["core_net_and_more"], n - 10))
            end
        end
    end

    print(L["core_debug_separator"])
    print("|cff888888Tip: ask your friends to run /fsnet too and compare ChannelId.|r")
    print("|cff888888If your ChannelId is nil while 'Connected: true', there's a sync bug.|r")
    print("|cff888888If your friends show 0 online users, the FSK channel is realm-locked or faction-locked.|r")
end

SLASH_FSCLASS1 = "/fsclass"
SlashCmdList["FSCLASS"] = function(msg)
    local Shared = _G.FrostSeekShared
    if not Shared then
        LPrint("core_shared_not_loaded")
        return
    end

    msg = msg or ""
    local cmd, arg = string.match(msg, "^(%S+)%s*(.*)$")
    cmd = cmd and string.lower(cmd) or ""

    if cmd == "set" and arg and arg ~= "" then
        if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
        FrostSeekDB.Settings.manualClass = arg
        Shared._cachedPlayerClass = nil
        LPrint("core_class_override_set", arg)
        LPrint("core_class_override_hint")
        return
    end

    if cmd == "reset" then
        if FrostSeekDB and FrostSeekDB.Settings then
            FrostSeekDB.Settings.manualClass = nil
        end
        Shared._cachedPlayerClass = nil
        LPrint("core_class_override_cleared")
        return
    end

    print(L["core_class_debug_header"])

    local manual = FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.manualClass
    print(L["core_class_manual_override"] .. (manual and manual ~= "" and "|cff44ff44" .. manual .. "|r" or "|cff666666(none)|r"))

    local className, classFile = UnitClass("player")
    print(L["core_class_unit_class"] .. tostring(className) .. " / " .. tostring(classFile))

    local isCoA = Shared._IsCoARealm and Shared._IsCoARealm() or false
    local Compat = _G.FrostSeekCompat
    local realmName = Compat and Compat.GetRealmName and Compat.GetRealmName() or GetRealmName() or "?"
    local ascMode = Compat and Compat.GetAscensionMode and Compat.GetAscensionMode() or "?"
    local serverType = Compat and Compat.GetServerType and Compat.GetServerType() or "?"
    print(L["core_class_realm"] .. tostring(realmName))
    print(L["core_class_server_type"] .. tostring(serverType))
    print(L["core_class_ascension_mode"] .. tostring(ascMode))
    print(L["core_class_is_coa"] .. tostring(isCoA))

    print(L["core_class_talent_tabs"])
    if GetTalentTabInfo then
        for i = 1, 5 do
            local ok, name = pcall(function() return GetTalentTabInfo(i) end)
            if ok and name and name ~= "" then
                print(L["core_class_tab_prefix"] .. i .. ": " .. tostring(name))
            end
        end
    else
        print(L["core_class_gettalenttabinfo_unavail"])
    end

    local resolved = Shared.GetPlayerClassFile and Shared.GetPlayerClassFile() or classFile or "?"
    print(L["core_class_resolved_class"] .. tostring(resolved) .. "|r")

    local iconPath = Shared.GetClassIcon and Shared.GetClassIcon(resolved) or "?"
    print(L["core_class_icon_path"] .. tostring(iconPath))

    local Presence = FrostSeek.Presence
    if Presence and Presence.onlineUsers then
        local pn = UnitName("player") or ""
        local me = Presence.onlineUsers[pn]
        if me then
            print(L["core_class_broadcast_class"] .. tostring(me.classFile))
        else
            print(L["core_class_broadcast_class"] .. tostring(resolved) .. L["core_class_broadcast_not_pinged"])
        end
    end

    print(L["core_debug_separator"])
    print(L["core_class_override_hint_cmd"])
    print(L["core_class_reset_hint_cmd"])
end
local _tk = FrostSeek._v.a("core", FrostSeek)

local autoOpenHandled = false

local function HandleAutoOpen()
    if autoOpenHandled then return end
    autoOpenHandled = true

    if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.autoOpen == true then
        C_Timer.After(3, function()
            if MainFrame then
                MainFrame:Show()
                if FrostSeek.SwitchTab then
                    FrostSeek:SwitchTab("dashboard")
                end
            end
        end)
    end
end

local function SaveWindowPosition()
    if not FrostSeekDB.Settings.savePosition then return end

    if not FrostSeekDB.Settings.windowPosition then
        FrostSeekDB.Settings.windowPosition = {}
    end

    local point, _, relativePoint, x, y = MainFrame:GetPoint()
    FrostSeekDB.Settings.windowPosition.point = point
    FrostSeekDB.Settings.windowPosition.relativePoint = relativePoint
    FrostSeekDB.Settings.windowPosition.x = x
    FrostSeekDB.Settings.windowPosition.y = y
end

local function InitializeFrostSeek()
    EnsureSettingsIntegrity()

    if FrostSeekDB.Settings.savePosition and FrostSeekDB.Settings.windowPosition then
        MainFrame:ClearAllPoints()
        MainFrame:SetPoint(
            FrostSeekDB.Settings.windowPosition.point,
            UIParent,
            FrostSeekDB.Settings.windowPosition.relativePoint,
            FrostSeekDB.Settings.windowPosition.x,
            FrostSeekDB.Settings.windowPosition.y
        )
    end

    MainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveWindowPosition()
    end)

    local savedScale = FrostSeekDB.Settings.uiScale
    if savedScale then
        MainFrame:SetScale(savedScale)
    end

    if FrostSeekDB.Settings.showWelcome then
        LPrint("core_loaded", FrostSeek.VERSION)
    end
end

local function LoadModules()
    C_Timer.After(1.0, function()
        local modulesToLoad = {
            "dashboard",
            "profile",
            "lfg",
            "lfm",
            "listings",
            "community",
            "options",
            "tooltip"
        }

        for _, moduleName in ipairs(modulesToLoad) do
            local module = FrostSeek.Modules[moduleName]
            if module and module.Initialize then
                local success, err = pcall(function()
                    module:Initialize(ContentFrame)
                end)
                if not success then
                    LPrint("core_module_init_error", tostring(moduleName), tostring(err))
                end
            end
        end

        if FrostSeek.Tabs and FrostSeek.Tabs["dashboard"] then
            FrostSeek:SwitchTab("dashboard")
        end

        local themeAPI = _G.FrostSeekTheme
        if themeAPI and themeAPI.Apply then
            themeAPI.Apply()
        end

        local Shared = _G.FrostSeekShared
        if Shared and Shared.GetServerProfile then
            if FrostSeekDB.Settings.serverProfileManual ~= true then
                FrostSeekDB.Settings.serverProfile = "auto"
            end
        end

        LPrint("core_modules_loaded", FrostSeek.VERSION)
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            HandleAutoOpen()
        end)
    end
end)


local ADDON_CHANNELS = { ["fsk"] = true, ["fsk-evt"] = true, ["blfg"] = true }

local function IsAddonChannelName(chanName)
    if not chanName then return false end
    local lower = string.lower(tostring(chanName))
    lower = string.match(lower, "^%s*%d*%.?%s*(.-)%s*$") or lower
    if ADDON_CHANNELS[lower] then return true end
    return false
end

local _cachedKeywords = nil
local _cachedKeywordsRaw = nil

local function GetFilterKeywords()
    local keywordsRaw = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.chatFilterKeywords or ""
    if _cachedKeywordsRaw == keywordsRaw and _cachedKeywords then
        return _cachedKeywords
    end
    _cachedKeywordsRaw = keywordsRaw
    _cachedKeywords = { "lfg", "lfm", "looking for group", "looking for member", "looking for raid", "lfr" }
    if keywordsRaw ~= "" then
        for kw in string.gmatch(keywordsRaw, "[^,]+") do
            local clean = string.match(kw, "^%s*(.-)%s*$")
            if clean and clean ~= "" then
                table.insert(_cachedKeywords, string.lower(clean))
            end
        end
    end
    return _cachedKeywords
end

local chatFilterLog = {}
local CHAT_FILTER_LOG_LIMIT = 20

local function AddChatFilterLog(sender, msg, reason)
    local entry = string.format("|cffd3d3d3[%s]|r [%s]: %s", sender or "?", reason or "?", msg or "")
    table.insert(chatFilterLog, 1, entry)
    if #chatFilterLog > CHAT_FILTER_LOG_LIMIT then
        table.remove(chatFilterLog)
    end
end

local function FrostSeekChatFilter(self, event, msg, sender, langName, chanName, ...)
    if not msg or msg == "" then return false end

    local db = FrostSeekDB and FrostSeekDB.LFG
    if not db then return false end

    local mainFilterOn = db.chatFilterEnabled == true
    local gprFilterOn  = db.chatFilterGuildPartyRaid == true

    local isGuildPartyRaidEvent =
        event == "CHAT_MSG_GUILD"
        or event == "CHAT_MSG_OFFICER"
        or event == "CHAT_MSG_PARTY"
        or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_RAID"
        or event == "CHAT_MSG_RAID_LEADER"

    if isGuildPartyRaidEvent then
        if not gprFilterOn then
            return false
        end
    else
        if not mainFilterOn then
            return false
        end
    end

    if event == "CHAT_MSG_CHANNEL" then
        if IsAddonChannelName(chanName) then return false end
        local channelBaseName = select(5, ...)
        if channelBaseName and IsAddonChannelName(tostring(channelBaseName)) then
            return false
        end
    end

    if db.chatFilterHideOwnMessages ~= true then
        local playerName = UnitName("player")
        if playerName and sender then
            local senderShort = tostring(sender):match("^([^%-]+)") or tostring(sender)
            if senderShort == playerName then
                return false
            end
        end
    end

    local m = string.lower(msg)

    if m:find("lfg", 1, true)
    or m:find("lfm", 1, true)
    or m:find("lfr", 1, true)
    or m:find("looking for group", 1, true)
    or m:find("looking for member", 1, true)
    or m:find("looking for raid", 1, true)
    or m:match("lf%d+m")
    or m:match("lf%d+")
    or m:find("keystone", 1, true) then
        AddChatFilterLog(sender, msg, "LFG/LFM/Keystone")
        return true
    end

    if m:find("lf", 1, true) then
        if m:find("dps", 1, true)
        or m:find("tank", 1, true)
        or m:find("heal", 1, true)
        or m:find("healer", 1, true)
        or m:find("heals", 1, true)
        or m:find("support", 1, true) then
            AddChatFilterLog(sender, msg, "LF+role")
            return true
        end
    end

    local keywords = GetFilterKeywords()
    for _, kw in ipairs(keywords) do
        if m:find(kw, 1, true) then
            AddChatFilterLog(sender, msg, "keyword:" .. kw)
            return true
        end
    end

    return false
end

local chatFilterRegistered = false
local function RegisterChatFilter()
    if chatFilterRegistered then return end

    if ChatFrame_AddMessageEventFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FrostSeekChatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FrostSeekChatFilter)
    end

    if not _G.FrostSeekOrigChatFrame_OnEvent then
        _G.FrostSeekOrigChatFrame_OnEvent = ChatFrame_OnEvent
        ChatFrame_OnEvent = function(self, event, ...)
            if FrostSeekChatFilter(self, event, ...) then
                return
            end
            return _G.FrostSeekOrigChatFrame_OnEvent(self, event, ...)
        end
    end

    chatFilterRegistered = true
    print("|cff88ccffFrostSeek:|r Filtro chat registrato (CHANNEL, YELL, SAY, GUILD, OFFICER, PARTY, RAID)")
end

C_Timer.After(2, RegisterChatFilter)
C_Timer.After(5, RegisterChatFilter)
C_Timer.After(10, RegisterChatFilter)

SLASH_FSCHATFILTER1 = "/fschatfilter"
SLASH_FSCHATFILTER2 = "/fscf"
SlashCmdList["FSCHATFILTER"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = string.lower(cmd or "")

    if cmd == "log" then
        local n = tonumber(arg) or 10
        local count = math.min(n, #chatFilterLog)
        if count == 0 then
            print("|cff88ccffFrostSeek:|r Log filtro chat vuoto")
            return
        end
        print("|cff88ccffFrostSeek:|r Ultimi " .. count .. " messaggi filtrati:")
        for i = 1, count do
            print(chatFilterLog[i])
        end
    elseif cmd == "status" then
        print("|cff88ccff=== FrostSeek Chat Filter Status ===|r")
        print("  API disponibile: " .. tostring(ChatFrame_AddMessageEventFilter ~= nil))
        print("  Filter registrato: " .. tostring(chatFilterRegistered))
        print("  chatFilterEnabled (canali normali CHANNEL/YELL/SAY): " .. tostring(FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.chatFilterEnabled))
        print("  chatFilterGuildPartyRaid (GILDA/OFFICER/PARTY/RAID): " .. tostring(FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.chatFilterGuildPartyRaid))
        print("  chatFilterKeywords: " .. tostring(FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.chatFilterKeywords))
        local kw = GetFilterKeywords()
        print("  Keywords attive (" .. #kw .. "): " .. table.concat(kw, ", "))
        print("  Messaggi filtrati in log: " .. #chatFilterLog)
    elseif cmd == "reregister" then
        chatFilterRegistered = false
        RegisterChatFilter()
        print("|cff44ff44FrostSeek:|r Filtro re-registrato")
    else
        print("|cff88ccffFrostSeek Chat Filter|r")
        print("  /fscf status - mostra stato filtro")
        print("  /fscf log [n] - mostra ultimi N messaggi filtrati")
        print("  /fscf reregister - forza re-registrazione filtro")
    end
end

local chatSnifferFrame = nil
local chatSnifferActive = false
SLASH_FSCHATSNIFF1 = "/fschatsniff"
SlashCmdList["FSCHATSNIFF"] = function(msg)
    if chatSnifferActive then
        chatSnifferActive = false
        print("|cffff5555FrostSeek:|r Chat sniffer DISATTIVATO")
        return
    end
    chatSnifferActive = true
    if not chatSnifferFrame then
        chatSnifferFrame = CreateFrame("Frame")
    end
    local chatEvents = {
        "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD",
        "CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_WHISPER", "CHAT_MSG_OFFICER",
        "CHAT_MSG_SYSTEM", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_YELL",
        "CHAT_MSG_CHANNEL_JOIN", "CHAT_MSG_CHANNEL_LEAVE",
        "CHAT_MSG_CHANNEL_NOTICE", "CHAT_MSG_CHANNEL_NOTICE_USER",
    }
    for _, evt in ipairs(chatEvents) do
        chatSnifferFrame:RegisterEvent(evt)
    end
    chatSnifferFrame:SetScript("OnEvent", function(self, event, ...)
        if not chatSnifferActive then return end
        local arg1 = ...
        if arg1 and type(arg1) == "string" then
            local lower = string.lower(arg1)
            if string.find(lower, "lfg", 1, true) or string.find(lower, "lfm", 1, true) or
               string.find(lower, "looking for", 1, true) then
                local sender = select(2, ...)
                local chanName = select(4, ...)
                print("|cffffcc00[FSK-SNIFF]|r " .. event .. " | msg=" .. tostring(string.sub(arg1, 1, 50)) ..
                      " | sender=" .. tostring(sender) .. " | chan=" .. tostring(chanName))
            end
        end
    end)
    print("|cff44ff44FrostSeek:|r Chat sniffer ATTIVATO - scrivi o ricevi un messaggio con 'lfg' o 'lfm' per vedere l'evento esatto")
    print("  Esegui di nuovo |cff88ccff/fschatsniff|r per disattivare")
end

local saveFrame = CreateFrame("Frame")
saveFrame:RegisterEvent("PLAYER_LOGOUT")
if pcall(function() saveFrame:RegisterEvent("PLAYER_QUIT") end) then

end
saveFrame:SetScript("OnEvent", function()
    SaveWindowPosition()

    if FrostSeekDB and FrostSeekDB.Settings then
        FrostSeekDB.Settings._lastSaved = time()
    end
end)

InitializeFrostSeek()
LoadModules()