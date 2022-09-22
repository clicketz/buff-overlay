local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local LGF = LibStub("LibGetFrame-1.0")

local C_Spell = C_Spell
local C_Timer = C_Timer
local PixelUtil = PixelUtil
local GetSpellTexture = GetSpellTexture
local IsAddOnLoaded = IsAddOnLoaded
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
local rawset = rawset
local print = print
local CreateFrame = CreateFrame
local TestBuffs = {}
local TestBuffIds = {}
local test
local callback = CreateFrame("Frame")

local defaultSettings = {
    profile = {
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
        iconBorderSize = 1,
        welcomeMessage = true,
        buffs = {},
    },
    global = {
        customBuffs = {},
    },
}

local defaultFrames = {
    "^Vd",
    "^GridLayout",
    "^Grid2Layout",
    "^PlexusLayout",
    "^InvenRaidFrames3Group%dUnitButton",
    "^ElvUF_Raid%d*Group",
    "^oUF_.-Raid",
    "^AshToAsh",
    "^Cell",
    "^LimeGroup",
    "^SUFHeaderraid",
    "^LUFHeaderraid",
    -- "^CompactRaid",
    "^InvenUnitFrames_Party%d",
    "^AleaUI_GroupHeader",
    "^SUFHeaderparty",
    "^LUFHeaderparty",
    "^ElvUF_PartyGroup",
    "^oUF_.-Party",
    "^PitBull4_Groups_Party",
    -- "^CompactParty",
    "^ElvUF_TankUnitButton%d$",
    "^ElvUF_AssistUnitButton%d$",
}

