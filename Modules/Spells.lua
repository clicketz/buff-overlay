local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Spells: AceModule
---@field private default table<number, table>
local Spells = Addon:NewModule('Spells')

---@class Database: AceModule
local DB = Addon:GetModule('Database')

Spells.default = {}

---Add a spell to the default
---@param class string class name
---@param spellId number
---@param prio number priority: lower number has higher priority
function Spells:AddDefault(class, spellId, prio)
    self.default[spellId] = {
        class = class,
        prio = prio,
    }
end

function Spells:AddChild(spellId, parentId)
    self.default[spellId] = {
        parent = parentId,
    }
end

function Spells:Get(spellId)
    return self.default[spellId]
end

---@param spellId number
---@param tbl table
function Spells:Set(spellId, tbl)
    self.default[spellId] = tbl
end

---@param spellId number
function Spells:Remove(spellId)
    self.default[spellId] = nil
end

function Spells:GetAllDefault()
    return Spells.default
end
