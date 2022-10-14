local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")

local _G = _G
local C_Spell = C_Spell
local C_Timer = C_Timer
local PixelUtil = PixelUtil
local CopyTable = CopyTable
local GetSpellTexture = GetSpellTexture
local UnitIsPlayer = UnitIsPlayer
local InCombatLockdown = InCombatLockdown
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid = IsInRaid
local GetCVarBool = GetCVarBool
local IsInInstance = IsInInstance
local select = select
local next = next
local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local type = type
local rawset = rawset
local CreateFrame = CreateFrame
local table_sort = table.sort
local string_find = string.find
local math_floor = math.floor
local math_min = math.min
local DebuffTypeColor = DebuffTypeColor

local TestBuffs = {}
local TestBuffIds = {}
local testTextFrame
local testBarNames = {}

local defaultBarSettings = {
    iconCount = 4,
    iconScale = 1,
    iconAlpha = 1.0,
    iconSpacing = 1,
    iconAnchor = "BOTTOM",
    iconRelativePoint = "CENTER",
    growDirection = "HORIZONTAL",
    showCooldownSpiral = true,
    showCooldownNumbers = false,
    cooldownNumberScale = 1,
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
    iconBorderSize = 1,
}

local defaultSettings = {
    profile = {
        welcomeMessage = true,
        bars = {},
        buffs = {},
    },
    global = {
        customBuffs = {},
    },
}

local filters = {
    "HELPFUL",
    "HARMFUL",
}

function BuffOverlay.print(msg)
    local newMsg = "|cff83b2ffBuffOverlay|r: " .. msg
    print(newMsg)
end

