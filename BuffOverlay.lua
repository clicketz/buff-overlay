local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")

local defaultSettings = {
    profile = {
        iconCount = 4,
        iconScale = 1.2,
        iconAlpha = 1.0,
        iconAnchor = "BOTTOM",
        iconRelativePoint = "CENTER",
        growDirection = "HORIZONTAL",
        showCooldownSpiral = true,
        showCooldownNumbers = false,
        cooldownNumberScale = 0.5,
        iconXOff = 0,
        iconYOff = 0,
        welcomeMessage = true,
        buffs = nil,
    },
    global = {
        customBuffs = {},
    },
}

local TestBuffs = {}
local test

local function InsertTestBuff(spellId)
    local tex = GetSpellTexture(spellId)
    if tex then
        rawset(TestBuffs, #TestBuffs + 1, { spellId, tex })
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
        custom[spellId] = { class = "MISC", prio = 100, enabled = true }
        LibStub("AceConfigRegistry-3.0"):NotifyChange("BuffOverlay")
        return true
    end
    return false
end

function BuffOverlay:UpdateCustomBuffs()
    for spellId, v in pairs(self.db.global.customBuffs) do
        self.db.profile.buffs[spellId] = v
        if not self.db.profile.buffs[spellId].custom then
            self.db.profile.buffs[spellId].custom = true
        end
    end
    self.options.args.spells.args = BuffOverlay_GetClasses()
    -- self:Refresh()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("BuffOverlay")
end

function BuffOverlay:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("BuffOverlayDB", defaultSettings, true)

    if not self.registered then
        self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
        self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
        self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

        self:Options()
        self.registered = true
    end

    if self.db.profile.welcomeMessage then
        self.print("Type /buffoverlay or /bo to open the options panel or /bo help for more commands.")
    end

    self.frames = {}
    self.overlays = {}
    self.priority = {}

    -- TODO: add this to db so it's not called every login
    for k, v in pairs(self.defaultSpells) do
        if not v.parent then
            InsertTestBuff(k)
        end
    end

    -- Remove invalid custom cooldowns
    for k, _ in pairs(self.db.global.customBuffs) do
        if (not GetSpellInfo(k)) then
            self.db.global.customBuffs[k] = nil
        end
    end

    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    SlashCmdList.BuffOverlay = function(msg)
        if msg == "help" or msg == "?" then
            self.print("Command List")
            print("|cffff0000/buffoverlay|r or |cffff0000/bo|r: Opens options panel.")
            print("|cffff0000/buffoverlay|r |cffFFFF00test|r: Shows test icons on raidframe.")
            print("|cffff0000/buffoverlay|r |cffFFFF00default|r: Resets current profile to default values.")
        elseif msg == "test" then
            self:Test()
        elseif msg == "default" then
            self.db:ResetProfile()
        else
            LibStub("AceConfigDialog-3.0"):SetDefaultSize("BuffOverlay", 600, 470)
            LibStub("AceConfigDialog-3.0"):Open("BuffOverlay")
        end
    end

    self:Refresh()
end

function BuffOverlay:ConsolidateChildren()
    for k, v in pairs(self.db.profile.buffs) do
        if v.parent then
            local parent = self.db.profile.buffs[v.parent]
            if not parent.children then
                parent.children = {}
            end
            parent.children[k] = true
        end
    end
end

function BuffOverlay:Refresh()
    for k, _ in pairs(self.overlays) do
        self.overlays[k]:Hide()
        self.overlays[k] = nil
    end

    self.index = 1

    -- If the current profile doesn't have any buffs saved use default list and save it
    if not self.db.profile.buffs then
        self.db.profile.buffs = {}
        for k, v in pairs(self.defaultSpells) do
            if v.parent then
                self.db.profile.buffs[k] = v
                table.insert(self.db.profile.buffs[k], self.defaultSpells[v.parent])
            else
                self.db.profile.buffs[k] = v
            end
            self.db.profile.buffs[k].enabled = true
        end

        self:ConsolidateChildren()
    end

    for frame, _ in pairs(self.frames) do
        if frame:IsShown() then CompactUnitFrame_UpdateAuras(frame) end
    end

    self:UpdateCustomBuffs()
end

function BuffOverlay.print(msg)
    print("|cffff0000BuffOverlay|r: " .. msg)
end

function BuffOverlay:Test()
    if InCombatLockdown() then
        self.print("You are in combat.")
        return
    end

    if not self.test and not (GetCVarBool("useCompactPartyFrames") and CompactRaidFrameManager_GetSetting("IsShown")) then
        self.print("Please enable raid-style party frames in Blizzard settings or join a 6+ player raid to see test icons.")
    end

    self.test = not self.test

    if not test then
        test = CreateFrame("Frame", "BuffOverlayTest", UIParent)
        test.bg = test:CreateTexture()
        test.bg:SetAllPoints(true)
        test.bg:SetColorTexture(1, 0, 0, 0.6)
        test.text = test:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        test.text:SetPoint("CENTER", 0, 0)
        test.text:SetText("Test")
        test:SetSize(test.text:GetWidth() + 20, test.text:GetHeight() + 2)
        test:EnableMouse(false)
        test:SetPoint("BOTTOM", _G["CompactRaidFrame1"], "TOP", 0, 0)
        test:Hide()
    end

    if not self.test then
        if GetNumGroupMembers() == 0 or
            not IsInRaid() and not select(2, IsInInstance()) == "arena" and GetCVarBool("useCompactPartyFrames") then
            CompactRaidFrameManager:Hide()
            CompactRaidFrameContainer:Hide()
        end
        test:Hide()
        self:Refresh()
        return
    end

    if GetNumGroupMembers() == 0 then
        CompactRaidFrameManager:Show()
        CompactRaidFrameContainer:Show()
    end
    test:Show()
    self:Refresh()
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

function BuffOverlay:ApplyOverlay(frame)
    if frame:IsForbidden() or not frame.buffFrames then
        return
    end

    local unit = frame.displayedUnit
    local bFrame = frame:GetName() .. "BuffOverlay"
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
            overlay:ClearAllPoints()
            if i == 1 then
                overlay:SetPoint(self.db.profile.iconAnchor, frame, self.db.profile.iconRelativePoint,
                    self.db.profile.iconXOff, self.db.profile.iconYOff)
            else
                if self.db.profile.growDirection == "DOWN" then
                    overlay:SetPoint("TOP", _G[bFrame .. i - 1], "BOTTOM")
                elseif self.db.profile.growDirection == "LEFT" then
                    overlay:SetPoint("BOTTOMRIGHT", _G[bFrame .. i - 1], "BOTTOMLEFT")
                elseif self.db.profile.growDirection == "UP" or self.db.profile.growDirection == "VERTICAL" then
                    overlay:SetPoint("BOTTOM", _G[bFrame .. i - 1], "TOP")
                else
                    overlay:SetPoint("BOTTOMLEFT", _G[bFrame .. i - 1], "BOTTOMRIGHT")
                end
            end
            overlay:SetScale(self.db.profile.iconScale)
            overlay:SetAlpha(self.db.profile.iconAlpha)
            overlay:EnableMouse(false)
            overlay:RegisterForClicks()
            self.overlays[bFrame .. i] = overlay
        end
        overlay:Hide()
    end

    if #self.priority > 0 then
        for i = 1, #self.priority do
            self.priority[i] = nil
        end
    end

    for i = 1, 40 do
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
            self.overlays[bFrame .. overlayNum]:SetSize(frame.buffFrames[1]:GetSize())

            local point, relativeTo, relativePoint, xOfs, yOfs = self.overlays[bFrame .. 1]:GetPoint()
            if self.db.profile.growDirection == "HORIZONTAL" then
                self.overlays[bFrame .. 1]:SetPoint(point, relativeTo, relativePoint,
                    -(self.overlays[bFrame .. 1]:GetWidth() / 2) * (overlayNum - 1) + self.db.profile.iconXOff, yOfs)
            elseif self.db.profile.growDirection == "VERTICAL" then
                self.overlays[bFrame .. 1]:SetPoint(point, relativeTo, relativePoint, xOfs,
                    -(self.overlays[bFrame .. 1]:GetHeight() / 2) * (overlayNum - 1) + self.db.profile.iconYOff)
            end
            overlayNum = overlayNum + 1
        else
            break
        end
    end

    if not self.frames[frame] then
        self.frames[frame] = true
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
    BuffOverlay:ApplyOverlay(frame)
end)
