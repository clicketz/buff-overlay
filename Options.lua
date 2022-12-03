local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local LibDialog = LibStub("LibDialog-1.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local version = GetAddOnMetadata("BuffOverlay", "Version")

local GetSpellInfo = GetSpellInfo
local GetCVarBool = GetCVarBool
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local CopyTable = CopyTable
local format = format
local next = next
local wipe = wipe
local pairs = pairs
local type = type
local tonumber = tonumber
local tostring = tostring
local Spell = Spell
local MAX_CLASSES = MAX_CLASSES
local CLASS_SORT_ORDER = CopyTable(CLASS_SORT_ORDER)
do
    -- Why oh why is this "sort order" table not actually sorted Blizzard?
    table.sort(CLASS_SORT_ORDER)
end
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local spellDescriptions = {}
local optionsDisabled = {}

local customSpellDescriptions = {
    [362486] = 353114, -- Keeper of the Grove
}

local customSpellNames = {
    [228050] = "Guardian of the Forgotten Queen",
}

BuffOverlay.customIcons = {
    ["Eating/Drinking"] = 134062,
    ["?"] = 134400,
    ["Cogwheel"] = 136243,
}

local customIcons = BuffOverlay.customIcons

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
                if not spellId then return end

                if BuffOverlay.db.profile.buffs[spellId].children then
                    for childId in pairs(BuffOverlay.db.profile.buffs[spellId].children) do
                        if BuffOverlay.db.global.customBuffs[childId] then
                            BuffOverlay.db.profile.buffs[childId] = nil
                            BuffOverlay.db.profile.buffs[spellId].children[childId] = nil
                        end
                    end

                    if next(BuffOverlay.db.profile.buffs[spellId].children) == nil then
                        BuffOverlay.db.profile.buffs[spellId].children = nil
                        BuffOverlay.db.profile.buffs[spellId].UpdateChildren = nil
                    end
                end

                BuffOverlay.db.global.customBuffs[spellId] = nil

                for id, spell in pairs(BuffOverlay.db.global.customBuffs) do
                    if spell.parent and spell.parent == spellId then
                        BuffOverlay.db.global.customBuffs[id] = nil
                    end
                end

                if BuffOverlay.defaultSpells[spellId] then
                    for k, v in pairs(BuffOverlay.defaultSpells[spellId]) do
                        if type(v) == "table" then
                            BuffOverlay.db.profile.buffs[spellId][k] = CopyTable(v)
                        else
                            BuffOverlay.db.profile.buffs[spellId][k] = v
                        end
                    end
                    BuffOverlay.db.profile.buffs[spellId].custom = nil
                    -- for barName in pairs(BuffOverlay.db.profile.bars) do
                    --     BuffOverlay.db.profile.buffs[spellId].enabled[barName] = false
                    -- end
                else
                    BuffOverlay.db.profile.buffs[spellId] = nil
                end

                if BuffOverlay.db.profile.buffs[spellId] and BuffOverlay.db.profile.buffs[spellId].children then
                    BuffOverlay.db.profile.buffs[spellId]:UpdateChildren()
                end

                BuffOverlay.options.args.customSpells.args[self.data] = nil
                if AceConfigDialog.OpenFrames["BuffOverlayDialog"] then
                    BuffOverlay.priorityListDialog.args[self.data] = nil
                    AceRegistry:NotifyChange("BuffOverlayDialog")
                end
                BuffOverlay:UpdateSpellOptionsTable()
                BuffOverlay:RefreshOverlays()

                AceRegistry:NotifyChange("BuffOverlay")
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

local function IsDifferentDialogBar(barName)
    return BuffOverlay.priorityListDialog.args.bar.name ~= barName
end

local deleteBarDelegate = {
    buttons = {
        {
            text = YES,
            on_click = function(self)
                local barName = self.data
                BuffOverlay:DeleteBar(barName)

                if AceConfigDialog.OpenFrames["BuffOverlayDialog"] and not IsDifferentDialogBar(barName) then
                    AceConfigDialog:Close("BuffOverlayDialog")
                end

                AceRegistry:NotifyChange("BuffOverlay")
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

-- Change the path for the new options menu in 10.0
local path = isRetail and "Options > Gameplay > Action Bars > Show Numbers for Cooldowns" or "Interface > ActionBars > Show Numbers for Cooldowns"

LibDialog:Register("ConfirmEnableBlizzardCooldownText", {
    text = format("In order for %s setting to work in BuffOverlay, cooldown text needs to be enabled in Blizzard settings. You can find this setting located at:\n\n%s\n\nWould you like BuffOverlay to enable this setting for you?\n\n", BuffOverlay:Colorize("Show Blizzard Cooldown Text", "main"), BuffOverlay:Colorize(path)),
    buttons = {
        {
            text = YES,
            on_click = function(self)
                local bar = self.data

                SetCVar("countdownForCooldowns", true)
                bar.showCooldownNumbers = true
                BuffOverlay:RefreshOverlays(true)

                AceRegistry:NotifyChange("BuffOverlay")
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

LibDialog:Register("ShowVersion", {
    text = format("%s\nCopy this version number and send it to the author if you need help with a bug.", BuffOverlay:Colorize("Version", "main")),
    buttons = {
        {
            text = OKAY,
        },
    },
    editboxes = {
        {
            auto_focus = false,
            text = format("%s", version),
            width = 200,
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

function BuffOverlay:ShowVersion()
    LibDialog:Spawn("ShowVersion")
end

function BuffOverlay:GetIconString(icon, iconSize)
    local size = iconSize or 0
    local ltTexel = 0.08 * 256
    local rbTexel = 0.92 * 256

    if not icon then
        icon = customIcons["?"]
    end

    return format("|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t", icon, size, size, ltTexel, rbTexel, ltTexel, rbTexel)
end

local function AddToPriorityDialog(spellIdStr, remove)
    local list = BuffOverlay.priorityListDialog.args
    local spellId = tonumber(spellIdStr) or spellIdStr
    local spell = BuffOverlay.db.profile.buffs[spellId]
    local spellName, _, icon = GetSpellInfo(spellId)

    if not spell then return end

    if customIcons[spellId] then
        icon = customIcons[spellId]
    end

    if customSpellNames[spellId] then
        spellName = customSpellNames[spellId]
    end

    -- local formattedName = (spellName and icon) and format("%s %s", BuffOverlay:GetIconString(icon, 20), spellName) or
    --     icon and format("%s %s", BuffOverlay:GetIconString(icon, 20), spellId) or spellIdStr

    if remove then
        list[spellIdStr] = nil
    else
        list[spellIdStr] = {
            name = BuffOverlay:Colorize(spellName or spellIdStr, spell.class) .. " [" .. spell.prio .. "]",
            image = icon,
            imageCoords = { 0.08, 0.92, 0.08, 0.92 },
            imageWidth = 16,
            imageHeight = 16,
            type = "description",
            order = spell.prio + 1,
        }
    end
end

local function GetSpells(class, barName)
    local spells = {}

    if next(BuffOverlay.db.profile.buffs) ~= nil then
        for k, v in pairs(BuffOverlay.db.profile.buffs) do
            -- Check if spell is valid for new db structure. If not, likely from old profile. Reset needed.
            if type(v) ~= "table" or not v.prio or not v.class then
                wipe(BuffOverlay.db.profile.buffs)
                BuffOverlay:Print("Corrupted buff database found. This is likely due to updating from an older version of Buff Overlay. Resetting buff database to default. Your other settings (including custom buffs) will be preserved.")
                return
            end

            if not v.parent and (v.class == class) then
                local spellName, _, icon = GetSpellInfo(k)
                local spellIdStr = tostring(k)

                if customIcons[k] then
                    icon = customIcons[k]
                end

                if not spellName then
                    optionsDisabled[k] = true
                end

                if not icon then
                    icon = customIcons["?"]
                end

                if customSpellNames[k] then
                    spellName = customSpellNames[k]
                end

                local formattedName = (spellName and icon) and format("%s%s", BuffOverlay:GetIconString(icon), spellName)
                    or icon and format("%s%s", BuffOverlay:GetIconString(icon), k) or spellIdStr

                if spellName then
                    local id = customSpellDescriptions[k] or k
                    local spell = Spell:CreateFromSpellID(id)
                    spell:ContinueOnSpellLoad(function()
                        spellDescriptions[k] = spell:GetSpellDescription()
                    end)
                end

                spells[spellIdStr] = {
                    name = "",
                    type = "group",
                    inline = true,
                    order = v.prio,
                    args = {
                        toggle = {
                            name = spellName or (type(k) == "string" and k) or format("Invalid Spell: %s", k),
                            image = icon,
                            imageCoords = { 0.08, 0.92, 0.08, 0.92 },
                            type = "toggle",
                            order = 0,
                            width = 1.175,
                            desc = function()
                                local description = spellDescriptions[k] and spellDescriptions[k] ~= ""
                                    and spellDescriptions[k] .. "\n" or ""

                                description = description
                                    .. format("\n%s %d", BuffOverlay:Colorize("Priority"), v.prio)
                                    .. (spellName and format("\n%s %d", BuffOverlay:Colorize("Spell ID"), k) or "")

                                if BuffOverlay.db.profile.buffs[k].children then
                                    description = description .. BuffOverlay:Colorize("\nChild Spell ID(s)\n")
                                    for child in pairs(BuffOverlay.db.profile.buffs[k].children) do
                                        description = description .. child .. "\n"
                                    end
                                end

                                return description
                            end,
                            get = function(info)
                                info.option.width = BuffOverlay.db.profile.buffs[k].state[barName].glow.enabled and 1.075 or 1.175
                                return BuffOverlay.db.profile.buffs[k].state[barName].enabled
                            end,
                            set = function(_, value)
                                BuffOverlay.db.profile.buffs[k].state[barName].enabled = value
                                if BuffOverlay.db.profile.buffs[k].children then
                                    for child in pairs(BuffOverlay.db.profile.buffs[k].children) do
                                        BuffOverlay.db.profile.buffs[child].state[barName].enabled = value
                                    end
                                end
                                if AceConfigDialog.OpenFrames["BuffOverlayDialog"] then
                                    if IsDifferentDialogBar(barName) then
                                        BuffOverlay:CreatePriorityDialog(barName)
                                    end
                                    AddToPriorityDialog(spellIdStr, not value)
                                    AceRegistry:NotifyChange("BuffOverlayDialog")
                                end
                                BuffOverlay:RefreshOverlays()
                            end,
                        },
                        edit = {
                            name = "",
                            image = "Interface\\Buttons\\UI-OptionsButton",
                            imageWidth = 12,
                            imageHeight = 12,
                            type = "execute",
                            order = 1,
                            width = 0.1,
                            func = function()
                                local key = k .. barName
                                BuffOverlay[key] = not BuffOverlay[key]
                            end,
                        },
                        glowColor = {
                            name = "",
                            type = "color",
                            order = 2,
                            width = 0.1,
                            hasAlpha = true,
                            hidden = function()
                                return not BuffOverlay.db.profile.buffs[k].state[barName].glow.enabled
                            end,
                            get = function()
                                return unpack(BuffOverlay.db.profile.buffs[k].state[barName].glow.color)
                            end,
                            set = function(_, r, g, b, a)
                                local color = BuffOverlay.db.profile.buffs[k].state[barName].glow.color
                                color[1] = r
                                color[2] = g
                                color[3] = b
                                color[4] = a
                                if BuffOverlay.db.profile.buffs[k].UpdateChildren then
                                    BuffOverlay.db.profile.buffs[k]:UpdateChildren()
                                end
                                BuffOverlay:RefreshOverlays()
                            end,
                        },
                        glow = {
                            name = "Glow",
                            desc = "Enable a glow border effect around the icon.",
                            type = "toggle",
                            order = 2,
                            width = 0.3,
                            get = function()
                                return BuffOverlay.db.profile.buffs[k].state[barName].glow.enabled
                            end,
                            set = function(_, value)
                                BuffOverlay.db.profile.buffs[k].state[barName].glow.enabled = value
                                if BuffOverlay.db.profile.buffs[k].UpdateChildren then
                                    BuffOverlay.db.profile.buffs[k]:UpdateChildren()
                                end
                                BuffOverlay:RefreshOverlays()
                            end,
                        },
                        own = {
                            name = "Own",
                            desc = "Only show the aura if you cast it.",
                            type = "toggle",
                            order = 3,
                            width = 0.3,
                            get = function()
                                return BuffOverlay.db.profile.buffs[k].state[barName].ownOnly
                            end,
                            set = function(_, value)
                                BuffOverlay.db.profile.buffs[k].state[barName].ownOnly = value
                                if BuffOverlay.db.profile.buffs[k].UpdateChildren then
                                    BuffOverlay.db.profile.buffs[k]:UpdateChildren()
                                end
                                BuffOverlay:RefreshOverlays()
                            end,
                        },
                        additionalSettings = {
                            name = " ",
                            type = "group",
                            inline = true,
                            order = 4,
                            hidden = function()
                                local key = k .. barName
                                return BuffOverlay[key] == nil and true or not BuffOverlay[key]
                            end,
                            args = {
                                header = {
                                    name = BuffOverlay:GetIconString(icon, 25) or "",
                                    type = "header",
                                    order = 0,
                                },
                                glowType = {
                                    name = "Glow Type",
                                    type = "select",
                                    order = 1,
                                    width = 0.75,
                                    values = {
                                        ["blizz"] = "Action Button",
                                        ["pixel"] = "Pixel",
                                    },
                                    get = function()
                                        return BuffOverlay.db.profile.buffs[k].state[barName].glow.type
                                    end,
                                    set = function(_, value)
                                        BuffOverlay.db.profile.buffs[k].state[barName].glow.type = value
                                        if BuffOverlay.db.profile.buffs[k].UpdateChildren then
                                            BuffOverlay.db.profile.buffs[k]:UpdateChildren()
                                        end
                                        BuffOverlay:RefreshOverlays(true, barName, true)
                                    end,
                                },
                                space = {
                                    name = " ",
                                    type = "description",
                                    order = 2,
                                    width = 0.05,
                                    hidden = function()
                                        return optionsDisabled[k]
                                    end,
                                },
                                space2 = {
                                    name = " ",
                                    type = "description",
                                    order = 2,
                                    width = 1,
                                    hidden = function()
                                        return not optionsDisabled[k]
                                    end,
                                },
                                editGlobalSettings = {
                                    name = "Edit Global Settings",
                                    type = "execute",
                                    desc = format("Add %s to the custom spell list, opening up global settings to edit for this spell.", formattedName),
                                    order = 3,
                                    width = 0.95,
                                    hidden = function()
                                        return optionsDisabled[k]
                                    end,
                                    func = function()
                                        BuffOverlay:AddToCustom(k)

                                        local dialog = AceConfigDialog.OpenFrames["BuffOverlay"]

                                        if dialog and dialog.children then
                                            for cKey, child in pairs(dialog.children) do
                                                if child.tabs then
                                                    for tKey, tab in pairs(child.tabs) do
                                                        if tab.value == "customSpells" then
                                                            C_Timer.After(0, function()
                                                                -- Click over to custom spells tab
                                                                dialog.children[cKey].tabs[tKey]:Click()

                                                                -- Find and select the spell in the list
                                                                for _, va in pairs(dialog.children[cKey].children) do
                                                                    if va.SelectByValue then
                                                                        for _, vb in pairs(va.lines) do
                                                                            if vb.value == tostring(k) then
                                                                                va:SelectByValue(vb.uniquevalue)
                                                                                return
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end)
                                                            return
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end,
                                },
                                testAura = {
                                    name = "Test Aura",
                                    type = "execute",
                                    desc = format("Show a test overlay for %s", formattedName),
                                    order = 4,
                                    width = 0.75,
                                    func = function()
                                        if BuffOverlay.test then
                                            if BuffOverlay:GetSingleTestAura() ~= k then
                                                BuffOverlay:Test()
                                            end
                                        end
                                        BuffOverlay:Test(barName, k)
                                    end,
                                },
                                space3 = {
                                    name = " ",
                                    type = "description",
                                    order = 5,
                                    width = 0.05,
                                },
                                applyToAll = {
                                    name = "Apply to All",
                                    type = "execute",
                                    desc = format("Apply %s's custom settings (glow, glow color, glow type, own only, etc) to all auras in %s.\n\nThis does not include any global settings (prio, class, etc).", formattedName, BuffOverlay:Colorize(BuffOverlay.db.profile.bars[barName].name or barName, "accent")),
                                    order = 6,
                                    width = 0.95,
                                    func = function()
                                        local current = BuffOverlay.db.profile.buffs[k].state[barName]
                                        for _, spell in pairs(BuffOverlay.db.profile.buffs) do
                                            for key, val in pairs(spell.state[barName]) do
                                                if key ~= "enabled" then
                                                    if type(val) == "table" then
                                                        spell.state[barName][key] = CopyTable(current[key])
                                                    else
                                                        spell.state[barName][key] = current[key]
                                                    end
                                                end
                                            end
                                        end
                                        BuffOverlay:RefreshOverlays(true, barName, true)
                                    end,
                                },
                            },
                        },
                    },
                }
            end
        end
    end
    return spells
end

function BuffOverlay:CreatePriorityDialog(barName)
    local bar = self.db.profile.bars[barName]

    local spells = {
        bar = {
            name = barName,
            type = "description",
            hidden = true,
        },
        desc = {
            name = "This informational panel is the full list of spells currently enabled for " .. self:Colorize((bar.name or barName), "main") .. " in order of priority. Any aura changes made while this panel is open will be reflected here in real time.",
            type = "description",
            order = 0,
        },
        space = {
            name = " ",
            type = "description",
            order = 0.5,
        },
    }

    for spellIdStr, info in pairs(GetSpells("MISC", barName)) do
        local spellId = tonumber(spellIdStr) or spellIdStr
        if self.db.profile.buffs[spellId].state[barName].enabled then
            spells[spellIdStr] = {
                name = self:Colorize(info.args.toggle.name, "MISC") .. " [" .. info.order .. "]",
                image = info.args.toggle.image,
                imageCoords = info.args.toggle.imageCoords,
                imageWidth = 16,
                imageHeight = 16,
                type = "description",
                order = info.order + 1,
            }
        end
    end

    for i = 1, MAX_CLASSES do
        local className = CLASS_SORT_ORDER[i]
        for spellIdStr, info in pairs(GetSpells(className, barName)) do
            local spellId = tonumber(spellIdStr) or spellIdStr
            if self.db.profile.buffs[spellId].state[barName].enabled then
                spells[spellIdStr] = {
                    name = self:Colorize(info.args.toggle.name, className) .. " [" .. info.order .. "]",
                    image = info.args.toggle.image,
                    imageCoords = info.args.toggle.imageCoords,
                    imageWidth = 16,
                    imageHeight = 16,
                    type = "description",
                    order = info.order + 1,
                }
            end
        end
    end

    self.priorityListDialog.name = self:Colorize((bar.name or barName), "main") .. " Enabled Auras Priority List"
    self.priorityListDialog.args = spells
end

local function GetClasses(barName)
    local classes = {}
    classes["MISC"] = {
        name = format("%s %s", BuffOverlay:GetIconString(customIcons["Cogwheel"], 15), BuffOverlay:Colorize("Miscellaneous", "MISC")),
        order = 99,
        type = "group",
        args = GetSpells("MISC", barName),
    }

    for i = 1, MAX_CLASSES do
        local className = CLASS_SORT_ORDER[i]
        classes[className] = {
            name = format("%s %s", BuffOverlay:GetIconString(classIcons[className], 15), BuffOverlay:Colorize(LOCALIZED_CLASS_NAMES_MALE[className], className)),
            order = i,
            type = "group",
            args = GetSpells(className, barName),
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

local function HasLessThanTwoBars()
    local count = 0
    for _ in pairs(BuffOverlay.db.profile.bars) do
        count = count + 1
    end
    return count < 2
end

function BuffOverlay:AddBarToOptions(bar, barName)
    self.options.args.bars.args[barName] = {
        name = bar.name or barName,
        type = "group",
        childGroups = "tab",
        args = {
            name = {
                name = "Set Bar Name",
                type = "input",
                order = 0,
                width = 1,
                set = function(info, val)
                    bar[info[#info]] = val
                    self.options.args.bars.args[barName].name = val
                    if AceConfigDialog.OpenFrames["BuffOverlayDialog"] and not IsDifferentDialogBar(barName) then
                        self.priorityListDialog.name = self:Colorize(val, "main") .. " Enabled Auras Priority List"
                        self.priorityListDialog.args.desc.name = "This informational panel is the full list of spells currently enabled for "
                            .. self:Colorize((val or barName), "main")
                            .. " in order of priority. Any aura changes made while this panel is open will be reflected here in real time."

                        AceRegistry:NotifyChange("BuffOverlayDialog")
                    end

                    self:UpdateSpellOptionsTable()
                end,
            },
            delete = {
                name = "Delete Bar",
                type = "execute",
                order = 1,
                width = 0.75,
                func = function()
                    local text = format("Are you sure you want to delete this bar?\n\n%s\n\n", BuffOverlay:Colorize(bar.name or barName, "main"))
                    deleteBarDelegate.text = text

                    LibDialog:Spawn(deleteBarDelegate, barName)
                end,
            },
            test = {
                name = "Test Bar",
                desc = "Show test overlays for this bar.",
                type = "execute",
                order = 2,
                width = 0.75,
                func = function()
                    if self.test then
                        if self:GetSingleTestAura() ~= nil then
                            self:Test()
                        end
                    end
                    self:Test(barName)
                end,
            },
            settings = {
                name = "Settings",
                type = "group",
                order = 3,
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    bar[info[#info]] = val
                    self:RefreshOverlays(true, barName)
                end,
                args = {
                    copySettings = {
                        name = "Copy Settings From",
                        desc = "This copies settings from 'Settings', 'Anchoring', and 'Visibility' tabs.",
                        type = "select",
                        order = 0,
                        width = 1,
                        values = function()
                            local values = {}
                            for k, v in pairs(self.db.profile.bars) do
                                if k ~= barName then
                                    values[k] = v.name or k
                                end
                            end
                            return values
                        end,
                        hidden = HasLessThanTwoBars,
                        set = function(info, val)
                            for k, v in pairs(self.db.profile.bars[val]) do
                                if k ~= "name" then
                                    bar[k] = type(v) == "table" and CopyTable(v) or v
                                end
                            end

                            self:Print("Copied settings, anchoring, and visibility tabs from " .. self:Colorize((self.db.profile.bars[val].name or val), "accent") .. " to " .. self:Colorize((bar.name or barName), "accent"))
                            self:RefreshOverlays(true, barName)
                        end,
                    },
                    space = {
                        name = " ",
                        type = "description",
                        order = 0.5,
                        width = "full",
                        hidden = HasLessThanTwoBars,
                    },
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
                            self:RefreshOverlays(true, barName)
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
                    debuffIconBorderColorByDispelType = {
                        order = 8.5,
                        name = "Color Debuff Icon Border by Dispel Type",
                        type = "toggle",
                        width = "full",
                        desc = "Change the icon border color based on the dispel type of the debuff. This overrides the icon border color.",
                        disabled = function() return not bar.iconBorder end,
                    },
                    buffIconBorderColorByDispelType = {
                        order = 8.6,
                        name = "Color Buff Icon Border by Dispel Type",
                        type = "toggle",
                        width = "full",
                        desc = "Change the icon border color based on the dispel type of the buff. This overrides the icon border color.",
                        disabled = function() return not bar.iconBorder end,
                    },
                    showCooldownSpiral = {
                        order = 9,
                        name = "Cooldown Spiral",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the cooldown spiral.",
                    },
                    showTooltip = {
                        order = 10,
                        name = "Show Tooltip On Hover",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the tooltip when hovering over an icon.",
                    },
                    showCooldownNumbers = {
                        order = 11,
                        name = "Show Blizzard Cooldown Text",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the cooldown text.",
                        get = function(info)
                            if not GetCVarBool("countdownForCooldowns") and bar[info[#info]] then
                                bar[info[#info]] = false
                                AceRegistry:NotifyChange("BuffOverlay")
                            end
                            return bar[info[#info]]
                        end,
                        set = function(info, val)
                            if val and not GetCVarBool("countdownForCooldowns") then
                                LibDialog:Spawn("ConfirmEnableBlizzardCooldownText", bar)
                            else
                                bar[info[#info]] = val
                                self:RefreshOverlays(true, barName)
                            end
                        end,
                    },
                },
            },
            anchoring = {
                name = "Anchoring",
                order = 4,
                type = "group",
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    bar[info[#info]] = val
                    self:RefreshOverlays(true, barName)
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
                        step = 0.1,
                    },
                    iconYOff = {
                        order = 5,
                        name = "Y-Offset",
                        type = "range",
                        width = 1.5,
                        desc = "Change the icon group's Y-Offset.",
                        min = -100,
                        max = 100,
                        step = 0.1,
                    },
                },
            },
            visibility = {
                order = 5,
                name = "Visibility",
                type = "group",
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    bar[info[#info]] = val
                    self:RefreshOverlays(true, barName)
                end,
                args = {
                    neverShow = {
                        order = 1,
                        name = "Never Show",
                        type = "toggle",
                        width = "full",
                        desc = "Never show this bar.",
                    },
                    showInWorld = {
                        order = 2,
                        name = "Show When Non-Instanced",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing this bar in the world/outside of instances.",
                    },
                    showInArena = {
                        order = 3,
                        name = "Show In Arena",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing this bar in an arena.",
                    },
                    showInBattleground = {
                        order = 4,
                        name = "Show In Battleground",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing this bar in a battleground.",
                    },
                    showInRaid = {
                        order = 5,
                        name = "Show In Raid",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing this bar in a raid instance.",
                    },
                    showInDungeon = {
                        order = 6,
                        name = "Show In Dungeon",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing this bar in a dungeon instance.",
                    },
                    showInScenario = {
                        order = 7,
                        name = "Show In Scenario",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing this bar in a scenario.",
                    },
                    frameTypes = {
                        order = 8,
                        name = "Frame Types",
                        type = "multiselect",
                        width = 0.9,
                        desc = "Show overlays on this frame type.\n\nBlizzard frames do not currently support separate types.",
                        values = function()
                            local t = {}
                            for k in pairs(bar.frameTypes) do
                                t[k] = k
                            end
                            return t
                        end,
                        get = function(info, key)
                            return bar.frameTypes[key]
                        end,
                        set = function(info, key, val)
                            bar.frameTypes[key] = val
                            self:RefreshOverlays(true, barName)
                        end,
                    },
                    header = {
                        order = 9,
                        name = "Group Size",
                        type = "header",
                    },
                    minGroupSize = {
                        order = 10,
                        name = "Group Size Minimum",
                        type = "range",
                        width = 1.5,
                        desc = "Show this bar when the group size is equal to or greater than this value.\n\n0=Solo with no group.\n1=Solo in a group.",
                        min = 0,
                        max = 40,
                        step = 1,
                        set = function(info, val)
                            bar[info[#info]] = val
                            if val > bar.maxGroupSize then
                                bar.maxGroupSize = val
                            end
                            self:RefreshOverlays(true, barName)
                        end,
                    },
                    maxGroupSize = {
                        order = 11,
                        name = "Group Size Maximum",
                        type = "range",
                        width = 1.5,
                        desc = "Show this bar when the group size is equal to or less than this value.\n\n0=Solo with no group.\n1=Solo in a group.",
                        min = 0,
                        max = 40,
                        step = 1,
                        set = function(info, val)
                            bar[info[#info]] = val
                            if val < bar.minGroupSize then
                                bar.minGroupSize = val
                            end
                            self:RefreshOverlays(true, barName)
                        end,
                    },
                },
            },
            spells = {
                order = 6,
                name = "Spells",
                type = "group",
                args = {
                    copySpells = {
                        name = "Copy Spells From",
                        type = "select",
                        order = 0,
                        width = 1,
                        values = function()
                            local values = {}
                            for k, v in pairs(self.db.profile.bars) do
                                if k ~= barName then
                                    values[k] = v.name or k
                                end
                            end
                            return values
                        end,
                        hidden = HasLessThanTwoBars,
                        set = function(info, val)
                            for _, v in pairs(self.db.profile.buffs) do
                                v.state[barName] = CopyTable(v.state[val])
                            end

                            local dialog = AceConfigDialog.OpenFrames["BuffOverlayDialog"]

                            if dialog and IsDifferentDialogBar(barName) then
                                self:CreatePriorityDialog(barName)
                            end

                            if dialog then
                                if IsDifferentDialogBar(barName) then
                                    self:CreatePriorityDialog(barName)
                                end

                                for k, v in pairs(self.db.profile.buffs) do
                                    if not v.parent then
                                        AddToPriorityDialog(tostring(k), not v.state[barName].enabled)
                                    end
                                end

                                AceRegistry:NotifyChange("BuffOverlayDialog")
                            end

                            self:Print("Copied spells from " .. self:Colorize((self.db.profile.bars[val].name or val), "accent") .. " to " .. self:Colorize((bar.name or barName), "accent"))
                            self:RefreshOverlays(true, barName)
                        end,
                    },
                    enableAll = {
                        order = 1,
                        name = "Enable All",
                        type = "execute",
                        width = 0.70,
                        desc = "Enable all spells.",
                        func = function()
                            local dialogIsOpen = AceConfigDialog.OpenFrames["BuffOverlayDialog"]

                            if dialogIsOpen and IsDifferentDialogBar(barName) then
                                self:CreatePriorityDialog(barName)
                            end

                            for k, v in pairs(self.db.profile.buffs) do
                                self.db.profile.buffs[k].enabled[barName] = true
                                if not v.parent and dialogIsOpen then
                                    AddToPriorityDialog(tostring(k))
                                end
                            end

                            if dialogIsOpen then
                                AceRegistry:NotifyChange("BuffOverlayDialog")
                            end

                            self:RefreshOverlays()
                        end,
                    },
                    disableAll = {
                        order = 2,
                        name = "Disable All",
                        type = "execute",
                        width = 0.70,
                        desc = "Disable all spells.",
                        func = function()
                            local dialogIsOpen = AceConfigDialog.OpenFrames["BuffOverlayDialog"]

                            if dialogIsOpen and IsDifferentDialogBar(barName) then
                                self:CreatePriorityDialog(barName)
                            end

                            for k in pairs(self.db.profile.buffs) do
                                self.db.profile.buffs[k].state[barName].enabled = false

                                if dialogIsOpen then
                                    BuffOverlay.priorityListDialog.args[tostring(k)] = nil
                                end
                            end

                            if dialogIsOpen then
                                AceRegistry:NotifyChange("BuffOverlayDialog")
                            end

                            self:RefreshOverlays()
                        end,
                    },
                    fullPriorityList = {
                        order = 3,
                        name = "Aura List",
                        type = "execute",
                        width = 0.70,
                        desc = "Shows a list of all enabled auras for this bar in order of priority.",
                        func = function()
                            local dialog = AceConfigDialog.OpenFrames["BuffOverlayDialog"]
                            if dialog and not IsDifferentDialogBar(barName) then
                                AceConfigDialog:Close("BuffOverlayDialog")
                            else
                                self:CreatePriorityDialog(barName)
                                AceConfigDialog:Open("BuffOverlayDialog")
                                dialog = AceConfigDialog.OpenFrames["BuffOverlayDialog"]
                                dialog:EnableResize(false)
                                local baseDialog = AceConfigDialog.OpenFrames["BuffOverlay"]
                                local width = (baseDialog and baseDialog.frame.width) or (InterfaceOptionsFrame and InterfaceOptionsFrame:GetWidth()) or 900

                                if not dialog.frame:IsUserPlaced() then
                                    dialog.frame:ClearAllPoints()
                                    dialog.frame:SetPoint("LEFT", UIParent, "CENTER", width / 2, 0)
                                end

                                if not dialog.frame.hooked then
                                    -- Avoid the dialog being moved unless the user drags it
                                    hooksecurefunc(dialog.frame, "SetPoint", function(widget, point, relativeTo, relativePoint, x, y)
                                        if widget:IsUserPlaced() then return end

                                        local appName = widget.obj.userdata.appName
                                        if (appName and appName == "BuffOverlayDialog")
                                        and (point ~= "LEFT"
                                            or relativeTo ~= UIParent
                                            or relativePoint ~= "CENTER"
                                            or x ~= width / 2
                                            or y ~= 0)
                                        then
                                            widget:ClearAllPoints()
                                            widget:SetPoint("LEFT", UIParent, "CENTER", width / 2, 0)
                                        end
                                    end)
                                    dialog.frame.hooked = true
                                end
                            end
                        end,
                    },
                    space4 = {
                        order = 4,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                },
            }
        }
    }
    self:UpdateSpellOptionsTable()
end

function BuffOverlay:UpdateBarOptionsTable()
    local options = self.options.args.bars.args

    for opt in pairs(options) do
        if opt ~= "addBar" and opt ~= "test" then
            options[opt] = nil
        end
    end

    for name, bar in pairs(self.db.profile.bars) do
        self:AddBarToOptions(bar, name)
    end
end

local customSpellInfo = {
    spellId = {
        order = 1,
        type = "description",
        width = "full",
        name = function(info)
            local spellId = tonumber(info[#info - 1])
            local str = BuffOverlay:Colorize("Spell ID ") .. spellId
            if BuffOverlay.db.profile.buffs[spellId].children then
                str = str .. BuffOverlay:Colorize("\n\nChild Spell ID(s)\n")
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
            local text = format("Are you sure you want to delete this spell?\n\n%s %s\n\n", BuffOverlay:GetIconString(icon, 20), spellName)
            if BuffOverlay.defaultSpells[spellId] then
                text = text .. format("(%s: This is a default spell. Deleting it from this tab will simply reset all its values to default and disable it, but it will not be removed from the spells tab.)", BuffOverlay:Colorize("Note", "accent"))
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
            -- Use "_MISC" to put Miscellaneous at the end of the list since Ace sorts the dropdown by key. (Hacky, but it works)
            -- _MISC gets converted in the setters/getters, so it won't affect other structures.
            classes["_MISC"] = format("%s %s", BuffOverlay:GetIconString(customIcons["Cogwheel"], 15), BuffOverlay:Colorize("Miscellaneous", "MISC"))
            for i = 1, MAX_CLASSES do
                local className = CLASS_SORT_ORDER[i]
                classes[className] = format("%s %s", BuffOverlay:GetIconString(classIcons[className], 15), BuffOverlay:Colorize(LOCALIZED_CLASS_NAMES_MALE[className], className))
            end
            return classes
        end,
        get = function(info)
            local spellId = tonumber(info[#info - 1])
            local class = BuffOverlay.db.global.customBuffs[spellId].class
            if class == "MISC" then
                class = "_MISC"
            end
            return class
        end,
        set = function(info, state)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            if state == "_MISC" then
                state = "MISC"
            end
            BuffOverlay.db.global.customBuffs[spellId][option] = state
            BuffOverlay.db.profile.buffs[spellId][option] = state
            if BuffOverlay.db.profile.buffs[spellId].children then
                BuffOverlay.db.profile.buffs[spellId]:UpdateChildren()
            end
            local spell = BuffOverlay.priorityListDialog.args[info[#info - 1]]
            if spell and AceConfigDialog.OpenFrames["BuffOverlayDialog"] then
                AddToPriorityDialog(info[#info - 1])
                AceRegistry:NotifyChange("BuffOverlayDialog")
            end
            BuffOverlay:UpdateSpellOptionsTable()
        end,
    },
    space = {
        order = 5,
        name = "\n",
        type = "description",
        width = "full",
    },
    prio = {
        order = 6,
        type = "input",
        name = "Priority (Lower is Higher Prio)",
        desc = "The priority of this spell. Lower numbers are higher priority. If two spells have the same priority, it will show alphabetically.",
        validate = function(_, value)
            local num = tonumber(value)
            if num and num < 1000000 and value:match("^%d+$") then
                if BuffOverlay.errorStatusText then
                    -- Clear error text on successful validation
                    local rootFrame = AceConfigDialog.OpenFrames["BuffOverlay"]
                    if rootFrame and rootFrame.SetStatusText then
                        rootFrame:SetStatusText("")
                    end
                    BuffOverlay.errorStatusText = nil
                end
                return true
            else
                BuffOverlay.errorStatusText = true
                return "Priority must be a positive integer from 0 to 999999"
            end
        end,
        set = function(info, state)
            local option = info[#info]
            local spellId = info[#info - 1]
            local val = tonumber(state)
            spellId = tonumber(spellId)
            BuffOverlay.db.global.customBuffs[spellId][option] = val
            BuffOverlay.db.profile.buffs[spellId][option] = val
            if BuffOverlay.db.profile.buffs[spellId].children then
                BuffOverlay.db.profile.buffs[spellId]:UpdateChildren()
            end
            local spell = BuffOverlay.priorityListDialog.args[info[#info - 1]]
            if spell and AceConfigDialog.OpenFrames["BuffOverlayDialog"] then
                spell.name = string.gsub(spell.name, tostring(spell.order - 1) .. "]", state .. "]")
                spell.order = val + 1
                AceRegistry:NotifyChange("BuffOverlayDialog")
            end
            BuffOverlay:RefreshOverlays()
            BuffOverlay:UpdateSpellOptionsTable()
        end,
        get = function(info)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            return tostring(BuffOverlay.db.global.customBuffs[spellId][option])
        end,
    },
    space2 = {
        order = 7,
        name = " ",
        type = "description",
        width = 2,
    },
    icon = {
        order = 8,
        name = "Custom Icon",
        type = "input",
        width = 1,
        desc = "The icon ID to use for this spell. This will overwrite the default icon.",
        get = function(info)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            local state = BuffOverlay.db.global.customBuffs[spellId][option]
            return state ~= nil and tostring(state) or ""
        end,
        set = function(info, state)
            local option = info[#info]
            local spellIdStr = info[#info - 1]
            local val = tonumber(state)
            local spellId = tonumber(spellIdStr)

            local name, _, icon = GetSpellInfo(spellId)

            if not (state:match("^%d+$") and val < 1000000) then
                if state == "" then
                    BuffOverlay.db.global.customBuffs[spellId][option] = nil
                    BuffOverlay.options.args.customSpells.args[spellIdStr].name = format("%s %s", BuffOverlay:GetIconString(icon, 15), name)
                else
                    BuffOverlay:Print(format("Invalid input for custom icon: %s", BuffOverlay:Colorize(state)))
                end
            else
                BuffOverlay.db.global.customBuffs[spellId][option] = val
                BuffOverlay.options.args.customSpells.args[spellIdStr].name = format("%s %s", BuffOverlay:GetIconString(val, 15), name)
            end

            BuffOverlay:UpdateCustomBuffs()
        end,
    },
    space3 = {
        order = 9,
        name = " ",
        type = "description",
        width = 2,
    },
    addChild = {
        order = 10,
        type = "input",
        name = "Add Child Spell ID",
        desc = "Add a child spell ID to this spell. Child IDs will be checked like normal IDs but will use all the same settings (including icon) as its parent. Also, any changes to the parent will apply to all of its children. This is useful for spells that have multiple ids which are convenient to track as a single spell (e.g. different ranks of the same spell).",
        width = 1,
        validate = function(_, value)
            local num = tonumber(value)
            if num and num < 10000000 and value:match("^%d+$") then
                if BuffOverlay.errorStatusText then
                    -- Clear error text on successful validation
                    local rootFrame = AceConfigDialog.OpenFrames["BuffOverlay"]
                    if rootFrame and rootFrame.SetStatusText then
                        rootFrame:SetStatusText("")
                    end
                    BuffOverlay.errorStatusText = nil
                end
                return true
            else
                BuffOverlay.errorStatusText = true
                return "Spell ID must be a positive integer from 0 to 9999999"
            end
        end,
        set = function(info, value)
            local parentId = tonumber(info[#info - 1])
            local childId = tonumber(value)

            BuffOverlay:InsertCustomChild(childId, parentId)
            BuffOverlay:UpdateCustomBuffs()
        end,
    },
    space4 = {
        order = 11,
        name = " ",
        type = "description",
        width = 2,
    },
    removeChild = {
        order = 12,
        type = "select",
        name = "Remove Custom Child Spell ID",
        width = 1,
        values = function(info)
            local spellId = tonumber(info[#info - 1])
            local values = {}
            for id in pairs(BuffOverlay.db.global.customBuffs) do
                if BuffOverlay.db.global.customBuffs[id].parent == spellId then
                    values[id] = id
                end
            end
            return values
        end,
        hidden = function(info)
            local spellId = tonumber(info[#info - 1])
            for id in pairs(BuffOverlay.db.global.customBuffs) do
                if BuffOverlay.db.global.customBuffs[id].parent == spellId then
                    return false
                end
            end
            return true
        end,
        set = function(info, value)
            local parentId = tonumber(info[#info - 1])
            local childId = tonumber(value)

            BuffOverlay:RemoveCustomChild(childId, parentId)
            BuffOverlay:UpdateCustomBuffs()
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
        validate = function(_, value)
            local num = tonumber(value)
            if num and num < 10000000 and value:match("^%d+$") then
                if BuffOverlay.errorStatusText then
                    -- Clear error text on successful validation
                    local rootFrame = AceConfigDialog.OpenFrames["BuffOverlay"]
                    if rootFrame and rootFrame.SetStatusText then
                        rootFrame:SetStatusText("")
                    end
                    BuffOverlay.errorStatusText = nil
                end
                return true
            else
                BuffOverlay.errorStatusText = true
                return "Spell ID must be a positive integer from 0 to 9999999"
            end
        end,
        set = function(_, state)
            local spellId = tonumber(state)

            if BuffOverlay.db.profile.buffs[spellId] and BuffOverlay.db.profile.buffs[spellId].parent then
                spellId = BuffOverlay.db.profile.buffs[spellId].parent
            end

            local name, _, icon = GetSpellInfo(spellId)

            if customIcons[spellId] then
                icon = customIcons[spellId]
            end

            if name then
                if BuffOverlay:InsertCustomAura(spellId) then
                    BuffOverlay.options.args.customSpells.args[state] = {
                        name = format("%s %s", BuffOverlay:GetIconString(icon, 15), name),
                        desc = function()
                            return spellDescriptions[spellId] or ""
                        end,
                        type = "group",
                        args = customSpellInfo,
                    }
                    BuffOverlay:UpdateCustomBuffs()
                    if AceConfigDialog.OpenFrames["BuffOverlayDialog"] then
                        AddToPriorityDialog(state)
                        AceRegistry:NotifyChange("BuffOverlayDialog")
                    end
                else
                    BuffOverlay:Print(format("%s %s is already being tracked.", BuffOverlay:GetIconString(icon, 20), name))
                end
            else
                BuffOverlay:Print(format("Invalid Spell ID %s", BuffOverlay:Colorize(state)))
            end
        end,
    }
}

function BuffOverlay:AddToCustom(spellId)
    local spellIdStr = tostring(spellId)
    local name, _, icon = GetSpellInfo(spellId)

    if customIcons[spellId] then
        icon = customIcons[spellId]
    end

    if name then
        if BuffOverlay:InsertCustomAura(spellId) then
            BuffOverlay.options.args.customSpells.args[spellIdStr] = {
                name = format("%s %s", BuffOverlay:GetIconString(icon, 15), name),
                desc = function()
                    return spellDescriptions[spellId] or ""
                end,
                type = "group",
                args = customSpellInfo,
            }
            BuffOverlay:UpdateCustomBuffs()
            if AceConfigDialog.OpenFrames["BuffOverlayDialog"] then
                AddToPriorityDialog(spellIdStr)
                AceRegistry:NotifyChange("BuffOverlayDialog")
            end
        end
    else
        BuffOverlay:Print(format("Invalid Spell ID %s", BuffOverlay:Colorize(spellIdStr)))
    end
end

function BuffOverlay:Options()
    for spellId, v in pairs(self.db.global.customBuffs) do
        if not v.parent then
            local name, _, icon = GetSpellInfo(spellId)
            customSpells[tostring(spellId)] = {
                name = format("%s %s", self:GetIconString(v.icon or icon, 15), name),
                desc = function()
                    return spellDescriptions[spellId] or ""
                end,
                type = "group",
                args = customSpellInfo,
            }
        end
    end
    self.options = {
        name = "BuffOverlay",
        type = "group",
        plugins = { profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) } },
        childGroups = "tab",
        args = {
            logo = {
                order = 1,
                type = "description",
                name = self:Colorize("Author") .. ": " .. GetAddOnMetadata("BuffOverlay", "Author") .. "\n" .. self:Colorize("Version") .. ": " .. version .. "\n\n",
                fontSize = "medium",
                -- "Logo" created by Marz Gallery @ https://www.flaticon.com/free-icons/nocturnal
                image = "Interface\\AddOns\\BuffOverlay\\Media\\Textures\\logo_transparent",
                imageWidth = 64,
                imageHeight = 64,
            },
            bars = {
                name = "Bars",
                type = "group",
                childGroups = "tab",
                order = 2,
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
                    test = {
                        order = 2,
                        name = "Test All",
                        type = "execute",
                        desc = "Toggle test overlays for all bars.",
                        func = function()
                            self:Test()
                        end,
                        width = 0.75,
                    },
                },
            },
            customSpells = {
                order = 3,
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
            globalSettings = {
                order = 4,
                name = "Global Settings",
                type = "group",
                args = {
                    welcomeMessage = {
                        order = 1,
                        name = "Welcome Message",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle showing of the welcome message on login.",
                        get = function(info) return self.db.profile[info[#info]] end,
                        set = function(info, val)
                            self.db.profile[info[#info]] = val
                        end,
                    },
                    minimap = {
                        order = 2,
                        name = "Minimap Icon",
                        type = "toggle",
                        width = "full",
                        desc = "Toggle the minimap icon.",
                        get = function(info) return not self.db.profile[info[#info]].hide end,
                        set = function()
                            self:ToggleMinimapIcon()
                        end,
                    },
                },
            }
        },
    }

    self.priorityListDialog = {
        name = "Temp",
        type = "group",
        args = {},
    }

    self:UpdateBarOptionsTable()

    -- Main options dialog.
    AceConfig:RegisterOptionsTable("BuffOverlay", self.options)
    AceConfig:RegisterOptionsTable("BuffOverlayDialog", self.priorityListDialog)
    AceConfigDialog:SetDefaultSize("BuffOverlay", 635, 720)
    AceConfigDialog:SetDefaultSize("BuffOverlayDialog", 300, 720)

    -------------------------------------------------------------------
    -- Create a simple blizzard options panel to direct users to "/bo"
    -------------------------------------------------------------------
    local panel = CreateFrame("Frame")
    panel.name = "BuffOverlay"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText("BuffOverlay")
    title:SetFont("Fonts\\FRIZQT__.TTF", 72, "OUTLINE")
    title:ClearAllPoints()
    title:SetPoint("TOP", 0, -70)

    local ver = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ver:SetText(version)
    ver:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    ver:ClearAllPoints()
    ver:SetPoint("TOP", title, "BOTTOM", 0, -20)

    local slash = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slash:SetText("/bo")
    slash:SetFont("Fonts\\FRIZQT__.TTF", 69, "OUTLINE")
    slash:ClearAllPoints()
    slash:SetPoint("BOTTOM", 0, 150)

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetText("Open Options")
    btn.Text:SetTextColor(1, 1, 1)
    btn:SetWidth(150)
    btn:SetHeight(30)
    btn:SetPoint("BOTTOM", 0, 100)
    btn.Left:SetDesaturated(true)
    btn.Right:SetDesaturated(true)
    btn.Middle:SetDesaturated(true)
    btn:SetScript("OnClick", function()
        if not InCombatLockdown() then
            HideUIPanel(SettingsPanel)
            HideUIPanel(InterfaceOptionsFrame)
            HideUIPanel(GameMenuFrame)
        end
        BuffOverlay:OpenOptions()
    end)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\MM_sky_01")
    bg:SetAlpha(0.2)
    bg:SetTexCoord(0, 1, 1, 0)

    if isRetail then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "BuffOverlay")
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end
