-- ============================================================
-- FrostSeek - Main Core System
-- ============================================================

local FrostSeek = {}

-- ==================== GLOBAL DATABASE ====================
FrostSeekDB = FrostSeekDB or {}

-- ==================== AYRO STRUTTURA PREDEFINITA ====================
if not FrostSeekDB.LFG then
    FrostSeekDB.LFG = {
        myRole = "",
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
            KEYSTONE = true
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
            KEYSTONE = ""
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

-- AYRO
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

-- A.Y.R.O

if not FrostSeekDB.Settings then
    FrostSeekDB.Settings = {
        uiScale = 1.0,
        windowPosition = nil,
        minimapButton = true,
        autoOpen = false,
        showWelcome = true,
        debugMode = false,
        savePosition = true
    }
end

-- ==================== ASSICURA CHE TUTTI I VALORI ESISTANO ====================
local function EnsureSettingsIntegrity()
    -- Settings
    if FrostSeekDB.Settings.uiScale == nil then FrostSeekDB.Settings.uiScale = 1.0 end
    if FrostSeekDB.Settings.autoOpen == nil then FrostSeekDB.Settings.autoOpen = false end
    if FrostSeekDB.Settings.minimapButton == nil then FrostSeekDB.Settings.minimapButton = true end
    if FrostSeekDB.Settings.savePosition == nil then FrostSeekDB.Settings.savePosition = true end
    if FrostSeekDB.Settings.debugMode == nil then FrostSeekDB.Settings.debugMode = false end
    if FrostSeekDB.Settings.showWelcome == nil then FrostSeekDB.Settings.showWelcome = true end
    
    if FrostSeekDB.LFG and FrostSeekDB.LFG.popupCategories then
        if FrostSeekDB.LFG.popupCategories.WORLD_BOSS == nil then
            FrostSeekDB.LFG.popupCategories.WORLD_BOSS = true
        end
    end

    -- Ensure custom keywords structure
    if FrostSeekDB.LFG and not FrostSeekDB.LFG.customKeywords then
        FrostSeekDB.LFG.customKeywords = {
            DUNGEON = "",
            RAID = "",
            WORLD_BOSS = "",
            PVP = "",
            MANASTORM = "",
            KEYSTONE = ""
        }
    end

    -- Ensure customMessages fields exist (migration for older versions)
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
end

-- Esegui subito l'integrità
EnsureSettingsIntegrity()

-- ==================== CONFIGURATION ====================
FrostSeek.Config = {
    PrimaryColor = {0.2, 0.6, 0.9, 1},
    SecondaryColor = {0.3, 0.3, 0.3, 1},
    ActiveColor = {0.1, 0.5, 0.8, 1},
    BackgroundColor = {0.1, 0.1, 0.1, 0.95},
    BorderColor = {0.4, 0.4, 0.4, 1},
    
    TabHeight = 40,
    TabWidth = 130,
    ButtonHeight = 30,
    ButtonWidth = 120,
    
    TitleFont = "GameFontNormalLarge",
    NormalFont = "GameFontNormal",
    SmallFont = "GameFontNormalSmall"
}

-- ==================== MAIN FRAME ====================
FrostSeek.MainFrame = CreateFrame("Frame", "FrostSeekFrame", UIParent)
local MainFrame = FrostSeek.MainFrame

MainFrame:Hide()

MainFrame:SetWidth(800)
MainFrame:SetHeight(630)
MainFrame:SetPoint("CENTER")
MainFrame:SetFrameStrata("HIGH")

MainFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
MainFrame:SetBackdropColor(unpack(FrostSeek.Config.BackgroundColor))
MainFrame:SetBackdropBorderColor(unpack(FrostSeek.Config.BorderColor))

MainFrame:EnableMouse(true)
MainFrame:SetMovable(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)

-- Allow ESC to close the window
tinsert(UISpecialFrames, "FrostSeekFrame")

-- Title
local title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", MainFrame, "TOP", 0, -12)
title:SetText("|cff88ccffFrost|r|cffffffffSeek|r")
title:SetTextColor(0.8, 0.9, 1)

-- Version
local versionText = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("TOP", title, "BOTTOM", 0, -2)
versionText:SetText("AYRO")

-- ==================== MODERN TAB SYSTEM ====================
MainFrame.TabFrame = CreateFrame("Frame", nil, MainFrame)
local TabFrame = MainFrame.TabFrame

TabFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -50)
TabFrame:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -15, -50)
TabFrame:SetHeight(FrostSeek.Config.TabHeight)

