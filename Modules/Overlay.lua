local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Overlay: AceModule
---@field private frames table<string, table>
local Overlay = Addon:NewModule('Overlay')

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Options: AceModule
local Options = Addon:GetModule('Options')

---@class Data: AceModule
local Data = Addon:GetModule('Data')

Overlay.frames = {}

function Overlay:GetAllOverlays()
    return self.frames
end

---@param key string
---@return table
function Overlay:Get(key)
    return self.frames[key]
end

---@param key string
---@param overlay table
function Overlay:Set(key, overlay)
    self.frames[key] = overlay
end

function Overlay:SetupContainer(frame)
    frame.BuffOverlays = frame.BuffOverlays or CreateFrame("Frame", frame:GetName() .. "BuffOverlayContainer", frame)
    frame.BuffOverlays:SetAllPoints()
end

function Overlay:HideAllOverlays(frame)
    if not frame.BuffOverlays then return end

    for _, child in ipairs({ frame.BuffOverlays:GetChildren() }) do
        child:Hide()
    end
end

function Overlay:RefreshOverlays(full, barName)
    local auras = DB:GetAuras()
    local overlays = Overlay:GetAllOverlays()

    -- fix for resetting profile with buffs active
    if next(auras) == nil then
        DB:CreateAuraTable()
    end

    if full then
        for _, overlay in pairs(overlays) do
            if barName then
                if overlay.bar.id == barName then
                    overlay:StopAllGlows()
                    overlay:Hide()
                    overlay.needsUpdate = true
                end
            else
                overlay:StopAllGlows()
                overlay:Hide()
                overlay.needsUpdate = true
            end
        end
    end

    for unit, frames in pairs(Data:GetAllFrames()) do
        for frame in pairs(frames) do
            if frame:IsShown() then
                self:ApplyOverlay(frame, unit, barName)
            else
                self:HideAllOverlays(frame)
            end
        end
    end

    for frame in pairs(self.blizzFrames) do
        if frame:IsShown() then
            self:ApplyOverlay(frame, frame.displayedUnit, barName)
        else
            self:HideAllOverlays(frame)
        end
    end
end
