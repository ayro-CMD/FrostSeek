-- ============================================================
-- FrostSeek - Compatibility Layer
-- ============================================================

local MAJOR, MINOR = "FrostSeekCompat", 1
if LibStub and LibStub:GetLibrary(MAJOR, true) then return end

-- ==================== C_Timer Polyfill ====================

if not C_Timer then
    C_Timer = {}

    local timerFrame = CreateFrame("Frame", "FrostSeek_TimerFrame")
    timerFrame:SetScript("OnUpdate", nil)
    local activeTimers = {}

    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        local i = 1
        while i <= #activeTimers do
            local timer = activeTimers[i]
            if not timer then
                table.remove(activeTimers, i)
            elseif timer.finished then
                table.remove(activeTimers, i)
            elseif timer.cancelled then
                table.remove(activeTimers, i)
            else
                if now >= timer.expiry then
                    timer.finished = true
                    table.remove(activeTimers, i)
                    if timer.callback then
                        timer.callback()
                    end
                else
                    i = i + 1
                end
            end
        end

        if #activeTimers == 0 then
            self:SetScript("OnUpdate", nil)
        end
    end)

    local function ensureTickerFrame()
        if not timerFrame:GetScript("OnUpdate") then
            timerFrame:SetScript("OnUpdate", timerFrame.OnUpdate)
        end
    end

    function C_Timer.After(delay, callback)
        local timer = {
            expiry = GetTime() + (delay or 0),
            callback = callback,
            type = "after"
        }
        table.insert(activeTimers, timer)
        ensureTickerFrame()
        return timer
    end

    function C_Timer.NewTicker(interval, callback, iterations)
        local timer = {
            interval = interval or 1,
            callback = callback,
            iterations = iterations,
            elapsed = 0,
            type = "ticker",
            cancelled = false
        }

        local tickerFrame = CreateFrame("Frame")
        tickerFrame:Hide()

        tickerFrame:SetScript("OnUpdate", function(self, elapsed)
            if timer.cancelled then
                self:Hide()
                return
            end

            timer.elapsed = timer.elapsed + elapsed
            if timer.elapsed >= timer.interval then
                timer.elapsed = timer.elapsed - timer.interval

                if timer.callback then
                    timer.callback()
                end

                if timer.iterations then
                    timer.iterations = timer.iterations - 1
                    if timer.iterations <= 0 then
                        timer.cancelled = true
                        self:Hide()
                    end
                end
            end
        end)

        tickerFrame:Show()

        
        return {
            Cancel = function()
                timer.cancelled = true
                tickerFrame:Hide()
            end,
            _timer = timer,
            _frame = tickerFrame
        }
    end
end

-- ==================== Texture:SetColorTexture Polyfill ====================
local textureMt = getmetatable(CreateFrame("Frame"):CreateTexture())
if textureMt and not textureMt.__index.SetColorTexture then
    textureMt.__index.SetColorTexture = function(self, r, g, b, a)
        self:SetTexture(r, g, b, a)
    end
end

-- ==================== Region:SetShown Polyfill ====================
local regionMt = getmetatable(CreateFrame("Frame"))
if regionMt and not regionMt.__index.SetShown then
    regionMt.__index.SetShown = function(self, shown)
        if shown then
            self:Show()
        else
            self:Hide()
        end
    end
end

FrostSeekCompat = FrostSeekCompat or {}
FrostSeekCompat.hasBackdropTemplate = false


do
    local testOk, testErr = pcall(function()
        local testFrame = CreateFrame("Frame", "FrostSeek_CompatTest", UIParent, "BackdropTemplate")
        testFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16 })
        FrostSeekCompat.hasBackdropTemplate = true
        testFrame:Hide()
        -- Remove from global
        _G["FrostSeek_CompatTest"] = nil
    end)
end

-- Utility
function FrostSeekCompat.GetBackdropTemplateStr()
    if FrostSeekCompat.hasBackdropTemplate then
        return "BackdropTemplate"
    end
    return ""
end

-- Print compatibility
local compatFrame = CreateFrame("Frame")
compatFrame:RegisterEvent("ADDON_LOADED")
compatFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "FrostSeek" then return end
    self:UnregisterEvent("ADDON_LOADED")

    print("|cff88ccffFrostSeek Compat:|r " ..
        (FrostSeekCompat.hasBackdropTemplate and "|cff00ff00BackdropTemplate: YES|r" or "|cffff8800BackdropTemplate: NO (native fallback)|r") ..
        " | " ..
        (C_Timer and "|cff00ff00C_Timer: OK|r" or "|cffff0000C_Timer: MISSING|r") ..
        " | " ..
        "|cff00ff00Compat layer loaded|r"
    )
end)