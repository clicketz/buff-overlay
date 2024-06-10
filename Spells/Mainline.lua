if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Localization: AceModule
local Localization = Addon:GetModule('Localization')
local L = Localization.L

---@class Spells: AceModule
local Spells = Addon:GetModule('Spells')

--[[

Controls default spells, but it is not necessary to add spells
through this file. See the in-game interface to add custom spells.

]]

local defaultSpells = {
    -- Death Knight
    [48707] = { class = "DEATHKNIGHT", prio = 50 },  --Anti-Magic Shell
    [48792] = { class = "DEATHKNIGHT", prio = 50 },  --Icebound Fortitude
    [49039] = { class = "DEATHKNIGHT", prio = 50 },  --Lichborne
    [55233] = { class = "DEATHKNIGHT", prio = 50 },  --Vampiric Blood
    [194679] = { class = "DEATHKNIGHT", prio = 50 }, --Rune Tap
    [145629] = { class = "DEATHKNIGHT", prio = 50 }, --Anti-Magic Zone
    [81256] = { class = "DEATHKNIGHT", prio = 50 },  --Dancing Rune Weapon
    [410305] = { class = "DEATHKNIGHT", prio = 50 }, --Bloodforged Armor

    -- Demon Hunter
    [196555] = { class = "DEMONHUNTER", prio = 10 }, --Netherwalk
    [209426] = { class = "DEMONHUNTER", prio = 50 }, --Darkness
    [206804] = { class = "DEMONHUNTER", prio = 50 }, --Rain from Above
    [187827] = { class = "DEMONHUNTER", prio = 50 }, --Metamorphosis (Vengeance)
    [212800] = { class = "DEMONHUNTER", prio = 50 }, --Blur
    [263648] = { class = "DEMONHUNTER", prio = 50 }, --Soul Barrier

    -- Druid
    [203554] = { class = "DRUID", prio = 5 },  --Focused Growth
    [347621] = { parent = 203554 },
    [362486] = { class = "DRUID", prio = 10 }, --Tranquility (Druid PVP)
    [22842] = { class = "DRUID", prio = 50 },  --Frenzied Regeneration
    [102342] = { class = "DRUID", prio = 50 }, --Ironbark
    [22812] = { class = "DRUID", prio = 50 },  --Barkskin
    [61336] = { class = "DRUID", prio = 50 },  --Survival Instincts
    [5215] = { class = "DRUID", prio = 70 },   --Prowl

    -- Evoker
    [378441] = { class = "EVOKER", prio = 10 }, --Time Stop
    [363916] = { class = "EVOKER", prio = 50 }, --Obsidian Scales
    [357170] = { class = "EVOKER", prio = 50 }, --Time Dilation
    [383005] = { class = "EVOKER", prio = 50 }, --Chrono Loop
    [374348] = { class = "EVOKER", prio = 50 }, --Renewing Blaze
    [370960] = { class = "EVOKER", prio = 50 }, --Emerald Communion
    [363534] = { class = "EVOKER", prio = 50 }, --Rewind
    [404381] = { class = "EVOKER", prio = 50 }, --Defy Fate

    -- Hunter
    [186265] = { class = "HUNTER", prio = 10 }, --Aspect of the Turtle
    [202748] = { class = "HUNTER", prio = 20 }, --Survival Tactics
    [53480] = { class = "HUNTER", prio = 50 },  --Roar of Sacrifice
    [264735] = { class = "HUNTER", prio = 50 }, --Survival of the Fittest (Pet Ability)
    [281195] = { parent = 264735 },             --Survival of the Fittest (Lone Wolf)
    [388035] = { class = "HUNTER", prio = 50 }, --Fortitude of the Bear
    [199483] = { class = "HUNTER", prio = 70 }, --Camouflage

    -- Mage
    [45438] = { class = "MAGE", prio = 10 },  --Ice Block
    [41425] = { class = "MAGE", prio = 20 },  --Hypothermia
    [414658] = { class = "MAGE", prio = 50 }, --Ice Cold
    [66] = { class = "MAGE", prio = 50 },     --Invisibility
    [32612] = { parent = 66 },
    [414664] = { class = "MAGE", prio = 50 }, --Mass Invisibility
    [198111] = { class = "MAGE", prio = 50 }, --Temporal Shield
    [113862] = { class = "MAGE", prio = 50 }, --Greater Invisibility
    [342246] = { class = "MAGE", prio = 50 }, --Alter Time
    [110909] = { parent = 342246 },
    [108978] = { parent = 342246 },

    -- Monk
    [353319] = { class = "MONK", prio = 10 }, --Peaceweaver
    [125174] = { class = "MONK", prio = 10 }, --Touch of Karma
    [202577] = { class = "MONK", prio = 50 }, --Dome of Mist
    [120954] = { class = "MONK", prio = 50 }, --Fortifying Brew
    [115176] = { class = "MONK", prio = 50 }, --Zen Meditation
    [116849] = { class = "MONK", prio = 50 }, --Life Cocoon
    [122278] = { class = "MONK", prio = 50 }, --Dampen Harm
    [122783] = { class = "MONK", prio = 50 }, --Diffuse Magic

    -- Paladin
    [204018] = { class = "PALADIN", prio = 10 }, --Blessing of Spellwarding
    [642] = { class = "PALADIN", prio = 10 },    --Divine Shield
    [228050] = { class = "PALADIN", prio = 10 }, --Guardian of the Forgotten Queen
    [1022] = { class = "PALADIN", prio = 10 },   --Blessing of Protection
    [25771] = { class = "PALADIN", prio = 20 },  --Forbearance
    [6940] = { class = "PALADIN", prio = 50 },   --Blessing of Sacrifice
    [199448] = { parent = 6940 },                --Blessing of Ultimate Sacrifice
    [498] = { class = "PALADIN", prio = 50 },    --Divine Protection
    [403876] = { parent = 498 },                 --Divine Protection (Retribution)
    [31850] = { class = "PALADIN", prio = 50 },  --Ardent Defender
    [86659] = { class = "PALADIN", prio = 50 },  --Guardian of Ancient Kings
    [205191] = { class = "PALADIN", prio = 50 }, --Eye for an Eye
    [184662] = { class = "PALADIN", prio = 50 }, --Shield of Vengeance
    [31821] = { class = "PALADIN", prio = 50 },  --Aura Mastery
    [327193] = { class = "PALADIN", prio = 50 }, --Moment of Glory

    -- Priest
    [197268] = { class = "PRIEST", prio = 10 }, --Ray of Hope
    [232707] = { parent = 197268 },             --Ray of Hope (Positive)
    [232708] = { parent = 197268 },             --Ray of Hope (Negative)
    [47788] = { class = "PRIEST", prio = 10 },  --Guardian Spirit
    [27827] = { class = "PRIEST", prio = 10 },  --Spirit of Redemption
    [215769] = { parent = 27827 },              --Spirit of the Redeemer
    [586] = { class = "PRIEST", prio = 50 },    --Fade
    [47585] = { class = "PRIEST", prio = 50 },  --Dispersion
    [33206] = { class = "PRIEST", prio = 50 },  --Pain Suppression
    [81782] = { class = "PRIEST", prio = 50 },  --Power Word: Barrier
    [271466] = { class = "PRIEST", prio = 50 }, --Luminous Barrier
    [19236] = { class = "PRIEST", prio = 50 },  --Desperate Prayer
    [64844] = { class = "PRIEST", prio = 50 },  --Divine Hymn

    -- Rogue
    [31224] = { class = "ROGUE", prio = 10 },  --Cloak of Shadows
    [45182] = { class = "ROGUE", prio = 50 },  --Cheating Death
    [5277] = { class = "ROGUE", prio = 50 },   --Evasion
    [1966] = { class = "ROGUE", prio = 50 },   --Feint
    [1784] = { class = "ROGUE", prio = 70 },   --Stealth
    [115191] = { parent = 1784 },              --Stealth (Shadowrunner)
    [11327] = { class = "ROGUE", prio = 70 },  --Vanish
    [114018] = { class = "ROGUE", prio = 70 }, --Shroud of Concealment
    [115834] = { parent = 114018 },

    -- Shaman
    [409293] = { class = "SHAMAN", prio = 10 }, --Burrow
    [108271] = { class = "SHAMAN", prio = 50 }, --Astral Shift
    [118337] = { class = "SHAMAN", prio = 50 }, --Harden Skin
    [201633] = { class = "SHAMAN", prio = 50 }, --Earthen Wall Totem
    [383018] = { class = "SHAMAN", prio = 50 }, --Stoneskin Totem
    [325174] = { class = "SHAMAN", prio = 50 }, --Spirit Link Totem
    [207498] = { class = "SHAMAN", prio = 50 }, --Ancestral Protection Totem
    [8178] = { class = "SHAMAN", prio = 50 },   --Grounding Totem

    -- Warlock
    [212295] = { class = "WARLOCK", prio = 50 }, --Nether Ward
    [104773] = { class = "WARLOCK", prio = 50 }, --Unending Resolve
    [108416] = { class = "WARLOCK", prio = 50 }, --Dark Pact

    -- Warrior
    [871] = { class = "WARRIOR", prio = 50 },    --Shield Wall
    [118038] = { class = "WARRIOR", prio = 50 }, --Die by the Sword
    [147833] = { class = "WARRIOR", prio = 50 }, --Intervene
    [23920] = { class = "WARRIOR", prio = 50 },  --Spell Reflection
    [184364] = { class = "WARRIOR", prio = 50 }, --Enraged Regeneration
    [97463] = { class = "WARRIOR", prio = 50 },  --Rallying Cry
    [12975] = { class = "WARRIOR", prio = 50 },  --Last Stand
    [190456] = { class = "WARRIOR", prio = 50 }, --Ignore Pain
    [213871] = { class = "WARRIOR", prio = 50 }, --Bodyguard
    [424655] = { class = "WARRIOR", prio = 50 }, --Safeguard

    -- Racials
    [58984] = { class = "MISC", prio = 70 }, --Shadowmeld

    -- Misc
    [L["Eating/Drinking"]] = { class = "MISC", prio = 90 },  --Food umbrella
    [L["Food & Drink"]] = { parent = L["Eating/Drinking"] }, --Food & Drink
    [L["Food"]] = { parent = L["Eating/Drinking"] },         --Food
    [L["Drink"]] = { parent = L["Eating/Drinking"] },        --Drink
    [L["Refreshment"]] = { parent = L["Eating/Drinking"] },  --Refreshment
    [185710] = { parent = L["Eating/Drinking"] },            --Sugar-Crusted Fish Feast
    [L["NewFood"]] = L["NewFood"] ~= "Remove" and { parent = L["Eating/Drinking"] } or nil,
    [L["NewDrink"]] = L["NewDrink"] ~= "Remove" and { parent = L["Eating/Drinking"] } or nil,
    [320224] = { class = "MISC", prio = 70 }, -- Podtender
    [363522] = { class = "MISC", prio = 70 }, -- Gladiator's Eternal Aegis
    [345231] = { class = "MISC", prio = 70 }, -- Gladiator's Emblem
}

