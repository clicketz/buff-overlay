BuffOverlay = LibStub("AceAddon-3.0"):NewAddon("BuffOverlay", "AceConsole-3.0")

--[[------------------------------------------------

 If you are editing this file, you should be aware
 that everything can now be done from the in-game
 interface, including adding custom buffs.

 Use the /buffoverlay or /bo command.

------------------------------------------------]]--

-- Lower prio = shown above other buffs
BuffOverlay.defaultSpells = {
    -- Death Knight
    [48707] = { class = "DEATHKNIGHT", prio = 50 }, --Anti-Magic Shell
    [48792] = { class = "DEATHKNIGHT", prio = 50 }, --Icebound Fortitude
    [49039] = { class = "DEATHKNIGHT", prio = 50 }, --Lichborne
    [55233] = { class = "DEATHKNIGHT", prio = 50 }, --Vampiric Blood
    [194679] = { class = "DEATHKNIGHT", prio = 50 }, --Rune Tap
    [145629] = { class = "DEATHKNIGHT", prio = 50 }, --Anti-Magic Zone
    [81256] = { class = "DEATHKNIGHT", prio = 50 }, --Dancing Rune Weapon

    -- Demon Hunter
    [196555] = { class = "DEMONHUNTER", prio = 10 }, --Netherwalk
    [209426] = { class = "DEMONHUNTER", prio = 50 }, --Darkness
    [206804] = { class = "DEMONHUNTER", prio = 50 }, --Rain from Above
    [187827] = { class = "DEMONHUNTER", prio = 50 }, --Metamorphosis (Vengeance)
    [212800] = { class = "DEMONHUNTER", prio = 50 }, --Blur
    [263648] = { class = "DEMONHUNTER", prio = 50 }, --Soul Barrier

    -- Druid
    [203554] = { class = "DRUID", prio = 5 }, --Focused Growth
    [362486] = { class = "DRUID", prio = 10 }, --Tranquility (Druid PVP)
    [102342] = { class = "DRUID", prio = 50 }, --Ironbark
    [22812] = { class = "DRUID", prio = 50 }, --Barkskin
    [61336] = { class = "DRUID", prio = 50 }, --Survival Instincts
    [5215] = { class = "DRUID", prio = 70 }, --Prowl

    -- Evoker
    [363916] = { class = "EVOKER", prio = 50 }, --Obsidian Scales
    [357170] = { class = "EVOKER", prio = 50 }, --Time Dilation
    [378441] = { class = "EVOKER", prio = 10 }, --Time Stop
    [383005] = { class = "EVOKER", prio = 50 }, --Chrono Loop
    [374348] = { class = "EVOKER", prio = 50 }, --Renewing Blaze
    [370960] = { class = "EVOKER", prio = 50 }, --Emerald Communion

    -- Hunter
    [186265] = { class = "HUNTER", prio = 10 }, --Aspect of the Turtle
    [53480] = { class = "HUNTER", prio = 50 }, --Roar of Sacrifice
    [264735] = { class = "HUNTER", prio = 50 }, --Survival of the Fittest (Pet Ability)
    [281195] = { parent = 264735 }, --Survival of the Fittest (Lone Wolf)
    [199483] = { class = "HUNTER", prio = 70 }, --Camouflage

    -- Mage
    [45438] = { class = "MAGE", prio = 10 }, --Ice Block
    [66] = { class = "MAGE", prio = 50 }, --Invisibility
    [32612] = { parent = 66 },
    [198158] = { class = "MAGE", prio = 50 }, --Mass Invisibility
    [198111] = { class = "MAGE", prio = 50 }, --Temporal Shield
    [110960] = { class = "MAGE", prio = 50 }, --Greater Invisibility
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
    [642] = { class = "PALADIN", prio = 10 }, --Divine Shield
    [228050] = { class = "PALADIN", prio = 10 }, --Guardian of the Forgotten Queen
    [1022] = { class = "PALADIN", prio = 10 }, --Blessing of Protection
    [6940] = { class = "PALADIN", prio = 50 }, --Blessing of Sacrifice
    [199448] = { parent = 6940 }, --Blessing of Ultimate Sacrifice
    [498] = { class = "PALADIN", prio = 50 }, --Divine Protection
    [31850] = { class = "PALADIN", prio = 50 }, --Ardent Defender
    [86659] = { class = "PALADIN", prio = 50 }, --Guardian of Ancient Kings
    [205191] = { class = "PALADIN", prio = 50 }, --Eye for an Eye
    [184662] = { class = "PALADIN", prio = 50 }, --Shield of Vengeance
    [31821] = { class = "PALADIN", prio = 50 }, --Aura Mastery
    [327193] = { class = "PALADIN", prio = 50 }, --Moment of Glory

    -- Priest
    [47788] = { class = "PRIEST", prio = 10 }, --Guardian Spirit
    [47585] = { class = "PRIEST", prio = 50 }, --Dispersion
    [33206] = { class = "PRIEST", prio = 50 }, --Pain Suppression
    [81782] = { class = "PRIEST", prio = 50 }, --Power Word: Barrier
    [271466] = { class = "PRIEST", prio = 50 }, --Luminous Barrier
    [20711] = { class = "PRIEST", prio = 50 }, --Spirit of Redemption
    [19236] = { class = "PRIEST", prio = 50 }, --Desperate Prayer

    -- Rogue
    [31224] = { class = "ROGUE", prio = 10 }, --Cloak of Shadows
    [45182] = { class = "ROGUE", prio = 50 }, --Cheating Death
    [5277] = { class = "ROGUE", prio = 50 }, --Evasion
    [1966] = { class = "ROGUE", prio = 50 }, --Feint
    [1784] = { class = "ROGUE", prio = 70 }, --Stealth
    [115191] = { parent = 1784 }, --Stealth (Shadowrunner)
    [11327] = { class = "ROGUE", prio = 70 }, --Vanish
    [114018] = { class = "ROGUE", prio = 70 }, --Shroud of Concealment

    -- Shaman
    [210918] = { class = "SHAMAN", prio = 10 }, --Ethereal Form
    [108271] = { class = "SHAMAN", prio = 50 }, --Astral Shift
    [118337] = { class = "SHAMAN", prio = 50 }, --Harden Skin
    [201633] = { class = "SHAMAN", prio = 50 }, --Earthen Wall Totem
    [383018] = { class = "SHAMAN", prio = 50 }, --Stoneskin Totem
    [325174] = { class = "SHAMAN", prio = 50 }, --Spirit Link Totem
    [207498] = { class = "SHAMAN", prio = 50 }, --Ancestral Protection Totem

    -- Warlock
    [212295] = { class = "WARLOCK", prio = 50 }, --Nether Ward
    [104773] = { class = "WARLOCK", prio = 50 }, --Unending Resolve
    [108416] = { class = "WARLOCK", prio = 50 }, --Dark Pact

    -- Warrior
    [871] = { class = "WARRIOR", prio = 50 }, --Shield Wall
    [118038] = { class = "WARRIOR", prio = 50 }, --Die by the Sword
    [147833] = { class = "WARRIOR", prio = 50 }, --Intervene
    [23920] = { class = "WARRIOR", prio = 50 }, --Spell Reflection
    [184364] = { class = "WARRIOR", prio = 50 }, --Enraged Regeneration
    [97463] = { class = "WARRIOR", prio = 50 }, --Rallying Cry
    [12975] = { class = "WARRIOR", prio = 50 }, --Last Stand
    [190456] = { class = "WARRIOR", prio = 50 }, --Ignore Pain
    [213871] = { class = "WARRIOR", prio = 50 }, --Bodyguard

    -- Misc
    ["Eating/Drinking"] = { class = "MISC", prio = 90 }, -- Food umbrella
    ["Food & Drink"] = { parent = "Eating/Drinking" }, --Food & Drink
    ["Food"] = { parent = "Eating/Drinking" }, --Food
    ["Drink"] = { parent = "Eating/Drinking" }, --Drink
    ["Refreshment"] = { parent = "Eating/Drinking" }, --Refreshment
    [185710] = { parent = "Eating/Drinking" }, --Sugar-Crusted Fish Feast
    [320224] = { class = "MISC", prio = 70 }, -- Podtender
    [363522] = { class = "MISC", prio = 70 }, -- Gladiator's Eternal Aegis
    [345231] = { class = "MISC", prio = 70 }, -- Gladiator's Emblem
}
