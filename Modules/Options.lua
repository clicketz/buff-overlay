local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Options: AceModule
local Options = Addon:NewModule('Options')

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Spells: AceModule
local Spells = Addon:GetModule('Spells')

---@class Overlay: AceModule
local Overlay = Addon:GetModule('Overlay')

---@class Bar: AceModule
local Bar = Addon:GetModule('Bar')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Test: AceModule
local Test = Addon:GetModule('Test')

---@class GUI: AceModule
local GUI = Addon:GetModule('GUI')

---@class Localization: AceModule
local Localization = addon:GetModule('Localization')
local L = Localization.L

local db = DB:GetData()
local LibDialog = LibStub("LibDialog-1.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfig = LibStub("AceConfig-3.0")

local optionsDisabled = {}

local CLASS_SORT_ORDER = CopyTable(CLASS_SORT_ORDER)
do
    table.sort(CLASS_SORT_ORDER)
end

Options.data = {}

local spellDescriptions = CreateFrame("Frame")
spellDescriptions:SetScript("OnEvent", function(self, event, spellId, success)
    if success then
        local id = customSpellDescriptions[spellId] or spellId
        self[spellId] = GetSpellDescription(id)
    end
end)
spellDescriptions:RegisterEvent("SPELL_DATA_LOAD_RESULT")

local function IsDifferentDialogBar(barName)
    return Options.priorityListDialog.args.bar.name ~= barName
end

local deleteBarDelegate = {
    buttons = {
        {
            text = YES,
            on_click = function(self)
                local barName = self.data
                Bar:Delete(barName)

                if AceConfigDialog.OpenFrames[addonName .. "Dialog"] and not IsDifferentDialogBar(barName) then
                    AceConfigDialog:Close(addonName .. "Dialog")
                end

                AceRegistry:NotifyChange(addonName)
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

local deleteSpellDelegate = {
    buttons = {
        {
            text = YES,
            on_click = function(self)
                local spellId = tonumber(self.data)
                if not spellId then return end

                if db.profile.auras[spellId].children then
                    for childId in pairs(db.profile.auras[spellId].children) do
                        if db.global.customAuras[childId]
                        and not (Spells.default[childId] and Spells.default[childId].parent == spellId) then
                            db.profile.auras[childId] = nil
                            db.profile.auras[spellId].children[childId] = nil
                        end
                    end

                    if next(db.profile.auras[spellId].children) == nil then
                        db.profile.auras[spellId].children = nil
                        db.profile.auras[spellId].UpdateChildren = nil
                    end
                end

                db.global.customAuras[spellId] = nil

                for id, spell in pairs(db.global.customAuras) do
                    if spell.parent and spell.parent == spellId then
                        db.global.customAuras[id] = nil
                    end
                end

                if Spells.default[spellId] then
                    for k, v in pairs(Spells.default[spellId]) do
                        if type(v) == "table" then
                            db.profile.auras[spellId][k] = CopyTable(v)
                        else
                            db.profile.auras[spellId][k] = v
                        end
                    end
                    db.profile.auras[spellId].custom = nil
                -- for barName in pairs(db.profile.bars) do
                --     db.profile.auras[spellId].enabled[barName] = false
                -- end
                else
                    db.profile.auras[spellId] = nil
                end

                Const.CUSTOM_ICONS[spellId] = nil

                if db.profile.auras[spellId] and db.profile.auras[spellId].children then
                    db.profile.auras[spellId]:UpdateChildren()
                end

                Options.data.args.customSpells.args[self.data] = nil
                if AceConfigDialog.OpenFrames[addonName .. "Dialog"] then
                    Options.priorityListDialog.args[self.data] = nil
                    AceRegistry:NotifyChange(addonName .. "Dialog")
                end
                Options:UpdateSpellOptionsTable()
                Overlay:RefreshOverlays()

                AceRegistry:NotifyChange(addonName)
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
local path = Const.IS_RETAIL and L["Options > Gameplay > Action Bars > Show Numbers for Cooldowns"] or L["Interface > ActionBars > Show Numbers for Cooldowns"]

LibDialog:Register("ConfirmEnableBlizzardCooldownText", {
    text = format(L["In order for %s setting to work in BuffOverlay, cooldown text needs to be enabled in Blizzard settings. You can find this setting located at:%s%s%sWould you like BuffOverlay to enable this setting for you?%s"], Util:Colorize(L["Show Blizzard Cooldown Text"], "main"), "\n\n", Util:Colorize(path), "\n\n", "\n\n"),
    buttons = {
        {
            text = YES,
            on_click = function(self)
                local bar = self.data

                SetCVar("countdownForCooldowns", true)
                bar.showCooldownNumbers = true
                Overlay:RefreshOverlays(true)

                AceRegistry:NotifyChange(addonName)
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
    text = format(L["%s%sCopy this version number and send it to the author if you need help with a bug."], Util:Colorize(GAME_VERSION_LABEL, "main"), "\n"),
    buttons = {
        {
            text = OKAY,
        },
    },
    editboxes = {
        {
            auto_focus = false,
            text = format("%s", Const.VERSION),
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

function Options:ShowVersion()
    LibDialog:Spawn("ShowVersion")
end

local function AddToPriorityDialog(spellIdStr, remove)
    local list = Options.priorityListDialog.args
    local spellId = tonumber(spellIdStr) or spellIdStr
    local spell = db.profile.auras[spellId]
    local spellName, _, icon = GetSpellInfo(spellId)

    if not spell then return end

    if Const.CUSTOM_ICONS[spellId] then
        icon = Const.CUSTOM_ICONS[spellId]
    end

    if Const.CUSTOM_SPELL_NAMES[spellId] then
        spellName = Const.CUSTOM_SPELL_NAMES[spellId]
    end

    if remove then
        list[spellIdStr] = nil
    else
        list[spellIdStr] = {
            name = Util:Colorize(spellName or spellIdStr, spell.class) .. " [" .. spell.prio .. "]",
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
    local optionsWidth = 0.975

    if next(db.profile.auras) ~= nil then
        for k, v in pairs(db.profile.auras) do
            -- Check if spell is valid for new db structure. If not, likely from old profile. Reset needed.
            if type(v) ~= "table" or not v.prio or not v.class then
                wipe(db.profile.auras)
                Util:Print(L["Corrupted buff database found. This is likely due to updating from an older version of Buff Overlay. Resetting buff database to default. Your other settings (including custom buffs) will be preserved."])
                return
            end

            if not v.parent and (v.class == class) then
                local spellName, _, icon = GetSpellInfo(k)
                local spellIdStr = tostring(k)

                if Const.CUSTOM_ICONS[k] then
                    icon = Const.CUSTOM_ICONS[k]
                end

                if not spellName then
                    optionsDisabled[k] = true
                end

                if not icon then
                    icon = Const.CUSTOM_ICONS["?"]
                end

                if Const.CUSTOM_SPELL_NAMES[k] then
                    spellName = Const.CUSTOM_SPELL_NAMES[k]
                end

                local formattedName = (spellName and icon) and format("%s%s", Util:GetIconString(icon), spellName)
                    or icon and format("%s%s", Util:GetIconString(icon), k) or spellIdStr

                if spellName then
                    if not spellDescriptions[k] then
                        C_Spell.RequestLoadSpellData(k)
                    end
                end

                spells[spellIdStr] = {
                    name = "",
                    type = "group",
                    inline = true,
                    order = v.prio,
                    args = {
                        toggle = {
                            name = spellName or (type(k) == "string" and k) or format(L["Invalid Spell: %s"], k),
                            image = icon,
                            imageCoords = { 0.08, 0.92, 0.08, 0.92 },
                            type = "toggle",
                            order = 0,
                            width = optionsWidth,
                            desc = function()
                                local description = spellDescriptions[k] and spellDescriptions[k] ~= ""
                                    and spellDescriptions[k] .. "\n" or ""

                                description = description
                                    .. format("\n%s %d", Util:Colorize(L["Priority"]), v.prio)
                                    .. (spellName and format("\n%s %d", Util:Colorize(L["Spell ID"]), k) or "")

                                if db.profile.auras[k].children then
                                    description = description .. "\n" .. Util:Colorize(L["Child Spell ID(s)"]) .. "\n"
                                    for child in pairs(db.profile.auras[k].children) do
                                        description = description .. child .. "\n"
                                    end
                                end

                                return description
                            end,
                            get = function(info)
                                local glowState = db.profile.auras[k].state[barName].glow
                                info.option.width = (glowState.customColor and glowState.enabled) and (optionsWidth - 0.1) or optionsWidth
                                return db.profile.auras[k].state[barName].enabled
                            end,
                            set = function(_, value)
                                db.profile.auras[k].state[barName].enabled = value
                                if db.profile.auras[k].children then
                                    for child in pairs(db.profile.auras[k].children) do
                                        db.profile.auras[child].state[barName].enabled = value
                                    end
                                end
                                if AceConfigDialog.OpenFrames[addonName .. "Dialog"] then
                                    if IsDifferentDialogBar(barName) then
                                        Options:CreatePriorityDialog(barName)
                                    end
                                    AddToPriorityDialog(spellIdStr, not value)
                                    AceRegistry:NotifyChange(addonName .. "Dialog")
                                end
                                Overlay:RefreshOverlays()
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
                                Options[key] = not Options[key] or nil
                            end,
                        },
                        glowColor = {
                            name = "",
                            type = "color",
                            order = 2,
                            width = 0.1,
                            hasAlpha = true,
                            hidden = function()
                                local glowState = db.profile.auras[k].state[barName].glow
                                return not (glowState.customColor and glowState.enabled)
                            end,
                            get = function()
                                return unpack(db.profile.auras[k].state[barName].glow.color)
                            end,
                            set = function(_, r, g, b, a)
                                local color = db.profile.auras[k].state[barName].glow.color
                                color[1] = r
                                color[2] = g
                                color[3] = b
                                color[4] = a
                                if db.profile.auras[k].UpdateChildren then
                                    db.profile.auras[k]:UpdateChildren()
                                end
                                Overlay:RefreshOverlays()
                            end,
                        },
                        glow = {
                            name = L["Glow"],
                            desc = L["Enable a glow border effect around the icon."],
                            type = "toggle",
                            order = 2,
                            width = 0.4,
                            get = function()
                                return db.profile.auras[k].state[barName].glow.enabled
                            end,
                            set = function(_, value)
                                db.profile.auras[k].state[barName].glow.enabled = value
                                if db.profile.auras[k].UpdateChildren then
                                    db.profile.auras[k]:UpdateChildren()
                                end
                                Overlay:RefreshOverlays()
                            end,
                        },
                        own = {
                            name = L["Own"],
                            desc = L["Only show the aura if you cast it."],
                            type = "toggle",
                            order = 3,
                            width = 0.4,
                            get = function()
                                return db.profile.auras[k].state[barName].ownOnly
                            end,
                            set = function(_, value)
                                db.profile.auras[k].state[barName].ownOnly = value
                                if db.profile.auras[k].UpdateChildren then
                                    db.profile.auras[k]:UpdateChildren()
                                end
                                Overlay:RefreshOverlays()
                            end,
                        },
                        additionalSettings = {
                            name = " ",
                            type = "group",
                            inline = true,
                            order = 4,
                            hidden = function()
                                local key = k .. barName
                                return Options[key] == nil and true or not Options[key]
                            end,
                            args = {
                                header = {
                                    name = Util:GetIconString(icon, 25) or "",
                                    type = "header",
                                    order = 0,
                                },
                                glowType = {
                                    name = L["Glow Type"],
                                    type = "select",
                                    order = 1,
                                    width = 0.75,
                                    values = {
                                        ["blizz"] = L["Action Button"],
                                        ["pixel"] = L["Pixel"],
                                        ["oldBlizz"] = Const.IS_RETAIL and L["Legacy Blizzard"] or nil,
                                    },
                                    get = function()
                                        return db.profile.auras[k].state[barName].glow.type
                                    end,
                                    set = function(_, value)
                                        db.profile.auras[k].state[barName].glow.type = value
                                        if db.profile.auras[k].UpdateChildren then
                                            db.profile.auras[k]:UpdateChildren()
                                        end
                                        Overlay:RefreshOverlays(true, barName)
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
                                    name = L["Edit Global Settings"],
                                    type = "execute",
                                    desc = format(L["Add %s to the custom spell list, opening up global settings to edit for this spell."], formattedName),
                                    order = 3,
                                    width = 0.95,
                                    hidden = function()
                                        return optionsDisabled[k]
                                    end,
                                    func = function()
                                        Options:AddToCustom(k)

                                        local dialog = AceConfigDialog.OpenFrames[addonName]

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
                                    name = L["Test Aura"],
                                    type = "execute",
                                    desc = format(L["Show a test overlay for %s"], formattedName),
                                    order = 4,
                                    width = 0.75,
                                    func = function()
                                        if Test:IsEnabled() then
                                            if Test:GetSingleTestAura() ~= k then
                                                Test:On()
                                            end
                                        end
                                        Test:Toggle(barName, k)
                                    end,
                                },
                                space3 = {
                                    name = " ",
                                    type = "description",
                                    order = 5,
                                    width = 0.05,
                                },
                                applyToAll = {
                                    name = L["Apply to All"],
                                    type = "execute",
                                    desc = format(L["Apply %s's custom settings (glow, glow color, glow type, own only, etc) to all auras in %s.%sThis does not include any global settings (prio, class, etc)."], formattedName, Util:Colorize(db.profile.bars[barName].name, "accent"), "\n\n"),
                                    order = 6,
                                    width = 0.95,
                                    func = function()
                                        local current = db.profile.auras[k].state[barName]
                                        for _, spell in pairs(db.profile.auras) do
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
                                        Overlay:RefreshOverlays(true, barName)
                                    end,
                                },
                                customColor = {
                                    name = L["Custom Glow Color"],
                                    desc = L["Toggle whether or not to use a custom color for glow."],
                                    type = "toggle",
                                    order = 7,
                                    width = 0.75,
                                    get = function()
                                        return db.profile.auras[k].state[barName].glow.customColor
                                    end,
                                    set = function(_, value)
                                        db.profile.auras[k].state[barName].glow.customColor = value
                                        if db.profile.auras[k].UpdateChildren then
                                            db.profile.auras[k]:UpdateChildren()
                                        end
                                        Overlay:RefreshOverlays(true, barName)
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

function Options:CreatePriorityDialog(barName)
    local bar = self.db.profile.bars[barName]

    local spells = {
        bar = {
            name = barName,
            type = "description",
            hidden = true,
        },
        desc = {
            name = format(L["This informational panel is the full list of spells currently enabled for %s in order of priority. Any aura changes made while this panel is open will be reflected here in real time."], self:Colorize(bar.name, "main")),
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

    self.priorityListDialog.name = self:Colorize(bar.name, "main") .. " " .. L["Enabled Auras Priority List"]
    self.priorityListDialog.args = spells
end

local function GetClasses(barName)
    local classes = {}
    classes["MISC"] = {
        name = format("%s %s", Util:GetIconString(Const.CUSTOM_ICONS["Cogwheel"], 15), Util:Colorize(MISCELLANEOUS, "MISC")),
        order = 99,
        type = "group",
        args = GetSpells("MISC", barName),
    }

    for i = 1, MAX_CLASSES do
        local className = CLASS_SORT_ORDER[i]
        classes[className] = {
            name = format("%s %s", Util:GetIconString(Const.CLASS_ICONS[className], 15), Util:Colorize(LOCALIZED_CLASS_NAMES_MALE[className], className)),
            order = i,
            type = "group",
            args = GetSpells(className, barName),
        }
    end
    return classes
end

function Options:UpdateSpellOptionsTable()
    if self.options then
        for barName in pairs(self.db.profile.bars) do
            for k, v in pairs(GetClasses(barName)) do
                if self.options.args.bars.args[barName] then
                    self.options.args.bars.args[barName].args.spells.args[k] = v
                end
            end
        end
    end
end

local function HasLessThanTwoBars()
    local count = 0
    for _ in pairs(db.profile.bars) do
        count = count + 1
    end
    return count < 2
end

function Options:AddBarToOptions(bar, barName)
    self.options.args.bars.args[barName] = {
        name = bar.name,
        type = "group",
        childGroups = "tab",
        args = {
            name = {
                name = L["Set Bar Name"],
                type = "input",
                order = 0,
                width = 1,
                set = function(info, val)
                    bar[info[#info]] = val
                    self.options.args.bars.args[barName].name = val
                    if AceConfigDialog.OpenFrames[addonName .. "Dialog"] and not IsDifferentDialogBar(barName) then
                        self.priorityListDialog.name = self:Colorize(val, "main") .. " " .. L["Enabled Auras Priority List"]
                        self.priorityListDialog.args.desc.name = format(L["This informational panel is the full list of spells currently enabled for %s in order of priority. Any aura changes made while this panel is open will be reflected here in real time."], self:Colorize((val or barName), "main"))

                        AceRegistry:NotifyChange(addonName .. "Dialog")
                    end

                    if bar.group then
                        bar.group:SetName(val)
                    end

                    self:UpdateSpellOptionsTable()
                end,
            },
            delete = {
                name = L["Delete Bar"],
                type = "execute",
                order = 1,
                width = 0.75,
                func = function()
                    local text = format(L["Are you sure you want to delete this bar?%s%s%s"], "\n\n", Util:Colorize(bar.name, "main"), "\n\n")
                    deleteBarDelegate.text = text

                    LibDialog:Spawn(deleteBarDelegate, barName)
                end,
            },
            test = {
                name = L["Test Bar"],
                desc = L["Show test overlays for this bar."],
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
                name = SETTINGS,
                type = "group",
                order = 3,
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    bar[info[#info]] = val
                    self:RefreshOverlays(true, barName)
                end,
                args = {
                    copySettings = {
                        name = L["Copy Settings From"],
                        desc = L["This copies settings from 'Settings', 'Anchoring', and 'Visibility' tabs."],
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

                            self:Print(format(L["Copied settings, anchoring, and visibility tabs from %s to %s"], self:Colorize((self.db.profile.bars[val].name), "accent"), self:Colorize(bar.name, "accent")))
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
                        name = L["Icon Count"],
                        type = "range",
                        width = 1,
                        desc = L["Number of icons you want to display (per frame)."],
                        min = 1,
                        max = 40,
                        softMax = 10,
                        step = 1,
                    },
                    iconAlpha = {
                        order = 2,
                        name = L["Icon Alpha"],
                        type = "range",
                        width = 1,
                        desc = L["Icon transparency."],
                        min = 0,
                        max = 1,
                        step = 0.01,
                    },
                    iconScale = {
                        order = 3,
                        name = L["Icon Scale"],
                        type = "range",
                        width = 1,
                        desc = L["Scale the size of the icon. Base icon size is proportionate to its parent frame."],
                        min = 0.01,
                        max = 99,
                        softMax = 3,
                        step = 0.01,
                    },
                    stackCountScale = {
                        order = 3.5,
                        name = L["Stack Count Scale"],
                        type = "range",
                        width = 1,
                        desc = L["Scale the icon's stack count text size."],
                        min = 0.01,
                        max = 10,
                        softMax = 3,
                        step = 0.01,
                        disabled = function() return not bar.showStackCount end,
                    },
                    cooldownNumberScale = {
                        order = 4,
                        name = L["Cooldown Text Scale"],
                        type = "range",
                        width = 1,
                        desc = L["Scale the icon's cooldown text size."],
                        min = 0.01,
                        max = 10,
                        softMax = 3,
                        step = 0.01,
                        disabled = function() return not bar.showCooldownNumbers end,
                    },
                    iconSpacing = {
                        order = 5,
                        name = L["Icon Spacing"],
                        type = "range",
                        width = 1,
                        desc = L["Spacing between icons. Spacing is scaled based on icon size for uniformity across different icon sizes."],
                        min = 0,
                        max = 200,
                        softMax = 20,
                        step = 1,
                    },
                    iconBorder = {
                        order = 6,
                        name = L["Icon Border"],
                        type = "toggle",
                        width = 0.75,
                        desc = L["Adds a pixel border around the icon. This will also zoom the icon in slightly to remove any default borders that may be present."] ..
                            "\n\n" ..
                            L["(Note: This will be automatically disabled if Masque is enabled for this bar.)"],
                    },
                    iconBorderColor = {
                        order = 7,
                        name = L["Icon Border Color"],
                        type = "color",
                        width = 0.75,
                        desc = L["Change the icon border color."],
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
                        name = L["Icon Border Size"],
                        type = "range",
                        width = 1.5,
                        desc = L["Change the icon border size (in pixels)."],
                        min = 1,
                        max = 10,
                        softMax = 5,
                        step = 1,
                        disabled = function() return not bar.iconBorder end,
                    },
                    showStackCount = {
                        order = 8.1,
                        name = L["Show Stack Count"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing of the stack count text on the icon."],
                    },
                    debuffIconBorderColorByDispelType = {
                        order = 8.5,
                        name = L["Color Debuff Icon Border by Dispel Type"],
                        type = "toggle",
                        width = "full",
                        desc = L["Change the icon border color based on the dispel type of the debuff. This overrides the icon border color."],
                        disabled = function() return not bar.iconBorder end,
                    },
                    buffIconBorderColorByDispelType = {
                        order = 8.6,
                        name = L["Color Buff Icon Border by Dispel Type"],
                        type = "toggle",
                        width = "full",
                        desc = L["Change the icon border color based on the dispel type of the buff. This overrides the icon border color."],
                        disabled = function() return not bar.iconBorder end,
                    },
                    showCooldownSpiral = {
                        order = 9,
                        name = L["Cooldown Spiral"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing of the cooldown spiral."],
                    },
                    showTooltip = {
                        order = 10,
                        name = L["Show Tooltip On Hover"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing of the tooltip when hovering over an icon."],
                    },
                    showCooldownNumbers = {
                        order = 11,
                        name = L["Show Blizzard Cooldown Text"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing of the cooldown text."],
                        get = function(info)
                            if not GetCVarBool("countdownForCooldowns") and bar[info[#info]] then
                                bar[info[#info]] = false
                                AceRegistry:NotifyChange(addonName)
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
                name = L["Anchoring"],
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
                        name = L["Icon Anchor"],
                        type = "select",
                        style = "dropdown",
                        width = 1,
                        desc = L["Where the anchor is on the icon."],
                        values = {
                            ["TOPLEFT"] = L["TOPLEFT"],
                            ["TOPRIGHT"] = L["TOPRIGHT"],
                            ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                            ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                            ["TOP"] = L["TOP"],
                            ["BOTTOM"] = L["BOTTOM"],
                            ["RIGHT"] = L["RIGHT"],
                            ["LEFT"] = L["LEFT"],
                            ["CENTER"] = L["CENTER"],
                        },
                    },
                    iconRelativePoint = {
                        order = 2,
                        name = L["Frame Attachment Point"],
                        type = "select",
                        style = "dropdown",
                        width = 1,
                        desc = L["Icon position relative to its parent frame."],
                        values = {
                            ["TOPLEFT"] = L["TOPLEFT"],
                            ["TOPRIGHT"] = L["TOPRIGHT"],
                            ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
                            ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
                            ["TOP"] = L["TOP"],
                            ["BOTTOM"] = L["BOTTOM"],
                            ["RIGHT"] = L["RIGHT"],
                            ["LEFT"] = L["LEFT"],
                            ["CENTER"] = L["CENTER"],
                        },
                    },
                    growDirection = {
                        order = 3,
                        name = L["Grow Direction"],
                        type = "select",
                        style = "dropdown",
                        width = 1,
                        desc = L["Where the icons will grow from the first icon."],
                        values = {
                            ["DOWN"] = HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_DOWN or L["DOWN"],
                            ["UP"] = HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_UP or L["UP"],
                            ["LEFT"] = HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT or L["LEFT"],
                            ["RIGHT"] = HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT or L["RIGHT"],
                            ["HORIZONTAL"] = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_HORIZONTAL or L["HORIZONTAL"],
                            ["VERTICAL"] = HUD_EDIT_MODE_SETTING_AURA_FRAME_ORIENTATION_VERTICAL or L["VERTICAL"],
                        },
                    },
                    iconXOff = {
                        order = 4,
                        name = L["X-Offset"],
                        type = "range",
                        width = 1.5,
                        desc = L["Change the icon group's X-Offset."],
                        min = -100,
                        max = 100,
                        step = 0.1,
                    },
                    iconYOff = {
                        order = 5,
                        name = L["Y-Offset"],
                        type = "range",
                        width = 1.5,
                        desc = L["Change the icon group's Y-Offset."],
                        min = -100,
                        max = 100,
                        step = 0.1,
                    },
                },
            },
            visibility = {
                order = 5,
                name = L["Visibility"],
                type = "group",
                get = function(info) return bar[info[#info]] end,
                set = function(info, val)
                    bar[info[#info]] = val
                    self:RefreshOverlays(true, barName)
                end,
                args = {
                    neverShow = {
                        order = 1,
                        name = L["Never Show"],
                        type = "toggle",
                        width = "full",
                        desc = L["Never show this bar."],
                    },
                    showInWorld = {
                        order = 2,
                        name = L["Show When Non-Instanced"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing this bar in the world/outside of instances."],
                    },
                    showInArena = {
                        order = 3,
                        name = L["Show In Arena"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing this bar in an arena."],
                    },
                    showInBattleground = {
                        order = 4,
                        name = L["Show In Battleground"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing this bar in a battleground."],
                    },
                    showInRaid = {
                        order = 5,
                        name = L["Show In Raid"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing this bar in a raid instance."],
                    },
                    showInDungeon = {
                        order = 6,
                        name = L["Show In Dungeon"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing this bar in a dungeon instance."],
                    },
                    showInScenario = {
                        order = 7,
                        name = L["Show In Scenario"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing this bar in a scenario."],
                    },
                    frameTypes = {
                        order = 8,
                        name = L["Frame Types"],
                        type = "multiselect",
                        width = 0.9,
                        desc = L["Show overlays on this frame type."],
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
                    -- header = {
                    --     order = 9,
                    --     name = L["Group Size"],
                    --     type = "header",
                    -- },
                    minGroupSize = {
                        order = 10,
                        name = format("%s %s", L["Group Size"], MINIMUM),
                        type = "range",
                        width = 1.5,
                        desc = L["Show this bar when the group size is equal to or greater than this value.\n\n0=Solo with no group.\n1=Solo in a group."],
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
                        name = format("%s %s", L["Group Size"], MAXIMUM),
                        type = "range",
                        width = 1.5,
                        desc = L["Show this bar when the group size is equal to or less than this value.\n\n0=Solo with no group.\n1=Solo in a group."],
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
                name = SPELLS,
                type = "group",
                args = {
                    copySpells = {
                        name = L["Copy Spells From"],
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

                            local dialog = AceConfigDialog.OpenFrames[addonName .. "Dialog"]

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

                                AceRegistry:NotifyChange(addonName .. "Dialog")
                            end

                            self:Print(format(L["Copied spells from %s to %s."], self:Colorize((self.db.profile.bars[val].name), "accent"), self:Colorize(bar.name, "accent")))
                            self:RefreshOverlays(true, barName)
                        end,
                    },
                    enableAll = {
                        order = 1,
                        name = ENABLE_ALL_ADDONS,
                        type = "execute",
                        width = 0.70,
                        desc = L["Enable all spells."],
                        func = function()
                            local dialogIsOpen = AceConfigDialog.OpenFrames[addonName .. "Dialog"]

                            if dialogIsOpen and IsDifferentDialogBar(barName) then
                                self:CreatePriorityDialog(barName)
                            end

                            for k, v in pairs(self.db.profile.buffs) do
                                self.db.profile.buffs[k].state[barName].enabled = true
                                if not v.parent and dialogIsOpen then
                                    AddToPriorityDialog(tostring(k))
                                end
                            end

                            if dialogIsOpen then
                                AceRegistry:NotifyChange(addonName .. "Dialog")
                            end

                            self:RefreshOverlays()
                        end,
                    },
                    disableAll = {
                        order = 2,
                        name = DISABLE_ALL_ADDONS,
                        type = "execute",
                        width = 0.70,
                        desc = L["Disable all spells."],
                        func = function()
                            local dialogIsOpen = AceConfigDialog.OpenFrames[addonName .. "Dialog"]

                            if dialogIsOpen and IsDifferentDialogBar(barName) then
                                self:CreatePriorityDialog(barName)
                            end

                            for k in pairs(self.db.profile.buffs) do
                                self.db.profile.buffs[k].state[barName].enabled = false

                                if dialogIsOpen then
                                    Options.priorityListDialog.args[tostring(k)] = nil
                                end
                            end

                            if dialogIsOpen then
                                AceRegistry:NotifyChange(addonName .. "Dialog")
                            end

                            self:RefreshOverlays()
                        end,
                    },
                    fullPriorityList = {
                        order = 3,
                        name = L["Aura List"],
                        type = "execute",
                        width = 0.70,
                        desc = L["Shows a list of all enabled auras for this bar in order of priority."],
                        func = function()
                            local dialog = AceConfigDialog.OpenFrames[addonName .. "Dialog"]
                            if dialog and not IsDifferentDialogBar(barName) then
                                AceConfigDialog:Close(addonName .. "Dialog")
                            else
                                self:CreatePriorityDialog(barName)
                                AceConfigDialog:Open(addonName .. "Dialog")
                                dialog = AceConfigDialog.OpenFrames[addonName .. "Dialog"]
                                dialog:EnableResize(false)
                                local baseDialog = AceConfigDialog.OpenFrames[addonName]
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
                                        if (appName and appName == addonName .. "Dialog")
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

local barCache = {}
function Options:TryAddBarToOptions(bar, barName)
    if self.options then
        self:AddBarToOptions(bar, barName)
    else
        barCache[bar] = barName
    end
end

function Options:UpdateBarOptionsTable()
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
            local str = Util:Colorize(L["Spell ID"]) .. " " .. spellId
            if db.profile.buffs[spellId].children then
                str = str .. "\n\n" .. Util:Colorize(L["Child Spell ID(s)"]) .. "\n"
                for child in pairs(db.profile.buffs[spellId].children) do
                    str = str .. child .. "\n"
                end
            end
            return str .. "\n\n"
        end,
    },
    delete = {
        order = 2,
        type = "execute",
        name = DELETE,
        width = 1,
        func = function(info)
            local spellId = tonumber(info[#info - 1])
            local spellName, _, icon = GetSpellInfo(spellId)
            if Const.CUSTOM_ICONS[spellId] then
                icon = Const.CUSTOM_ICONS[spellId]
            end
            local text = format("%s\n\n%s %s\n\n", L["Are you sure you want to delete this spell?"], Util:GetIconString(icon, 20), spellName)
            if Spells.default[spellId] then
                text = text .. format(L["(%s: This is a default spell. Deleting it from this tab will simply reset all of its values to their defaults, but it will not be removed from the spells tab.)"], Util:Colorize(LABEL_NOTE, "accent"))
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
        name = CLASS,
        values = function()
            local classes = {}
            -- Use "_MISC" to put Miscellaneous at the end of the list since Ace sorts the dropdown by key. (Hacky, but it works)
            -- _MISC gets converted in the setters/getters, so it won't affect other structures.
            classes["_MISC"] = format("%s %s", Util:GetIconString(Const.CUSTOM_ICONS["Cogwheel"], 15), Util:Colorize(MISCELLANEOUS, "MISC"))
            for i = 1, MAX_CLASSES do
                local className = CLASS_SORT_ORDER[i]
                classes[className] = format("%s %s", Util:GetIconString(Const.CLASS_ICONS[className], 15), Util:Colorize(LOCALIZED_CLASS_NAMES_MALE[className], className))
            end
            return classes
        end,
        get = function(info)
            local spellId = tonumber(info[#info - 1])
            local class = db.global.customBuffs[spellId].class
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
            db.global.customBuffs[spellId][option] = state
            db.profile.buffs[spellId][option] = state
            if db.profile.buffs[spellId].children then
                db.profile.buffs[spellId]:UpdateChildren()
            end
            local spell = Options.priorityListDialog.args[info[#info - 1]]
            if spell and AceConfigDialog.OpenFrames[addonName .. "Dialog"] then
                AddToPriorityDialog(info[#info - 1])
                AceRegistry:NotifyChange(addonName .. "Dialog")
            end
            Options:UpdateSpellOptionsTable()
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
        name = L["Priority (Lower is Higher Prio)"],
        desc = L["The priority of this spell. Lower numbers are higher priority. If two spells have the same priority, it will show alphabetically."],
        validate = function(_, value)
            local num = tonumber(value)
            if num and num < 1000000 and value:match("^%d+$") then
                if Options.errorStatusText then
                    -- Clear error text on successful validation
                    local rootFrame = AceConfigDialog.OpenFrames[addonName]
                    if rootFrame and rootFrame.SetStatusText then
                        rootFrame:SetStatusText("")
                    end
                    Options.errorStatusText = nil
                end
                return true
            else
                Options.errorStatusText = true
                return L["Priority must be a positive integer from 0 to 999999"]
            end
        end,
        set = function(info, state)
            local option = info[#info]
            local spellId = info[#info - 1]
            local val = tonumber(state)
            spellId = tonumber(spellId)
            db.global.customBuffs[spellId][option] = val
            db.profile.buffs[spellId][option] = val
            if db.profile.buffs[spellId].children then
                db.profile.buffs[spellId]:UpdateChildren()
            end
            local spell = Options.priorityListDialog.args[info[#info - 1]]
            if spell and AceConfigDialog.OpenFrames[addonName .. "Dialog"] then
                spell.name = string.gsub(spell.name, tostring(spell.order - 1) .. "]", state .. "]")
                spell.order = val + 1
                AceRegistry:NotifyChange(addonName .. "Dialog")
            end
            Overlay:RefreshOverlays()
            Options:UpdateSpellOptionsTable()
        end,
        get = function(info)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            return tostring(db.global.customBuffs[spellId][option])
        end,
    },
    space2 = {
        order = 7,
        name = " ",
        type = "description",
        width = 2,
    },
    currentIcon = {
        order = 7.5,
        name = "",
        type = "description",
        width = 0.33,
        image = function(info)
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            local icon = db.global.customBuffs[spellId].icon

            return icon
                or select(3, GetSpellInfo(spellId))
                or Const.CUSTOM_ICONS[info[#info - 1]]
                or Const.CUSTOM_ICONS["?"]
        end,
        imageCoords = { 0.08, 0.92, 0.08, 0.92 },
    },
    icon = {
        order = 8,
        name = L["Custom Icon"],
        type = "input",
        width = 0.66,
        desc = L["The icon ID to use for this spell. This will overwrite the default icon."],
        get = function(info)
            local option = info[#info]
            local spellId = info[#info - 1]
            spellId = tonumber(spellId)
            local state = db.global.customBuffs[spellId][option]
            return state ~= nil and tostring(state) or ""
        end,
        set = function(info, state)
            local option = info[#info]
            local spellIdStr = info[#info - 1]
            local val = tonumber(state)
            local spellId = tonumber(spellIdStr)

            local name, _, icon = GetSpellInfo(spellId)

            if not (state:match("^%d+$") and val < 1000000000) then
                if state == "" then
                    db.global.customBuffs[spellId][option] = nil
                    Options.data.args.customSpells.args[spellIdStr].name = format("%s %s", Util:GetIconString(icon, 15), name)
                else
                    Util:Print(format(L["Invalid input for custom icon: %s"], Util:Colorize(state)))
                end
            else
                db.global.customBuffs[spellId][option] = val
                Options.data.args.customSpells.args[spellIdStr].name = format("%s %s", Util:GetIconString(val, 15), name)
            end

            DB:UpdateCustomAuras()
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
        name = L["Add Child Spell ID"],
        desc = L["Add a child spell ID to this spell. Child IDs will be checked like normal IDs but will use all the same settings (including icon) as its parent. Also, any changes to the parent will apply to all of its children. This is useful for spells that have multiple ids which are convenient to track as a single spell (e.g. different ranks of the same spell)."],
        width = 1,
        validate = function(_, value)
            local num = tonumber(value)

            if (not value or value == "")
            or (num and num < 10000000 and value:match("^%d+$")) then
                if Options.errorStatusText then
                    -- Clear error text on successful validation
                    local rootFrame = AceConfigDialog.OpenFrames[addonName]
                    if rootFrame and rootFrame.SetStatusText then
                        rootFrame:SetStatusText("")
                    end
                    Options.errorStatusText = nil
                end
                return true
            else
                Options.errorStatusText = true
                return L["Spell ID must be a positive integer from 0 to 9999999"]
            end
        end,
        set = function(info, value)
            if not value or value == "" then return end

            local parentId = tonumber(info[#info - 1])
            local childId = tonumber(value)

            DB:InsertCustomChild(childId, parentId)
            DB:UpdateCustomAuras()
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
        name = L["Remove Custom Child Spell ID"],
        width = 1,
        values = function(info)
            local spellId = tonumber(info[#info - 1])
            local values = {}
            for id in pairs(db.global.customBuffs) do
                if db.global.customBuffs[id].parent == spellId
                and not (Spells.default[id] and Spells.default[id].parent == spellId) then
                    values[id] = id
                end
            end
            return values
        end,
        hidden = function(info)
            local spellId = tonumber(info[#info - 1])
            for id in pairs(db.global.customBuffs) do
                if db.global.customBuffs[id].parent == spellId
                and not (Spells.default[id] and Spells.default[id].parent == spellId) then
                    return false
                end
            end
            return true
        end,
        set = function(info, value)
            local parentId = tonumber(info[#info - 1])
            local childId = tonumber(value)

            DB:RemoveCustomChild(childId, parentId)
            DB:UpdateCustomAuras()
        end,
    },
}

local customSpells = {
    spellId_info = {
        order = 1,
        type = "description",
        name = L["In addition to adding new spells here, you can also add any Spell ID from the spells tab to edit its default values.\n(Note: anything you add here will persist through addon updates and profile resets.)"],
    },
    spellId = {
        order = 2,
        name = L["Spell ID"],
        desc = L["Enter the spell ID of the spell you want to keep track of."] .. "\n\n" .. L["Keep in mind you want to add the Spell ID of the aura that appears on the buff/debuff bar, not necessarily the Spell ID from the spell book or talent tree."],
        type = "input",
        validate = function(_, value)
            local num = tonumber(value)
            if num and num < 10000000 and value:match("^%d+$") then
                if Options.errorStatusText then
                    -- Clear error text on successful validation
                    local rootFrame = AceConfigDialog.OpenFrames[addonName]
                    if rootFrame and rootFrame.SetStatusText then
                        rootFrame:SetStatusText("")
                    end
                    Options.errorStatusText = nil
                end
                return true
            else
                Options.errorStatusText = true
                return L["Spell ID must be a positive integer from 0 to 9999999"]
            end
        end,
        set = function(_, state)
            local spellId = tonumber(state)
            local spellIdStr = state
            local child = false
            local childId

            if db.profile.auras[spellId] and db.profile.auras[spellId].parent then
                child = true
                childId = spellId
                spellId = db.profile.auras[spellId].parent
                spellIdStr = tostring(spellId)
            end

            local name, _, icon = GetSpellInfo(spellId)

            if Const.CUSTOM_ICONS[spellId] then
                icon = Const.CUSTOM_ICONS[spellId]
            end

            if name then
                if DB:InsertCustomAura(spellId) then
                    Options.data.args.customSpells.args[spellIdStr] = {
                        name = format("%s %s", Util:GetIconString(icon, 15), name),
                        desc = function()
                            return spellDescriptions[spellId] or ""
                        end,
                        type = "group",
                        args = customSpellInfo,
                    }
                    DB:UpdateCustomAuras()
                    if AceConfigDialog.OpenFrames[addonName .. "Dialog"] then
                        AddToPriorityDialog(spellIdStr)
                        AceRegistry:NotifyChange(addonName .. "Dialog")
                    end
                else
                    Util:Print(format(L["%s %s is already being tracked."], Util:GetIconString(icon, 20), name))
                end
            else
                if child then
                    Util:Print(format(L["%s is already being tracked as a child of %s and cannot be edited."], Util:Colorize(childId), Util:Colorize(spellId)))
                else
                    Util:Print(format(L["Invalid Spell ID %s"], Util:Colorize(spellId)))
                end
            end
        end,
    }
}

function Options:AddToCustom(spellId)
    local spellIdStr = tostring(spellId)
    local name, _, icon = GetSpellInfo(spellId)

    if Const.CUSTOM_ICONS[spellId] then
        icon = Const.CUSTOM_ICONS[spellId]
    end

    if name then
        if DB:InsertCustomAura(spellId) then
            self.data.args.customSpells.args[spellIdStr] = {
                name = format("%s %s", Util:GetIconString(icon, 15), name),
                desc = function()
                    return spellDescriptions[spellId] or ""
                end,
                type = "group",
                args = customSpellInfo,
            }
            DB:UpdateCustomAuras()
            if AceConfigDialog.OpenFrames[addonName .. "Dialog"] then
                AddToPriorityDialog(spellIdStr)
                AceRegistry:NotifyChange(addonName .. "Dialog")
            end
        end
    else
        Util:Print(format(L["Invalid Spell ID %s"], Util:Colorize(spellIdStr)))
    end
end

function Options:Get()
    return self.data
end

function Options:OnInitialize()
    for spellId, v in pairs(db.global.customAuras) do
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
    self.data = {
        name = addonName,
        type = "group",
        plugins = { profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) } },
        childGroups = "tab",
        args = {
            logo = {
                order = 1,
                type = "description",
                name = self:Colorize(L["Author"]) .. ": " .. Const.AUTHOR .. "\n" .. self:Colorize(GAME_VERSION_LABEL) .. ": " .. Const.VERSION .. "\n\n",
                fontSize = "medium",
                -- "Logo" created by Marz Gallery @ https://www.flaticon.com/free-icons/nocturnal
                image = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\logo_transparent",
                imageWidth = 64,
                imageHeight = 64,
            },
            bars = {
                name = L["Bars"],
                type = "group",
                childGroups = "tab",
                order = 2,
                args = {
                    addBar = {
                        order = 1,
                        name = L["Add Bar"],
                        type = "execute",
                        desc = L["Add an additional aura bar with default settings."],
                        width = 0.75,
                        func = function()
                            self:AddBar()
                        end,
                    },
                    test = {
                        order = 2,
                        name = L["Test All"],
                        type = "execute",
                        desc = L["Toggle test overlays for all bars."],
                        func = function()
                            self:Test()
                        end,
                        width = 0.75,
                    },
                },
            },
            customSpells = {
                order = 3,
                name = L["Custom Spells"],
                type = "group",
                args = customSpells,
                get = function(info)
                    local option = info[#info]
                    local spellId = info[#info - 1]
                    spellId = tonumber(spellId)
                    if not spellId then return end
                    return self.db.global.customAuras[spellId][option]
                end,
            },
            globalSettings = {
                order = 4,
                name = BASE_SETTINGS,
                type = "group",
                args = {
                    welcomeMessage = {
                        order = 1,
                        name = L["Welcome Message"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle showing of the welcome message on login."],
                        get = function(info) return self.db.profile[info[#info]] end,
                        set = function(info, val)
                            self.db.profile[info[#info]] = val
                        end,
                    },
                    minimap = {
                        order = 2,
                        name = L["Minimap Icon"],
                        type = "toggle",
                        width = "full",
                        desc = L["Toggle the minimap icon."],
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

    -- Add any bar attempted to be added to options
    -- before options were initialized
    for bar, barName in pairs(barCache) do
        self:AddBarToOptions(bar, barName)
    end

    self:UpdateBarOptionsTable()

    -- Main options dialog.
    AceConfig:RegisterOptionsTable(addonName, self.data)
    AceConfig:RegisterOptionsTable(addonName .. "Dialog", self.priorityListDialog)
    AceConfigDialog:SetDefaultSize(addonName, 635, 730)
    AceConfigDialog:SetDefaultSize(addonName .. "Dialog", 300, 730)

    -------------------------------------------------------------------
    -- Create a simple blizzard options panel to direct users to "/bo"
    -------------------------------------------------------------------
    local panel = CreateFrame("Frame")
    panel.name = addonName

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(addonName)
    title:SetFont("Fonts\\FRIZQT__.TTF", 72, "OUTLINE")
    title:ClearAllPoints()
    title:SetPoint("TOP", 0, -70)

    local ver = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ver:SetText(Const.VERSION)
    ver:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    ver:ClearAllPoints()
    ver:SetPoint("TOP", title, "BOTTOM", 0, -20)

    local slash = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slash:SetText("/bo")
    slash:SetFont("Fonts\\FRIZQT__.TTF", 69, "OUTLINE")
    slash:ClearAllPoints()
    slash:SetPoint("BOTTOM", 0, 150)

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetText(L["Open Options"])
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
        GUI:Open()
    end)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\MM_sky_01")
    bg:SetAlpha(0.2)
    bg:SetTexCoord(0, 1, 1, 0)

    if Const.IS_RETAIL then
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end
