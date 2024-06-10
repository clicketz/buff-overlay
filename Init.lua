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
