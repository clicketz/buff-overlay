local addonName = ... ---@type string

---@class BuffOverlay: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Spells: AceModule
---@field private default table<number, table>
local spells = addon:NewModule('Spells')

spells.default = {}

function spells:Add(class, spellId, prio)
    self.default[spellId] = {
        class = class,
        prio = prio,
    }
end

function spells:AddChild(spellId, parentId)
    self.default[spellId] = {
        parent = parentId,
    }
end

function spells:Get(spellId)
    return self.default[spellId]
end
