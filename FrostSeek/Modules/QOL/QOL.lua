-- ============================================================
-- FrostSeek - Quality of Life Module
-- ============================================================

local FrostSeek = _G.FrostSeek

local QOL = {}

-- ==================== VARIABILI LOCALI ====================
local merchantFrame = nil

-- ==================== FUNZIONI HELPER ====================
local function ShouldProcess()
    return not UnitAffectingCombat("player")
end

-- ==================== AUTO VENDOR & REPAIR ====================
local function SetupMerchantFrame()
    merchantFrame = CreateFrame("Frame")
    merchantFrame:RegisterEvent("MERCHANT_SHOW")
    merchantFrame:SetScript("OnEvent", function()
        if not ShouldProcess() then return end
        
        C_Timer.After(0.5, function()
            -- Vendi oggetti grigi
            if FrostSeekDB.QOL and FrostSeekDB.QOL.autoSellGreys then
                local totalSold = 0
                for bag = 0, 4 do
                    for slot = 1, GetContainerNumSlots(bag) do
                        local itemLink = GetContainerItemLink(bag, slot)
                        if itemLink then
                            local _, _, quality = GetItemInfo(itemLink)
                            if quality == 0 then -- Grigio
                                UseContainerItem(bag, slot)
                                totalSold = totalSold + 1
                            end
                        end
                    end
                end
                if totalSold > 0 then
                    print("|cff88ccff[QOL]|r Venduti " .. totalSold .. " oggetti grigi")
                end
            end
            
            -- Ripara equipaggiamento
            if FrostSeekDB.QOL and FrostSeekDB.QOL.autoRepair then
                local repairCost = GetRepairAllCost()
                if repairCost > 0 then
                    if FrostSeekDB.QOL.useGuildRepair and CanGuildBankRepair() then
                        RepairAllItems(true)
                        print("")
                    else
                        RepairAllItems()
                        print("")
                    end
                end
            end
        end)
    end)
end

-- ==================== MODULO INIZIALIZZAZIONE ====================
function QOL:Initialize(parentFrame)
    print("")
    
    self.frame = CreateFrame("Frame", nil, parentFrame)
    self.frame:SetAllPoints(parentFrame)
    self.frame:Hide()
    
    SetupMerchantFrame()
    
    print("")
end

function QOL:Show() end
function QOL:Hide() end

-- ==================== MODULE REGISTRATION ====================
local function RegisterQOLModule()
    if not _G.FrostSeek then
        C_Timer.After(0.5, RegisterQOLModule)
        return
    end
    
    if not FrostSeekDB.QOL then
        FrostSeekDB.QOL = {
            autoSellGreys = false,
            autoRepair = false,
            useGuildRepair = false,
        }
    end
    
    if _G.FrostSeek.RegisterModule then
        _G.FrostSeek:RegisterModule("qol", QOL)
        print("")
    end
end

RegisterQOLModule()