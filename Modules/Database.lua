local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Database: AceModule
local DB = Addon:NewModule('Database')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Options: AceModule
local Options = Addon:GetModule('Options')

---@class Spells: AceModule
local Spells = Addon:GetModule('Spells')

---@class LDB: AceModule
local LDB = Addon:GetModule('LDB')

---@class Bar: AceModule
local Bar = Addon:GetModule('Bar')

---@return DatabaseDefaults
function DB:GetData()
    return self.data
end

function DB:GetCustomAuras()
    return self.data.global.customAuras
end

function DB:GetAuras()
    return self.data.profile.auras
end

---@return table
function DB:GetBars()
    return self.data.profile.bars
end

---@return table
function DB:GetMinimap()
    return self.data.profile.minimap
end

---@return boolean
function DB:WelcomeMessageEnabled()
    return self.data.profile.welcomeMessage
end

---@return boolean
function DB:IsMinimapHidden()
    return self.data.profile.minimap.hide
end

function DB:ToggleMinimapIcon()
    self.data.profile.minimap.hide = not self.data.profile.minimap.hide
end

---@param spellId number
---@return boolean
function DB:InsertCustomAura(spellId)
    if not C_Spell.DoesSpellExist(spellId) then
        return false
    end

    local custom = self.data.global.customAuras

    if not custom[spellId] and not self.data.profile.auras[spellId] then
        custom[spellId] = {
            class = "MISC",
            prio = 100,
            custom = true
        }
        return true
    elseif not custom[spellId] and self.data.profile.auras[spellId] then
        custom[spellId] = {
            class = self.data.profile.auras[spellId].class,
            prio = self.data.profile.auras[spellId].prio,
            custom = true,
        }
        return true
    end

    return false
end

function DB:InsertCustomChild(childId, parentId)
    if not C_Spell.DoesSpellExist(childId) then
        Util:Print(format(L["Invalid Spell ID %s"], Util:Colorize(childId)))
        return false
    end

    local custom = self.data.global.customAuras

    if not custom[childId] and not self.data.profile.auras[childId] then
        custom[childId] = {
            parent = parentId,
            custom = true,
        }
        return true
    end

    local pId = (custom[childId] and custom[childId].parent) or (self.data.profile.auras[childId] and self.data.profile.auras[childId].parent)

    if pId then
        local name, _, icon = GetSpellInfo(pId)
        Util:Print(format(L["%s is already being tracked under %s %s."], Util:Colorize(childId), Util:GetIconString(icon, 20), name))
    else
        local name, _, icon = GetSpellInfo(childId)
        Util:Print(format(L["%s %s is already being tracked."], Util:GetIconString(icon, 20), name))
    end

    return false
end

function DB:RemoveCustomChild(childId, parentId)
    local customAuras = self.data.global.customAuras
    local auras = self.data.profile.auras

    if auras[parentId] and auras[parentId].children then
        auras[parentId].children[childId] = nil

        if next(auras[parentId].children) == nil then
            auras[parentId].children = nil
            auras[parentId].UpdateChildren = nil
        end
    end

    customAuras[childId] = nil
    auras[childId] = nil
end

local function UpdateChildren(self)
    local db = DB:GetData()

    for child in pairs(self.children) do
        for k, v in pairs(self) do
            if k ~= "children" and k ~= "UpdateChildren" then
                if type(v) == "table" then
                    db.profile.auras[child][k] = CopyTable(v)
                else
                    db.profile.auras[child][k] = v
                end
            end
        end

        if db.profile.auras[child].custom and not self.custom then
            db.global.customAuras[child] = nil
            if Spells:Get(child) then
                db.profile.auras[child].custom = nil
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
function DB:UpdateAuraStates()
    local auras = self.data.profile.auras

    for _, aura in pairs(auras) do
        for _, state in pairs(aura.state) do
            for attr, info in pairs(Const.AURA_STATE) do
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
                        if Const.AURA_STATE[attr][k] == nil then
                            state[attr][k] = nil
                        end
                    end
                elseif Const.AURA_STATE[attr] == nil then
                    state[attr] = nil
                end
            end
        end
    end
end

