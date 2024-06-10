if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

---@class BuffOverlay: AceModule
local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local L = BuffOverlay.L

--[[------------------------------------------------

 If you are editing this file, you should be aware
 that everything can now be done from the in-game
 interface, including adding custom buffs.

 Use the /buffoverlay or /bo command.

------------------------------------------------]]--

-- Lower prio = shown above other buffs
BuffOverlay.defaultSpells = {
    -- Druid
    [22812] = { class = "DRUID", prio = 50 }, --Barkskin
    [5215] = { class = "DRUID", prio = 70 },
        [6783] = { parent = 5215 },
        [9913] = { parent = 5215 },

    -- Hunter
    [19263] = { class = "HUNTER", prio = 50 }, --Deterrence

    -- Mage
    [45438] = { class = "MAGE", prio = 10 }, --Ice Block
    [543] = { class = "MAGE", prio = 50 }, --Fire Ward
        [8457] = { parent = 543 },
        [8458] = { parent = 543 },
        [10223] = { parent = 543 },
        [10225] = { parent = 543 },
    [6143] = { class = "MAGE", prio = 50 }, --Frost Ward
        [8461] = { parent = 6143 },
        [8462] = { parent = 6143 },
        [10177] = { parent = 6143 },
        [28609] = { parent = 6143 },

    -- Paladin
    [6940] = { class = "PALADIN", prio = 50 }, --Blessing of Sacrifice
        [20729] = { parent = 6940 },
    [1022] = { class = "PALADIN", prio = 10 }, --Blessing of Protection
        [5599] = { parent = 1022 },
        [10278] = { parent = 1022 },
    [19753] = { class = "PALADIN", prio = 10 }, --Divine Intervention
    [642] = { class = "PALADIN", prio = 10 }, --Divine Shield
        [498] = { parent = 642 },
        [1020] = { parent = 642 },
        [5573] = { parent = 642 },

    -- Priest
    [33206] = { class = "PRIEST", prio = 50 }, --Pain Suppression

    -- Rogue
    [31224] = { class = "ROGUE", prio = 10 }, --Cloak of Shadows
    [5277] = { class = "ROGUE", prio = 50 }, --Evasion
        [26669] = { parent = 5277 },
    [45182] = { class = "ROGUE", prio = 10 }, --Cheating Death
    [1784] = { class = "ROGUE", prio = 70 }, --Stealth
        [1785] = { parent = 1784 },
        [1786] = { parent = 1784 },
        [1787] = { parent = 1784 },

    -- Shaman
    [30823] = { class = "SHAMAN", prio = 50 }, --Shamanistic Rage

    -- Warlock
    [6229] = { class = "WARLOCK", prio = 50 }, --Shadow Ward
        [11739] = { parent = 6229 },
        [11740] = { parent = 6229 },
        [28610] = { parent = 6229 },
    [7812] = { class = "WARLOCK", prio = 50 }, --Sacrifice (Voidwalker)
        [19438] = { parent = 7812 },
        [19440] = { parent = 7812 },
        [19441] = { parent = 7812 },
        [19442] = { parent = 7812 },
        [19443] = { parent = 7812 },

    -- Warrior
    [12975] = { class = "WARRIOR", prio = 50 }, --Last Stand
    [871] = { class = "WARRIOR", prio = 50 }, --Shield Wall
    [23920] = { class = "WARRIOR", prio = 50 }, --Spell Reflection
    [3411] = { class = "WARRIOR", prio = 50 }, --Intervene

    -- Misc
    [L["Eating/Drinking"]] = { class = "MISC", prio = 90 }, -- Food umbrella
        [L["Food & Drink"]] = { parent = L["Eating/Drinking"] }, --Food & Drink
        [L["Food"]] = { parent = L["Eating/Drinking"] }, --Food
        [L["Drink"]] = { parent = L["Eating/Drinking"] }, --Drink
        [L["Refreshment"]] = { parent = L["Eating/Drinking"] }, --Refreshment
}
