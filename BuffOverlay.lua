---@class BuffOverlay: AceModule
local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceRegistry = LibStub("AceConfigRegistry-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LCG = LibStub("LibCustomGlow-1.0")
local LDBIcon = LibStub("LibDBIcon-1.0")
local version = C_AddOns.GetAddOnMetadata("BuffOverlay", "Version")
local Masque

local LATEST_DB_VERSION = 1.0

-- Localization Table
local L = BuffOverlay.L

-- Upvalues
local _G = _G
local C_Spell = C_Spell
local C_Timer = C_Timer
local PixelUtil = PixelUtil
local CopyTable = CopyTable
local GetSpellTexture = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture
local GetSpellInfo = BuffOverlay.GetSpellInfo
local UnitIsPlayer = UnitIsPlayer
local InCombatLockdown = InCombatLockdown
local GetNumGroupMembers = GetNumGroupMembers
local IsInInstance = IsInInstance
local next = next
local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local type = type
local rawset = rawset
local format = format
local select = select
local CreateFrame = CreateFrame
local table_sort = table.sort
local string_find = string.find
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_rand = math.random
local DebuffTypeColor = DebuffTypeColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local testBuffs = {}
local testBuffIds = {}
local testBarNames = {}
local testSingleAura
local testTextFrame
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local defaultBarSettings = {
    iconCount = 4,
    iconScale = 1,
    iconAlpha = 1.0,
    iconSpacing = 0,
    iconAnchor = "BOTTOM",
    iconRelativePoint = "CENTER",
    growDirection = "HORIZONTAL",
    showCooldownSpiral = true,
    showCooldownNumbers = false,
    showStackCount = true,
    cooldownNumberScale = 1,
    stackCountScale = 0.9,
    iconXOff = 0,
    iconYOff = 0,
    iconBorder = true,
    iconBorderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 1,
    },
    debuffIconBorderColorByDispelType = true,
    buffIconBorderColorByDispelType = false,
    iconBorderSize = 1,
    showTooltip = true,
    neverShow = false,
    showInWorld = true,
    showInArena = true,
    showInBattleground = true,
    showInRaid = true,
    showInDungeon = true,
    showInScenario = true,
    maxGroupSize = 40,
    minGroupSize = 0,
    frameTypes = {
        ["raid"] = true,
        ["party"] = true,
        ["tank"] = true,
        ["pet"] = true,
        ["assist"] = true,
        ["player"] = true,
        ["arena"] = true,
    }
}

local defaultSettings = {
    profile = {
        welcomeMessage = true,
        minimap = {
            hide = false,
        },
        bars = {},
        buffs = {},
    },
    global = {
        customBuffs = {},
        dbVer = 0,
    },
}

local filters = {
    "HELPFUL",
    "HARMFUL",
}

local dispelTypes = {
    "Magic",
    "Curse",
    "Disease",
    "Poison",
    "none",
}

local hexFontColors = {
    ["main"] = "ff83b2ff",
    ["accent"] = "ff9b6ef3",
    ["value"] = "ffffe981",
    ["logo"] = "ffff7a00",
    ["blizzardFont"] = NORMAL_FONT_COLOR:GenerateHexColor(),
}

local auraState = {
    enabled = true,
    glow = {
        enabled = false,
        color = { 1, 1, 1, 1 },
        customColor = false,
        n = 8,          -- number of lines
        freq = 0.25,    -- frequency of the lines
        length = nil,   -- length of each line
        thickness = 1,  -- thickness of each line
        xOff = 0,       -- x offset
        yOff = 0,       -- y offset
        border = false, -- show a border
        key = nil,      -- key used to register the glow for multiple glows
        type = "blizz", -- blizz / pixel / oldBlizz
    },
    ownOnly = false,
}

local ldbData = {
    type = "launcher",
    text = "BuffOverlay",
    -- "Logo" created by Marz Gallery @ https://www.flaticon.com/free-icons/nocturnal
    icon = "Interface\\AddOns\\BuffOverlay\\Media\\Textures\\logo",
    OnTooltipShow = function(tooltip)
        tooltip:AddDoubleLine(BuffOverlay:Colorize("BuffOverlay", "main"), BuffOverlay:Colorize(version, "accent"))
        tooltip:AddLine(" ")
        tooltip:AddLine(format(L["%s to toggle options window."], BuffOverlay:Colorize(L["Left-click"])), 1, 1, 1, false)
        tooltip:AddLine(format(L["%s to toggle test icons."], BuffOverlay:Colorize(L["Right-click"])), 1, 1, 1, false)
        tooltip:AddLine(format(L["%s to toggle the minimap icon."], BuffOverlay:Colorize(L["Shift+Right-click"])), 1, 1, 1, false)
    end,
    OnClick = function(clickedFrame, button)
        if button == "LeftButton" then
            BuffOverlay:ToggleOptions()
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                BuffOverlay:ToggleMinimapIcon()
                if BuffOverlay.db.profile.minimap.hide then
                    BuffOverlay:Print(format(L["Minimap icon is now hidden. Type %s %s to show it again."], BuffOverlay:Colorize("/bo", "accent"), BuffOverlay:Colorize("minimap", "accent")))
                end
                AceRegistry:NotifyChange("BuffOverlay")
            else
                BuffOverlay:Test()
            end
        end
    end,
}

local broker = LDB:NewDataObject("BuffOverlay", ldbData)

if AddonCompartmentFrame then
    AddonCompartmentFrame:RegisterAddon({
        text = "BuffOverlay",
        icon = "Interface\\AddOns\\BuffOverlay\\Media\\Textures\\logo_transparent",
        notCheckable = true,
        func = function()
            BuffOverlay:ToggleOptions()
        end,
    })
end

function BuffOverlay:OpenOptions()
    AceConfigDialog:Open("BuffOverlay")
    local dialog = AceConfigDialog.OpenFrames["BuffOverlay"]
    if dialog then
        dialog:EnableResize(false)
    end
end

function BuffOverlay:ToggleOptions()
    if AceConfigDialog.OpenFrames["BuffOverlay"] then
        AceConfigDialog:Close("BuffOverlay")
        AceConfigDialog:Close("BuffOverlayDialog")
    else
        self:OpenOptions()
    end
