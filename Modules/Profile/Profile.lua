local FrostSeek = _G.FrostSeek

local Profile = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("profile", Profile)

local Shared = _G.FrostSeekShared
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end

local function EnsureProfileDB()
    if not FrostSeekDB then
        FrostSeekDB = {}
    end
    if not FrostSeekDB.Profile then
        FrostSeekDB.Profile = {
            role = "",
            spec = "",
            discord = false,
            note = "",
            autoFill = true,
            autoIlvl = 0,
            autoGs = 0,
            status = "Online",
        }
    end

    local p = FrostSeekDB.Profile
    if p.role == nil or p.role == "" then p.role = "No Role" end
    if p.spec == nil then p.spec = "" end
    if p.discord == nil then p.discord = false end
    if p.note == nil then p.note = "" end
    if p.autoFill == nil then p.autoFill = true end
    if p.autoIlvl == nil then p.autoIlvl = 0 end
    if p.autoGs == nil then p.autoGs = 0 end
    if p.status == nil or p.status == "" then p.status = "Online" end
    return p
end

local function EnsureProfileFields()
    return EnsureProfileDB()
end

EnsureProfileDB()

function Profile:AutoFill()
    local p = EnsureProfileDB()
    if not p then return 0, 0 end

    local ilvl = 0
    if FrostSeek.CalculateGearScore then
        local sum, count = 0, 0
        for i = 1, 17 do
            if i ~= 4 then
                local itemLink = GetInventoryItemLink("player", i)
                if itemLink then
                    local _, _, _, itemLevel = GetItemInfo(itemLink)
                    if itemLevel and itemLevel > 0 then
                        sum = sum + itemLevel
                        count = count + 1
                    end
                end
            end
        end
        ilvl = count > 0 and math.floor((sum / count) + 0.5) or 0
    end

    local gs = 0
    if FrostSeek.CalculateGearScore then
        gs = FrostSeek.CalculateGearScore("player") or 0
    end

    p.autoIlvl = ilvl
    p.autoGs = gs

    return ilvl, gs
end

function Profile:GetProfile()
    local p = EnsureProfileDB()
    if p.autoFill then
        self:AutoFill()
    end
    return p
end

function Profile:GetProfileForApp()
    local p = self:GetProfile()
    local Shared = _G.FrostSeekShared
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end

    return {
        name = UnitName("player") or "",
        class = classFile or "",
        classFile = classFile or "",
        level = tostring(UnitLevel("player") or 60),
        role = p.role or "DPS",
        itemLevel = tostring(p.autoIlvl or 0),
        gearScore = tostring(p.autoGs or 0),
        roleType = p.spec or "",
        discord = p.discord and "Yes" or "No",
        status = p.status or "Online",
        note = p.note or "",
        applied = time(),
    }
end

function Profile:Save()
    self:AutoFill()
end

