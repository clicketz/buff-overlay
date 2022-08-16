BuffOverlay = LibStub("AceAddon-3.0"):NewAddon("BuffOverlay", "AceConsole-3.0")

--Higher in spellList = higher shown priority

BuffOverlay.defaultSpells = {
    --High Priority

    --Immunities
    45438,  --Ice Block (Mage)
    642,    --Divine Shield (Paladin)
        498,
        1020,
        5573,
    1022,   --Blessing of Protection (Paladin)
        5599,
        10278,
    19753,  --Divine Intervention

    --Druid
    22812,  --Barkskin

    --Hunter
    19263,  --Deterrence

    --Mage
    543,    --Fire Ward
        8457,
        8458,
        10223,
        10225,
    6143,   --Frost Ward
        8461,
        8462,
        10177,
        28609,

    --Paladin
    6940,   --Blessing of Sacrifice
        20729,

    --Priest
    33206,  --Pain Suppression

    --Rogue
    45182,  --Cheating Death
    31224,  --Cloak of Shadows
    5277,   --Evasion
        26669,

    --Shaman
    30823,  --Shamanistic Rage

    --Warlock
    6229,   --Shadow Ward
        11739,
        11740,
        28610,
    7812,  --Sacrifice (Voidwalker)
        19438,
        19440,
        19441,
        19442,
        19443,

    --Warrior
    12975,  --Last Stand
    871,    --Shield Wall
    23920,  --Spell Reflection
    3411,   --Intervene

    --Racials
    20594,  --Stoneform
    20580,  --Shadowmeld

    --Other
    1784,   --Stealth
        1785,
        1786,
        1787,
    5215,   --Prowl
        6783,
        9913,
    "Food",
    "Drink",
    "Food & Drink",
    "Refreshment",
}