end

local function UpdateMinimapIcon()
    if BuffOverlay.db.profile.minimap.hide then
        LDBIcon:Hide("BuffOverlay")
    else
        LDBIcon:Show("BuffOverlay")
    end
end

function BuffOverlay:ToggleMinimapIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide

    UpdateMinimapIcon()
end

do
    for class, val in pairs(RAID_CLASS_COLORS) do
        hexFontColors[class] = val.colorStr
    end
end

function BuffOverlay:Colorize(text, color)
    if not text then return end
    local hexColor = hexFontColors[color] or hexFontColors["blizzardFont"]
    return "|c" .. hexColor .. text .. "|r"
end

function BuffOverlay:Print(...)
    print(self:Colorize("BuffOverlay", "main") .. ":", ...)
end

local function GetFirstUnusedNum()
    local num = 1

    while BuffOverlay.db.profile.bars["Bar" .. num] do
        num = num + 1
    end

    return num
end

local function masqueCallback()
    BuffOverlay:RefreshOverlays(true)
end

function BuffOverlay:AddBar()
    local num = GetFirstUnusedNum()
    local barName = "Bar" .. num

    self.db.profile.bars[barName] = CopyTable(defaultBarSettings)

    local bar = self.db.profile.bars[barName]
    bar.name = barName
    bar.id = barName
    self:TryAddBarToOptions(bar, barName)

    for _, v in pairs(self.db.profile.buffs) do
        if v.state[barName] == nil then
            v.state[barName] = CopyTable(auraState)
        end
    end

    if Masque then
        bar.group = Masque:Group("BuffOverlay", bar.name, barName)
        bar.group:RegisterCallback(masqueCallback)
    end

    self:RefreshOverlays(true)
end

function BuffOverlay:DeleteBar(barName)
    if self.db.profile.bars[barName].group then
        self.db.profile.bars[barName].group:Delete()
    end

    self.db.profile.bars[barName] = nil
    self.options.args.bars.args[barName] = nil
    testBarNames[barName] = nil

    for _, v in pairs(self.db.profile.buffs) do
        if v.state then
            v.state[barName] = nil
        end
    end

    self:RefreshOverlays(true)
end

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math_floor(num * mult + 0.5) / mult
end

