if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local addonName = ... ---@type string

---@class BuffOverlay: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Localization: AceModule
local L = addon:GetModule('Localization')

---@class Spells: AceModule
local spells = addon:GetModule('Spells')

--[[

Controls default spells, but it is not necessary to add spells
through this file. See the in-game interface to add custom spells.

]]

-- Death Knight
spells:Add("DEATHKNIGHT", 145629, 50) -- Anti-Magic Zone
spells:Add("DEATHKNIGHT", 194679, 50) -- Rune Tap
spells:Add("DEATHKNIGHT", 410305, 50) -- Bloodforged Armor
spells:Add("DEATHKNIGHT", 48707, 50)  -- Anti-Magic Shell
spells:Add("DEATHKNIGHT", 48792, 50)  -- Icebound Fortitude
spells:Add("DEATHKNIGHT", 49039, 50)  -- Lichborne
spells:Add("DEATHKNIGHT", 55233, 50)  -- Vampiric Blood
spells:Add("DEATHKNIGHT", 81256, 50)  -- Dancing Rune Weapon

-- Demon Hunter
spells:Add("DEMONHUNTER", 187827, 50) -- Metamorphosis
spells:Add("DEMONHUNTER", 196555, 10) -- Netherwalk
spells:Add("DEMONHUNTER", 206804, 50) -- Rain from Above
spells:Add("DEMONHUNTER", 209426, 50) -- Darkness
spells:Add("DEMONHUNTER", 212800, 50) -- Blur
spells:Add("DEMONHUNTER", 263648, 50) -- Soul Barrier

-- Druid
spells:Add("DRUID", 102342, 50) -- Ironbark
spells:Add("DRUID", 203554, 5)  -- Focused Growth
spells:AddChild(347621, 203554)
spells:Add("DRUID", 22812, 50)  -- Barkskin
spells:Add("DRUID", 22842, 50)  -- Frenzied Regeneration
spells:Add("DRUID", 362486, 10) -- Keeper of the Grove
spells:Add("DRUID", 5215, 70)   -- Prowl
spells:Add("DRUID", 61336, 50)  -- Survival Instincts

-- Evoker
spells:Add("EVOKER", 357170, 50) -- Time Dilation
spells:Add("EVOKER", 363534, 50) -- Rewind
spells:Add("EVOKER", 363916, 50) -- Obsidian Scales
spells:Add("EVOKER", 370960, 50) -- Emerald Communion
spells:Add("EVOKER", 374348, 50) -- Renewing Blaze
spells:Add("EVOKER", 378441, 10) -- Time Stop
spells:Add("EVOKER", 383005, 50) -- Chrono Loop
spells:Add("EVOKER", 404381, 50) -- Defy Fate

-- Hunter
spells:Add("HUNTER", 186265, 10) -- Aspect of the Turtle
spells:Add("HUNTER", 199483, 70) -- Camouflage
spells:Add("HUNTER", 202748, 20) -- Survival Tactics
spells:Add("HUNTER", 264735, 50) -- Survival of the Fittest
spells:AddChild(281195, 264735)
spells:Add("HUNTER", 388035, 50) -- Fortitude of the Bear
spells:Add("HUNTER", 53480, 50)  -- Roar of Sacrifice

-- Mage
spells:Add("MAGE", 113862, 50) -- Greater Invisibility
spells:Add("MAGE", 198111, 50) -- Temporal Shield
spells:Add("MAGE", 342246, 50) -- Alter Time
spells:AddChild(108978, 342246)
spells:AddChild(110909, 342246)
spells:Add("MAGE", 41425, 20)  -- Hypothermia
spells:Add("MAGE", 414658, 50) -- Ice Cold
spells:Add("MAGE", 414664, 50) -- Mass Invisibility
spells:Add("MAGE", 45438, 10)  -- Ice Block
spells:Add("MAGE", 66, 50)     -- Invisibility
spells:AddChild(32612, 66)

-- Monk
spells:Add("MONK", 115176, 50) -- Zen Meditation
spells:Add("MONK", 116849, 50) -- Life Cocoon
spells:Add("MONK", 120954, 50) -- Fortifying Brew
spells:Add("MONK", 122278, 50) -- Dampen Harm
spells:Add("MONK", 122783, 50) -- Diffuse Magic
spells:Add("MONK", 125174, 10) -- Touch of Karma
spells:Add("MONK", 202577, 50) -- Dome of Mist
spells:Add("MONK", 353319, 10) -- Peaceweaver

