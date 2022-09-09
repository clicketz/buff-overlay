local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")
local LGF = LibStub("LibGetFrame-1.0")

local C_Spell = C_Spell
local GetSpellInfo = GetSpellInfo
local IsAddOnLoaded = IsAddOnLoaded
local next = next
local TestBuffs = {}
local TestBuffIds = {}
local test

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
        cooldownNumberScale = 0.5,
        iconXOff = 0,
        iconYOff = 0,
        iconBorder = true,
        iconBorderColor = {
            r = 0,
            g = 0,
            b = 0,
            a = 1,
        },
        iconBorderSize = 0.75,
        welcomeMessage = true,
        buffs = {},
    },
    global = {
        customBuffs = {},
    },
}

local defaultFrames = {
    "^Vd1",
    "^HealBot",
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
}

local function InsertTestBuff(spellId)
    local tex = GetSpellTexture(spellId)
    if tex and not TestBuffIds[spellId] then
        rawset(TestBuffs, #TestBuffs + 1, { spellId, tex })
        rawset(TestBuffIds, spellId, true)
    end
end

local function UnitBuffTest(_, index)
    local buff = TestBuffs[index]
    if not buff then return end
    return "TestBuff", buff[2], 0, nil, 60, GetTime() + 60, nil, nil, nil, buff[1]
end

function BuffOverlay:InsertBuff(spellId)
    if not C_Spell.DoesSpellExist(spellId) then return end

    local custom = self.db.global.customBuffs
    if not custom[spellId] and not self.db.profile.buffs[spellId] then
        custom[spellId] = { class = "MISC", prio = 100, custom = true }
        return true
    end
    return false
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

        InsertTestBuff(spellId)
    end
    self.options.args.spells.args = BuffOverlay_GetClasses()
end

local function ValidateBuffData()
    for k, v in pairs(BuffOverlay.db.profile.buffs) do
        -- Check for old buffs from a previous DB
        if (not BuffOverlay.defaultSpells[k]) and (not BuffOverlay.db.global.customBuffs[k]) then
            BuffOverlay.db.profile.buffs[k] = nil
        elseif v.parent then -- child found
            local parent = BuffOverlay.db.profile.buffs[v.parent]

            if not parent.children then
                parent.children = {}
            end

            parent.children[k] = true

            -- Give child the same fields as parent
            for key, val in pairs(parent) do
                if key ~= "children" then
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

function BuffOverlay:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BuffOverlayDB", defaultSettings, true)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("BuffOverlay", 590, 520)

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
            self:RefreshOverlays(false)
        end
    end)

    LGF.RegisterCallback("BuffOverlay", "FRAME_UNIT_UPDATE", function(event, frame, unit)
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
        self:RefreshOverlays(false)
    end)

    LGF.RegisterCallback("BuffOverlay", "FRAME_UNIT_REMOVED", function(event, frame, unit)
        self:RefreshOverlays(false)
    end)

    self:UpdateBuffs()

    -- Remove invalid custom cooldowns
    for k in pairs(self.db.global.customBuffs) do
        if (not GetSpellInfo(k)) or self.defaultSpells[k] then
            self.db.global.customBuffs[k] = nil
        end
    end

    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    SlashCmdList.BuffOverlay = function(msg)
        if msg == "help" or msg == "?" then
            self.print("Command List")
            print("|cff9b6ef3/buffoverlay|r or |cff9b6ef3/bo|r: Opens options panel.")
            print("|cff9b6ef3/bo|r |cffffe981test|r: Shows test icons on all visible raid/party frames.")
            print("|cff9b6ef3/bo|r |cffffe981reset|r: Resets current profile to default values.")
        elseif msg == "test" then
            self:Test()
        elseif msg == "reset" or msg == "default" then
            self.db:ResetProfile()
        else
            LibStub("AceConfigDialog-3.0"):Open("BuffOverlay")
        end
    end

    self:Refresh()
end

