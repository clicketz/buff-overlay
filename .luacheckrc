std = "lua51"
max_line_length = false
exclude_files = {
    ".luacheckrc",
    "Libs/",
}
ignore = {
    "11./SLASH_.*", -- slash handler
    "211/L", -- Unused local variable "L"
    "212", -- unused argument
}
globals = {
    "_G",

    -- BuffOverlay
    "BuffOverlay",
    "BuffOverlayBorderTemplateMixin",

    -- Mixins
    "PixelUtil",
    "Settings",
    "Spell",

    -- Mixin Functions
    "UpdateSizes",

    -- FrameXML Frames
    "CompactPartyFrame",
    "CompactRaidFrameContainer",
    "CompactRaidFrameManager",
    "EditModeManagerFrame",
    "GameMenuFrame",
    "GameTooltip",
    "InterfaceOptionsFrame",
    "PartyFrame",
    "SettingsPanel",
    "UIParent",

    -- Misc
    "C_Spell",
    "C_Timer",
    "SlashCmdList",

    -- Functions
    "CompactUnitFrame_UpdateAuras",
    "CooldownFrame_Clear",
    "CooldownFrame_Set",
    "CopyTable",
    "CreateFrame",
    "debugprofilestop",
    "format",
    "GetAddOnMetadata",
    "GetCVar",
    "GetCVarBool",
    "GetLocale",
    "GetNumGroupMembers",
    "GetSpellInfo",
    "GetSpellTexture",
    "GetTime",
    "HideUIPanel",
    "hooksecurefunc",
    "InCombatLockdown",
    "InterfaceOptions_AddCategory",
    "IsAddOnLoaded",
    "IsInInstance",
    "IsInRaid",
    "IsShiftKeyDown",
    "next",
    "nop",
    "SecureButton_GetModifiedUnit",
    "SecureButton_GetUnit",
    "SetBorderSizes",
    "SetCVar",
    "SetVertexColor",
    "UnitAura",
    "UnitBuff",
    "UnitGUID",
    "UnitIsPlayer",
    "UpdateRaidAndPartyFrames",
    "wipe",

    -- Constants
    "CLASS_ICON_TCOORDS",
    "CLASS_SORT_ORDER",
    "DebuffTypeColor",
    "LOCALIZED_CLASS_NAMES_MALE",
    "NORMAL_FONT_COLOR",
    "RAID_CLASS_COLORS",

    -- Global Strings
    "BUFF_STACKS_OVERFLOW",
    "MAX_CLASSES",
    "NO", -- localized "No"
    "OKAY", -- localized "Okay"
    "WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",
    "WOW_PROJECT_WRATH_CLASSIC",
    "YES", -- localized "Yes"

    -- Third Party AddOns
    "ElvUF_Parent", -- ElvUI
    "GAME_LOCALE",
    "LibStub",
    "Scorpio",
}
