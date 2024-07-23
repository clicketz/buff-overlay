---@class BuffOverlay: AceModule
BuffOverlay = LibStub("AceAddon-3.0"):NewAddon("BuffOverlay", "AceConsole-3.0")

-- Localization Table
BuffOverlay.L = {}

-- Make missing translations available
setmetatable(BuffOverlay.L, {__index = function(t, k)
    local v = tostring(k)
    rawset(t, k, v)
    return v
end})

-- Definitions
BuffOverlay.GetSpellInfo = function(spellID)
    if not spellID then
        return nil
    end

    -- Classic flavors still use old GetSpellInfo
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
end