local function GetFirstUnusedNum()
    local nums = {}

    for name in pairs(BuffOverlay.db.profile.bars) do
        rawset(nums, #nums + 1, tonumber(string.match(name, "%d+")))
    end

    table_sort(nums)

    for i, num in ipairs(nums) do
        if i ~= num then
            return i
        end
    end

    return #nums + 1
end

function BuffOverlay:AddBar()
    local num = GetFirstUnusedNum()
    local barName = "Bar" .. num

    self.db.profile.bars[barName] = CopyTable(defaultBarSettings)
    self:AddBarToOptions(self.db.profile.bars[barName], barName)

    for _, v in pairs(self.db.profile.buffs) do
        if v.enabled[barName] == nil then
            v.enabled[barName] = true
        end
    end

    self:RefreshOverlays(true)
end

function BuffOverlay:DeleteBar(barName)
    self.db.profile.bars[barName] = nil
    self.options.args.bars.args[barName] = nil

    for _, v in pairs(self.db.profile.buffs) do
        if v.enabled then
            v.enabled[barName] = nil
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
    if tex and not TestBuffIds[spellId] then
        rawset(TestBuffs, #TestBuffs + 1, { spellId, tex })
        rawset(TestBuffIds, spellId, true)
    end
end

local function UnitAuraTest(_, index, filter)
    local buff = TestBuffs[index]
    if not buff then return end
    return "TestBuff", buff[2], 0, nil, 60, GetTime() + 60, nil, nil, nil, buff[1]
end

function BuffOverlay:InsertBuff(spellId)
    if not C_Spell.DoesSpellExist(spellId) then
        return false
    end

    local custom = self.db.global.customBuffs
    if not custom[spellId] and not self.db.profile.buffs[spellId] then
        custom[spellId] = { class = "MISC", prio = 100, custom = true }
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
        if BuffOverlay.db.profile.buffs[child].custom and not self.custom then
            BuffOverlay.db.profile.buffs[child].custom = nil
        end
        for k, v in pairs(self) do
            if k ~= "children" and k ~= "UpdateChildren" then
                BuffOverlay.db.profile.buffs[child][k] = v
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

        if not self.db.profile.buffs[spellId] then
            self.db.profile.buffs[spellId] = {
                enabled = {},
            }
        end

        local buff = self.db.profile.buffs[spellId]

        if type(buff.enabled) ~= "table" then
            buff.enabled = {}
        end

        for barName in pairs(self.db.profile.bars) do
            if buff.enabled[barName] == nil then
                buff.enabled[barName] = true
            end
        end

        for field, value in pairs(v) do
            buff[field] = value
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
        if v.custom then
            if v.parent and not BuffOverlay.db.global.customBuffs[v.parent] then
                v.custom = nil
            elseif not BuffOverlay.db.global.customBuffs[k] then
                v.custom = nil
            end
        end

        -- Check for orphaned bar data
        for barName in pairs(v.enabled) do
            if not BuffOverlay.db.profile.bars[barName] then
                v.enabled[barName] = nil
            end
        end

        -- Check for old buffs from a previous DB
        if (not BuffOverlay.defaultSpells[k]) and (not BuffOverlay.db.global.customBuffs[k]) then
            BuffOverlay.db.profile.buffs[k] = nil
        elseif v.parent then -- child found
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
                    BuffOverlay.db.profile.buffs[k][key] = val
                end
            end
        else
            InsertTestBuff(k)
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
                enabled = {},
            }
            for key, val in pairs(v) do
                self.db.profile.buffs[k][key] = val
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
            if not self.db.profile.buffs[k] then
                self.db.profile.buffs[k] = {
                    enabled = {},
                }

                for barName in pairs(self.db.profile.bars) do
                    self.db.profile.buffs[k].enabled[barName] = true
                end

                for key, val in pairs(v) do
                    self.db.profile.buffs[k][key] = val
                end
            else
                if type(self.db.profile.buffs[k].enabled) ~= "table" then
                    self.db.profile.buffs[k].enabled = {}
                end

                for key, val in pairs(v) do
                    self.db.profile.buffs[k][key] = val
                end

                for barName in pairs(self.db.profile.bars) do
                    if self.db.profile.buffs[k].enabled[barName] == nil then
                        self.db.profile.buffs[k].enabled[barName] = true
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
    for _, bar in pairs(BuffOverlay.db.profile.bars) do
        for attr, val in pairs(defaultBarSettings) do
            if bar[attr] == nil then
                if type(val) == "table" then
                    bar[attr] = CopyTable(val)
                else
                    bar[attr] = val
                end
            end
        end

        for attribute in pairs(bar) do
            if defaultBarSettings[attribute] == nil then
                bar[attribute] = nil
            end
        end
    end
end

function BuffOverlay:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BuffOverlayDB", defaultSettings, true)

    if not self.registered then
        self.db.RegisterCallback(self, "OnProfileChanged", "FullRefresh")
        self.db.RegisterCallback(self, "OnProfileCopied", "FullRefresh")
        self.db.RegisterCallback(self, "OnProfileReset", "FullRefresh")

        self:Options()
        self.registered = true
    end

    if self.db.profile.welcomeMessage then
        self.print("Type |cff9b6ef3/buffoverlay|r or |cff9b6ef3/bo|r to open the options panel or |cff9b6ef3/bo help|r for more commands.")
    end

    self.overlays = {}
    self.priority = {}
    self.units = {}
    self.unitFrames = {}
    self.blizzFrames = {}

    -- Clean up old DB entries
    for _, content in pairs(self.db.profiles) do
        for attr in pairs(defaultBarSettings) do
            if content[attr] ~= nil then
                self.print("There has been a major update and unfortunately your profiles need to be reset. Upside though, you can now add BuffOverlay aura bars in multiple locations on your frames! Check it out by typing |cff9b6ef3/bo|r in chat.")
                wipe(self.db.profile)
                self.db:ResetProfile()
                break
            end
        end
    end

    InitUnits()

    if next(self.db.profile.bars) == nil then
        self:AddBar()
    end

    ValidateBarAttributes()

    -- EventHandler for third-party addons
    -- Note: More events get added in InitFrames()
    self.eventHandler = CreateFrame("Frame")
    self.eventHandler:RegisterEvent("PLAYER_LOGIN")
    self.eventHandler:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            self:InitFrames()
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:UpdateUnits()
        elseif event == "PLAYER_ENTERING_WORLD" then
            self:UpdateUnits()
        elseif event == "UNIT_EXITED_VEHICLE" or event == "UNIT_ENTERED_VEHICLE" then
            -- Wait for the next frame for the vehicle to be fully loaded/unloaded
            C_Timer.After(0, function()
                self:UpdateUnits()
            end)
        end
    end)

    self:UpdateBuffs()

    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    function SlashCmdList.BuffOverlay(msg)
        if msg == "help" or msg == "?" then
            self.print("Command List")
            print("|cff9b6ef3/buffoverlay|r or |cff9b6ef3/bo|r: Opens options panel.")
            print("|cff9b6ef3/bo|r |cffffe981test|r: Shows test icons on all visible raid/party frames.")
            print("|cff9b6ef3/bo|r |cffffe981reset|r: Resets current profile to default settings. This does not remove any custom buffs.")
        elseif msg == "test" then
            self:Test()
        elseif msg == "reset" or msg == "default" then
            self.db:ResetProfile()
        else
            LibStub("AceConfigDialog-3.0"):Open("BuffOverlay")
        end
    end
