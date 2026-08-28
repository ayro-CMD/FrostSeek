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
local Shared = _G.FrostSeekShared
local _tc = Shared and Shared._tc or function(t) return {0.5,0.5,0.5} end
local _hex = Shared and Shared._hex or function(t) return "|cFF888888" end
local UI = _G.FrostSeekUIUtils
local Listings = _G.FrostSeek and _G.FrostSeek.Listings
local _tk = FrostSeek and FrostSeek._v and FrostSeek._v.a("listings_ui", Listings)
local L = FrostSeek.L
local Lf = FrostSeek.Lf or function(k, ...) return string.format(k, ...) end
local _C = Listings._core
local ACTIVITY_TYPES = _C.ACTIVITY_TYPES
local APP_PENDING_EXPIRE = _C.APP_PENDING_EXPIRE
local BOSS_DIFFICULTIES = _C.BOSS_DIFFICULTIES
local DIFFICULTIES = _C.DIFFICULTIES
local EVENT_DIFFICULTIES = _C.EVENT_DIFFICULTIES
local KEY_DIFFICULTIES = _C.KEY_DIFFICULTIES
local LISTING_EXPIRE = _C.LISTING_EXPIRE
local LOOT_OPTIONS = _C.LOOT_OPTIONS
local MANASTORM_DIFFICULTIES = _C.MANASTORM_DIFFICULTIES
local MAX_BROWSE_ROWS = _C.MAX_BROWSE_ROWS
local PVP_DIFFICULTIES = _C.PVP_DIFFICULTIES
local QUEST_DIFFICULTIES = _C.QUEST_DIFFICULTIES
local RAID_DIFFICULTIES = _C.RAID_DIFFICULTIES
local ROLES_NEEDED = _C.ROLES_NEEDED
local TYPE_COLORS = _C.TYPE_COLORS
local TYPE_ICONS = _C.TYPE_ICONS
local VOICE_OPTIONS = _C.VOICE_OPTIONS
local GetActivitiesForType = _C.GetActivitiesForType
local GetRelevantExpansions = _C.GetRelevantExpansions
local LPrint = _C.LPrint
local ageText = _C.ageText
local classColorText = _C.classColorText
local classIcon = _C.classIcon
local memberCount = _C.memberCount
local now = _C.now
local roleText = _C.roleText

local browseScrollFrame = nil


function Listings:ScrollBrowse(direction)
    if not browseScrollFrame then return end
    local range = self.browseScrollChild:GetHeight() - browseScrollFrame:GetHeight()
    if range <= 0 then return end
    local cur = browseScrollFrame:GetVerticalScroll()
    if direction == "UP" then
        browseScrollFrame:SetVerticalScroll(math.max(0, cur - 30))
    elseif direction == "DOWN" then
        browseScrollFrame:SetVerticalScroll(math.min(range, cur + 30))
    end
end

function Listings:Initialize(parentFrame)
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)

    local F = self.frame
    local pad = 14
    local curY = -10

    self.subTab = "browse"

    self.subTabs = {}
    local subTabDefs = {
        { id = "browse", name = L["tab_browse"] },
        { id = "create", name = L["tab_create_group"] },
        { id = "mylisting", name = L["tab_my_group"] },
        { id = "applications", name = L["tab_applications"] },
        { id = "profile", name = L["tab_profile"] },
    }

    for i, st in ipairs(subTabDefs) do
        local btn = CreateFrame("Button", nil, F)
        btn:SetSize(120, 26)
        btn:SetPoint("TOPLEFT", F, "TOPLEFT", pad + (i - 1) * 125, curY)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(_tc("bgButton")))

        btn.border = btn:CreateTexture(nil, "BORDER")
        btn.border:SetAllPoints()
        btn.border:SetColorTexture(unpack(_tc("border")))

        btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(st.name)
        btn.text:SetTextColor(unpack(_tc("textNorm")))

        btn.subId = st.id
        btn:SetScript("OnClick", function(self)
            Listings.subTab = self.subId
            Listings:RefreshSubTabs()
            Listings:RefreshContent()
        end)

        self.subTabs[st.id] = btn
    end
    curY = curY - 35

    self.content = CreateFrame("Frame", nil, F)
    self.content:SetPoint("TOPLEFT", F, "TOPLEFT", pad, curY)
    self.content:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -pad, pad)
    self:BuildBrowseFrame()
    self:BuildCreateFrame()
    self:BuildMyListingFrame()
    self:BuildApplicationsFrame()
    self.profileFrame = CreateFrame("Frame", nil, self.content)
    self.profileFrame:SetAllPoints(self.content)
    self.profileFrame:Hide()
    if FrostSeek.Profile and FrostSeek.Profile.Initialize then
        FrostSeek.Profile:Initialize(self.profileFrame)
    end

    self:RefreshSubTabs()
    self:RefreshContent()

    self.frame:Hide()
end

function Listings:RefreshSubTabs()
    for id, btn in pairs(self.subTabs) do
        if id == self.subTab then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.border:SetColorTexture(unpack(_tc("borderFocus")))
            btn.text:SetTextColor(unpack(_tc("textPrimary")))
        else
            btn.bg:SetColorTexture(unpack(_tc("bgButton")))
            btn.border:SetColorTexture(unpack(_tc("border")))
            btn.text:SetTextColor(unpack(_tc("textNorm")))
        end
    end
end

function Listings:RefreshContent()
    if self.browseFrame then self.browseFrame:SetShown(self.subTab == "browse") end
    if self.createFrame then self.createFrame:SetShown(self.subTab == "create") end
    if self.myListingFrame then self.myListingFrame:SetShown(self.subTab == "mylisting") end
    if self.applicationsFrame then self.applicationsFrame:SetShown(self.subTab == "applications") end
    if self.profileFrame then self.profileFrame:SetShown(self.subTab == "profile") end

    if self.subTab == "browse" then self:RefreshBrowse()
    elseif self.subTab == "mylisting" then self:RefreshMyListing()
    elseif self.subTab == "applications" then self:RefreshApplications()
    elseif self.subTab == "profile" then
        if FrostSeek.Profile and FrostSeek.Profile.Show then
            FrostSeek.Profile:Show()
        end
    end