function DB:UpdateCustomAuras()
    for spellId, v in pairs(self.data.global.customAuras) do
        -- Fix for old database entries
        if v.enabled then
            v.enabled = nil
        end

        if v.icon then
            self.customIcons[spellId] = v.icon
        elseif self.customIcons[spellId] then
            self.customIcons[spellId] = nil
        end

        if not self.data.profile.auras[spellId] then
            self.data.profile.auras[spellId] = {
                state = {},
            }
        end

        local aura = self.data.profile.auras[spellId]

        if not aura.state then
            aura.state = {}
        end

        for barName in pairs(self.data.profile.bars) do
            if aura.state[barName] == nil then
                aura.state[barName] = CopyTable(Const.AURA_STATE)
            end
        end

        local t = v.parent and self.data.global.customAuras[v.parent] or v

        for field, value in pairs(t) do
            if type(value) == "table" then
                aura[field] = CopyTable(value)
            else
                aura[field] = value
            end
        end

        if v.parent then
            local parent = self.data.profile.auras[v.parent]

            aura.parent = v.parent

            if parent then
                if not parent.children then
                    parent.children = {}
                    parent.UpdateChildren = UpdateChildren
                end
                parent.children[spellId] = true
                parent:UpdateChildren()
            end

            if aura.UpdateChildren then
                aura.UpdateChildren = nil
            end
        end

        if aura.children then
            aura:UpdateChildren()
        end

        InsertTestBuff(spellId)
    end

    self:UpdateSpellOptionsTable()
    self:RefreshOverlays()
end

function DB:ValidateAuraData()
    for k, v in pairs(self.data.profile.auras) do
        local spell = Spells:Get(k)

        if v.enabled then -- Fix for old database entries
            v.enabled = nil
        end

        if (not spell) and (not self.data.global.customAuras[k]) then
            self.data.profile.auras[k] = nil
        else
            if v.custom then
                if v.parent and not self.data.global.customAuras[v.parent] then
                    v.custom = nil
                elseif not self.data.global.customAuras[k] then
                    v.custom = nil
                end
            end

            if v.parent then -- child found
                -- Fix for updating parent info or updating a child to a non-parent
                if spell and not spell.parent then
                    v.parent = nil
                else
                    -- Fix for switching an old parent to a child
                    if v.children then
                        v.children = nil
                    end

                    if v.UpdateChildren then
                        v.UpdateChildren = nil
                    end

                    local parent = self.data.profile.auras[v.parent]

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
                                self.data.profile.auras[k][key] = CopyTable(val)
                            else
                                self.data.profile.auras[k][key] = val
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
                    local childData = Spells:Get(child)
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
    DB:UpdateCustomAuras()
end

function DB:CreateAuraTable()
    local newdb = false
    -- If the current profile doesn't have any buffs saved use default list and save it
    if next(self.data.profile.auras) == nil then
        for k, v in pairs(Spells:GetAllDefault()) do
            self.data.profile.auras[k] = {
                state = {},
            }

            for barName in pairs(self.data.profile.bars) do
                self.data.profile.auras[k].state[barName] = CopyTable(Const.AURA_STATE)
            end

            for key, val in pairs(v) do
                if type(val) == "table" then
                    self.data.profile.auras[k][key] = CopyTable(val)
                else
                    self.data.profile.auras[k][key] = val
                end
            end
        end
        newdb = true
        ValidateBuffData()
    end

    return newdb
end

function DB:UpdateAuras()
    if not self:CreateAuraTable() then
        -- Update buffs if any user changes are made to lua file
        for k, v in pairs(Spells:GetAllDefault()) do
            if v.parent then
                if self.data.global.customAuras[k] then
                    self.data.global.customAuras[k] = nil
                    self.options.args.customSpells.args[tostring(k)] = nil
                end
            end

            if not self.data.profile.auras[k] then
                self.data.profile.auras[k] = {
                    state = {},
                }

                for barName in pairs(self.data.profile.bars) do
                    self.data.profile.auras[k].state[barName] = CopyTable(Const.AURA_STATE)
                end

                for key, val in pairs(v) do
                    if type(val) == "table" then
                        self.data.profile.auras[k][key] = CopyTable(val)
                    else
                        self.data.profile.auras[k][key] = val
                    end
                end
            else
                if not self.data.profile.auras[k].state then
                    self.data.profile.auras[k].state = {}
                end

                for key, val in pairs(v) do
                    if type(val) == "table" then
                        self.data.profile.auras[k][key] = CopyTable(val)
                    else
                        self.data.profile.auras[k][key] = val
                    end
                end

                for barName in pairs(self.data.profile.bars) do
                    if self.data.profile.auras[k].state[barName] == nil then
                        self.data.profile.auras[k].state[barName] = CopyTable(Const.AURA_STATE)
                    end
                end
            end
        end
        self:ValidateAuraData()
    end
