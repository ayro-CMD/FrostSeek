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

Shared.ROLE_COLORS = {
    Tank = {0.29, 0.64, 1.00},
    Healer = {0.27, 1.00, 0.40},
    DPS = {1.00, 0.33, 0.33},
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
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetPoint("CENTER")
    frame:SetSize(320, 120)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -12)
    frame.title:SetText(title or "Confirm")
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetPoint("TOP", frame.title, "BOTTOM", 0, -8)
    frame.text:SetWidth(280)
    frame.text:SetText(text or "Are you sure?")
    frame.confirmBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.confirmBtn:SetSize(128, 24)
    frame.confirmBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -8, 12)
    frame.confirmBtn:SetText(YES or "Yes")
    frame.confirmBtn:SetScript("OnClick", function()
        frame:Hide()
        if onConfirm then onConfirm() end
    end)
    frame.cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.cancelBtn:SetSize(128, 24)
    frame.cancelBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 8, 12)
    frame.cancelBtn:SetText(NO or "No")
    frame.cancelBtn:SetScript("OnClick", function()
        frame:Hide()
        if onCancel then onCancel() end
    end)
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

_G.FrostSeekShared = Shared

if _G.FrostSeek then
    _G.FrostSeek.Shared = Shared
end

return Shared
