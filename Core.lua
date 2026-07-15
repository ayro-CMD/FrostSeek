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

FrostSeek.VERSION = "2.1.1"

FrostSeekDB = FrostSeekDB or {}

if not FrostSeekDB.LFG then
    FrostSeekDB.LFG = {
        myRole = "No Role",
        includeCurrentLre = true,
        silentNotifications = false,
        frameDuration = 5,
        dontDisplayDeclinedDuration = 300,
        dontDisplaySpammers = 30,
        disablePopups = false,
        disableLFG = false,
        filterWords = "echo,recruit,lfg,wts,buy,shop,gold,sell,account,boost,carry,guild,pve,eu,na,need,wtt,wtb,bazar,hello,player",
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
        customFilterWords = "",
        showActiveRecruitersWindow = false,
        activeWindowPosition = nil,
        activeWindowCategory = "ALL",
        customMessages = {
            enabled = false,
            template = "inv {role} {class} {ench} {ilvl} ilvl {gs}gs",
            showClass = true,
            showIlvl = true,
            showGs = true,
            showEnchant = true,
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
        autoInviteMinIlvl = 150,
        customMessage = "",
    }
end

if FrostSeekDB.LFM then
    if FrostSeekDB.LFM.autoSpamInterval == nil then FrostSeekDB.LFM.autoSpamInterval = 30 end
    if FrostSeekDB.LFM.spamChannels == nil then FrostSeekDB.LFM.spamChannels = {} end
    if FrostSeekDB.LFM.autoInviteEnabled == nil then FrostSeekDB.LFM.autoInviteEnabled = false end
    if FrostSeekDB.LFM.autoInviteMinIlvl == nil then FrostSeekDB.LFM.autoInviteMinIlvl = 150 end
    if FrostSeekDB.LFM.customMessage == nil then FrostSeekDB.LFM.customMessage = "" end
end

if not FrostSeekDB.MPlusScores then
    FrostSeekDB.MPlusScores = {}
end

if not FrostSeekDB.Profile then
    FrostSeekDB.Profile = {
        role = "No Role",
        spec = "",
        discord = false,
        note = "",
        autoFill = true,
        autoIlvl = 0,
        autoGs = 0,
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
        theme = "ShadowS",
        frostnetEnabled = true,
        applyWhisper = false,
    }
end

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
    if FrostSeekDB.LFG and FrostSeekDB.LFG.popupCategories then
        if FrostSeekDB.LFG.popupCategories.WORLD_BOSS == nil then
            FrostSeekDB.LFG.popupCategories.WORLD_BOSS = true
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
        if cm.template == nil or cm.template == "" then cm.template = "inv {role} {class} {ench} {ilvl} ilvl {gs}gs" end
        if cm.showClass == nil then cm.showClass = true end
        if cm.showIlvl == nil then cm.showIlvl = true end
        if cm.showGs == nil then cm.showGs = true end
        if cm.showEnchant == nil then cm.showEnchant = true end
        if cm.showRole == nil then cm.showRole = true end
        if cm.showAchievement == nil then cm.showAchievement = false end
        if cm.achievementLink == nil then cm.achievementLink = "" end
        if cm.showKeystone == nil then cm.showKeystone = false end
        if cm.keystoneLink == nil then cm.keystoneLink = "" end
    end

    if FrostSeekDB.Profile then
        if FrostSeekDB.Profile.role == nil or FrostSeekDB.Profile.role == "" then FrostSeekDB.Profile.role = "No Role" end
        if FrostSeekDB.Profile.spec == nil then FrostSeekDB.Profile.spec = "" end
        if FrostSeekDB.Profile.discord == nil then FrostSeekDB.Profile.discord = false end
        if FrostSeekDB.Profile.note == nil then FrostSeekDB.Profile.note = "" end
        if FrostSeekDB.Profile.autoFill == nil then FrostSeekDB.Profile.autoFill = true end
        if FrostSeekDB.Profile.autoIlvl == nil then FrostSeekDB.Profile.autoIlvl = 0 end
        if FrostSeekDB.Profile.autoGs == nil then FrostSeekDB.Profile.autoGs = 0 end
    end
end

EnsureSettingsIntegrity()

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

    TitleFont = "GameFontNormalLarge",
    NormalFont = "GameFontNormal",
    SmallFont = "GameFontNormalSmall"
}

