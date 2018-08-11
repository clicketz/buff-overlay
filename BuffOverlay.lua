local overlays = {}
local buffs = {}

local prioritySpellList = { --The higher on the list, the higher priority the buff has.

--//Immunities (High Priority)

--Demon Hunter
196555,	--Netherwalk

--Hunter
186265,	--Aspect of the Turtle

--Mage
45438,	--Ice Block

--Monk
125174,	--Touch of Karma

--Paladin
642,	--Divine Shield
1022,	--Blessing of Protection

--Priest
47788,	--Guardian Spirit

--Rogue
31224,	--Cloak of Shadows

--Shaman
210918,	--Ethereal Form

--//Damage Reduction+

--Death Knight
48707,	--Anti-Magic Shell
48792,	--Icebound Fortitude
55233,	--Vampiric Blood
194679,	--Rune Tap
145629,	--Anti-Magic Zone
81256,	--Dancing Rune Weapon

--Demon Hunter
187827,	--Metamorphosis (Vengeance)
212800,	--Blur

--Druid
102342,	--Ironbark
22812,	--Barkskin
61336,	--Survival Instincts
5215,	--Prowl

--Hunter
53480,	--Roar of Sacrifice
264735,	--Survival of the Fittest (Pet Ability)
281195,	--Survival of the Fittest (Lone Wolf)

--Mage
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

--Paladin
498,	--Divine Protection
31850,	--Ardent Defender
86659,	--Guardian of Ancient Kings

--Priest
47585,	--Dispersion
33206,	--Pain Suppression
81782,	--Power Word: Barrier
271466,	--Luminous Barrier

--Rogue
5277,	--Evasion
199754,	--Riposte
1784,	--Stealth

--Shaman
108271,	--Astral Shift

--Warlock
104773,	--Unending Resolve

--Warrior
118038,	--Die by the Sword
184364,	--Enraged Regeneration
871,	--Shield Wall
97463,	--Rallying Cry
12975,	--Last Stand

--//Other

"Food",
"Drink",
"Food & Drink",
"Refreshment",
}

for k, v in ipairs(prioritySpellList) do
	buffs[v] = k
end

hooksecurefunc("CompactUnitFrame_UpdateBuffs", function(self)
	if self:IsForbidden() or not self:IsVisible() or not self.buffFrames then
		return
	end

	local unit, index, buff = self.displayedUnit, index, buff
	for i = 1, 32 do --BUFF_MAX_DISPLAY
		local buffName, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)

		if spellId then
			if buffs[buffName] then
				buffs[spellId] = buffs[buffName]
			end

			if buffs[spellId] then
				if not buff or buffs[spellId] < buffs[buff] then
					buff = spellId
					index = i
				end
			end
		else
			break
		end
	end

	local overlay = overlays[self]
	if not overlay then
		if not index then
			return
		end
		overlay = CreateFrame("Button", "$parentBuffOverlay", self, "CompactAuraTemplate")
		overlay:ClearAllPoints()
		overlay:SetPoint("BOTTOM", self, "CENTER")
		overlay:SetAlpha(0.75)
		overlay:EnableMouse(false)
		overlay:RegisterForClicks()
		overlays[self] = overlay
	end

	if index then
		overlay:SetSize(self.buffFrames[1]:GetSize())
		overlay:SetScale(1.2)
		CompactUnitFrame_UtilSetBuff(overlay, unit, index, nil)
	end
	overlay:SetShown(index and true or false)
end)
