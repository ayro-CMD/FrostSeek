local _tk = _G.FrostSeek and _G.FrostSeek._v and _G.FrostSeek._v.a("uiutils", true)

local function _T()
    return _G.FrostSeek and _G.FrostSeek.Theme or _G.FrostSeekTheme
end

local _utilsRegistered = false

local function _ensureRegistered()
    if _utilsRegistered then return end
    _utilsRegistered = true
    local theme = _T()
    if theme and theme.RegisterModule then
        theme.RegisterModule("uiutils")
    end
end

local function _c(token)
    local theme = _T()
    if theme and theme.Get then
        return theme.Get(token)
    end
    return {0.5, 0.5, 0.5}
end

local function _cmul(color, factor)
    if not color then return {0.5, 0.5, 0.5} end
    local result = {}
    for i, v in ipairs(color) do
        if i <= 3 then
            result[i] = math.min(1, v * factor)
        else
            result[i] = v
        end
    end
    return result
end

local function CreateModernButton(parent, width, height, text, color)
    _ensureRegistered()

    local T = _T()
    local primary = color or _c("primary")
    local c = primary

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 70, height or 22)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 1, -1)
    btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)

    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", 0, 0)
    btn.border:SetPoint("BOTTOMRIGHT", 0, 0)
    btn.border:SetColorTexture(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.7)

    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    btn.accent:SetHeight(1.5)
    btn.accent:SetColorTexture(c[1], c[2], c[3], 0.4)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text or "")
    btn.text:SetTextColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2)

    btn.color = c

    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 0.9)
        self.border:SetColorTexture(c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 0.9)
        self.accent:SetColorTexture(c[1], c[2], c[3], 0.8)
        self.text:SetTextColor(min(c[1] * 1.4, 1), min(c[2] * 1.4, 1), min(c[3] * 1.4, 1))
    end)

    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)
        self.border:SetColorTexture(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.7)
        self.accent:SetColorTexture(c[1], c[2], c[3], 0.4)
        self.text:SetTextColor(c[1] * 1.2, c[2] * 1.2, c[3] * 1.2)
    end)

    return btn
end

local function CreateModernEditBox(parent, width, height)
    _ensureRegistered()

    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width or 120, height or 20)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormalSmall")
    eb:SetTextInsets(6, 6, 0, 0)

    local bgC = _c("bgInput")
    local brC = _c("borderInput")
    local acC = _c("accentBar")
    local bgFC = _c("bgInputFocus")
    local brFC = _c("borderFocus")
    local acFC = _c("accentFocus")

    eb.bg = eb:CreateTexture(nil, "BACKGROUND")
    eb.bg:SetPoint("TOPLEFT", 1, -1)
    eb.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    eb.bg:SetColorTexture(unpack(bgC))

    eb.border = eb:CreateTexture(nil, "BORDER")
    eb.border:SetPoint("TOPLEFT", 0, 0)
    eb.border:SetPoint("BOTTOMRIGHT", 0, 0)
    eb.border:SetColorTexture(unpack(brC))

    eb.accent = eb:CreateTexture(nil, "OVERLAY")
    eb.accent:SetPoint("BOTTOMLEFT", 2, 0)
    eb.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    eb.accent:SetHeight(1.5)
    eb.accent:SetColorTexture(unpack(acC))

    eb:SetScript("OnEditFocusGained", function(self)
        self.bg:SetColorTexture(unpack(bgFC))
        self.border:SetColorTexture(unpack(brFC))
        self.accent:SetColorTexture(unpack(acFC))
    end)

    eb:SetScript("OnEditFocusLost", function(self)
        self.bg:SetColorTexture(unpack(bgC))
        self.border:SetColorTexture(unpack(brC))
        self.accent:SetColorTexture(unpack(acC))
    end)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    return eb
end

