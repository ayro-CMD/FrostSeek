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
local VersionCheck = {}
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("versioncheck", VersionCheck)

local L = FrostSeek and FrostSeek.L or function(k) return k end

VersionCheck.CURSEFORGE_URL = "https://www.curseforge.com/wow/addons/frostseek"
VersionCheck.GITHUB_URL     = "https://github.com/ayro-CMD/FrostSeek"

local LOGIN_DELAY_SECONDS = 20

local function EnsureDB()
    if not FrostSeekDB then FrostSeekDB = {} end
    if not FrostSeekDB.VersionCheck then
        FrostSeekDB.VersionCheck = {
            newestSeenVersion = nil,
            newestSeenAt       = 0,
        }
    end
    local db = FrostSeekDB.VersionCheck
    if db.newestSeenVersion == nil then db.newestSeenVersion = nil end
    if db.newestSeenAt       == nil then db.newestSeenAt       = 0 end
    return db
end

local function CompareVersions(vA, vB)
    local Presence = FrostSeek and FrostSeek.Presence
    if Presence and Presence.CompareVersions then
        return Presence:CompareVersions(vA, vB)
    end
    local function parse(v)
        local parts = {}
        for n in string.gmatch(tostring(v), "%d+") do
            table.insert(parts, tonumber(n) or 0)
        end
        return parts
    end
    local a, b = parse(vA), parse(vB)
    local maxLen = math.max(#a, #b)
    for i = 1, maxLen do
        local na = a[i] or 0
        local nb = b[i] or 0
        if na > nb then return 1 end
        if na < nb then return -1 end
    end
    return 0
end
VersionCheck.CompareVersions = CompareVersions

local function GetNewestSeenVersionFromPresence()
    local Presence = FrostSeek and FrostSeek.Presence
    if not Presence or not Presence.onlineUsers then return nil end
    local best, bestAt
    for name, u in pairs(Presence.onlineUsers) do
        local v = u and u.version
        if v and v ~= "" then
            if not best or (Presence.CompareVersions and Presence:CompareVersions(v, best) > 0) then
                best = v
                bestAt = u.seen or u.lastHeartbeat or time()
            end
        end
    end
    return best, bestAt
end

function VersionCheck.ObserveVersion(version)
    if not version or version == "" then return end
    local db = EnsureDB()
    if not db.newestSeenVersion or CompareVersions(version, db.newestSeenVersion) > 0 then
        db.newestSeenVersion = version
        db.newestSeenAt = time()
    end
end

local function ResolveNewestVersion()
    local liveVersion, liveAt = GetNewestSeenVersionFromPresence()
    local db = EnsureDB()

    if liveVersion and CompareVersions(liveVersion, db.newestSeenVersion or "0") >= 0 then
        db.newestSeenVersion = liveVersion
        db.newestSeenAt = liveAt or time()
    end

    return db.newestSeenVersion
end

local function PrintURL(label, url, hexColor)
    local coloredLabel = "|cff" .. hexColor .. label .. "|r"
    print(coloredLabel .. " " .. url)
end

function VersionCheck.RunLoginCheck()
    local myVersion = (FrostSeek and FrostSeek.VERSION) or "0"
    local newestVersion = ResolveNewestVersion()

    if not newestVersion then
        if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
            print(L["version_check_no_data_yet"])
        end
        return
    end

    local cmp = CompareVersions(newestVersion, myVersion)
    if cmp > 0 then
        print("|cffffff00[FrostSeek]|r " ..
              string.format(L["version_check_outdated"],
                            tostring(myVersion), tostring(newestVersion)))
        PrintURL(L["version_check_curseforge_label"] or "Update on CurseForge:",
                 VersionCheck.CURSEFORGE_URL, "88ccff")
        PrintURL(L["version_check_github_label"] or "Source on GitHub:",
                 VersionCheck.GITHUB_URL, "88ccff")
    else
        if FrostSeekDB and FrostSeekDB.Settings and FrostSeekDB.Settings.debugMode then
            print(string.format(L["version_check_up_to_date"], tostring(myVersion)))
        end
    end
end

local function HookPresenceUpdates()
    local Presence = FrostSeek and FrostSeek.Presence
    if not Presence or not Presence.HandlePresence then return end
    if Presence._fskVersionCheckHooked then return end
    local orig = Presence.HandlePresence
    Presence.HandlePresence = function(self, user)
        local ok = pcall(orig, self, user)
        if user and user.version and user.version ~= "" then
            pcall(VersionCheck.ObserveVersion, user.version)

            local myVersion = (FrostSeek and FrostSeek.VERSION) or "0"
            if CompareVersions(user.version, myVersion) > 0 then
                if not VersionCheck._sessionWarned then
                    VersionCheck._sessionWarned = true
                    VersionCheck.RunLoginCheck()
                end
            end
        end
        return ok
    end
    Presence._fskVersionCheckHooked = true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_LOGIN" then return end
    EnsureDB()
    HookPresenceUpdates()
    VersionCheck._sessionWarned = false
    if C_Timer and C_Timer.After then
        C_Timer.After(LOGIN_DELAY_SECONDS, function()
            pcall(VersionCheck.RunLoginCheck)
        end)
    end
end)

FrostSeek.VersionCheck = VersionCheck

SLASH_FSKVERSION1 = "/fsversion"
SLASH_FSKVERSION2 = "/fsv"
SlashCmdList["FSKVERSION"] = function(msg)
    local cmd = string.match(tostring(msg or ""), "^%s*(.-)%s*$") or ""
    cmd = string.lower(cmd)
    local db = EnsureDB()
    local myVersion = (FrostSeek and FrostSeek.VERSION) or "0"
    local newest = ResolveNewestVersion() or "(none)"

    if cmd == "test" then
        local fakeNewest = "9.9.9"
        print("|cff88ccffFrostSeek:|r Test warning triggered (fake newest = v" .. fakeNewest .. ")")
        print("|cffffff00[FrostSeek]|r " ..
              string.format(L["version_check_outdated"], tostring(myVersion), fakeNewest))
        PrintURL(L["version_check_curseforge_label"] or "Update on CurseForge:",
                 VersionCheck.CURSEFORGE_URL, "88ccff")
        PrintURL(L["version_check_github_label"] or "Source on GitHub:",
                 VersionCheck.GITHUB_URL, "88ccff")
        return
    end

    print("|cff88ccff=== FrostSeek VersionCheck ===|r")
    print("  Your version: |cffffff00v" .. tostring(myVersion) .. "|r")
    print("  Newest seen: |cff44ff44v" .. tostring(newest) .. "|r")
    if cmd == "check" then
        VersionCheck.RunLoginCheck()
    elseif cmd == "" then
        print("Usage: /fsversion [check|test]")
    else
        print("Usage: /fsversion [check|test]")
    end
end

return VersionCheck