-- Content frame
local ContentFrame = CreateFrame("Frame", nil, MainFrame)
MainFrame.ContentFrame = ContentFrame

ContentFrame:SetPoint("TOPLEFT", TabFrame, "BOTTOMLEFT", 0, -5)
ContentFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 15)

-- Tab storage
FrostSeek.Tabs = {}
FrostSeek.ActiveTab = nil
FrostSeek.Modules = {}

-- ==================== MODERN TAB CREATION ====================
function FrostSeek:CreateModernTab(name, displayName)
    local tab = CreateFrame("Button", "FrostSeekTab_" .. name, TabFrame)
    tab:SetWidth(FrostSeek.Config.TabWidth)
    tab:SetHeight(FrostSeek.Config.TabHeight)
    
    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    tab.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    
    tab.border = tab:CreateTexture(nil, "BORDER")
    tab.border:SetAllPoints()
    tab.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    
    tab.highlight = tab:CreateTexture(nil, "BACKGROUND")
    tab.highlight:SetAllPoints()
    tab.highlight:SetColorTexture(0.25, 0.25, 0.25, 0.9)
    tab.highlight:Hide()
    
    tab.activeOverlay = tab:CreateTexture(nil, "OVERLAY")
    tab.activeOverlay:SetAllPoints()
    tab.activeOverlay:SetColorTexture(0.2, 0.6, 0.9, 0.3)
    tab.activeOverlay:Hide()
    
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("CENTER")
    tab.text:SetText(displayName)
    tab.text:SetTextColor(1, 1, 1)
    
    tab:SetScript("OnEnter", function(self)
        if FrostSeek.ActiveTab ~= name then
            self.highlight:Show()
            self.text:SetTextColor(0.6, 0.8, 1)
        end
    end)
    
    tab:SetScript("OnLeave", function(self)
        if FrostSeek.ActiveTab ~= name then
            self.highlight:Hide()
            self.text:SetTextColor(1, 1, 1)
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

-- ==================== TAB MANAGEMENT ====================
function FrostSeek:SwitchTab(tabName)
    -- Hide current tab
    if self.ActiveTab and self.Tabs[self.ActiveTab] then
        local oldTab = self.Tabs[self.ActiveTab]
        
        --CLOVER
        oldTab.button.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
        oldTab.button.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
        oldTab.button.activeOverlay:Hide()
        oldTab.button.text:SetTextColor(1, 1, 1)
        
        if oldTab.module and oldTab.module.Hide then
            oldTab.module:Hide()
        end
    end
    
    -- NESI
    local newTab = self.Tabs[tabName]
    if newTab then
        newTab.button.bg:SetColorTexture(0.1, 0.2, 0.3, 1)
        newTab.button.border:SetColorTexture(0.3, 0.5, 0.7, 1)
        newTab.button.activeOverlay:Show()
        newTab.button.text:SetTextColor(1, 1, 1)
        
        if newTab.module and newTab.module.Show then
            newTab.module:Show()
        end
        
        self.ActiveTab = tabName
    end
end

-- ==================== MODULE REGISTRATION ====================
function FrostSeek:RegisterModule(name, moduleTable)
    self.Modules[name] = moduleTable
    if self.Tabs[name] then
        self.Tabs[name].module = moduleTable
        if FrostSeekDB.Settings.debugMode then
            print("|cff88ccffFrostSeek|r: Module '" .. name .. "' attached to tab")
        end
    end
    if FrostSeekDB.Settings.debugMode then
        print("|cff88ccffFrostSeek|r: Module '" .. name .. "' registered")
    end
end

-- ==================== CREATE ALL TABS ====================
local tabDefinitions = {
    { id = "dashboard", name = "Dashboard", desc = "System Overview" },
    { id = "lfg", name = "LFG", desc = "Looking For Group" },
    { id = "lfm", name = "LFM", desc = "Looking For Members" },
    { id = "options", name = "Options", desc = "System Settings" }
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
            self.text:SetTextColor(0.6, 0.8, 1)
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tabDef.name)
        GameTooltip:AddLine(tabDef.desc, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    
    tab:SetScript("OnLeave", function(self)
        if FrostSeek.ActiveTab ~= tabDef.id then
            self.highlight:Hide()
            self.text:SetTextColor(1, 1, 1)
        end
        GameTooltip:Hide()
    end)
end

-- ==================== CLOSE BUTTON ====================
local closeBtn = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -5, -5)
closeBtn:SetWidth(30)
closeBtn:SetHeight(30)

-- ==================== MINIMAP BUTTON ====================
local miniButton = CreateFrame("Button", "FrostSeekMiniMapButton", Minimap)
miniButton:SetWidth(32)
miniButton:SetHeight(32)
miniButton:SetFrameStrata("TOOLTIP")
miniButton:SetFrameLevel(100)

local minimapPosition = FrostSeekDB.MinimapButtonPosition or 45
miniButton:SetPoint("CENTER", Minimap, "CENTER", minimapPosition, minimapPosition - 80)

-- Icon paths
local ICON_BASE = "Interface\\AddOns\\FrostSeek\\Media\\texture\\icon\\"

miniButton:SetNormalTexture(ICON_BASE .. "multi.tga")
miniButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

miniButton:EnableMouse(true)
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
    end
end)

miniButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local activeCat = FrostSeek._activeMinimapCategory
    if activeCat then
        GameTooltip:SetText("FrostSeek - |cff88ccffNew " .. activeCat .. "|r", 0.8, 0.9, 1)
    else
        GameTooltip:SetText("FrostSeek", 0.8, 0.9, 1)
    end
    GameTooltip:AddLine("Left Click: Open LFG", 1, 1, 1)
    GameTooltip:AddLine("Drag: Move button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

miniButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- ==================== MINIMAP ICON DYNAMIC SYSTEM ====================
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

-- Priorita
local ICON_PRIORITY = {
    KEYSTONE = 6, RAID = 5, PVP = 4,
    WORLD_BOSS = 3, MANASTORM = 2, DUNGEON = 1,
}

local DEFAULT_ICON = ICON_BASE .. "multi.tga"
local activeMinimapCats = {}

-- Frame per lampeggio
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

-- ==================== SLASH COMMANDS ====================
SLASH_FROSTSEEK1 = "/fs"
SLASH_FROSTSEEK2 = "/frostseek"
SlashCmdList["FROSTSEEK"] = function(msg)
    if MainFrame:IsShown() then
        MainFrame:Hide()
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
    print("autoOpen = " .. tostring(FrostSeekDB.Settings.autoOpen))
    print("minimapButton = " .. tostring(FrostSeekDB.Settings.minimapButton))
    print("debugMode = " .. tostring(FrostSeekDB.Settings.debugMode))
    print("savePosition = " .. tostring(FrostSeekDB.Settings.savePosition))
    print("uiScale = " .. tostring(FrostSeekDB.Settings.uiScale))
    print("MainFrame scale = " .. tostring(MainFrame:GetScale()))
    print("MainFrame is shown = " .. tostring(MainFrame:IsShown()))
    
    print("|cff88ccffModules:|r")
    for name, module in pairs(FrostSeek.Modules) do
        print("  " .. name .. ": " .. tostring(module ~= nil))
    end
    
    print("|cff88ccff====================================|r")
end

SLASH_FSOPEN1 = "/fsopen"
SlashCmdList["FSOPEN"] = function()
    MainFrame:Show()
    FrostSeek:SwitchTab("dashboard")
    print("|cff88ccffFrostSeek:|r Window opened manually")
end

-- ==================== VARIABILE PER TRACCIARE AUTOOPEN====================
local autoOpenHandled = false

-- ==================== FUNZIONE PER APRIRE LA FINESTRA ====================
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
                print("|cff88ccffFrostSeek:|r Auto-open enabled - window opened")
            end
        end)
    else
        if FrostSeekDB.Settings.debugMode then
            print("|cff88ccffFrostSeek:|r Auto-open disabled - window remains hidden")
        end
    end