function BuffOverlay:RefreshOverlays(full)
    -- fix for resetting profile with buffs active
    if next(self.db.profile.buffs) == nil then
        self:CreateBuffTable()
    end

    if full then
        for k in pairs(self.overlays) do
            self.overlays[k]:Hide()
            self.overlays[k] = nil
        end
    end

    for frame, info in pairs(self.frames) do
        if (frame:IsShown() and frame:IsVisible()) then self:ApplyOverlay(frame, info.unit) end
    end
end

function BuffOverlay:Refresh()
    self:RefreshOverlays(true)
    self.options.args.spells.args = BuffOverlay_GetClasses()
end

function BuffOverlay:FullRefresh()
    self:UpdateBuffs()
    self:Refresh()
end

function BuffOverlay.print(msg)
    local newMsg = "|cff83b2ffBuffOverlay|r: " .. msg
    print(newMsg)
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
        test:Hide()
    end

    if not self.test then
        if GetNumGroupMembers() == 0 or
            not IsInRaid() and not select(2, IsInInstance()) == "arena" and GetCVarBool("useCompactPartyFrames") then
            if CompactRaidFrameManager then
                CompactRaidFrameManager:Hide()
                CompactRaidFrameContainer:Hide()
            end
        end
        self.print("Exiting test mode.")
        test:Hide()
        self:RefreshOverlays(false)
        return
    end

    if GetNumGroupMembers() == 0 then
        if CompactRaidFrameManager then
            CompactRaidFrameManager:Show()
            CompactRaidFrameContainer:Show()
        end
    end

    local anchor = false
    if CompactRaidFrameManager then
        local pFrames = { _G["CompactRaidFrame1"], _G["CompactPartyFrameMember1"] }
        for _, compactFrame in pairs(pFrames) do
            if not self.frames[compactFrame] then
                self.frames[compactFrame] = self.frames[compactFrame] or {}
                self.frames[compactFrame].unit = compactFrame.displayedUnit
            end

            if compactFrame:IsShown() and compactFrame:IsVisible() then
                anchor = compactFrame
                break
            end
        end
    end

    if not anchor then
        for frame in pairs(self.frames) do
            if frame.unit and (UnitGUID("player") == UnitGUID(frame.unit)) and frame:IsShown() and frame:IsVisible() then
                anchor = frame
                break
            end
        end
    end

    self.print("Test mode activated.")

    test:ClearAllPoints()
    if anchor then
        test:SetPoint("BOTTOM", anchor, "TOP", 0, 0)
    else
        self.print("|cff9b6ef3(Note)|r Frames need to be visible in order to see test icons. If you are using a non-Blizzard frame addon, you will need to make the frames visible either by joining a group or through that addon's settings.")
        test:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    test:Show()

    self:RefreshOverlays(false)
end

local function CompactUnitFrame_UtilSetBuff(buffFrame, unit, index, filter)

    local UnitBuff = BuffOverlay.test and UnitBuffTest or UnitBuff

    local _, icon, count, _, duration, expirationTime = UnitBuff(unit, index, filter)
    buffFrame.icon:SetTexture(icon)
    if (count > 1) then
        local countText = count
        if (count >= 100) then
            countText = BUFF_STACKS_OVERFLOW
        end
        buffFrame.count:Show()
        buffFrame.count:SetText(countText)
    else
        buffFrame.count:Hide()
    end
    buffFrame:SetID(index)
    local enabled = expirationTime and expirationTime ~= 0
    if enabled then
        local startTime = expirationTime - duration
        CooldownFrame_Set(buffFrame.cooldown, startTime, duration, true)
    else
        CooldownFrame_Clear(buffFrame.cooldown)
    end
    buffFrame:Show()
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
    local size = BuffOverlay.db.profile.iconBorderSize
    local borderColor = BuffOverlay.db.profile.iconBorderColor

    border:SetBorderSizes(size, 1, size, 1)
    border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    border:UpdateSizes()

    border:SetShown(BuffOverlay.db.profile.iconBorder)
end

