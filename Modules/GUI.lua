local addonName = ...
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class GUI: AceModule
local GUI = Addon:NewModule('GUI')

function GUI:Open()
    AceConfigDialog:Open(addonName)
    local dialog = AceConfigDialog.OpenFrames[addonName]
    if dialog then
        dialog:EnableResize(false)
    end
end

function GUI:Close()
    AceConfigDialog:Close(addonName)
    AceConfigDialog:Close(addonName .. "Dialog")
end

function GUI:Toggle()
    if AceConfigDialog.OpenFrames[addonName] then
        self:Close()
    else
        self:Open()
    end
end
