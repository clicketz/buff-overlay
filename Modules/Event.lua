local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Event: AceModule
local Event = Addon:GetModule('Event')

---@class Aura: AceModule
local Aura = Addon:GetModule('Aura')

-- For Blizzard Frames
hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
    if not frame.buffFrames then return end

    Aura:Update(frame, frame.displayedUnit)
end)
