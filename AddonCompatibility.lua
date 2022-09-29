local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")

local pairs, IsAddOnLoaded = pairs, IsAddOnLoaded
local maxDepth = 50

local enabledFrameNames = {}

BuffOverlay.frames = {}

local addonFrameInfo = {
    ["ElvUI"] = {
        {
            frame = "^ElvUF_Raid",
            type = "raid",
            unit = "unit",
        },
        {
            frame = "^ElvUF_Party",
            type = "party",
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
            frame = "^Vd",
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
            frame = "^HealBot",
            type = "raid",
            unit = "unit",
        },
    },
    ["Cell"] = {
        {
            frame = "^Cell",
            type = "raid",
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
            frame = "^PlexusLayout",
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
            frame = "^SUFHeader",
            type = "raid",
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
            frame = "^GwCompactRaid",
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
    }
}

local function CheckEnabledAddOns()
    for addon, info in pairs(addonFrameInfo) do
        if IsAddOnLoaded(addon) then
            for _, frameInfo in pairs(info) do
                enabledFrameNames[frameInfo.frame] = { unit = frameInfo.unit }
            end
        end
    end
end

local function ScanFrames(depth, frame, ...)
    if not frame then return end

    if depth < maxDepth and frame.IsForbidden and not frame:IsForbidden() then
        local type = frame:GetObjectType()
        if type == "Frame" or type == "Button" then
            ScanFrames(depth + 1, frame:GetChildren())

            local name = frame:GetName()
            -- Make sure we only store unit frames
            local unit = SecureButton_GetUnit(frame)

            if name and unit and not BuffOverlay.frames[frame] then
                for enabledFrames, data in pairs(enabledFrameNames) do
                    if name:find(enabledFrames) then
                        BuffOverlay.frames[frame] = { unit = data.unit }
                        BuffOverlay:SetupContainer(frame)
                        break
                    end
                end
            end
        end
    end
    ScanFrames(depth, ...)
end

function BuffOverlay:UpdateUnits()
    for frame, data in pairs(self.frames) do
        local unit = frame[data.unit] or SecureButton_GetUnit(frame)

        if unit and not data.blizz then
            self:AddUnitFrame(frame, unit)
        end
    end
    self:RefreshOverlays()
end

function BuffOverlay:GetAllFrames()
    -- Timer is needed to account for addons that have a delay in creating their frames
    C_Timer.After(1, function()
        ScanFrames(0, UIParent)
        self:UpdateUnits()
    end)
end

function BuffOverlay:InitFrames()
    -- Double wait to make sure all addons are loaded.
    -- PLAYER_LOGIN fires too early.
    C_Timer.After(0, function()
        C_Timer.After(0, function()
            CheckEnabledAddOns()
            ScanFrames(0, UIParent)
            self:UpdateUnits()
        end)
    end)
end