local function InsertTestBuff(spellId)
    local tex = GetSpellTexture(spellId)
    if tex and not testBuffIds[spellId] then
        rawset(testBuffs, #testBuffs + 1, { spellId, tex })
        rawset(testBuffIds, spellId, true)
    end
end

local function UnitAuraTest(unit, index, filter)
    if testSingleAura then
        local icon = BuffOverlay.customIcons[testSingleAura] or select(3, GetSpellInfo(testSingleAura)) or BuffOverlay.customIcons["?"]
        local key = testSingleAura

        return key, icon, 3, nil, 60, GetTime() + 60, "player", nil, nil, testSingleAura
    else
        local buff = testBuffs[index]
        local dispelType = dispelTypes[math_rand(1, 5)]

        if not buff then return end

        return "TestBuff", buff[2], 3, dispelType, 60, GetTime() + 60, "player", nil, nil, buff[1]
    end
end

function BuffOverlay:InsertCustomAura(spellId)
    if not C_Spell.DoesSpellExist(spellId) then
        return false
    end

    local custom = self.db.global.customBuffs

    if not custom[spellId] and not self.db.profile.buffs[spellId] then
        custom[spellId] = {
            class = "MISC",
            prio = 100,
            custom = true
        }
        return true
    elseif not custom[spellId] and self.db.profile.buffs[spellId] then
        custom[spellId] = {
            class = self.db.profile.buffs[spellId].class,
            prio = self.db.profile.buffs[spellId].prio,
            custom = true,
        }
        return true
    end

    return false
end

function BuffOverlay:InsertCustomChild(childId, parentId)
    if not C_Spell.DoesSpellExist(childId) then
        self:Print(format(L["Invalid Spell ID %s"], BuffOverlay:Colorize(childId)))
        return false
    end

    local custom = self.db.global.customBuffs

    if not custom[childId] and not self.db.profile.buffs[childId] then
        custom[childId] = {
            parent = parentId,
            custom = true,
        }
        return true
    end

    local pId = (custom[childId] and custom[childId].parent) or (self.db.profile.buffs[childId] and self.db.profile.buffs[childId].parent)

    if pId then
        local name, _, icon = GetSpellInfo(pId)
        self:Print(format(L["%s is already being tracked under %s %s."], self:Colorize(childId), self:GetIconString(icon, 20), name))
    else
        local name, _, icon = GetSpellInfo(childId)
        self:Print(format(L["%s %s is already being tracked."], self:GetIconString(icon, 20), name))
    end

    return false
end

function BuffOverlay:RemoveCustomChild(childId, parentId)
    local custom = self.db.global.customBuffs
    local profile = self.db.profile.buffs

    if profile[parentId] and profile[parentId].children then
        profile[parentId].children[childId] = nil

        if next(profile[parentId].children) == nil then
            profile[parentId].children = nil
            profile[parentId].UpdateChildren = nil
        end
    end

    custom[childId] = nil
    profile[childId] = nil
end

local function InitUnitFrames()
    for unit in pairs(BuffOverlay.units) do
        BuffOverlay.unitFrames[unit] = {}
    end
end

local function InitUnits()
    local units = BuffOverlay.units
    local container = CreateFrame("Frame", "BuffOverlayContainer", UIParent)

    for i = 1, 40 do
        units["raid" .. i] = CreateFrame("Frame", "BuffOverlayRaid" .. i, container)
        units["raidpet" .. i] = CreateFrame("Frame", "BuffOverlayRaidPet" .. i, container)
    end
    for i = 1, 4 do
        units["party" .. i] = CreateFrame("Frame", "BuffOverlayParty" .. i, container)
        units["partypet" .. i] = CreateFrame("Frame", "BuffOverlayPartyPet" .. i, container)
    end
    units["player"] = CreateFrame("Frame", "BuffOverlayPlayer", container)
    units["pet"] = CreateFrame("Frame", "BuffOverlayPet", container)

    InitUnitFrames()

    for unit, frame in pairs(units) do
        frame:SetScript("OnEvent", function()
            for f in pairs(BuffOverlay.unitFrames[unit]) do
                BuffOverlay:ApplyOverlay(f, unit)
            end
        end)

        frame:RegisterUnitEvent("UNIT_AURA", unit)
    end
end

function BuffOverlay:AddUnitFrame(frame, unit)
    if not self.unitFrames[unit] then
        self.unitFrames[unit] = {}
    end

    -- Remove the frame if it exists for another unit
    for u in pairs(self.unitFrames) do
        if u ~= unit and self.unitFrames[u][frame] then
            self.unitFrames[u][frame] = nil
        end
    end

    self.unitFrames[unit][frame] = true
end

local function UpdateChildren(self)
    for child in pairs(self.children) do
        for k, v in pairs(self) do
            if k ~= "children" and k ~= "UpdateChildren" then
                if type(v) == "table" then
                    BuffOverlay.db.profile.buffs[child][k] = CopyTable(v)
                else
                    BuffOverlay.db.profile.buffs[child][k] = v
                end
            end
        end

        if BuffOverlay.db.profile.buffs[child].custom and not self.custom then
            BuffOverlay.db.global.customBuffs[child] = nil
            if BuffOverlay.defaultSpells[child] then
                BuffOverlay.db.profile.buffs[child].custom = nil
            else
                self.children[child] = nil
            end
        end
    end

    if next(self.children) == nil then
        self.children = nil
        self.UpdateChildren = nil
    end
end

-- Expensive. Run as few times as possible (once on startup preferrably).
-- Will need to be recursive if table depth increases on default state.
local function UpdateAuraState()
    local auras = BuffOverlay.db.profile.buffs

    for _, aura in pairs(auras) do
        for _, state in pairs(aura.state) do
            for attr, info in pairs(auraState) do
                if state[attr] == nil then
                    state[attr] = type(info) == "table" and CopyTable(info) or info
                elseif type(state[attr]) == "table" then
                    if type(info) == "table" then
                        for k, v in pairs(info) do
                            if state[attr][k] == nil then
                                state[attr][k] = v
                            end
                        end
                    else
                        state[attr] = info
                    end
                end
            end

            for attr, info in pairs(state) do
                if type(info) == "table" then
                    for k in pairs(info) do
                        if auraState[attr][k] == nil then
                            state[attr][k] = nil
                        end
                    end
                elseif auraState[attr] == nil then
                    state[attr] = nil
                end
            end
        end
    end
end

function BuffOverlay:UpdateCustomBuffs()
    for spellId, v in pairs(self.db.global.customBuffs) do
        -- Fix for old database entries
        if v.enabled then
            v.enabled = nil
        end

        if v.icon then
            self.customIcons[spellId] = v.icon
        elseif self.customIcons[spellId] then
            self.customIcons[spellId] = nil
        end

        if not self.db.profile.buffs[spellId] then
            self.db.profile.buffs[spellId] = {
                state = {},
            }
        end

        local buff = self.db.profile.buffs[spellId]

        if not buff.state then
            buff.state = {}
        end

        for barName in pairs(self.db.profile.bars) do
            if buff.state[barName] == nil then
                buff.state[barName] = CopyTable(auraState)
            end
        end

        local t = v.parent and self.db.global.customBuffs[v.parent] or v

        for field, value in pairs(t) do
            if type(value) == "table" then
                buff[field] = CopyTable(value)
            else
                buff[field] = value
            end
        end

        if v.parent then
            local parent = self.db.profile.buffs[v.parent]

            buff.parent = v.parent

            if parent then
                if not parent.children then
                    parent.children = {}
                    parent.UpdateChildren = UpdateChildren
                end
                parent.children[spellId] = true
                parent:UpdateChildren()
            end

            if buff.UpdateChildren then
                buff.UpdateChildren = nil
            end
        end

        if buff.children then
            buff:UpdateChildren()
        end

        InsertTestBuff(spellId)
    end

    self:UpdateSpellOptionsTable()
    self:RefreshOverlays()
end

local function ValidateBuffData()
    for k, v in pairs(BuffOverlay.db.profile.buffs) do
        if v.enabled then -- Fix for old database entries
            v.enabled = nil
        end

        if (not BuffOverlay.defaultSpells[k]) and (not BuffOverlay.db.global.customBuffs[k]) then
            BuffOverlay.db.profile.buffs[k] = nil
        else
            if v.custom then
                if v.parent and not BuffOverlay.db.global.customBuffs[v.parent] then
                    v.custom = nil
                elseif not BuffOverlay.db.global.customBuffs[k] then
                    v.custom = nil
                end
            end

            if v.parent then -- child found
                -- Fix for updating parent info or updating a child to a non-parent
                if BuffOverlay.defaultSpells[k] and not BuffOverlay.defaultSpells[k].parent then
                    v.parent = nil
                else
                    -- Fix for switching an old parent to a child
                    if v.children then
                        v.children = nil
                    end

                    if v.UpdateChildren then
                        v.UpdateChildren = nil
                    end

                    local parent = BuffOverlay.db.profile.buffs[v.parent]

                    if not parent.children then
                        parent.children = {}
                    end

                    parent.children[k] = true

                    if not parent.UpdateChildren then
                        parent.UpdateChildren = UpdateChildren
                    end

                    -- Give child the same fields as parent
                    for key, val in pairs(parent) do
                        if key ~= "children" and key ~= "UpdateChildren" then
                            if type(val) == "table" then
                                BuffOverlay.db.profile.buffs[k][key] = CopyTable(val)
                            else
                                BuffOverlay.db.profile.buffs[k][key] = val
                            end
                        end
                    end
                end
            else
                InsertTestBuff(k)
            end

            -- Check to see if any children were deleted and update DB accordingly
            if v.children then
                for child in pairs(v.children) do
                    local childData = BuffOverlay.defaultSpells[child]
                    if not childData or not childData.parent or childData.parent ~= k then
                        v.children[child] = nil
                    end
                end

                if next(v.children) == nil then
                    v.children = nil
                    if v.UpdateChildren then
                        v.UpdateChildren = nil
                    end
                end
            end
        end
    end
    BuffOverlay:UpdateCustomBuffs()
end

function BuffOverlay:CreateBuffTable()
    local newdb = false
    -- If the current profile doesn't have any buffs saved use default list and save it
    if next(self.db.profile.buffs) == nil then
        for k, v in pairs(self.defaultSpells) do
            self.db.profile.buffs[k] = {
                state = {},
            }

            for barName in pairs(self.db.profile.bars) do
                self.db.profile.buffs[k].state[barName] = CopyTable(auraState)
            end

            for key, val in pairs(v) do
                if type(val) == "table" then
                    self.db.profile.buffs[k][key] = CopyTable(val)
                else
                    self.db.profile.buffs[k][key] = val
                end
            end
        end
        newdb = true
        ValidateBuffData()
    end

    return newdb
end

function BuffOverlay:UpdateBuffs()
    if not self:CreateBuffTable() then
        -- Update buffs if any user changes are made to lua file
        for k, v in pairs(self.defaultSpells) do
            if v.parent then
                if self.db.global.customBuffs[k] then
                    self.db.global.customBuffs[k] = nil
                    self.options.args.customSpells.args[tostring(k)] = nil
                end
            end

            if not self.db.profile.buffs[k] then
                self.db.profile.buffs[k] = {
                    state = {},
                }

                for barName in pairs(self.db.profile.bars) do
                    self.db.profile.buffs[k].state[barName] = CopyTable(auraState)
                end

                for key, val in pairs(v) do
                    if type(val) == "table" then
                        self.db.profile.buffs[k][key] = CopyTable(val)
                    else
                        self.db.profile.buffs[k][key] = val
                    end
                end
            else
                if not self.db.profile.buffs[k].state then
                    self.db.profile.buffs[k].state = {}
                end

                for key, val in pairs(v) do
                    if type(val) == "table" then
                        self.db.profile.buffs[k][key] = CopyTable(val)
                    else
                        self.db.profile.buffs[k][key] = val
                    end
                end

                for barName in pairs(self.db.profile.bars) do
                    if self.db.profile.buffs[k].state[barName] == nil then
                        self.db.profile.buffs[k].state[barName] = CopyTable(auraState)
                    end
                end
            end
        end
        ValidateBuffData()
    end
end

local function HideAllOverlays(frame)
    if not frame.BuffOverlays then return end

    for _, child in ipairs({ frame.BuffOverlays:GetChildren() }) do
        child:Hide()
    end
end

local function ValidateBarAttributes()
    if next(BuffOverlay.db.profile.bars) == nil then
        BuffOverlay:AddBar()
    end

    for barName, bar in pairs(BuffOverlay.db.profile.bars) do
        if not bar.name then
            bar.name = barName
        end

        if not bar.id then
            bar.id = barName
        end

        for attr, val in pairs(defaultBarSettings) do
            if bar[attr] == nil then
                if type(val) == "table" then
                    bar[attr] = CopyTable(val)
                else
                    bar[attr] = val
                end
            elseif type(val) == "table" then
                for key, value in pairs(val) do
                    if bar[attr][key] == nil then
                        if type(value) == "table" then
                            bar[attr][key] = CopyTable(value)
                        else
                            bar[attr][key] = value
                        end
                    end
                end
            end
        end

        for attribute in pairs(bar) do
            if attribute ~= "name" and attribute ~= "id" then
                if defaultBarSettings[attribute] == nil then
                    bar[attribute] = nil
                elseif type(defaultBarSettings[attribute]) == "table" then
                    for key in pairs(bar[attribute]) do
                        if defaultBarSettings[attribute][key] == nil then
                            bar[attribute][key] = nil
                        end
                    end
                end
            end
        end
    end
end

local function ValidateSpellIds()
    for spellId in pairs(BuffOverlay.defaultSpells) do
        if type(spellId) == "number" then
            if not C_Spell.DoesSpellExist(spellId) then
                BuffOverlay.defaultSpells[spellId] = nil
                BuffOverlay.db.profile.buffs[spellId] = nil
                BuffOverlay.db.global.customBuffs[spellId] = nil
                BuffOverlay:Print(format(L["Spell ID %s is invalid. If you haven't made any manual code changes, please report this to the author."], BuffOverlay:Colorize(spellId)))
            end
        end
    end

    for spellId in pairs(BuffOverlay.db.profile.buffs) do
        if type(spellId) == "number" then
            if not C_Spell.DoesSpellExist(spellId) then
                BuffOverlay.db.profile.buffs[spellId] = nil
                BuffOverlay.db.global.customBuffs[spellId] = nil
                BuffOverlay:Print(format(L["Spell ID %s is invalid and has been removed."], BuffOverlay:Colorize(spellId)))
            end
        end
    end

    for spellId in pairs(BuffOverlay.db.global.customBuffs) do
        if type(spellId) == "number" then
            if not C_Spell.DoesSpellExist(spellId) then
                BuffOverlay.db.global.customBuffs[spellId] = nil
                BuffOverlay:Print(format(L["Spell ID %s is invalid and has been removed."], BuffOverlay:Colorize(spellId)))
            end
        end
    end
end

local function ValidateDatabase()
    -- Clean up old DB entries
    local reset = false
    for _, content in pairs(BuffOverlay.db.profiles) do
        for attr in pairs(defaultBarSettings) do
            if content[attr] ~= nil then
                BuffOverlay:Print(format(L["There has been a major update and unfortunately your profiles need to be reset. Upside though, you can now add BuffOverlay aura bars in multiple locations on your frames! Check it out by typing %s in chat."], BuffOverlay:Colorize("/bo", "accent")))
                BuffOverlay.db:ResetDB("Default")
                reset = true
                break
            end
        end
        if reset then break end
    end

    BuffOverlay.db.global.dbVer = LATEST_DB_VERSION
end

function BuffOverlay:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BuffOverlayDB", defaultSettings, true)
    LDBIcon:Register("BuffOverlay", broker, self.db.profile.minimap)

    self.numGroupMembers = GetNumGroupMembers()
    self.overlays = {}
    self.priority = {}
    self.units = {}
    self.unitFrames = {}
    self.blizzFrames = {}

    ValidateDatabase()
    ValidateSpellIds()
    ValidateBarAttributes()

    self.db.RegisterCallback(self, "OnProfileChanged", "FullRefresh")
    self.db.RegisterCallback(self, "OnProfileCopied", "FullRefresh")
    self.db.RegisterCallback(self, "OnProfileReset", "FullRefresh")
    self.db.RegisterCallback(self, "OnDatabaseReset", "FullRefresh")

    if self.db.profile.welcomeMessage then
        self:Print(format(L["Type %s or %s to open the options panel or %s for more commands."], self:Colorize("/buffoverlay", "accent"), self:Colorize("/bo", "accent"), self:Colorize("/bo help", "accent")))
    end

    self:Options()
    InitUnits()

    -- EventHandler for third-party addons
    -- Note: More events get added in InitFrames()
    -- TODO: Separate this into event methods
    self.eventHandler = CreateFrame("Frame")
    self.eventHandler:RegisterEvent("PLAYER_LOGIN")
    self.eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventHandler:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.eventHandler:RegisterEvent("UI_SCALE_CHANGED")
    self.eventHandler:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            self.pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
            self:InitFrames()
            Masque = LibStub("Masque", true)
        elseif event == "GROUP_ROSTER_UPDATE" then
            self.numGroupMembers = GetNumGroupMembers()
            if self.addons then
                self:UpdateUnits()
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            self.instanceType = select(2, IsInInstance())
            if self.addons then
                self:UpdateUnits()
            end
        elseif event == "UNIT_EXITED_VEHICLE" or event == "UNIT_ENTERED_VEHICLE" then
            -- Wait for the next frame for the vehicle to be fully loaded/unloaded
            C_Timer.After(0, function()
                self:UpdateUnits()
            end)
        elseif event == "UI_SCALE_CHANGED" then
            self.pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
            self:RefreshOverlays(true)
        end
    end)

    self:UpdateBuffs()
    UpdateAuraState()

    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    function SlashCmdList.BuffOverlay(msg)
        if msg == "help" or msg == "?" then
            self:Print(L["Command List"])
            print(format(L["%s or %s: Toggles the options panel."], self:Colorize("/buffoverlay", "accent"), self:Colorize("/bo", "accent")))
            print(format(L["%s %s: Shows test icons on all visible raid/party frames."], self:Colorize("/bo", "accent"), self:Colorize("test", "value")))
            print(format(L["%s %s: Toggles the minimap icon."], self:Colorize("/bo", "accent"), self:Colorize("minimap", "value")))
            print(format(L["%s %s: Shows a copyable version string for bug reports."], self:Colorize("/bo", "accent"), self:Colorize("version", "value")))
            print(format(L["%s %s: Resets current profile to default settings. This does not remove any custom auras."], self:Colorize("/bo", "accent"), self:Colorize("reset", "value")))
        elseif msg == "test" then
            self:Test()
        elseif msg == "reset" or msg == "default" then
            self.db:ResetProfile()
        elseif msg == "minimap" then
            self:ToggleMinimapIcon()
        elseif msg == "version" then
            self:ShowVersion()
        else
            self:ToggleOptions()
        end
    end