local function CreateModernDropdown(parent, width, height)
    _ensureRegistered()

    local dd = CreateFrame("Frame", nil, parent)
    dd:SetSize(width or 120, height or 22)

    local brC = _c("borderMenu")
    local acC = _c("accentBar")
    local brHC = _c("borderHover")
    local acFC = _c("accentFocus")
    local bgMenuC = _c("bgMenuBg")
    local textNorm = _c("textNorm")

    dd.bg = dd:CreateTexture(nil, "BACKGROUND")
    dd.bg:SetPoint("TOPLEFT", 0, 0)
    dd.bg:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.bg:SetColorTexture(0, 0, 0, 1)

    dd.border = dd:CreateTexture(nil, "BORDER")
    dd.border:SetPoint("TOPLEFT", 0, 0)
    dd.border:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.border:SetColorTexture(unpack(brC))

    dd.accent = dd:CreateTexture(nil, "OVERLAY")
    dd.accent:SetPoint("BOTTOMLEFT", 2, 0)
    dd.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    dd.accent:SetHeight(1.5)
    dd.accent:SetColorTexture(unpack(acC))

    dd.button = CreateFrame("Button", nil, dd)
    dd.button:SetAllPoints(dd)

    dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dd.text:SetPoint("LEFT", 6, 0)
    dd.text:SetPoint("RIGHT", dd, "RIGHT", -22, 0)
    dd.text:SetJustifyH("LEFT")
    dd.text:SetTextColor(0.9, 0.9, 0.9)
    dd.text:SetText("")

    dd.arrowText = dd:CreateFontString(nil, "OVERLAY")
    dd.arrowText:SetPoint("RIGHT", -6, 0)
    dd.arrowText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    dd.arrowText:SetText("v")
    dd.arrowText:SetTextColor(0.6, 0.65, 0.7, 0.9)

    dd.menu = CreateFrame("Frame", nil, UIParent)
    dd.menu:SetFrameStrata("DIALOG")
    dd.menu:SetToplevel(true)
    dd.menu:EnableMouse(true)
    dd.menu:SetSize(width or 120, 10)
    dd.menu:Hide()

    dd.menuBg = dd.menu:CreateTexture(nil, "BACKGROUND")
    dd.menuBg:SetPoint("TOPLEFT", 0, 0)
    dd.menuBg:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.menuBg:SetColorTexture(unpack(bgMenuC))

    dd.menuBorder = dd.menu:CreateTexture(nil, "BORDER")
    dd.menuBorder:SetPoint("TOPLEFT", 0, 0)
    dd.menuBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    dd.menuBorder:SetColorTexture(unpack(brC))

    dd.menu.buttons = {}
    dd.menu.maxShown = 20
    dd.options = {}
    dd.onChange = nil

    dd.menu:SetScript("OnHide", function()
        dd.border:SetColorTexture(unpack(brC))
        dd.accent:SetColorTexture(unpack(acC))
    end)

    local function CloseMenu()
        dd.menu:Hide()
    end

    dd.closeHandler = CreateFrame("Frame", nil, UIParent)
    dd.closeHandler:RegisterEvent("GLOBAL_MOUSE_DOWN")
    dd.closeHandler:SetScript("OnEvent", function(self, event)
        if dd.menu:IsShown() then
            if not MouseIsOver(dd.menu) and not MouseIsOver(dd) then
                CloseMenu()
            end
        end
    end)

    local function ToggleMenu()
        if dd.menu:IsShown() then
            CloseMenu()
        else
            dd.menu:ClearAllPoints()
            dd.menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
            dd.menu:Show()
            dd.border:SetColorTexture(unpack(brHC))
            dd.accent:SetColorTexture(unpack(acFC))
        end
    end

    dd.button:SetScript("OnClick", ToggleMenu)

    dd.button:SetScript("OnEnter", function()
        if not dd.menu:IsShown() then
            dd.border:SetColorTexture(unpack(brHC))
            dd.accent:SetColorTexture(unpack(acFC))
        end
    end)

    dd.button:SetScript("OnLeave", function()
        if not dd.menu:IsShown() then
            dd.border:SetColorTexture(unpack(brC))
            dd.accent:SetColorTexture(unpack(acC))
        end
    end)

    function dd:SetOptions(options)
        self.options = options or {}
        for _, b in ipairs(self.menu.buttons) do
            b:Hide()
            b:SetParent(nil)
        end
        wipe(self.menu.buttons)

        local count = #self.options
        local maxH = min(count, self.menu.maxShown)
        self.menu:SetHeight(maxH * 22 + 4)

        for i, opt in ipairs(self.options) do
            local b = CreateFrame("Button", nil, self.menu)
            b:SetSize(self:GetWidth() - 2, 22)
            b:SetPoint("TOPLEFT", 1, -2 - (i-1) * 22)

            b.optBg = b:CreateTexture(nil, "BACKGROUND")
            b.optBg:SetAllPoints()
            b.optBg:SetColorTexture(0, 0, 0, 0)

            b.optAccent = b:CreateTexture(nil, "OVERLAY")
            b.optAccent:SetPoint("TOPLEFT", 0, 0)
            b.optAccent:SetSize(2, 22)
            b.optAccent:SetColorTexture(unpack(acC))

            b.optText = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            b.optText:SetPoint("LEFT", 8, 0)
            b.optText:SetPoint("RIGHT", b, "RIGHT", -8, 0)
            b.optText:SetJustifyH("LEFT")
            b.optText:SetText(opt)
            b.optText:SetTextColor(unpack(textNorm))

            b:Show()

            b:SetScript("OnEnter", function(self)
                self.optBg:SetColorTexture(unpack(_c("bgRowHover")))
                self.optAccent:SetColorTexture(unpack(acFC))
                self.optText:SetTextColor(1, 1, 1)
            end)
            b:SetScript("OnLeave", function(self)
                self.optBg:SetColorTexture(0, 0, 0, 0)
                self.optAccent:SetColorTexture(unpack(acC))
                self.optText:SetTextColor(unpack(textNorm))
            end)
            b:SetScript("OnClick", function()
                dd:SetText(opt)
                dd.selectedValue = opt
                CloseMenu()
                if dd.onChange then dd.onChange(opt) end
            end)

            self.menu.buttons[i] = b
        end
    end

    function dd:SetText(txt)
        self.text:SetText(txt)
    end

    function dd:GetText()
        return self.text:GetText()
    end

    return dd
