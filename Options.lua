local GetSpellInfo = GetSpellInfo
local format = format
local Spell = Spell
local MAX_CLASSES = MAX_CLASSES
local CLASS_SORT_ORDER = CLASS_SORT_ORDER

local function GetSpells(class)
    local spells = {}
    local descr = {}

    if BuffOverlay.db.profile.buffs then
        for k, v in pairs(BuffOverlay.db.profile.buffs) do
            if not v.child and (v.class == class) then
                local spellName, _, icon = GetSpellInfo(k)
                local formattedName = spellName and format("|T%s:0|t %s", icon, spellName) or tostring(k)

                if spellName then
                    local s = Spell:CreateFromSpellID(k)
                    s:ContinueOnSpellLoad(function()
                        descr[k] = s:GetSpellDescription()
                    end)
                end

                spells[tostring(k)] = {
                    name = formattedName,
                    type = "toggle",
                    desc = descr[k] or "",
                    width = "full",
                    get = function()
                        return BuffOverlay.db.profile.buffs[k].enabled or false
                    end,
                    set = function(_, value)
                        BuffOverlay.db.profile.buffs[k].enabled = value
                        if BuffOverlay.db.profile.buffs[k].children then
                            for child, _ in pairs(BuffOverlay.db.profile.buffs[k].children) do
                                BuffOverlay.db.profile.buffs[child].enabled = value
                            end
                        end
                        BuffOverlay:Refresh()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("BuffOverlay")
                    end,
                }
            end
        end
    end
    return spells
end

function BuffOverlay_GetClasses()
    local classes = {}
    classes["MISC"] = {
        name = "Miscellaneous",
        order = 1,
        type = "group",
        args = GetSpells("MISC"),
        icon = "Interface\\Icons\\Trade_Engineering",
        iconCoords = nil,
    }

    for i = 1, MAX_CLASSES do
        classes[CLASS_SORT_ORDER[i]] = {
            name = LOCALIZED_CLASS_NAMES_MALE[CLASS_SORT_ORDER[i]],
            order = 0,
            type = "group",
            args = GetSpells(CLASS_SORT_ORDER[i]),
            icon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
            iconCoords = CLASS_ICON_TCOORDS[CLASS_SORT_ORDER[i]],
        }
    end
    return classes
end

