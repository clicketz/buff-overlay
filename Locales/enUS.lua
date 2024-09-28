---@class BuffOverlay: AceModule
local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")

local L = BuffOverlay.L

local GetSpellInfo = BuffOverlay.GetSpellInfo

--@localization(locale="enUS", format="lua_additive_table", handle-subnamespaces="none")@

-- Localize Eating/Drinking Aura Names
L["Drink"] = GetSpellInfo(430) or "Drink"
local newDrink = GetSpellInfo(396920) or L["Drink"] -- Some locales have different names for "drink" in recent patches.
L["NewDrink"] = newDrink ~= L["Drink"] and newDrink or "Remove"
L["Food"] = GetSpellInfo(5004) or "Food"
local newFood = GetSpellInfo(369156) or L["Food"] -- Some locales have different names for "food" in recent patches.
L["NewFood"] = newFood ~= L["Food"] and newFood or "Remove"
L["Food & Drink"] = GetSpellInfo(170906) or "Food & Drink"
L["Food and Drink"] = GetSpellInfo(462177) or "Food and Drink"
L["Refreshment"] = GetSpellInfo(44166) or "Refreshment"