end

function BuffOverlay:RefreshOverlays(full, barName)
    -- fix for resetting profile with buffs active
    if next(self.db.profile.buffs) == nil then
        self:CreateBuffTable()
    end

    if full then
        for _, overlay in pairs(self.overlays) do
            if barName then
                if overlay.bar.id == barName then
                    overlay:StopAllGlows()
                    overlay:Hide()
                    overlay.needsUpdate = true
                end
            else
                overlay:StopAllGlows()
                overlay:Hide()
                overlay.needsUpdate = true
            end
        end
    end

    for unit, frames in pairs(self.unitFrames) do
        for frame in pairs(frames) do
            if frame:IsShown() then
                self:ApplyOverlay(frame, unit, barName)
            else
                HideAllOverlays(frame)
            end
        end
    end

    for frame in pairs(self.blizzFrames) do
        if frame:IsShown() then
            self:ApplyOverlay(frame, frame.displayedUnit, barName)
        else
            HideAllOverlays(frame)
        end
    end
end

function BuffOverlay:FullRefresh()
    if next(self.db.profile.bars) == nil then
        self:AddBar()
    end
    ValidateBarAttributes()
    self:UpdateBarOptionsTable()
    self:UpdateBuffs()
    self:RefreshOverlays(true)
    UpdateMinimapIcon()
