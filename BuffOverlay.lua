--//User Options

local iconCount = 4
local iconScale = 1.0
local iconAlpha = .75
local iconPosition = "TOPLEFT"
local growDirection = "RIGHT"
local showCooldownNumbers = false
local cooldownNumberScale = .5

--[[ Notes

iconCount: Number of icons you want to display.
iconScale: The scale of the icon based on the size of the default icons on raidframe.
iconAlpha: Icon transparency.
iconPosition: "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOP", "BOTTOM", "RIGHT", "LEFT", "CENTER", "HIGHCENTER"
growDirection:"DOWN", "UP", "LEFT", "RIGHT"
showCooldownNumbers: Show or hide cooldown text (must have it enabled in blizzard settings or use an addon).
cooldownNumberScale: Scale the icon's cooldown text size.

]]

local spellList = {
--Death Knight
48707,  --Anti-Magic Shell
48792,  --Icebound Fortitude
55233,  --Vampiric Blood
194679, --Rune Tap
145629, --Anti-Magic Zone
81256,  --Dancing Rune Weapon

--Demon Hunter
196555, --Netherwalk
187827, --Metamorphosis (Vengeance)
212800, --Blur

--Druid
102342, --Ironbark
22812,  --Barkskin
61336,  --Survival Instincts
5215,   --Prowl

--Hunter
186265, --Aspect of the Turtle
53480,  --Roar of Sacrifice
264735, --Survival of the Fittest (Pet Ability)
281195, --Survival of the Fittest (Lone Wolf)

--Mage
45438,  --Ice Block
198111, --Temporal Shield
198144, --Ice Form

--Monk
125174, --Touch of Karma
120954, --Fortifying Brew (Brewmaster)
243435, --Fortifying Brew (Mistweaver)
201318, --Fortifying Brew (Windwalker)
115176, --Zen Meditation
116849, --Life Cocoon
122278, --Dampen Harm
122783, --Diffuse Magic

--Paladin
642,    --Divine Shield
1022,   --Blessing of Protection
204018, --Blessing of Spellwarding
498,    --Divine Protection
31850,  --Ardent Defender
86659,  --Guardian of Ancient Kings

--Priest
47788,  --Guardian Spirit
47585,  --Dispersion
33206,  --Pain Suppression
81782,  --Power Word: Barrier
271466, --Luminous Barrier

--Rogue
31224,  --Cloak of Shadows
5277,   --Evasion
199754, --Riposte
45182,  --Cheating Death
1784,   --Stealth

--Shaman
210918, --Ethereal Form
108271, --Astral Shift

--Warlock
104773, --Unending Resolve
108416, --Dark Pact

--Warrior
118038, --Die by the Sword
184364, --Enraged Regeneration
871,    --Shield Wall
97463,  --Rallying Cry
12975,  --Last Stand

--//Other

"Food",
"Drink",
"Food & Drink",
"Refreshment",
}

local buffs = {}
local overlays = {}

for k, v in ipairs(spellList) do
    buffs[v] = k
end

--Anchor Settings
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
    local index = 1
    local overlayNum = 1

    for i = 1, iconCount do
        local overlay = overlays[frame .. i]
        if not overlay then
            if not self or not unit then return end
            overlay = _G[frame .. i] or CreateFrame("Button", frame .. i, self, "CompactAuraTemplate")
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
                elseif growDirection == "UP" then
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

    while overlayNum <= iconCount do
        local buffName, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, index)
        if spellId then
            if buffs[buffName] then
                buffs[spellId] = buffs[buffName]
            end
            
            if buffs[spellId] then
                CompactUnitFrame_UtilSetBuff(overlays[frame .. overlayNum], unit, index, nil)
                overlays[frame .. overlayNum]:SetSize(self.buffFrames[1]:GetSize())
                overlayNum = overlayNum + 1
            end
        else
            break
        end
        index = index + 1
    end
end)