end

function Listings:BuildBrowseFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.browseFrame = f

    local filters = {"All", "Dungeons", "Raids", "Keys", "Events", "Manastorm", "Quests"}
    self.filterButtons = {}
    for i, ft in ipairs(filters) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(65, 22)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", (i - 1) * 70, 0)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(unpack(_tc("bgBlock")))
        btn.text = btn:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(ft)
        btn.text:SetTextColor(unpack(_tc("textNorm")))
        btn.filterType = ft
        btn:SetScript("OnClick", function(self)
            Listings.filter = self.filterType
            if browseScrollFrame then browseScrollFrame:SetVerticalScroll(0) end
            Listings:RefreshFilterButtons()
            Listings:RefreshBrowse()
        end)
        self.filterButtons[ft] = btn
    end

    self.searchBox = UI and UI.CreateModernEditBox(f, 200, 20) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.searchBox:SetAutoFocus(false)
        self.searchBox:SetFontObject("FSKFontNormalSmall")
        self.searchBox:SetWidth(200)
        self.searchBox:SetHeight(20)
    end
    self.searchBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    self.searchBox:SetScript("OnTextChanged", function(self)
        Listings.searchText = self:GetText() or ""
        if browseScrollFrame then browseScrollFrame:SetVerticalScroll(0) end
        Listings:RefreshBrowse()
    end)

    self.browseCount = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.browseCount:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -24)
    self.browseCount:SetTextColor(unpack(_tc("textDim")))

    local browseListFrame = CreateFrame("Frame", nil, f)
    browseListFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -44)
    browseListFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 135)

    browseScrollFrame = CreateFrame("ScrollFrame", "FrostSeekBrowseScroll", browseListFrame, "UIPanelScrollFrameTemplate")
    browseScrollFrame:SetPoint("TOPLEFT", browseListFrame, "TOPLEFT", 0, 0)
    browseScrollFrame:SetPoint("BOTTOMRIGHT", browseListFrame, "BOTTOMRIGHT", 0, 0)

    local scrollChild = CreateFrame("Frame", nil, browseScrollFrame)
    scrollChild:SetSize(750, 200)
    browseScrollFrame:SetScrollChild(scrollChild)
    self.browseScrollChild = scrollChild

    self.browseRows = {}
    for i = 1, MAX_BROWSE_ROWS do
        local r = CreateFrame("Button", nil, scrollChild)
        r:SetWidth(750)
        r:SetHeight(28)
        if i == 1 then
            r:SetPoint("TOP", scrollChild, "TOP", 0, 0)
        else
            r:SetPoint("TOP", self.browseRows[i-1], "BOTTOM", 0, 2)
        end

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(20, 20)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)

        r.title = r:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
        r.title:SetPoint("LEFT", r, "LEFT", 28, 0)
        r.title:SetWidth(180)
        r.title:SetJustifyH("LEFT")

        r.leaderIcon = r:CreateTexture(nil, "ARTWORK")
        r.leaderIcon:SetSize(16, 16)
        r.leaderIcon:SetPoint("LEFT", r, "LEFT", 212, 0)
        r.leaderIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.leaderIcon:Hide()

        r.leader = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.leader:SetPoint("LEFT", r, "LEFT", 232, 0)
        r.leader:SetWidth(70)

        r.diff = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.diff:SetPoint("LEFT", r, "LEFT", 305, 0)
        r.diff:SetWidth(80)

        r.ilvl = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.ilvl:SetPoint("LEFT", r, "LEFT", 388, 0)
        r.ilvl:SetWidth(50)

        r.members = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.members:SetPoint("LEFT", r, "LEFT", 440, 0)
        r.members:SetWidth(55)

        r.roles = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.roles:SetPoint("LEFT", r, "LEFT", 497, 0)
        r.roles:SetWidth(80)
        r.roles:SetJustifyH("LEFT")

        r.note = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.note:SetPoint("LEFT", r, "LEFT", 579, 0)
        r.note:SetWidth(170)
        r.note:SetJustifyH("LEFT")

        r:SetScript("OnClick", function()
            if r.listingId then
                Listings.selectedListing = r.listingId
                Listings:RefreshBrowse()
            end
        end)
        r:SetScript("OnDoubleClick", function()
            if r.listingId then
                Listings.selectedListing = r.listingId
                Listings:Apply()
            end
        end)

        self.browseRows[i] = r
        r:Hide()
    end

    self.scrollIndicator = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.scrollIndicator:SetPoint("BOTTOM", f, "BOTTOM", 0, -12)
    self.scrollIndicator:SetText("")
    self.scrollIndicator:SetTextColor(unpack(_tc("textDim")))

    self.detailPanel = CreateFrame("Frame", nil, f)
    self.detailPanel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    self.detailPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    self.detailPanel:SetHeight(120)

    local dpBg = self.detailPanel:CreateTexture(nil, "BACKGROUND")
    dpBg:SetAllPoints()
    dpBg:SetColorTexture(unpack(_tc("bgBlock")))

    self.detailText = self.detailPanel:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.detailText:SetPoint("TOPLEFT", self.detailPanel, "TOPLEFT", 10, -8)
    self.detailText:SetPoint("TOPRIGHT", self.detailPanel, "TOPRIGHT", -10, -8)
    self.detailText:SetHeight(80)
    self.detailText:SetJustifyH("LEFT")
    self.detailText:SetJustifyV("TOP")
    self.detailText:SetText(_hex("textDim") .. L["listings_select_group_r"])

    self.applyBtn = UI and UI.CreateModernButton(self.detailPanel, 120, 26, L["listings_apply"]) or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.applyBtn:SetSize(120, 26)
        self.applyBtn:SetText(L["listings_apply"])
    end
    self.applyBtn:SetPoint("BOTTOMRIGHT", self.detailPanel, "BOTTOMRIGHT", -10, 8)
    self.applyBtn:SetScript("OnClick", function() Listings:Apply() end)
    self.applyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["listings_apply"], 0.8, 1, 0.8)
        local LFG = _G.FrostSeek and _G.FrostSeek.Modules and _G.FrostSeek.Modules.lfg
        local previewMsg
        if LFG and LFG.CreateWhisperMessage then
            previewMsg = LFG.CreateWhisperMessage() or ""
        end
        if previewMsg and previewMsg ~= "" then
            if #previewMsg > 200 then previewMsg = LFG.TruncateVisible and LFG.TruncateVisible(previewMsg, 200) or (string.sub(previewMsg, 1, 197) .. "...") end
            local isCustom = FrostSeekDB and FrostSeekDB.LFG and FrostSeekDB.LFG.customMessages and FrostSeekDB.LFG.customMessages.enabled
            local label = isCustom and (L["tip_preview_custom"] or "Preview (custom):") or (L["tip_preview_base"] or "Preview (base):")
            GameTooltip:AddLine(label, 0.7, 0.85, 1, true)
            GameTooltip:AddLine("|cff88ccff" .. previewMsg .. "|r", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    self.applyBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    self.whisperBtn = UI and UI.CreateModernButton(self.detailPanel, 90, 26, L["popup_whisper"]) or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.whisperBtn:SetSize(90, 26)
        self.whisperBtn:SetText(L["popup_whisper"])
    end
    self.whisperBtn:SetPoint("BOTTOMRIGHT", self.applyBtn, "BOTTOMLEFT", -8, 0)
    self.whisperBtn:SetScript("OnClick", function()
        local l = Listings.listings[Listings.selectedListing]
        if l and l.leader then
            if FrostSeekCompat and FrostSeekCompat.OpenChat then
                FrostSeekCompat.OpenChat("/w " .. l.leader .. " ")
            elseif ChatFrame_OpenChat then
                ChatFrame_OpenChat("/w " .. l.leader .. " ")
            end
        end
    end)


    self.frostnetBtn = UI and UI.CreateModernButton(self.detailPanel, 100, 26, L["frostnet_title"], _tc("accent")) or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.frostnetBtn:SetSize(100, 26)
        self.frostnetBtn:SetText(L["frostnet_title"])
    end
    self.frostnetBtn:SetPoint("BOTTOMLEFT", self.whisperBtn, "BOTTOMLEFT", -108, 0)
    self.frostnetBtn:SetScript("OnClick", function()
        if FrostSeek.Presence then
            FrostSeek.Presence:TogglePanel(FrostSeek.MainFrame)
        end
    end)

    self.joinVoiceBtn = UI and UI.CreateModernButton(self.detailPanel, 100, 26, L["voice_join"], _tc("accent")) or CreateFrame("Button", nil, self.detailPanel, "UIPanelButtonTemplate")
    if not UI then
        self.joinVoiceBtn:SetSize(100, 26)
        self.joinVoiceBtn:SetText("|cff88ccff" .. (L["voice_join"] or "Join Voice") .. "|r")
    end

    self.joinVoiceBtn:SetPoint("BOTTOMRIGHT", self.frostnetBtn, "BOTTOMLEFT", -8, 0)
    self.joinVoiceBtn:SetScript("OnClick", function()
        local VB = FrostSeek and FrostSeek.VoiceBridge
        if not VB then return end
        local l = Listings.listings[Listings.selectedListing]
        if not l then return end
        local decoded = VB.DecodeVoiceField(l.voice)
        if decoded and decoded.url then
            VB:Set(l.leader, decoded.url, true)
            VB:JoinVoice(l.leader)
        else
            VB:JoinVoice(l.leader)
        end
    end)
    self.joinVoiceBtn:Hide()

    self:RefreshFilterButtons()
end

function Listings:RefreshFilterButtons()
    for ft, btn in pairs(self.filterButtons) do
        if ft == self.filter then
            btn.bg:SetColorTexture(unpack(_tc("bgTabActive")))
            btn.text:SetTextColor(unpack(_tc("textPrimary")))
        else
            btn.bg:SetColorTexture(unpack(_tc("bgBlock")))
            btn.text:SetTextColor(unpack(_tc("textNorm")))
        end
    end
end

function Listings:RefreshBrowse()
    if not self.browseFrame then return end
    local list = self:GetVisibleListings()
    local totalFiltered = #list

    if self.browseCount then
        self.browseCount:SetText(string.format(L["listings_active_groups"], totalFiltered))
    end

    if self.scrollIndicator then
        self.scrollIndicator:SetText(tostring(totalFiltered) .. L["browse_groups_count_suffix"])
    end

    local scrollChild = self.browseScrollChild
    if scrollChild then
        scrollChild:SetHeight(math.max(200, totalFiltered * 30 + 4))
    end

    for i, row in ipairs(self.browseRows) do
        local l = list[i]
        if l then
            row:Show()
            row.listingId = l.id

            if l.id == self.selectedListing then
                row.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            else
                row.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))
            end

            local icon = TYPE_ICONS[l.type] or TYPE_ICONS.Dungeon
            row.icon:SetTexture(icon)
            row.title:SetText((TYPE_COLORS[l.type] or "|cffffffff") .. (l.activity or "?") .. "|r")

            if row.leaderIcon then
                local leaderName = tostring(l.leader or "")
                local cf = nil
                if leaderName ~= "" and FrostSeek.Presence and FrostSeek.Presence.onlineUsers then
                    local u = FrostSeek.Presence.onlineUsers[leaderName]
                    if u and u.classFile and u.classFile ~= "" then
                        cf = u.classFile
                    end
                end
                if cf then
                    row.leaderIcon:SetTexture(classIcon(cf))
                    row.leaderIcon:Show()
                else
                    row.leaderIcon:Hide()
                end
            end

            row.leader:SetText(tostring(l.leader or ""))
            row.diff:SetText(tostring(l.difficulty or ""))
            row.ilvl:SetText((l.minItemLevel and l.minItemLevel ~= "") and (l.minItemLevel .. "+") or "--")
            row.members:SetText(tostring(l.members or 1) .. "/" .. tostring(l.maxMembers or 5))
            if l.roles and l.roles ~= "" then
                local roleStr = ""
                for roleName in string.gmatch(l.roles, "[^/]+") do
                    roleStr = roleStr .. roleText(roleName) .. " "
                end
                row.roles:SetText(roleStr ~= "" and roleStr or "--")
            else
                row.roles:SetText(_hex("textDim") .. L["any_r"])
            end
            row.note:SetText(tostring(l.note or ""))
        else
            row:Hide()
            row.listingId = nil
            if row.leaderIcon then row.leaderIcon:Hide() end
        end
    end

    local sl = self.listings[self.selectedListing]
    if sl then
        local lines = {}
        table.insert(lines, (TYPE_COLORS[sl.type] or "|cffffffff") .. tostring(sl.activity) .. "|r  " .. tostring(sl.difficulty or ""))
        table.insert(lines, _hex("textDim") .. L["lbl_leader_r"] .. tostring(sl.leader or "?") .. "   " .. _hex("textDim") .. L["lbl_members_r"] .. tostring(sl.members or 1) .. "/" .. tostring(sl.maxMembers or 5))
        if sl.roles and sl.roles ~= "" then
            local detailRoles = ""
            for roleName in string.gmatch(sl.roles, "[^/]+") do
                detailRoles = detailRoles .. roleText(roleName) .. "  "
            end
            if detailRoles ~= "" then
                table.insert(lines, _hex("textDim") .. L["lbl_lf_r"] .. detailRoles)
            end
        end
        if sl.minItemLevel and sl.minItemLevel ~= "" then
            table.insert(lines, _hex("textDim") .. L["lbl_min_ilvl_r"] .. sl.minItemLevel .. "+")
        end
        if sl.voice and sl.voice ~= "None" then
            local VB = FrostSeek and FrostSeek.VoiceBridge
            local voiceDisplay = tostring(sl.voice)
            if VB then
                local decoded = VB.DecodeVoiceField(sl.voice)
                if decoded then
                    voiceDisplay = decoded.channel
                    if decoded.url then
                        VB:Set(sl.leader, decoded.url, true)
                    end
                end
            end
            table.insert(lines, _hex("textDim") .. L["lbl_voice_r"] .. voiceDisplay)
        end
        if sl.loot and sl.loot ~= "Group Loot" then
            table.insert(lines, _hex("textDim") .. L["lbl_loot_r"] .. tostring(sl.loot))
        end
        if sl.note and sl.note ~= "" then
            table.insert(lines, _hex("textDim") .. L["lbl_note_r"] .. tostring(sl.note))
        end
        table.insert(lines, _hex("textDim") .. L["lbl_published_r"] .. ageText(sl.created))
        self.detailText:SetText(table.concat(lines, "\n"))

        if self.joinVoiceBtn then
            local VB = FrostSeek and FrostSeek.VoiceBridge
            local hasVoiceLink = false
            if VB then
                local decoded = VB.DecodeVoiceField(sl.voice)
                if decoded and decoded.url then hasVoiceLink = true end
                if not hasVoiceLink and VB:Get(sl.leader) then hasVoiceLink = true end
            end
            self.joinVoiceBtn:SetShown(hasVoiceLink)
        end
    else
        self.detailText:SetText(_hex("textDim") .. L["listings_select_group_r"])
        if self.joinVoiceBtn then self.joinVoiceBtn:Hide() end
    end
