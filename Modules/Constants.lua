local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Constants: AceModule
local Const = Addon:NewModule('Constants')

---@class Localization: AceModule
local Localization = Addon:GetModule('Localization')
local L = Localization.L

Const.LATEST_DB_VERSION = 1.1
Const.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Const.AUTHOR = C_AddOns.GetAddOnMetadata(addonName, "Author")
Const.VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version")

Const.BAR_SETTINGS = {
    iconCount = 4,
    iconScale = 1,
    iconAlpha = 1.0,
    iconSpacing = 0,
    iconAnchor = "BOTTOM",
    iconRelativePoint = "CENTER",
    growDirection = "HORIZONTAL",
    showCooldownSpiral = true,
    showCooldownNumbers = false,
    showStackCount = true,
    cooldownNumberScale = 1,
    stackCountScale = 0.9,
    iconXOff = 0,
    iconYOff = 0,
    iconBorder = true,
    iconBorderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 1,
    },
    debuffIconBorderColorByDispelType = true,
    buffIconBorderColorByDispelType = false,
    iconBorderSize = 1,
    showTooltip = true,
    neverShow = false,
    showInWorld = true,
    showInArena = true,
    showInBattleground = true,
    showInRaid = true,
    showInDungeon = true,
    showInScenario = true,
    maxGroupSize = 40,
    minGroupSize = 0,
    frameTypes = {
        ["raid"] = true,
        ["party"] = true,
        ["tank"] = true,
        ["pet"] = true,
        ["assist"] = true,
        ["player"] = true,
        ["arena"] = true,
    }
}

---@class DatabaseDefaults
Const.DB_DEFAULTS = {
    profile = {
        welcomeMessage = true,
        minimap = {
            hide = false,
        },
        bars = {},
        buffs = {},
        auras = {},
    },
    global = {
        customBuffs = {},
        customAuras = {},
        dbVer = 0,
    },
}

Const.AURA_STATE = {
    enabled = true,
    glow = {
        enabled = false,
        color = { 1, 1, 1, 1 },
        customColor = false,
        n = 8,          -- number of lines
        freq = 0.25,    -- frequency of the lines
        length = nil,   -- length of each line
        thickness = 1,  -- thickness of each line
        xOff = 0,       -- x offset
        yOff = 0,       -- y offset
        border = false, -- show a border
        key = nil,      -- key used to register the glow for multiple glows
        type = "blizz", -- blizz / pixel / oldBlizz
    },
    ownOnly = false,
}

Const.CLASS_ICONS = {
    ["DEATHKNIGHT"] = 135771,
    ["DEMONHUNTER"] = 1260827,
    ["DRUID"] = 625999,
    ["EVOKER"] = 4574311,
    ["HUNTER"] = 626000,
    ["MAGE"] = 626001,
    ["MONK"] = 626002,
    ["PALADIN"] = 626003,
    ["PRIEST"] = 626004,
    ["ROGUE"] = 626005,
    ["SHAMAN"] = 626006,
    ["WARLOCK"] = 626007,
    ["WARRIOR"] = 626008,
}

Const.CUSTOM_SPELL_DESCRIPTIONS = {
    [362486] = 353114, -- Keeper of the Grove
}

Const.CUSTOM_SPELL_NAMES = {
    [228050] = GetSpellInfo(228049),
}

Const.CUSTOM_ICONS = {
    [L["Eating/Drinking"]] = 134062,
    ["?"] = 134400,
    ["Cogwheel"] = 136243,
}

Const.IGNORE_PARENT_ICONS = {
    [L["Eating/Drinking"]] = true,
    [197268] = true, -- Ray of Hope
}

Const.FILTERS = {
    "HELPFUL",
    "HARMFUL",
}

Const.DISPEL_TYPES = {
    "Magic",
    "Curse",
    "Disease",
    "Poison",
    "none",
}

---@type table<string, string>
Const.HEX_COLORS = {
    ["main"] = "ff83b2ff",
    ["accent"] = "ff9b6ef3",
    ["value"] = "ffffe981",
    ["logo"] = "ffff7a00",
    ["blizzardFont"] = NORMAL_FONT_COLOR:GenerateHexColor(),
}

--[[
    Add class colors from RAID_CLASS_COLORS
]]
do
    for class, data in pairs(RAID_CLASS_COLORS) do
        Const.HEX_COLORS[class] = data.colorStr
    end
end
