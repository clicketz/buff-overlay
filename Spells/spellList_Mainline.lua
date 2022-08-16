BuffOverlay = LibStub("AceAddon-3.0"):NewAddon("BuffOverlay", "AceConsole-3.0")

--Higher in spellList = higher shown priority

BuffOverlay.defaultSpells = {
    --High Priority
    203554, --Focused Growth (Druid)
    -- 279793, --Grove Tending (Druid)

    --Immunities
    196555, --Netherwalk (Demon Hunter)
    186265, --Aspect of the Turtle (Hunter)
    45438,  --Ice Block (Mage)
    125174, --Touch of Karma (Monk)
    228050, --Divine Shield (Prot Paladin PVP)
    642,    --Divine Shield (Paladin)
    199448, --Blessing of Ultimate Sacrifice (Paladin)
    1022,   --Blessing of Protection (Paladin)
    47788,  --Guardian Spirit (Priest)
    31224,  --Cloak of Shadows (Rogue)
    210918, --Ethereal Form (Shaman)
    362486, --Tranquility (Druid PVP)

    --Death Knight
    48707,  --Anti-Magic Shell
    48792,  --Icebound Fortitude
    287081, --Lichborne
    55233,  --Vampiric Blood
    194679, --Rune Tap
    145629, --Anti-Magic Zone
    81256,  --Dancing Rune Weapon

    --Demon Hunter
    206804, --Rain from Above
    187827, --Metamorphosis (Vengeance)
    212800, --Blur
    263648, --Soul Barrier

    --Druid
    102342, --Ironbark
    22812,  --Barkskin
    61336,  --Survival Instincts

    --Hunter
    53480,  --Roar of Sacrifice
    264735, --Survival of the Fittest (Pet Ability)
    281195, --Survival of the Fittest (Lone Wolf)

    --Mage
    66,     --Invisibility
    198111, --Temporal Shield
    113862, --Greater Invisibility
    342246, --Alter Time (Arcane)
    110909, --Alter Time (Frost/Fire)
        108978,

    --Monk
    120954, --Fortifying Brew (Brewmaster)
    243435, --Fortifying Brew (Mistweaver)
    201318, --Fortifying Brew (Windwalker)
    115176, --Zen Meditation
    116849, --Life Cocoon
    122278, --Dampen Harm
    122783, --Diffuse Magic

    --Paladin
    204018, --Blessing of Spellwarding
    6940,   --Blessing of Sacrifice
    498,    --Divine Protection
    31850,  --Ardent Defender
    86659,  --Guardian of Ancient Kings
    205191, --Eye for an Eye

    --Priest
    47585,  --Dispersion
    33206,  --Pain Suppression
    213602, --Greater Fade
    81782,  --Power Word: Barrier
    271466, --Luminous Barrier
    20711,  --Spirit of Redemption

    --Rogue
    45182,  --Cheating Death
    5277,   --Evasion
    199754, --Riposte
    1966,   --Feint

    --Shaman
    108271, --Astral Shift
    118337, --Harden Skin

    --Warlock
    212195, --Nether Ward
    104773, --Unending Resolve
    108416, --Dark Pact

    --Warrior
    147833, --Intervene
    118038, --Die by the Sword
    871,    --Shield Wall
    213915, --Mass Spell Reflection
    23920,  --Spell Reflection (Prot)
    216890, --Spell Reflection (Arms/Fury)
    184364, --Enraged Regeneration
    97463,  --Rallying Cry
    12975,  --Last Stand
    190456, --Ignore Pain

    --Other
    1784,   --Stealth
    5215,   --Prowl
    185710, --Sugar-Crusted Fish Feast
    "Food",
    "Drink",
    "Food & Drink",
    "Refreshment",
}