end

-- ==================== FUNZIONE PER SALVARE LA POSIZIONE ====================
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

-- ==================== INITIALIZATION ====================
local function InitializeFrostSeek()
    EnsureSettingsIntegrity()
    
    -- ORYA
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
    
    -- Save position on drag stop
    MainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveWindowPosition()
    end)
    
    -- Apply UI scale
    local savedScale = FrostSeekDB.Settings.uiScale
    if savedScale then
        MainFrame:SetScale(savedScale)
        if FrostSeekDB.Settings.debugMode then
            print("|cff88ccffFrostSeek:|r UI Scale applied: " .. savedScale)
        end
    end
    
    if FrostSeekDB.Settings.showWelcome then
        print("|cff88ccffFrostSeek loaded!|r")
    end
end

-- ==================== MODULE LOADER ====================
local function LoadModules()
    C_Timer.After(1.0, function()
        local modulesToLoad = {
            "dashboard",
            "lfg", 
            "lfm",
            "options",
            "tooltip"
        }
        
        for _, moduleName in ipairs(modulesToLoad) do
            local module = FrostSeek.Modules[moduleName]
            if module and module.Initialize then
                local success, err = pcall(function()
                    module:Initialize(ContentFrame)
                end)
                if success then
                    if FrostSeekDB.Settings.debugMode then
                        print("|cff88ccffFrostSeek Core:|r Module '" .. moduleName .. "' initialized")
                    end
                else
                    print("|cffff0000FrostSeek Core:|r Error initializing '" .. moduleName .. "': " .. tostring(err))
                end
            elseif FrostSeekDB.Settings.debugMode then
                print("|cff88ccffFrostSeek Core:|r Module '" .. moduleName .. "' not ready")
            end
        end
        
        -- Set active tab to dashboard by default
        if FrostSeek.Tabs and FrostSeek.Tabs["dashboard"] then
            FrostSeek.ActiveTab = "dashboard"
        end
        
        print("|cff88ccffFrostSeek:|r By |cffb188ffAYRO")
    end)
end

-- ==================== EVENTO PLAYER_LOGIN ====================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            HandleAutoOpen()
        end)
    end
end)

-- ==================== AGGIUNGI EVENTO PER IL SALVATAGGIO ====================
local saveFrame = CreateFrame("Frame")
saveFrame:RegisterEvent("PLAYER_LOGOUT")
saveFrame:RegisterEvent("PLAYER_QUIT")
saveFrame:SetScript("OnEvent", function()
    SaveWindowPosition()
    
    if FrostSeekDB and FrostSeekDB.Settings then
        FrostSeekDB.Settings._lastSaved = time()
        if FrostSeekDB.Settings.debugMode then
            print("|cff88ccffFrostSeek:|r Saving settings... uiScale = " .. tostring(FrostSeekDB.Settings.uiScale))
        end
    end
end)

-- ==================== ESPORTAZIONE ====================
_G.FrostSeek = FrostSeek

-- Avvia l'inizializzazione
InitializeFrostSeek()
LoadModules()