end

local MAX_APP_ROWS = 10

function Listings:BuildApplicationsFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.applicationsFrame = f

    local title = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    title:SetText("|cff88ccff" .. L["listings_my_applications"] .. "|r")

    self.appCount = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    self.appCount:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -4)
    self.appCount:SetTextColor(unpack(_tc("textDim")))

    local header = CreateFrame("Frame", nil, f)
    header:SetWidth(750)
    header:SetHeight(22)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -30)
    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetColorTexture(unpack(_tc("bgBlock")))

    local hLabels = {{L["col_activity"], 4}, {L["col_type"], 200}, {L["col_leader"], 280}, {L["col_key"], 360}, {L["col_status"], 460}, {L["col_applied"], 550}, {L["col_decided"], 630}}
    for _, lbl in ipairs(hLabels) do
        local t = header:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        t:SetPoint("LEFT", header, "LEFT", lbl[2], 0)
        t:SetText(_hex("textDim") .. lbl[1] .. "|r")
    end

    self.appRows = {}
    for i = 1, MAX_APP_ROWS do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(750)
        r:SetHeight(26)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -54 - ((i - 1) * 28))

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))

        r.activity = r:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
        r.activity:SetPoint("LEFT", r, "LEFT", 4, 0)
        r.activity:SetWidth(192)
        r.activity:SetJustifyH("LEFT")

        r.type = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.type:SetPoint("LEFT", r, "LEFT", 200, 0)
        r.type:SetWidth(78)

        r.leader = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.leader:SetPoint("LEFT", r, "LEFT", 280, 0)
        r.leader:SetWidth(78)

        r.key = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.key:SetPoint("LEFT", r, "LEFT", 360, 0)
        r.key:SetWidth(98)
        r.key:SetJustifyH("LEFT")

        r.status = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.status:SetPoint("LEFT", r, "LEFT", 460, 0)
        r.status:SetWidth(88)

        r.applied = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.applied:SetPoint("LEFT", r, "LEFT", 550, 0)
        r.applied:SetWidth(78)

        r.decided = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.decided:SetPoint("LEFT", r, "LEFT", 630, 0)
        r.decided:SetWidth(78)

        r:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(unpack(_tc("bgRowHover")))
        end)
        r:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))
        end)

        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.appData and self.appData.status == "pending" then
                Listings:WithdrawApplication(self.appData.id)
            end
        end)

        self.appRows[i] = r
        r:Hide()
    end

    self.clearAppsBtn = UI and UI.CreateModernButton(f, 140, 24, L["listings_clear_history"], _tc("catPvP")) or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    if not UI then
        self.clearAppsBtn:SetSize(140, 24)
        self.clearAppsBtn:SetText(L["listings_clear_history"])
    end
    self.clearAppsBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    self.clearAppsBtn:SetScript("OnClick", function()
        local function doClear()
            for id, app in pairs(Listings.myApplications) do
                if app.status ~= "pending" then
                    Listings.myApplications[id] = nil
                end
            end
            Listings:RefreshApplications()
        end
        if Shared and Shared.ConfirmDialog then
            Shared.ConfirmDialog(L["listings_clear_history"], L["listings_clear_history_confirm"], doClear)
        else
            doClear()
        end
    end)

    local hint = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", self.clearAppsBtn, "BOTTOMRIGHT", 12, 4)
    hint:SetText(_hex("textDim") .. L["hint_withdraw_app"])

    f:Hide()