end

function BuffOverlay:RefreshOverlays(full, barName)
    -- fix for resetting profile with buffs active
    if next(self.db.profile.buffs) == nil then
        self:CreateBuffTable()
    end

    if full then
        for k in pairs(self.overlays) do
            if barName then
                if k:match("BuffOverlay" .. barName) then
                    self.overlays[k]:Hide()
                    self.overlays[k].needsUpdate = true
                end
            else
                self.overlays[k]:Hide()
                self.overlays[k].needsUpdate = true
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

function BuffOverlay:Test(barName)
    if InCombatLockdown() then
        if self.test then
            self.test = false
            if testTextFrame then
                testTextFrame:Hide()
            end
            self:UpdateUnits()
            self.print("Exiting test mode.")
            return
        else
            self.print("You are in combat.")
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
            testTextFrame.text:SetText("BuffOverlay Test")
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
                end
            end
        end

        self.print("Test mode activated.")
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
                    self.print("|cff9b6ef3(Note)|r Frames need to be visible in order to see test icons. If you are using a non-Blizzard frame addon, you will need to make the frames visible either by joining a group or through that addon's settings.")
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

        if GetNumGroupMembers() == 0 or
            not IsInRaid() and not select(2, IsInInstance()) == "arena" and GetCVarBool("useCompactPartyFrames") then
            if CompactRaidFrameManager then
                CompactRaidFrameManager:Hide()
                CompactRaidFrameContainer:Hide()
                if CompactPartyFrame then
                    CompactPartyFrame:Hide()
                end
            end
        end
        self.print("Exiting test mode.")
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

local function SetOverlayAura(overlay, index, icon, count, duration, expirationTime, dispelType, filter)
    local bar = overlay.bar

    overlay.icon:SetTexture(icon)

    if (count > 1) then
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

    local enabled = expirationTime and expirationTime ~= 0
    if enabled then
        local startTime = expirationTime - duration
        CooldownFrame_Set(overlay.cooldown, startTime, duration, true)
    else
        CooldownFrame_Clear(overlay.cooldown)
    end

    if overlay.border and bar.iconBorder then
        if bar.debuffIconBorderColorByDispelType then
            if filter == "HARMFUL" then
                local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
                overlay.border:SetVertexColor(color.r, color.g, color.b, bar.iconBorderColor.a)
            else
                overlay.border:SetVertexColor(bar.iconBorderColor.r, bar.iconBorderColor.g, bar.iconBorderColor.b, bar.iconBorderColor.a)
            end
        else
            overlay.border:SetVertexColor(bar.iconBorderColor.r, bar.iconBorderColor.g, bar.iconBorderColor.b, bar.iconBorderColor.a)
        end
    end

    overlay:Show()
