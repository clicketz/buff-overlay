local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Localization: AceModule
local Localization = Addon:GetModule('Localization')
local L = Localization.L

--[[
    Need a local version of Blizzard's AuraUtil.ForEachAura due to it not existing on classic flavors.
]]
local function ForEachAuraHelper(unit, filter, func, usePackedAura, continuationToken, ...)
    -- continuationToken is the first return value of UnitAuraSlots()
    local n = select('#', ...)
    for i = 1, n do
        local slot = select(i, ...)
        local done
        local auraInfo = C_UnitAuras.GetAuraDataBySlot(unit, slot)
        if usePackedAura then
            done = func(auraInfo)
        else
            done = func(AuraUtil.UnpackAuraData(auraInfo))
        end
        if done then
            -- if func returns true then no further slots are needed, so don't return continuationToken
            return nil
        end
    end
    return continuationToken
end

function Util.ForEachAura(unit, filter, maxCount, func, usePackedAura)
    if maxCount and maxCount <= 0 then
        return
    end
    local continuationToken
    repeat
        -- continuationToken is the first return value of UnitAuraSltos
        continuationToken = ForEachAuraHelper(unit, filter, func, usePackedAura, C_UnitAuras.GetAuraSlots(unit, filter, maxCount, continuationToken))
    until continuationToken == nil
end

---@return string|nil
function Util:Colorize(text, color)
    if not text then return end
    local hexColor = Const.HEX_COLORS[color] or Const.HEX_COLORS["blizzardFont"]
    return "|c" .. hexColor .. text .. "|r"
end

function Util:Print(...)
    print(self:Colorize(addonName, "main") .. ":", ...)
end

function Util:PrintWelcomeMessage()
    self:Print(format(L["Type %s or %s to open the options panel or %s for more commands."], self:Colorize("/buffoverlay", "accent"), self:Colorize("/bo", "accent"), self:Colorize("/bo help", "accent")))
end

---@param num number
---@param numDecimalPlaces number
---@return number
function Util:round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Util:GetIconString(icon, iconSize)
    local size = iconSize or 0
    local ltTexel = 0.08 * 256
    local rbTexel = 0.92 * 256

    if not icon then
        icon = Const.CUSTOM_ICONS["?"]
    end

    return format("|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t", icon, size, size, ltTexel, rbTexel, ltTexel, rbTexel)
end

function Util.GetSpellInfo(spellID)
    if not spellID then
        return nil
    end

    -- Classic flavors still use old GetSpellInfo
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end

    return nil, nil, nil, nil, nil, nil, spellID, nil
end
