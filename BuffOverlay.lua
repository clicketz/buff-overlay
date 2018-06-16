local indicators = {}
local buffs = {}
local _, class = UnitClass("player")

buffs = {
--Death Knight
["Icebound Fortitude"] = true,
["Vampiric Blood"] = true,
["Rune Tap"] = true,
["Anti-Magic Shell"] = true,
["Anti-Magic Zone"] = true,
["Dancing Rune Weapon"] = true,
--Demon Hunter
["Blur"] = true,
["Netherwalk"] = true,
--Druid
["Prowl"] = true,
["Ironbark"] = true,
["Barkskin"] = true,
["Survival Instincts"] = true,
--Hunter
["Roar of Sacrifice"] = true,
["Aspect of the Turtle"] = true,
--Mage
["Ice Block"] = true,
["Temporal Shield"] = true,
["Ice Form"] = true,
--Monk
["Fortifying Brew"] = true,
["Zen Meditation"] = true,
["Life Cocoon"] = true,
["Dampen Harm"] = true,
["Touch of Karma"] = true,
--Paladin
["Divine Protection"] = true,
["Blessing of Protection"] = true,
["Divine Shield"] = true,
["Ardent Defender"] = true,
["Guardian of Ancient Kings"] = true,
--Priest
["Pain Suppression"] = true,
["Dispersion"] = true,
["Power Word: Barrier"] = true,
["Luminous Barrier"] = true,
--Rogue
["Evasion"] = true,
["Cloak of Shadows"] = true,
["Riposte"] = true,
["Stealth"] = true,
--Shaman
["Astral Shift"] = true,
["Ethereal Form"] = true,
--Warlock
["Unending Resolve"] = true,
["Nether Ward"] = true,
--Warrior
["Shield Wall"] = true,
["Rallying Cry"] = true,
["Last Stand"] = true,
["Spell Reflection"] = true,
["Die by the Sword"] = true,
--Other
["Drink"] = true,
["Food & Drink"] = true,
}

local function getIndicator(frame)
local indicator = indicators[frame:GetName()]
	if not indicator then
		indicator = CreateFrame("Button", nil, frame, "CompactAuraTemplate")
		indicator:ClearAllPoints()
		indicator:SetPoint("CENTER", frame, "CENTER", 0, 10)
		indicator:SetSize(22, 22)
		indicator:SetAlpha(0.7)
		indicators[frame:GetName()] = indicator
	end
	return indicator
end

local function updateBuffs(frame)
	if frame:IsForbidden() or (not frame:IsVisible()) then
		return
	end

	local indicator = getIndicator(frame)
	local buffName = nil
	for i = 1, 40 do
		local buffName = UnitBuff(frame.displayedUnit, i)
		if not buffName then
			break
		end
		if buffs[buffName] then
			if not frame.buffFrames then -- fix for personal resource bar
				return
			end
			indicator:SetSize(frame.buffFrames[1]:GetSize()) -- scale
			CompactUnitFrame_UtilSetBuff(indicator, frame.displayedUnit, i, nil)
		return
		end
	end
	indicator:Hide()
end
hooksecurefunc("CompactUnitFrame_UpdateBuffs", updateBuffs)
