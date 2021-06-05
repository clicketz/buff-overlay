--Buff Overlay by clicket

BuffOverlay = LibStub("AceAddon-3.0"):NewAddon("BuffOverlay", "AceConsole-3.0")

local isBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

--Higher in spellList = higher shown priority

if isBC then
    BuffOverlay.defaultSpells = {
        --High Priority

        --Immunities
        45438,  --Ice Block (Mage)
        642,    --Divine Shield (Paladin)
        498,    --Divine Protection (Paladin)
        1022,   --Blessing of Protection (Paladin)

        --Druid
        22812,  --Barkskin
        61336,  --Survival Instincts

        --Hunter
        19263,  --Deterrence

        --Mage
        543,    --Fire Ward
        6143,   --Frost Ward
        11426,  --Ice Barrier

        --Paladin
        6940,   --Blessing of Sacrifice

        --Priest
        33206,  --Pain Suppression

        --Rogue
        31224,  --Cloak of Shadows
        5277,   --Evasion

        --Shaman
        30823,  --Shamanistic Rage

        --Warlock
        6229,   --Shadow Ward

        --Warrior
        12975,  --Last Stand
        871,    --Shield Wall
        23920,  --Spell Reflection
        3411,   --Intervene

        --Racials
        20594,  --Stoneform
        20580,  --Shadowmeld

        --Other
        1784,   --Stealth
        5215,   --Prowl
        "Food",
        "Drink",
        "Food & Drink",
        "Refreshment",
    }
else
    BuffOverlay.defaultSpells = {
        --High Priority
        203554, --Focused Growth (Druid)
        -- 279793, --Grove Tending (Druid)

        --Immunities
        196555, --Netherwalk (Demon Hunter)
        186265, --Aspect of the Turtle (Hunter)
        45438,  --Ice Block (Mage)
        125174, --Touch of Karma (Monk)
        228050, --Divine Shield (Prot Paladin PVP)
        642,    --Divine Shield (Paladin)
        199448, --Blessing of Ultimate Sacrifice (Paladin)
        1022,   --Blessing of Protection (Paladin)
        47788,  --Guardian Spirit (Priest)
        31224,  --Cloak of Shadows (Rogue)
        210918, --Ethereal Form (Shaman)

        --Death Knight
        48707,  --Anti-Magic Shell
        48792,  --Icebound Fortitude
        287081, --Lichborne
        55233,  --Vampiric Blood
        194679, --Rune Tap
        145629, --Anti-Magic Zone
        81256,  --Dancing Rune Weapon

        --Demon Hunter
        206804, --Rain from Above
        187827, --Metamorphosis (Vengeance)
        212800, --Blur
        263648, --Soul Barrier

        --Druid
        102342, --Ironbark
        22812,  --Barkskin
        61336,  --Survival Instincts

        --Hunter
        53480,  --Roar of Sacrifice
        264735, --Survival of the Fittest (Pet Ability)
        281195, --Survival of the Fittest (Lone Wolf)

        --Mage
        198111, --Temporal Shield
        113862, --Greater Invisibility

        --Monk
        120954, --Fortifying Brew (Brewmaster)
        243435, --Fortifying Brew (Mistweaver)
        201318, --Fortifying Brew (Windwalker)
        115176, --Zen Meditation
        116849, --Life Cocoon
        122278, --Dampen Harm
        122783, --Diffuse Magic

        --Paladin
        204018, --Blessing of Spellwarding
        6940,   --Blessing of Sacrifice
        498,    --Divine Protection
        31850,  --Ardent Defender
        86659,  --Guardian of Ancient Kings
        205191, --Eye for an Eye

        --Priest
        47585,  --Dispersion
        33206,  --Pain Suppression
        213602, --Greater Fade
        81782,  --Power Word: Barrier
        271466, --Luminous Barrier

        --Rogue
        45182,  --Cheating Death
        5277,   --Evasion
        199754, --Riposte
        1966,   --Feint

        --Shaman
        108271, --Astral Shift
        118337, --Harden Skin

        --Warlock
        212195, --Nether Ward
        104773, --Unending Resolve
        108416, --Dark Pact

        --Warrior
        190456, --Ignore Pain
        118038, --Die by the Sword
        871,    --Shield Wall
        213915, --Mass Spell Reflection
        23920,  --Spell Reflection (Prot)
        216890, --Spell Reflection (Arms/Fury)
        184364, --Enraged Regeneration
        97463,  --Rallying Cry
        12975,  --Last Stand

        --Other
        185710, --Sugar-Crusted Fish Feast
        "Food",
        "Drink",
        "Food & Drink",
        "Refreshment",
    }
end

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
        buffs = BuffOverlay.defaultSpells,
    },
}

local TestBuffs = {}

local function InsertTestBuff(spellId)
    local tex = GetSpellTexture(spellId)
    rawset(TestBuffs, #TestBuffs+1, {spellId, tex})
end

local function UnitBuffTest(_, index)
    local buff = TestBuffs[index]
    if not buff then return end
    return "TestBuff", buff[2], 0, nil, 60, GetTime() + 60, nil, nil, nil, buff[1]
end

function BuffOverlay:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("BuffOverlayDB", defaultSettings, true)

    self.index = 1

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
    self.buffs = {}
    self.bars = {}

    for i = 1, #self.defaultSpells do
        InsertTestBuff(self.defaultSpells[i])
    end

    for k, v in ipairs(self.defaultSpells) do
        self.buffs[v] = k
    end

    SLASH_BuffOverlay1 = "/bo"
    SLASH_BuffOverlay2 = "/buffoverlay"
    SlashCmdList.BuffOverlay = function(msg)
        if msg == "help" or msg =="?" then
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
end

function BuffOverlay:Refresh()
    for k, _ in pairs(self.overlays) do
        self.overlays[k]:Hide()
        self.overlays[k] = nil
    end

    for frame, _ in pairs(self.frames) do
        if frame:IsShown() then CompactUnitFrame_UpdateAuras(frame) end
    end
end

function BuffOverlay.print(msg)
    print("|cffff0000BuffOverlay|r: "..msg)
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
        test:SetSize(test.text:GetWidth()+20, test.text:GetHeight()+2)
        test:EnableMouse(false)
        test:SetPoint("BOTTOM", CompactRaidFrame1, "TOP", 0, 0)
        test:Hide()
    end

    if not self.test then
        if GetNumGroupMembers() == 0 or not IsInRaid() and not select(2, IsInInstance())=="arena" and GetCVarBool("useCompactPartyFrames") then
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
    if ( count > 1 ) then
        local countText = count
        if ( count >= 100 ) then
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
                overlay:SetPoint(self.db.profile.iconAnchor, frame, self.db.profile.iconRelativePoint, self.db.profile.iconXOff, self.db.profile.iconYOff)
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
            if self.buffs[buffName] and not self.buffs[spellId] then
                self.buffs[spellId] = self.buffs[buffName]
            end

            if self.buffs[spellId] then
                rawset(self.priority, #self.priority+1, {i, self.buffs[spellId]})
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
                self.overlays[bFrame .. 1]:SetPoint(point, relativeTo, relativePoint, -(self.overlays[bFrame .. 1]:GetWidth()/2)*(overlayNum-1)+self.db.profile.iconXOff, yOfs)
            elseif self.db.profile.growDirection == "VERTICAL" then
                self.overlays[bFrame .. 1]:SetPoint(point, relativeTo, relativePoint, xOfs, -(self.overlays[bFrame .. 1]:GetHeight()/2)*(overlayNum-1)+self.db.profile.iconYOff)
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
