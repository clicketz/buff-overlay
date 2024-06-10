local addonName = ...

---@class BuffOverlay: AceAddon
local Addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Glow: AceModule
local Glow = Addon:NewModule('Glow')

---@class Overlay: AceModule
local Overlay = Addon:GetModule('Overlay')

local LCG = LibStub("LibCustomGlow-1.0")

function Glow:UpdateSize(overlay)
    local glow = overlay.glow
    local w, h = overlay:GetSize()
    glow:SetSize(w * 1.3, h * 1.3)
end

function Glow:Setup(frame)
    if not frame.glow then
        -- Use this frame to ensure the glow is always on top
        local glow = CreateFrame("Frame", nil, frame)
        glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
        glow:SetFrameLevel(frame:GetFrameLevel() + 6)
        frame.glow = glow
    end

    if not frame.StopAllGlows then
        frame.StopAllGlows = function(self)
            LCG.ButtonGlow_Stop(self.glow)
            LCG.PixelGlow_Stop(self)
            LCG.ProcGlow_Stop(self)

            self.glow:Hide()
            self.glowing = false
        end
    end

    frame.glow:Hide()
end

function Glow:HideAll()
    for _, overlay in pairs(Overlay:GetAllOverlays()) do
        overlay:StopAllGlows()
    end
end
