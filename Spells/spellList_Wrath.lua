BuffOverlay = LibStub("AceAddon-3.0"):NewAddon("BuffOverlay", "AceConsole-3.0")

--Higher in spellList = higher shown priority

BuffOverlay.defaultSpells = {
    --High Priority

    --Immunities
    19263, --Deterrence (Hunter)
    --34471, --The Beast Within (Hunter)
    45438,  --Ice Block (Mage)
    642,    --Divine Shield (Paladin)
        498,
        1020,
        5573,
    1022,   --Blessing of Protection (Paladin)
        5599,
        10278,
    19753,  --Divine Intervention (Paladin)
    47788,  --Guardian Spirit (Priest)
    31224,  --Cloak of Shadows (Rogue)
    30456,  --Nigh-Invulnerability
    46924,  --Bladestorm (Warrior)

    --Death Knight
    48707,  --Anti-Magic Shell
    47484,  --Huddle (Ghoul)
    48792,  --Icebound Fortitude
    50461,  --Anti-Magic Zone

    --Druid
    102342, --Ironbark
    22812,  --Barkskin
    22842,  --Frenzied Regeneration
    61336,  --Survival Instincts

    --Hunter
    1742,   --Cower (Pet)
    26064,  --Shell Shield (Pet)
    53476,  --Intervene (Pet)
    53480,  --Roar of Sacrifice (Pet)

    --Mage
    66,     --Invisibility
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
    31821,  --Aura Mastery
    31852,  --Ardent Defender
    64205,  --Divine Sacrifice

    --Priest
    20711,  --Spirit of Redemption
    47585,  --Dispersion
    33206,  --Pain Suppression

    --Rogue
    45182,  --Cheating Death
    5277,   --Evasion
        26669,
    14278,  --Ghostly Strike

    --Shaman
    30823,  --Shamanistic Rage

    --Warlock
    6229,   --Shadow Ward
        11739,
        11740,
        28610,
    7812,   --Voidwalker Sac
        19438,
        19440,
        19441,
        19442,
        19443,
    30300,  --Nether Protection


    --Warrior
    2565,   --Shield Block
    3411,   --Intervene
    12975,  --Last Stand
    20230,  --Retaliation
    871,    --Shield Wall
    23920,  --Spell Reflection

    --Other
    1784,   --Stealth
    5215,   --Prowl
    "Food",
    "Drink",
    "Food & Drink",
    "Refreshment",
}