local customSpellInfo = {
    spellId = {
        order = 1,
        type = "description",
        name = function(info)
            local spellId = info[#info - 1]
            return "|cffffd700 " .. "Spell ID" .. "|r " .. spellId .. "\n"
        end,
    },
    delete = {
        order = 2,
        type = "execute",
        name = "Delete",
        confirm = true,
        confirmText = "Are you sure you want to delete this spell?",
        func = function(info)
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            BuffOverlay.db.global.customBuffs[spellId] = nil
            if not BuffOverlay.defaultSpells[spellId] then
                BuffOverlay.db.profile.buffs[spellId] = nil
            end
            info.options.args.customSpells.args[info[#info - 1]] = nil
            BuffOverlay:UpdateCustomBuffs()
        end,
    },
    class = {
        order = 3,
        type = "select",
        name = "Class",
        values = function()
            local classes = {}
            classes["MISC"] = "Miscellaneous"
            for i = 1, MAX_CLASSES do
                classes[CLASS_SORT_ORDER[i]] = LOCALIZED_CLASS_NAMES_MALE[CLASS_SORT_ORDER[i]]
            end
            return classes
        end,
        set = function(info, state)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            BuffOverlay.db.global.customBuffs[spellId][option] = state
            BuffOverlay:UpdateCustomBuffs()
        end,
    },
    prio = {
        order = 4,
        type = "range",
        name = "Priority (Lower is Higher Prio)",
        min = 1,
        max = 100,
        step = 1,
        set = function(info, state)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            BuffOverlay.db.global.customBuffs[spellId][option] = state
            BuffOverlay.db.profile.buffs[spellId][option] = state
            -- BuffOverlay:UpdateCustomBuffs()
        end,
        get = function(info)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            local value = BuffOverlay.db.global.customBuffs[spellId][option]
            if not value then return 100 end
            return BuffOverlay.db.global.customBuffs[spellId][option]
        end,
    },
}

local customSpells = {
    spellId = {
        name = "Spell ID",
        type = "input",
        set = function(info, state)
            local spellId = tonumber(state)
            local name = GetSpellInfo(spellId)
            local custom = BuffOverlay.db.global.customBuffs
            if custom[spellId] then return end

            if spellId and name then
                if BuffOverlay:InsertBuff(spellId) then
                    BuffOverlay.options.args.customSpells.args[tostring(spellId)] = {
                        name = name,
                        type = "group",
                        childGroups = "tab",
                        args = customSpellInfo,
                        icon = GetSpellTexture(spellId),
                    }
                    BuffOverlay:UpdateCustomBuffs()
                end
            end
        end,
    }
}

function BuffOverlay:Options()
    for spellId, _ in pairs(BuffOverlay.db.global.customBuffs) do
        customSpells[tostring(spellId)] = {
            name = GetSpellInfo(spellId),
            type = "group",
            childGroups = "tab",
            args = customSpellInfo,
            icon = GetSpellTexture(spellId),
        }
    end
    self.options = {
        name = "BuffOverlay",
        descStyle = "inline",
        type = "group",
        plugins = { profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) } },
        childGroups = "tab",
        args = {
            author = {
                order = 1,
                name = "|cffffd700" .. "Author:" .. "|r " .. GetAddOnMetadata("BuffOverlay", "Author") .. "\n",
                type = "description",
                cmdHidden = true
            },
            vers = {
                order = 2,
                name = "|cffffd700" .. "Version:" .. "|r " .. GetAddOnMetadata("BuffOverlay", "Version") .. "\n\n",
                type = "description",
                cmdHidden = true
            },
            test = {
                order = 3,
                name = "Toggle Test Buffs",
                type = "execute",
                func = "Test",
                handler = BuffOverlay
            },
            welcomeMessage = {
                order = 4,
                name = "Welcome Message",
                type = "toggle",
                width = "full",
                desc = "Toggle showing of the welcome message on login.",
                get = function(info) return self.db.profile[info[#info]] end,
                set = function(info, val)
                    self.db.profile[info[#info]] = val
                    self:Refresh()
                end,
            },
            layout = {
                order = 5,
                name = "Settings",
                type = "group",
                get = function(info) return self.db.profile[info[#info]] end,
                set = function(info, val)
                    if InCombatLockdown() then
                        self.print("Cannot change settings in combat.")
                        return
                    end
                    self.db.profile[info[#info]] = val
                    self:Refresh()
                end,
                args = {
                    iconCount = {
                        order = 1,
                        name = "Icon Count",
                        type = "range",
                        width = 1.5,
                        desc = "Number of icons you want to display (per frame).",
                        min = 0,
                        max = 40,
                        softMax = 10,
                        step = 1,
                    },
                    iconAlpha = {
                        order = 2,
                        name = "Icon Alpha",
                        type = "range",
                        width = 1.5,
                        desc = "Icon transparency.",
                        min = 0,
                        max = 1,
                        step = 0.01,
                    },
                    iconScale = {
                        order = 3,
                        name = "Icon Scale",
                        type = "range",
                        width = 1.5,
                        desc = "The scale of the icon based on the size of the default icons on raidframe.",
                        min = 0.01,
                        max = 99,
                        softMax = 3,
                        step = 0.01,
                    },
                    cooldownNumberScale = {
                        order = 4,
                        name = "Cooldown Text Scale",
                        type = "range",
                        width = 1.5,
                        desc = "Scale the icon's cooldown text size.",
                        min = 0.01,
                        max = 10,
                        softMax = 2,
                        step = 0.01,
                    },
                    iconAnchor = {
                        order = 5,
                        name = "Icon Anchor",
                        type = "select",
                        style = "dropdown",
                        width = 1,
                        desc = "Where the anchor is on the icon.",
                        values = {
                            ["TOPLEFT"] = "TOPLEFT",
                            ["TOPRIGHT"] = "TOPRIGHT",
                            ["BOTTOMLEFT"] = "BOTTOMLEFT",
                            ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
                            ["TOP"] = "TOP",
                            ["BOTTOM"] = "BOTTOM",
                            ["RIGHT"] = "RIGHT",
                            ["LEFT"] = "LEFT",
                            ["CENTER"] = "CENTER",
                        },
                    },
                    iconRelativePoint = {
                        order = 6,
                        name = "Frame Attachment Point",
                        type = "select",
                        style = "dropdown",
                        width = 1,
                        desc = "Icon position relative to its parent frame.",
                        values = {
                            ["TOPLEFT"] = "TOPLEFT",
                            ["TOPRIGHT"] = "TOPRIGHT",
                            ["BOTTOMLEFT"] = "BOTTOMLEFT",
                            ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
                            ["TOP"] = "TOP",
                            ["BOTTOM"] = "BOTTOM",
                            ["RIGHT"] = "RIGHT",
                            ["LEFT"] = "LEFT",
                            ["CENTER"] = "CENTER",
                        },
                    },
                    growDirection = {
                        order = 7,
                        name = "Grow Direction",
                        type = "select",
                        style = "dropdown",
                        width = 1,
                        desc = "Where the icons will grow from the first icon.",
                        values = {
                            ["DOWN"] = "DOWN",
                            ["UP"] = "UP",
                            ["LEFT"] = "LEFT",
                            ["RIGHT"] = "RIGHT",
                            ["HORIZONTAL"] = "HORIZONTAL",
                            ["VERTICAL"] = "VERTICAL",
                        },
                    },
                    iconXOff = {
                        order = 8,
                        name = "X-Offset",
                        type = "range",
                        width = 1.5,
                        desc = "Change the icon group's X-Offset.",
                        min = -100,
                        max = 100,
                        step = 1,
                    },
                    iconYOff = {
                        order = 9,
                        name = "Y-Offset",
                        type = "range",
                        width = 1.5,
                        desc = "Change the icon group's Y-Offset.",
                        min = -100,
                        max = 100,
                        step = 1,
                    },
                    showCooldownSpiral = {
                        order = 10,
                        name = "Cooldown Spiral",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the cooldown spiral.",
                    },
                    showCooldownNumbers = {
                        order = 11,
                        name = "Show Blizzard Cooldown Text",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the cooldown text. Note that you must also enable the 'Show Numbers for Cooldown' in Blizzard settings."
                    },
                }
            },
            spells = {
                order = 6,
                name = "Spells",
                type = "group",
                args = BuffOverlay_GetClasses(),
            },
            customSpells = {
                order = 7,
                name = "Custom Spells",
                type = "group",
                args = customSpells,
                set = function(info, state)
                    local option = info[#info]
                    local spellId = info[#info - 1]
                    spellId = tonumber(spellId)
                    BuffOverlay.db.global.customBuffs[spellId][option] = state
                    BuffOverlay:UpdateCustomBuffs()
                end,
                get = function(info)
                    local option = info[#info]
                    local spellId = info[#info - 1]
                    spellId = tonumber(spellId)
                    if not spellId then return end
                    return BuffOverlay.db.global.customBuffs[spellId][option]
                end,
            },
        }
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("BuffOverlay", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BuffOverlay", "BuffOverlay")
end
