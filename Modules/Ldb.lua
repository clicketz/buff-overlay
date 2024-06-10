local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class LDB: AceModule
local LDB = Addon:NewModule('LDB')

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class GUI: AceModule
local GUI = Addon:GetModule('GUI')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Test: AceModule
local Test = Addon:GetModule('Test')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Localization: AceModule
local Localization = Addon:GetModule('Localization')
local L = Localization.L

local LibDataBroker = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local AceRegistry = LibStub("AceConfigRegistry-3.0")

local ldbData = {
    type = "launcher",
    text = addonName,
    -- "Logo" created by Marz Gallery @ https://www.flaticon.com/free-icons/nocturnal
    icon = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\logo",
    OnTooltipShow = function(tooltip)
        tooltip:AddDoubleLine(Util:Colorize(addonName, "main"), Util:Colorize(Const.VERSION, "accent"))
        tooltip:AddLine(" ")
        tooltip:AddLine(format(L["%s to toggle options window."], Util:Colorize(L["Left-click"])), 1, 1, 1, false)
        tooltip:AddLine(format(L["%s to toggle test icons."], Util:Colorize(L["Right-click"])), 1, 1, 1, false)
        tooltip:AddLine(format(L["%s to toggle the minimap icon."], Util:Colorize(L["Shift+Right-click"])), 1, 1, 1, false)
    end,
    OnClick = function(clickedFrame, button)
        if button == "LeftButton" then
            GUI:Toggle()
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                LDB:ToggleMinimapIcon()
                if DB:IsMinimapHidden() then
                    Util:Print(format(L["Minimap icon is now hidden. Type %s %s to show it again."], Util:Colorize("/bo", "accent"), Util:Colorize("minimap", "accent")))
                end
                AceRegistry:NotifyChange(addonName)
            else
                Test:On()
            end
        end
    end,
}

local broker = LibDataBroker:NewDataObject(addonName, ldbData)

if AddonCompartmentFrame then
    AddonCompartmentFrame:RegisterAddon({
        text = addonName,
        icon = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\logo_transparent",
        notCheckable = true,
        func = function()
            GUI:Toggle()
        end,
    })
end

function LDB:UpdateMinimapIcon()
    if DB:IsMinimapHidden() then
        LDBIcon:Hide(addonName)
    else
        LDBIcon:Show(addonName)
    end
end

function LDB:OnInitialize()
    LDBIcon:Register(addonName, broker, DB:GetMinimap())
end

local function UpdateMinimapIconShowState()
    if DB:IsMinimapHidden() then
        LDBIcon:Hide(addonName)
    else
        LDBIcon:Show(addonName)
    end
end

function LDB:ToggleMinimapIcon()
    DB:ToggleMinimapIcon()
    UpdateMinimapIconShowState()
end