-- Paladin
spells:Add("PALADIN", 1022, 10)   -- Blessing of Protection
spells:Add("PALADIN", 184662, 50) -- Shield of Vengeance
spells:Add("PALADIN", 204018, 10) -- Blessing of Spellwarding
spells:Add("PALADIN", 205191, 50) -- Eye for an Eye
spells:Add("PALADIN", 228050, 10) -- Divine Shield
spells:Add("PALADIN", 25771, 20)  -- Forbearance
spells:Add("PALADIN", 31821, 50)  -- Aura Mastery
spells:Add("PALADIN", 31850, 50)  -- Ardent Defender
spells:Add("PALADIN", 327193, 50) -- Moment of Glory
spells:Add("PALADIN", 498, 50)    -- Divine Protection
spells:AddChild(403876, 498)
spells:Add("PALADIN", 642, 10)    -- Divine Shield
spells:Add("PALADIN", 6940, 50)   -- Blessing of Sacrifice
spells:AddChild(199448, 6940)
spells:Add("PALADIN", 86659, 50)  -- Guardian of Ancient Kings

-- Priest
spells:Add("PRIEST", 19236, 50)  -- Desperate Prayer
spells:Add("PRIEST", 197268, 10) -- Ray of Hope
spells:AddChild(232707, 197268)
spells:AddChild(232708, 197268)
spells:Add("PRIEST", 271466, 50) -- Luminous Barrier
spells:Add("PRIEST", 27827, 10)  -- Spirit of Redemption
spells:AddChild(215769, 27827)
spells:Add("PRIEST", 33206, 50)  -- Pain Suppression
spells:Add("PRIEST", 47585, 50)  -- Dispersion
spells:Add("PRIEST", 47788, 10)  -- Guardian Spirit
spells:Add("PRIEST", 586, 50)    -- Fade
spells:Add("PRIEST", 64844, 50)  -- Divine Hymn
spells:Add("PRIEST", 81782, 50)  -- Power Word: Barrier

-- Rogue
spells:Add("ROGUE", 11327, 70)  -- Vanish
spells:Add("ROGUE", 114018, 70) -- Shroud of Concealment
spells:AddChild(115834, 114018)
spells:Add("ROGUE", 1784, 70)   -- Stealth
spells:AddChild(115191, 1784)
spells:Add("ROGUE", 1966, 50)   -- Feint
spells:Add("ROGUE", 31224, 10)  -- Cloak of Shadows
spells:Add("ROGUE", 45182, 50)  -- Cheating Death
spells:Add("ROGUE", 5277, 50)   -- Evasion

-- Shaman
spells:Add("SHAMAN", 108271, 50) -- Astral Shift
spells:Add("SHAMAN", 118337, 50) -- Harden Skin
spells:Add("SHAMAN", 201633, 50) -- Earthen Wall
spells:Add("SHAMAN", 207498, 50) -- Ancestral Protection
spells:Add("SHAMAN", 325174, 50) -- Spirit Link Totem
spells:Add("SHAMAN", 383018, 50) -- Stoneskin
spells:Add("SHAMAN", 409293, 10) -- Burrow
spells:Add("SHAMAN", 8178, 50)   -- Grounding Totem

-- Warlock
spells:Add("WARLOCK", 104773, 50) -- Unending Resolve
spells:Add("WARLOCK", 108416, 50) -- Dark Pact
spells:Add("WARLOCK", 212295, 50) -- Nether Ward

-- Warrior
spells:Add("WARRIOR", 118038, 50) -- Die by the Sword
spells:Add("WARRIOR", 12975, 50)  -- Last Stand
spells:Add("WARRIOR", 147833, 50) -- Intervene
spells:Add("WARRIOR", 184364, 50) -- Enraged Regeneration
spells:Add("WARRIOR", 190456, 50) -- Ignore Pain
spells:Add("WARRIOR", 213871, 50) -- Bodyguard
spells:Add("WARRIOR", 23920, 50)  -- Spell Reflection
spells:Add("WARRIOR", 424655, 50) -- Safeguard
spells:Add("WARRIOR", 871, 50)    -- Shield Wall
spells:Add("WARRIOR", 97463, 50)  -- Rallying Cry

-- Misc
spells:Add("MISC", 320224, 70)                   -- Podtender
spells:Add("MISC", 345231, 70)                   -- Gladiator's Emblem
spells:Add("MISC", 363522, 70)                   -- Gladiator's Eternal Aegis
spells:Add("MISC", 58984, 70)                    -- Shadowmeld
spells:Add("MISC", L:G("Eating / Drinking"), 90) -- Eating/Drinking
spells:AddChild(185710, L:G("Eating / Drinking"))
spells:AddChild(L:G("Drink"), L:G("Eating / Drinking"))
spells:AddChild(L:G("Food & Drink"), L:G("Eating / Drinking"))
spells:AddChild(L:G("Food"), L:G("Eating / Drinking"))
spells:AddChild(L:G("Refreshment"), L:G("Eating / Drinking"))
