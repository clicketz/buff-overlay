local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Test: AceModule
local Test = Addon:NewModule('Test')

---@class Data: AceModule
local Data = Addon:GetModule('Data')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Compatibility: AceModule
local Compat = Addon:GetModule('Compatibility')

local testModeEnabled = false
local testAuras = {}
local testAuraIds = {}
local testBarNames = {}
local testSingleAura
local testTextFrame

function Test:On()
    testModeEnabled = true
end

function Test:Off()
    testModeEnabled = false
end

---@return boolean
function Test:IsEnabled()
    return testModeEnabled
end

---@return number
function Test:GetSingleTestAura()
    return testSingleAura
end

function Test:GetTestBarNames()
    return testBarNames
end

function Test:InsertAura(spellId)
    local tex = GetSpellTexture(spellId)
    if tex and not testAuraIds[spellId] then
        rawset(testAuras, #testAuras + 1, { spellId, tex })
        rawset(testAuraIds, spellId, true)
    end
end

function Test:UnitAura(_, index, filter)
    if testSingleAura then
        local icon = Const.CUSTOM_ICONS[testSingleAura] or select(3, GetSpellInfo(testSingleAura)) or Const.CUSTOM_ICONS["?"]
        local key = testSingleAura

        return key, icon, 3, nil, 60, GetTime() + 60, "player", nil, nil, testSingleAura
    else
        local buff = testAuras[index]
        local dispelType = Const.DISPEL_TYPES[math.rand(1, 5)]

        if not buff then return end

        return "TestBuff", buff[2], 3, dispelType, 60, GetTime() + 60, "player", nil, nil, buff[1]
    end
end

---@return table|boolean
local function GetTestAnchor()
    local anchor = false
    for frame, info in pairs(Data:GetAllFrames()) do
        if UnitIsPlayer(frame[info.unit])
        and frame:IsShown()
        and frame:IsVisible() then
            anchor = frame

            local parent = frame:GetParent()
            while parent:GetSize() ~= UIParent:GetSize()
                and parent ~= ElvUF_Parent
                and parent:IsShown()
                and parent:IsVisible()
            do
                anchor = parent
                parent = parent:GetParent()
            end

            break
        end
    end
    return anchor
end

local function HideTestFrames()
    if Test:IsEnabled() then return end

    if EditModeManagerFrame then
        if EditModeManagerFrame.editModeActive then return end
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

---@param barName string
---@param singleAura number
function Test:Toggle(barName, singleAura)
    Compat:UpdateUnits()

    testSingleAura = singleAura

    if InCombatLockdown() then
        if testModeEnabled then
            Test:Off()
            if testTextFrame then
                testTextFrame:Hide()
            end
            self:RefreshOverlays()
            combatDropUpdate:RegisterEvent("PLAYER_REGEN_ENABLED")
            Util:Print(L["Exiting test mode. Frame visibility will update out of combat."])
            return
        else
            Util:Print(ERR_AFFECTING_COMBAT)
        end

        return
    end

    if not testModeEnabled then
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

        testTextFrame:ClearAllPoints()

        local anchor = false
        if CompactRaidFrameManager then
            local container = _G.PartyFrame or _G.CompactRaidFrameContainer

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

    if next(testBarNames) == nil and testModeEnabled then
        Test:Off()
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
        Test:On()
    end

    if not barName then
        if next(testBarNames) ~= nil then
            wipe(testBarNames)
        end
    end

    if testModeEnabled and next(testBarNames) ~= nil then
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