local filters = {
    "HELPFUL",
    "HARMFUL",
}

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function InsertTestBuff(spellId)
    local tex = GetSpellTexture(spellId)
    if tex and not TestBuffIds[spellId] then
        rawset(TestBuffs, #TestBuffs + 1, { spellId, tex })
        rawset(TestBuffIds, spellId, true)
    end
end

local function UnitBuffTest(_, index, filter)
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

local function UpdateChildren(self)
    for child in pairs(self.children) do
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
            self.db.profile.buffs[spellId] = {}
            self.db.profile.buffs[spellId].enabled = true
        end

        local buff = self.db.profile.buffs[spellId]

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
        if v.custom and not BuffOverlay.db.global.customBuffs[k] then
            v.custom = nil
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
            self.db.profile.buffs[k] = {}
            for key, val in pairs(v) do
                self.db.profile.buffs[k][key] = val
            end
            self.db.profile.buffs[k].enabled = true
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
                self.db.profile.buffs[k] = {}
                for key, val in pairs(v) do
                    self.db.profile.buffs[k][key] = val
                end
                self.db.profile.buffs[k].enabled = true
            else
                local e = self.db.profile.buffs[k].enabled
                for key, val in pairs(v) do
                    self.db.profile.buffs[k][key] = val
                end
                self.db.profile.buffs[k].enabled = e
            end
        end
        ValidateBuffData()
    end
end

local function HideAllOverlays(frame)
    local bFrame = frame:GetName() .. "BuffOverlay"
    for i = 1, BuffOverlay.db.profile.iconCount do
        local overlay = BuffOverlay.overlays[bFrame .. i]
        if overlay then
            overlay:Hide()
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

    self.frames = {}
    self.overlays = {}
    self.priority = {}

    -- EventHandler
    local eventHandler = CreateFrame("Frame")
    -- TODO: Waiting for this event is kind of hacky, I'd rather a more official way to init LGF
    eventHandler:RegisterEvent("INITIAL_CLUBS_LOADED") -- this event is fired a few seconds after addons are loaded
    eventHandler:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventHandler:SetScript("OnEvent", function(_, event)
        if event == "INITIAL_CLUBS_LOADED" then
            -- Init LGF. Will not init automatically, and will also break if init too early
            LGF.GetUnitFrame("player")
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:RefreshOverlays()
        end
    end)

    LGF.RegisterCallback(self, "FRAME_UNIT_UPDATE", function(event, frame, unit)
        -- TODO: Use a more performant lookup. The issue is that LGF returns all frames on FRAME_UNIT_UPDATE
        --  including frames that we don't care about (such as nameplates).
        local found = false
        local frameName = frame:GetName()
        for _, v in pairs(defaultFrames) do
            if string.find(frameName, v) then
                found = true
                break
            end
        end
        if not found then return end

        if not self.frames[frame] then self.frames[frame] = {} end
        self.frames[frame].unit = unit

        -- specific fix for SUF
        if IsAddOnLoaded("ShadowedUnitFrames") then
            -- SUF overwrites RegisterUnitEvent
            frame:RegisterUnitEvent("UNIT_AURA", frame, "FullUpdate")
        else
            frame:RegisterUnitEvent("UNIT_AURA", unit)
        end

        if not self.frames[frame].hooked then
            frame:HookScript("OnEvent", function(s, ev)
                if ev == "UNIT_AURA" then
                    if not self.frames[s] then return end
                    self:ApplyOverlay(s, self.frames[s].unit)
                end
            end)
            self.frames[frame].hooked = true
        end
        self:RefreshOverlays()
    end)

    LGF.RegisterCallback(self, "FRAME_UNIT_REMOVED", function(event, frame, unit)
        if not self.frames[frame] then return end
        self:RefreshOverlays()
    end)

    self:UpdateBuffs()

    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    SlashCmdList.BuffOverlay = function(msg)
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

function BuffOverlay:RefreshOverlays(full)
    -- fix for resetting profile with buffs active
    if next(self.db.profile.buffs) == nil then
        self:CreateBuffTable()
    end

    if full then
        for k in pairs(self.overlays) do
            self.overlays[k]:Hide()
            self.overlays[k].needsUpdate = true
        end
    end

    for frame, info in pairs(self.frames) do
        if frame:IsShown() and frame:IsVisible() then
            if string.find(info.unit, "target") or info.unit == "focus" then
                HideAllOverlays(frame)
            else
                self:ApplyOverlay(frame, info.unit)
            end
        end
    end
end

function BuffOverlay:FullRefresh()
    self:UpdateBuffs()
    self:RefreshOverlays(true)
    self:UpdateSpellOptionsTable()
end

function BuffOverlay.print(msg)
    local newMsg = "|cff83b2ffBuffOverlay|r: " .. msg
    print(newMsg)
end

local function GetTestAnchor()
    local anchor = false
    for frame, info in pairs(BuffOverlay.frames) do
        if UnitIsPlayer(info.unit) and frame:IsShown() and frame:IsVisible() then
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
    return anchor
end

function BuffOverlay:Test()
    if InCombatLockdown() then
        self.print("You are in combat.")
        return
    end

    self.test = not self.test

    if not test then
        test = CreateFrame("Frame", "BuffOverlayTest", UIParent)
        test.bg = test:CreateTexture()
        test.bg:SetAllPoints(true)
        test.bg:SetColorTexture(1, 0, 0, 0.6)
        test.text = test:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        test.text:SetPoint("CENTER", 0, 0)
        test.text:SetText("BuffOverlay Test")
        test:SetSize(test.text:GetWidth() + 20, test.text:GetHeight() + 2)
        test:EnableMouse(false)
    end

    test:Hide()

    if not self.test then
        if GetNumGroupMembers() == 0 or
            not IsInRaid() and not select(2, IsInInstance()) == "arena" and GetCVarBool("useCompactPartyFrames") then
            if CompactRaidFrameManager then
                CompactRaidFrameManager:Hide()
                CompactRaidFrameContainer:Hide()
            end
        end
        self.print("Exiting test mode.")
        self:RefreshOverlays()
        return
    end

    if GetNumGroupMembers() == 0 then
        if CompactRaidFrameManager then
            CompactRaidFrameManager:Show()
            CompactRaidFrameContainer:Show()
        end
    end

    self.print("Test mode activated.")
    test:ClearAllPoints()

    local anchor = false
    if CompactRaidFrameManager then
        local container = _G["CompactRaidFrameContainer"]
        if container and container:IsShown() and container:IsVisible() then
            anchor = container
        end
    end

    if not anchor then
        anchor = GetTestAnchor()
    end

    if not anchor then
        LGF.ScanForUnitFrames()
        LGF.RegisterCallback(callback, "GETFRAME_REFRESH", function()
            -- NOTE: Timer might be unnecessary here, but it's a failsafe
            C_Timer.After(0.1, function()
                local anc = GetTestAnchor()

                if not anc then
                    self.print("|cff9b6ef3(Note)|r Frames need to be visible in order to see test icons. If you are using a non-Blizzard frame addon, you will need to make the frames visible either by joining a group or through that addon's settings.")
                    test:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                else
                    test:SetPoint("BOTTOMLEFT", anc, "TOPLEFT", 0, 2)
                end

                test:Show()
            end)

            LGF.UnregisterCallback(callback, "GETFRAME_REFRESH")
        end)
    else
        test:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
        test:Show()
    end

    self:RefreshOverlays()
end

local function SetOverlayAura(overlay, index, icon, count, duration, expirationTime)
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

    overlay:Show()
end

local function UpdateBorder(frame)
    -- zoomed in/out
    if BuffOverlay.db.profile.iconBorder then
        frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        frame.icon:SetTexCoord(0, 1, 0, 1)
    end

    if not frame.border then
        frame.border = CreateFrame("Frame", nil, frame, "BuffOverlayBorderTemplate")
        frame.border:SetFrameLevel(frame:GetFrameLevel() + 1)
    end

    local border = frame.border
    local size = BuffOverlay.db.profile.iconBorderSize - 1
    local borderColor = BuffOverlay.db.profile.iconBorderColor

    local pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
    local pixelSize = (pixelFactor / 2) + (pixelFactor * size)

    border:SetBorderSizes(pixelSize, 1, pixelSize, 1)
    border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    border:UpdateSizes()

    border:SetShown(BuffOverlay.db.profile.iconBorder)
end

function BuffOverlay:ApplyOverlay(frame, unit)
    if frame:IsForbidden() or not (frame:IsShown() and frame:IsVisible()) then return end
    if string.find(unit, "target") or unit == "focus" then return end

    local bFrame = frame:GetName() .. "BuffOverlay"
    local frameWidth, frameHeight = frame:GetSize()
    local overlaySize = math.min(frameHeight, frameWidth) * 0.33
    local relativeSpacing = overlaySize *
        (self.db.profile.iconSpacing / self.options.args.layout.args.iconSpacing.softMax)
    local overlayNum = 1

    local UnitAura = self.test and UnitBuffTest or UnitAura

    -- TODO: Create an overlay container on each frame to make iterating over frame specific overlays easier
    for i = 1, self.db.profile.iconCount do
        local overlay = self.overlays[bFrame .. i]

        if not overlay or overlay.needsUpdate or (round(overlay.spacing, 2) ~= round(relativeSpacing, 2)) or
            (round(overlay.size, 2) ~= round(overlaySize, 2)) then
            overlay = _G[bFrame .. i] or CreateFrame("Button", bFrame .. i, frame, "CompactAuraTemplate")

            overlay.spacing = relativeSpacing
            overlay.size = overlaySize

            if overlay.size <= 0 then
                overlay.needsUpdate = true
                return
            else
                overlay.needsUpdate = false
            end

            overlay.cooldown:SetDrawSwipe(self.db.profile.showCooldownSpiral)
            overlay.cooldown:SetHideCountdownNumbers(not self.db.profile.showCooldownNumbers)
            overlay.cooldown:SetScale(self.db.profile.cooldownNumberScale * overlay.size / 36)

            overlay.count:SetScale(0.8)
            overlay.count:ClearPointsOffset()

            overlay:SetScale(self.db.profile.iconScale)
            overlay:SetAlpha(self.db.profile.iconAlpha)
            PixelUtil.SetSize(overlay, overlaySize, overlaySize)
            overlay:EnableMouse(false)
            overlay:RegisterForClicks()
            overlay:SetFrameLevel(999)

            UpdateBorder(overlay)

            overlay:ClearAllPoints()

            if i == 1 then
                PixelUtil.SetPoint(overlay, self.db.profile.iconAnchor, frame, self.db.profile.iconRelativePoint,
                    self.db.profile.iconXOff, self.db.profile.iconYOff)
            else
                if self.db.profile.growDirection == "DOWN" then
                    PixelUtil.SetPoint(overlay, "TOP", _G[bFrame .. i - 1], "BOTTOM", 0, -relativeSpacing)
                elseif self.db.profile.growDirection == "LEFT" then
                    PixelUtil.SetPoint(overlay, "BOTTOMRIGHT", _G[bFrame .. i - 1], "BOTTOMLEFT", -relativeSpacing, 0)
                elseif self.db.profile.growDirection == "UP" or self.db.profile.growDirection == "VERTICAL" then
                    PixelUtil.SetPoint(overlay, "BOTTOM", _G[bFrame .. i - 1], "TOP", 0, relativeSpacing)
                else
                    PixelUtil.SetPoint(overlay, "BOTTOMLEFT", _G[bFrame .. i - 1], "BOTTOMRIGHT", relativeSpacing, 0)
                end
            end
            self.overlays[bFrame .. i] = overlay
        end
        overlay:Hide()
    end

    if #self.priority > 0 then
        wipe(self.priority)
    end

    -- TODO: Optimize this with new UNIT_AURA event payload
    for _, filter in ipairs(filters) do
        for i = 1, 999 do
            local spellName, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, i, filter)
            if spellId then
                local aura = self.db.profile.buffs[spellName] or self.db.profile.buffs[spellId]

                if aura and aura.enabled then
                    rawset(self.priority, #self.priority + 1, { i, aura.prio, icon, count, duration, expirationTime })
                end
            else
                break
            end
        end
        if self.test then break end
    end

    if #self.priority > 1 then
        table.sort(self.priority, function(a, b)
            return a[2] < b[2]
        end)
    end

    while overlayNum <= self.db.profile.iconCount do
        local data = self.priority[overlayNum]
        if data then
            SetOverlayAura(self.overlays[bFrame .. overlayNum], data[1], data[3], data[4], data[5], data[6])
            overlayNum = overlayNum + 1
        else
            break
        end
    end

    overlayNum = overlayNum - 1

    if overlayNum > 0 and (self.db.profile.growDirection == "HORIZONTAL" or self.db.profile.growDirection == "VERTICAL") then
        local overlay1 = self.overlays[bFrame .. 1]
        local width, height = overlay1:GetSize()
        local point, relativeTo, relativePoint, xOfs, yOfs = overlay1:GetPoint()

        local x = self.db.profile.growDirection == "HORIZONTAL" and
            (-(width / 2) * (overlayNum - 1) + self.db.profile.iconXOff -
                (((overlayNum - 1) / 2) * relativeSpacing)) or xOfs
        local y = self.db.profile.growDirection == "VERTICAL" and
            (-(height / 2) * (overlayNum - 1) + self.db.profile.iconYOff -
                (((overlayNum - 1) / 2) * relativeSpacing)) or yOfs

        PixelUtil.SetPoint(overlay1, point, relativeTo, relativePoint, x, y)
    end
end

-- For Blizzard Frames
hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
    if not frame.buffFrames then return end

    if not BuffOverlay.frames[frame] then
        BuffOverlay.frames[frame] = {}
    end

    BuffOverlay.frames[frame].unit = frame.displayedUnit

    BuffOverlay:ApplyOverlay(frame, frame.displayedUnit)
end)