end

local function GetTestAnchor()
    local anchor = false
    if BuffOverlay.frames then
        for frame, info in pairs(BuffOverlay.frames) do
            if UnitIsPlayer(frame[info.unit]) and frame:IsShown() and frame:IsVisible() then
                anchor = frame

                local parent = frame:GetParent()
                while parent:GetSize() ~= UIParent:GetSize() and parent ~= ElvUF_Parent and parent:IsShown() and
                    parent:IsVisible() do
                    anchor = parent
                    parent = parent:GetParent()
                end

                break
            end
        end
    end
    return anchor
end

local function HideTestFrames()
    if BuffOverlay.test then return end
    if isRetail then
        if EditModeManagerFrame and EditModeManagerFrame.editModeActive then return end
        UpdateRaidAndPartyFrames()
    elseif CompactRaidFrameManager and GetNumGroupMembers() == 0 then
        CompactRaidFrameManager:Hide()
        CompactRaidFrameContainer:Hide()
        if CompactPartyFrame then
            CompactPartyFrame:Hide()
        end
    end
end

local combatDropUpdate = CreateFrame("Frame")
combatDropUpdate:SetScript("OnEvent", function(self)
    HideTestFrames()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end)

function BuffOverlay:GetSingleTestAura()
    return testSingleAura
end