end

local borderPieces = {
    "Top",
    "Bottom",
    "Left",
    "Right",
}

local function DisablePixelSnap(border)
    for _, pieceName in pairs(borderPieces) do
        local piece = border[pieceName]
        if piece then
            piece:SetSnapToPixelGrid(false)
            piece:SetTexelSnappingBias(0)
        end
    end
end

local function UpdateBorder(overlay)
    local bar = overlay.bar

    -- zoomed in/out
    if bar.iconBorder then
        overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        overlay.icon:SetTexCoord(0, 1, 0, 1)
    end

    if not overlay.border then
        overlay.border = CreateFrame("Frame", nil, overlay, "BuffOverlayBorderTemplate")
        overlay.border:SetFrameLevel(overlay:GetFrameLevel() + 5)

        DisablePixelSnap(overlay.border)
    end

    local border = overlay.border
    local size = bar.iconBorderSize - 1
    local borderColor = bar.iconBorderColor

    local pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
    local pixelSize = (pixelFactor / 2) + (pixelFactor * size)

    border:SetBorderSizes(pixelSize, pixelSize, pixelSize, pixelSize)
    border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    border:UpdateSizes()

    border:SetShown(bar.iconBorder)
end

function BuffOverlay:SetupContainer(frame)
    frame.BuffOverlays = frame.BuffOverlays or CreateFrame("Frame", frame:GetName() .. "BuffOverlayContainer", frame)
    frame.BuffOverlays:SetAllPoints()
end

local function sortAuras(a, b)
    return a[2] < b[2]
end