FrostSeek.MainFrame = CreateFrame("Frame", "FrostSeekFrame", UIParent)
local MainFrame = FrostSeek.MainFrame

MainFrame:Hide()

MainFrame:SetWidth(800)
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

local title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", MainFrame, "TOP", 0, -12)
title:SetText("|cff88ccffFrost|r|cffffffffSeek|r")
title:SetTextColor(0.8, 0.9, 1)

local versionText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("TOP", title, "BOTTOM", 0, -2)
versionText:SetText("v" .. FrostSeek.VERSION)

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

    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
    end
end

function FrostSeek:RegisterModule(name, moduleTable)
    self.Modules[name] = moduleTable
    if self.Tabs[name] then
        self.Tabs[name].module = moduleTable
    end
end

local tabDefinitions = {
    { id = "dashboard", name = "Dashboard", desc = "System Overview & FrostNet" },
    { id = "listings", name = "FrostNet", desc = "Browse, Create Groups & Profile" },
    { id = "lfg", name = "LFG", desc = "Looking For Group" },
    { id = "lfm", name = "LFM", desc = "Looking For Members" },
    { id = "options", name = "Options", desc = "System Settings" },
}

for i, tabDef in ipairs(tabDefinitions) do
    local tab = FrostSeek:CreateModernTab(tabDef.id, tabDef.name)

    if i == 1 then
        tab:SetPoint("LEFT", TabFrame, "LEFT", 0, 0)
    else
        tab:SetPoint("LEFT", FrostSeek.Tabs[tabDefinitions[i-1].id].button, "RIGHT", 2, 0)
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
        GameTooltip:SetText(tabDef.name)
        GameTooltip:AddLine(tabDef.desc, 0.8, 0.8, 0.8, true)
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

