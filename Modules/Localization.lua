local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Localization: AceModule
local Localization = Addon:NewModule('Localization')

-- Localization Table
Localization.L = {}

-- Make missing translations available
setmetatable(Localization.L, {
    __index = function(t, k)
        local v = tostring(k)
        rawset(t, k, v)
        return v
    end
})

Localization:Enable()