function Profile:Initialize(parentFrame)
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
    title:SetText("|cff88ccffYour Profile|r")
    curY = curY - 35

    local autoInfo = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoInfo:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    autoInfo:SetWidth(740)
    autoInfo:SetJustifyH("LEFT")
    self.autoInfo = autoInfo
    curY = curY - 50

    local div = F:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    div:SetPoint("TOPRIGHT", F, "TOPRIGHT", -pad, curY)
    div:SetHeight(1)
    div:SetColorTexture(unpack(_tc("line")))
    curY = curY - 15

    local roleLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    roleLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    roleLabel:SetText(_hex("accent") .. "Role|r")
    curY = curY - 22

    local roleButtons = {}
    local roles = { "No Role", "Tank", "Healer", "DPS" }
    local roleColors = { ["No Role"] = "|cff888888", Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555" }

    for i, role in ipairs(roles) do
        local btn = CreateFrame("Button", nil, F)
        btn:SetSize(90, 28)
        btn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + (i - 1) * 95, curY)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetPoint("TOPLEFT", 1, -1)
        btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))

        btn.hoverTex = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hoverTex:SetAllPoints()
        btn.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
        btn.hoverTex:Hide()

        btn.accent = btn:CreateTexture(nil, "OVERLAY")
        btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
        btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
        btn.accent:SetHeight(2)
        btn.accent:SetColorTexture(unpack(_tc("accentBar")))

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(roleColors[role] .. role .. "|r")
        btn.text:SetTextColor(unpack(_tc("textPrimary")))

        btn.roleName = role

        btn:SetScript("OnEnter", function(self)
            self.hoverTex:Show()
            self.text:SetTextColor(unpack(_tc("textAccent")))
            self.border:SetColorTexture(unpack(_tc("borderHover")))
        end)

        btn:SetScript("OnLeave", function(self)
            self.hoverTex:Hide()
            local p2 = EnsureProfileDB()
            if self.roleName == p2.role then
                self.text:SetTextColor(unpack(_tc("textPrimary")))
                self.border:SetColorTexture(unpack(_tc("borderFocus")))
            else
                self.text:SetTextColor(unpack(_tc("textMuted")))
                self.border:SetColorTexture(unpack(_tc("border")))
            end
        end)

        btn:SetScript("OnClick", function(self)
            local p = EnsureProfileDB()
            p.role = self.roleName
            if FrostSeekDB and FrostSeekDB.LFG then
                FrostSeekDB.LFG.myRole = self.roleName
            end
            Profile:UpdateRoleButtons()
            Profile:UpdateAutoInfo()
            if FrostSeek and FrostSeek.LFG and FrostSeek.LFG.roleDropdown then
                FrostSeek.LFG.roleDropdown:SetText(self.roleName)
                FrostSeek.LFG.roleDropdown.selectedValue = self.roleName
            end
        end)

        roleButtons[role] = btn
    end
    self.roleButtons = roleButtons
    curY = curY - 40

    local specLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    specLabel:SetText(_hex("accent") .. "Spec / Secondary Role|r")
    curY = curY - 22

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernEditBox then
        self.specEdit = FrostSeek.UI.CreateModernEditBox(F, 300, 24)
    else
        self.specEdit = CreateFrame("EditBox", nil, F)
        self.specEdit:SetAutoFocus(false)
        self.specEdit:SetFontObject("GameFontNormalSmall")
        self.specEdit:SetWidth(300)
        self.specEdit:SetHeight(24)
    end
    self.specEdit:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    do
        local p = EnsureProfileDB()
        self.specEdit:SetText(p.spec or "")
    end
    self.specEdit:SetScript("OnTextChanged", function(self)
        local p = EnsureProfileDB()
        p.spec = self:GetText() or ""
    end)
    self.specEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 40

    local discLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    discLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    discLabel:SetText(_hex("accent") .. "Discord Ready|r")
    curY = curY - 22

    local discToggle = CreateFrame("Button", nil, F)
    discToggle:SetSize(110, 28)
    discToggle:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)

    discToggle.bg = discToggle:CreateTexture(nil, "BACKGROUND")
    discToggle.bg:SetPoint("TOPLEFT", 1, -1)
    discToggle.bg:SetPoint("BOTTOMRIGHT", -1, 1)

    discToggle.border = discToggle:CreateTexture(nil, "BORDER")
    discToggle.border:SetAllPoints()
    discToggle.border:SetColorTexture(unpack(_tc("border")))

    discToggle.hoverTex = discToggle:CreateTexture(nil, "HIGHLIGHT")
    discToggle.hoverTex:SetAllPoints()
    discToggle.hoverTex:SetColorTexture(unpack(_tc("accentBar")))
    discToggle.hoverTex:Hide()

    discToggle.accent = discToggle:CreateTexture(nil, "OVERLAY")
    discToggle.accent:SetPoint("BOTTOMLEFT", 2, 0)
    discToggle.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    discToggle.accent:SetHeight(2)

    discToggle.text = discToggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    discToggle.text:SetPoint("CENTER")

    discToggle:SetScript("OnEnter", function(self)
        self.hoverTex:Show()
        local p2 = EnsureProfileDB()
        self.border:SetColorTexture(p2.discord and _tc("borderHover") or unpack(_tc("borderHover")))
    end)

    discToggle:SetScript("OnLeave", function(self)
        self.hoverTex:Hide()
        local p2 = EnsureProfileDB()
        if p2.discord then
            self.border:SetColorTexture(0.3, 0.7, 0.4, 0.9)
        else
            self.border:SetColorTexture(unpack(_tc("border")))
        end
    end)

    discToggle:SetScript("OnClick", function(self)
        local p = EnsureProfileDB()
        p.discord = not p.discord
        Profile:UpdateDiscordToggle()
        Profile:UpdateAutoInfo()
        Profile:UpdateRoleButtons()
        print("|cff88ccffFrostNet:|r Discord " .. (p.discord and "|cff44ff44Ready|r" or "|cffff5555Not Available|r"))
    end)
    self.discToggle = discToggle
    curY = curY - 45

    local noteLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    noteLabel:SetText(_hex("accent") .. "Application Notes|r")
    curY = curY - 22

    if FrostSeek and FrostSeek.UI and FrostSeek.UI.CreateModernEditBox then
        self.noteEdit = FrostSeek.UI.CreateModernEditBox(F, 500, 50)
    else
        self.noteEdit = CreateFrame("EditBox", nil, F)
        self.noteEdit:SetAutoFocus(false)
        self.noteEdit:SetFontObject("GameFontNormalSmall")
        self.noteEdit:SetWidth(500)
        self.noteEdit:SetHeight(50)
        self.noteEdit:SetMultiLine(true)
    end
    self.noteEdit:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    do
        local p = EnsureProfileDB()
        self.noteEdit:SetText(p.note or "")
    end
    self.noteEdit:SetScript("OnTextChanged", function(self)
        local p = EnsureProfileDB()
        p.note = self:GetText() or ""
    end)
    self.noteEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - 65

    local previewLabel = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    previewLabel:SetText(_hex("accent") .. "Profile Preview|r")
    curY = curY - 22

    self.preview = F:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.preview:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    self.preview:SetWidth(740)
    self.preview:SetHeight(100)
    self.preview:SetJustifyH("LEFT")
    self.preview:SetJustifyV("TOP")

    self:UpdateDiscordToggle()
    self:UpdateAutoInfo()

    self.frame:Hide()
