--//User Options

local iconCount = 4
local iconScale = 1.2
local iconAlpha = 0.75
local iconPosition = "HIGHCENTER"
local growDirection = "HORIZONTAL"
local showCooldownSpiral = true
local showCooldownNumbers = false
local cooldownNumberScale = 0.5

--[[ Notes

iconCount: Number of icons you want to display (per frame).

iconScale: The scale of the icon based on the size of the default icons on raidframe.

iconAlpha: Icon transparency.

iconPosition: "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOP", "BOTTOM", "RIGHT", "LEFT", "CENTER", "HIGHCENTER"

growDirection: "DOWN", "UP", "LEFT", "RIGHT", "HORIZONTAL", "VERTICAL"

showCooldownSpiral: Enable or disable showing the grey cooldown spiral.

showCooldownNumbers: Show or hide cooldown text (must have it enabled in blizzard settings or use an addon).

cooldownNumberScale: Scale the icon's cooldown text size.

]]

--Higher in spellList = higher shown priority
local spellList = {
--Immunities (High Priority)
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
5215,   --Prowl

--Hunter
53480,  --Roar of Sacrifice
264735, --Survival of the Fittest (Pet Ability)
281195, --Survival of the Fittest (Lone Wolf)

--Mage
198111, --Temporal Shield
113862, --Greater Invisibility
198144, --Ice Form

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
1784,   --Stealth

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
"Food",
"Drink",
"Food & Drink",
"Refreshment"
}

local buffs = {}
local overlays = {}
local priority = {}

for k, v in ipairs(spellList) do
    buffs[v] = k
end

if iconPosition == "HIGHCENTER" then
    anchor = "BOTTOM"
    iconPosition = "CENTER"
else
    anchor = iconPosition
end

hooksecurefunc("CompactUnitFrame_UpdateBuffs", function(self)
    if self:IsForbidden() or not self:IsVisible() or not self.buffFrames then
        return
    end

    local unit = self.displayedUnit
    local frame = self:GetName() .. "BuffOverlay"
    local overlayNum = 1

    for i = 1, iconCount do
        local overlay = overlays[frame .. i]
        if not overlay then
            if not self or not unit then return end
            overlay = _G[frame .. i] or CreateFrame("Button", frame .. i, self, "CompactAuraTemplate")
            overlay.cooldown:SetDrawSwipe(showCooldownSpiral)
            overlay.cooldown:SetHideCountdownNumbers(not showCooldownNumbers)
            overlay.cooldown:SetScale(cooldownNumberScale)
            overlay:ClearAllPoints()
            if i == 1 then
                overlay:SetPoint(anchor, self, iconPosition)
            else
                if growDirection == "DOWN" then
                    overlay:SetPoint("TOP", _G[frame .. i - 1], "BOTTOM")
                elseif growDirection == "LEFT" then
                    overlay:SetPoint("BOTTOMRIGHT", _G[frame .. i - 1], "BOTTOMLEFT")
                elseif growDirection == "UP" or growDirection == "VERTICAL" then
                    overlay:SetPoint("BOTTOM", _G[frame .. i - 1], "TOP")
                else
                    overlay:SetPoint("BOTTOMLEFT", _G[frame .. i - 1], "BOTTOMRIGHT")
                end
            end
            overlay:SetScale(iconScale)
            overlay:SetAlpha(iconAlpha)
            overlay:EnableMouse(false)
            overlay:RegisterForClicks()
            overlays[frame .. i] = overlay
        end
        overlay:Hide()
    end

    if #priority > 0 then
        for i = 1, #priority do
            priority[i] = nil
        end
    end

    for i = 1, 40 do
        local buffName, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
        if spellId then
            if buffs[buffName] and not buffs[spellId] then
                buffs[spellId] = buffs[buffName]
            end

            if buffs[spellId] then
                rawset(priority, #priority+1, {i, buffs[spellId]})
            end
        else
            break
        end
    end

    if #priority > 1 then
        table.sort(priority, function(a, b)
            return a[2] < b[2]
        end)
    end

    while overlayNum <= iconCount do
        if priority[overlayNum] then
            CompactUnitFrame_UtilSetBuff(overlays[frame .. overlayNum], unit, priority[overlayNum][1], nil)
            overlays[frame .. overlayNum]:SetSize(self.buffFrames[1]:GetSize())

            local point, relativeTo, relativePoint, xOfs, yOfs = overlays[frame .. 1]:GetPoint()
            if growDirection == "HORIZONTAL" then
                overlays[frame .. 1]:SetPoint(point, relativeTo, relativePoint, -(overlays[frame .. 1]:GetWidth()/2)*(overlayNum-1), yOfs)
            elseif growDirection == "VERTICAL" then
                overlays[frame .. 1]:SetPoint(point, relativeTo, relativePoint, xOfs, -(overlays[frame .. 1]:GetHeight()/2)*(overlayNum-1))
            end
            overlayNum = overlayNum + 1
        else
            break
        end
    end
end)
