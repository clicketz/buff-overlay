local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Aura: AceModule
local Aura = Addon:NewModule('Aura')

---@class Database: AceModule
local DB = Addon:GetModule('Database')

---@class Constants: AceModule
local Const = Addon:GetModule('Constants')

---@class Overlay: AceModule
local Overlay = Addon:GetModule('Overlay')

---@class Bar: AceModule
local Bar = Addon:GetModule('Bar')

---@class Test: AceModule
local Test = Addon:GetModule('Test')

---@class Data: AceModule
local Data = Addon:GetModule('Data')

---@class Util: AceModule
local Util = Addon:GetModule('Util')

---@class Glow: AceModule
local Glow = Addon:GetModule('Glow')

local LCG = LibStub("LibCustomGlow-1.0")

local priority = {}
local Masque

local function ShouldShow(bar, frameType)
    if not bar.frameTypes[frameType] then
        return false
    end

    if Test:IsEnabled() then
        return true
    end

    local instanceType = Data.instanceType
    local numGroupMembers = Data.numGroupMembers

    if bar.neverShow
    or numGroupMembers > bar.maxGroupSize
    or numGroupMembers < bar.minGroupSize
    or instanceType == "none" and not bar.showInWorld
    or instanceType == "pvp" and not bar.showInBattleground
    or instanceType == "arena" and not bar.showInArena
    or instanceType == "party" and not bar.showInDungeon
    or instanceType == "raid" and not bar.showInRaid
    or instanceType == "scenario" and not bar.showInScenario
    then
        return false
    end

    return true
end

local function masqueCallback()
    Overlay:RefreshOverlays(true)
end

local function sortAuras(a, b)
    return a[2] < b[2]
end

local function SetAura(overlay, index, icon, count, duration, expirationTime, dispelType, filter, spellId)
    local bar = overlay.bar

    overlay.icon:SetTexture(icon)

    if (count > 1) then
        local countText = count
        if (count >= 100) then
            countText = BUFF_STACKS_OVERFLOW
        end
        overlay.count:Show()
        overlay.count:SetText(countText)
    else
        overlay.count:Hide()
    end

    overlay:SetID(index)
    overlay.filter = filter
    overlay.spellId = spellId

    local enabled = expirationTime and expirationTime ~= 0
    if enabled then
        local startTime = expirationTime - duration
        CooldownFrame_Set(overlay.cooldown, startTime, duration, true)
    else
        CooldownFrame_Clear(overlay.cooldown)
    end

    if overlay.border and bar.iconBorder then
        if bar.debuffIconBorderColorByDispelType and filter == "HARMFUL" then
            local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
            overlay.border:SetVertexColor(color.r, color.g, color.b, bar.iconBorderColor.a)
        elseif bar.buffIconBorderColorByDispelType and filter == "HELPFUL" then
            local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
            overlay.border:SetVertexColor(color.r, color.g, color.b, bar.iconBorderColor.a)
        else
            overlay.border:SetVertexColor(bar.iconBorderColor.r, bar.iconBorderColor.g, bar.iconBorderColor.b, bar.iconBorderColor.a)
        end
    end

    overlay:Show()
end

local borderPieces = {
    "Top",
    "Bottom",
    "Left",
    "Right",
}

local function DisablePixelSnap(overlay)
    local border = overlay.border
    local icon = overlay.icon

    for _, pieceName in pairs(borderPieces) do
        local piece = border[pieceName]
        if piece then
            piece:SetTexelSnappingBias(0.0)
            piece:SetSnapToPixelGrid(false)
        end
    end

    icon:SetTexelSnappingBias(0.0)
    icon:SetSnapToPixelGrid(false)
end

local function UpdateBorder(overlay)
    local bar = overlay.bar

    if overlay.__MSQ_Enabled and bar.iconBorder then
        bar.iconBorder = false
    end

    -- zoomed in/out
    if bar.iconBorder then
        overlay.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        overlay.icon:SetTexCoord(0, 1, 0, 1)
    end

    if not overlay.border then
        overlay.border = CreateFrame("Frame", nil, overlay, "BuffOverlayBorderTemplate")
        overlay.border:SetFrameLevel(overlay:GetFrameLevel() + 5)
        overlay.border.SetFrameLevel = nop

        DisablePixelSnap(overlay)
    end

    local border = overlay.border
    local size = bar.iconBorderSize - 1
    local borderColor = bar.iconBorderColor

    local pixelFactor = BuffOverlay.pixelFactor
    local pixelSize = (pixelFactor / 2) + (pixelFactor * size)

    border:SetBorderSizes(pixelSize, pixelSize, pixelSize, pixelSize)
    border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    border:UpdateSizes()

    border:SetShown(bar.iconBorder)

    Glow:UpdateSize(overlay)
end

