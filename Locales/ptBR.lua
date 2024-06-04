if (GAME_LOCALE or GetLocale()) ~= "ptBR" then return end

local addonName = ... ---@type string

---@class BuffOverlay: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Localization: AceModule
local L = addon:GetModule('Localization')

--@localization(locale="ptBR", format="lua_additive_table", table-name="L.data", handle-subnamespaces="none")@
