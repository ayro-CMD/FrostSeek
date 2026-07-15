local FrostSeek = _G.FrostSeek
local Shared = _G.FrostSeekShared
local UI = _G.FrostSeekUIUtils
local L = FrostSeek and FrostSeek.L

local History = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("history", History)

local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end

if not FrostSeekDB.History then
    FrostSeekDB.History = {}
end

local MAX_HISTORY = 200
local ROW_HEIGHT = 24
local MAX_DISPLAY_ROWS = 12

local CATEGORY_COLORS = {
    DUNGEON = "|cFF00FF00",
    RAID = "|cFFFFAA00",
    WORLD_BOSS = "|cFFFFA500",
    PVP = "|cFFFF5555",
    MANASTORM = "|cFFAA88FF",
    KEYSTONE = "|cFFFF88FF",
    MISC = "|cFF888888",
}

local CATEGORY_LABELS = {
    DUNGEON = "Dungeon",
    RAID = "Raid",
    WORLD_BOSS = "WB",
    PVP = "PvP",
    MANASTORM = "MS",
    KEYSTONE = "KS",
    MISC = "Misc",
}

function History:AddEntry(entry)
    if not entry then return end
    if not FrostSeekDB.History then FrostSeekDB.History = {} end

    entry.timestamp = entry.timestamp or time()
    entry.dateStr = entry.dateStr or date("%H:%M", entry.timestamp)

    table.insert(FrostSeekDB.History, 1, entry)

    while #FrostSeekDB.History > MAX_HISTORY do
        table.remove(FrostSeekDB.History)
    end

    if History.scrollFrame and History.frame and History.frame:IsShown() then
        History:RefreshList()
    end
end

function History:RecordJoin(sender, dungeon, category)
    self:AddEntry({
        type = "join",
        sender = sender or "Unknown",
        dungeon = dungeon or "",
        category = category or "MISC",
    })
end

function History:RecordCreate(dungeon, category)
    self:AddEntry({
        type = "create",
        sender = UnitName("player") or "You",
        dungeon = dungeon or "",
        category = category or "MISC",
    })
end

function History:RecordApply(listingActivity)
    self:AddEntry({
        type = "apply",
        sender = UnitName("player") or "You",
        dungeon = listingActivity or "",
        category = "DUNGEON",
    })
end

function History:Clear()
    FrostSeekDB.History = {}
    if History.scrollFrame then
        History:RefreshList()
    end
    print("|cff88ccffFrostSeek History:|r All history cleared")
end

function History:GetCount()
    return FrostSeekDB.History and #FrostSeekDB.History or 0
end

function History:Initialize(parentFrame)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end

    if self.frame then
        self.frame:SetParent(parentFrame)
        self.frame:ClearAllPoints()
        self.frame:SetAllPoints(parentFrame)
        self.frame:Hide()
        return
    end

    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local F = self.frame
    local pad = 18
    local curY = -15

    local title = F:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    title:SetText("|cff88ccffActivity History|r")
    curY = curY - 30

    local subtitle = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    subtitle:SetWidth(740)
    subtitle:SetJustifyH("LEFT")
    self.subtitle = subtitle
    curY = curY - 20

    local filterLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    filterLabel:SetText(_hex("accent") .. "Filter|r")
    curY = curY - 22

    self.filterDropdown = UI.CreateModernDropdown(F, 160, 22)
    self.filterDropdown:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    self.filterDropdown:SetOptions({"All", "Joined", "Created", "Applied", "Dungeon", "Raid", "PvP", "Keystone"})
    self.filterDropdown:SetText("All")
    self.filterDropdown.onChange = function(opt)
        History.currentFilter = opt
        History:RefreshList()
    end
    self.currentFilter = "All"

    local clearBtn = UI.CreateModernButton(F, 90, 22, "Clear All", _tc("catPvP"))
    clearBtn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + 170, curY)
    clearBtn:SetScript("OnClick", function()
        Shared.ConfirmDialog("Clear History", "Delete all activity history?", function()
            History:Clear()
        end)
    end)

    curY = curY - 35

    
    local headerBg = F:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    headerBg:SetPoint("TOPRIGHT", F, "TOPRIGHT", -pad, curY)
    headerBg:SetHeight(20)
    headerBg:SetColorTexture(unpack(_tc("bgBlock")))

    local headers = {
        { text = "Time", width = 55, x = pad + 6 },
        { text = "Type", width = 55, x = pad + 66 },
        { text = "Category", width = 60, x = pad + 126 },
        { text = "Activity", width = 200, x = pad + 196 },
        { text = "Player", width = 150, x = pad + 410 },
    }

    for _, h in ipairs(headers) do
        local ht = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ht:SetPoint("TOPLEFT", F, "TOPLEFT", h.x, curY + 2)
        ht:SetWidth(h.width)
        ht:SetJustifyH("LEFT")
        ht:SetText(_hex("textDim") .. h.text .. "|r")
    end
    curY = curY - 22

    
    self.scrollFrame = CreateFrame("ScrollFrame", "FrostSeekHistoryScroll", F, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad - 20, 10)

    self.scrollChild = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollChild:SetWidth(750)
    self.scrollChild:SetHeight(MAX_DISPLAY_ROWS * ROW_HEIGHT)
    self.scrollFrame:SetScrollChild(self.scrollChild)

    self.rowPool = {}

    self.frame:Hide()
