local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")

local _G, pairs, IsAddOnLoaded, next = _G, pairs, IsAddOnLoaded, next
local addOnsExist = true
local enabledPatterns = {}
local framesToFind = {}
local tempFrameCache = {}

BuffOverlay.frames = {}

local addonFrameInfo = {
    ["ElvUI"] = {
        {
            frame = "^ElvUF_Raid%d+Group%dUnitButton%d+$",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^ElvUF_PartyGroup1UnitButton%d+$",
            type = "party",
            unit = "unit",
        },
        {
            frame = "^ElvUF_RaidpetGroup%dUnitButton%d+$",
            type = "pet",
            unit = "unit",
        },
        {
            frame = "^ElvUF_TankUnitButton%d$",
            type = "tank",
            unit = "unit",
        },
        {
            frame = "^ElvUF_AssistUnitButton%d$",
            type = "assist",
            unit = "unit",
        },
    },
    ["VuhDo"] = {
        {
            frame = "^Vd%dH%d+$",
            type = "raid",
            unit = "raidid",
        },
    },
    ["Grid"] = {
        {
            frame = "^GridLayout",
            type = "raid",
            unit = "unit",
        },
    },
    ["Grid2"] = {
        {
            frame = "^Grid2Layout",
            type = "raid",
            unit = "unit",
        },
    },
    ["HealBot"] = {
        {
            frame = "^HealBot_Action_HealUnit",
            type = "raid",
            unit = "unit",
        },
    },
    ["Cell"] = {
        {
            frame = "^CellRaidFrameHeader%d+UnitButton%d+$",
            type = "raid",
            unit = "unitid",
        },
        {
            frame = "^CellPartyFrameHeaderUnitButton%d+$",
            type = "party",
            unit = "unitid",
        },
        {
            frame = "^CellRaidFrameHeader%d+UnitButton%d+Pet$",
            type = "pet",
            unit = "unitid",
        },
        {
            frame = "^CellPartyFrameHeaderUnitButton%d+Pet$",
            type = "pet",
            unit = "unitid",
        },
        {
            frame = "^CellSoloFramePlayer$",
            type = "solo",
            unit = "unitid",
        },
        {
            frame = "^CellSoloFramePet$",
            type = "pet",
            unit = "unitid",
        },
    },
    ["Aptechka"] = {
        {
            frame = "^NugRaid%d+UnitButton%d+",
            type = "raid",
            unit = "unit",
        },
    },
    ["InvenRaidFrames3"] = {
        {
            frame = "^InvenRaidFrames3Group%dUnitButton",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^InvenUnitFrames_Party%d",
            type = "party",
            unit = "unit",
        },
    },
    ["Lime"] = {
        {
            frame = "^LimeGroup",
            type = "raid",
            unit = "unit",
        },
    },
    ["Plexus"] = {
        {
            frame = "^PlexusLayoutHeader%dUnitButton",
            type = "raid",
            unit = "unit",
        },
    },
    ["Tukui"] = {
        {
            frame = "TuikuiPartyUnitButton",
            type = "party",
            unit = "unit",
        },
        {
            frame = "TukuiRaidUnitButton",
            type = "raid",
            unit = "unit",
        },
    },
    ["ShadowedUnitFrames"] = {
        {
            frame = "^SUFHeaderraidUnitButton",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^SUFHeaderraid%dUnitButton",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^SUFHeaderpartyUnitButton",
            type = "party",
            unit = "unit",
        },
    },
    ["ZPerl"] = {
        {
            frame = "^XPerl_Raid",
            type = "raid",
            unit = "partyid",
        },
    },
    ["PitBull4"] = {
        {
            frame = "^PitBull4_Groups_Party",
            type = "raid",
            unit = "unit",
        },
    },
    ["NDui"] = {
        {
            frame = "^oUF_.-Party",
            type = "party",
            unit = "unit",
        },
        {
            frame = "^oUF_.-Raid",
            type = "raid",
            unit = "unit",
        },
    },
    ["oUF"] = {
        {
            frame = "^oUF_.-Party",
            type = "party",
            unit = "unit",
        },
        {
            frame = "^oUF_.-Raid",
            type = "raid",
            unit = "unit",
        },
    },
    ["KkthxUI"] = {
        {
            frame = "^oUF_.-Party",
            type = "party",
            unit = "unit",
        },
        {
            frame = "^oUF_.-Raid",
            type = "raid",
            unit = "unit",
        },
    },
    ["GW2_UI"] = {
        {
            frame = "^GwCompactRaidFrame",
            type = "raid",
            unit = "unit",
        },
    },
    ["AltzUI"] = {
        {
            frame = "^Altz_HealerRaidUnitButton",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^Altz_DpsRaidUnitButton",
            type = "raid",
            unit = "unit",
        },
    },
    ["AshToAsh"] = {
        {
            frame = "^AshToAshUnit%d+Unit%d+",
            type = "raid",
            unit = "unit",
        },
    },
    ["LunaUnitFrames"] = {
        {
            frame = "^LUFHeaderpartyUnitButton%d+",
            type = "party",
            unit = "unit",
        },
        {
            frame = "^LUFHeaderraid%d+UnitButton%d+",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^LUFHeadermaintankUnitButton%d+",
            type = "tank",
            unit = "unit",
        },
    },
}