end

function DB:ValidateBarAttributes()
    if next(self.data.profile.bars) == nil then
        Bar:Add()
    end

    for name, bar in pairs(self.data.profile.bars) do
        if not bar.name then
            bar.name = name
        end

        if not bar.id then
            bar.id = name
        end

        for attr, val in pairs(Const.BAR_SETTINGS) do
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
                if Const.BAR_SETTINGS[attribute] == nil then
                    bar[attribute] = nil
                elseif type(Const.BAR_SETTINGS[attribute]) == "table" then
                    for key in pairs(bar[attribute]) do
                        if Const.BAR_SETTINGS[attribute][key] == nil then
                            bar[attribute][key] = nil
                        end
                    end
                end
            end
        end
    end
end

--d
function DB:ValidateSpellIds()
    for spellId in pairs(Spells:GetAllDefault()) do
        if type(spellId) == "number" then
            if not C_Spell.DoesSpellExist(spellId) then
                Spells:Remove(spellId)
                self.data.profile.auras[spellId] = nil
                self.data.global.customAuras[spellId] = nil
                Util:Print(format(L["Spell ID %s is invalid. If you haven't made any manual code changes, please report this to the author."], Util:Colorize(spellId)))
            end
        end
    end

    for spellId in pairs(self.data.profile.auras) do
        if type(spellId) == "number" then
            if not C_Spell.DoesSpellExist(spellId) then
                self.data.profile.auras[spellId] = nil
                self.data.global.customAuras[spellId] = nil
                Util:Print(format(L["Spell ID %s is invalid and has been removed."], Util:Colorize(spellId)))
            end
        end
    end

    for spellId in pairs(self.data.global.customAuras) do
        if type(spellId) == "number" then
            if not C_Spell.DoesSpellExist(spellId) then
                self.data.global.customAuras[spellId] = nil
                Util:Print(format(L["Spell ID %s is invalid and has been removed."], Util:Colorize(spellId)))
            end
        end
    end
end

--d
function DB:Validate()
    local dbVer = self.data.global.dbVer

    -- Clean up old DB entries
    local reset = false
    for _, content in pairs(self.data.profiles) do
        for attr in pairs(Const.BAR_SETTINGS) do
            if content[attr] ~= nil then
                Util:Print(format(L["There has been a major update and unfortunately your profiles need to be reset. Upside though, you can now add BuffOverlay aura bars in multiple locations on your frames! Check it out by typing %s in chat."], Util:Colorize("/bo", "accent")))
                self.data:ResetDB("Default")
                reset = true
                break
            end
        end
        if reset then break end
    end

    -- Changed from "buffs" to "auras" in 1.1
    if dbVer <= 1.0 then
        self.data.global.customAuras = CopyTable(self.data.global.customAuras)
        self.data.profile.auras = CopyTable(self.data.profile.auras)

        --TODO: Delete old db entries eventually...
    end

    self.data.global.dbVer = Const.LATEST_DB_VERSION
end

function DB:FullRefresh()
    if next(self.data.profile.bars) == nil then
        Bar:Add()
    end
    self:ValidateBarAttributes()
    self:UpdateBarOptionsTable()
    self:UpdateAuras()
    self:RefreshOverlays(true)
    LDB:UpdateMinimapIcon()
end

function DB:OnInitialize()
    self.data = LibStub("AceDB-3.0"):New(addonName .. "DB", Const.DB_DEFAULTS, true) --[[@as DatabaseDefaults]]

    self:Validate()
    self:ValidateSpellIds()
    self:ValidateBarAttributes()

    self.data.RegisterCallback(self, "OnProfileChanged", "FullRefresh")
    self.data.RegisterCallback(self, "OnProfileCopied", "FullRefresh")
    self.data.RegisterCallback(self, "OnProfileReset", "FullRefresh")
    self.data.RegisterCallback(self, "OnDatabaseReset", "FullRefresh")
end
