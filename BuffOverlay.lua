local addonName, ns = ...

---@class BuffOverlay: AceModule
local Addon = LibStub("AceAddon-3.0"):NewAddon(ns, addonName)

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

function Addon:OnInitialize()
    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    function SlashCmdList.BuffOverlay(msg)
        if msg == "help" or msg == "?" then
            self:Print(L["Command List"])
            print(format(L["%s or %s: Toggles the options panel."], self:Colorize("/buffoverlay", "accent"), self:Colorize("/bo", "accent")))
            print(format(L["%s %s: Shows test icons on all visible raid/party frames."], self:Colorize("/bo", "accent"), self:Colorize("test", "value")))
            print(format(L["%s %s: Toggles the minimap icon."], self:Colorize("/bo", "accent"), self:Colorize("minimap", "value")))
            print(format(L["%s %s: Shows a copyable version string for bug reports."], self:Colorize("/bo", "accent"), self:Colorize("version", "value")))
            print(format(L["%s %s: Resets current profile to default settings. This does not remove any custom auras."], self:Colorize("/bo", "accent"), self:Colorize("reset", "value")))
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
