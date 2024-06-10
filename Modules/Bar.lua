local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Bar: AceModule
local Bar = Addon:NewModule('Bar')

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Options: AceModule
local Options = Addon:GetModule('Options')

---@return number
function Bar:GetFirstUnusedNum(bars)
    local num = 1

    while bars["Bar" .. num] do
        num = num + 1
    end

    return num
end

function Bar:Add()
    local bars = DB:GetBars()
    local auras = DB:GetAuras()
    local name = "Bar" .. self:GetFirstUnusedNum(bars)

    bars[name] = CopyTable(Const.BAR_SETTINGS)

    local bar = bars[name]
    bar.name = name
    bar.id = name

    Options:TryAddBarToOptions(bar, name)

    for _, v in pairs(auras) do
        if v.state[name] == nil then
            v.state[name] = CopyTable(Const.AURA_STATE)
        end
    end

    if Masque then
        bar.group = Masque:Group(addonName, bar.name, name)
        bar.group:RegisterCallback(masqueCallback)
    end

    self:RefreshOverlays(true)
end

function Bar:Delete(name)
    local bars = DB:GetBars()
    local auras = DB:GetAuras()

    if bars[name].group then
        bars[name].group:Delete()
    end

    bars[name] = nil
    self.options.args.bars.args[name] = nil
    testBarNames[name] = nil

    for _, v in pairs(auras) do
        if v.state then
            v.state[name] = nil
        end
    end

    self:RefreshOverlays(true)
end
