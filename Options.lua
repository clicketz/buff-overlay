local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local LibDialog = LibStub("LibDialog-1.0")

local GetSpellInfo = GetSpellInfo
local GetCVarBool = GetCVarBool
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local format = format
local next = next
local wipe = wipe
local pairs = pairs
local type = type
local tonumber = tonumber
local tostring = tostring
local Spell = Spell
local MAX_CLASSES = MAX_CLASSES
local CLASS_SORT_ORDER = CLASS_SORT_ORDER
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
-- local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

local spellDescriptions = {}

local customSpellDescriptions = {
    [362486] = 353114, -- Keeper of the Grove
}

local customIcons = {
    ["Eating/Drinking"] = 134062,
    ["?"] = 134400,
    ["Cogwheel"] = 136243,
}

local classIcons = {
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

local deleteSpellDelegate = {
    buttons = {
        {
            text = YES,
            on_click = function(self)
                local spellId = tonumber(self.data)

                BuffOverlay.db.global.customBuffs[spellId] = nil

                if BuffOverlay.defaultSpells[spellId] then
                    for k, v in pairs(BuffOverlay.defaultSpells[spellId]) do
                        BuffOverlay.db.profile.buffs[spellId][k] = v
                    end
                    BuffOverlay.db.profile.buffs[spellId].custom = nil
                    for barName in pairs(BuffOverlay.db.profile.bars) do
                        BuffOverlay.db.profile.buffs[spellId].enabled[barName] = false
                    end
                else
                    BuffOverlay.db.profile.buffs[spellId] = nil
                end

                if BuffOverlay.db.profile.buffs[spellId] and BuffOverlay.db.profile.buffs[spellId].children then
                    BuffOverlay.db.profile.buffs[spellId]:UpdateChildren()
                end

                BuffOverlay.options.args.customSpells.args[self.data] = nil
                BuffOverlay:UpdateSpellOptionsTable()
                BuffOverlay:RefreshOverlays()

                LibStub("AceConfigRegistry-3.0"):NotifyChange("BuffOverlay")
            end,
        },
        {
            text = NO,
        },
    },
    no_close_button = true,
    show_while_dead = true,
    hide_on_escape = true,
    on_show = function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:Raise()
    end,
}

LibDialog:Register("ConfirmEnableBlizzardCooldownText", {
    text = "In order for |cff83b2ffShow Blizzard Cooldown Text|r setting to work in BuffOverlay, cooldown text needs to be enabled in Blizzard settings. You can find this setting located at:\n\n|cffFFFF00Interface > ActionBars > Show Numbers for Cooldowns|r\n\nWould you like BuffOverlay to enable this setting for you?\n\n",
    buttons = {
        {
            text = YES,
            on_click = function()
                SetCVar("countdownForCooldowns", true)
                BuffOverlay.db.profile.showCooldownNumbers = true
                BuffOverlay:RefreshOverlays(true)

                LibStub("AceConfigRegistry-3.0"):NotifyChange("BuffOverlay")
            end,
        },
        {
            text = NO,
        },
    },
    no_close_button = true,
    show_while_dead = true,
    hide_on_escape = true,
    on_show = function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:Raise()
    end,
})

local function GetIconString(icon)
    return format("|T%s:0|t", icon)
end

local function GetSpells(class, barName)
    local spells = {}

    if next(BuffOverlay.db.profile.buffs) ~= nil then
        for k, v in pairs(BuffOverlay.db.profile.buffs) do
            -- Check if spell is valid for new db structure. If not, likely from old profile. Reset needed.
            if type(v) ~= "table" or not v.prio or not v.class then
                wipe(BuffOverlay.db.profile.buffs)
                BuffOverlay.print("Corrupted buff database found. This is likely due to updating from an older version of Buff Overlay. Resetting buff database to default. Your other settings (including custom buffs) will be preserved.")
                return
            end

            if not v.parent and (v.class == class) then
                local spellName, _, icon = GetSpellInfo(k)

                if customIcons[k] then
                    icon = customIcons[k]
                end

                local formattedName = spellName and format("%s %s", GetIconString(icon), spellName) or
                    icon and format("%s %s", GetIconString(icon), k) or tostring(k)

                if spellName then
                    local id = customSpellDescriptions[k] or k
                    local spell = Spell:CreateFromSpellID(id)
                    spell:ContinueOnSpellLoad(function()
                        spellDescriptions[k] = spell:GetSpellDescription()
                    end)
                end

                spells[tostring(k)] = {
                    name = formattedName,
                    type = "toggle",
                    desc = function()
                        local description = spellDescriptions[k] and spellDescriptions[k] ~= "" and
                            spellDescriptions[k] .. "\n" or ""

                        description = description .. format("\n|cffffd100Priority|r %d", v.prio)

                        local spellId = tonumber(k)
                        if spellId then
                            description = description .. format("\n|cffffd100Spell ID|r %d", spellId)
                            if BuffOverlay.db.profile.buffs[spellId].children then
                                description = description .. " |cffffd700 " .. "\nChild Spell ID(s)" .. "|r\n"
                                for child in pairs(BuffOverlay.db.profile.buffs[spellId].children) do
                                    description = description .. child .. "\n"
                                end
                            end
                        end

                        return description
                    end,
                    width = "full",
                    get = function()
                        return BuffOverlay.db.profile.buffs[k].enabled[barName] or false
                    end,
                    set = function(_, value)
                        BuffOverlay.db.profile.buffs[k].enabled[barName] = value
                        if BuffOverlay.db.profile.buffs[k].children then
                            for child in pairs(BuffOverlay.db.profile.buffs[k].children) do
                                BuffOverlay.db.profile.buffs[child].enabled[barName] = value
                            end
                        end
                        BuffOverlay:RefreshOverlays()
                    end,
                }
            end
        end
    end
    return spells
end

local function GetClasses(barName)
    local classes = {}
    classes["MISC"] = {
        name = format("%s Miscellaneous", GetIconString(customIcons["Cogwheel"])),
        order = 1,
        type = "group",
        args = GetSpells("MISC", barName),
        -- icon = "Interface\\Icons\\Trade_Engineering",
        -- iconCoords = nil,
    }

    for i = 1, MAX_CLASSES do
        local className = CLASS_SORT_ORDER[i]
        classes[className] = {
            -- format icons directly in case user is using a custom icon pack
            name = format("%s %s", GetIconString(classIcons[className]), LOCALIZED_CLASS_NAMES_MALE[className]),
            order = 0,
            type = "group",
            args = GetSpells(className, barName),
            -- icon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
            -- iconCoords = CLASS_ICON_TCOORDS[className],
        }
    end
    return classes
end

function BuffOverlay:UpdateSpellOptionsTable()
    for barName in pairs(self.db.profile.bars) do
        for k, v in pairs(GetClasses(barName)) do
            if self.options.args.bars.args[barName] then
                self.options.args.bars.args[barName].args.spells.args[k] = v
            end
        end
    end
end

function BuffOverlay:AddBarToOptions(bar, barName)
    self.options.args.bars.args[barName] = {
        name = bar.name or barName,
        type = "group",
        childGroups = "tab",
        args = {
            delete = {
                name = "Delete Bar",
                type = "execute",
                order = 1,
                width = 0.75,
                func = function()
                    BuffOverlay:DeleteBar(barName)
                end,
            },
            name = {
                name = "Set Bar Name",
                type = "input",
                order = 0,
                width = 1,
                get = function() return "" end,
                set = function(info, val)
                    bar[info[#info]] = val
                    self.options.args.bars.args[barName].name = val
                end,
            },
            space = {
                name = "",
                type = "description",
                order = 0.5,
                width = 0.1,
            },
            settings = {
                name = "Settings",
                type = "group",
                order = 1,
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    if InCombatLockdown() then
                        self.print("Cannot change settings in combat.")
                        return
                    end
                    bar[info[#info]] = val
                    self:RefreshOverlays(true)
                end,
                args = {
                    iconCount = {
                        order = 1,
                        name = "Icon Count",
                        type = "range",
                        width = 1.5,
                        desc = "Number of icons you want to display (per frame).",
                        min = 1,
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
                        width = 1,
                        desc = "Scale the size of the icon. Base icon size is proportionate to its parent frame.",
                        min = 0.01,
                        max = 99,
                        softMax = 3,
                        step = 0.01,
                    },
                    cooldownNumberScale = {
                        order = 4,
                        name = "Cooldown Text Scale",
                        type = "range",
                        width = 1,
                        desc = "Scale the icon's cooldown text size.",
                        min = 0.01,
                        max = 10,
                        softMax = 3,
                        step = 0.01,
                        disabled = function() return not bar.showCooldownNumbers end,
                    },
                    iconSpacing = {
                        order = 5,
                        name = "Icon Spacing",
                        type = "range",
                        width = 1,
                        desc = "Spacing between icons. Spacing is scaled based on icon size for uniformity across different icon sizes.",
                        min = 0,
                        max = 200,
                        softMax = 20,
                        step = 1,
                    },
                    iconBorder = {
                        order = 6,
                        name = "Icon Border",
                        type = "toggle",
                        width = 0.75,
                        desc = "Adds a pixel border around the icon. This will also zoom the icon in slightly to remove any default borders that may be present.",
                    },
                    iconBorderColor = {
                        order = 7,
                        name = "Icon Border Color",
                        type = "color",
                        width = 0.75,
                        desc = "Change the icon border color.",
                        hasAlpha = true,
                        disabled = function() return not bar.iconBorder end,
                        get = function(info)
                            local t = bar[info[#info]]
                            return t.r, t.g, t.b, t.a
                        end,
                        set = function(info, r, g, b, a)
                            local t = bar[info[#info]]
                            t.r, t.g, t.b, t.a = r, g, b, a
                            self:RefreshOverlays(true)
                        end,
                    },
                    iconBorderSize = {
                        order = 8,
                        name = "Icon Border Size",
                        type = "range",
                        width = 1.5,
                        desc = "Change the icon border size (in pixels).",
                        min = 1,
                        max = 10,
                        softMax = 5,
                        step = 1,
                        disabled = function() return not bar.iconBorder end,
                    },
                    showCooldownSpiral = {
                        order = 9,
                        name = "Cooldown Spiral",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the cooldown spiral.",
                    },
                    showCooldownNumbers = {
                        order = 10,
                        name = "Show Blizzard Cooldown Text",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the cooldown text.",
                        get = function(info)
                            if not GetCVarBool("countdownForCooldowns") and bar[info[#info]] then
                                bar[info[#info]] = false
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("BuffOverlay")
                            end
                            return bar[info[#info]]
                        end,
                        set = function(info, val)
                            if InCombatLockdown() then
                                self.print("Cannot change settings in combat.")
                                return
                            end

                            if val and not GetCVarBool("countdownForCooldowns") then
                                LibDialog:Spawn("ConfirmEnableBlizzardCooldownText")
                            else
                                bar[info[#info]] = val
                                self:RefreshOverlays(true)
                            end
                        end,
                    },
                },
            },
            anchoring = {
                name = "Anchoring",
                order = 2,
                type = "group",
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    if InCombatLockdown() then
                        self.print("Cannot change settings in combat.")
                        return
                    end
                    bar[info[#info]] = val
                    self:RefreshOverlays(true)
                end,
                args = {
                    iconAnchor = {
                        order = 1,
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
                        order = 2,
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
                        order = 3,
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
                        order = 4,
                        name = "X-Offset",
                        type = "range",
                        width = 1.5,
                        desc = "Change the icon group's X-Offset.",
                        min = -100,
                        max = 100,
                        step = 1,
                    },
                    iconYOff = {
                        order = 5,
                        name = "Y-Offset",
                        type = "range",
                        width = 1.5,
                        desc = "Change the icon group's Y-Offset.",
                        min = -100,
                        max = 100,
                        step = 1,
                    },
                },
            },
            spells = {
                order = 3,
                name = "Spells",
                type = "group",
                args = {
                    enableAll = {
                        order = 1,
                        name = "Enable All",
                        type = "execute",
                        width = 0.75,
                        desc = "Enable all spells.",
                        func = function()
                            for k in pairs(self.db.profile.buffs) do
                                self.db.profile.buffs[k].enabled[barName] = true
                            end
                            self:RefreshOverlays()
                        end,
                    },
                    disableAll = {
                        order = 2,
                        name = "Disable All",
                        type = "execute",
                        width = 0.75,
                        desc = "Disable all spells.",
                        func = function()
                            for k in pairs(self.db.profile.buffs) do
                                self.db.profile.buffs[k].enabled[barName] = false
                            end
                            self:RefreshOverlays()
                        end,
                    },
                    space4 = {
                        order = 3,
                        name = "\n",
                        type = "description",
                        width = "full",
                    },
                },
            }
        }
    }
    self:UpdateSpellOptionsTable()
end

function BuffOverlay:UpdateBarOptions()
    local options = self.options.args.bars.args

    for opt in pairs(options) do
        if opt ~= "addBar" then
            options[opt] = nil
        end
    end

    for name, bar in pairs(self.db.profile.bars) do
        self:AddBarToOptions(bar, name)
    end

    self:UpdateSpellOptionsTable()
end

local customSpellInfo = {
    spellId = {
        order = 1,
        type = "description",
        width = "full",
        name = function(info)
            local spellId = tonumber(info[#info - 1])
            local str = "|cffffd700" .. "Spell ID" .. "|r " .. spellId
            if BuffOverlay.db.profile.buffs[spellId].children then
                str = str .. " |cffffd700 " .. "\n\nChild Spell ID(s)" .. "|r\n"
                for child in pairs(BuffOverlay.db.profile.buffs[spellId].children) do
                    str = str .. child .. "\n"
                end
            end
            return str .. "\n\n"
        end,
    },
    delete = {
        order = 2,
        type = "execute",
        name = "Delete",
        width = 1,
        func = function(info)
            local spellId = tonumber(info[#info - 1])
            local spellName, _, icon = GetSpellInfo(spellId)
            local text = format("Are you sure you want to delete\n\n%s %s?\n\n", GetIconString(icon), spellName)
            if BuffOverlay.defaultSpells[spellId] then
                text = text ..
                    "(|cff9b6ef3Note|r: This is a default spell. Deleting it from this tab will simply reset all its values to default and disable it, but it will not be removed from the spells tab.)"
            end
            deleteSpellDelegate.text = text

            LibDialog:Spawn(deleteSpellDelegate, info[#info - 1])
        end,
    },
    header1 = {
        order = 3,
        name = "",
        type = "header",
    },
    class = {
        order = 4,
        type = "select",
        name = "Class",
        values = function()
            local classes = {}
            classes["MISC"] = format("%s Miscellaneous", GetIconString(customIcons["Cogwheel"]))
            for i = 1, MAX_CLASSES do
                local className = CLASS_SORT_ORDER[i]
                local icon = classIcons[className] or customIcons["?"]
                classes[className] = format("%s %s", GetIconString(icon), LOCALIZED_CLASS_NAMES_MALE[className])
            end
            return classes
        end,
        set = function(info, state)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            BuffOverlay.db.global.customBuffs[spellId][option] = state
            BuffOverlay.db.profile.buffs[spellId][option] = state
            if BuffOverlay.db.profile.buffs[spellId].children then
                BuffOverlay.db.profile.buffs[spellId]:UpdateChildren()
            end
            BuffOverlay:UpdateSpellOptionsTable()
        end,
    },
    space = {
        order = 5,
        name = "\n\n",
        type = "description",
        width = "full",
    },
    prio = {
        order = 6,
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
            if BuffOverlay.db.profile.buffs[spellId].children then
                BuffOverlay.db.profile.buffs[spellId]:UpdateChildren()
            end
            BuffOverlay:RefreshOverlays()
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
    spellId_info = {
        order = 1,
        type = "description",
        name = "In addition to adding new spells here, you can also add any Spell ID from the spells tab to edit its default values.\n(Note: anything you add here will persist through addon updates and profile resets.)",
    },
    spellId = {
        order = 2,
        name = "Spell ID",
        desc = "Enter the spell ID of the spell you want to keep track of.",
        type = "input",
        set = function(_, state)
            local spellId = tonumber(state)

            if BuffOverlay.db.profile.buffs[spellId] and BuffOverlay.db.profile.buffs[spellId].parent then
                spellId = BuffOverlay.db.profile.buffs[spellId].parent
            end

            local name, _, icon = GetSpellInfo(spellId)

            if name then
                if BuffOverlay:InsertBuff(spellId) then
                    BuffOverlay.options.args.customSpells.args[tostring(spellId)] = {
                        name = format("%s %s", GetIconString(icon), name),
                        desc = function()
                            return spellDescriptions[spellId] or ""
                        end,
                        type = "group",
                        args = customSpellInfo,
                    }
                    BuffOverlay:UpdateCustomBuffs()
                else
                    BuffOverlay.print(format("%s %s is already being tracked.", GetIconString(icon) or customIcons["?"],
                        name))
                end
            else
                BuffOverlay.print(format("Invalid Spell ID |cffffd700%s|r", state))
            end
        end,
    }
}

function BuffOverlay:Options()
    for spellId in pairs(self.db.global.customBuffs) do
        customSpells[tostring(spellId)] = {
            name = format("%s %s", GetIconString(select(3, GetSpellInfo(spellId))), GetSpellInfo(spellId)),
            desc = function()
                return spellDescriptions[spellId] or ""
            end,
            type = "group",
            args = customSpellInfo,
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
                name = "Toggle Test Auras",
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
                end,
            },
            bars = {
                name = "Bars",
                type = "group",
                childGroups = "tab",
                order = 5.5,
                args = {
                    addBar = {
                        order = 1,
                        name = "Add Bar",
                        type = "execute",
                        width = 0.75,
                        func = function()
                            self:AddBar()
                        end,
                    },
                },
            },
            customSpells = {
                order = 7,
                name = "Custom Spells",
                type = "group",
                args = customSpells,
                get = function(info)
                    local option = info[#info]
                    local spellId = info[#info - 1]
                    spellId = tonumber(spellId)
                    if not spellId then return end
                    return self.db.global.customBuffs[spellId][option]
                end,
            },
        },
    }

    -- Main options dialog.
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BuffOverlay", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BuffOverlay", "BuffOverlay")
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("BuffOverlay", 630, 590)
end
