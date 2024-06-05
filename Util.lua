local addonName = ... ---@type string

---@class BuffOverlay: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Util: AceModule
local util = addon:NewModule('Util')

-- Need a local version of Blizzard's AuraUtil.ForEachAura due to it not existing on classic flavors.
local function ForEachAuraHelper(unit, filter, func, usePackedAura, continuationToken, ...)
    -- continuationToken is the first return value of UnitAuraSlots()
    local n = select('#', ...)
    for i = 1, n do
        local slot = select(i, ...)
        local done
        local auraInfo = C_UnitAuras.GetAuraDataBySlot(unit, slot)
        if usePackedAura then
            done = func(auraInfo)
        else
            done = func(AuraUtil.UnpackAuraData(auraInfo))
        end
        if done then
            -- if func returns true then no further slots are needed, so don't return continuationToken
            return nil
        end
    end
    return continuationToken
end

function util.ForEachAura(unit, filter, maxCount, func, usePackedAura)
    if maxCount and maxCount <= 0 then
        return
    end
    local continuationToken
    repeat
        -- continuationToken is the first return value of UnitAuraSltos
        continuationToken = ForEachAuraHelper(unit, filter, func, usePackedAura, C_UnitAuras.GetAuraSlots(unit, filter, maxCount, continuationToken))
    until continuationToken == nil
end
