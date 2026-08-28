--[[
==============================================================================
 FrostSeek - Font System (Fonts.lua)
==============================================================================
 Copyright (c) 2026 Ayro. All rights reserved.

 License: FrostSeek Proprietary License - All Rights Reserved
 Author:  Ayro
==============================================================================
]]

FSK_FontSystem = {
    templates = {
        { obj = "FSKFontNormalSmall",  src = "GameFontNormalSmall",  size = 10 },
        { obj = "FSKFontNormal",       src = "GameFontNormal",       size = 12 },
        { obj = "FSKFontNormalLarge",  src = "GameFontNormalLarge",  size = 14 },
        { obj = "FSKFontNormalHuge",   src = "GameFontNormalHuge",   size = 20 },
        { obj = "FSKFontDisableSmall", src = "GameFontDisableSmall", size = 10 },
    },
    objects = {},
    report = {},
}

local BUNDLED_FONTS = {
    "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\Carlito-Regular.ttf",
    "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\LiberationSans-Regular.ttf",
    "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\LiberationSerif-Regular.ttf",
    "Interface\\AddOns\\FrostSeek\\Media\\Fonts\\DejaVuSans.ttf",
}
FSK_FontSystem.BUNDLED_FONTS = BUNDLED_FONTS

local FALLBACK_FONTS = {
    "Fonts\\FRIZQT__.TTF",
    "Fonts\\ARIALN.TTF",
    "Fonts\\SKURRI.TTF",
    "Fonts\\MORPHEUS.TTF",
}

local CANDIDATE_SRCS = {
    "GameFontNormalSmall", "GameFontNormal", "GameFontNormalLarge",
    "GameFontNormalHuge", "GameFontDisableSmall", "GameFontWhite",
    "GameFontHighlightSmall", "GameFontHighlight", "GameFontGreen",
    "SystemFont_Shadow_Med1", "SystemFont_Med1", "SystemFont_Small",
    "QuestFont", "QuestFont_Large", "GameTooltipText",
    "NumberFontNormal", "GameFontBlack", "ChatFontNormal",
}

local function try(fn)
    local ok, a, b, c = pcall(fn)
    if ok then return true, a, b, c end
    return false
end

local _probeFrame
local function newProbeString()
    if not _probeFrame then
        local ok, f = pcall(CreateFrame, "Frame", nil, nil)
        if not ok or not f then return nil end
        pcall(f.Hide, f)
        _probeFrame = f
    end
    local ok, fs = pcall(_probeFrame.CreateFontString, _probeFrame, nil, "BACKGROUND")
    if not ok or not fs then return nil end
    return fs
end

local function fontWorks(obj)
    if not obj then return false end
    local ok, file = try(function() return obj:GetFont() end)
    if not ok or not file or file == "" then return false end
    local fs = newProbeString()
    pcall(fs.SetFontObject, fs, obj)
    return pcall(fs.SetText, fs, "FrostSeek")
end
FSK_FontSystem.FontWorks = fontWorks


local function findAnyValidBlizzardFont()
    for _, name in ipairs(CANDIDATE_SRCS) do
        local o = _G[name]
        if o then
            local ok, file, size, flags = try(function() return o:GetFont() end)
            if ok and file and file ~= "" then
                return file, size, flags
            end
        end
    end
end
FSK_FontSystem.FindAnyValidBlizzardFont = findAnyValidBlizzardFont

local function trySetFont(obj, file, size, flags)
    if not file or file == "" then return false end
    try(function() obj:SetFont(file, size or 12, flags or "") end)
    return fontWorks(obj)
end

local function copyFontProps(obj, src)
    if not src then return end
    try(function()
        local r, g, b, a = src:GetTextColor()
        if r then obj:SetTextColor(r, g, b, a or 1) end
    end)
    try(function()
        local r, g, b, a = src:GetShadowColor()
        if r then obj:SetShadowColor(r, g, b, a or 1) end
    end)
    try(function()
        local x, y = src:GetShadowOffset()
        if x or y then obj:SetShadowOffset(x or 1, y or -1) end
    end)
    try(function()
        local sp = src:GetSpacing()
        if sp then obj:SetSpacing(sp) end
    end)
