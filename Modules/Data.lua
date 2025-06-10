local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Data: AceModule
local Data = Addon:GetModule('Data')

---@class Aura: AceModule
local Aura = Addon:GetModule('Aura')

--[[
    These confusing frame structures are a holdover from legacy code.
    -- TODO: Fix frame reference data structures
]]
local frames = {}
local framesPerUnit = {}
local blizzFrames = {}
local units = {}

Data.instanceType = "none"
Data.numGroupMembers = 0

local function InitUnitFrames()
    for unit in pairs(units) do
        framesPerUnit[unit] = {}
    end
end

local function InitUnits()
    local container = CreateFrame("Frame", addonName .. "Container", UIParent)

    for i = 1, 40 do
        units["raid" .. i] = CreateFrame("Frame", addonName .. "Raid" .. i, container)
        units["raidpet" .. i] = CreateFrame("Frame", addonName .. "RaidPet" .. i, container)
    end
    for i = 1, 4 do
        units["party" .. i] = CreateFrame("Frame", addonName .. "Party" .. i, container)
        units["partypet" .. i] = CreateFrame("Frame", addonName .. "PartyPet" .. i, container)
    end
    units["player"] = CreateFrame("Frame", addonName .. "Player", container)
    units["pet"] = CreateFrame("Frame", addonName .. "Pet", container)

    InitUnitFrames()

    for unit, frame in pairs(units) do
        frame:SetScript("OnEvent", function()
            for f in pairs(framesPerUnit[unit]) do
                Aura:Update(f, unit)
            end
        end)

        frame:RegisterUnitEvent("UNIT_AURA", unit)
    end
end

function Data:AddUnitFrame(frame, unit)
    if not framesPerUnit[unit] then
        framesPerUnit[unit] = {}
    end

    -- Remove the frame if it exists for another unit
    for u in pairs(framesPerUnit) do
        if u ~= unit and framesPerUnit[u][frame] then
            framesPerUnit[u][frame] = nil
        end
    end

    framesPerUnit[unit][frame] = true
end

function Data:AddFrame(frame, unit, type, blizz)
    frames[frame] = {
        unit = unit,
        type = type,
        blizz = blizz,
    }
end

function Data:FrameExists(frame)
    return frames[frame] ~= nil
end

function Data:GetUnits()
    return units
end

function Data:GetUnitFrames()
    return framesPerUnit
end

function Data:GetFrames()
    return frames
end

function Data:GetBlizzFrames()
    return blizzFrames
end

function Data:AddBlizzardFrame(frame)
    blizzFrames[frame] = true
end

function Data:OnInitialize()
    InitUnits()
end
