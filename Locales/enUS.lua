local addonName = ... ---@type string

---@class BuffOverlay: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Localization: AceModule
local L = addon:GetModule('Localization')

--@localization(locale="enUS", format="lua_additive_table", table-name="L.data", handle-subnamespaces="none")@

-- Localize Eating/Drinking Aura Names
L:S("Drink", GetSpellInfo(430) or "Drink")
local newDrink = GetSpellInfo(396920) or L:G("Drink") -- Some locales have different names for "drink" in recent patches.
L:S("NewDrink", newDrink ~= L:G("Drink") and newDrink or "Remove")
L:S("Food", GetSpellInfo(5004) or "Food")
local newFood = GetSpellInfo(369156) or L:G("Food") -- Some locales have different names for "food" in recent patches.
L:S("NewFood", newFood ~= L:G("Food") and newFood or "Remove")
L:S("Food & Drink", GetSpellInfo(170906) or "Food & Drink")
L:S("Refreshment", GetSpellInfo(44166) or "Refreshment")