function Aura:Update(frame, unit, barNameToApply)
    if not frame or not unit or frame:IsForbidden() or not frame:IsShown() then return end
    if string.find(unit, "target") or unit == "focus" then return end

    if not frame.BuffOverlays then
        Overlay:SetupContainer(frame)
    end

    local overlays = Overlay:GetAllOverlays()
    local frameName = frame:GetName()
    local frameType = self.frames[frame] and self.frames[frame].type
    local frameWidth, frameHeight = frame:GetSize()
    local overlaySize = Util:round(math.min(frameHeight, frameWidth) * 0.33, 1)
    local UnitAura = Test:IsEnabled() and Test.UnitAura or C_UnitAuras.GetAuraDataByIndex
    local testBarNames = Test:GetTestBarNames()

    local bars = next(testBarNames) ~= nil and testBarNames or DB:GetBars()

    for barName, bar in pairs(bars) do
        if ShouldShow(bar, frameType) and not (barNameToApply and barName ~= barNameToApply) then
            if Masque and not bar.group then
                bar.group = Masque:Group(addonName, bar.name, barName)
                bar.group:RegisterCallback(masqueCallback)

                Overlay:RefreshOverlays(true, barName)
            end

            local overlayName = frameName .. addonName .. barName .. "Icon"
            local relativeSpacing = overlaySize * (bar.iconSpacing / 20)

            for i = 1, bar.iconCount do
                local overlay = overlays[overlayName .. i]

                if not overlay
                or overlay.needsUpdate
                or overlay.size ~= overlaySize
                then
                    if not overlay then
                        overlay = CreateFrame("Button", overlayName .. i, frame.BuffOverlays, "CompactAuraTemplate")
                        overlay.stack = CreateFrame("Frame", overlayName .. i .. "StackCount", overlay)
                        overlay.barName = barName
                        Glow:Setup(overlay)
                    end

                    if bar.group and not overlay.__MSQ_Enabled then
                        bar.group:AddButton(overlay)
                    end

                    overlay.bar = bar
                    overlay.size = overlaySize

                    if overlay.size <= 0 then
                        overlay.needsUpdate = true
                        return
                    else
                        overlay.needsUpdate = false
                    end

                    overlay.cooldown:SetDrawSwipe(bar.showCooldownSpiral)
                    overlay.cooldown:SetHideCountdownNumbers(not bar.showCooldownNumbers)
                    overlay.cooldown:SetScale(overlay.__MSQ_Enabled and 1 or (bar.cooldownNumberScale * overlaySize / 36))

                    if bar.showTooltip and not overlay:GetScript("OnEnter") then
                        overlay:SetScript("OnEnter", function(s)
                            GameTooltip:SetOwner(s, "ANCHOR_BOTTOMRIGHT")

                            if Test:IsEnabled() then
                                GameTooltip:SetSpellByID(s.spellId)
                            else
                                GameTooltip:SetUnitAura(s.unit, s:GetID(), s.filter)
                            end
                        end)

                        overlay:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                    elseif not bar.showTooltip and overlay:GetScript("OnEnter") then
                        overlay:SetScript("OnEnter", nil)
                        overlay:SetScript("OnLeave", nil)
                    end

                    overlay:SetScale(bar.iconScale)
                    overlay:SetAlpha(bar.iconAlpha)
                    overlay:SetSize(overlaySize, overlaySize)

                    if bar.group then
                        bar.group:ReSkin(overlay)
                    end

                    if bar.showTooltip then
                        overlay:SetMouseClickEnabled(false)
                    else
                        overlay:EnableMouse(false)
                    end
                    overlay:RegisterForClicks()

                    -- Fix for addons that recursively change its children's frame levels
                    if overlay.SetFrameLevel ~= nop then
                        overlay:SetFrameLevel(math.max(frame:GetFrameLevel() + 20, 999))
                        overlay.stack:SetFrameLevel(overlay:GetFrameLevel() + 10)
                        overlay.SetFrameLevel = nop
                        overlay.stack.SetFrameLevel = nop
                    end

                    if overlay.cooldown.SetFrameLevel ~= nop then
                        overlay.cooldown:SetFrameLevel(overlay:GetFrameLevel() + 1)
                        overlay.cooldown.SetFrameLevel = nop
                    end

                    overlay.count:SetScale(bar.stackCountScale * overlay.size / 20)
                    overlay.count:ClearPointsOffset()
                    overlay.count:SetParent(overlay.stack)
                    overlay.stack:SetShown(bar.showStackCount)

                    overlay:ClearAllPoints()

                    UpdateBorder(overlay)

                    overlay.spacing = relativeSpacing + (bar.iconBorder and ((overlay.border.borderSize * 3) / bar.iconScale) or 0)

                    if i == 1 then
                        overlay:SetPoint(bar.iconAnchor, frame.BuffOverlays, bar.iconRelativePoint, bar.iconXOff, bar.iconYOff)
                    else
                        local prevOverlay = Overlay:Get(overlayName .. (i - 1))

                        if bar.growDirection == "DOWN" then
                            overlay:SetPoint("TOP", prevOverlay, "BOTTOM", 0, -overlay.spacing)
                        elseif bar.growDirection == "LEFT" then
                            overlay:SetPoint("BOTTOMRIGHT", prevOverlay, "BOTTOMLEFT", -overlay.spacing, 0)
                        elseif bar.growDirection == "UP" or bar.growDirection == "VERTICAL" then
                            overlay:SetPoint("BOTTOM", prevOverlay, "TOP", 0, overlay.spacing)
                        else
                            overlay:SetPoint("BOTTOMLEFT", prevOverlay, "BOTTOMRIGHT", overlay.spacing, 0)
                        end
                    end

                    Overlay:Set(overlayName .. i, overlay)
                end
                overlay.unit = unit
                -- overlay:Hide()
            end

            if not priority[barName] then
                priority[barName] = {}
            end

            if next(priority[barName]) ~= nil then
                wipe(priority[barName])
            end
        end
    end

    -- TODO: Optimize this with new UNIT_AURA event payload
    for _, filter in ipairs(Const.FILTERS) do
        for i = 1, 40 do
            local spellName, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = UnitAura(unit, i, filter)
            if spellId then
                local aura = self.db.profile.buffs[spellId] or self.db.profile.buffs[spellName]

                if aura then
                    local castByPlayerOrPlayerPet = source == "player" or source == "pet" or source == "vehicle"

                    if aura.parent and not self.ignoreParentIcons[aura.parent] then
                        icon = self.customIcons[aura.parent] or select(3, GetSpellInfo(aura.parent)) or icon
                    elseif self.customIcons[spellId] then
                        icon = self.customIcons[spellId]
                    end

                    for barName, bar in pairs(bars) do
                        if ShouldShow(bar, frameType)
                        and not (barNameToApply and barName ~= barNameToApply)
                        and (aura.state[barName].enabled or Test:IsEnabled())
                        and (not aura.state[barName].ownOnly or (aura.state[barName].ownOnly and castByPlayerOrPlayerPet))
                        then
                            rawset(priority[barName], #priority[barName] + 1, { i, aura.prio, icon, count, duration, expirationTime, dispelType, filter, aura, spellId })
                        end
                    end
                end
            else
                break
            end
        end
        if Test:IsEnabled() then break end
    end

    for barName, bar in pairs(bars) do
        if ShouldShow(bar, frameType) and not (barNameToApply and barName ~= barNameToApply) then
            local overlayName = frameName .. addonName .. barName .. "Icon"
            local overlayNum = 1
            local activeOverlays = 0

            if #priority[barName] > 1 then
                table.sort(priority[barName], sortAuras)
            end

            while overlayNum <= bar.iconCount do
                local data = priority[barName][overlayNum]
                local olay = overlays[overlayName .. overlayNum]

                if data then
                    local glow = data[9].state[barName].glow
                    local pixelBorderSize = bar.iconBorder and (olay.border.borderSize + 1) or 1.2

                    if glow.enabled then
                        local color = glow.customColor and glow.color or nil

                        if olay.glowing ~= glow.type then
                            olay:StopAllGlows()
                        end

                        if glow.type == "blizz" then
                            olay.border:Hide()
                            if Const.IS_RETAIL then
                                LCG.ProcGlow_Start(olay, { color = color, startAnim = false, xOffset = 1, yOffset = 1 })
                            else
                                LCG.ButtonGlow_Start(olay.glow, color)
                            end
                        elseif glow.type == "pixel" then
                            LCG.PixelGlow_Start(olay, color, glow.n, glow.freq, glow.length, pixelBorderSize, glow.xOff, glow.yOff, glow.border, glow.key)
                        elseif glow.type == "oldBlizz" then
                            olay.border:Hide()
                            LCG.ButtonGlow_Start(olay.glow, color)
                        end
                        olay.glow:Show()
                        olay.glowing = glow.type
                    else
                        olay.border:SetShown(bar.iconBorder)
                        if olay.glowing then
                            olay:StopAllGlows()
                            olay.glow:Hide()
                        end
                    end

                    SetAura(olay, data[1], data[3], data[4], data[5], data[6], data[7], data[8], data[10])

                    activeOverlays = activeOverlays + 1
                else
                    olay:Hide()
                end

                overlayNum = overlayNum + 1
            end

            if activeOverlays > 0 and (bar.growDirection == "HORIZONTAL" or bar.growDirection == "VERTICAL") then
                local overlay1 = overlays[overlayName .. 1]
                local width, height = overlay1:GetSize()
                local point, relativeTo, relativePoint, xOfs, yOfs = overlay1:GetPoint()

                local x = bar.growDirection == "HORIZONTAL" and (-(width / 2) * (activeOverlays - 1) + bar.iconXOff - (((activeOverlays - 1) / 2) * overlay1.spacing)) or xOfs
                local y = bar.growDirection == "VERTICAL" and (-(height / 2) * (activeOverlays - 1) + bar.iconYOff - (((activeOverlays - 1) / 2) * overlay1.spacing)) or yOfs

                overlay1:SetPoint(point, relativeTo, relativePoint, x, y)
            end
        end
    end
end

function Aura:OnEnable()
    Masque = LibStub("Masque", true)
end