function BuffOverlay:Test(barName, singleAura)
    self:UpdateUnits()

    testSingleAura = singleAura

    if InCombatLockdown() then
        if self.test then
            self.test = false
            if testTextFrame then
                testTextFrame:Hide()
            end
            self:RefreshOverlays()
            combatDropUpdate:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:Print(L["Exiting test mode. Frame visibility will update out of combat."])
            return
        else
            self:Print(ERR_AFFECTING_COMBAT)
        end

        return
    end

    if not self.test then
        if not testTextFrame then
            testTextFrame = CreateFrame("Frame", "BuffOverlayTest", UIParent)
            testTextFrame.bg = testTextFrame:CreateTexture()
            testTextFrame.bg:SetAllPoints()
            testTextFrame.bg:SetColorTexture(1, 0, 0, 0.6)
            testTextFrame.text = testTextFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            testTextFrame.text:SetPoint("CENTER", 0, 0)
            testTextFrame.text:SetFormattedText("BuffOverlay %s", L["Test"])
            testTextFrame:SetSize(testTextFrame.text:GetWidth() + 20, testTextFrame.text:GetHeight() + 2)
            testTextFrame:EnableMouse(false)
        end

        testTextFrame:Hide()

        if GetNumGroupMembers() == 0 then
            if CompactRaidFrameManager then
                CompactRaidFrameManager:Show()
                CompactRaidFrameContainer:Show()
                if CompactPartyFrame then
                    CompactPartyFrame:Show()
                    if PartyFrame and PartyFrame.UpdatePaddingAndLayout then
                        PartyFrame:UpdatePaddingAndLayout()
                    end
                end
            end
        end

        -- self:Print("Test mode activated.")
        testTextFrame:ClearAllPoints()

        local anchor = false
        if CompactRaidFrameManager then
            local container = _G["PartyFrame"] or _G["CompactRaidFrameContainer"]

            if container and container:IsShown() and container:IsVisible() then
                anchor = container
            end
        end

        if not anchor then
            anchor = GetTestAnchor()
        end

        if not anchor then
            self:UpdateUnits()
            C_Timer.After(0.1, function()
                anchor = GetTestAnchor()

                if not anchor then
                    self:Print(format(L["%s Frames need to be visible in order to see test icons. If you are using a non-Blizzard frame addon, you will need to make the frames visible either by joining a group or through that addon's settings."], self:Colorize(LABEL_NOTE, "accent")))
                    testTextFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                else
                    testTextFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
                end

                testTextFrame:Show()
            end)
        else
            testTextFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
            testTextFrame:Show()
        end
    end

    if barName then
        testBarNames[barName] = testBarNames[barName] == nil and self.db.profile.bars[barName] or nil
    else
        local allBars = true
        for k in pairs(self.db.profile.bars) do
            if testBarNames[k] == nil then
                allBars = false
                break
            end
        end

        if allBars then
            wipe(testBarNames)
        end
    end

    if next(testBarNames) == nil and self.test then
        self.test = false
        if InCombatLockdown() then
            combatDropUpdate:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:Print(L["Exiting test mode. Frame visibility will update out of combat."])
        else
            HideTestFrames()
            -- self:Print("Exiting test mode.")
        end
        testTextFrame:Hide()
        self:RefreshOverlays()
        return
    else
        self.test = true
    end

    if not barName then
        if next(testBarNames) ~= nil then
            wipe(testBarNames)
        end
    end

    if self.test and next(testBarNames) ~= nil then
        for _, frames in pairs(self.unitFrames) do
            for frame in pairs(frames) do
                if frame:IsShown() then
                    HideAllOverlays(frame)
                end
            end
        end

        for frame in pairs(self.blizzFrames) do
            if frame:IsShown() then
                HideAllOverlays(frame)
            end
        end
    end

    self:RefreshOverlays()
end

local function SetOverlayAura(overlay, index, icon, count, duration, expirationTime, dispelType, filter, spellId)
    local bar = overlay.bar

    overlay.icon:SetTexture(icon)

    if count > 1 then
        local countText = count
        if (count >= 100) then
            countText = BUFF_STACKS_OVERFLOW
        end
        overlay.count:Show()
        overlay.count:SetText(countText)
    else
        overlay.count:Hide()
    end

    overlay:SetID(index)
    overlay.filter = filter
    overlay.spellId = spellId

    local enabled = expirationTime and expirationTime ~= 0
    if enabled then
        local startTime = expirationTime - duration
        CooldownFrame_Set(overlay.cooldown, startTime, duration, true)
    else
        CooldownFrame_Clear(overlay.cooldown)
    end

    if overlay.border and bar.iconBorder then
        if bar.debuffIconBorderColorByDispelType and filter == "HARMFUL" then
            local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
            overlay.border:SetVertexColor(color.r, color.g, color.b, bar.iconBorderColor.a)
        elseif bar.buffIconBorderColorByDispelType and filter == "HELPFUL" then
            local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
            overlay.border:SetVertexColor(color.r, color.g, color.b, bar.iconBorderColor.a)
        else
            overlay.border:SetVertexColor(bar.iconBorderColor.r, bar.iconBorderColor.g, bar.iconBorderColor.b, bar.iconBorderColor.a)
        end
    end

    overlay:Show()
end

local function UpdateGlowSize(overlay)
    local glow = overlay.glow
    local w, h = overlay:GetSize()
    glow:SetSize(w * 1.3, h * 1.3)
end

local function SetupGlow(overlay)
    if not overlay.glow then
        -- Use this frame to ensure the glow is always on top
        local glow = CreateFrame("Frame", nil, overlay)
        glow:SetPoint("CENTER", overlay, "CENTER", 0, 0)
        glow:SetFrameLevel(overlay:GetFrameLevel() + 6)
        overlay.glow = glow
    end

    if not overlay.StopAllGlows then
        overlay.StopAllGlows = function(self)
            LCG.ButtonGlow_Stop(self.glow)
            LCG.PixelGlow_Stop(self)
            LCG.ProcGlow_Stop(self)

            self.glow:Hide()
            self.glowing = false
        end
    end

    overlay.glow:Hide()
end

function BuffOverlay:HideGlows()
    for _, overlay in pairs(self.overlays) do
        overlay:StopAllGlows()
    end
end

local borderPieces = {
    "Top",
    "Bottom",
    "Left",
    "Right",
}

local function DisablePixelSnap(overlay)
    local border = overlay.border
    local icon = overlay.icon

    for _, pieceName in pairs(borderPieces) do
        local piece = border[pieceName]
        if piece then
            piece:SetTexelSnappingBias(0.0)
            piece:SetSnapToPixelGrid(false)
        end
    end

    icon:SetTexelSnappingBias(0.0)
    icon:SetSnapToPixelGrid(false)
end