end

local function deriveNative(obj, src)
    if not src then return false end
    if try(function() obj:CopyFontObject(src) end) and fontWorks(obj) then
        return true
    end
    try(function()
        local file, size, flags = src:GetFont()
        if file then obj:SetFont(file, size, flags) end
    end)
    copyFontProps(obj, src)
    return fontWorks(obj)
end

local function applyBestAvailable(obj, size)
    for _, b in ipairs(BUNDLED_FONTS) do
        if trySetFont(obj, b, size) then return "bundled" end
    end
    local file, _, flags = findAnyValidBlizzardFont()
    if file and trySetFont(obj, file, size, flags) then return "wide-scan" end
    for _, ff in ipairs(FALLBACK_FONTS) do
        if trySetFont(obj, ff, size) then return "classic" end
    end
    return nil
end
FSK_FontSystem.ApplyBestAvailable = applyBestAvailable

function FSK_FontSystem.DeriveFromSource(obj, src, size)
    if not obj then return false end
    if deriveNative(obj, src) then return true end
    return applyBestAvailable(obj, size) ~= nil
end

local function buildTemplate(t)
    local obj = _G[t.obj]
    if not obj then
        local ok, created = pcall(CreateFont, t.obj)
        if ok and created then obj = created end
    end
    if not obj then
        FSK_FontSystem.report[t.obj] = "create-failed"
        return nil
    end
    _G[t.obj] = obj
    t.object = obj
    FSK_FontSystem.objects[t.obj] = obj

    if deriveNative(obj, _G[t.src]) then
        FSK_FontSystem.report[t.obj] = "native"
        return obj
    end

    local how = applyBestAvailable(obj, t.size)
    if how == "bundled" then
        copyFontProps(obj, _G[t.src])
    end
    FSK_FontSystem.report[t.obj] = how or "FAILED"
    return obj
end

for _, t in ipairs(FSK_FontSystem.templates) do
    buildTemplate(t)
end

function FSK_FontSystem.EnsureValid()
    for _, t in ipairs(FSK_FontSystem.templates) do
        local obj = t.object or _G[t.obj]
        if obj and not fontWorks(obj) then
            buildTemplate(t)
        else
            _G[t.obj] = obj
            t.object = obj
            FSK_FontSystem.objects[t.obj] = obj
        end
    end
end

function FSK_FontSystem.IsHealthy()
    for _, t in ipairs(FSK_FontSystem.templates) do
        local obj = t.object or _G[t.obj]
        if not obj or not fontWorks(obj) then
            return false, t.obj
        end
    end
    return true
end

local TEMPLATE_SIZE = {}
for _, t in ipairs(FSK_FontSystem.templates) do
    TEMPLATE_SIZE[t.obj] = t.size or 12
end

function FSK_FontSystem.SafeText(fs, templateName, text)
    if not fs then return false end
    if pcall(fs.SetText, fs, text) then return true end
    local obj = FSK_FontSystem.objects[templateName] or _G[templateName]
    if obj then
        pcall(fs.SetFontObject, fs, obj)
        if pcall(fs.SetText, fs, text) then return true end
    end
    for _, b in ipairs(BUNDLED_FONTS) do
        pcall(fs.SetFont, fs, b, TEMPLATE_SIZE[templateName] or 12, "")
        if pcall(fs.SetText, fs, text) then return true end
    end
    return false
end

do
    local bundled, failed = 0, 0
    for _, status in pairs(FSK_FontSystem.report) do
        if status == "FAILED" or status == "create-failed" then
            failed = failed + 1
        elseif status == "bundled" then
            bundled = bundled + 1
        end
    end
    if failed > 0 then
        pcall(print, "|cffff4444FrostSeek|r: font system: " .. failed
            .. " font object(s) could not be initialised - please report this message.")
    elseif bundled > 0 then
        pcall(print, "|cff88ccffFrostSeek|r: using bundled fonts"
            .. " (client fonts not usable on this client).")
    end
end