end

function Listings:RefreshApplications()
    if not self.applicationsFrame then return end

    local apps = {}
    for id, app in pairs(self.myApplications) do
        table.insert(apps, app)
    end
    table.sort(apps, function(a, b)
        return (a.appliedAt or 0) > (b.appliedAt or 0)
    end)

    local pending = 0
    for _, app in ipairs(apps) do
        if app.status == "pending" then pending = pending + 1 end
    end
    if self.appCount then
        self.appCount:SetText(string.format(L["listings_total_pending"], #apps, pending))
    end

    for i, row in ipairs(self.appRows) do
        local app = apps[i]
        if app then
            row:Show()
            row.appData = app

            local typeColor = TYPE_COLORS[app.type] or "|cffffffff"
            row.activity:SetText(typeColor .. (app.activity or "?") .. "|r")
            row.type:SetText(tostring(app.type or ""))
            row.leader:SetText(tostring(app.leader or ""))

            if app.key and app.key ~= "" then
                row.key:SetText("|cffb866ff" .. tostring(app.key) .. "|r")
            else
                row.key:SetText(_hex("textDim") .. "--|r")
            end

            local statusText = app.status or "pending"
            if statusText == "pending" then
                row.status:SetText(L["app_pending_col"])
            elseif statusText == "accepted" then
                row.status:SetText(L["app_accepted_col"])
            elseif statusText == "declined" then
                row.status:SetText(L["app_declined_col"])
            elseif statusText == "withdrawn" then
                row.status:SetText(L["app_withdrawn_col"])
            elseif statusText == "expired" then
                row.status:SetText(L["app_expired_col"])
            else
                row.status:SetText(tostring(statusText))
            end

            if app.appliedAt then
                row.applied:SetText(ageText(app.appliedAt))
            else
                row.applied:SetText("--")
            end

            if app.decidedAt then
                row.decided:SetText(ageText(app.decidedAt))
            else
                row.decided:SetText(_hex("textDim") .. "--|r")
            end
        else
            row:Hide()
            row.appData = nil
        end
    end
end
--shynga
function Listings:WithdrawApplication(id)
    if not id or not self.myApplications[id] then return end
    self.myApplications[id].status = "withdrawn"
    self.myApplications[id].decidedAt = time()
    LPrint("net_app_withdrawn", tostring(self.myApplications[id].activity))
    self:RefreshApplications()
end

function Listings:BuildCreateFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.createFrame = f

    local curY = -5
    local leftPad = 10
    local labelW = 120
    local inputW = 250
    local rowH = 32

    local tLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    tLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    tLabel:SetText(_hex("accent") .. L["label_type"] .. "|r")

    self.createType = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createType:SetSize(200, 24)
    end
    self.createType:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createType.SetOptions then
        self.createType:SetOptions(ACTIVITY_TYPES)
        self.createType:SetText("Dungeon")
    end
    curY = curY - rowH

    local eLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    eLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    eLabel:SetText(_hex("accent") .. L["label_expansion"] .. "|r")

    self.createExpansion = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createExpansion:SetSize(200, 24)
    end
    self.createExpansion:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createExpansion.SetOptions then
        local exps = GetRelevantExpansions()
        self.createExpansion:SetOptions(exps)
        self.createExpansion:SetText(exps[1] or "Classic")
    end
    curY = curY - rowH

    local aLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    aLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    aLabel:SetText(_hex("accent") .. L["label_activity"] .. "|r")

    self.createActivity = UI and UI.CreateModernDropdown(f, inputW, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createActivity:SetSize(inputW, 24)
    end
    self.createActivity:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    local initialActs = GetActivitiesForType("Classic", "Dungeon")
    if self.createActivity.SetOptions then
        self.createActivity:SetOptions(initialActs)
        if #initialActs > 0 then self.createActivity:SetText(initialActs[1]) end
    end

    self.createActivityEdit = nil
    curY = curY - rowH

    local dLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    dLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    dLabel:SetText(_hex("accent") .. L["label_difficulty"] .. "|r")

    self.createDiff = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createDiff:SetSize(200, 24)
    end
    self.createDiff:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createDiff.SetOptions then
        self.createDiff:SetOptions(DIFFICULTIES)
        self.createDiff:SetText("Normal")
    end
    curY = curY - rowH

    local kLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    kLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    kLabel:SetText(_hex("accent") .. L["label_key_level"] .. "|r")
    self.createKeyLevelLabel = kLabel

    self.createKeyLevel = UI and UI.CreateModernEditBox(f, 60, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createKeyLevel:SetAutoFocus(false)
        self.createKeyLevel:SetFontObject("FSKFontNormalSmall")
        self.createKeyLevel:SetWidth(60)
        self.createKeyLevel:SetHeight(24)
    end
    self.createKeyLevel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createKeyLevel:SetText("")
    self.createKeyLevel:SetNumeric(true)
    self.createKeyLevel:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.createKeyLevel:Hide()
    kLabel:Hide()
    curY = curY - rowH

    local rLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    rLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    rLabel:SetText(_hex("accent") .. L["label_roles_needed"] .. "|r")

    self.createRoles = { Tank = false, Healer = false, DPS = false, Support = false }
    self.createRoleToggles = {}
    local roleColors = { Tank = _tc("catDungeon"), Healer = _tc("success"), DPS = _tc("danger"), Support = {0.70, 0.40, 1.00} }
    local roleLabels = { Tank = "Tank", Healer = "Healer", DPS = "DPS", Support = "Support" }

    for i, role in ipairs(ROLES_NEEDED) do
        local toggle
        if UI and UI.CreateSmallToggle then
            toggle = UI.CreateSmallToggle(f, roleLabels[role], (i - 1) * 95, 0, 80, 22, function(active)
                Listings.createRoles[role] = active
            end)
        else
            toggle = CreateFrame("Button", nil, f)
            toggle:SetSize(80, 22)
            toggle:SetPoint("LEFT", f, "LEFT", leftPad + labelW + (i - 1) * 95, 0)
            toggle.bg = toggle:CreateTexture(nil, "BACKGROUND")
            toggle.bg:SetAllPoints()
            toggle.bg:SetColorTexture(0.1, 0.1, 0.12, 0.4)
            toggle.text = toggle:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
            toggle.text:SetPoint("CENTER")
            toggle.text:SetText(roleLabels[role])
            toggle.text:SetTextColor(0.7, 0.7, 0.7)
            toggle.active = false
            toggle:SetScript("OnClick", function(self)
                self.active = not self.active
                self.text:SetTextColor(self.active and 0.4 or 0.7, self.active and 1 or 0.7, self.active and 0.4 or 0.7)
                Listings.createRoles[role] = self.active
            end)
        end
        if toggle.ClearAllPoints then
            toggle:ClearAllPoints()
            toggle:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW + (i - 1) * 95, curY + 4)
        end
        self.createRoleToggles[role] = toggle
    end
    curY = curY - rowH

    local mLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    mLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    mLabel:SetText(_hex("accent") .. L["label_max_members"] .. "|r")

    self.createMaxMembers = UI and UI.CreateModernEditBox(f, 60, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createMaxMembers:SetAutoFocus(false)
        self.createMaxMembers:SetFontObject("FSKFontNormalSmall")
        self.createMaxMembers:SetWidth(60)
        self.createMaxMembers:SetHeight(24)
    end
    self.createMaxMembers:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createMaxMembers:SetText("5")
    self.createMaxMembers:SetNumeric(true)
    self.createMaxMembers:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - rowH

    local iLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    iLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    iLabel:SetText(_hex("accent") .. L["label_min_ilvl"] .. "|r")

    self.createMinIlvl = UI and UI.CreateModernEditBox(f, 80, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createMinIlvl:SetAutoFocus(false)
        self.createMinIlvl:SetFontObject("FSKFontNormalSmall")
        self.createMinIlvl:SetWidth(80)
        self.createMinIlvl:SetHeight(24)
    end
    self.createMinIlvl:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createMinIlvl:SetText("")
    self.createMinIlvl:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - rowH

    local vLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    vLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    vLabel:SetText(_hex("accent") .. L["label_voice_chat"] .. "|r")

    self.createVoice = UI and UI.CreateModernDropdown(f, 150, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createVoice:SetSize(150, 24)
    end
    self.createVoice:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createVoice.SetOptions then
        self.createVoice:SetOptions(VOICE_OPTIONS)
        self.createVoice:SetText(L["none"])
    end

    local vHint = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
    vHint:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW + 160, curY + 4)
    vHint:SetText(_hex("textDim") .. L["hint_discord_profile"])
    vHint:SetWidth(400)
    vHint:SetJustifyH("LEFT")
    self.createVoiceHint = vHint

    curY = curY - rowH

    local lLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    lLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    lLabel:SetText(_hex("accent") .. L["label_loot_method"] .. "|r")

    self.createLoot = UI and UI.CreateModernDropdown(f, 200, 24) or CreateFrame("Frame", nil, f)
    if not UI then
        self.createLoot:SetSize(200, 24)
    end
    self.createLoot:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    if self.createLoot.SetOptions then
        self.createLoot:SetOptions(LOOT_OPTIONS)
        self.createLoot:SetText(L["create_loot_group"])
    end
    curY = curY - rowH

    local nLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    nLabel:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad, curY)
    nLabel:SetText(_hex("accent") .. L["label_note"] .. "|r")

    self.createNote = UI and UI.CreateModernEditBox(f, 400, 24) or CreateFrame("EditBox", nil, f)
    if not UI then
        self.createNote:SetAutoFocus(false)
        self.createNote:SetFontObject("FSKFontNormalSmall")
        self.createNote:SetWidth(400)
        self.createNote:SetHeight(24)
    end
    self.createNote:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createNote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    curY = curY - rowH - 10

    self.createBtn = UI and UI.CreateModernButton(f, 160, 30, L["listings_publish_group"]) or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    if not UI then
        self.createBtn:SetSize(160, 30)
        self.createBtn:SetText("|cff44ff44" .. L["listings_publish_group"] .. "|r")
    end
    self.createBtn:SetPoint("TOPLEFT", f, "TOPLEFT", leftPad + labelW, curY)
    self.createBtn:SetScript("OnClick", function()
        Listings:SubmitCreate()
    end)

    self.createType.onChange = function(selected)
        local ltype = selected or "Dungeon"

        if Listings.createExpansion then
            if ltype == "PvP" or ltype == "Manastorm" then
                Listings.createExpansion:SetAlpha(0.4)
                Listings.createExpansion.button:Disable()
            elseif ltype == "Event" then
                Listings.createExpansion:SetAlpha(1.0)
                Listings.createExpansion.button:Enable()
                if Listings.createExpansion.SetOptions then
                    local exps = GetRelevantExpansions()
                    Listings.createExpansion:SetOptions(exps)
                    Listings.createExpansion:SetText(exps[1] or "Classic")
                end
            else
                Listings.createExpansion:SetAlpha(1.0)
                Listings.createExpansion.button:Enable()
                if Listings.createExpansion.SetOptions then
                    local exps = GetRelevantExpansions()
                    Listings.createExpansion:SetOptions(exps)
                    Listings.createExpansion:SetText(exps[1] or "Classic")
                end
            end
        end

        local expansion = Listings.createExpansion and Listings.createExpansion.GetText and Listings.createExpansion:GetText() or "Classic"
        local acts = GetActivitiesForType(expansion, ltype)
        if Listings.createActivity and Listings.createActivity.SetOptions then
            Listings.createActivity:SetOptions(acts)
            if #acts > 0 then Listings.createActivity:SetText(acts[1]) end
        end

        if Listings.createDiff and Listings.createDiff.SetOptions then
            if ltype == "Key" then
                Listings.createDiff:SetOptions(KEY_DIFFICULTIES)
                Listings.createDiff:SetText("Mythic+")
            elseif ltype == "Raid" then
                Listings.createDiff:SetOptions(RAID_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "World Boss" then
                Listings.createDiff:SetOptions(BOSS_DIFFICULTIES)
                Listings.createDiff:SetText("Open World")
            elseif ltype == "PvP" then
                Listings.createDiff:SetOptions(PVP_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "Event" then
                Listings.createDiff:SetOptions(EVENT_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "Manastorm" then
                Listings.createDiff:SetOptions(MANASTORM_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            elseif ltype == "Quest" then
                Listings.createDiff:SetOptions(QUEST_DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            else
                Listings.createDiff:SetOptions(DIFFICULTIES)
                Listings.createDiff:SetText("Normal")
            end
        end

        if ltype == "Key" then
            if Listings.createKeyLevel then Listings.createKeyLevel:Show() end
            if Listings.createKeyLevelLabel then Listings.createKeyLevelLabel:Show() end
        else
            if Listings.createKeyLevel then Listings.createKeyLevel:Hide() end
            if Listings.createKeyLevelLabel then Listings.createKeyLevelLabel:Hide() end
        end
    end

    self.createExpansion.onChange = function(selected)
        local ltype = Listings.createType and Listings.createType.GetText and Listings.createType:GetText() or "Dungeon"
        local acts = GetActivitiesForType(selected, ltype)
        if Listings.createActivity and Listings.createActivity.SetOptions then
            Listings.createActivity:SetOptions(acts)
            if #acts > 0 then Listings.createActivity:SetText(acts[1]) end
        end
    end

    f:Hide()
end

function Listings:SubmitCreate()
    local activity = self.createActivity and self.createActivity.GetText and self.createActivity:GetText() or ""
    if activity == "" then
        print("|cff88ccffFrostNet:|r " .. (L["net_select_activity"] or "Select an activity!"))
        return
    end

    local ltype = self.createType and self.createType.GetText and self.createType:GetText() or "Dungeon"
    local diff = self.createDiff and self.createDiff.GetText and self.createDiff:GetText() or "Normal"
    local keyLvl = self.createKeyLevel and self.createKeyLevel.GetText and self.createKeyLevel:GetText() or ""

    if ltype == "Key" and keyLvl ~= "" then
        diff = "Mythic+ " .. tostring(keyLvl)
    end
    local maxM = self.createMaxMembers and tonumber(self.createMaxMembers:GetText()) or 5
    local minIlvl = self.createMinIlvl and self.createMinIlvl:GetText() or ""
    local voiceChannel = self.createVoice and self.createVoice.GetText and self.createVoice:GetText() or "None"
    local note = self.createNote and self.createNote:GetText() or ""
    local keyData = ltype == "Key" and keyLvl or ""
    local loot = self.createLoot and self.createLoot.GetText and self.createLoot:GetText() or "Group Loot"

    local pn = UnitName("player") or ""
    local VB = FrostSeek and FrostSeek.VoiceBridge
    local voice = voiceChannel
    if VB and pn ~= "" then
        voice = VB.EncodeVoiceField(voiceChannel, pn)
    end

    local rolesList = {}
    if self.createRoles then
        for role, active in pairs(self.createRoles) do
            if active then table.insert(rolesList, role) end
        end
    end
    local rolesStr = table.concat(rolesList, "/")

    self:CreateListing(activity, ltype, diff, rolesStr, minIlvl, maxM, voice, loot, note, keyData)

    self.subTab = "mylisting"
    self:RefreshSubTabs()
    self:RefreshContent()
end

function Listings:BuildMyListingFrame()
    local F = self.content
    local f = CreateFrame("Frame", nil, F)
    f:SetAllPoints(F)
    self.myListingFrame = f
    self.myListingInfo = f:CreateFontString(nil, "OVERLAY", "FSKFontNormal")
    self.myListingInfo:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
    self.myListingInfo:SetWidth(740)
    self.myListingInfo:SetHeight(100)
    self.myListingInfo:SetJustifyH("LEFT")
    self.myListingInfo:SetJustifyV("TOP")
    self.applicantsLabel = f:CreateFontString(nil, "OVERLAY", "FSKFontNormalLarge")
    self.applicantsLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -120)
    self.applicantsLabel:SetText(L["txt_applicants_colored"])
    self.applicantRows = {}
    for i = 1, 8 do
        local r = CreateFrame("Button", nil, f)
        r:SetWidth(750)
        r:SetHeight(26)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -145 - ((i - 1) * 28))

        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", r, "LEFT", 4, 0)

        r.name = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.name:SetPoint("LEFT", r, "LEFT", 26, 0)
        r.name:SetWidth(100)

        r.class = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.class:SetPoint("LEFT", r, "LEFT", 130, 0)
        r.class:SetWidth(70)

        r.role = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.role:SetPoint("LEFT", r, "LEFT", 205, 0)
        r.role:SetWidth(50)

        r.ilvl = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.ilvl:SetPoint("LEFT", r, "LEFT", 260, 0)
        r.ilvl:SetWidth(50)

        r.note = r:CreateFontString(nil, "OVERLAY", "FSKFontNormalSmall")
        r.note:SetPoint("LEFT", r, "LEFT", 315, 0)
        r.note:SetWidth(255)
        r.note:SetJustifyH("LEFT")

        r.acceptBtn = UI and UI.CreateModernButton(r, 55, 20, L["listings_accept"]) or CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        if not UI then
            r.acceptBtn:SetSize(55, 20)
            r.acceptBtn:SetText(L["listings_accept"])
        end
        r.acceptBtn:SetPoint("RIGHT", r, "RIGHT", -62, 0)
        r.acceptBtn:SetScript("OnClick", function()
            if r.applicantName then Listings:AcceptApplicant(r.applicantName) end
        end)

        r.declineBtn = UI and UI.CreateModernButton(r, 55, 20, L["no"]) or CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        if not UI then
            r.declineBtn:SetSize(55, 20)
            r.declineBtn:SetText(L["no"])
        end
        r.declineBtn:SetPoint("RIGHT", r, "RIGHT", -4, 0)
        r.declineBtn:SetScript("OnClick", function()
            if r.applicantName then Listings:DeclineApplicant(r.applicantName) end
        end)

        self.applicantRows[i] = r
        r:Hide()
    end

    self.cancelBtn = UI and UI.CreateModernButton(f, 140, 28, L["listings_remove_listing"]) or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    if not UI then
        self.cancelBtn:SetSize(140, 28)
        self.cancelBtn:SetText("|cffff5555" .. L["listings_remove_listing"] .. "|r")
    end
    self.cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    self.cancelBtn:SetScript("OnClick", function() Listings:CancelListing("manual") end)

    f:Hide()
end

function Listings:RefreshMyListing()
    if not self.myListingFrame then return end

    if not self.myListing then
        self.myListingInfo:SetText(_hex("textDim") .. L["listings_no_active_group_full"])
        if self.applicantsLabel then self.applicantsLabel:Hide() end
        for _, r in ipairs(self.applicantRows or {}) do r:Hide() end
        if self.cancelBtn then self.cancelBtn:Hide() end
        return
    end

    if self.cancelBtn then self.cancelBtn:Show() end
    if self.applicantsLabel then self.applicantsLabel:Show() end

    local l = self.myListing
    local lines = {}
    table.insert(lines, (TYPE_COLORS[l.type] or "|cffffffff") .. tostring(l.activity) .. "|r  " .. tostring(l.difficulty or ""))
    table.insert(lines, _hex("textDim") .. L["lbl_leader_r"] .. tostring(l.leader) .. "   " .. _hex("textDim") .. L["lbl_members_r"] .. tostring(memberCount()) .. "/" .. tostring(l.maxMembers or 5))
    if l.roles and l.roles ~= "" then
        local myRoles = ""
        for roleName in string.gmatch(l.roles, "[^/]+") do
            myRoles = myRoles .. roleText(roleName) .. "  "
        end
        if myRoles ~= "" then
            table.insert(lines, _hex("textDim") .. L["lbl_lf_r"] .. myRoles)
        end
    end
    if l.minItemLevel and l.minItemLevel ~= "" then
        table.insert(lines, _hex("textDim") .. L["lbl_min_ilvl_r"] .. l.minItemLevel .. "+")
    end
    if l.voice and l.voice ~= "None" then
        local voiceDisplay = tostring(l.voice)
        local VB = FrostSeek and FrostSeek.VoiceBridge
        if VB and VB.DecodeVoiceField then
            local decoded = VB.DecodeVoiceField(l.voice)
            if decoded and decoded.channel then
                voiceDisplay = decoded.channel
            end
        end
        table.insert(lines, _hex("textDim") .. L["lbl_voice_r"] .. voiceDisplay)
    end
    if l.note and l.note ~= "" then
        table.insert(lines, _hex("textDim") .. L["lbl_note_r"] .. l.note)
    end
    self.myListingInfo:SetText(table.concat(lines, "\n"))

    self:RefreshApplicants()
end

function Listings:UpdateApplicantBadge()
    if not FrostSeek.Tabs or not FrostSeek.Tabs.listings or not FrostSeek.Tabs.listings.badge then
        return
    end
    local badge = FrostSeek.Tabs.listings.badge
    local count = 0
    if self.applicants then
        for _ in pairs(self.applicants) do count = count + 1 end
    end
    if count == 0 or FrostSeek.ActiveTab == "listings" then
        badge:Hide()
        badge:SetText("")
    else
        badge:SetText(tostring(count))
        badge:Show()
    end
end

function Listings:RefreshApplicants()
    if not self.applicantRows then return end

    local apps = {}
    for _, a in pairs(self.applicants) do
        table.insert(apps, a)
    end
    table.sort(apps, function(a, b) return (a.applied or 0) < (b.applied or 0) end)

    for i, row in ipairs(self.applicantRows) do
        local a = apps[i]
        if a then
            row:Show()
            row.applicantName = a.name

            if a.name == self.selectedApplicant then
                row.bg:SetColorTexture(unpack(_tc("bgRowHover")))
            else
                row.bg:SetColorTexture(unpack(_tc(i % 2 == 0 and "bgRowEven" or "bgRowOdd")))
            end

            row.icon:SetTexture(classIcon(a.classFile))
            row.name:SetText(classColorText(a.name, a.classFile))
            row.class:SetText(tostring(a.class or ""))
            row.role:SetText(roleText(a.role))
            row.ilvl:SetText((a.itemLevel and a.itemLevel ~= "" and a.itemLevel ~= "0") and (a.itemLevel .. " ilvl") or "--")
            row.note:SetText(tostring(a.note or ""))
        else
            row:Hide()
            row.applicantName = nil
        end
    end

    if self.applicantsLabel then
        self.applicantsLabel:SetText(L["txt_applicants_count_colored"] .. tostring(#apps) .. ")")
    end
end

function Listings:Show()
    if self.frame then self.frame:Show() end
    self:RefreshContent()
end

function Listings:Hide()
    if self.frame then self.frame:Hide() end
end

C_Timer.NewTicker(20, function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    if Listings.myListing then
        Listings:CheckAutoClose()
        Listings:BroadcastMyListing()
    end
    for id, l in pairs(Listings.listings) do
        if l.seen and now() - l.seen > LISTING_EXPIRE then
            Listings.listings[id] = nil
        end
    end
    local expired = false
    for id, app in pairs(Listings.myApplications) do
        if app.status == "pending" and app.appliedAt and (now() - app.appliedAt) > APP_PENDING_EXPIRE then
            app.status = "expired"
            app.decidedAt = time()
            expired = true
        end
    end
    if expired and Listings.frame and Listings.frame:IsShown() then
        Listings:RefreshApplications()
    end
end)

local rosterFrame = CreateFrame("Frame")
pcall(function() rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE") end)
rosterFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
rosterFrame:RegisterEvent("RAID_ROSTER_UPDATE")
rosterFrame:SetScript("OnEvent", function()
    if not FrostSeek or not FrostSeek._v or not FrostSeek._v.c(_tk) then return end
    if Listings.myListing then
        Listings:CheckAutoClose()
        Listings:BroadcastMyListing()
    end
end)