local function UpdateBorder(overlay)
    local bar = overlay.bar

    if overlay.__MSQ_Enabled and bar.iconBorder then
        bar.iconBorder = false
    end

    -- zoomed in/out
    if bar.iconBorder then
        overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        overlay.icon:SetTexCoord(0, 1, 0, 1)
    end

    if not overlay.border then
        overlay.border = CreateFrame("Frame", nil, overlay, "BuffOverlayBorderTemplate")
        overlay.border:SetFrameLevel(overlay:GetFrameLevel() + 5)
        overlay.border.SetFrameLevel = nop

        DisablePixelSnap(overlay)
    end

    local border = overlay.border
    local size = bar.iconBorderSize - 1
    local borderColor = bar.iconBorderColor

    local pixelFactor = BuffOverlay.pixelFactor
    local pixelSize = (pixelFactor / 2) + (pixelFactor * size)

    border:SetBorderSizes(pixelSize, pixelSize, pixelSize, pixelSize)
    border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    border:UpdateSizes()

    border:SetShown(bar.iconBorder)

    UpdateGlowSize(overlay)
end

function BuffOverlay:SetupContainer(frame)
    frame.BuffOverlays = frame.BuffOverlays or CreateFrame("Frame", frame:GetName() .. "BuffOverlayContainer", frame)
    frame.BuffOverlays:SetAllPoints()
end

local function sortAuras(a, b)
    return a[2] < b[2]
end

local function ShouldShow(bar, frameType)
    if not bar.frameTypes[frameType] then
        return false
    end

    if BuffOverlay.test then
        return true
    end

    local instanceType = BuffOverlay.instanceType
    local numGroupMembers = BuffOverlay.numGroupMembers

    if bar.neverShow
    or numGroupMembers > bar.maxGroupSize
    or numGroupMembers < bar.minGroupSize
    or instanceType == "none" and not bar.showInWorld
    or instanceType == "pvp" and not bar.showInBattleground
    or instanceType == "arena" and not bar.showInArena
    or instanceType == "party" and not bar.showInDungeon
    or instanceType == "raid" and not bar.showInRaid
    or instanceType == "scenario" and not bar.showInScenario
    then
        return false
    end

    return true
end

BuffOverlay.UnitAura = function(unit, index, filter)
    local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)

    if aura then
        return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, nil, nil, aura.spellId
    else
        return nil
    end
end

