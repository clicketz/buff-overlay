local addonName, addon = ...

---@class BuffOverlay: AceModule
local Addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName)

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Localization: AceModule
local Localization = Addon:GetModule('Localization')
local L = Localization.L

function Addon:OnInitialize()
    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    function SlashCmdList.BuffOverlay(msg)
        if msg == "help" or msg == "?" then
            self:Print(L["Command List"])
            print(format(L["%s or %s: Toggles the options panel."], Util:Colorize("/buffoverlay", "accent"), Util:Colorize("/bo", "accent")))
            print(format(L["%s %s: Shows test icons on all visible raid/party frames."], Util:Colorize("/bo", "accent"), self:Colorize("test", "value")))
            print(format(L["%s %s: Toggles the minimap icon."], Util:Colorize("/bo", "accent"), Util:Colorize("minimap", "value")))
            print(format(L["%s %s: Shows a copyable version string for bug reports."], Util:Colorize("/bo", "accent"), Util:Colorize("version", "value")))
            print(format(L["%s %s: Resets current profile to default settings. This does not remove any custom auras."], Util:Colorize("/bo", "accent"), Util:Colorize("reset", "value")))
        elseif msg == "test" then
            self:Test()
        elseif msg == "reset" or msg == "default" then
            self.db:ResetProfile()
        elseif msg == "minimap" then
            self:ToggleMinimapIcon()
        elseif msg == "version" then
            self:ShowVersion()
        else
            self:ToggleOptions()
        end
    end

    if DB:WelcomeMessageEnabled() then
        Util:PrintWelcomeMessage()
    end
end