end

local function CreateSmallToggle(parent, text, x, y, width, height, onClick)
    _ensureRegistered()

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 36, height or 20)
    btn:SetPoint("LEFT", parent, "LEFT", x, y)

    local acC = _c("accentBar")
    local brC = _c("borderInput")

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("TOPLEFT", 1, -1)
    btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.bg:SetColorTexture(0.1, 0.1, 0.12, 0.4)

    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetPoint("TOPLEFT", 0, 0)
    btn.border:SetPoint("BOTTOMRIGHT", 0, 0)
    btn.border:SetColorTexture(unpack(brC))

    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetPoint("BOTTOMLEFT", 2, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", -2, 0)
    btn.accent:SetHeight(1.5)
    btn.accent:SetColorTexture(unpack(acC))

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetTextColor(0.7, 0.7, 0.7)

    btn.active = false

    btn:SetScript("OnClick", function(self)
        self.active = not self.active
        if self.active then
            self.bg:SetColorTexture(0.12, 0.28, 0.15, 0.85)
            self.border:SetColorTexture(0.3, 0.7, 0.4, 0.9)
            self.accent:SetColorTexture(0.3, 0.9, 0.4, 0.7)
            self.text:SetTextColor(0.4, 1, 0.4)
        else
            self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.4)
            self.border:SetColorTexture(unpack(brC))
            self.accent:SetColorTexture(unpack(acC))
            self.text:SetTextColor(0.7, 0.7, 0.7)
        end
        if onClick then onClick(self.active) end
    end)

    btn:SetScript("OnEnter", function(self)
        if self.active then
            self.bg:SetColorTexture(0.15, 0.35, 0.18, 0.9)
            self.border:SetColorTexture(0.4, 0.8, 0.5, 1.0)
            self.accent:SetColorTexture(0.4, 1.0, 0.5, 0.9)
        else
            self.bg:SetColorTexture(0.14, 0.18, 0.24, 0.7)
            self.border:SetColorTexture(unpack(_c("borderFocus")))
            self.accent:SetColorTexture(unpack(_c("accentFocus")))
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if self.active then
            self.bg:SetColorTexture(0.12, 0.28, 0.15, 0.85)
            self.border:SetColorTexture(0.3, 0.7, 0.4, 0.9)
            self.accent:SetColorTexture(0.3, 0.9, 0.4, 0.7)
            self.text:SetTextColor(0.4, 1, 0.4)
        else
            self.bg:SetColorTexture(0.1, 0.1, 0.12, 0.4)
            self.border:SetColorTexture(unpack(brC))
            self.accent:SetColorTexture(unpack(acC))
            self.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end)

    return btn
end

local function CreateSettingCheckbox(parent)
    _ensureRegistered()

    local checkbox = CreateFrame("Button", nil, parent)
    checkbox:SetSize(24, 24)

    local brC = _c("borderCheck")
    local bgC = _c("bgCheckbox")

    checkbox.bg = checkbox:CreateTexture(nil, "BACKGROUND")
    checkbox.bg:SetAllPoints()
    checkbox.bg:SetColorTexture(unpack(bgC))

    checkbox.border = checkbox:CreateTexture(nil, "BORDER")
    checkbox.border:SetAllPoints()
    checkbox.border:SetColorTexture(unpack(brC))

    checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
    checkbox.check:SetSize(16, 16)
    checkbox.check:SetPoint("CENTER")
    checkbox.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox.check:SetVertexColor(unpack(_c("primary")))
    checkbox.check:Hide()

    checkbox.highlight = checkbox:CreateTexture(nil, "HIGHLIGHT")
    checkbox.highlight:SetAllPoints()
    checkbox.highlight:SetColorTexture(unpack(_c("bgRowHover")))
    checkbox.highlight:Hide()

    checkbox.checked = false

    checkbox:SetScript("OnEnter", function(self)
        self.highlight:Show()
        self.border:SetColorTexture(unpack(_c("borderHover")))
    end)

    checkbox:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        self.border:SetColorTexture(unpack(brC))
    end)

    return checkbox
end

FrostSeekUIUtils = {
    CreateModernButton = CreateModernButton,
    CreateModernEditBox = CreateModernEditBox,
    CreateModernDropdown = CreateModernDropdown,
    CreateSmallToggle = CreateSmallToggle,
    CreateSettingCheckbox = CreateSettingCheckbox,
    _c = _c,
    _cmul = _cmul,
}
