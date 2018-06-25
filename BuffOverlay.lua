local overlays = {}
local buffs = {}

buffs = {
--Death Knight
[48792] = true, --Icebound Fortitude
[55233] = true, --Vampiric Blood
[194679] = true, --Rune Tap
[48707] = true, --Anti-Magic Shell
[145629] = true, --Anti-Magic Zone
[81256] = true, --Dancing Rune Weapon
--Demon Hunter
[212800] = true, --Blur
[196555] = true, --Netherwalk
--Druid
[5215] = true, --Prowl
[102342] = true, --Ironbark
[22812] = true, --Barkskin
[61336] = true, --Survival Instincts
--Hunter
[53480] = true, --Roar of Sacrifice
[186265] = true, --Aspect of the Turtle
--Mage
[45438] = true, --Ice Block
[198111] = true, --Temporal Shield
[198144] = true, --Ice Form
--Monk
[120954] = true, --Fortifying Brew (Brewmaster)
[243435] = true, --Fortifying Brew (Mistweaver)
[201318] = true, --Fortifying Brew (Windwalker)
[115176] = true, --Zen Meditation
[116849] = true, --Life Cocoon
[122278] = true, --Dampen Harm
[125174] = true, --Touch of Karma
--Paladin
[498] = true, --Divine Protection
[1022] = true, --Blessing of Protection
[642] = true, --Divine Shield
[31850] = true, --Ardent Defender
[86659] = true, --Guardian of Ancient Kings
--Priest
[33206] = true, --Pain Suppression
[47585] = true, --Dispersion
[81782] = true, --Power Word: Barrier
[271466] = true, --Luminous Barrier
--Rogue
[5277] = true, --Evasion
[31224] = true, --Cloak of Shadows
[199754] = true, --Riposte
[1784] = true, --Stealth
--Shaman
[108271] = true, --Astral Shift
[210918] = true, --Ethereal Form
--Warlock
[104773] = true, --Unending Resolve
--Warrior
[184364] = true, --Enraged Regeneration
[871] = true, --Shield Wall
[97463] = true, --Rallying Cry
[12975] = true, --Last Stand
[118038] = true, --Die by the Sword
--Other
["Food"] = true,
["Drink"] = true,
["Food & Drink"] = true,
["Refreshment"] = true,
}

local function getOverlay(frame)
local overlay = overlays[frame:GetName()]
	if not overlay then
		overlay = CreateFrame("Button", nil, frame, "CompactAuraTemplate")
		overlay:ClearAllPoints()
		overlay:SetPoint("BOTTOM", frame, "CENTER", 0, 0)
		overlay:SetSize(22, 22)
		overlay:SetAlpha(0.75)
		overlays[frame:GetName()] = overlay
	end
	return overlay
end

local function updateOverlay(frame)
	if frame:IsForbidden() or (not frame:IsVisible()) then
		return
	end

	local overlay = getOverlay(frame)
	local spellId = nil
	local buffName = nil
	for i = 1, 40 do
		local buffName, _, _, _, _, _, _, _, _, _, spellId = UnitBuff(frame.displayedUnit, i)
		if not spellId then
			break
		end
		if buffs[spellId] or buffs[buffName] then
			if not frame.buffFrames then -- fix for personal resource bar
				return
			end
			overlay:SetSize(frame.buffFrames[1]:GetSize())
			overlay:SetScale(1.2)
			CompactUnitFrame_UtilSetBuff(overlay, frame.displayedUnit, i, nil)
		return
		end
	end
	overlay:Hide()
end
hooksecurefunc("CompactUnitFrame_UpdateBuffs", updateOverlay)