function BuffOverlay:ApplyOverlay(frame, unit, barNameToApply)
    if not frame or not unit or frame:IsForbidden() or not frame:IsShown() then return end
    if string_find(unit, "target") or unit == "focus" then return end

    if not frame.BuffOverlays then
        self:SetupContainer(frame)
    end

    local frameName = frame:GetName()
    local frameType = self.frames[frame] and self.frames[frame].type
    local frameWidth, frameHeight = frame:GetSize()
    local overlaySize = round(math_min(frameHeight, frameWidth) * 0.33, 1)
    local UnitAura = self.test and UnitAuraTest or self.UnitAura

    local bars = next(testBarNames) ~= nil and testBarNames or self.db.profile.bars

    for barName, bar in pairs(bars) do
        if ShouldShow(bar, frameType) and not (barNameToApply and barName ~= barNameToApply) then
            if Masque and not bar.group then
                bar.group = Masque:Group("BuffOverlay", bar.name, barName)
                bar.group:RegisterCallback(masqueCallback)

                BuffOverlay:RefreshOverlays(true, barName)
            end

            local overlayName = frameName .. "BuffOverlay" .. barName .. "Icon"
            local relativeSpacing = overlaySize * (bar.iconSpacing / 20)

            for i = 1, bar.iconCount do
                ---@class overlay
                local overlay = self.overlays[overlayName .. i]

                if not overlay
                or overlay.needsUpdate
                or overlay.size ~= overlaySize
                then
                    if not overlay then
                        overlay = CreateFrame("Button", overlayName .. i, frame.BuffOverlays, "CompactAuraTemplate")
                        overlay.stack = CreateFrame("Frame", overlayName .. i .. "StackCount", overlay)
                        overlay.barName = barName
                        SetupGlow(overlay)
                    end

                    if bar.group and not overlay.__MSQ_Enabled then
                        bar.group:AddButton(overlay)
                    end

                    overlay.bar = bar
                    overlay.size = overlaySize

                    if overlay.size <= 0 then
                        overlay.needsUpdate = true
                        return
                    else
                        overlay.needsUpdate = false
                    end

                    overlay.cooldown:SetDrawSwipe(bar.showCooldownSpiral)
                    overlay.cooldown:SetHideCountdownNumbers(not bar.showCooldownNumbers)
                    overlay.cooldown:SetScale(overlay.__MSQ_Enabled and 1 or (bar.cooldownNumberScale * overlaySize / 36))

                    if bar.showTooltip and not overlay:GetScript("OnEnter") then
                        overlay:SetScript("OnEnter", function(s)
                            GameTooltip:SetOwner(s, "ANCHOR_BOTTOMRIGHT")

                            if self.test then
                                GameTooltip:SetSpellByID(s.spellId)
                            else
                                GameTooltip:SetUnitAura(s.unit, s:GetID(), s.filter)
                            end
                        end)

                        overlay:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                    elseif not bar.showTooltip and overlay:GetScript("OnEnter") then
                        overlay:SetScript("OnEnter", nil)
                        overlay:SetScript("OnLeave", nil)
                    end

                    overlay:SetScale(bar.iconScale)
                    overlay:SetAlpha(bar.iconAlpha)
                    overlay:SetSize(overlaySize, overlaySize)

                    if bar.group then
                        bar.group:ReSkin(overlay)
                    end

                    if bar.showTooltip then
                        overlay:SetMouseClickEnabled(false)
                    else
                        overlay:EnableMouse(false)
                    end
                    overlay:RegisterForClicks()

                    -- Fix for addons that recursively change its children's frame levels
                    if overlay.SetFrameLevel ~= nop then
                        overlay:SetFrameLevel(math_max(frame:GetFrameLevel() + 20, 999))
                        overlay.stack:SetFrameLevel(overlay:GetFrameLevel() + 10)
                        overlay.SetFrameLevel = nop
                        overlay.stack.SetFrameLevel = nop
                    end

                    if overlay.cooldown.SetFrameLevel ~= nop then
                        overlay.cooldown:SetFrameLevel(overlay:GetFrameLevel() + 1)
                        overlay.cooldown.SetFrameLevel = nop
                    end

                    overlay.count:SetScale(bar.stackCountScale * overlay.size / 20)
                    overlay.count:ClearPointsOffset()
                    overlay.count:SetParent(overlay.stack)
                    overlay.stack:SetShown(bar.showStackCount)

                    overlay:ClearAllPoints()

                    UpdateBorder(overlay)

                    overlay.spacing = relativeSpacing + (bar.iconBorder and ((overlay.border.borderSize * 3) / bar.iconScale) or 0)

                    if i == 1 then
                        overlay:SetPoint(bar.iconAnchor, frame.BuffOverlays, bar.iconRelativePoint, bar.iconXOff, bar.iconYOff)
                    else
                        local prevOverlay = self.overlays[overlayName .. (i - 1)]

                        if bar.growDirection == "DOWN" then
                            overlay:SetPoint("TOP", prevOverlay, "BOTTOM", 0, -overlay.spacing)
                        elseif bar.growDirection == "LEFT" then
                            overlay:SetPoint("BOTTOMRIGHT", prevOverlay, "BOTTOMLEFT", -overlay.spacing, 0)
                        elseif bar.growDirection == "UP" or bar.growDirection == "VERTICAL" then
                            overlay:SetPoint("BOTTOM", prevOverlay, "TOP", 0, overlay.spacing)
                        else
                            overlay:SetPoint("BOTTOMLEFT", prevOverlay, "BOTTOMRIGHT", overlay.spacing, 0)
                        end
                    end

                    self.overlays[overlayName .. i] = overlay
                end
                overlay.unit = unit
                -- overlay:Hide()
            end

            if not self.priority[barName] then
                self.priority[barName] = {}
            end

            if next(self.priority[barName]) ~= nil then
                wipe(self.priority[barName])
            end
        end
    end

    -- TODO: Optimize this with new UNIT_AURA event payload
    for _, filter in ipairs(filters) do
        for i = 1, 40 do
            local spellName, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = UnitAura(unit, i, filter)
            if spellId then
                local aura = self.db.profile.buffs[spellId] or self.db.profile.buffs[spellName]

                if aura then
                    local castByPlayerOrPlayerPet = source == "player" or source == "pet" or source == "vehicle"

                    if aura.parent and not self.ignoreParentIcons[aura.parent] then
                        icon = self.customIcons[aura.parent] or select(3, GetSpellInfo(aura.parent)) or icon
                    elseif self.customIcons[spellId] then
                        icon = self.customIcons[spellId]
                    end

                    for barName, bar in pairs(bars) do
                        if ShouldShow(bar, frameType)
                        and not (barNameToApply and barName ~= barNameToApply)
                        and (aura.state[barName].enabled or self.test)
                        and (not aura.state[barName].ownOnly or (aura.state[barName].ownOnly and castByPlayerOrPlayerPet))
                        then
                            rawset(self.priority[barName], #self.priority[barName] + 1, { i, aura.prio, icon, count, duration, expirationTime, dispelType, filter, aura, spellId })
                        end
                    end
                end
            else
                break
            end
        end
        if self.test then break end
    end

    for barName, bar in pairs(bars) do
        if ShouldShow(bar, frameType) and not (barNameToApply and barName ~= barNameToApply) then
            local overlayName = frameName .. "BuffOverlay" .. barName .. "Icon"
            local overlayNum = 1
            local activeOverlays = 0

            if #self.priority[barName] > 1 then
                table_sort(self.priority[barName], sortAuras)
            end

            while overlayNum <= bar.iconCount do
                local data = self.priority[barName][overlayNum]
                local olay = self.overlays[overlayName .. overlayNum]

                if data then
                    local glow = data[9].state[barName].glow
                    local pixelBorderSize = bar.iconBorder and (olay.border.borderSize + 1) or 1.2

                    if glow.enabled then
                        local color = glow.customColor and glow.color or nil

                        if olay.glowing ~= glow.type then
                            olay:StopAllGlows()
                        end

                        if glow.type == "blizz" then
                            olay.border:Hide()
                            if isRetail then
                                LCG.ProcGlow_Start(olay, { color = color, startAnim = false, xOffset = 1, yOffset = 1 })
                            else
                                LCG.ButtonGlow_Start(olay.glow, color)
                            end
                        elseif glow.type == "pixel" then
                            LCG.PixelGlow_Start(olay, color, glow.n, glow.freq, glow.length, pixelBorderSize, glow.xOff, glow.yOff, glow.border, glow.key)
                        elseif glow.type == "oldBlizz" then
                            olay.border:Hide()
                            LCG.ButtonGlow_Start(olay.glow, color)
                        end
                        olay.glow:Show()
                        olay.glowing = glow.type
                    else
                        olay.border:SetShown(bar.iconBorder)
                        if olay.glowing then
                            olay:StopAllGlows()
                            olay.glow:Hide()
                        end
                    end

                    SetOverlayAura(olay, data[1], data[3], data[4], data[5], data[6], data[7], data[8], data[10])

                    activeOverlays = activeOverlays + 1
                else
                    olay:Hide()
                end

                overlayNum = overlayNum + 1
            end

            if activeOverlays > 0 and (bar.growDirection == "HORIZONTAL" or bar.growDirection == "VERTICAL") then
                local overlay1 = self.overlays[overlayName .. 1]
                local width, height = overlay1:GetSize()
                local point, relativeTo, relativePoint, xOfs, yOfs = overlay1:GetPoint()

                local x = bar.growDirection == "HORIZONTAL" and (-(width / 2) * (activeOverlays - 1) + bar.iconXOff - (((activeOverlays - 1) / 2) * overlay1.spacing)) or xOfs
                local y = bar.growDirection == "VERTICAL" and (-(height / 2) * (activeOverlays - 1) + bar.iconYOff - (((activeOverlays - 1) / 2) * overlay1.spacing)) or yOfs

                overlay1:SetPoint(point, relativeTo, relativePoint, x, y)
            end
        end
    end
end

-- For Blizzard Frames
hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
    if not frame.buffFrames then return end

    BuffOverlay:ApplyOverlay(frame, frame.displayedUnit)
end)