-- TODO: Look into how this function works with multiple bars. Currently a lot of wasted cycles. Needs entire rework, probably.
--  Might be good to save rework until dragonflight since UNIT_AURA seems to be getting efficiency changes with payload updates.
function BuffOverlay:ApplyOverlay(frame, unit, barNameToApply)
    if not frame or not unit or frame:IsForbidden() or not frame:IsShown() then return end
    if string_find(unit, "target") or unit == "focus" then return end

    if not frame.BuffOverlays then
        self:SetupContainer(frame)
    end

    local frameName = frame:GetName()
    local frameWidth, frameHeight = frame:GetSize()
    local overlaySize = round(math_min(frameHeight, frameWidth) * 0.33, 1)
    local UnitAura = self.test and UnitAuraTest or UnitAura

    local bars = next(testBarNames) ~= nil and testBarNames or self.db.profile.bars

    for barName, bar in pairs(bars) do
        if not (barNameToApply and barName ~= barNameToApply) then
            local overlayName = frameName .. "BuffOverlay" .. barName .. "Icon"
            local relativeSpacing = overlaySize * (bar.iconSpacing / self.options.args.bars.args[barName].args.settings.args.iconSpacing.softMax)

            for i = 1, bar.iconCount do
                local overlay = self.overlays[overlayName .. i]

                if not overlay or
                    overlay.needsUpdate or
                    overlay.size ~= overlaySize then

                    if not overlay then
                        overlay = CreateFrame("Button", overlayName .. i, frame.BuffOverlays, "CompactAuraTemplate")
                    end

                    overlay.bar = bar
                    overlay.barName = barName
                    overlay.spacing = relativeSpacing
                    overlay.size = overlaySize

                    if overlay.size <= 0 then
                        overlay.needsUpdate = true
                        return
                    else
                        overlay.needsUpdate = false
                    end

                    overlay.cooldown:SetDrawSwipe(bar.showCooldownSpiral)
                    overlay.cooldown:SetHideCountdownNumbers(not bar.showCooldownNumbers)
                    overlay.cooldown:SetScale(bar.cooldownNumberScale * overlay.size / 36)

                    overlay.count:SetScale(0.8)
                    overlay.count:ClearPointsOffset()

                    overlay:SetScale(bar.iconScale)
                    overlay:SetAlpha(bar.iconAlpha)
                    overlay:SetSize(overlaySize, overlaySize)
                    overlay:EnableMouse(false)
                    overlay:RegisterForClicks()
                    overlay:SetFrameLevel(999)

                    overlay:ClearAllPoints()

                    if i == 1 then
                        PixelUtil.SetPoint(overlay, bar.iconAnchor, frame, bar.iconRelativePoint, bar.iconXOff, bar.iconYOff)
                    else
                        local prevOverlay = self.overlays[overlayName .. (i - 1)]

                        if bar.growDirection == "DOWN" then
                            PixelUtil.SetPoint(overlay, "TOP", prevOverlay, "BOTTOM", 0, -relativeSpacing)
                        elseif bar.growDirection == "LEFT" then
                            PixelUtil.SetPoint(overlay, "BOTTOMRIGHT", prevOverlay, "BOTTOMLEFT", -relativeSpacing, 0)
                        elseif bar.growDirection == "UP" or bar.growDirection == "VERTICAL" then
                            PixelUtil.SetPoint(overlay, "BOTTOM", prevOverlay, "TOP", 0, relativeSpacing)
                        else
                            PixelUtil.SetPoint(overlay, "BOTTOMLEFT", prevOverlay, "BOTTOMRIGHT", relativeSpacing, 0)
                        end
                    end

                    UpdateBorder(overlay)

                    self.overlays[overlayName .. i] = overlay
                end
                overlay:Hide()
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
            local spellName, icon, count, dispelType, duration, expirationTime, _, _, _, spellId = UnitAura(unit, i, filter)
            if spellId then
                local aura = self.db.profile.buffs[spellId] or self.db.profile.buffs[spellName]

                if aura then
                    for barName in pairs(bars) do
                        if not (barNameToApply and barName ~= barNameToApply) and (aura.enabled[barName] or self.test) then
                            rawset(self.priority[barName], #self.priority[barName] + 1, { i, aura.prio, icon, count, duration, expirationTime, dispelType, filter })
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
        if not (barNameToApply and barName ~= barNameToApply) then
            local overlayName = frameName .. "BuffOverlay" .. barName .. "Icon"
            local overlayNum = 1

            if #self.priority[barName] > 1 then
                table_sort(self.priority[barName], sortAuras)
            end

            while overlayNum <= bar.iconCount do
                local data = self.priority[barName][overlayNum]
                if data then
                    SetOverlayAura(self.overlays[overlayName .. overlayNum], data[1], data[3], data[4], data[5], data[6], data[7], data[8])
                    overlayNum = overlayNum + 1
                else
                    break
                end
            end

            overlayNum = overlayNum - 1

            if overlayNum > 0 and (bar.growDirection == "HORIZONTAL" or bar.growDirection == "VERTICAL") then
                local overlay1 = self.overlays[overlayName .. 1]
                local width, height = overlay1:GetSize()
                local point, relativeTo, relativePoint, xOfs, yOfs = overlay1:GetPoint()

                local x = bar.growDirection == "HORIZONTAL" and (-(width / 2) * (overlayNum - 1) + bar.iconXOff - (((overlayNum - 1) / 2) * overlay1.spacing)) or xOfs
                local y = bar.growDirection == "VERTICAL" and (-(height / 2) * (overlayNum - 1) + bar.iconYOff - (((overlayNum - 1) / 2) * overlay1.spacing)) or yOfs

                PixelUtil.SetPoint(overlay1, point, relativeTo, relativePoint, x, y)
            end
        end
    end
end

-- For Blizzard Frames
hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
    if not frame.buffFrames then return end

    if BuffOverlay.frames and not BuffOverlay.frames[frame] then
        BuffOverlay.frames[frame] = {
            unit = "displayedUnit",
            blizz = true,
        }
    end

    if BuffOverlay.blizzFrames and not BuffOverlay.blizzFrames[frame] then
        BuffOverlay.blizzFrames[frame] = true
    end

    BuffOverlay:ApplyOverlay(frame, frame.displayedUnit)
end)