end

function History:RefreshList()
    if not self.scrollChild then return end

    for _, row in ipairs(self.rowPool) do
        row:Hide()
    end

    local history = FrostSeekDB.History or {}
    local filtered = {}

    for _, entry in ipairs(history) do
        local pass = true
        if self.currentFilter == "Joined" and entry.type ~= "join" then pass = false end
        if self.currentFilter == "Created" and entry.type ~= "create" then pass = false end
        if self.currentFilter == "Applied" and entry.type ~= "apply" then pass = false end
        if self.currentFilter == "Dungeon" and entry.category ~= "DUNGEON" then pass = false end
        if self.currentFilter == "Raid" and entry.category ~= "RAID" then pass = false end
        if self.currentFilter == "PvP" and entry.category ~= "PVP" then pass = false end
        if self.currentFilter == "Keystone" and entry.category ~= "KEYSTONE" then pass = false end
        if pass then
            table.insert(filtered, entry)
        end
    end

    if self.subtitle then
        self.subtitle:SetText(string.format("|cff888888Showing %d of %d entries|r", #filtered, #history))
    end

    self.scrollChild:SetHeight(math.max(MAX_DISPLAY_ROWS * ROW_HEIGHT, #filtered * ROW_HEIGHT))

    for i, entry in ipairs(filtered) do
        if i > MAX_HISTORY then break end

        local row = self.rowPool[i]
        if not row then
            row = CreateFrame("Frame", nil, self.scrollChild)
            row:SetHeight(ROW_HEIGHT)
            row:SetWidth(750)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()

            row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.timeText:SetPoint("LEFT", row, "LEFT", 6, 0)
            row.timeText:SetWidth(55)
            row.timeText:SetJustifyH("LEFT")

            row.typeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.typeText:SetPoint("LEFT", row, "LEFT", 66, 0)
            row.typeText:SetWidth(55)
            row.typeText:SetJustifyH("LEFT")

            row.catText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.catText:SetPoint("LEFT", row, "LEFT", 126, 0)
            row.catText:SetWidth(60)
            row.catText:SetJustifyH("LEFT")

            row.activityText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.activityText:SetPoint("LEFT", row, "LEFT", 196, 0)
            row.activityText:SetWidth(200)
            row.activityText:SetJustifyH("LEFT")

            row.playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.playerText:SetPoint("LEFT", row, "LEFT", 410, 0)
            row.playerText:SetWidth(150)
            row.playerText:SetJustifyH("LEFT")

            self.rowPool[i] = row
        end

        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -(i - 1) * ROW_HEIGHT + ROW_HEIGHT)

        local bgC = (i % 2 == 0) and _tc("bgRowEven") or _tc("bgRowOdd")
        row.bg:SetColorTexture(unpack(bgC))

        row.timeText:SetText(entry.dateStr or "??:??")
        row.timeText:SetTextColor(unpack(_tc("textDim")))

        local typeLabel = entry.type == "join" and "|cff44ff44Joined|r" or
                          entry.type == "create" and "|cff88ccffCreated|r" or
                          entry.type == "apply" and "|cffffcc00Applied|r" or "|cff888888?|r"
        row.typeText:SetText(typeLabel)

        local catColor = CATEGORY_COLORS[entry.category] or CATEGORY_COLORS.MISC
        local catLabel = CATEGORY_LABELS[entry.category] or "Misc"
        row.catText:SetText(catColor .. catLabel .. "|r")

        row.activityText:SetText(entry.dungeon or "")
        row.activityText:SetTextColor(unpack(_tc("textPrimary")))

        row.playerText:SetText(entry.sender or "")
        row.playerText:SetTextColor(unpack(_tc("textMuted")))

        row:Show()
    end
end

function History:Show()
    self:RefreshList()
    if self.frame then self.frame:Show() end
end

function History:Hide()
    if self.frame then self.frame:Hide() end
end

FrostSeek.History = History

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("history", History)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("history")
end
