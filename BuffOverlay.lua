local overlays = {}
local buffs = {}

local spellList = {
--Death Knight
48792,	--Icebound Fortitude
55233,	--Vampiric Blood
194679,	--Rune Tap
48707,	--Anti-Magic Shell
145629,	--Anti-Magic Zone
81256,	--Dancing Rune Weapon

--Demon Hunter
187827,	--Metamorphosis (Vengeance)
212800,	--Blur
196555,	--Netherwalk

--Druid
5215,	--Prowl
102342,	--Ironbark
22812,	--Barkskin
61336,	--Survival Instincts

--Hunter
53480,	--Roar of Sacrifice
186265,	--Aspect of the Turtle

--Mage
45438,	--Ice Block
198111,	--Temporal Shield
198144,	--Ice Form

--Monk
120954,	--Fortifying Brew (Brewmaster)
243435,	--Fortifying Brew (Mistweaver)
201318,	--Fortifying Brew (Windwalker)
115176,	--Zen Meditation
116849,	--Life Cocoon
122278,	--Dampen Harm
122783,	--Diffuse Magic
125174,	--Touch of Karma

--Paladin
498,	--Divine Protection
1022,	--Blessing of Protection
642,	--Divine Shield
31850,	--Ardent Defender
86659,	--Guardian of Ancient Kings

--Priest
33206,	--Pain Suppression
47585,	--Dispersion
81782,	--Power Word: Barrier
271466,	--Luminous Barrier

--Rogue
5277,	--Evasion
31224,	--Cloak of Shadows
199754,	--Riposte
1784,	--Stealth

--Shaman
108271,	--Astral Shift
210918,	--Ethereal Form

--Warlock
104773,	--Unending Resolve

--Warrior
184364,	--Enraged Regeneration
871,	--Shield Wall
97463,	--Rallying Cry
12975,	--Last Stand
118038,	--Die by the Sword

--Other
"Food",
"Drink",
"Food & Drink",
"Refreshment",
}

for k, v in ipairs(spellList) do
	buffs[v] = k
end

hooksecurefunc("CompactUnitFrame_UpdateBuffs", function(self)
	if self:IsForbidden() or not self:IsVisible() or not self.buffFrames then
		return
	end

	local unit, index = self.displayedUnit, 1
	repeat
		local buffName, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, index)
		if spellId then
			if buffs[spellId] or buffs[buffName] then
				break
			end
			index = index + 1
		else
			index = nil
		end
	until not spellId

	local overlay = overlays[self]
	if not overlay then
		if not index then
			return
		end
		overlay = CreateFrame("Button", nil, self, "CompactAuraTemplate")
		overlay:ClearAllPoints()
		overlay:SetPoint("BOTTOM", self, "CENTER")
		overlay:SetAlpha(0.75)
		overlays[self] = overlay
	end

	if index then
		overlay:SetSize(self.buffFrames[1]:GetSize())
		overlay:SetScale(1.2)
		CompactUnitFrame_UtilSetBuff(overlay, unit, index, nil)
	end
	overlay:SetShown(index and true or false)
end)