end

function Profile:UpdateRoleButtons()
    if not self.roleButtons then return end
    local p = EnsureProfileDB()
    local currentRole = p.role or ""
    for role, btn in pairs(self.roleButtons) do
        if role == currentRole then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.border:SetColorTexture(unpack(_tc("borderFocus")))
            btn.accent:SetColorTexture(unpack(_tc("accentFocus")))
            if btn.text then btn.text:SetTextColor(unpack(_tc("textPrimary"))) end
        else
            btn.bg:SetPoint("TOPLEFT", 1, -1)
            btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
            btn.border:SetColorTexture(unpack(_tc("border")))
            btn.accent:SetColorTexture(unpack(_tc("accentBar")))
            if btn.text then btn.text:SetTextColor(unpack(_tc("textMuted"))) end
        end
    end
end

function Profile:UpdateDiscordToggle()
    if not self.discToggle then return end
    local p = EnsureProfileDB()
    local dt = self.discToggle
    if p.discord then
        if dt.bg then dt.bg:SetColorTexture(0.12, 0.28, 0.15, 0.85) end
        if dt.border then dt.border:SetColorTexture(0.3, 0.7, 0.4, 0.9) end
        if dt.accent then dt.accent:SetColorTexture(0.3, 0.7, 0.4, 0.9) end
        if dt.text then
            dt.text:SetText("|cff44ff44Yes|r")
            dt.text:SetTextColor(unpack(_tc("textPrimary")))
        end
    else
        if dt.bg then dt.bg:SetColorTexture(0.2, 0.1, 0.1, 0.85) end
        if dt.border then dt.border:SetColorTexture(unpack(_tc("border"))) end
        if dt.accent then dt.accent:SetColorTexture(unpack(_tc("accentBar"))) end
        if dt.text then
            dt.text:SetText("|cffff5555No|r")
            dt.text:SetTextColor(unpack(_tc("textMuted")))
        end
    end
end

function Profile:UpdateAutoInfo()
    if not self.autoInfo then return end
    local ilvl, gs = self:AutoFill()
    local Shared = _G.FrostSeekShared
    local classFile
    if Shared and Shared.GetPlayerClassFile then
        classFile = Shared.GetPlayerClassFile()
    else
        _, classFile = UnitClass("player")
    end
    local p = EnsureProfileDB()
    local roleName = p.role or "No Role"
    local roleColors = { ["No Role"] = "|cff888888", Tank = "|cff4aa3ff", Healer = "|cff44ff66", DPS = "|cffff5555" }

    local lines = {}
    table.insert(lines, "|cffffffff" .. tostring(UnitName("player") or "?") .. "|r  " ..
        _hex("textDim") .. "Lv " .. tostring(UnitLevel("player") or 60) .. " " ..
        tostring(classFile or "") .. "|r")
    table.insert(lines, "|cff88ccffiLvl:|r |cff44ff44" .. tostring(ilvl or 0) .. "|r   " ..
        "|cff88ccffGS:|r |cffffcc00" .. tostring(gs or 0) .. "|r   " ..
        "|cff88ccffRole:|r " .. (roleColors[p.role] or "|cffffffff") .. roleName .. "|r   " ..
        "|cff88ccffDiscord:|r " .. (p.discord and "|cff44ff44Yes|r" or "|cffff5555No|r"))

    self.autoInfo:SetText(table.concat(lines, "\n"))

    if self.preview then
        local app = self:GetProfileForApp()
        local previewLines = {}
        table.insert(previewLines, _hex("textDim") .. "--- Application Profile ---|r")
        table.insert(previewLines, "|cff88ccffName:|r " .. app.name .. "  |cff88ccffClass:|r " .. app.classFile)
        table.insert(previewLines, "|cff88ccffiLvl:|r " .. app.itemLevel .. "  |cff88ccffGS:|r " .. app.gearScore .. "  |cff88ccffRole:|r " .. app.role)
        if app.roleType and app.roleType ~= "" then
            table.insert(previewLines, "|cff88ccffSpec:|r " .. app.roleType)
        end
        if app.discord == "Yes" then
            table.insert(previewLines, "|cff88ccffDiscord:|r |cff44ff44Available|r")
        end
        if app.note and app.note ~= "" then
            table.insert(previewLines, "|cff88ccffNotes:|r " .. app.note)
        end
        self.preview:SetText(table.concat(previewLines, "\n"))
    end
end

function Profile:Show()
    self:UpdateAutoInfo()
    self:UpdateRoleButtons()
    self:UpdateDiscordToggle()
    if self.frame then self.frame:Show() end
end

function Profile:Hide()
    if self.frame then self.frame:Hide() end
end

FrostSeek.Profile = Profile

if _G.FrostSeek and _G.FrostSeek.RegisterModule then
    _G.FrostSeek:RegisterModule("profile", Profile)
end
if _G.FrostSeekTheme and _G.FrostSeekTheme.RegisterModule then
    _G.FrostSeekTheme.RegisterModule("profile")
end