do
    for spellId, spell in pairs(defaultSpells) do
        if spell.parent then
            Spells:AddChild(spellId, spell.parent)
        else
            Spells:AddDefault(spell.class, spellId, spell.prio)
        end
    end
end

--[[
-- Death Knight
Spells:Put("DEATHKNIGHT", 145629, 50) -- Anti-Magic Zone
Spells:Put("DEATHKNIGHT", 194679, 50) -- Rune Tap
Spells:Put("DEATHKNIGHT", 410305, 50) -- Bloodforged Armor
Spells:Put("DEATHKNIGHT", 48707, 50)  -- Anti-Magic Shell
Spells:Put("DEATHKNIGHT", 48792, 50)  -- Icebound Fortitude
Spells:Put("DEATHKNIGHT", 49039, 50)  -- Lichborne
Spells:Put("DEATHKNIGHT", 55233, 50)  -- Vampiric Blood
Spells:Put("DEATHKNIGHT", 81256, 50)  -- Dancing Rune Weapon

-- Demon Hunter
Spells:Put("DEMONHUNTER", 187827, 50) -- Metamorphosis
Spells:Put("DEMONHUNTER", 196555, 10) -- Netherwalk
Spells:Put("DEMONHUNTER", 206804, 50) -- Rain from Above
Spells:Put("DEMONHUNTER", 209426, 50) -- Darkness
Spells:Put("DEMONHUNTER", 212800, 50) -- Blur
Spells:Put("DEMONHUNTER", 263648, 50) -- Soul Barrier

-- Druid
Spells:Put("DRUID", 102342, 50) -- Ironbark
Spells:Put("DRUID", 203554, 5)  -- Focused Growth
Spells:AddChild(347621, 203554)
Spells:Put("DRUID", 22812, 50)  -- Barkskin
Spells:Put("DRUID", 22842, 50)  -- Frenzied Regeneration
Spells:Put("DRUID", 362486, 10) -- Keeper of the Grove
Spells:Put("DRUID", 5215, 70)   -- Prowl
Spells:Put("DRUID", 61336, 50)  -- Survival Instincts

-- Evoker
Spells:Put("EVOKER", 357170, 50) -- Time Dilation
Spells:Put("EVOKER", 363534, 50) -- Rewind
Spells:Put("EVOKER", 363916, 50) -- Obsidian Scales
Spells:Put("EVOKER", 370960, 50) -- Emerald Communion
Spells:Put("EVOKER", 374348, 50) -- Renewing Blaze
Spells:Put("EVOKER", 378441, 10) -- Time Stop
Spells:Put("EVOKER", 383005, 50) -- Chrono Loop
Spells:Put("EVOKER", 404381, 50) -- Defy Fate

-- Hunter
Spells:Put("HUNTER", 186265, 10) -- Aspect of the Turtle
Spells:Put("HUNTER", 199483, 70) -- Camouflage
Spells:Put("HUNTER", 202748, 20) -- Survival Tactics
Spells:Put("HUNTER", 264735, 50) -- Survival of the Fittest
Spells:AddChild(281195, 264735)
Spells:Put("HUNTER", 388035, 50) -- Fortitude of the Bear
Spells:Put("HUNTER", 53480, 50)  -- Roar of Sacrifice

-- Mage
Spells:Put("MAGE", 113862, 50) -- Greater Invisibility
Spells:Put("MAGE", 198111, 50) -- Temporal Shield
Spells:Put("MAGE", 342246, 50) -- Alter Time
Spells:AddChild(108978, 342246)
Spells:AddChild(110909, 342246)
Spells:Put("MAGE", 41425, 20)  -- Hypothermia
Spells:Put("MAGE", 414658, 50) -- Ice Cold
Spells:Put("MAGE", 414664, 50) -- Mass Invisibility
Spells:Put("MAGE", 45438, 10)  -- Ice Block
Spells:Put("MAGE", 66, 50)     -- Invisibility
Spells:AddChild(32612, 66)

-- Monk
Spells:Put("MONK", 115176, 50) -- Zen Meditation
Spells:Put("MONK", 116849, 50) -- Life Cocoon
Spells:Put("MONK", 120954, 50) -- Fortifying Brew
Spells:Put("MONK", 122278, 50) -- Dampen Harm
Spells:Put("MONK", 122783, 50) -- Diffuse Magic
Spells:Put("MONK", 125174, 10) -- Touch of Karma
Spells:Put("MONK", 202577, 50) -- Dome of Mist
Spells:Put("MONK", 353319, 10) -- Peaceweaver

-- Paladin
Spells:Put("PALADIN", 1022, 10)   -- Blessing of Protection
Spells:Put("PALADIN", 184662, 50) -- Shield of Vengeance
Spells:Put("PALADIN", 204018, 10) -- Blessing of Spellwarding
Spells:Put("PALADIN", 205191, 50) -- Eye for an Eye
Spells:Put("PALADIN", 228050, 10) -- Divine Shield
Spells:Put("PALADIN", 25771, 20)  -- Forbearance
Spells:Put("PALADIN", 31821, 50)  -- Aura Mastery
Spells:Put("PALADIN", 31850, 50)  -- Ardent Defender
Spells:Put("PALADIN", 327193, 50) -- Moment of Glory
Spells:Put("PALADIN", 498, 50)    -- Divine Protection
Spells:AddChild(403876, 498)
Spells:Put("PALADIN", 642, 10)    -- Divine Shield
Spells:Put("PALADIN", 6940, 50)   -- Blessing of Sacrifice
Spells:AddChild(199448, 6940)
Spells:Put("PALADIN", 86659, 50)  -- Guardian of Ancient Kings

-- Priest
Spells:Put("PRIEST", 19236, 50)  -- Desperate Prayer
Spells:Put("PRIEST", 197268, 10) -- Ray of Hope
Spells:AddChild(232707, 197268)
Spells:AddChild(232708, 197268)
Spells:Put("PRIEST", 271466, 50) -- Luminous Barrier
Spells:Put("PRIEST", 27827, 10)  -- Spirit of Redemption
Spells:AddChild(215769, 27827)
Spells:Put("PRIEST", 33206, 50)  -- Pain Suppression
Spells:Put("PRIEST", 47585, 50)  -- Dispersion
Spells:Put("PRIEST", 47788, 10)  -- Guardian Spirit
Spells:Put("PRIEST", 586, 50)    -- Fade
Spells:Put("PRIEST", 64844, 50)  -- Divine Hymn
Spells:Put("PRIEST", 81782, 50)  -- Power Word: Barrier

-- Rogue
Spells:Put("ROGUE", 11327, 70)  -- Vanish
Spells:Put("ROGUE", 114018, 70) -- Shroud of Concealment
Spells:AddChild(115834, 114018)
Spells:Put("ROGUE", 1784, 70)   -- Stealth
Spells:AddChild(115191, 1784)
Spells:Put("ROGUE", 1966, 50)   -- Feint
Spells:Put("ROGUE", 31224, 10)  -- Cloak of Shadows
Spells:Put("ROGUE", 45182, 50)  -- Cheating Death
Spells:Put("ROGUE", 5277, 50)   -- Evasion

-- Shaman
Spells:Put("SHAMAN", 108271, 50) -- Astral Shift
Spells:Put("SHAMAN", 118337, 50) -- Harden Skin
Spells:Put("SHAMAN", 201633, 50) -- Earthen Wall
Spells:Put("SHAMAN", 207498, 50) -- Ancestral Protection
Spells:Put("SHAMAN", 325174, 50) -- Spirit Link Totem
Spells:Put("SHAMAN", 383018, 50) -- Stoneskin
Spells:Put("SHAMAN", 409293, 10) -- Burrow
Spells:Put("SHAMAN", 8178, 50)   -- Grounding Totem

-- Warlock
Spells:Put("WARLOCK", 104773, 50) -- Unending Resolve
Spells:Put("WARLOCK", 108416, 50) -- Dark Pact
Spells:Put("WARLOCK", 212295, 50) -- Nether Ward

-- Warrior
Spells:Put("WARRIOR", 118038, 50) -- Die by the Sword
Spells:Put("WARRIOR", 12975, 50)  -- Last Stand
Spells:Put("WARRIOR", 147833, 50) -- Intervene
Spells:Put("WARRIOR", 184364, 50) -- Enraged Regeneration
Spells:Put("WARRIOR", 190456, 50) -- Ignore Pain
Spells:Put("WARRIOR", 213871, 50) -- Bodyguard
Spells:Put("WARRIOR", 23920, 50)  -- Spell Reflection
Spells:Put("WARRIOR", 424655, 50) -- Safeguard
Spells:Put("WARRIOR", 871, 50)    -- Shield Wall
Spells:Put("WARRIOR", 97463, 50)  -- Rallying Cry

-- Misc
Spells:Put("MISC", 320224, 70) -- Podtender
Spells:Put("MISC", 345231, 70) -- Gladiator's Emblem
Spells:Put("MISC", 363522, 70) -- Gladiator's Eternal Aegis
Spells:Put("MISC", 58984, 70)  -- Shadowmeld
Spells:Put("MISC", L:G("Eating / Drinking"), 90)
Spells:AddChild(185710, L:G("Eating / Drinking"))
Spells:AddChild(L:G("Drink"), L:G("Eating / Drinking"))
Spells:AddChild(L:G("Food & Drink"), L:G("Eating / Drinking"))
Spells:AddChild(L:G("Food"), L:G("Eating / Drinking"))
Spells:AddChild(L:G("Refreshment"), L:G("Eating / Drinking"))
]]
