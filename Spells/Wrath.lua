if WOW_PROJECT_ID ~= WOW_PROJECT_WRATH_CLASSIC then return end

---@class BuffOverlay: AceModule
local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local L = BuffOverlay.L

--[[------------------------------------------------

 If you are editing this file, you should be aware
 that everything can now be done from the in-game
 interface, including adding custom buffs.

 Use the /buffoverlay or /bo command.

------------------------------------------------]]
-- Lower prio = shown above other buffs
BuffOverlay.defaultSpells = {
    -- Death Knight
    [48707] = { class = "DEATHKNIGHT", prio = 50 }, --Anti-Magic Shell
    [47484] = { class = "DEATHKNIGHT", prio = 50 }, --Huddle (Ghoul)
    [48792] = { class = "DEATHKNIGHT", prio = 50 }, --Icebound Fortitude
    [50461] = { class = "DEATHKNIGHT", prio = 50 }, --Anti-Magic Zone

    -- Druid
    [22812] = { class = "DRUID", prio = 50 }, --Barkskin
    [22842] = { class = "DRUID", prio = 50 }, --Frenzied Regeneration
    [61336] = { class = "DRUID", prio = 50 }, --Survival Instincts
    [5215] = { class = "DRUID", prio = 70 },  --Prowl

    -- Hunter
    --[34471] = {class = "HUNTER"}, --The Beast Within
    [19263] = { class = "HUNTER", prio = 10 }, --Deterrence
    [1742] = { class = "HUNTER", prio = 50 },  --Cower (Pet)
    [26064] = { class = "HUNTER", prio = 50 }, --Shell Shield (Pet)
    [53476] = { class = "HUNTER", prio = 50 }, --Intervene (Pet)
    [53480] = { class = "HUNTER", prio = 50 }, --Roar of Sacrifice (Pet)

    -- Mage
    [45438] = { class = "MAGE", prio = 10 }, --Ice Block
    [41425] = { class = "MAGE", prio = 20 }, --Hypothermia
    [66] = { class = "MAGE", prio = 50 },    --Invisibility
        [32612] = { parent = 66 },
    [543] = { class = "MAGE", prio = 50 },   --Fire Ward
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
    [642] = { class = "PALADIN", prio = 10 },  --Divine Shield
    [1022] = { class = "PALADIN", prio = 10 }, --Blessing of Protection
        [5599] = { parent = 1022 },
        [10278] = { parent = 1022 },
    [19753] = { class = "PALADIN", prio = 10 }, --Divine Intervention
    [25771] = { class = "PALADIN", prio = 20 }, --Forbearance
    [498] = { class = "PALADIN", prio = 50 },   --Divine Protection
    [31821] = { class = "PALADIN", prio = 50 }, --Aura Mastery
    [31852] = { class = "PALADIN", prio = 50 }, --Ardent Defender
    [64205] = { class = "PALADIN", prio = 50 }, --Divine Sacrifice

    -- Priest
    [47788] = { class = "PRIEST", prio = 10 }, --Guardian Spirit
    [27827] = { class = "PRIEST", prio = 10 }, --Spirit of Redemption
    [47585] = { class = "PRIEST", prio = 50 }, --Dispersion
    [33206] = { class = "PRIEST", prio = 50 }, --Pain Suppression

    -- Rogue
    [31224] = { class = "ROGUE", prio = 10 }, --Cloak of Shadows
    [45182] = { class = "ROGUE", prio = 50 }, --Cheating Death
    [5277] = { class = "ROGUE", prio = 50 },  --Evasion
        [26669] = { parent = 5277 },
    [14278] = { class = "ROGUE", prio = 50 }, --Ghostly Strike
    [1784] = { class = "ROGUE", prio = 70 },  --Stealth

    -- Shaman
    [30823] = { class = "SHAMAN", prio = 50 }, --Shamanistic Rage
    [8178] = { class = "SHAMAN", prio = 50 },  --Grounding Totem

    -- Warlock
    [6229] = { class = "WARLOCK", prio = 50 }, --Shadow Ward
        [11739] = { parent = 6229 },
        [11740] = { parent = 6229 },
        [28610] = { parent = 6229 },
    [7812] = { class = "WARLOCK", prio = 50 }, --Voidwalker Sac
        [19438] = { parent = 7812 },
        [19440] = { parent = 7812 },
        [19441] = { parent = 7812 },
        [19442] = { parent = 7812 },
        [19443] = { parent = 7812 },

    -- Warrior
    [46924] = { class = "WARRIOR", prio = 10 }, --Bladestorm
    [2565] = { class = "WARRIOR", prio = 50 },  --Shield Block
    [3411] = { class = "WARRIOR", prio = 50 },  --Intervene
    [12975] = { class = "WARRIOR", prio = 50 }, --Last Stand
    [20230] = { class = "WARRIOR", prio = 50 }, --Retaliation
    [871] = { class = "WARRIOR", prio = 50 },   --Shield Wall
    [23920] = { class = "WARRIOR", prio = 50 }, --Spell Reflection

    -- Racials
    [58984] = { class = "MISC", prio = 70 }, --Shadowmeld

    -- Misc
    [L["Eating/Drinking"]] = { class = "MISC", prio = 90 },      --Food umbrella
        [L["Food & Drink"]] = { parent = L["Eating/Drinking"] }, --Food & Drink
        [L["Food"]] = { parent = L["Eating/Drinking"] },         --Food
        [L["Drink"]] = { parent = L["Eating/Drinking"] },        --Drink
        [L["Refreshment"]] = { parent = L["Eating/Drinking"] },  --Refreshment
    [30456] = { class = "MISC", prio = 10 },                     --Nigh-Invulnerability
}