function BuffOverlay:ApplyOverlay(frame, unit)
    if frame:IsForbidden() then return end

    local bFrame = frame:GetName() .. "BuffOverlay"
    local frameWidth, frameHeight = frame:GetSize()
    local overlayNum = 1

    local UnitBuff = self.test and UnitBuffTest or UnitBuff

    for i = 1, self.db.profile.iconCount do
        local overlay = self.overlays[bFrame .. i]
        if not overlay then
            overlay = _G[bFrame .. i] or CreateFrame("Button", bFrame .. i, frame, "CompactAuraTemplate")
            overlay.cooldown:SetDrawSwipe(self.db.profile.showCooldownSpiral)
            overlay.cooldown:SetHideCountdownNumbers(not self.db.profile.showCooldownNumbers)
            overlay.cooldown:SetScale(self.db.profile.cooldownNumberScale)
            overlay.count:SetPoint("BOTTOMRIGHT", bFrame .. i, "BOTTOMRIGHT")
            overlay.count:SetScale(0.8)
            UpdateBorder(overlay)
            overlay:ClearAllPoints()
            if i == 1 then
                overlay:SetPoint(self.db.profile.iconAnchor, frame, self.db.profile.iconRelativePoint,
                    self.db.profile.iconXOff, self.db.profile.iconYOff)
            else
                if self.db.profile.growDirection == "DOWN" then
                    overlay:SetPoint("TOP", _G[bFrame .. i - 1], "BOTTOM", 0, -self.db.profile.iconSpacing)
                elseif self.db.profile.growDirection == "LEFT" then
                    overlay:SetPoint("BOTTOMRIGHT", _G[bFrame .. i - 1], "BOTTOMLEFT", -self.db.profile.iconSpacing, 0)
                elseif self.db.profile.growDirection == "UP" or self.db.profile.growDirection == "VERTICAL" then
                    overlay:SetPoint("BOTTOM", _G[bFrame .. i - 1], "TOP", 0, self.db.profile.iconSpacing)
                else
                    overlay:SetPoint("BOTTOMLEFT", _G[bFrame .. i - 1], "BOTTOMRIGHT", self.db.profile.iconSpacing, 0)
                end
            end
            overlay:SetScale(self.db.profile.iconScale)
            overlay:SetAlpha(self.db.profile.iconAlpha)
            overlay:EnableMouse(false)
            overlay:RegisterForClicks()
            overlay:SetFrameLevel(999)
            self.overlays[bFrame .. i] = overlay
        end
        overlay:Hide()
    end

    if #self.priority > 0 then
        for i = 1, #self.priority do
            self.priority[i] = nil
        end
    end

    -- This will stop long before iterating 999 times, but the number needs to be large to cover test buff table sizes.
    for i = 1, 999 do
        local buffName, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
        if spellId then
            if self.db.profile.buffs[buffName] and not self.db.profile.buffs[spellId] then
                self.db.profile.buffs[spellId] = self.db.profile.buffs[buffName]
            end

            if self.db.profile.buffs[spellId] and self.db.profile.buffs[spellId].enabled then
                rawset(self.priority, #self.priority + 1, { i, self.db.profile.buffs[spellId].prio })
            end
        else
            break
        end
    end

    if #self.priority > 1 then
        table.sort(self.priority, function(a, b)
            return a[2] < b[2]
        end)
    end

    while overlayNum <= self.db.profile.iconCount do
        if self.priority[overlayNum] then
            CompactUnitFrame_UtilSetBuff(self.overlays[bFrame .. overlayNum], unit, self.priority[overlayNum][1], nil)

            local buffSize = math.min(frameHeight, frameWidth) * 0.33
            self.overlays[bFrame .. overlayNum]:SetSize(buffSize, buffSize)

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
        local x = self.db.profile.growDirection == "HORIZONTAL" and (-(width / 2) * (overlayNum - 1) + self.db.profile.iconXOff -
        (((overlayNum - 1) / 2) * self.db.profile.iconSpacing)) or xOfs
        local y = self.db.profile.growDirection == "VERTICAL" and (-(height / 2) * (overlayNum - 1) + self.db.profile.iconYOff -
        (((overlayNum - 1) / 2) * self.db.profile.iconSpacing)) or yOfs

        overlay1:SetPoint(point, relativeTo, relativePoint, x, y)
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
