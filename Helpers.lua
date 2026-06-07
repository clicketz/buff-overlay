---@class BuffOverlay: AceModule
local BuffOverlay = LibStub("AceAddon-3.0"):GetAddon("BuffOverlay")

function BuffOverlay.CreateAuraButton(name, parent)
    local f = CreateFrame("Button", name, parent)
    f:Hide()

    f.icon = f:CreateTexture(nil, "BACKGROUND")
    f.icon:SetAllPoints()

    f.normal = f:CreateTexture(nil, "BORDER")
    f.normal:SetAllPoints()
    f.normal:SetTexture(nil)

    -- pushed texture (unused atm)
    f.pushed = f:CreateTexture(nil, "ARTWORK")
    f.pushed:SetAllPoints()
    f.pushed:SetTexture(nil)
    f:SetPushedTexture(f.pushed)

    -- highlight texture (unused atm)
    f.highlight = f:CreateTexture(nil, "HIGHLIGHT")
    f.highlight:SetAllPoints()
    f.highlight:SetTexture(nil)
    f:SetHighlightTexture(f.highlight)

    -- cooldown spiral
    f.cooldown = CreateFrame("Cooldown", "$parentCooldown", f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints()
    f.cooldown:SetDrawEdge(false)
    f.cooldown:SetReverse(true)

    -- stack count
    f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.count:SetPoint("BOTTOMRIGHT", 0, 0)

    return f
end