local function AddOnsExist()
    local addonsExist = false
    for addon, info in pairs(addonFrameInfo) do
        if IsAddOnLoaded(addon) then
            for _, frameInfo in pairs(info) do
                enabledPatterns[frameInfo.frame] = { unit = frameInfo.unit }
            end

            if not addonsExist then
                addonsExist = true
            end

            -- Fix for ElvUI Party Pet Frames. They are not in the frame cache due
            -- to the way ElvUI creates them. This is unique to party pets, thankfully.
            if addon == "ElvUI" then
                for i = 1, 5 do
                    framesToFind["ElvUF_PartyGroup1UnitButton" .. i .. "Pet"] = "unit"
                end
            end
        end
    end
    addOnsExist = addonsExist
    return addonsExist
end

local function cleanFrameCache()
    for frame in pairs(tempFrameCache) do
        local name = frame:GetName()

        -- AshToAsh Fix
        if name:match("AshToAshUnit%dShadowGroupHeaderUnitButton") then
            local root = frame:GetParent():GetParent()
            local frames = { root:GetChildren() }
            local data = addonFrameInfo["AshToAsh"][1]

            for _, f in pairs(frames) do
                if f:GetName():match(data.frame) then
                    BuffOverlay.frames[f] = { unit = data.unit }
                end
            end
        else
            for addOnFramePattern, data in pairs(enabledPatterns) do
                if name:match(addOnFramePattern) then
                    BuffOverlay.frames[frame] = { unit = data.unit }
                    break
                end
            end
        end

        tempFrameCache[frame] = nil
    end
end

local function updateUnits()
    cleanFrameCache()

    if next(framesToFind) ~= nil then
        for f, data in pairs(framesToFind) do
            local frame = _G[f]
            if frame and not BuffOverlay.frames[frame] then
                BuffOverlay.frames[frame] = { data.unit }
                framesToFind[f] = nil
            end
        end
    end

    for frame, data in pairs(BuffOverlay.frames) do
        local unit = frame[data.unit] or SecureButton_GetUnit(frame)

        if unit and not data.blizz then
            BuffOverlay:AddUnitFrame(frame, unit)
        end
    end
    BuffOverlay:RefreshOverlays()
end

function BuffOverlay:UpdateUnits()
    if not addOnsExist then return end
    -- Some addons take a second to load their frames fully.
    -- updateUnits() is cheap so we'll just run it twice.
    updateUnits()
    C_Timer.After(1, updateUnits)
end

function BuffOverlay:InitFrames()
    -- Double wait to make sure all addons are loaded.
    -- PLAYER_LOGIN fires too early.
    C_Timer.After(0, function()
        C_Timer.After(0, function()
            -- Blizzard frames are handled differently so if we have no supported addons
            -- installed then we don't need to waste cycles scanning for frames.
            if AddOnsExist() then
                self.eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
                self.eventHandler:RegisterEvent("GROUP_ROSTER_UPDATE")
                self.eventHandler:RegisterEvent("UNIT_EXITED_VEHICLE")
                self.eventHandler:RegisterEvent("UNIT_ENTERED_VEHICLE")

                self:UpdateUnits()
            end
        end)
    end)
end

hooksecurefunc("CreateFrame", function(type, name)
    if not addOnsExist then return end

    if name and type == "Button" then
        local frame = _G[name]

        if frame and not frame:IsForbidden() then
            if not name:match("BuffOverlayBar") then
                tempFrameCache[frame] = true
            end
        end
    end
end)