local minimapPosition = FrostSeekDB.MinimapButtonPosition or 45
miniButton:SetPoint("CENTER", Minimap, "CENTER", minimapPosition, minimapPosition - 80)

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
    if button == "LeftButton" then
        if MainFrame:IsShown() and FrostSeek.ActiveTab == "lfg" then
            MainFrame:Hide()
        else
            MainFrame:Show()
            FrostSeek:SwitchTab("lfg")
        end
    elseif button == "RightButton" then
        
        if FrostSeek.Presence and FrostSeek.Presence.TogglePanel then
            FrostSeek.Presence:TogglePanel(MainFrame)
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
    if activeCat then
        GameTooltip:SetText("FrostSeek - |cff88ccffNew " .. activeCat .. "|r", 0.8, 0.9, 1)
    else
        GameTooltip:SetText("FrostSeek", 0.8, 0.9, 1)
    end
    if onlineCount > 1 then
        GameTooltip:AddLine("|cff88ccffFrostNet:|r " .. tostring(onlineCount) .. " online", 0.53, 0.8, 1)
    end
    GameTooltip:AddLine("Left Click: Open LFG", 1, 1, 1)
    GameTooltip:AddLine("Right Click: FrostNet Online", 0.53, 0.8, 1)
    GameTooltip:AddLine("Drag: Move button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

miniButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

FrostSeek.MiniMapButton = miniButton
FrostSeek._activeMinimapCategory = nil

local CATEGORY_ICONS = {
    KEYSTONE    = ICON_BASE .. "rosa.tga",
    RAID        = ICON_BASE .. "orange.tga",
    PVP         = ICON_BASE .. "red.tga",
    WORLD_BOSS  = ICON_BASE .. "giallo.tga",
    MANASTORM   = ICON_BASE .. "viola.tga",
    DUNGEON     = ICON_BASE .. "verde.tga",
}

local ICON_PRIORITY = {
    KEYSTONE = 6, RAID = 5, PVP = 4,
    WORLD_BOSS = 3, MANASTORM = 2, DUNGEON = 1,
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
            print("|cff88ccffFrostNet:|r Ping sent!")
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

SLASH_FSOPTIONS1 = "/fsoptions"
SlashCmdList["FSOPTIONS"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("options")
end

SLASH_FSDEBUG1 = "/fsdebug"
SlashCmdList["FSDEBUG"] = function()
    print("|cff88ccff========== FROSTSEEK DEBUG ==========|r")
    print("version = " .. tostring(FrostSeek.VERSION))
    print("autoOpen = " .. tostring(FrostSeekDB.Settings.autoOpen))
    print("minimapButton = " .. tostring(FrostSeekDB.Settings.minimapButton))
    print("debugMode = " .. tostring(FrostSeekDB.Settings.debugMode))
    print("frostnetEnabled = " .. tostring(FrostSeekDB.Settings.frostnetEnabled))
    print("savePosition = " .. tostring(FrostSeekDB.Settings.savePosition))
    print("uiScale = " .. tostring(FrostSeekDB.Settings.uiScale))
    print("MainFrame scale = " .. tostring(MainFrame:GetScale()))
    print("MainFrame is shown = " .. tostring(MainFrame:IsShown()))

    print("|cff88ccffModules:|r")
    for name, module in pairs(FrostSeek.Modules) do
        print("  " .. name .. ": " .. tostring(module ~= nil))
    end

    print("|cff88ccffFrostNet:|r")
    local Network = FrostSeek.Network
    if Network then
        print("  Channel: " .. tostring(Network.channelName))
        print("  Connected: " .. tostring(Network.isConnected))
        print("  ChannelId: " .. tostring(Network.channelId))
        print("  Queue length: " .. tostring(Network._queue and #Network._queue or 0))
        if Network._queue and #Network._queue > 0 then
            for i, m in ipairs(Network._queue) do
                if i <= 5 then
                    print("    [" .. i .. "] " .. tostring(string.sub(m, 1, 60)))
                end
            end
            if #Network._queue > 5 then
                print("    ... and " .. (#Network._queue - 5) .. " more")
            end
        end
    end
    local Presence = FrostSeek.Presence
    if Presence then
        print("  Online users: " .. tostring(Presence:GetOnlineCount()))
    end

    print("|cff88ccff====================================|r")
end

SLASH_FSOPEN1 = "/fsopen"
SlashCmdList["FSOPEN"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("dashboard")
    print("|cff88ccffFrostSeek:|r Welcome, adventurer!")
end

SLASH_FSNET1 = "/fsnet"
SlashCmdList["FSNET"] = function()
    print("|cff88ccff========== FROSTNET STATUS ==========|r")
    local Network = FrostSeek.Network
    if not Network then
        print("|cffff5555Network module not loaded!|r")
        return
    end
    print("Channel name      : " .. tostring(Network.channelName))
    print("Connected         : " .. tostring(Network.isConnected))
    print("ChannelId         : " .. tostring(Network.channelId))
    print("Queue length      : " .. tostring(Network._queue and #Network._queue or 0))
    print("WasConnected ever : " .. tostring(Network.wasConnected))
    print("Join attempts     : " .. tostring(Network.joinAttempts) .. "/" .. tostring(Network.maxJoinAttempts))

   
    print("|cff88ccff--- Channels seen by WoW client ---|r")
    if GetNumDisplayChannels then
        local count = GetNumDisplayChannels() or 0
        if count == 0 then
            print("  (no channels — player may not be in any custom channel)")
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
        print("  GetNumDisplayChannels not available on this client")
    end

    print("|cff88ccff--- My listing ---|r")
    local Listings = FrostSeek.Listings
    if Listings then
        if Listings.myListing then
            local ml = Listings.myListing
            print("  id       : " .. tostring(ml.id))
            print("  activity : " .. tostring(ml.activity))
            print("  type     : " .. tostring(ml.type))
            print("  leader   : " .. tostring(ml.leader))
            print("  members  : " .. tostring(ml.members) .. "/" .. tostring(ml.maxMembers))
        else
            print("  (no active listing)")
        end
        print("  Total listings in cache: " .. tostring(Listings.listings and (function() local n=0; for _ in pairs(Listings.listings) do n=n+1 end; return n end)() or 0))
    end

    print("|cff88ccff--- Online users ---|r")
    local Presence = FrostSeek.Presence
    if Presence and Presence.GetOnlineCount then
        print("  Online count: " .. tostring(Presence:GetOnlineCount()))
        if Presence.onlineUsers then
            local n = 0
            for name, _ in pairs(Presence.onlineUsers) do
                n = n + 1
                if n <= 10 then
                    print("  - " .. tostring(name))
                end
            end
            if n > 10 then
                print("  ... and " .. (n - 10) .. " more")
            end
        end
    end

    print("|cff88ccff====================================|r")
    print("|cff888888Tip: ask your friends to run /fsnet too and compare ChannelId.|r")
    print("|cff888888If your ChannelId is nil while 'Connected: true', there's a sync bug.|r")
    print("|cff888888If your friends show 0 online users, the FSK channel is realm-locked or faction-locked.|r")
end

SLASH_FSCLASS1 = "/fsclass"
SlashCmdList["FSCLASS"] = function(msg)
    local Shared = _G.FrostSeekShared
    if not Shared then
        print("|cffff5555FrostSeek:|r Shared module not loaded!")
        return
    end

    msg = msg or ""
    local cmd, arg = string.match(msg, "^(%S+)%s*(.*)$")
    cmd = cmd and string.lower(cmd) or ""

    if cmd == "set" and arg and arg ~= "" then
        if not FrostSeekDB.Settings then FrostSeekDB.Settings = {} end
        FrostSeekDB.Settings.manualClass = arg
        Shared._cachedPlayerClass = nil
        print("|cff88ccffFrostSeek:|r Manual class override set to |cffffffff" .. arg .. "|r")
        print("|cff888888Type /fsclass reset to remove the override.|r")
        return
    end

    if cmd == "reset" then
        if FrostSeekDB and FrostSeekDB.Settings then
            FrostSeekDB.Settings.manualClass = nil
        end
        Shared._cachedPlayerClass = nil
        print("|cff88ccffFrostSeek:|r Manual class override cleared. Using auto-detection.")
        return
    end

    print("|cff88ccff========== CLASS DETECTION DEBUG ==========|r")

    local manual = FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.manualClass
    print("1. Manual override : " .. (manual and manual ~= "" and "|cff44ff44" .. manual .. "|r" or "|cff666666(none)|r"))

    local className, classFile = UnitClass("player")
    print("2. UnitClass        : " .. tostring(className) .. " / " .. tostring(classFile))

    local isCoA = Shared._IsCoARealm and Shared._IsCoARealm() or false
    local Compat = _G.FrostSeekCompat
    local realmName = Compat and Compat.GetRealmName and Compat.GetRealmName() or GetRealmName() or "?"
    local ascMode = Compat and Compat.GetAscensionMode and Compat.GetAscensionMode() or "?"
    local serverType = Compat and Compat.GetServerType and Compat.GetServerType() or "?"
    print("3. Realm            : " .. tostring(realmName))
    print("   Server type      : " .. tostring(serverType))
    print("   Ascension mode   : " .. tostring(ascMode))
    print("   IsCoA            : " .. tostring(isCoA))

    print("4. Talent tabs      :")
    if GetTalentTabInfo then
        for i = 1, 5 do
            local ok, name = pcall(function() return GetTalentTabInfo(i) end)
            if ok and name and name ~= "" then
                print("   Tab " .. i .. ": " .. tostring(name))
            end
        end
    else
        print("   |cffff5555GetTalentTabInfo not available|r")
    end

    local resolved = Shared.GetPlayerClassFile and Shared.GetPlayerClassFile() or classFile or "?"
    print("5. Resolved class   : |cff44ff44" .. tostring(resolved) .. "|r")

    local iconPath = Shared.GetClassIcon and Shared.GetClassIcon(resolved) or "?"
    print("6. Icon path        : " .. tostring(iconPath))

    local Presence = FrostSeek.Presence
    if Presence and Presence.onlineUsers then
        local pn = UnitName("player") or ""
        local me = Presence.onlineUsers[pn]
        if me then
            print("7. Broadcast class  : " .. tostring(me.classFile))
        else
            print("7. Broadcast class  : " .. tostring(resolved) .. " |cff888888(not yet pinged)|r")
        end
    end

    print("|cff88ccff====================================|r")
    print("|cff888888To override: /fsclass set Templar|r")
    print("|cff888888To reset:    /fsclass reset|r")
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
        print("|cff88ccffFrostSeek v" .. FrostSeek.VERSION .. " loaded!|r  |cff666666-- AYRO|r")
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
                    print("|cffff0000FrostSeek Core:|r Error initializing '" .. moduleName .. "': " .. tostring(err))
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

        print("|cff88ccffFrostSeek:|r v" .. FrostSeek.VERSION .. " -- All modules loaded")
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